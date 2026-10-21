BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Native static provider integration' {
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
