{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --null-input -n --raw-input -R --slurp -s --raw-output -r --compact-output -c --sort-keys -S --exit-status -e --join-output -j --ascii-output -a --tab --monochrome-output -M --color-output -C --stream --seq' '--from-file -f --indent -L'
    foreach ($option in @('--arg','--argjson','--slurpfile','--rawfile')) { $syntax.Options[$option] = 2 }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
