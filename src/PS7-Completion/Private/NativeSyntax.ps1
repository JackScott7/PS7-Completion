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
    param($Context, [hashtable] $Syntax)
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
        if ($node.Options.ContainsKey($argument)) {
            $remaining = $node.Options[$argument]
            if ($remaining) { $pending = $argument }
            continue
        }
        if ($argument.StartsWith('-')) {
            $parts = $argument.Split('=', 2)
            if ($parts.Count -eq 2 -and $node.Options.ContainsKey($parts[0]) -and $node.Options[$parts[0]] -eq 1) {
                if ($node.StopAfterOperands -ccontains $parts[0]) { return }
                continue
            }
            return
        }
        if (-not $positional -and $node.Children.ContainsKey($argument) -and @($node.Children.Keys) -ccontains $argument) {
            $node = $node.Children[$argument]
            continue
        }
        if ($node.Children.Count -or $node.StopAtPositional) { return }
        $positional = $true
    }
    if ($pending) {
        if ($node.Values.ContainsKey($pending)) {
            New-PS7CompletionResult -Candidate $node.Values[$pending] -WordToComplete $Context.WordToComplete
        }
        return
    }
    $candidates = @($node.Options.Keys)
    if (-not $positional) { $candidates += @($node.Children.Keys) }
    New-PS7CompletionResult -Candidate $candidates -WordToComplete $Context.WordToComplete
}
