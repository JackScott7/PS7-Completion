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
            Enabled = $script:Registry[$name].Enabled
            Loaded = $script:Providers.ContainsKey($name)
            Status = $script:Registry[$name].Status
            Source = $script:Registry[$name].Source
        }
    }
}
