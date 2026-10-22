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
    $matching = [Collections.Generic.List[string]]::new()
    $start = 0
    $ordered = $Candidate
    if ($Candidate.Count -gt 512 -and $prefix) {
        # Native array sorting plus a lower-bound search avoids walking thousands
        # of nonmatching values in the PowerShell interpreter. Never mutate input.
        $ordered = [string[]]$Candidate.Clone()
        [Array]::Sort($ordered, [StringComparer]::OrdinalIgnoreCase)
        $end = $ordered.Length
        while ($start -lt $end) {
            $middle = $start + [int][Math]::Floor(($end - $start) / 2)
            if ([StringComparer]::OrdinalIgnoreCase.Compare($ordered[$middle], $prefix) -lt 0) { $start = $middle + 1 }
            else { $end = $middle }
        }
    }
    for ($index = $start; $index -lt $ordered.Count; $index++) {
        $value = $ordered[$index]
        if ($Candidate.Count -gt 512 -and $prefix -and -not $value.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { break }
        if ([string]::IsNullOrEmpty($value) -or -not $value.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($value)) { continue }
        $matching.Add($value)
    }
    $matching.Sort([StringComparer]::Ordinal)
    $count = 0
    $quotedToken = $WordToComplete.StartsWith("'") -or $WordToComplete.StartsWith('"')
    foreach ($value in $matching) {
        $text = $value
        if ($value.StartsWith('@') -or $value -notmatch '^[\p{L}\p{N}_./\\:@=+%-]+$' -or $quotedToken) {
            $text = "'" + $value.Replace("'", "''") + "'"
        }
        $description = if ($ToolTip) { $ToolTip } else { $value }
        [System.Management.Automation.CompletionResult]::new($text, $value, $ResultType, $description)
        $count++
        if ($count -ge 512) { break }
    }
}
