{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version --info --list-sdks --list-runtimes' -Children @{ 'build'=(New-PS7SyntaxNode '--help --no-restore --no-incremental --nologo'); 'test'=(New-PS7SyntaxNode '--help --no-build --no-restore --list-tests'); 'run'=(New-PS7SyntaxNode '--help --no-build --no-restore --no-launch-profile'); 'publish'=(New-PS7SyntaxNode '--help --no-build --no-restore --self-contained'); 'restore'=(New-PS7SyntaxNode '--help --force --no-cache'); 'new'=(New-PS7SyntaxNode '--help --list --search'); 'add'=(New-PS7SyntaxNode '--help'); 'remove'=(New-PS7SyntaxNode '--help'); 'list'=(New-PS7SyntaxNode '--help'); 'clean'=(New-PS7SyntaxNode '--help --no-restore'); 'pack'=(New-PS7SyntaxNode '--help --no-build --no-restore'); 'tool'=(New-PS7SyntaxNode '--help') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
