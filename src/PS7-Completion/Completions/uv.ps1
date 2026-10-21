{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --quiet -q --verbose -v --offline --no-cache' '--directory --project --config-file --cache-dir --color' -Children @{
    init=(New-PS7SyntaxNode '--help --lib --app --bare' '--name --python')
    add=(New-PS7SyntaxNode '--help --dev --no-sync' '--optional --group --index --python')
    remove=(New-PS7SyntaxNode '--help --dev --no-sync' '--group')
    sync=(New-PS7SyntaxNode '--help --frozen --locked --all-extras --no-dev' '--python --group')
    lock=(New-PS7SyntaxNode '--help --upgrade --check' '--python --upgrade-package')
    run=(New-PS7SyntaxNode '--help --frozen --locked --no-sync' '--python --with' -StopAtPositional)
    venv=(New-PS7SyntaxNode '--help --seed --clear' '--python --prompt')
    python=(New-PS7SyntaxNode '--help' -Children @{ list=(New-PS7SyntaxNode '--installed'); install=(New-PS7SyntaxNode); find=(New-PS7SyntaxNode); pin=(New-PS7SyntaxNode); uninstall=(New-PS7SyntaxNode) })
    tool=(New-PS7SyntaxNode '--help' -Children @{ run=(New-PS7SyntaxNode '' '--from --python' -StopAtPositional); install=(New-PS7SyntaxNode '' '--python'); list=(New-PS7SyntaxNode); uninstall=(New-PS7SyntaxNode); upgrade=(New-PS7SyntaxNode '--all') })
    pip=(New-PS7SyntaxNode '--help' -Children @{ install=(New-PS7SyntaxNode '--upgrade --no-deps --system' '--requirement -r --python'); list=(New-PS7SyntaxNode); freeze=(New-PS7SyntaxNode); uninstall=(New-PS7SyntaxNode); check=(New-PS7SyntaxNode); compile=(New-PS7SyntaxNode '' '--output-file -o'); sync=(New-PS7SyntaxNode '' '--python') })
}
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
