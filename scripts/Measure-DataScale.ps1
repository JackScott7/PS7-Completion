#Requires -Version 7.4
[CmdletBinding()]
param([string] $OutputDirectory = (Join-Path $PSScriptRoot '../dist/scale'))
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
Import-Module (Join-Path $PSScriptRoot '../src/PS7-Completion/PS7-Completion.psd1') -Force
$module = Get-Module PS7-Completion
$records = foreach ($kind in @('Processes','Services','Tasks')) {
    & $module {
        param($Kind)
        $original = ${function:Invoke-PS7QueryProcess}
        try {
            # Exercise cache normalization using synthetic snapshots, without
            # enumerating personal system data or changing the production worker.
            $script:ScaleFixture = @(foreach ($i in 1..10000) {
                if ($Kind -eq 'Processes') { @{ Id=[string]$i; Name="fixture$i.exe" } }
                elseif ($Kind -eq 'Tasks') { "\folder$i\fixture task" }
                else { "fixture-service$i" }
            })
            function Invoke-PS7QueryProcess { @{ Data=$script:ScaleFixture; Dependencies=@() } }
            Clear-PS7CompletionCache
            $before = [GC]::GetTotalMemory($true)
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $data = @(Get-PS7QueryData $Kind)
            $elapsed = $clock.Elapsed.TotalMilliseconds
            $retained = [GC]::GetTotalMemory($true) - $before
            $strings = if ($Kind -eq 'Processes') { @($data | ForEach-Object Name) } else { $data }
            $results = @(New-PS7CompletionResult -Candidate $strings)
            if ($data.Count -ne 4096 -or $results.Count -ne 512) { throw 'Scale count regression.' }
            @{ Kind=$Kind; Source='SyntheticSnapshot'; InputCount=10000; CachedCount=$data.Count;
                ResultCount=$results.Count; CollectionMs=$elapsed; ManagedMemoryDeltaBytes=$retained }
        }
        finally {
            Set-Item Function:Invoke-PS7QueryProcess $original
            Remove-Variable ScaleFixture -Scope Script
            Clear-PS7CompletionCache
        }
    } $kind
}
$fixtureDirectory = Join-Path $OutputDirectory ([guid]::NewGuid().ToString())
New-Item -ItemType Directory $fixtureDirectory | Out-Null
$rootConfig = Join-Path $fixtureDirectory 'config'
$includes = foreach ($index in 1..24) {
    $child = Join-Path $fixtureDirectory "child$index"
    1..100 | ForEach-Object { "Host fixture-$index-$_" } | Set-Content $child
    'Include "' + [IO.Path]::GetFullPath($child) + '"'
}
Set-Content $rootConfig $includes
$before = [GC]::GetTotalMemory($true)
$clock = [Diagnostics.Stopwatch]::StartNew()
$hosts = @(& $module { param($Path) Get-PS7QueryData SshHosts $Path } ([IO.Path]::GetFullPath($rootConfig)))
$elapsed = $clock.Elapsed.TotalMilliseconds
$retained = [GC]::GetTotalMemory($true) - $before
if ($hosts.Count -ne 2400) { throw 'SSH scale count regression.' }
$records += @{ Kind='SshHosts'; Source='SyntheticFiles'; InputCount=2400; Files=25;
    CachedCount=$hosts.Count; CollectionMs=$elapsed; ManagedMemoryDeltaBytes=$retained }
@{ PowerShell=$PSVersionTable.PSVersion.ToString(); OS=$PSVersionTable.OS; Cases=@($records);
    MemoryMetric='Managed heap delta after collection; not a peak-memory limit or live collector measurement.' } |
    ConvertTo-Json -Depth 6 | Set-Content (Join-Path $OutputDirectory 'results.json')
$records
