{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --verbose -v --quiet -q' -Children @{ show=(New-PS7SyntaxNode '--help' -Children @{ 'active-toolchain'=(New-PS7SyntaxNode); home=(New-PS7SyntaxNode) }); update=(New-PS7SyntaxNode '--help --no-self-update'); default=(New-PS7SyntaxNode '--help'); toolchain=(New-PS7SyntaxNode '--help' -Children @{ list=(New-PS7SyntaxNode); install=(New-PS7SyntaxNode '' '--profile --component --target'); uninstall=(New-PS7SyntaxNode) }); target=(New-PS7SyntaxNode '--help' -Children @{ list=(New-PS7SyntaxNode '--installed'); add=(New-PS7SyntaxNode '' '--toolchain'); remove=(New-PS7SyntaxNode '' '--toolchain') }); component=(New-PS7SyntaxNode '--help' -Children @{ list=(New-PS7SyntaxNode '--installed'); add=(New-PS7SyntaxNode '' '--toolchain'); remove=(New-PS7SyntaxNode '' '--toolchain') }); run=(New-PS7SyntaxNode '--help --install' -StopAtPositional) }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
