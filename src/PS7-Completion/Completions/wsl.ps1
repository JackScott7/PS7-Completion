{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --status --version --list -l --verbose -v --all --running --install --update --shutdown' '--terminate -t --distribution -d --user -u --set-default -s --set-version --set-default-version --unregister --export --import --import-in-place --mount --unmount'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
