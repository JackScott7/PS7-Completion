BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    function Get-PipMatches([string] $Line) {
        @([System.Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null).CompletionMatches |
            Select-Object CompletionText, ListItemText, ResultType, ToolTip) | ConvertTo-Json -Compress
    }
}
Describe 'Pip interpreter parity' {
    It 'matches direct completion for <_>' -ForEach @(
        '', 'ins', '--ver', 'install --', 'install --requirement ',
        'install --requirement "two words.txt" --u', 'list --format ',
        'list --format j', 'cache ', 'cache p', 'uninstall --y', '--unknown '
    ) {
        $expected = Get-PipMatches "pip $_"
        foreach ($prefix in @('python -m pip', 'python.exe -m pip', 'python3 -m pip',
            'python3.exe -m pip', 'python -I -W ignore -X dev -m pip', 'python -mpip',
            '& "C:\Python\python.exe" -m pip')) {
            Get-PipMatches "$prefix $_" | Should -Be $expected
        }
    }
    It 'does not dispatch pip in unrelated interpreter modes' -ForEach @(
        'python -c "-m pip" ins', 'python -- -m pip ins',
        'python other.py -m pip ins', 'python -m PIP ins', 'python -m other ins'
    ) {
        Get-PipMatches $_ | Should -Not -Match '"CompletionText":"install"'
    }
    It 'respects pip exclusion' {
        Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force -ArgumentList @{ Exclude = @('pip') }
        Get-PipMatches 'python -m pip ins' | Should -Not -Match '"CompletionText":"install"'
        Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    }
    It 'uses the same replacement provider, context, and failure handling' {
        Register-PS7CompletionProvider -Name pip -CommandName pip,pip.exe,pip3,pip3.exe -Force -ScriptBlock {
            param($context)
            if ($context.ArgumentIndex -ne 1 -or $context.PreviousArguments[0] -ne 'two words' -or
                $context.Arguments[0] -ne "'two words'" -or $context.Values[0] -ne 'two words' -or
                $context.CursorPosition -ne $context.CommandAst.Extent.EndOffset) { throw 'Wrong context' }
            New-PS7CompletionResult -Candidate custom -WordToComplete $context.WordToComplete
        }
        Get-PipMatches "python -m pip 'two words' cu" | Should -Be (Get-PipMatches "pip 'two words' cu")
        Get-PipMatches "python -m pip 'two words' cu" | Should -Match '"CompletionText":"custom"'
        Get-PipMatches 'python -m pip wrong cu' | Should -Not -Match '"CompletionText":"custom"'
        (Get-PS7CompletionProvider | Where-Object Name -EQ pip).Status | Should -Be Failed
        Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    }
}
