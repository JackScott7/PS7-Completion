#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Baseline,
    [Parameter(Mandatory)][string] $Current,
    [ValidateRange(0,1000)][double] $MaxRegressionPercent = 25,
    [ValidateRange(0,10000)][double] $MinRegressionMs = 5,
    [switch] $EnforceTiming,
    [string] $OutputPath
)
$ErrorActionPreference = 'Stop'
$before = Get-Content -LiteralPath $Baseline -Raw | ConvertFrom-Json -AsHashtable
$after = Get-Content -LiteralPath $Current -Raw | ConvertFrom-Json -AsHashtable
if ($before.SchemaVersion -ne 1 -or $after.SchemaVersion -ne 1) { throw 'Unsupported benchmark schema.' }
foreach ($key in @('Machine','PowerShell','OS','Processor','LogicalProcessors')) {
    if ($before.Environment[$key] -ne $after.Environment[$key]) { throw "Different benchmark environment: $key" }
}
foreach ($key in @('ColdSamples','WarmSamples','LiveQueries')) {
    if ($before.Parameters[$key] -ne $after.Parameters[$key]) { throw "Different benchmark protocol: $key" }
}
function Get-MetricMap([hashtable] $Report) {
    $metrics = @{ Import=@{Timing=$Report.Import}; ShellStartup=@{Timing=$Report.ShellStartup}; ResultFormatting=$Report.ResultFormatting }
    foreach ($section in @('FirstCompletion','WarmCompletion','Routing','Queries')) {
        foreach ($key in $Report[$section].Keys) { $metrics["$section/$key"] = $Report[$section][$key] }
    }
    $metrics
}
$old = Get-MetricMap $before; $new = Get-MetricMap $after
if (@(Compare-Object @($old.Keys) @($new.Keys)).Count) { throw 'Different benchmark case inventory.' }
$correctness = [Collections.Generic.List[string]]::new()
$regressions = [Collections.Generic.List[string]]::new()
$comparisons = foreach ($key in ($old.Keys | Sort-Object)) {
    $a = $old[$key]; $b = $new[$key]
    if ($b.ContainsKey('Failures') -and $b.Failures -gt 0) { $correctness.Add("$key has failed samples") }
    if ($b.ContainsKey('CachePrimed') -and -not $b.CachePrimed) { $correctness.Add("$key was not a cache hit") }
    if ($b.ContainsKey('ResultCounts') -and -not $key.StartsWith('Queries/')) {
        if (@($b.ResultCounts | Where-Object { $_ -le 0 }).Count) { $correctness.Add("$key returned no results") }
        if (@(Compare-Object @($a.ResultCounts | Sort-Object -Unique) @($b.ResultCounts | Sort-Object -Unique)).Count) {
            $correctness.Add("$key changed result counts")
        }
    }
    $limit = [Math]::Max($a.Timing.P95Ms * (1 + $MaxRegressionPercent / 100), $a.Timing.P95Ms + $MinRegressionMs)
    $regressed = $b.Timing.P95Ms -gt $limit
    if ($regressed) { $regressions.Add($key) }
    [pscustomobject]@{ Case=$key; BeforeP95Ms=$a.Timing.P95Ms; AfterP95Ms=$b.Timing.P95Ms; LimitMs=$limit; Regressed=$regressed }
}
if ($after.FailedProviders.Count) { $correctness.Add('One or more providers failed') }
$result = [pscustomobject]@{ CorrectnessFailures=$correctness.ToArray(); TimingRegressions=$regressions.ToArray(); Comparisons=@($comparisons) }
if ($OutputPath) { $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath }
if ($correctness.Count) { throw ($correctness -join '; ') }
if ($EnforceTiming -and $regressions.Count) { throw ('Performance regressions: ' + ($regressions -join ', ')) }
$result
