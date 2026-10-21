# Register this file with -Path. It returns one scriptblock and has no eager work.
{
    param($Context)
    if ($Context.ArgumentIndex -eq 0) {
        New-PS7CompletionResult -Candidate 'build','test','deploy' -WordToComplete $Context.WordToComplete
    }
    elseif ($Context.PreviousArguments[0] -eq 'deploy') {
        New-PS7CompletionResult -Candidate 'development','staging','production' -WordToComplete $Context.WordToComplete
    }
}
