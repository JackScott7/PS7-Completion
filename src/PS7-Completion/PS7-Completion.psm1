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
    $files = [IO.Directory]::GetFiles([IO.Path]::Combine($PSScriptRoot, $folder), '*.ps1')
    [Array]::Sort($files, [StringComparer]::Ordinal)
    foreach ($file in $files) { . $file }
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
$registryTokens = $null
$registryErrors = $null
$registryAst = [Management.Automation.Language.Parser]::ParseFile([IO.Path]::Combine($PSScriptRoot, 'Registry.psd1'), [ref]$registryTokens, [ref]$registryErrors)
if ($registryErrors.Count -or $registryAst.EndBlock.Statements.Count -ne 1) { throw 'Invalid registry data.' }
$builtins = $registryAst.EndBlock.Statements[0].PipelineElements[0].Expression.SafeGetValue()
if ($builtins -isnot [hashtable]) { throw 'Registry must be a data hashtable.' }
# Validate every entry before registering any callbacks.
$commands = @{}
foreach ($name in $builtins.Keys) {
    $entry = $builtins[$name]
    Assert-PS7ProviderDefinition -Name $name -CommandName $entry.Commands -SkipAliasCheck:($name -in $script:Excluded)
    $path = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, $entry.File))
    if (-not $path.StartsWith($PSScriptRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not [IO.File]::Exists($path) -or [IO.Path]::GetExtension($path) -ne '.ps1') { throw "Invalid provider path: $name" }
    $entry.File = $path
    foreach ($command in $entry.Commands) {
        if ($commands.ContainsKey($command)) { throw "Duplicate executable: $command" }
        $commands[$command] = $name
    }
}
foreach ($name in $script:Excluded) { if (-not $builtins.ContainsKey($name)) { throw "Unknown provider: $name" } }
$names = [string[]]@($builtins.Keys)
[Array]::Sort($names, [StringComparer]::Ordinal)
foreach ($name in $names) {
    $entry = $builtins[$name]
    if ($name -in $script:Excluded) {
        $script:Registry[$name] = @{ Commands = $entry.Commands; File = $entry.File; Enabled = $false; Status = 'Excluded'; Source = 'BuiltIn' }
    }
    else {
        # These entries were already validated as a batch. Avoid resolving and
        # validating them twice through the public registration API at import.
        $callback = $ExecutionContext.InvokeCommand.NewScriptBlock(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
Invoke-PS7Provider -Name '$name' -WordToComplete `$wordToComplete -CommandAst `$commandAst -CursorPosition `$cursorPosition
"@)
        Register-ArgumentCompleter -Native -CommandName $entry.Commands -ScriptBlock $callback
        $script:Registry[$name] = @{ Commands = $entry.Commands; File = $entry.File; Enabled = $true; Status = 'Registered'; Source = 'BuiltIn' }
    }
}
Export-ModuleMember -Function Get-PS7CompletionProvider, Clear-PS7CompletionCache, Register-PS7CompletionProvider, New-PS7CompletionResult
