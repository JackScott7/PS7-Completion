#Requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$manifest = Test-ModuleManifest (Join-Path $root 'src/PS7-Completion/PS7-Completion.psd1')
$version = $manifest.Version.ToString()
$changelog = Get-Content -LiteralPath (Join-Path $root 'CHANGELOG.md') -Raw
$heading = '(?m)^## ' + [regex]::Escape($version) + ' - [^\r\n]+\r?$'
if ([regex]::Matches($changelog, $heading).Count -ne 1) {
    throw "CHANGELOG.md must contain exactly one entry for $version."
}
$section = [regex]::Match($changelog, '(?ms)^## ' + [regex]::Escape($version) + ' - [^\r\n]+\r?\n(.*?)(?=^## |\z)').Groups[1].Value
foreach ($category in @('Added','Changed','Fixed')) {
    $content = [regex]::Match($section, '(?ms)^### ' + $category + '\s*\r?\n(.*?)(?=^### |\z)').Groups[1].Value
    if ($content -notmatch '(?m)^- .+') { throw "The $version changelog needs a $category entry." }
}
$paths = @(& git -C $root ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or -not $paths.Count) { throw 'Cannot inspect tracked project files.' }
$emDash = [char]0x2014
foreach ($relativePath in $paths) {
    if ($relativePath -notmatch '\.(md|ps1|psm1|psd1|iss|ya?ml|txt|template)$') { continue }
    $path = Join-Path $root $relativePath
    if ([IO.File]::ReadAllText($path).Contains($emDash)) { throw "Em dash in tracked project text: $relativePath" }
}
"Release metadata valid for $version."
