{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --isolated --verbose -v --quiet -q --no-input --disable-pip-version-check' '--python --proxy --timeout --retries --log' -Children @{
    install=(New-PS7SyntaxNode '--help --upgrade -U --user --no-deps --pre --dry-run --force-reinstall' '--requirement -r --constraint -c --editable -e --target -t --index-url -i --extra-index-url')
    uninstall=(New-PS7SyntaxNode '--help --yes -y' '--requirement -r')
    list=(New-PS7SyntaxNode '--help --outdated --editable --local' '--format' -Values @{ '--format'=@('columns','freeze','json') })
    freeze=(New-PS7SyntaxNode '--help --all --local'); show=(New-PS7SyntaxNode '--help --files -f'); check=(New-PS7SyntaxNode '--help')
    download=(New-PS7SyntaxNode '--help --no-deps' '--dest -d --requirement -r --index-url -i')
    cache=(New-PS7SyntaxNode '--help' -Children @{ dir=(New-PS7SyntaxNode); info=(New-PS7SyntaxNode); list=(New-PS7SyntaxNode); purge=(New-PS7SyntaxNode); remove=(New-PS7SyntaxNode) })
}
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
