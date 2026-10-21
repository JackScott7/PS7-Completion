param([hashtable] $Configuration = @{})

Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'PS7-Completion supports Windows only.' }
$script:Registry = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Registry.psd1')
$script:Providers = @{}
$script:Cache = @{}
$script:Excluded = @($Configuration['Exclude'] | Where-Object { $_ })
foreach ($name in $script:Excluded) {
    if (-not $script:Registry.ContainsKey($name)) { throw "Unknown provider: $name" }
}
foreach ($folder in @('Private', 'Public')) {
    Get-ChildItem (Join-Path $PSScriptRoot $folder) -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}
foreach ($name in $script:Registry.Keys) {
    if ($name -in $script:Excluded) { continue }
    # Bind each provider ID in module scope without relying on loop-variable capture.
    $callback = $ExecutionContext.InvokeCommand.NewScriptBlock(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
Invoke-PS7Provider -Name '$name' -WordToComplete `$wordToComplete -CommandAst `$commandAst -CursorPosition `$cursorPosition
"@)
    Register-ArgumentCompleter -Native -CommandName $script:Registry[$name].Commands -ScriptBlock $callback
}
Export-ModuleMember -Function Get-PS7CompletionProvider, Clear-PS7CompletionCache
