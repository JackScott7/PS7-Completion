param([hashtable] $Configuration = @{})

Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'PS7-Completion supports Windows only.' }
$script:ModuleRoot = $PSScriptRoot
$script:Registry = @{}
$script:Providers = @{}
$script:Cache = @{}
$script:CacheGeneration = 0
$script:QueryClock = $null
foreach ($folder in @('Private', 'Public')) {
    Get-ChildItem (Join-Path $PSScriptRoot $folder) -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}
if ($null -eq $Configuration) { throw 'Configuration cannot be null.' }
foreach ($key in $Configuration.Keys) { if ($key -ne 'Exclude') { throw "Unknown configuration key: $key" } }
$script:Excluded = @()
if ($Configuration.ContainsKey('Exclude')) {
    if ($Configuration.Exclude -isnot [array] -and $Configuration.Exclude -isnot [string]) { throw 'Exclude must contain provider IDs.' }
    foreach ($name in $Configuration.Exclude) {
        if ($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)) { throw 'Exclude must contain nonempty provider IDs.' }
        $script:Excluded += $name
    }
}
$builtins = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Registry.psd1')
# Validate every entry before registering any callbacks.
$commands = @{}
foreach ($name in $builtins.Keys) {
    $entry = $builtins[$name]
    Assert-PS7ProviderDefinition -Name $name -CommandName $entry.Commands
    $path = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $entry.File))
    if (-not $path.StartsWith($PSScriptRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf) -or [IO.Path]::GetExtension($path) -ne '.ps1') { throw "Invalid provider path: $name" }
    $entry.File = $path
    foreach ($command in $entry.Commands) {
        if ($commands.ContainsKey($command)) { throw "Duplicate executable: $command" }
        $commands[$command] = $name
    }
}
foreach ($name in $script:Excluded) { if (-not $builtins.ContainsKey($name)) { throw "Unknown provider: $name" } }
foreach ($name in ($builtins.Keys | Sort-Object)) {
    $entry = $builtins[$name]
    if ($name -in $script:Excluded) {
        $script:Registry[$name] = @{ Commands = $entry.Commands; File = $entry.File; Enabled = $false; Status = 'Excluded'; Source = 'BuiltIn' }
    }
    else {
        Register-PS7CompletionProvider -Name $name -CommandName $entry.Commands -Path $entry.File
        $script:Registry[$name].Source = 'BuiltIn'
    }
}
Export-ModuleMember -Function Get-PS7CompletionProvider, Clear-PS7CompletionCache, Register-PS7CompletionProvider, New-PS7CompletionResult
