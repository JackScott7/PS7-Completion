{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version -V -b -B -E -i -I -O -OO -q -s -S -u -v -x' '-c -m -W -X' -Values @{ '-m'=@('pip','venv','http.server','unittest','json.tool') } -StopAtPositional -StopAfterOperands @('-c','-m')
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
