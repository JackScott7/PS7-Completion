{
    param($Context)
    # Windows ping: -r takes a hop count, whereas -R is an IPv6 flag.
    $syntax = New-PS7SyntaxNode '-t -a -f -R -p -4 -6 /?' '-n -l -i -v -r -s -j -k -w -S -c'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
