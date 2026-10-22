{
    param($Context)
    $options = @('-4', '-6', '-A', '-a', '-C', '-F', '-i', '-J', '-L', '-p', '-R', '-v', '-l', '-o', '-D', '-N', '-T', '-t', '-V')
    $operands = @('-F', '-i', '-J', '-L', '-p', '-R', '-l', '-o', '-D')
    $config = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ssh/config'
    $pending = ''
    $destinationSeen = $false
    $endOptions = $false
    foreach ($argument in $Context.PreviousArguments) {
        if ($pending) {
            if ($pending -ceq '-F') {
                if ($argument -ceq 'none') { $config = ''; $pending = ''; continue }
                $config = [IO.Path]::GetFullPath($argument, $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path)
            }
            $pending = ''; continue
        }
        if ($argument -ceq '--') { $endOptions = $true; continue }
        if (-not $endOptions -and $argument.StartsWith('-')) {
            if ($argument -cin $operands) { $pending = $argument }
            elseif ($argument.Length -gt 2 -and $argument.Substring(0,2) -cin $operands) {
                if ($argument.Substring(0,2) -ceq '-F') {
                    if ($argument.Substring(2) -ceq 'none') { $config = ''; continue }
                    $config = [IO.Path]::GetFullPath($argument.Substring(2), $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path)
                }
            }
            elseif ($argument -cnotin $options) { return }
        }
        else { $destinationSeen = $true }
    }
    if ($destinationSeen) { return }
    if ($pending) {
        if ($pending -cin @('-i','-F')) { Complete-PS7LocalPath -WordToComplete $Context.WordToComplete }
        return
    }
    $current = ConvertFrom-PS7Literal $Context.WordToComplete
    if (-not $endOptions -and $current.Length -gt 2 -and $current.Substring(0,2) -cin @('-i','-F')) {
        Complete-PS7LocalPath -WordToComplete $Context.WordToComplete -AttachedPrefix $current.Substring(0,2)
        return
    }
    if (-not $endOptions -and $Context.WordToComplete.StartsWith('-')) {
        New-PS7CompletionResult -Candidate $options -WordToComplete $Context.WordToComplete
        return
    }
    $prefix = ConvertFrom-PS7Literal $Context.WordToComplete
    $userPrefix = if ($prefix.Contains('@')) { $prefix.Substring(0, $prefix.LastIndexOf('@') + 1) } else { '' }
    if (-not $config) { return }
    $hosts = @(Get-PS7QueryData -Kind SshHosts -Path $config | ForEach-Object { $userPrefix + $_ })
    New-PS7CompletionResult -Candidate $hosts -WordToComplete $Context.WordToComplete
}
