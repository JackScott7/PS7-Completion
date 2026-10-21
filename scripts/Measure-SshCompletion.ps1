#Requires -Version 7.4
[CmdletBinding()]
param([ValidateRange(3,100)][int] $Samples = 7)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$manifest = Join-Path $root 'src/PS7-Completion/PS7-Completion.psd1'
$times = @()
foreach ($sample in 1..$Samples) {
    # A fresh shell gives every sample an empty module cache and unloaded provider.
    $script = @'
param([string] $Manifest)
Import-Module $Manifest -ErrorAction Stop
$line = 'ssh s'
$watch = [Diagnostics.Stopwatch]::StartNew()
$matches = [Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null).CompletionMatches
$watch.Stop()
if (-not $matches) { throw 'SSH completion produced no matches.' }
$watch.Elapsed.TotalMilliseconds.ToString([Globalization.CultureInfo]::InvariantCulture)
'@
    $path = Join-Path $root ('dist/measurements/ssh-' + [guid]::NewGuid().ToString() + '.ps1')
    New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
    try {
        [IO.File]::WriteAllText($path, $script)
        $output = & (Join-Path $PSHOME 'pwsh.exe') -NoLogo -NoProfile -NonInteractive -File $path $manifest
        if ($LASTEXITCODE -ne 0) { throw 'SSH completion measurement failed.' }
        $times += [double]::Parse($output, [Globalization.CultureInfo]::InvariantCulture)
    }
    finally { Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue }
}
$sorted = @($times | Sort-Object)
[pscustomobject]@{
    Samples = $Samples
    MedianMs = [Math]::Round($sorted[[int][Math]::Floor($Samples / 2)], 2)
    P95Ms = [Math]::Round($sorted[[int][Math]::Ceiling($Samples * 0.95) - 1], 2)
    Milliseconds = $times
}
