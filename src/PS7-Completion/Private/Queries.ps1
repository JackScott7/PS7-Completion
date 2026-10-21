function Get-PS7DependencyStamp {
    param([string] $Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Ignore
    if ($null -eq $item) { return "$Path|missing" }
    $length = if ($item.PSIsContainer) { -1 } else { $item.Length }
    return "$Path|$length|$($item.LastWriteTimeUtc.Ticks)"
}

function Invoke-PS7QueryProcess {
    param([hashtable] $Request, [int] $TimeoutMilliseconds = 500,
        [string] $WorkerPath = (Join-Path $script:ModuleRoot 'Workers/Query.ps1'))
    if ($TimeoutMilliseconds -le 0) { throw 'Completion query deadline exceeded.' }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $PSHOME 'pwsh.exe'
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [Text.Encoding]::UTF8
    $start.StandardErrorEncoding = [Text.Encoding]::UTF8
    $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($Request | ConvertTo-Json -Compress)))
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $WorkerPath, '-RequestBase64', $payload)) { $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'Cannot start completion query worker.' }
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
        if (-not $process.WaitForExit($remaining)) { throw 'Completion query deadline exceeded.' }
        if ($process.ExitCode -ne 0) { throw 'Completion query worker failed.' }
        $json = $output.GetAwaiter().GetResult()
        if ($errors.GetAwaiter().GetResult()) { throw 'Completion query worker wrote an error.' }
        if ($json.Length -gt 2097152) { throw 'Query output exceeds its size limit.' }
        return ($json | ConvertFrom-Json -AsHashtable -ErrorAction Stop)
    }
    finally {
        if ($process.Id -and -not $process.HasExited) {
            $process.Kill($true)
            # Reap our worker rather than leaving a runaway task after timeout.
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Get-PS7QueryData {
    param([ValidateSet('Processes','Services','Tasks','SshHosts')][string] $Kind, [string] $Path = '')
    $key = "$Kind|$Path"
    $now = [Diagnostics.Stopwatch]::GetTimestamp()
    if ($script:Cache.ContainsKey($key)) {
        $entry = $script:Cache[$key]
        $valid = (($now - $entry.Created) / [Diagnostics.Stopwatch]::Frequency) -lt 30
        if ($valid) {
            foreach ($dependency in $entry.Dependencies) {
                if ((Get-PS7DependencyStamp $dependency.Path) -ne $dependency.Stamp) { $valid = $false; break }
            }
        }
        if ($valid) { return $entry.Data }
        $script:Cache.Remove($key)
    }
    $generation = $script:CacheGeneration
    $remaining = if ($null -ne $script:QueryClock) { 500 - [int]$script:QueryClock.ElapsedMilliseconds } else { 500 }
    $response = Invoke-PS7QueryProcess -Request @{ Kind = $Kind; Path = $Path } -TimeoutMilliseconds $remaining
    if (-not $response.ContainsKey('Data') -or -not $response.ContainsKey('Dependencies')) { throw 'Invalid query response.' }
    $data = @($response.Data | Select-Object -First 4096)
    if ($generation -eq $script:CacheGeneration) {
        if ($script:Cache.Count -ge 128) {
            $oldest = $script:Cache.Keys | Sort-Object { $script:Cache[$_].Created } | Select-Object -First 1
            $script:Cache.Remove($oldest)
        }
        $script:Cache[$key] = @{ Created = [Diagnostics.Stopwatch]::GetTimestamp(); Data = $data; Dependencies = @($response.Dependencies) }
    }
    return $data
}
