#Requires -Version 7.4
[CmdletBinding()]
param(
    [string] $Manifest = (Join-Path $PSScriptRoot '../src/PS7-Completion/PS7-Completion.psd1'),
    [ValidateRange(1,100)][int] $ColdSamples = 5,
    [ValidateRange(1,1000)][int] $WarmSamples = 30,
    [switch] $LiveQueries,
    [string] $OutputPath = (Join-Path $PSScriptRoot '../dist/performance/results.json')
)
$ErrorActionPreference = 'Stop'
$Manifest = (Resolve-Path -LiteralPath $Manifest).Path
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Path (Split-Path $OutputPath) -Force | Out-Null
function Get-Distribution([double[]] $Values) {
    $sorted = @($Values | Sort-Object)
    $middle = [int][Math]::Floor($sorted.Count / 2)
    $median = if ($sorted.Count % 2) { $sorted[$middle] } else { ($sorted[$middle - 1] + $sorted[$middle]) / 2 }
    @{ Samples=$Values; Count=$Values.Count; MedianMs=[Math]::Round($median,3);
        P95Ms=[Math]::Round($sorted[[int][Math]::Ceiling($sorted.Count * 0.95)-1],3) }
}
function Measure-Operation([scriptblock] $Operation, [int] $Samples) {
    $times = @(); $counts = @(); $failures = 0; $timeouts = 0
    foreach ($sample in 1..$Samples) {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        try { $values = @(& $Operation); $counts += $values.Count }
        catch { $failures++; if ($_.Exception.Message -match 'deadline|timeout') { $timeouts++ }; $counts += 0 }
        $times += $watch.Elapsed.TotalMilliseconds
    }
    @{ Timing=(Get-Distribution $times); ResultCounts=$counts; Failures=$failures; Timeouts=$timeouts }
}
$cases = [ordered]@{
    ssh='ssh -'; winget='winget ins'; schtasks='schtasks /q'; services='sc.exe que'; taskkill='taskkill /p'
    git='git sta'; gh='gh pr '; ripgrep='rg --col'; jq='jq --'; pip='pip ins'; python='python --'
    uv='uv pip '; flask='flask run --'; fastapi='fastapi dev --'; tailscale='tailscale --'
    node='node --'; npm='npm ins'; sqlite3='sqlite3 -'; ffmpeg='ffmpeg -'; rustc='rustc --'
    rustup='rustup '; nano='nano --'; ping='ping -'; uvx='uvx --'; uvicorn='uvicorn --'
    twine='twine '; ruff='ruff '; ipconfig='ipconfig /'; tracert='tracert -'; netstat='netstat -'
    curl='curl.exe --'; cargo='cargo '; docker='docker '; nslookup='nslookup -'
}
$startup = @(); $imports = @(); $first = @{}
$sampleScript = Join-Path $PSScriptRoot 'performance/Invoke-Sample.ps1'
$engine = Join-Path $PSHOME 'pwsh.exe'
foreach ($sample in 1..$ColdSamples) {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $ready = & $engine -NoLogo -NoProfile -NonInteractive -File $sampleScript -Manifest $Manifest -StartupOnly
    if ($LASTEXITCODE -ne 0 -or $ready -ne 'ready') { throw 'Startup probe failed.' }
    $startup += $watch.Elapsed.TotalMilliseconds
    foreach ($name in $cases.Keys) {
        $output = & $engine -NoLogo -NoProfile -NonInteractive -File $sampleScript -Manifest $Manifest -Line $cases[$name]
        if ($LASTEXITCODE -ne 0) { throw "Fresh-process probe failed: $name" }
        $record = $output | ConvertFrom-Json
        $imports += $record.ImportMs
        if (-not $first.ContainsKey($name)) { $first[$name] = @() }
        $first[$name] += $record
    }
}
Get-Module PS7-Completion | Remove-Module -Force
Import-Module $Manifest -Force
$module = Get-Module PS7-Completion
$registered = @(Get-PS7CompletionProvider | Where-Object Source -EQ BuiltIn | ForEach-Object Name)
if (@(Compare-Object $registered @($cases.Keys)).Count) { throw 'Benchmark cases must cover every bundled provider.' }
$warm = @{}; $cold = @{}
foreach ($name in $cases.Keys) {
    $line = $cases[$name]
    [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
    $warm[$name] = Measure-Operation { [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches } $WarmSamples
    $cold[$name] = @{ Timing=(Get-Distribution @($first[$name] | ForEach-Object FirstMs));
        ResultCounts=@($first[$name] | ForEach-Object Count);
        Failures=(@($first[$name] | ForEach-Object FailedProviders) | Measure-Object -Sum).Sum }
}
Register-PS7CompletionProvider -Name perfscript -CommandName perfscript.py -ScriptBlock {
    param($context)
    if ($context.ArgumentIndex -eq 0) { New-PS7CompletionResult -Candidate add -WordToComplete $context.WordToComplete }
}
$routing = @{}
foreach ($line in @('perfscript.py a','python perfscript.py a','pip ins','python -m pip ins')) {
    [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
    $routing[$line] = Measure-Operation { [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches } $WarmSamples
}
$fixture = Join-Path (Split-Path $OutputPath) 'ssh-config'
1..200 | ForEach-Object { 'Host perf-{0:d4}' -f $_ } | Set-Content -LiteralPath $fixture
$queries = @{}
$kinds = @('SshHosts'); if ($LiveQueries) { $kinds += @('Processes','Services','Tasks') }
foreach ($kind in $kinds) {
    $path = if ($kind -eq 'SshHosts') { $fixture } else { '' }
    $queries["$kind/miss"] = Measure-Operation {
        Clear-PS7CompletionCache
        & $module { param($k,$p) Get-PS7QueryData -Kind $k -Path $p } $kind $path
    } $ColdSamples
    $primed = & $module { $script:Cache.Count -gt 0 }
    $queries["$kind/hit"] = Measure-Operation {
        & $module { param($k,$p) Get-PS7QueryData -Kind $k -Path $p } $kind $path
    } $WarmSamples
    $queries["$kind/hit"].CachePrimed = $primed
}
$candidates = @(1..4096 | ForEach-Object { 'value-{0:d5}' -f $_ })
$formatting = Measure-Operation { New-PS7CompletionResult -Candidate $candidates -WordToComplete 'value-03' } $WarmSamples
$worker = @{}
if ($LiveQueries) {
    $probe = Join-Path (Split-Path $OutputPath) 'worker-probe.ps1'
    'param([string] $RequestBase64); ''{"Data":[],"Dependencies":[]}''' | Set-Content -LiteralPath $probe
    $worker.Startup = Measure-Operation {
        & $module { param($p) Invoke-PS7QueryProcess -Request @{} -WorkerPath $p } $probe
    } $ColdSamples
    foreach ($kind in @('Processes','Services','Tasks')) {
        $details = @()
        foreach ($sample in 1..$ColdSamples) {
            try {
                $response = & $module { param($k) Invoke-PS7QueryProcess -Request @{ Kind=$k; Measure=$true } } $kind
                $details += @{ Success=$true; Count=@($response.Data).Count;
                    Metrics=if ($response.ContainsKey('Metrics')) { $response.Metrics } else { $null } }
            }
            catch { $details += @{ Success=$false; Timeout=($_.Exception.Message -match 'deadline|timeout') } }
        }
        $worker[$kind] = $details
    }
}
$report = [ordered]@{
    SchemaVersion=1; MeasuredAtUtc=[DateTime]::UtcNow.ToString('o'); Manifest=$Manifest
    Environment=@{ PowerShell=$PSVersionTable.PSVersion.ToString(); OS=$PSVersionTable.OS;
        Processor=$env:PROCESSOR_IDENTIFIER; LogicalProcessors=[Environment]::ProcessorCount; Machine=[Environment]::MachineName }
    Parameters=@{ ColdSamples=$ColdSamples; WarmSamples=$WarmSamples; LiveQueries=[bool]$LiveQueries }
    ShellStartup=(Get-Distribution $startup); Import=(Get-Distribution $imports)
    FirstCompletion=$cold; WarmCompletion=$warm; Routing=$routing; Queries=$queries; ResultFormatting=$formatting; Worker=$worker
    FailedProviders=@(Get-PS7CompletionProvider | Where-Object Status -EQ Failed | ForEach-Object Name)
}
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputPath
Write-Output $OutputPath
