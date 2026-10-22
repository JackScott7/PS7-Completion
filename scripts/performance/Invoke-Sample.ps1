#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string] $Manifest, [string] $Line = '', [switch] $StartupOnly)
$ErrorActionPreference = 'Stop'
if ($StartupOnly) { 'ready'; return }
$clock = [Diagnostics.Stopwatch]::StartNew()
Import-Module $Manifest -ErrorAction Stop
$importMs = $clock.Elapsed.TotalMilliseconds
$completionMatches = @()
$firstMs = 0.0
if ($Line) {
    $clock.Restart()
    $completionMatches = @([Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null).CompletionMatches)
    $firstMs = $clock.Elapsed.TotalMilliseconds
}
@{ ImportMs=$importMs; FirstMs=$firstMs; Count=$completionMatches.Count;
    FailedProviders=@(Get-PS7CompletionProvider | Where-Object Status -EQ Failed).Count } | ConvertTo-Json -Compress
