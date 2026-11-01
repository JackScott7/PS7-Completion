# This worker accepts a fixed query kind, never script text from the command line.
param([Parameter(Mandatory)][string] $RequestBase64)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'Collectors.ps1')
try {
    $request = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($RequestBase64)) | ConvertFrom-Json -AsHashtable
    $queryClock = [Diagnostics.Stopwatch]::StartNew()
    $dependencies = @()
    $data = switch ($request.Kind) {
        'Processes' {
            $processes = [Diagnostics.Process]::GetProcesses()
            try {
                $count = 0
                foreach ($process in $processes) {
                    if ($count -ge 4096) { break }
                    # A process may exit between enumeration and reading its name.
                    try { @{ Id = [string]$process.Id; Name = $process.ProcessName + '.exe' }; $count++ }
                    catch { continue }
                }
            }
            finally { foreach ($process in $processes) { $process.Dispose() } }
        }
        'Services' {
            $services = [System.ServiceProcess.ServiceController]::GetServices()
            Get-PS7ServiceValue -Services $services
        }
        'Tasks' {
            # COM avoids launching schtasks.exe and does not require a task mutation.
            $scheduler = New-Object -ComObject 'Schedule.Service'
            try {
                $scheduler.Connect()
                Get-PS7TaskValue -Scheduler $scheduler
            }
            finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($scheduler) }
        }
        default { throw 'Unknown query kind.' }
    }
    $response = @{ Data = @($data); Dependencies = @($dependencies) }
    if ($request.ContainsKey('Measure') -and $request.Measure) {
        $currentProcess = [Diagnostics.Process]::GetCurrentProcess()
        try {
            $response.Metrics = @{ CollectionMs = $queryClock.Elapsed.TotalMilliseconds;
                WorkerPeakWorkingSetBytes = $currentProcess.PeakWorkingSet64 }
        }
        finally { $currentProcess.Dispose() }
        $serializationClock = [Diagnostics.Stopwatch]::StartNew()
        $null = $response | ConvertTo-Json -Depth 8 -Compress
        $response.Metrics.SerializationMs = $serializationClock.Elapsed.TotalMilliseconds
    }
    $response | ConvertTo-Json -Depth 8 -Compress
}
catch { exit 1 }
