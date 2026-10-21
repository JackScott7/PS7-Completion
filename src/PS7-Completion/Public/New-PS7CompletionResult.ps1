function New-PS7CompletionResult {
    <#
    .SYNOPSIS
    Filters literal candidates by prefix and constructs safely quoted results.
    .EXAMPLE
    New-PS7CompletionResult -Candidate 'hello world','help' -WordToComplete 'he'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs objects; does not change state.')]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [AllowEmptyCollection()][string[]] $Candidate = @(),
        [AllowEmptyString()][string] $WordToComplete = '',
        [string] $ToolTip,
        [System.Management.Automation.CompletionResultType] $ResultType = 'ParameterValue'
    )
    try { $prefix = ConvertFrom-PS7Literal $WordToComplete } catch { return }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in ($Candidate | Sort-Object)) {
        if ([string]::IsNullOrEmpty($value) -or -not $value.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($value)) { continue }
        $text = $value
        if ($value.StartsWith('@') -or $value -notmatch '^[\p{L}\p{N}_./\\:@=+%-]+$' -or $WordToComplete.StartsWith("'") -or $WordToComplete.StartsWith('"')) {
            $text = "'" + $value.Replace("'", "''") + "'"
        }
        $description = if ($ToolTip) { $ToolTip } else { $value }
        [System.Management.Automation.CompletionResult]::new($text, $value, $ResultType, $description)
        if ($seen.Count -ge 512) { break }
    }
}
