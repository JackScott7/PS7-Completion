{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --verbose -v --quiet -q --silent -s --isolated' '--config --color' -Children @{
        check = (New-PS7SyntaxNode '--fix --no-fix --unsafe-fixes --no-unsafe-fixes --show-fixes --diff --watch -w --fix-only --ignore-noqa --preview --no-preview --statistics --show-files --show-settings --no-cache -n --exit-zero --exit-non-zero-on-fix --respect-gitignore --no-respect-gitignore --force-exclude' '--output-format --output-file -o --target-version --extension --select --ignore --extend-select --per-file-ignores --extend-per-file-ignores --fixable --unfixable --exclude --extend-exclude --line-length --cache-dir --stdin-filename' -Values @{
            '--output-format' = @('concise', 'full', 'json', 'json-lines', 'junit', 'grouped', 'github', 'gitlab', 'pylint', 'rdjson', 'azure', 'sarif')
        })
        format = (New-PS7SyntaxNode '--check --diff --preview --no-preview --no-cache -n --exit-non-zero-on-format --respect-gitignore --no-respect-gitignore --force-exclude' '--extension --target-version --cache-dir --stdin-filename --exclude --extend-exclude --line-length --range')
        rule = (New-PS7SyntaxNode '--all' '--output-format' -Values @{ '--output-format' = @('text', 'json') })
        config = (New-PS7SyntaxNode '' '--output-format' -Values @{ '--output-format' = @('text', 'json') })
        linter = (New-PS7SyntaxNode '' '--output-format' -Values @{ '--output-format' = @('text', 'json') })
        clean = (New-PS7SyntaxNode)
        server = (New-PS7SyntaxNode)
        version = (New-PS7SyntaxNode '' '--output-format' -Values @{ '--output-format' = @('text', 'json') })
    }
    # Ruff accepts these global options both before and after its subcommand.
    foreach ($node in @($syntax) + @($syntax.Children.Values)) {
        foreach ($flag in @('--help', '-h', '--verbose', '-v', '--quiet', '-q', '--silent', '-s', '--isolated')) { $node.Options[$flag] = 0 }
        foreach ($operand in @('--config', '--color')) { $node.Options[$operand] = 1 }
        $node.Values['--color'] = @('auto', 'always', 'never')
        if ($node.Options.ContainsKey('--target-version')) {
            $node.Values['--target-version'] = @('py37', 'py38', 'py39', 'py310', 'py311', 'py312', 'py313', 'py314', 'py315')
        }
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
