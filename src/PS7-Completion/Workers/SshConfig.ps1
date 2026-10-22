function script:Read-PS7SshConfig {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Clock', Justification = 'Nested time-budget checks read the enclosing parser clock.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Path, [Diagnostics.Stopwatch] $Clock)
    $state = @{
        Hosts = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        Visited = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        Dependencies = [Collections.Generic.List[object]]::new()
        DependencyPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        Items = @{}
        Bytes = 0L
    }
    $sshRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ssh'
    function Assert-TimeBudget {
        if ($Clock -and $Clock.ElapsedMilliseconds -ge 500) { throw 'SSH config read deadline exceeded.' }
    }
    function Get-LocalItem([string] $Candidate) {
        # Metadata is reused only within this bounded parse, never across requests.
        if (-not $state.Items.ContainsKey($Candidate)) {
            $state.Items[$Candidate] = Get-Item -LiteralPath $Candidate -Force -ErrorAction Ignore
        }
        return $state.Items[$Candidate]
    }
    function Test-LocalPath([string] $Candidate, [int] $LinkDepth = 0) {
        Assert-TimeBudget
        if ($LinkDepth -ge 32) { return $false }
        if ($Candidate.StartsWith('\\') -or $Candidate.StartsWith('//')) { return $false }
        $full = [IO.Path]::GetFullPath($Candidate)
        if ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($full)).DriveType -ne 'Fixed') { return $false }
        # Inspect parents first so a link to a network share is rejected before
        # asking the filesystem for any of its children.
        $parts = [Collections.Generic.Stack[string]]::new()
        for ($part = $full; $part; $part = [IO.Path]::GetDirectoryName($part)) { $parts.Push($part) }
        foreach ($part in $parts) {
            Assert-TimeBudget
            $item = Get-LocalItem $part
            if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                $target = $item.LinkTarget
                if (-not $target) { return $false }
                if (-not [IO.Path]::IsPathRooted($target)) {
                    $target = [IO.Path]::GetFullPath($target, [IO.Path]::GetDirectoryName($part))
                }
                if (-not (Test-LocalPath $target ($LinkDepth + 1))) { return $false }
                Add-Dependency $part
            }
        }
        return $true
    }
    function Add-Dependency([string] $Candidate) {
        if (-not $state.DependencyPaths.Add($Candidate)) { return }
        $item = Get-LocalItem $Candidate
        $stamp = "$Candidate|missing"
        if ($item) {
            $length = if ($item.PSIsContainer) { -1 } else { $item.Length }
            $stamp = "$Candidate|$length|$($item.LastWriteTimeUtc.Ticks)|$($item.Attributes)|$($item.LinkTarget)"
        }
        $state.Dependencies.Add(@{ Path = $Candidate; Stamp = $stamp })
    }
    function Read-ConfigFile([string] $Candidate, [int] $Depth) {
        Assert-TimeBudget
        if ($Depth -gt 8 -or $state.Visited.Count -ge 64) { throw 'SSH Include limit exceeded.' }
        if (-not (Test-LocalPath $Candidate)) { return }
        $full = [IO.Path]::GetFullPath($Candidate)
        if (-not $state.Visited.Add($full)) { return }
        Add-Dependency $full
        $item = Get-LocalItem $full
        if (-not $item -or $item.PSIsContainer) { return }
        if ($item.Length -gt 1048576 -or ($state.Bytes + $item.Length) -gt 4194304) { throw 'SSH config size limit exceeded.' }
        $state.Bytes += $item.Length
        $conditional = $false
        try { $lines = [IO.File]::ReadAllLines($full) } catch { return }
        foreach ($line in $lines) {
            Assert-TimeBudget
            if ($line -notmatch '^\s*(Host|Include|Match)(?:\s*=\s*|\s+)(.*)$') { continue }
            $directive = $Matches[1]
            $body = $Matches[2]
            $tokens = [Collections.Generic.List[string]]::new()
            foreach ($token in [regex]::Matches($body, '"([^"]*)"|([^\s"#]+)|(#.*$)')) {
                if ($token.Groups[3].Success) { break }
                if ($token.Groups[1].Success) { $tokens.Add($token.Groups[1].Value) } else { $tokens.Add($token.Groups[2].Value) }
            }
            if ($directive -eq 'Match') { $conditional = $true; continue }
            if ($directive -eq 'Host') {
                $conditional = $false
                foreach ($alias in $tokens) {
                    if ($alias -and $alias -notmatch '[*?!\[\]]') { [void]$state.Hosts.Add($alias) }
                    if ($state.Hosts.Count -gt 4096) { throw 'SSH host limit exceeded.' }
                }
            }
            elseif (-not $conditional) {
                foreach ($include in $tokens) {
                    # Expansions other than ~/ and wildcard filenames are not evaluated.
                    if ($include -match '[$%`]' -or $include.StartsWith('~') -and -not $include.StartsWith('~/')) { continue }
                    $pattern = if ($include.StartsWith('~/')) { Join-Path ([Environment]::GetFolderPath('UserProfile')) $include.Substring(2) }
                    elseif ([IO.Path]::IsPathRooted($include)) { $include }
                    else { Join-Path $sshRoot $include }
                    $directory = [IO.Path]::GetDirectoryName($pattern)
                    if ($directory -match '[*?\[\]]' -or -not (Test-LocalPath $directory)) { continue }
                    Add-Dependency $directory
                    if ([Management.Automation.WildcardPattern]::ContainsWildcardCharacters([IO.Path]::GetFileName($pattern))) {
                        $files = @(Get-ChildItem -LiteralPath $directory -File -Force -ErrorAction Ignore | Where-Object Name -Like ([IO.Path]::GetFileName($pattern)) | Sort-Object Name | Select-Object -First 65)
                        foreach ($file in $files) { Read-ConfigFile $file.FullName ($Depth + 1) }
                    }
                    else { Read-ConfigFile $pattern ($Depth + 1) }
                }
            }
        }
    }
    Read-ConfigFile $Path 0
    @{ Hosts = @($state.Hosts | Sort-Object); Dependencies = @($state.Dependencies.ToArray()) }
}
