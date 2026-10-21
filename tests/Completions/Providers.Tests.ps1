BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Native static provider integration' {
    It 'lists commands before options for <Line>' -ForEach @(
        @{ Line = 'uv ' }
        @{ Line = 'git ' }
        @{ Line = 'gh ' }
        @{ Line = 'pip ' }
        @{ Line = 'python -m pip ' }
        @{ Line = 'flask ' }
        @{ Line = 'fastapi ' }
        @{ Line = 'tailscale ' }
        @{ Line = 'npm ' }
        @{ Line = 'rustup ' }
        @{ Line = 'winget ' }
        @{ Line = 'uv tool ' }
        @{ Line = 'gh pr ' }
        @{ Line = 'rustup toolchain ' }
    ) {
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null)
        $matches = @($result.CompletionMatches)
        $commands = @($matches | Where-Object ResultType -EQ Command)
        $options = @($matches | Where-Object ResultType -NE Command)
        $commands.Count | Should -BeGreaterThan 0
        $options.Count | Should -BeGreaterThan 0
        $matches.CompletionText | Should -Be @($commands.CompletionText + $options.CompletionText)
        $commands.CompletionText | Should -Be @($commands.CompletionText | Sort-Object -CaseSensitive)
        $options.CompletionText | Should -Be @($options.CompletionText | Sort-Object -CaseSensitive)
    }

    It 'completes <Line> without executing the native command' -ForEach @(
        @{ Line = 'ssh -'; Expected = '-p' }
        @{ Line = 'winget ins'; Expected = 'install' }
        @{ Line = 'schtasks /q'; Expected = '/Query' }
        @{ Line = 'sc.exe que'; Expected = 'query' }
        @{ Line = 'taskkill /p'; Expected = '/PID' }
    ) {
        $result = [System.Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null)
        $result.CompletionMatches.CompletionText | Should -Contain $Expected
    }
}
