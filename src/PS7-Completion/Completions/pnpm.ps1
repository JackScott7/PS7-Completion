{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -v --recursive -r --workspace-root -w' -Children @{ 'install'=(New-PS7SyntaxNode '--frozen-lockfile --offline --prefer-offline --ignore-scripts'); 'add'=(New-PS7SyntaxNode '--save-dev -D --save-prod -P --global -g --workspace'); 'remove'=(New-PS7SyntaxNode '--global -g'); 'run'=(New-PS7SyntaxNode '--if-present --parallel' -StopAtPositional); 'exec'=(New-PS7SyntaxNode '--parallel' -StopAtPositional); 'test'=(New-PS7SyntaxNode '--help'); 'update'=(New-PS7SyntaxNode '--latest --interactive'); 'dlx'=(New-PS7SyntaxNode '--help' -StopAtPositional); 'list'=(New-PS7SyntaxNode '--json' '--depth'); 'audit'=(New-PS7SyntaxNode '--json --fix') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
