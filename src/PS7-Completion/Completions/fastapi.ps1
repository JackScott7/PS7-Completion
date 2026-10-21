{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version' -Children @{ dev=(New-PS7SyntaxNode '--help --reload --no-reload' '--host --port --app --entrypoint --root-path'); run=(New-PS7SyntaxNode '--help --reload --no-reload' '--host --port --app --entrypoint --root-path --workers') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
