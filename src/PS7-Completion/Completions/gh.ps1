{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version' -Children @{
    auth=(New-PS7SyntaxNode '--help' -Children @{ login=(New-PS7SyntaxNode '--web --with-token' '--hostname --git-protocol'); status=(New-PS7SyntaxNode '--active' '--hostname'); logout=(New-PS7SyntaxNode '' '--hostname --user') })
    pr=(New-PS7SyntaxNode '--help' '-R --repo' -Children @{ list=(New-PS7SyntaxNode '--help' '--state --base --head --author --limit --json --jq' -Values @{ '--state'=@('open','closed','merged','all') }); view=(New-PS7SyntaxNode '--web --comments' '--json --jq'); create=(New-PS7SyntaxNode '--draft --web --fill' '--title --body --base --head'); checkout=(New-PS7SyntaxNode '--detach --force' '--branch') })
    issue=(New-PS7SyntaxNode '--help' '-R --repo' -Children @{ list=(New-PS7SyntaxNode '' '--state --label --assignee --limit'); view=(New-PS7SyntaxNode '--web --comments'); create=(New-PS7SyntaxNode '--web' '--title --body') })
    repo=(New-PS7SyntaxNode '--help' -Children @{ clone=(New-PS7SyntaxNode -StopAtPositional); view=(New-PS7SyntaxNode '--web' '--json --jq'); list=(New-PS7SyntaxNode '' '--limit --language') })
    workflow=(New-PS7SyntaxNode '--help' -Children @{ list=(New-PS7SyntaxNode '--all'); view=(New-PS7SyntaxNode '--web --yaml'); run=(New-PS7SyntaxNode '' '--ref --field --raw-field') })
}
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
