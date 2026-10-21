{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version --no-pager --paginate' '-C -c --git-dir --work-tree' -Children @{
    status = (New-PS7SyntaxNode '--short -s --branch -b --porcelain --ignored')
    add = (New-PS7SyntaxNode '--all -A --patch -p --dry-run -n --force -f')
    commit = (New-PS7SyntaxNode '--all -a --amend --no-edit --signoff -s' '--message -m --file -F')
    diff = (New-PS7SyntaxNode '--cached --staged --stat --name-only --name-status --check')
    log = (New-PS7SyntaxNode '--oneline --graph --all --decorate' '--max-count -n --author --since --until')
    clone = (New-PS7SyntaxNode '--bare --mirror --recursive' '--branch -b --depth --origin -o')
    fetch = (New-PS7SyntaxNode '--all --prune -p --tags --dry-run')
    pull = (New-PS7SyntaxNode '--rebase --ff-only --no-rebase')
    push = (New-PS7SyntaxNode '--all --tags --force-with-lease --set-upstream -u --dry-run')
    branch = (New-PS7SyntaxNode '--all -a --delete -d -D --list --show-current')
    switch = (New-PS7SyntaxNode '--detach' '--create -c -C')
    checkout = (New-PS7SyntaxNode '--detach' '-b -B')
    restore = (New-PS7SyntaxNode '--staged --worktree' '--source -s')
    remote = (New-PS7SyntaxNode '--verbose -v' -Children @{ add=(New-PS7SyntaxNode); remove=(New-PS7SyntaxNode); rename=(New-PS7SyntaxNode) })
    stash = (New-PS7SyntaxNode -Children @{ push=(New-PS7SyntaxNode '--include-untracked -u --all -a' '--message -m'); pop=(New-PS7SyntaxNode '--index'); list=(New-PS7SyntaxNode); apply=(New-PS7SyntaxNode '--index') })
}
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
