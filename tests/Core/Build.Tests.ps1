BeforeAll { $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path }
Describe 'Release payload' {
    It 'assembles an importable lazy runtime with Python routing' {
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1')
        $modulePath = Join-Path $build.Payload 'PS7-Completion.psm1'
        Get-Content $modulePath -Raw | Should -Not -Match '# BEGIN RUNTIME LOAD'
        try {
            Get-Module PS7-Completion | Remove-Module -Force
            Import-Module (Join-Path $build.Payload 'PS7-Completion.psd1') -Force
            @(Get-PS7CompletionProvider).Count | Should -Be 34
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
    It 'keeps source version unchanged for upgrade fixtures' {
        $sourceManifest = Join-Path $projectRoot 'src/PS7-Completion/PS7-Completion.psd1'
        $before = Get-Content $sourceManifest -Raw
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1') -Version 0.1.1
        (Test-ModuleManifest (Join-Path $build.Payload 'PS7-Completion.psd1')).Version.ToString() | Should -Be '0.1.1'
        Get-Content $sourceManifest -Raw | Should -Be $before
    }
    It 'generates a manifest with exact installer hash and no placeholders' {
        $installer = Join-Path $TestDrive 'fixture.exe'
        Set-Content $installer 'fixture bytes only'
        $metadata = Join-Path $TestDrive 'build.json'
        @{ Version='0.1.0'; Installer=$installer } | ConvertTo-Json | Set-Content $metadata
        $path = & (Join-Path $projectRoot 'scripts/New-WinGetManifest.ps1') -BuildMetadata $metadata -OutputDirectory (Join-Path $TestDrive 'manifest')
        $yaml = Get-Content $path -Raw
        $yaml | Should -Match ((Get-FileHash $installer).Hash)
        $yaml | Should -Match 'PackageIdentifier: JackScott7.PS7-Completion'
        $yaml | Should -Not -Match '__[A-Z_]+__'
    }
}
