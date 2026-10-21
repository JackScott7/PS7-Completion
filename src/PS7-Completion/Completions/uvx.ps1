{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --isolated --no-env-file --offline --no-cache -n --quiet -q --verbose -v --no-config --refresh' '--from --with -w --with-editable --with-requirements --constraints -c --build-constraints -b --overrides --env-file --python -p --index --default-index --index-url -i --extra-index-url --cache-dir --directory --project --config-file --color' -Values @{
        '--color' = @('auto', 'always', 'never')
    } -StopAtPositional
    # Arguments after the tool name belong to that tool, not uvx.
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
