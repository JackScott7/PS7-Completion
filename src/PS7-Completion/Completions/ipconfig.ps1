{
    param($Context)
    $syntax = New-PS7SyntaxNode '/? /all /allcompartments /flushdns /displaydns /registerdns' -Children @{
        '/renew' = (New-PS7SyntaxNode -StopAtPositional)
        '/release' = (New-PS7SyntaxNode -StopAtPositional)
        '/renew6' = (New-PS7SyntaxNode -StopAtPositional)
        '/release6' = (New-PS7SyntaxNode -StopAtPositional)
        '/showclassid' = (New-PS7SyntaxNode -StopAtPositional)
        '/setclassid' = (New-PS7SyntaxNode -StopAtPositional)
        '/showclassid6' = (New-PS7SyntaxNode -StopAtPositional)
        '/setclassid6' = (New-PS7SyntaxNode -StopAtPositional)
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
