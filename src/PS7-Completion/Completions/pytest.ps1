{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --verbose -v --quiet -q --exitfirst -x --collect-only --disable-warnings --no-header --no-summary --strict-markers --strict-config -s' '--capture --maxfail --tb -k -m -c --rootdir --junitxml --durations'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
