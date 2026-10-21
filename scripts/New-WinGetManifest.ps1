#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string] $BuildMetadata, [Parameter(Mandatory)][string] $OutputDirectory)
$ErrorActionPreference = 'Stop'
$build = Get-Content -LiteralPath $BuildMetadata -Raw | ConvertFrom-Json
if (-not $build.Installer -or -not (Test-Path -LiteralPath $build.Installer)) { throw 'Build metadata must name an existing installer.' }
if ($build.Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid package version.' }
$hash = (Get-FileHash -LiteralPath $build.Installer -Algorithm SHA256).Hash
$template = Get-Content (Join-Path $PSScriptRoot '../packaging/winget/manifest.yaml.template') -Raw
$manifest = $template.Replace('__VERSION__', $build.Version).Replace('__SHA256__', $hash)
if ($manifest -match '__[A-Z_]+__') { throw 'Unresolved manifest placeholder.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$path = Join-Path $OutputDirectory "JackScott7.PS7-Completion.yaml"
Set-Content -LiteralPath $path -Value $manifest -Encoding utf8
$path
