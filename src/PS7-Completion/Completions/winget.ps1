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
            # Capability snapshot: WinGet 1.29.380 source help. No tool is launched
            # from a completion callback; older versions may expose a smaller subset.
            foreach ($key in @('--wait','--logs','--open-logs','--verbose','--nowarn','--ignore-warnings','--no-proxy')) { $options[$key]=0 }
            $options['--proxy']=1
            $sourceCommands = @('add','list','update','remove','reset','export','edit')
            if (-not $tail.Count) {
                New-PS7CompletionResult -Candidate $sourceCommands -WordToComplete $Context.WordToComplete -ResultType Command
                New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete -ResultType ParameterName
                return
            }
            $sourceCommand = $tail[0]
            if ($sourceCommand -notin $sourceCommands) { return }
            $options['--name']=1; $options['-n']=1
            switch ($sourceCommand) {
                'add' {
                    foreach ($key in @('--arg','-a','--type','-t','--trust-level','--header')) { $options[$key]=1 }
                    $options['--accept-source-agreements']=0; $options['--explicit']=0
                }
                'edit' {
                    $options['--explicit']=1; $options['-e']=1
                }
                'reset' { $options['--force']=0 }
            }
            $tail = @($tail | Select-Object -Skip 1)
        }
        default { return }
    }
    $state = Get-PS7OptionState -Arguments $tail -Options $options -AllowEquals
    $positionalLimit = if ($command -eq 'source' -and $sourceCommand -eq 'add') { 3 } else { 1 }
    if (-not $state.Valid -or $state.Positionals.Count -gt $positionalLimit) { return }
    $word = ConvertFrom-PS7Literal $Context.WordToComplete
    $attached = ''
    if (-not $state.Pending -and $word.StartsWith('--') -and $word.Contains('=')) {
        $parts = $word.Split('=', 2)
        if (-not $options.ContainsKey($parts[0]) -or $options[$parts[0]] -ne 1) { return }
        $state.Pending = $parts[0]
        $attached = $parts[0] + '='
    }
    $valueWord = if ($attached) { $word.Substring($attached.Length) } else { $Context.WordToComplete }
    if ($state.Pending) {
        if (($command -eq 'export' -and $state.Pending -in @('--output','-o')) -or
            ($command -eq 'import' -and $state.Pending -in @('--import-file','-i'))) {
            Complete-PS7LocalPath -WordToComplete $Context.WordToComplete -AttachedPrefix $attached
            return
        }
        $values = @()
        if ($state.Pending -eq '--scope') { $values = @('user','machine') }
        elseif ($command -ne 'source' -and $state.Pending -in @('--architecture','-a')) { $values = @('x86','x64','arm','arm64') }
        elseif ($command -eq 'source') {
            switch ($state.Pending) {
                { $_ -in @('--type','-t') } { $values = @('Microsoft.PreIndexed.Package','Microsoft.Rest') }
                '--trust-level' { $values = @('none','trusted') }
                { $_ -in @('--explicit','-e') } { if ($sourceCommand -eq 'edit') { $values = @('true','false') } }
            }
        }
        if ($attached) {
            New-PS7CompletionResult -Candidate @($values | ForEach-Object { $attached + $_ }) -WordToComplete $Context.WordToComplete
        } else { New-PS7CompletionResult -Candidate $values -WordToComplete $valueWord }
        return
    }
    New-PS7CompletionResult -Candidate @($options.Keys) -WordToComplete $Context.WordToComplete
}
