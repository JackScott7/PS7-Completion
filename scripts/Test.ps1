#Requires -Version 7.4
[CmdletBinding()]
param([switch] $SkipAnalyzer, [switch] $Coverage)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module Pester -MinimumVersion 5.7.1 -ErrorAction Stop
if (-not $SkipAnalyzer) {
    Import-Module PSScriptAnalyzer -MinimumVersion 1.24.0 -ErrorAction Stop
    $issues = @(foreach ($folder in @('src','scripts')) { Invoke-ScriptAnalyzer -Path (Join-Path $root $folder) -Recurse -Severity Warning,Error })
    if ($issues.Count) {
        $issues | Format-Table -AutoSize | Out-Host
        throw 'Script analysis failed.'
    }
}
$configuration = New-PesterConfiguration
$configuration.Run.Path = Join-Path $root 'tests'
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = 'Detailed'
if ($Coverage) {
    $reportRoot = Join-Path $root 'dist/coverage'
    New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = Join-Path $root 'src/PS7-Completion/Completions/*.ps1'
    $configuration.CodeCoverage.OutputPath = Join-Path $reportRoot 'coverage.xml'
    $configuration.CodeCoverage.CoveragePercentTarget = 0
}
$result = Invoke-Pester -Configuration $configuration
if ($Coverage) {
    $registry = Import-PowerShellDataFile (Join-Path $root 'src/PS7-Completion/Registry.psd1')
    $rows = foreach ($name in ($registry.Keys | Sort-Object)) {
        $path = [IO.Path]::GetFullPath((Join-Path $root "src/PS7-Completion/$($registry[$name].File)"))
        $hit = @($result.CodeCoverage.CommandsExecuted | Where-Object File -EQ $path).Count
        $missed = @($result.CodeCoverage.CommandsMissed | Where-Object File -EQ $path).Count
        [pscustomobject]@{ Provider=$name; Executed=$hit; Missed=$missed; Percent=if ($hit + $missed) { [Math]::Round(100 * $hit / ($hit + $missed),2) } else { 0 } }
    }
    $rows | ConvertTo-Json | Set-Content (Join-Path $reportRoot 'providers.json')
    $rows | Format-Table | Out-Host
    if (@($rows | Where-Object Executed -EQ 0).Count) { throw 'A bundled provider has no measured coverage.' }
}
if ($result.Result -ne 'Passed' -or $result.TotalCount -eq 0) { throw 'Pester validation failed.' }
