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
                if ($argument -ceq 'none') { return }
                $config = [IO.Path]::GetFullPath($argument, $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path)
            }
            $pending = ''; continue
        }
        if ($argument -ceq '--') { $endOptions = $true; continue }
        if (-not $endOptions -and $argument.StartsWith('-')) {
            if ($argument -cin $operands) { $pending = $argument }
            elseif ($argument -cnotin $options) { return }
        }
        else { $destinationSeen = $true }
    }
    if ($pending -or $destinationSeen) { return }
    if (-not $endOptions -and $Context.WordToComplete.StartsWith('-')) {
        New-PS7CompletionResult -Candidate $options -WordToComplete $Context.WordToComplete
        return
    }
    $prefix = ConvertFrom-PS7Literal $Context.WordToComplete
    $userPrefix = if ($prefix.Contains('@')) { $prefix.Substring(0, $prefix.LastIndexOf('@') + 1) } else { '' }
    $hosts = @(Get-PS7QueryData -Kind SshHosts -Path $config | ForEach-Object { $userPrefix + $_ })
    New-PS7CompletionResult -Candidate $hosts -WordToComplete $Context.WordToComplete
}
