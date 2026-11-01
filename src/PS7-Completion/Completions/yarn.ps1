{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -v' -Children @{ 'install'=(New-PS7SyntaxNode '--immutable --immutable-cache --check-cache'); 'add'=(New-PS7SyntaxNode '--dev -D --peer -P --exact -E'); 'remove'=(New-PS7SyntaxNode '--all'); 'run'=(New-PS7SyntaxNode '--help' -StopAtPositional); 'exec'=(New-PS7SyntaxNode '--help' -StopAtPositional); 'test'=(New-PS7SyntaxNode '--help'); 'dlx'=(New-PS7SyntaxNode '--help' -StopAtPositional); 'up'=(New-PS7SyntaxNode '--interactive -i'); 'why'=(New-PS7SyntaxNode '--recursive -R'); 'workspace'=(New-PS7SyntaxNode '--help'); 'workspaces'=(New-PS7SyntaxNode '--help') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
