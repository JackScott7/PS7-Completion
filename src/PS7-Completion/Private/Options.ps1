function Get-PS7OptionState {
    param([string[]] $Arguments, [hashtable] $Options, [switch] $AllowEquals)
    $pending = ''
    $values = @{}
    $positionals = [Collections.Generic.List[string]]::new()
    $valid = $true
    foreach ($argument in $Arguments) {
        if ($pending) { $values[$pending] = $argument; $pending = ''; continue }
        if ($Options.ContainsKey($argument)) {
            if ($Options[$argument] -eq 1) { $pending = $argument } else { $values[$argument] = $true }
        }
        elseif ($AllowEquals -and $argument.StartsWith('--') -and $argument.Contains('=')) {
            $parts = $argument.Split('=', 2)
            if (-not $Options.ContainsKey($parts[0]) -or $Options[$parts[0]] -ne 1) { $valid = $false; break }
            $values[$parts[0]] = $parts[1]
        }
        elseif ($argument.StartsWith('-') -or $argument.StartsWith('/') -or $argument.EndsWith('=')) { $valid = $false; break }
        else { $positionals.Add($argument) }
    }
    [pscustomobject]@{ Pending = $pending; Values = $values; Positionals = $positionals.ToArray(); Valid = $valid }
}

function Complete-PS7CommaValue {
    param([string[]] $Candidates, [string] $WordToComplete)
    $word = ConvertFrom-PS7Literal $WordToComplete
    $parts = $word.Split(',')
    $used = @($parts | Select-Object -SkipLast 1)
    if ($used -contains '*' -or @($used | Where-Object { $_ -notin $Candidates }).Count) { return }
    $head = $word.Substring(0, $word.LastIndexOf(',') + 1)
    $values = @($Candidates | Where-Object { $_ -notin $used -and (-not $used.Count -or $_ -ne '*') } | ForEach-Object { $head + $_ })
    New-PS7CompletionResult -Candidate $values -WordToComplete $WordToComplete
}
