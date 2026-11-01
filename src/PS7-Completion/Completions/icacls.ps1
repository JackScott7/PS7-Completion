{
    param($Context)
    $syntax = New-PS7SyntaxNode '/? /T /C /L /Q /reset /verify /inheritance /inheritance:e /inheritance:d /inheritance:r' '/save /restore /setowner /findsid /substitute /grant /deny /remove'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
