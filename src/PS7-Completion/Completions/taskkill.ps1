{
    param($Context)
    $options = @{ '/PID'=1; '/IM'=1; '/FI'=1; '/F'=0; '/T'=0; '/?'=0; '/S'=1; '/U'=1; '/P'=1 }
    $state = Get-PS7OptionState -Arguments $Context.PreviousArguments -Options $options
    if (-not $state.Valid -or $state.Positionals.Count) { return }
    if ($state.Pending) {
        if ($state.Pending -eq '/FI') {
            $word = ConvertFrom-PS7Literal $Context.WordToComplete
            $names = @('STATUS','IMAGENAME','PID','SESSION','CPUTIME','MEMUSAGE','USERNAME','SERVICES','WINDOWTITLE','MODULES')
            if ($state.Values.ContainsKey('/S')) { $names = @($names | Where-Object { $_ -notin @('STATUS','WINDOWTITLE') }) }
            $candidates = @()
            if ($word -notmatch '\s') { $candidates = @($names | ForEach-Object { $_ + ' ' }) }
            elseif ($word -match '^(\S+)\s+(\S*)$' -and $Matches[1] -in $names) {
                $name = $Matches[1]
                $operators = if ($name -in @('PID','SESSION','CPUTIME','MEMUSAGE')) { @('eq','ne','gt','lt','ge','le') } else { @('eq','ne') }
                $candidates = @($operators | ForEach-Object { $name + ' ' + $_ + ' ' })
            }
            elseif ($word -match '^(STATUS)\s+(eq|ne)\s+(.*)$' -and -not $state.Values.ContainsKey('/S')) {
                $head = $Matches[1] + ' ' + $Matches[2] + ' '
                $candidates = @('RUNNING','NOT RESPONDING','UNKNOWN' | ForEach-Object { $head + $_ })
            }
            New-PS7CompletionResult -Candidate $candidates -WordToComplete $Context.WordToComplete
            return
        }
        if ($state.Values.ContainsKey('/S')) { return }
        if ($state.Pending -eq '/PID') {
            New-PS7CompletionResult -Candidate @(Get-PS7QueryData Processes | ForEach-Object { $_.Id }) -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/IM') {
            New-PS7CompletionResult -Candidate @(Get-PS7QueryData Processes | ForEach-Object { $_.Name }) -WordToComplete $Context.WordToComplete
        }
        return
    }
    New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete
}
