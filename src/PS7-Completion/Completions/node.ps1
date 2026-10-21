{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -v --check -c --interactive -i --test --watch --inspect --inspect-brk --no-warnings' '--eval -e --print -p --require -r --import --input-type --env-file' -Values @{ '--input-type'=@('module','commonjs') } -StopAtPositional -StopAfterOperands @('--eval','-e','--print','-p')
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
