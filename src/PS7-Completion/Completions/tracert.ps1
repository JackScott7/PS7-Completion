{
    param($Context)
    $syntax = New-PS7SyntaxNode '-d -R -4 -6 /?' '-h -j -w -S' -StopAtPositional
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
