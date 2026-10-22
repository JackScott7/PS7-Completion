function Complete-PS7LocalPath {
    param([string] $WordToComplete, [string] $AttachedPrefix = '')
    try {
        $word = ConvertFrom-PS7Literal $WordToComplete
        $value = $word.Substring($AttachedPrefix.Length)
        # Enumerate only one literal local directory. Never expand wildcards or follow
        # network paths or reparse points, which can target remote storage.
        if ($value.StartsWith('\\') -or $value.StartsWith('//') -or $value -match '^[^:]+::') { return }
        $separator = [Math]::Max($value.LastIndexOf('\'), $value.LastIndexOf('/'))
        $directory = if ($separator -ge 0) { $value.Substring(0, $separator + 1) } else { '' }
        $leaf = $value.Substring($separator + 1)
        $base = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path
        $resolved = [IO.Path]::GetFullPath($(if ($directory) { $directory } else { '.' }), $base)
        if ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($resolved)).DriveType -ne [IO.DriveType]::Fixed) { return }
        $ancestor = [IO.DirectoryInfo]::new($resolved)
        while ($null -ne $ancestor) {
            if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return }
            $ancestor = $ancestor.Parent
        }
        $clock = [Diagnostics.Stopwatch]::StartNew()
        $visited = 0
        $candidates = @(foreach ($entry in [IO.DirectoryInfo]::new($resolved).EnumerateFileSystemInfos()) {
            $visited++
            if ($visited -gt 4096 -or $clock.ElapsedMilliseconds -ge 100) { return }
            if ($entry.Name.StartsWith($leaf, [StringComparison]::OrdinalIgnoreCase) -and
                ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
                $suffix = if (($entry.Attributes -band [IO.FileAttributes]::Directory) -ne 0) { [IO.Path]::DirectorySeparatorChar } else { '' }
                $AttachedPrefix + $directory + $entry.Name + $suffix
            }
        })
        New-PS7CompletionResult -Candidate $candidates -WordToComplete $WordToComplete
    } catch { Write-Debug "Local path completion unavailable: $($_.Exception.Message)" }
}
