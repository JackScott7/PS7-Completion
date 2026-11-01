function Get-PS7ServiceValue {
    param([object[]] $Services)
    try {
        for ($index = 0; $index -lt [Math]::Min(4096, $Services.Length); $index++) {
            try {
                $name = $Services[$index].ServiceName
                if ($null -ne $name -and $name.Length -gt 0) { $name }
            }
            catch { continue }
        }
    }
    finally { foreach ($service in $Services) { $service.Dispose() } }
}

function Close-PS7TaskObject {
    param($Object)
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($Object)
}

function Get-PS7TaskValue {
    param($Scheduler)
    $queue = [Collections.Generic.Queue[string]]::new()
    $queue.Enqueue('\')
    $count = 0
    $folders = 0
    while ($queue.Count -and $count -lt 4096 -and $folders -lt 4096) {
        $folders++
        $folder = $Scheduler.GetFolder($queue.Dequeue())
        try {
            foreach ($task in $folder.GetTasks(1)) {
                try { $task.Path; $count++ } finally { Close-PS7TaskObject $task }
                if ($count -ge 4096) { break }
            }
            foreach ($child in $folder.GetFolders(0)) {
                try { if ($queue.Count -lt 4096) { $queue.Enqueue($child.Path) } }
                finally { Close-PS7TaskObject $child }
            }
        }
        finally { Close-PS7TaskObject $folder }
    }
}
