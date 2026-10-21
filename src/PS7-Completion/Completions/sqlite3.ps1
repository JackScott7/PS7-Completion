{
    param($Context)
    $syntax = New-PS7SyntaxNode '-help -version -batch -bail -readonly -header -noheader -csv -column -json -line -list -table -box -markdown -quote -html -echo' '-cmd -init -separator -newline -nullvalue' -StopAtPositional
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
