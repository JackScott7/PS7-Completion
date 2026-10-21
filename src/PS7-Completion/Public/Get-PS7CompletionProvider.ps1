function Get-PS7CompletionProvider {
    <# .SYNOPSIS
    Lists registered provider metadata and lazy-load state.
    #>
    [CmdletBinding()]
    param()
    foreach ($name in ($script:Registry.Keys | Sort-Object)) {
        [pscustomobject]@{
            Name = $name
            Commands = $script:Registry[$name].Commands
            Enabled = $name -notin $script:Excluded
            Loaded = $script:Providers.ContainsKey($name)
            Status = 'Static scaffold'
        }
    }
}
