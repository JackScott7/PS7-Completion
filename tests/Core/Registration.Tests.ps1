BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    function Complete-Line([string] $Line) {
        @([System.Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null).CompletionMatches)
    }
}
Describe 'Public provider registration' {
    It 'registers inline code for bare and exe names' {
        Register-PS7CompletionProvider -Name fixture -CommandName fixturetool,fixturetool.exe -ScriptBlock {
            param($context)
            New-PS7CompletionResult -Candidate 'build','test','two words' -WordToComplete $context.WordToComplete
        }
        (Complete-Line 'fixturetool bu').CompletionText | Should -Contain 'build'
        (Complete-Line 'fixturetool.exe tw').CompletionText | Should -Contain "'two words'"
    }
    It 'loads a file only on demand and only once' {
        $path = Join-Path $TestDrive 'provider.ps1'
        Set-Content $path '{ param($context) New-PS7CompletionResult -Candidate lazy -WordToComplete $context.WordToComplete }'
        Register-PS7CompletionProvider -Name lazyfixture -CommandName lazyfixture.exe -Path $path
        (Get-PS7CompletionProvider | Where-Object Name -EQ lazyfixture).Loaded | Should -BeFalse
        (Complete-Line 'lazyfixture.exe la').CompletionText | Should -Contain lazy
        Set-Content $path 'throw "must not reload"'
        (Complete-Line 'lazyfixture.exe la').CompletionText | Should -Contain lazy
    }
    It 'requires explicit replacement and unchanged executable names' {
        { Register-PS7CompletionProvider -Name fixture -CommandName fixturetool -ScriptBlock {} } | Should -Throw '*already exists*'
        { Register-PS7CompletionProvider -Name fixture -CommandName different.exe -ScriptBlock {} -Force } | Should -Throw '*same executable*'
        Register-PS7CompletionProvider -Name fixture -CommandName fixturetool,fixturetool.exe -ScriptBlock { param($context) New-PS7CompletionResult -Candidate replaced -WordToComplete $context.WordToComplete } -Force
        (Complete-Line 'fixturetool rep').CompletionText | Should -Contain replaced
    }
    It 'rejects conflicting names and aliases before changing registry' {
        { Register-PS7CompletionProvider -Name collision -CommandName fixturetool -ScriptBlock {} } | Should -Throw '*belongs to*'
        { Register-PS7CompletionProvider -Name aliasfixture -CommandName ls -ScriptBlock {} } | Should -Throw '*alias*'
        { Register-PS7CompletionProvider -Name "bad'name" -CommandName valid.exe -ScriptBlock {} } | Should -Throw '*identifiers*'
        { Register-PS7CompletionProvider -Name invalidfile -CommandName valid.exe -Path (Join-Path $TestDrive 'missing.ps1') } | Should -Throw
        @(Get-PS7CompletionProvider | Where-Object Name -In collision,aliasfixture,invalidfile).Count | Should -Be 0
    }
    It 'discards partial output and non-terminating errors' {
        Register-PS7CompletionProvider -Name failurefixture -CommandName failurefixture.exe -ScriptBlock {
            New-PS7CompletionResult -Candidate shouldnotappear
            Write-Error 'fixture failure'
        }
        @(Complete-Line 'failurefixture.exe shouldnotappear' | Where-Object CompletionText -EQ shouldnotappear).Count | Should -Be 0
        (Get-PS7CompletionProvider | Where-Object Name -EQ failurefixture).Status | Should -Be Failed
    }
    It 'rejects warning output' {
        Register-PS7CompletionProvider -Name warningfixture -CommandName warningfixture.exe -ScriptBlock { Write-Warning 'noisy'; New-PS7CompletionResult -Candidate shouldnotappear }
        @(Complete-Line 'warningfixture.exe shouldnotappear' | Where-Object CompletionText -EQ shouldnotappear).Count | Should -Be 0
        (Get-PS7CompletionProvider | Where-Object Name -EQ warningfixture).Status | Should -Be Failed
    }
    It 'round trips special characters as literal arguments' -ForEach @('two words', "o'hare", '$(bad)', 'semi;colon', 'a`b', 'x&y') {
        $result = New-PS7CompletionResult -Candidate $_
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput("tool $($result.CompletionText)", [ref]$tokens, [ref]$errors)
        $command = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        $errors.Count | Should -Be 0
        $command.CommandElements[1].Value | Should -Be $_
        $command.CommandElements[1] | Should -BeOfType ([System.Management.Automation.Language.StringConstantExpressionAst])
    }
    It 'completes quoted prefixes without double quoting' {
        (New-PS7CompletionResult -Candidate 'two words' -WordToComplete '"two').CompletionText | Should -Be "'two words'"
    }
    It 'loads the documented example without editing module files' {
        Register-PS7CompletionProvider -Name example -CommandName mytool,mytool.exe -Path (Join-Path $PSScriptRoot '../../examples/mytool.ps1')
        (Complete-Line 'mytool bu').CompletionText | Should -Contain build
        (Complete-Line 'mytool.exe deploy sta').CompletionText | Should -Contain staging
    }
}
