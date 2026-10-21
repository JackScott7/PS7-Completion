function Clear-PS7CompletionCache {
    <# .SYNOPSIS
    Clears cached provider data without unloading provider implementations.
    #>
    [CmdletBinding()]
    param()
    $script:Cache.Clear()
}
