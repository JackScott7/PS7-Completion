{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --ignore-case -i --case-sensitive -s --smart-case -S --fixed-strings -F --line-number -n --files --hidden --no-ignore --count -c --files-with-matches -l --invert-match -v --word-regexp -w --json --pcre2 -P' '--regexp -e --file -f --glob -g --type -t --type-not -T --context -C --after-context -A --before-context -B --max-count -m --replace -r --encoding --color' -Values @{ '--color'=@('never','auto','always','ansi') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
