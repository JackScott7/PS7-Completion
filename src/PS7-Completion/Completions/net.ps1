{
    param($Context)
    $syntax = New-PS7SyntaxNode '/?' -Children @{ 'user'=(New-PS7SyntaxNode '/help /add /delete /active:yes /active:no'); 'localgroup'=(New-PS7SyntaxNode '/help /add /delete'); 'group'=(New-PS7SyntaxNode '/help /add /delete'); 'use'=(New-PS7SyntaxNode '/help /delete /persistent:yes /persistent:no'); 'share'=(New-PS7SyntaxNode '/help /delete'); 'start'=(New-PS7SyntaxNode '/help'); 'stop'=(New-PS7SyntaxNode '/help'); 'accounts'=(New-PS7SyntaxNode '/help'); 'session'=(New-PS7SyntaxNode '/help'); 'view'=(New-PS7SyntaxNode '/help'); 'help'=(New-PS7SyntaxNode '/?') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax -CaseInsensitive
}
