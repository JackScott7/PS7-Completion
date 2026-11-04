{
    param($Context)
    $syntax = New-PS7SyntaxNode '/?' -Children @{ 'query'=(New-PS7SyntaxNode '/help /ve /s /k /d /c /e /z' '/v /f /t'); 'add'=(New-PS7SyntaxNode '/help /ve /f' '/v /t /s /d'); 'delete'=(New-PS7SyntaxNode '/help /ve /va /f' '/v'); 'copy'=(New-PS7SyntaxNode '/help /s /f'); 'export'=(New-PS7SyntaxNode '/help /y'); 'import'=(New-PS7SyntaxNode '/help'); 'save'=(New-PS7SyntaxNode '/help /y'); 'load'=(New-PS7SyntaxNode '/help'); 'unload'=(New-PS7SyntaxNode '/help'); 'restore'=(New-PS7SyntaxNode '/help'); 'compare'=(New-PS7SyntaxNode '/help /ve /s' '/v'); 'flags'=(New-PS7SyntaxNode '/help') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
