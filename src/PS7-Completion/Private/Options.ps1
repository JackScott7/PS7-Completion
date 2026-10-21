function Get-PS7OptionState {
    param([string[]] $Arguments, [hashtable] $Options)
    $pending = ''
    $values = @{}
    $positionals = [Collections.Generic.List[string]]::new()
    $valid = $true
    foreach ($argument in $Arguments) {
        if ($pending) { $values[$pending] = $argument; $pending = ''; continue }
        if ($Options.ContainsKey($argument)) {
            if ($Options[$argument] -eq 1) { $pending = $argument } else { $values[$argument] = $true }
        }
        elseif ($argument.StartsWith('-') -or $argument.StartsWith('/') -or $argument.EndsWith('=')) { $valid = $false; break }
        else { $positionals.Add($argument) }
    }
    [pscustomobject]@{ Pending = $pending; Values = $values; Positionals = $positionals.ToArray(); Valid = $valid }
}
