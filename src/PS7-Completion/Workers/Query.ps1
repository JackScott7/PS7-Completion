# This worker accepts a fixed query kind, never script text from the command line.
param([Parameter(Mandatory)][string] $RequestBase64)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
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
            try {
                for ($index = 0; $index -lt [Math]::Min(4096, $services.Length); $index++) { $services[$index].ServiceName }
            }
            finally { foreach ($service in $services) { $service.Dispose() } }
        }
        'Tasks' {
            # COM avoids launching schtasks.exe and does not require a task mutation.
            $scheduler = New-Object -ComObject 'Schedule.Service'
            try {
                $scheduler.Connect()
                $queue = [Collections.Generic.Queue[string]]::new()
                $queue.Enqueue('\')
                $count = 0
                $folders = 0
                while ($queue.Count -and $count -lt 4096 -and $folders -lt 4096) {
                    $folders++
                    $folder = $scheduler.GetFolder($queue.Dequeue())
                    try {
                        foreach ($task in $folder.GetTasks(1)) {
                            try { $task.Path; $count++ } finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($task) }
                            if ($count -ge 4096) { break }
                        }
                        foreach ($child in $folder.GetFolders(0)) {
                            try { if ($queue.Count -lt 4096) { $queue.Enqueue($child.Path) } } finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($child) }
                        }
                    }
                    finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($folder) }
                }
            }
            finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($scheduler) }
        }
        default { throw 'Unknown query kind.' }
    }
    $response = @{ Data = @($data); Dependencies = @($dependencies) }
    if ($request.ContainsKey('Measure') -and $request.Measure) {
        $response.Metrics = @{ CollectionMs = $queryClock.Elapsed.TotalMilliseconds }
        $serializationClock = [Diagnostics.Stopwatch]::StartNew()
        $null = $response | ConvertTo-Json -Depth 8 -Compress
        $response.Metrics.SerializationMs = $serializationClock.Elapsed.TotalMilliseconds
    }
    $response | ConvertTo-Json -Depth 8 -Compress
}
catch { exit 1 }
