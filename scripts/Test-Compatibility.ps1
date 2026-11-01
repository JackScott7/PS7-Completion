#Requires -Version 7.4
[CmdletBinding()]
param(
    [string] $Manifest = (Join-Path $PSScriptRoot '../src/PS7-Completion/PS7-Completion.psd1'),
    [string[]] $Engine = @((Join-Path $PSHOME 'pwsh.exe')),
    [string] $OutputPath = (Join-Path $PSScriptRoot '../dist/compatibility/results.json')
)
$ErrorActionPreference = 'Stop'
$Manifest = (Resolve-Path -LiteralPath $Manifest).Path
$records = foreach ($executable in $Engine) {
    foreach ($scenario in @('MissingExecutables','RepeatedImport','Exclusion')) {
        $json = & $executable -NoLogo -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot 'validation/Compatibility-Probe.ps1') -Manifest $Manifest -Scenario $scenario
        if ($LASTEXITCODE -ne 0) { throw "Compatibility probe failed: $executable / $scenario" }
        $json | ConvertFrom-Json
    }
}
New-Item -ItemType Directory -Path (Split-Path ([IO.Path]::GetFullPath($OutputPath))) -Force | Out-Null
@($records) | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath
$records
