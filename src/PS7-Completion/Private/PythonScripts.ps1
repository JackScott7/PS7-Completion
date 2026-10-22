function Get-PS7PythonScriptRoute {
    param($Context)
    # Inspect completed literal arguments only; never resolve or execute a target.
    $previous = @($Context.PreviousArguments)
    $target = $null
    $skip = 0
    for ($index = 0; $index -lt $previous.Count; $index++) {
        $argument = $previous[$index]
        if ($argument -ceq '-m' -or $argument -ceq '-mpip') {
            if ($argument -ceq '-mpip') { $target = 'pip'; $skip = $index + 1 }
            elseif ($index + 1 -lt $previous.Count -and $previous[$index + 1] -ceq 'pip') {
                $target = 'pip'; $skip = $index + 2
            }
            else { return }
            break
        }
        if ($argument -ceq '--') { $index++; break }
        if ($argument -cin @('-c', '-', '--help', '--version', '-h', '-V', '-VV')) { return }
        if ($argument -cmatch '^-[cm].+') { return }
        if ($argument -cin @('-W', '-X', '--check-hash-based-pycs')) { $index++; continue }
        if ($argument -cmatch '^-[WX].+') { continue }
        if ($argument -cin @('-b', '-bb', '-B', '-E', '-i', '-I', '-O', '-OO', '-q', '-s', '-S', '-u', '-v', '-vv', '-x', '-P')) { continue }
        if ($argument.StartsWith('-')) { return }
        break
    }
    if (-not $target) {
        if ($index -ge $previous.Count) { return }
        $target = [IO.Path]::GetFileName($previous[$index])
        if ([IO.Path]::GetExtension($target) -ine '.py') { return }
        $skip = $index + 1
    }
    if ($script:CommandOwners.ContainsKey($target)) {
        $name = $script:CommandOwners[$target]
        # Keep the original AST/absolute cursor, but expose target-relative args.
        return [pscustomobject]@{
            Name = $name
            Context = [pscustomobject]@{
                WordToComplete = $Context.WordToComplete
                CommandAst = $Context.CommandAst
                CursorPosition = $Context.CursorPosition
                Arguments = @($Context.Arguments | Select-Object -Skip $skip)
                Values = @($Context.Values | Select-Object -Skip $skip)
                PreviousArguments = @($previous | Select-Object -Skip $skip)
                ArgumentIndex = $Context.ArgumentIndex - $skip
                IsSupported = $Context.IsSupported
            }
        }
    }
}
