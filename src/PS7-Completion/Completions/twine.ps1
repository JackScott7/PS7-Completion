{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version --no-color' -Children @{
        check = (New-PS7SyntaxNode '--help -h --strict')
        upload = (New-PS7SyntaxNode '--help -h --attestations --sign -s --non-interactive --skip-existing --verbose --disable-progress-bar' '--repository -r --repository-url --sign-with --identity -i --username -u --password -p --comment -c --config-file --cert --client-cert')
        register = (New-PS7SyntaxNode '--help -h --non-interactive --verbose --disable-progress-bar' '--repository -r --repository-url --username -u --password -p --comment -c --config-file --cert --client-cert')
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
