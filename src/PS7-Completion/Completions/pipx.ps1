{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version --quiet -q --verbose -v' -Children @{ 'install'=(New-PS7SyntaxNode '--help --force --include-deps' '--python --pip-args'); 'uninstall'=(New-PS7SyntaxNode '--help'); 'upgrade'=(New-PS7SyntaxNode '--help --include-injected' '--pip-args'); 'upgrade-all'=(New-PS7SyntaxNode '--help --include-injected'); 'list'=(New-PS7SyntaxNode '--help --json --short'); 'run'=(New-PS7SyntaxNode '--help --no-cache' '--spec --python' -StopAtPositional); 'runpip'=(New-PS7SyntaxNode '--help' -StopAtPositional); 'inject'=(New-PS7SyntaxNode '--help --include-apps --include-deps'); 'ensurepath'=(New-PS7SyntaxNode '--help --force'); 'environment'=(New-PS7SyntaxNode '--help') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
