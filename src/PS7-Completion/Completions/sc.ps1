{
    param($Context)
    $operations = @('query', 'queryex', 'start', 'stop', 'qc', 'config', 'create', 'delete', 'description')
    $previous = @($Context.PreviousArguments)
    if (-not $previous.Count) {
        New-PS7CompletionResult -Candidate $operations -WordToComplete $Context.WordToComplete -ResultType Command
        return
    }
    if ($previous[0].StartsWith('\\')) { return }
    $operation = $previous[0]
    if ($operation -notin $operations) { return }
    $queryOptions = @{ 'type='=1; 'state='=1; 'bufsize='=1; 'ri='=1; 'group='=1 }
    $configOptions = @{ 'type='=1; 'start='=1; 'error='=1; 'binPath='=1; 'group='=1; 'tag='=1; 'depend='=1; 'obj='=1; 'DisplayName='=1; 'password='=1 }
    if ($previous.Count -eq 1) {
        if ($operation -ne 'create') {
            # Query keys are an alternative to a service operand, not combined with it.
            if ($operation -in @('query','queryex')) {
                New-PS7CompletionResult -Candidate @($queryOptions.Keys) -WordToComplete $Context.WordToComplete
                if ($Context.WordToComplete.Contains('=')) { return }
            }
            New-PS7CompletionResult -Candidate @(Get-PS7QueryData Services) -WordToComplete $Context.WordToComplete
        }
        return
    }
    $options = @{}
    $tail = @()
    if ($operation -in @('query','queryex')) {
        if (-not $queryOptions.ContainsKey($previous[1])) { return }
        $options = $queryOptions
        $tail = @($previous | Select-Object -Skip 1)
    }
    elseif ($operation -in @('create','config')) {
        $options = $configOptions
        $tail = @($previous | Select-Object -Skip 2)
    }
    else { return }
    $state = Get-PS7OptionState -Arguments $tail -Options $options
    if (-not $state.Valid -or $state.Positionals.Count) { return }
    if ($state.Pending) {
        $candidates = switch ($state.Pending) {
            'state=' { @('active','inactive','all') }
            'type=' { if ($operation -in @('query','queryex')) { @('driver','service','all','own','share','interact','kernel','filesys','rec','adapt') } else { @('own','share','interact','kernel','filesys','rec','adapt') } }
            'start=' { @('boot','system','auto','demand','disabled','delayed-auto') }
            'error=' { @('normal','severe','critical','ignore') }
            'tag=' { @('yes','no') }
            default { @() }
        }
        New-PS7CompletionResult -Candidate @($candidates) -WordToComplete $Context.WordToComplete
        return
    }
    New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete
}
