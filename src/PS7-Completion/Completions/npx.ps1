{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -v --yes -y --no' '--call -c --package -p' -StopAtPositional -StopAfterOperands @('--call', '-c')
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
