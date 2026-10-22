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
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
        if (-not $process.WaitForExit($remaining)) { throw 'Completion query deadline exceeded.' }
        if ($process.ExitCode -ne 0) { throw 'Completion query worker failed.' }
        $json = $output.GetAwaiter().GetResult()
        if ($errors.GetAwaiter().GetResult()) { throw 'Completion query worker wrote an error.' }
        if ($json.Length -gt 2097152) { throw 'Query output exceeds its size limit.' }
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
