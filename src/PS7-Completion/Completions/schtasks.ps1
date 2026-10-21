{
    param($Context)
    $operations = @('/Create', '/Delete', '/Query', '/Change', '/Run', '/End', '/ShowSid', '/?')
    if (-not $Context.PreviousArguments.Count) {
        New-PS7CompletionResult -Candidate $operations -WordToComplete $Context.WordToComplete
        return
    }
    $operation = $Context.PreviousArguments[0]
    $options = @{ '/?'=0; '/S'=1; '/U'=1; '/P'=1 }
    switch ($operation) {
        '/Create' { $extra = @{ '/TN'=1; '/TR'=1; '/SC'=1; '/ST'=1; '/SD'=1; '/ED'=1; '/ET'=1; '/MO'=1; '/D'=1; '/M'=1; '/RU'=1; '/RP'=1; '/RL'=1; '/XML'=1; '/F'=0; '/IT'=0; '/Z'=0 } }
        '/Change' { $extra = @{ '/TN'=1; '/TR'=1; '/ST'=1; '/SD'=1; '/ED'=1; '/ET'=1; '/RU'=1; '/RP'=1; '/ENABLE'=0; '/DISABLE'=0; '/IT'=0 } }
        '/Query' { $extra = @{ '/TN'=1; '/FO'=1; '/NH'=0; '/V'=0; '/XML'=0 } }
        '/Delete' { $extra = @{ '/TN'=1; '/F'=0 } }
        '/Run' { $extra = @{ '/TN'=1; '/I'=0 } }
        '/End' { $extra = @{ '/TN'=1 } }
        '/ShowSid' { $options = @{ '/?'=0 }; $extra = @{ '/TN'=1 } }
        default { return }
    }
    foreach ($key in $extra.Keys) { $options[$key] = $extra[$key] }
    $state = Get-PS7OptionState -Arguments @($Context.PreviousArguments | Select-Object -Skip 1) -Options $options
    if (-not $state.Valid -or $state.Positionals.Count) { return }
    if ($state.Pending) {
        if ($state.Pending -eq '/TN' -and $operation -ne '/Create' -and -not $state.Values.ContainsKey('/S')) {
            New-PS7CompletionResult -Candidate @(Get-PS7QueryData Tasks) -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/SC') {
            New-PS7CompletionResult -Candidate MINUTE,HOURLY,DAILY,WEEKLY,MONTHLY,ONCE,ONSTART,ONLOGON,ONIDLE,ONEVENT -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/FO') { New-PS7CompletionResult -Candidate TABLE,LIST,CSV -WordToComplete $Context.WordToComplete }
        elseif ($state.Pending -eq '/RL') { New-PS7CompletionResult -Candidate LIMITED,HIGHEST -WordToComplete $Context.WordToComplete }
        return
    }
    New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete
}
