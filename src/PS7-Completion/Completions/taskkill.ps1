{
    param($Context)
    $options = @{ '/PID'=1; '/IM'=1; '/FI'=1; '/F'=0; '/T'=0; '/?'=0; '/S'=1; '/U'=1; '/P'=1 }
    $state = Get-PS7OptionState -Arguments $Context.PreviousArguments -Options $options
    if (-not $state.Valid -or $state.Positionals.Count) { return }
    if ($state.Pending) {
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
