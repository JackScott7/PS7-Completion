{
    param($Context)
    $syntax = New-PS7SyntaxNode '/? /scannow /verifyonly /scanfile /verifyfile /offbootdir /offwindir /offlogfile'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
