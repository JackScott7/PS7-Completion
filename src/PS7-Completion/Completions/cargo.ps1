{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --list --verbose -v --quiet -q --locked --offline --frozen' '--color --config --explain' -Children @{
        build = (New-PS7SyntaxNode '--release --workspace --all-targets --all-features --no-default-features --lib --bins --tests --examples' '--package -p --jobs -j --target --target-dir --manifest-path --features --profile --bin --example')
        check = (New-PS7SyntaxNode '--release --workspace --all-targets --all-features --no-default-features' '--package -p --jobs -j --target --target-dir --manifest-path --features --profile')
        run = (New-PS7SyntaxNode '--release --all-features --no-default-features' '--package -p --jobs -j --target --manifest-path --features --profile --bin --example' -StopAtPositional)
        test = (New-PS7SyntaxNode '--release --workspace --all-features --no-default-features --no-run --lib --bins --tests --doc' '--package -p --jobs -j --target --manifest-path --features --profile')
        new = (New-PS7SyntaxNode '--bin --lib' '--name --edition --vcs')
        init = (New-PS7SyntaxNode '--bin --lib' '--name --edition --vcs')
        add = (New-PS7SyntaxNode '--dev --build --optional --no-default-features' '--features --git --branch --tag --rev --path --package -p --manifest-path')
        remove = (New-PS7SyntaxNode '--dev --build' '--package -p --manifest-path')
        clean = (New-PS7SyntaxNode '--release --doc --dry-run' '--package -p --target --target-dir --manifest-path --profile')
        doc = (New-PS7SyntaxNode '--open --no-deps --release --workspace --all-features' '--package -p --target --manifest-path --features')
        update = (New-PS7SyntaxNode '--dry-run' '--package -p --precise --manifest-path')
        search = (New-PS7SyntaxNode '' '--limit --registry')
        install = (New-PS7SyntaxNode '--force --locked --debug --all-features --no-default-features' '--version --git --branch --tag --rev --path --root --target --features --bin')
        uninstall = (New-PS7SyntaxNode '' '--root --bin')
        publish = (New-PS7SyntaxNode '--dry-run --no-verify --allow-dirty' '--registry --token --manifest-path --package -p')
    }
    foreach ($node in @($syntax.Children.Values)) {
        foreach ($flag in @('--help','-h','--verbose','-v','--quiet','-q','--locked','--offline','--frozen')) { $node.Options[$flag] = 0 }
        foreach ($operand in @('--color','--config')) { $node.Options[$operand] = 1 }
        $node.Values['--color'] = @('auto','always','never')
        if ($node.Options.ContainsKey('--edition')) { $node.Values['--edition'] = @('2015','2018','2021','2024') }
    }
    $syntax.Values['--color'] = @('auto','always','never')
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
