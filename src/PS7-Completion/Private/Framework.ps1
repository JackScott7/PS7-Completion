function New-PS7CompletionContext {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs an in-memory context only.')]
    [CmdletBinding()]
    param([string] $WordToComplete, [System.Management.Automation.Language.CommandAst] $CommandAst, [int] $CursorPosition)
    $arguments = [System.Collections.Generic.List[string]]::new()
    $index = 0
    foreach ($element in @($CommandAst.CommandElements | Select-Object -Skip 1)) {
        if ($element.Extent.StartOffset -gt $CursorPosition) { break }
        $length = [Math]::Min($element.Extent.Text.Length, $CursorPosition - $element.Extent.StartOffset)
        $arguments.Add($element.Extent.Text.Substring(0, $length))
        if ($element.Extent.EndOffset -lt $CursorPosition) { $index++ }
    }
    [pscustomobject]@{
        WordToComplete = $WordToComplete
        CommandAst = $CommandAst
        CursorPosition = $CursorPosition
        Arguments = $arguments.ToArray()
        ArgumentIndex = $index
    }
}

function New-PS7StaticCompletion {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs completion objects without changing system state.')]
    [CmdletBinding()]
    param([string[]] $Candidates, [string] $WordToComplete)
    foreach ($candidate in $Candidates) {
        if ($candidate.StartsWith($WordToComplete, [StringComparison]::OrdinalIgnoreCase)) {
            [System.Management.Automation.CompletionResult]::new($candidate, $candidate, 'ParameterValue', $candidate)
        }
    }
}

function Invoke-PS7Provider {
    param([string] $Name, [string] $WordToComplete, [System.Management.Automation.Language.CommandAst] $CommandAst, [int] $CursorPosition)
    try {
        if (-not $script:Providers.ContainsKey($Name)) {
            $provider = & (Join-Path $PSScriptRoot ('../' + $script:Registry[$Name].File))
            if ($provider -isnot [scriptblock]) { throw "Provider $Name must return one scriptblock." }
            $script:Providers[$Name] = $provider
        }
        $context = New-PS7CompletionContext $WordToComplete $CommandAst $CursorPosition
        & $script:Providers[$Name] $context
    }
    catch { Write-Debug "PS7-Completion provider '$Name': $_" }
}
