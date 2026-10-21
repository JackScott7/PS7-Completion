#Requires -Version 7.4
[CmdletBinding()]
param(
    [switch] $Installer,
    [string] $CompilerPath,
    [ValidatePattern('^\d+\.\d+\.\d+$')][string] $Version
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'src/PS7-Completion'
$manifest = Test-ModuleManifest (Join-Path $source 'PS7-Completion.psd1')
$releaseVersion = if ($Version) { $Version } else { $manifest.Version.ToString() }
$dist = Join-Path $root 'dist'
# Unique staging avoids stale payload files without deleting previous artifacts.
$stage = Join-Path $dist ('builds/' + [guid]::NewGuid().ToString())
$payload = Join-Path $stage "payload/PS7-Completion/$releaseVersion"
New-Item -ItemType Directory -Path $payload -Force | Out-Null
Copy-Item -Path "$source/*" -Destination $payload -Recurse
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination $payload
if ($Version) {
    $manifestPath = Join-Path $payload 'PS7-Completion.psd1'
    $manifestText = Get-Content -LiteralPath $manifestPath -Raw
    $manifestText = [regex]::Replace($manifestText, "(?m)^(\s*ModuleVersion\s*=\s*)'[^']*'", { param($match) $match.Groups[1].Value + "'$Version'" })
    Set-Content -LiteralPath $manifestPath -Value $manifestText -Encoding utf8
}
$payloadManifest = Test-ModuleManifest (Join-Path $payload 'PS7-Completion.psd1')
if ($payloadManifest.Version.ToString() -ne $releaseVersion) { throw 'Payload version mismatch.' }
if ((Get-Content (Join-Path $payload 'LICENSE') -Raw) -notmatch '^MIT License') { throw 'A distribution license is required.' }
$archive = Join-Path $stage "PS7-Completion-$releaseVersion.zip"
Compress-Archive -Path (Join-Path $stage 'payload/PS7-Completion') -DestinationPath $archive -Force
$installerPath = $null
if ($Installer) {
    if (-not $CompilerPath) { $CompilerPath = (Get-Command ISCC.exe -ErrorAction Stop).Source }
    & $CompilerPath "/DModuleVersion=$releaseVersion" "/DSourceDir=$payload" "/O$stage" (Join-Path $root 'packaging/windows/installer.iss') | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed: $LASTEXITCODE" }
    $installerPath = Join-Path $stage "PS7-Completion-$releaseVersion-windows-x64.exe"
    if (-not (Test-Path -LiteralPath $installerPath)) { throw 'Installer artifact missing.' }
}
$assets = @($archive)
if ($installerPath) { $assets += $installerPath }
$hashes = @($assets | Get-FileHash -Algorithm SHA256)
$checksumPath = Join-Path $stage 'SHA256SUMS.txt'
$hashes | ForEach-Object { '{0}  {1}' -f $_.Hash.ToLowerInvariant(), (Split-Path $_.Path -Leaf) } | Set-Content $checksumPath
$result = [pscustomobject]@{ Version = $releaseVersion; Archive = $archive; Installer = $installerPath; Checksums = $checksumPath; Payload = $payload; Assets = @($assets) + $checksumPath }
$result | ConvertTo-Json | Set-Content (Join-Path $dist 'latest-build.json')
$result
