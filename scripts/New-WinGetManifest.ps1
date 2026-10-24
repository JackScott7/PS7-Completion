#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string] $BuildMetadata, [Parameter(Mandatory)][string] $OutputDirectory)
$ErrorActionPreference = 'Stop'
$build = Get-Content -LiteralPath $BuildMetadata -Raw | ConvertFrom-Json
if (-not $build.Installer -or -not (Test-Path -LiteralPath $build.Installer)) { throw 'Build metadata must name an existing installer.' }
if ($build.Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid package version.' }
$hash = (Get-FileHash -LiteralPath $build.Installer -Algorithm SHA256).Hash
$expectedName = "PS7-Completion-$($build.Version)-windows-x64.exe"
if ((Split-Path $build.Installer -Leaf) -cne $expectedName) { throw 'Installer filename/version mismatch.' }
if (-not $build.Checksums -or -not (Test-Path -LiteralPath $build.Checksums)) { throw 'Build checksum file is required.' }
$pattern = '^([a-fA-F0-9]{64})\s{2}' + [regex]::Escape($expectedName) + '$'
$checksum = @(Get-Content -LiteralPath $build.Checksums | Where-Object { $_ -match $pattern })
if ($checksum.Count -ne 1 -or $checksum[0] -notmatch $pattern -or $Matches[1] -ne $hash) {
    throw 'Installer checksum mismatch.'
}
if (-not $build.Payload -or (Import-PowerShellDataFile (Join-Path $build.Payload 'PS7-Completion.psd1')).ModuleVersion -ne $build.Version) {
    throw 'Payload/package version mismatch.'
}
$template = Get-Content (Join-Path $PSScriptRoot '../packaging/winget/manifest.yaml.template') -Raw
$manifest = $template.Replace('__VERSION__', $build.Version).Replace('__SHA256__', $hash)
if ($manifest -match '__[A-Z_]+__') { throw 'Unresolved manifest placeholder.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$path = Join-Path $OutputDirectory "JackScott7.PS7-Completion.yaml"
Set-Content -LiteralPath $path -Value $manifest -Encoding utf8
$path
