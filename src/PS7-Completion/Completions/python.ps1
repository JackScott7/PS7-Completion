{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version -V -b -B -E -i -I -O -OO -q -s -S -u -v -x' '-c -m -W -X' -Values @{ '-m'=@('pip','venv','http.server','unittest','json.tool') } -StopAtPositional -StopAfterOperands @('-c','-m')
    # Scan only interpreter options, never script arguments or option operands.
    $previous = @($Context.PreviousArguments)
    for ($index = 0; $index -lt $previous.Count; $index++) {
        $argument = $previous[$index]
        if (-not $syntax.Options.ContainsKey($argument)) { break }
        if ($argument -ceq '-c') { break }
        if ($argument -ceq '-m') {
            if ($index + 1 -lt $previous.Count -and $previous[$index + 1] -ceq 'pip') {
                $pipContext = [pscustomobject]@{ PreviousArguments = @($previous | Select-Object -Skip ($index + 2)); WordToComplete = $Context.WordToComplete }
                $pipProvider = & (Join-Path $script:ModuleRoot 'Completions/pip.ps1')
                & $pipProvider $pipContext
                return
            }
            break
        }
        $index += $syntax.Options[$argument]
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
