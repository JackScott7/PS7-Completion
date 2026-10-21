#Requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module Pester -MinimumVersion 5.7.1 -ErrorAction Stop
Import-Module PSScriptAnalyzer -MinimumVersion 1.24.0 -ErrorAction Stop
$issues = @(foreach ($folder in @('src','scripts')) { Invoke-ScriptAnalyzer -Path (Join-Path $root $folder) -Recurse -Severity Warning,Error })
if ($issues.Count) {
    $issues | Format-Table -AutoSize | Out-Host
    throw 'Script analysis failed.'
}
$result = Invoke-Pester -Path (Join-Path $root 'tests') -PassThru -Output Detailed
if ($result.Result -ne 'Passed' -or $result.TotalCount -eq 0) { throw 'Pester validation failed.' }
