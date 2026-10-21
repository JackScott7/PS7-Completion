function Register-PS7CompletionProvider {
    <#
    .SYNOPSIS
    Registers trusted completion code for native executable names in this session.
    .DESCRIPTION
    Supply a scriptblock receiving one context, or a .ps1 file returning one
    scriptblock (loaded on first completion). Providers emit CompletionResult only.
    Registration may replace another module's native completer; it is not restored.
    .EXAMPLE
    Register-PS7CompletionProvider -Name demo -CommandName demo.exe -ScriptBlock {
        param($context)
        New-PS7CompletionResult -Candidate 'build','test' -WordToComplete $context.WordToComplete
    }
    #>
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string[]] $CommandName,
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock')][scriptblock] $ScriptBlock,
        [Parameter(Mandatory, ParameterSetName = 'Path')][string] $Path,
        [switch] $Force
    )
    Assert-PS7ProviderDefinition -Name $Name -CommandName $CommandName
    if ($script:Registry.ContainsKey($Name)) {
        if (-not $Force) { throw "Provider '$Name' already exists. Use -Force to replace its implementation." }
        if (@(Compare-Object @($script:Registry[$Name].Commands | Sort-Object) @($CommandName | Sort-Object)).Count) {
            throw 'Replacement must retain the same executable names; restart the shell to change them.'
        }
    }
    foreach ($existing in $script:Registry.Keys) {
        if ($existing -eq $Name -or -not $script:Registry[$existing].Enabled) { continue }
        foreach ($command in $CommandName) {
            if ($command -in $script:Registry[$existing].Commands) { throw "Executable '$command' belongs to provider '$existing'." }
        }
    }
    $resolved = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        $provider = $null
        $drive = $null
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path, [ref]$provider, [ref]$drive)
        if ($provider.Name -ne 'FileSystem' -or [IO.Path]::GetExtension($resolved) -ne '.ps1' -or -not [IO.File]::Exists($resolved)) { throw 'Path must be an existing .ps1 file.' }
    }
    $callback = $ExecutionContext.InvokeCommand.NewScriptBlock(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
Invoke-PS7Provider -Name '$Name' -WordToComplete `$wordToComplete -CommandAst `$commandAst -CursorPosition `$cursorPosition
"@)
    Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock $callback
    $script:Registry[$Name] = @{ Commands = @($CommandName); File = $resolved; Enabled = $true; Status = 'Registered'; Source = 'Custom' }
    $script:Providers.Remove($Name)
    if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') { $script:Providers[$Name] = $ScriptBlock; $script:Registry[$Name].Status = 'Loaded' }
    Clear-PS7CompletionCache
}
