#Requires -Version 7.4
[CmdletBinding()]
param([ValidateRange(1,100)][int] $ImportSamples = 30, [ValidateRange(1,1000)][int] $CompletionSamples = 100)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$manifest = Join-Path $root 'src/PS7-Completion/PS7-Completion.psd1'
$directory = Join-Path $root ('dist/measurements/' + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$child = Join-Path $directory 'import.ps1'
@'
param([string] $Manifest)
$watch = [Diagnostics.Stopwatch]::StartNew()
Import-Module $Manifest -ErrorAction Stop
$watch.Elapsed.TotalMilliseconds.ToString([Globalization.CultureInfo]::InvariantCulture)
'@ | Set-Content $child
$imports = @(foreach ($i in 1..$ImportSamples) {
    $sample = & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -NonInteractive -File $child $manifest
    if ($LASTEXITCODE -ne 0) { throw 'Import measurement failed.' }
    [double]::Parse($sample, [Globalization.CultureInfo]::InvariantCulture)
})
function Get-Summary([double[]] $Samples) {
    $sorted = @($Samples | Sort-Object)
    @{ Count=$sorted.Count; MedianMs=[Math]::Round($sorted[[int][Math]::Floor($sorted.Count/2)],2); P95Ms=[Math]::Round($sorted[[int][Math]::Ceiling($sorted.Count*0.95)-1],2) }
}
Import-Module $manifest -Force
$warm = @{}
foreach ($line in @('ssh -', 'winget ins', 'schtasks /q', 'sc.exe que', 'taskkill /p')) {
    [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
    $samples = @(foreach ($i in 1..$CompletionSamples) {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
        $watch.Elapsed.TotalMilliseconds
    })
    $warm[$line] = Get-Summary $samples
}
$result = [ordered]@{
    MeasuredAtUtc = [DateTime]::UtcNow.ToString('o')
    PowerShell = $PSVersionTable.PSVersion.ToString()
    OS = $PSVersionTable.OS
    Processor = $env:PROCESSOR_IDENTIFIER
    LogicalProcessors = [Environment]::ProcessorCount
    Import = Get-Summary $imports
    WarmCompletion = $warm
}
$result | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $directory 'results.json')
$result | ConvertTo-Json -Depth 6
