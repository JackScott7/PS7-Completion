BeforeAll { $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path }
Describe 'Release payload' {
    It 'builds a clean versioned archive with MIT license and matching manifest' {
        $build = & (Join-Path $projectRoot 'scripts/Build.ps1')
        $build.Archive | Should -Exist
        $build.Checksums | Should -Exist
        $manifest = Test-ModuleManifest (Join-Path $build.Payload 'PS7-Completion.psd1')
        $manifest.Version.ToString() | Should -Be $build.Version
        Get-Content (Join-Path $build.Payload 'LICENSE') -Raw | Should -Match '^MIT License'
        Get-Content $build.Checksums -Raw | Should -Match ((Get-FileHash $build.Archive).Hash.ToLowerInvariant())
        $expanded = Join-Path $TestDrive 'expanded'
        Expand-Archive $build.Archive $expanded
        Join-Path $expanded "PS7-Completion/$($build.Version)/Workers/Query.ps1" | Should -Exist
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
