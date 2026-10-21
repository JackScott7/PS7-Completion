# This worker accepts a fixed query kind, never script text from the command line.
param([Parameter(Mandatory)][string] $RequestBase64)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
    $request = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($RequestBase64)) | ConvertFrom-Json -AsHashtable
    $dependencies = @()
    $data = switch ($request.Kind) {
        'Processes' {
            Get-Process | Select-Object -First 4096 | ForEach-Object { @{ Id = [string]$_.Id; Name = $_.ProcessName + '.exe' } }
        }
        'Services' {
            $services = [System.ServiceProcess.ServiceController]::GetServices()
            try { $services | Select-Object -First 4096 -ExpandProperty ServiceName }
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
                while ($queue.Count -and $count -lt 4096) {
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
    @{ Data = @($data); Dependencies = @($dependencies) } | ConvertTo-Json -Depth 8 -Compress
}
catch { exit 1 }
