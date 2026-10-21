{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version --debug --no-debug' '--app -A --env-file -e' -Children @{ run=(New-PS7SyntaxNode '--help --reload --no-reload --debugger --no-debugger --with-threads --without-threads' '--host -h --port -p --cert --key --extra-files --exclude-patterns'); routes=(New-PS7SyntaxNode '--help --all-methods' '--sort' -Values @{ '--sort'=@('endpoint','methods','domain','rule','match') }); shell=(New-PS7SyntaxNode '--help') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
