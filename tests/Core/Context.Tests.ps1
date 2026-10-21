BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Context and insertion boundaries' {
    It 'ignores commands before a pipeline and arguments after the cursor' {
        Register-PS7CompletionProvider -Name contextfixture -CommandName contextfixture.exe -ScriptBlock {
            param($context)
            if ($context.ArgumentIndex -eq 1 -and $context.PreviousArguments[0] -eq 'two words') {
                New-PS7CompletionResult -Candidate help -WordToComplete $context.WordToComplete
            }
        }
        $line = 'echo ignored | contextfixture.exe "two words" he later'
        $cursor = $line.IndexOf('he later') + 2
        [Management.Automation.CommandCompletion]::CompleteInput($line,$cursor,$null).CompletionMatches.CompletionText | Should -Contain help
    }
    It 'does not invoke custom providers for expression or redirection contexts' {
        $global:PS7FixtureCalls = 0
        try {
            Register-PS7CompletionProvider -Name expressionfixture -CommandName expressionfixture.exe -ScriptBlock { $global:PS7FixtureCalls++ }
            foreach ($line in @('expressionfixture.exe $env:PATH ', 'expressionfixture.exe $(Get-Date) ', 'expressionfixture.exe > target')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            }
            $global:PS7FixtureCalls | Should -Be 0
        }
        finally { Remove-Variable PS7FixtureCalls -Scope Global }
    }
    It 'preserves SSH options differing only by case' {
        $line = 'ssh -a'
        $matches = [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText
        ($matches -ccontains '-a') | Should -BeTrue
        ($matches -ccontains '-A') | Should -BeTrue
    }
    It 'quotes leading at signs rather than creating splat expressions' {
        (New-PS7CompletionResult -Candidate '@value').CompletionText | Should -Be "'@value'"
    }
    It 'parses escaped spaces and literal escaped dollar signs without evaluation' {
        (New-PS7CompletionResult -Candidate 'two words' -WordToComplete 'two` wo').CompletionText | Should -Be "'two words'"
        (New-PS7CompletionResult -Candidate '$literal' -WordToComplete '"`$lit').CompletionText | Should -Be "'`$literal'"
    }
    It 'really skips excluded registrations and validates all settings first' {
        $manifest = (Get-Module PS7-Completion).Path.Replace('.psm1','.psd1')
        $code = @'
param($manifest)
Register-ArgumentCompleter -Native -CommandName ssh -ScriptBlock { [Management.Automation.CompletionResult]::new('sentinel','sentinel','ParameterValue','sentinel') }
Import-Module $manifest -ArgumentList @{ Exclude = @('ssh') }
$result = [Management.Automation.CommandCompletion]::CompleteInput('ssh se',6,$null)
if ('sentinel' -notin $result.CompletionMatches.CompletionText) { exit 1 }
'@
        $file = Join-Path $TestDrive 'exclude.ps1'
        Set-Content $file $code
        & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -NonInteractive -File $file $manifest
        $LASTEXITCODE | Should -Be 0
        { Import-Module $manifest -Force -ArgumentList @{ Invalid = 1 } -ErrorAction Stop } | Should -Throw '*configuration key*'
    }
}
