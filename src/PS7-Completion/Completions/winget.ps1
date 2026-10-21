{
    param($Context)
    $commands = @('install', 'show', 'source', 'search', 'list', 'upgrade', 'uninstall', 'export', 'import')
    $previous = @($Context.PreviousArguments)
    if (-not $previous.Count) {
        New-PS7CompletionResult -Candidate $commands -WordToComplete $Context.WordToComplete -ResultType Command
        New-PS7CompletionResult -Candidate '--help','--version' -WordToComplete $Context.WordToComplete -ResultType ParameterName
        return
    }
    $command = $previous[0]
    $options = @{ '--help'=0; '-?'=0; '--disable-interactivity'=0; '--verbose-logs'=0 }
    $tail = @($previous | Select-Object -Skip 1)
    if ($command -in @('install','show','search','list','upgrade','uninstall')) {
        foreach ($key in @('--id','--name','--moniker','--source','-s','--query','-q')) { $options[$key] = 1 }
        foreach ($key in @('--exact','-e','--accept-source-agreements')) { $options[$key] = 0 }
    }
    switch ($command) {
        'install' {
            foreach ($key in @('--version','-v','--scope','--architecture','-a','--location','-l','--manifest','-m','--override')) { $options[$key] = 1 }
            foreach ($key in @('--silent','--interactive','--accept-package-agreements','--force')) { $options[$key] = 0 }
        }
        'show' { $options['--version']=1; $options['--versions']=0; $options['--scope']=1; $options['--architecture']=1 }
        'search' { $options['--tag']=1; $options['--command']=1; $options['--count']=1 }
        'list' { $options['--scope']=1; $options['--upgrade-available']=0 }
        'upgrade' {
            foreach ($key in @('--version','--scope','--architecture','--location')) { $options[$key]=1 }
            foreach ($key in @('--all','--include-unknown','--silent','--interactive','--accept-package-agreements')) { $options[$key]=0 }
        }
        'uninstall' { $options['--version']=1; $options['--scope']=1; $options['--silent']=0; $options['--interactive']=0 }
        'export' { $options['--output']=1; $options['-o']=1; $options['--source']=1; $options['--include-versions']=0; $options['--accept-source-agreements']=0 }
        'import' { $options['--import-file']=1; $options['-i']=1; $options['--ignore-unavailable']=0; $options['--ignore-versions']=0; $options['--accept-package-agreements']=0; $options['--accept-source-agreements']=0 }
        'source' {
            if (-not $tail.Count) { New-PS7CompletionResult -Candidate add,list,update,remove,reset,export -WordToComplete $Context.WordToComplete -ResultType Command; return }
            if ($tail[0] -notin @('add','list','update','remove','reset','export')) { return }
            $options['--name']=1; $options['-n']=1
            if ($tail[0] -eq 'add') { $options['--arg']=1; $options['--type']=1; $options['--accept-source-agreements']=0 }
            if ($tail[0] -eq 'reset') { $options['--force']=0 }
            $tail = @($tail | Select-Object -Skip 1)
        }
        default { return }
    }
    $state = Get-PS7OptionState -Arguments $tail -Options $options
    if (-not $state.Valid -or $state.Positionals.Count -gt 1) { return }
    if ($state.Pending) {
        if ($state.Pending -eq '--scope') { New-PS7CompletionResult -Candidate user,machine -WordToComplete $Context.WordToComplete }
        elseif ($state.Pending -in @('--architecture','-a')) { New-PS7CompletionResult -Candidate x86,x64,arm,arm64 -WordToComplete $Context.WordToComplete }
        return
    }
    New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete
}
