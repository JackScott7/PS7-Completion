BeforeAll { $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path }
Describe 'Release payload' {
    It 'assembles an importable lazy runtime with Python routing' {
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1')
        $modulePath = Join-Path $build.Payload 'PS7-Completion.psm1'
        Get-Content $modulePath -Raw | Should -Not -Match '# BEGIN RUNTIME LOAD'
        try {
            Get-Module PS7-Completion | Remove-Module -Force
            Import-Module (Join-Path $build.Payload 'PS7-Completion.psd1') -Force
            @(Get-PS7CompletionProvider).Count | Should -Be 46
            @(Get-PS7CompletionProvider | Where-Object Loaded).Count | Should -Be 0
            $line = 'python -m pip ins'
            [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain install
        }
        finally {
            Get-Module PS7-Completion | Remove-Module -Force
            Import-Module (Join-Path $projectRoot 'src/PS7-Completion/PS7-Completion.psd1') -Force
        }
    }
    It 'stages a clean versioned payload without ZIP distribution assets' {
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1')
        $build.Assets.Count | Should -Be 0
        $build.Checksums | Should -BeNullOrEmpty
        @(Get-ChildItem (Split-Path (Split-Path (Split-Path $build.Payload))) -Recurse -Filter *.zip).Count | Should -Be 0
        $manifest = Test-ModuleManifest (Join-Path $build.Payload 'PS7-Completion.psd1')
        $manifest.Version.ToString() | Should -Be $build.Version
        Get-Content (Join-Path $build.Payload 'LICENSE') -Raw | Should -Match '^MIT License'
        Join-Path $build.Payload 'Workers/Query.ps1' | Should -Exist
    }
    It 'uses the safe registry parser when the staged data changes' {
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1')
        $registry = Join-Path $build.Payload 'Registry.psd1'
        Add-Content -LiteralPath $registry -Value '# changed but valid'
        try {
            Get-Module PS7-Completion | Remove-Module -Force
            Import-Module (Join-Path $build.Payload 'PS7-Completion.psd1') -Force
            @(Get-PS7CompletionProvider).Count | Should -Be 46
            Get-Module PS7-Completion | Remove-Module -Force
            $changed = (Get-Content -LiteralPath $registry -Raw).Replace("'ssh.exe'", "'sshfixture.exe'")
            Set-Content -LiteralPath $registry -Value $changed
            Import-Module (Join-Path $build.Payload 'PS7-Completion.psd1') -Force
            (Get-PS7CompletionProvider | Where-Object Name -EQ ssh).Commands | Should -Contain 'sshfixture.exe'
            Get-Module PS7-Completion | Remove-Module -Force
            $global:PS7RegistryFixtureExecuted = $false
            Set-Content -LiteralPath $registry -Value '$global:PS7RegistryFixtureExecuted = $true; throw "must not execute"'
            { Import-Module (Join-Path $build.Payload 'PS7-Completion.psd1') -Force -ErrorAction Stop } | Should -Throw
            $global:PS7RegistryFixtureExecuted | Should -BeFalse
        }
        finally {
            Get-Module PS7-Completion | Remove-Module -Force
            Remove-Variable PS7RegistryFixtureExecuted -Scope Global -ErrorAction SilentlyContinue
            Import-Module (Join-Path $projectRoot 'src/PS7-Completion/PS7-Completion.psd1') -Force
        }
    }
    It 'keeps source version unchanged for upgrade fixtures' {
        $sourceManifest = Join-Path $projectRoot 'src/PS7-Completion/PS7-Completion.psd1'
        $before = Get-Content $sourceManifest -Raw
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1') -Version 0.1.1
        (Test-ModuleManifest (Join-Path $build.Payload 'PS7-Completion.psd1')).Version.ToString() | Should -Be '0.1.1'
        Get-Content $sourceManifest -Raw | Should -Be $before
    }
    It 'generates a manifest with exact installer hash and no placeholders' {
        $installer = Join-Path $TestDrive 'PS7-Completion-0.1.0-windows-x64.exe'
        Set-Content $installer 'fixture bytes only'
        $metadata = Join-Path $TestDrive 'build.json'
        $checksums = Join-Path $TestDrive 'SHA256SUMS.txt'
        ((Get-FileHash $installer).Hash + '  ' + (Split-Path $installer -Leaf)) | Set-Content $checksums
        Set-Content (Join-Path $TestDrive 'PS7-Completion.psd1') "@{ ModuleVersion='0.1.0' }"
        @{ Version='0.1.0'; Installer=$installer; Checksums=$checksums; Payload=$TestDrive } | ConvertTo-Json | Set-Content $metadata
        $paths = @(& (Join-Path $projectRoot 'scripts/New-WinGetManifest.ps1') -BuildMetadata $metadata -OutputDirectory (Join-Path $TestDrive 'manifest'))
        $paths.Count | Should -Be 3
        $paths | Split-Path -Leaf | Should -Contain 'JackScott7.PS7-Completion.installer.yaml'
        $paths | Split-Path -Leaf | Should -Contain 'JackScott7.PS7-Completion.locale.en-US.yaml'
        $paths | Split-Path -Leaf | Should -Contain 'JackScott7.PS7-Completion.yaml'
        foreach ($path in $paths) {
            $yaml = Get-Content $path -Raw
            $yaml | Should -Match 'PackageIdentifier: JackScott7.PS7-Completion'
            $yaml | Should -Match 'PackageVersion: 0.1.0'
            $yaml | Should -Match '(?m)^ManifestVersion: 1\.12\.0\s*$'
            $yaml | Should -Not -Match '__[A-Z_]+__'
        }
        $installerYaml = Get-Content ($paths | Where-Object { $_ -like '*.installer.yaml' }) -Raw
        $installerYaml | Should -Match ((Get-FileHash $installer).Hash)
        $installerYaml | Should -Match 'ElevationRequirement: elevationRequired'
        $installerYaml | Should -Match '(?m)^  Silent: /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART\s*$'
        $installerYaml | Should -Match '(?m)^  SilentWithProgress: /SP- /SILENT /SUPPRESSMSGBOXES /NORESTART\s*$'
        $installerYaml | Should -Match ([regex]::Escape("ProductCode: '{D1452431-C5FC-4982-8B42-334EFA8ABBC0}_is1'"))
        Set-Content $installer 'tampered bytes'
        { & (Join-Path $projectRoot 'scripts/New-WinGetManifest.ps1') -BuildMetadata $metadata -OutputDirectory (Join-Path $TestDrive 'manifest') } | Should -Throw '*checksum mismatch*'
        ((Get-FileHash $installer).Hash + '  ' + (Split-Path $installer -Leaf)) | Set-Content $checksums
        Set-Content (Join-Path $TestDrive 'PS7-Completion.psd1') "@{ ModuleVersion='0.5.0' }"
        { & (Join-Path $projectRoot 'scripts/New-WinGetManifest.ps1') -BuildMetadata $metadata -OutputDirectory (Join-Path $TestDrive 'manifest') } | Should -Throw '*version mismatch*'
    }
}
