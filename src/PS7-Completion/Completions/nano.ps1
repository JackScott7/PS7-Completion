{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --backup -B --linenumbers -l --mouse -m --softwrap -S --tabstospaces -E --view -v --ignorercfiles -I --nonewlines -L --nowrap -w --autoindent -i' '--tabsize -T --syntax -Y --rcfile -f --operatingdir -o --backupdir -C'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
