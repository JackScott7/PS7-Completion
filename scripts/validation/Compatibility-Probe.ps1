#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string] $Manifest,
    [Parameter(Mandatory)][ValidateSet('MissingExecutables','RepeatedImport','Exclusion')][string] $Scenario)
$ErrorActionPreference = 'Stop'
function Get-CompletionMatch([string] $Line) {
    @([Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null).CompletionMatches)
}
if ($Scenario -eq 'Exclusion') {
    Register-ArgumentCompleter -Native -CommandName ssh -ScriptBlock {
        [Management.Automation.CompletionResult]::new('sentinel','sentinel','ParameterValue','fixture')
    }
    Import-Module $Manifest -ArgumentList @{ Exclude=@('ssh') }
    if ('sentinel' -notin (Get-CompletionMatch 'ssh se').CompletionText) { throw 'Excluded callback was replaced.' }
}
else {
    if ($Scenario -eq 'MissingExecutables') { $env:PATH = '' }
    Import-Module $Manifest
    $registry = Import-PowerShellDataFile (Join-Path (Split-Path $Manifest) 'Registry.psd1')
    foreach ($name in $registry.Keys) {
        foreach ($command in $registry[$name].Commands) {
            $prefix = if ($name -eq 'services') { 'q' } elseif ($name -in 'schtasks','taskkill','ipconfig') { '/' } else { '-' }
            $completionMatches = Get-CompletionMatch "$command $prefix"
            if (-not $completionMatches.Count -or @($completionMatches | Where-Object { $_ -isnot [Management.Automation.CompletionResult] }).Count) {
                throw "Invalid static results: $name / $command"
            }
        }
    }
    if ($Scenario -eq 'RepeatedImport') {
        $before = @((Get-CompletionMatch 'winget ins').CompletionText)
        foreach ($iteration in 1..3) {
            Import-Module $Manifest -Force
            $after = @((Get-CompletionMatch 'winget ins').CompletionText)
            if (@(Compare-Object $before $after).Count) { throw 'Repeated import changed static results.' }
        }
    }
    if (@(Get-PS7CompletionProvider | Where-Object Status -EQ Failed).Count) { throw 'Provider failed.' }
}
@{ Scenario=$Scenario; Result='Passed'; PowerShell=$PSVersionTable.PSVersion.ToString(); OS=$PSVersionTable.OS;
    ManifestVersion=(Import-PowerShellDataFile $Manifest).ModuleVersion } | ConvertTo-Json -Compress
