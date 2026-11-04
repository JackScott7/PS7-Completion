function New-PS7SyntaxNode {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs an in-memory syntax table.')]
    [CmdletBinding()]
    param([string] $Flags = '', [string] $Operands = '', [hashtable] $Children = @{}, [hashtable] $Values = @{}, [switch] $StopAtPositional, [string[]] $StopAfterOperands = @())
    $options = [Collections.Generic.Dictionary[string,int]]::new([StringComparer]::Ordinal)
    foreach ($flag in ($Flags -split ' ')) { if ($flag) { $options[$flag] = 0 } }
    foreach ($operand in ($Operands -split ' ')) { if ($operand) { $options[$operand] = 1 } }
    @{ Options = $options; Children = $Children; Values = $Values; StopAtPositional = $StopAtPositional.IsPresent; StopAfterOperands = $StopAfterOperands }
}

function Invoke-PS7SyntaxCompletion {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'CaseInsensitive', Justification = 'The nested key lookup reads this option.')]
    [CmdletBinding()]
    param($Context, [hashtable] $Syntax, [switch] $CaseInsensitive)
    function Find-SyntaxKey($Keys, [string] $Value) {
        foreach ($key in $Keys) {
            if (($CaseInsensitive -and $key -ieq $Value) -or (-not $CaseInsensitive -and $key -ceq $Value)) { return $key }
        }
    }
    $node = $Syntax
    $pending = ''
    $remaining = 0
    $positional = $false
    foreach ($argument in $Context.PreviousArguments) {
        if ($remaining) {
            $remaining--
            if (-not $remaining) {
                if ($node.StopAfterOperands -ccontains $pending) { return }
                $pending = ''
            }
            continue
        }
        if ($argument -ceq '--') { return }
        $option = Find-SyntaxKey $node.Options.Keys $argument
        if ($null -ne $option) {
            $remaining = $node.Options[$option]
            if ($remaining) { $pending = $option }
            continue
        }
        if ($argument.StartsWith('-')) {
            $parts = $argument.Split('=', 2)
            $option = Find-SyntaxKey $node.Options.Keys $parts[0]
            if ($parts.Count -eq 2 -and $null -ne $option -and $node.Options[$option] -eq 1) {
                if ($node.StopAfterOperands -ccontains $option) { return }
                continue
            }
            return
        }
        $child = Find-SyntaxKey $node.Children.Keys $argument
        if (-not $positional -and $null -ne $child) {
            $node = $node.Children[$child]
            continue
        }
        if ($node.Children.Count -or $node.StopAtPositional) { return }
        $positional = $true
    }
    if ($pending) {
        if (@($node.Values.Keys) -ccontains $pending) {
            New-PS7CompletionResult -Candidate $node.Values[$pending] -WordToComplete $Context.WordToComplete
        }
        return
    }
    if ($Context.WordToComplete.StartsWith('-') -and $Context.WordToComplete.Contains('=')) {
        $parts = $Context.WordToComplete.Split('=', 2)
        $option = Find-SyntaxKey $node.Options.Keys $parts[0]
        if ($null -ne $option -and $node.Options[$option] -eq 1 -and @($node.Values.Keys) -ccontains $option) {
            $candidates = @($node.Values[$option] | ForEach-Object { $parts[0] + '=' + $_ })
            New-PS7CompletionResult -Candidate $candidates -WordToComplete $Context.WordToComplete
        }
        return
    }
    if (-not $positional) {
        New-PS7CompletionResult -Candidate @($node.Children.Keys) -WordToComplete $Context.WordToComplete -ResultType Command
    }
    New-PS7CompletionResult -Candidate @($node.Options.Keys) -WordToComplete $Context.WordToComplete -ResultType ParameterName
}
