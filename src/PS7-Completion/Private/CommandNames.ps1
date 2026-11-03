function Convert-PS7CommandName {
    param([Management.Automation.CommandCompletion] $Completion, [string] $InputText)
    # Explicit paths and explicitly typed extensions retain PowerShell's behavior.
    if ($Completion.ReplacementIndex -lt 0 -or $Completion.ReplacementLength -lt 0) { return $Completion }
    $word = $InputText.Substring($Completion.ReplacementIndex, $Completion.ReplacementLength)
    if ($word -match '[\\/]' -or $word -match '\.e(?:x(?:e)?)?$') { return $Completion }
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($InputText, [ref]$tokens, [ref]$errors)
    $command = $ast.Find({ param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.CommandElements.Count -gt 0 -and $node.CommandElements[0].Extent.StartOffset -eq $Completion.ReplacementIndex }, $true)
    if ($null -eq $command) { return $Completion }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $results = [Collections.ObjectModel.Collection[Management.Automation.CompletionResult]]::new()
    foreach ($item in $Completion.CompletionMatches) {
        if ($item.ResultType -eq 'Command' -and $item.ListItemText -match '^([^\\/]+)\.exe$' -and
            [IO.Path]::IsPathRooted($item.ToolTip)) {
            $name = $Matches[1]
            if ($seen.Contains($name)) { continue }
            $resolved = Get-Command -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($resolved -and $resolved.CommandType -eq 'Application' -and $resolved.Source -ieq $item.ToolTip) {
                $null = $seen.Add($name)
                $results.Add([Management.Automation.CompletionResult]::new($name, $name, $item.ResultType, $item.ToolTip))
                continue
            }
        }
        $results.Add($item)
    }
    $Completion.CompletionMatches = $results
    return $Completion
}

function Enable-PS7ExtensionlessCommand {
    $previous = (Get-Command TabExpansion2 -CommandType Function -ErrorAction Stop).ScriptBlock
    $convert = ${function:Convert-PS7CommandName}
    $wrapper = {
        [CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
        param(
            [Parameter(Mandatory, Position=0, ParameterSetName='ScriptInputSet')][AllowEmptyString()][string] $inputScript,
            [Parameter(Position=1, ParameterSetName='ScriptInputSet')][int] $cursorColumn = $inputScript.Length,
            [Parameter(Mandatory, Position=0, ParameterSetName='AstInputSet')][Management.Automation.Language.Ast] $ast,
            [Parameter(Mandatory, Position=1, ParameterSetName='AstInputSet')][Management.Automation.Language.Token[]] $tokens,
            [Parameter(Mandatory, Position=2, ParameterSetName='AstInputSet')][Management.Automation.Language.IScriptPosition] $positionOfCursor,
            [Parameter(Position=2, ParameterSetName='ScriptInputSet')][Parameter(Position=3, ParameterSetName='AstInputSet')][hashtable] $options
        )
        $result = & $previous @PSBoundParameters
        $text = if ($PSCmdlet.ParameterSetName -eq 'AstInputSet') { $ast.Extent.Text } else { $inputScript }
        if ($result -is [Management.Automation.CommandCompletion]) { & $convert $result $text } else { $result }
    }.GetNewClosure()
    Set-Item Function:\global:TabExpansion2 -Value $wrapper
    $ExecutionContext.SessionState.Module.OnRemove = {
        $current = Get-Command TabExpansion2 -CommandType Function -ErrorAction SilentlyContinue
        if ($current -and $current.ScriptBlock.ToString() -ceq $wrapper.ToString()) {
            Set-Item Function:\global:TabExpansion2 -Value $previous
        }
    }.GetNewClosure()
}
