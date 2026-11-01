function Read-PS7SshConfig {
    param([string] $Path, [Diagnostics.Stopwatch] $Clock)
    # The worker replaces this trampoline in module scope. Static completion and
    # import never parse or load the SSH traversal implementation.
    . (Join-Path $script:ModuleRoot 'Workers/SshConfig.ps1')
    Read-PS7SshConfig -Path $Path -Clock $Clock
}

function Get-PS7DependencyStamp {
    param([string] $Path, $Item)
    if (-not $PSBoundParameters.ContainsKey('Item')) { $item = Get-Item -LiteralPath $Path -Force -ErrorAction Ignore }
    if ($null -eq $item) { return "$Path|missing" }
    $length = if ($item.PSIsContainer) { -1 } else { $item.Length }
    return "$Path|$length|$($item.LastWriteTimeUtc.Ticks)|$($item.Attributes)|$($item.LinkTarget)"
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
    $started = $false
    try {
        if (-not $process.Start()) { throw 'Cannot start completion query worker.' }
        $started = $true
        # Fixed buffers bound both redirected streams while the worker runs.
        # Reading one extra character lets us reject oversized output before it
        # can accumulate in the parent process or block a full pipe.
        $outputBuffer = [char[]]::new(2097153)
        $errorBuffer = [char[]]::new(4097)
        $output = $process.StandardOutput.ReadBlockAsync($outputBuffer, 0, $outputBuffer.Length)
        $errors = $process.StandardError.ReadBlockAsync($errorBuffer, 0, $errorBuffer.Length)
        while (-not $process.HasExited -or -not $output.IsCompleted -or -not $errors.IsCompleted) {
            if ($output.IsCompleted -and $output.GetAwaiter().GetResult() -ge $outputBuffer.Length) { throw 'Query output exceeds its size limit.' }
            if ($errors.IsCompleted -and $errors.GetAwaiter().GetResult() -ge $errorBuffer.Length) { throw 'Query error output exceeds its size limit.' }
            $remaining = $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds
            if ($remaining -le 0) { throw 'Completion query deadline exceeded.' }
            if (-not $process.HasExited) {
                $process.Refresh()
                if ($process.PrivateMemorySize64 -gt 268435456) { throw 'Completion query worker memory limit exceeded.' }
            }
            if ($process.HasExited) { [Threading.Thread]::Sleep([Math]::Min(10, $remaining)) }
            else { [void]$process.WaitForExit([Math]::Min(10, $remaining)) }
        }
        if ($process.ExitCode -ne 0) { throw 'Completion query worker failed.' }
        $outputLength = $output.GetAwaiter().GetResult()
        $errorLength = $errors.GetAwaiter().GetResult()
        if ($outputLength -ge $outputBuffer.Length) { throw 'Query output exceeds its size limit.' }
        if ($errorLength -gt 0) { throw 'Completion query worker wrote an error.' }
        $json = [string]::new($outputBuffer, 0, $outputLength)
        $parseClock = [Diagnostics.Stopwatch]::StartNew()
        $response = $json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        if ($Request.ContainsKey('Measure') -and $Request.Measure -and $response.ContainsKey('Metrics')) {
            $response.Metrics.ParseMs = $parseClock.Elapsed.TotalMilliseconds
            $response.Metrics.TotalMs = $clock.Elapsed.TotalMilliseconds
        }
        return $response
    }
    finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill($true)
            # Reap our worker rather than leaving a runaway task after timeout.
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Get-PS7QueryData {
    param([ValidateSet('Processes','Services','Tasks','SshHosts')][string] $Kind, [string] $Path = '')
    if ($Kind -eq 'SshHosts' -and $Path) {
        $Path = [IO.Path]::GetFullPath($Path, $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path)
    }
    $key = "$Kind|$Path"
    $now = [Diagnostics.Stopwatch]::GetTimestamp()
    if ($script:Cache.ContainsKey($key)) {
        $entry = $script:Cache[$key]
        $valid = (($now - $entry.Created) / [Diagnostics.Stopwatch]::Frequency) -lt 30
        if ($valid) {
            foreach ($dependency in $entry.Dependencies) {
                if ($null -ne $script:QueryClock -and $script:QueryClock.ElapsedMilliseconds -ge 500) { throw 'Completion query deadline exceeded.' }
                if ((Get-PS7DependencyStamp $dependency.Path) -ne $dependency.Stamp) { $valid = $false; break }
            }
        }
        if ($valid) { return $entry.Data }
        $script:Cache.Remove($key)
    }
    $generation = $script:CacheGeneration
    if ($Kind -eq 'SshHosts') {
        $deadline = if ($null -ne $script:QueryClock) { $script:QueryClock } else { [Diagnostics.Stopwatch]::StartNew() }
        $result = Read-PS7SshConfig -Path $Path -Clock $deadline
        $response = @{ Data = $result.Hosts; Dependencies = $result.Dependencies }
    }
    else {
        $remaining = if ($null -ne $script:QueryClock) { 500 - [int]$script:QueryClock.ElapsedMilliseconds } else { 500 }
        $response = Invoke-PS7QueryProcess -Request @{ Kind = $Kind; Path = $Path } -TimeoutMilliseconds $remaining
    }
    if (-not $response.ContainsKey('Data') -or -not $response.ContainsKey('Dependencies')) { throw 'Invalid query response.' }
    # Bound retained values independently of the source and discard exact
    # duplicates before they consume the cache/result budget. Preserve case.
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $values = [Collections.Generic.List[object]]::new()
    $characters = 0
    foreach ($value in $response.Data) {
        if ($values.Count -ge 4096) { break }
        if ($null -eq $value) { continue }
        $identity = if ($Kind -eq 'Processes') { "$($value.Id)|$($value.Name)" } else { [string]$value }
        if (-not $identity -or $identity.Length -gt 32768) { continue }
        if ($characters + $identity.Length -gt 1048576) { break }
        if ($seen.Add($identity)) { $values.Add($value); $characters += $identity.Length }
    }
    $data = $values.ToArray()
    # A file may change after the parser captured its stamp. Do not cache that
    # inconsistent snapshot; the next request must collect fresh data.
    $stable = $true
    foreach ($dependency in $response.Dependencies) {
        if ($null -ne $script:QueryClock -and $script:QueryClock.ElapsedMilliseconds -ge 500) { throw 'Completion query deadline exceeded.' }
        if ((Get-PS7DependencyStamp $dependency.Path) -ne $dependency.Stamp) { $stable = $false; break }
    }
    if ($stable -and $generation -eq $script:CacheGeneration) {
        if ($script:Cache.Count -ge 128) {
            $oldest = $script:Cache.Keys | Sort-Object { $script:Cache[$_].Created } | Select-Object -First 1
            $script:Cache.Remove($oldest)
        }
        $script:Cache[$key] = @{ Created = [Diagnostics.Stopwatch]::GetTimestamp(); Data = $data; Dependencies = @($response.Dependencies) }
    }
    return $data
}
