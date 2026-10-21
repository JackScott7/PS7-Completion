#Requires -Version 7.4
[CmdletBinding()]
param([switch] $Installer)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'src/PS7-Completion'
$manifest = Test-ModuleManifest (Join-Path $source 'PS7-Completion.psd1')
$version = $manifest.Version.ToString()
$dist = Join-Path $root 'dist'
# Unique staging avoids stale payload files without deleting previous artifacts.
$stage = Join-Path $dist ('staging/' + [guid]::NewGuid().ToString())
$payload = Join-Path $stage "PS7-Completion/$version"
New-Item -ItemType Directory -Path $payload -Force | Out-Null
Copy-Item -Path "$source/*" -Destination $payload -Recurse
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination $payload
$archive = Join-Path $dist "PS7-Completion-$version.zip"
Compress-Archive -Path (Join-Path $stage 'PS7-Completion') -DestinationPath $archive -Force
if ($Installer) {
    $compiler = Get-Command ISCC.exe -ErrorAction Stop
    & $compiler.Source "/DModuleVersion=$version" "/DSourceDir=$payload" "/O$dist" (Join-Path $root 'packaging/windows/installer.iss')
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed: $LASTEXITCODE" }
}
Get-FileHash -Algorithm SHA256 -LiteralPath $archive
