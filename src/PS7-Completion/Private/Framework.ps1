function New-PS7CompletionContext {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs an in-memory context only.')]
    [CmdletBinding()]
    param([string] $WordToComplete, [System.Management.Automation.Language.CommandAst] $CommandAst, [int] $CursorPosition)
    $arguments = [System.Collections.Generic.List[string]]::new()
    $values = [Collections.Generic.List[string]]::new()
    $index = 0
    $supported = $null -ne $CommandAst
    if (-not $supported) { throw 'CommandAst is required.' }
    foreach ($element in @($CommandAst.CommandElements | Select-Object -Skip 1)) {
        if ($element.Extent.StartOffset -gt $CursorPosition) { break }
        $length = [Math]::Min($element.Extent.Text.Length, $CursorPosition - $element.Extent.StartOffset)
        $raw = $element.Extent.Text.Substring(0, $length)
        $arguments.Add($raw)
        try {
            if ($element -isnot [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $element -isnot [System.Management.Automation.Language.ConstantExpressionAst] -and
                $element -isnot [System.Management.Automation.Language.CommandParameterAst]) { throw 'Unsupported argument AST.' }
            $values.Add((ConvertFrom-PS7Literal $raw))
        }
        catch { $supported = $false; $values.Add('') }
        if ($element.Extent.EndOffset -lt $CursorPosition) { $index++ }
    }
    foreach ($redirect in $CommandAst.Redirections) {
        if ($CursorPosition -ge $redirect.Extent.StartOffset -and $CursorPosition -le $redirect.Extent.EndOffset) { $supported = $false }
    }
    [pscustomobject]@{
        WordToComplete = $WordToComplete
        CommandAst = $CommandAst
        CursorPosition = $CursorPosition
        Arguments = $arguments.ToArray()
        ArgumentIndex = $index
        Values = $values.ToArray()
        PreviousArguments = @($values | Select-Object -First $index)
        IsSupported = $supported
    }
}

function ConvertFrom-PS7Literal {
    param([AllowEmptyString()][string] $Text)
    if (-not $Text) { return '' }
    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput("ps7literal $Text", [ref]$tokens, [ref]$errors)
    foreach ($errorRecord in $errors) {
        if ($errorRecord.ErrorId -ne 'TerminatorExpectedAtEndOfString') { throw 'Unsupported incomplete argument.' }
    }
    if ($ast.EndBlock.Statements.Count -ne 1 -or $ast.EndBlock.Statements[0] -isnot [Management.Automation.Language.PipelineAst]) { throw 'Expression arguments are unsupported.' }
    $pipeline = $ast.EndBlock.Statements[0]
    if ($pipeline.PipelineElements.Count -ne 1) { throw 'Expression arguments are unsupported.' }
    $command = $pipeline.PipelineElements[0]
    if ($command -isnot [Management.Automation.Language.CommandAst] -or $command.CommandElements.Count -ne 2 -or $command.Redirections.Count) { throw 'Expression arguments are unsupported.' }
    $argument = $command.CommandElements[1]
    if ($argument -is [Management.Automation.Language.StringConstantExpressionAst]) { return $argument.Value }
    if ($argument -is [Management.Automation.Language.ConstantExpressionAst]) { return $argument.Extent.Text }
    # Parameter names are already parsed literal tokens; colon arguments require
    # a separate grammar and are deliberately not evaluated here.
    if ($argument -is [Management.Automation.Language.CommandParameterAst] -and $null -eq $argument.Argument) { return $argument.Extent.Text }
    throw 'Expression arguments are unsupported.'
}

function New-PS7StaticCompletion {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Constructs completion objects without changing system state.')]
    [CmdletBinding()]
    param([string[]] $Candidates, [string] $WordToComplete)
    New-PS7CompletionResult -Candidate $Candidates -WordToComplete $WordToComplete
}

function Invoke-PS7Provider {
    param([string] $Name, [string] $WordToComplete, [System.Management.Automation.Language.CommandAst] $CommandAst, [int] $CursorPosition)
    $previousClock = $script:QueryClock
    $script:QueryClock = [Diagnostics.Stopwatch]::StartNew()
    try {
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
        if (-not $script:Registry.ContainsKey($Name) -or -not $script:Registry[$Name].Enabled) { return }
        if (-not $script:Providers.ContainsKey($Name)) {
            $loaded = @(& $script:Registry[$Name].File *>&1)
            if ($loaded.Count -ne 1 -or $loaded[0] -isnot [scriptblock]) { throw 'Provider file must return exactly one scriptblock.' }
            $script:Providers[$Name] = $loaded[0]
        }
        $context = New-PS7CompletionContext $WordToComplete $CommandAst $CursorPosition
        if (-not $context.IsSupported) { return }
        $results = @(& $script:Providers[$Name] $context *>&1)
        foreach ($result in $results) {
            if ($result -isnot [System.Management.Automation.CompletionResult]) { throw 'Provider emitted something other than CompletionResult.' }
        }
        $script:Registry[$Name].Status = 'Loaded'
        $results | Sort-Object -Property CompletionText -Unique -CaseSensitive | Select-Object -First 512
    }
    catch {
        if ($script:Registry.ContainsKey($Name)) { $script:Registry[$Name].Status = 'Failed' }
        Write-Debug "PS7-Completion provider '$Name' failed: $_"
    }
    finally { $script:QueryClock = $previousClock }
}

function Assert-PS7ProviderDefinition {
    param([string] $Name, [string[]] $CommandName)
    if ($Name -notmatch '^[a-zA-Z][a-zA-Z0-9_-]{0,63}$') { throw 'Provider names must be simple identifiers (up to 64 characters).' }
    if (-not $CommandName.Count) { throw 'At least one executable name is required.' }
    $seen = @{}
    $aliases = @{}
    foreach ($alias in $ExecutionContext.SessionState.InvokeCommand.GetCommands('*', [Management.Automation.CommandTypes]::Alias, $true)) { $aliases[$alias.Name] = $true }
    foreach ($command in $CommandName) {
        if ($command -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$') { throw "Invalid executable name: $command" }
        if ($seen.ContainsKey($command)) { throw "Duplicate executable: $command" }
        $seen[$command] = $true
        if ($aliases.ContainsKey($command)) { throw "Executable name '$command' is a PowerShell alias. Use its .exe name." }
    }
}
