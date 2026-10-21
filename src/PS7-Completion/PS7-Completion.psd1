@{
    RootModule = 'PS7-Completion.psm1'
    ModuleVersion = '0.1.1'
    GUID = 'e6a18633-5f20-44e9-a613-5eb5b3f3d9d1'
    Author = 'PS7-Completion contributors'
    Description = 'Lazy native command completion for PowerShell 7 on Windows.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @('Get-PS7CompletionProvider', 'Clear-PS7CompletionCache', 'Register-PS7CompletionProvider', 'New-PS7CompletionResult')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
