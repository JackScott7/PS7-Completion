{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version' '--socket' -Children @{ up=(New-PS7SyntaxNode '--help --accept-routes --accept-dns --ssh --reset' '--auth-key --hostname --advertise-routes --exit-node --login-server'); down=(New-PS7SyntaxNode '--help'); status=(New-PS7SyntaxNode '--help --json --active --peers --self'); ip=(New-PS7SyntaxNode '--help -4 -6'); ping=(New-PS7SyntaxNode '--help --verbose' '--c --timeout'); version=(New-PS7SyntaxNode '--json'); logout=(New-PS7SyntaxNode '--help'); set=(New-PS7SyntaxNode '--help --accept-routes --accept-dns --ssh' '--hostname --exit-node --advertise-routes') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
