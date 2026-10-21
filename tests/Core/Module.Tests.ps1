BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
BeforeAll {
    $manifest = Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1'
    Import-Module $manifest -Force
}
Describe 'Module contract' {
    It 'exports only the two public commands' {
        $commands = @(Get-Command -Module PS7-Completion | Select-Object -ExpandProperty Name)
        $commands.Count | Should -Be 2
        $commands | Should -Contain 'Get-PS7CompletionProvider'
        $commands | Should -Contain 'Clear-PS7CompletionCache'
    }
    It 'registers all five providers without eagerly loading them' {
        @(Get-PS7CompletionProvider).Count | Should -Be 5
        @(Get-PS7CompletionProvider | Where-Object Loaded).Count | Should -Be 0
        (Get-PS7CompletionProvider | Where-Object Name -EQ services).Commands | Should -Be @('sc.exe')
    }
    InModuleScope PS7-Completion {
        It 'preserves quoted argument boundaries and ignores later arguments' {
            $line = 'ssh "two words" host later'
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref] $tokens, [ref] $errors)
            $command = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
            $context = New-PS7CompletionContext 'ho' $command 18
            $context.Arguments.Count | Should -Be 2
            $context.Arguments[0] | Should -Be '"two words"'
            $context.Arguments[1] | Should -Be 'ho'
            $context.ArgumentIndex | Should -Be 1
        }
        It 'treats wildcard characters as literal prefix text' {
            @(New-PS7StaticCompletion @('abc') '*').Count | Should -Be 0
        }
        It 'selects the next argument after trailing whitespace' {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput('ssh host ', [ref] $tokens, [ref] $errors)
            $command = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
            (New-PS7CompletionContext '' $command 9).ArgumentIndex | Should -Be 1
        }
        It 'isolates provider failures' {
            $script:Providers['broken'] = { throw 'fixture failure' }
            try { @(Invoke-PS7Provider -Name broken -WordToComplete '' -CommandAst $null -CursorPosition 0).Count | Should -Be 0 }
            finally { $script:Providers.Remove('broken') }
        }
        It 'clears data without unloading providers' {
            $script:Cache['sample'] = 1
            Clear-PS7CompletionCache
            $script:Cache.Count | Should -Be 0
        }
    }
}
Describe 'Configuration' {
    It 'skips excluded providers at registration time' {
        Import-Module $manifest -Force -ArgumentList @{ Exclude = @('ssh') }
        (Get-PS7CompletionProvider | Where-Object Name -EQ ssh).Enabled | Should -BeFalse
    }
    It 'rejects an unknown provider ID' {
        { Import-Module $manifest -Force -ArgumentList @{ Exclude = @('missing') } -ErrorAction Stop } | Should -Throw '*Unknown provider*'
    }
}
