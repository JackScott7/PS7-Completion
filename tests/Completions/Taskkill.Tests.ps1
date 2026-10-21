BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Taskkill contexts' {
    It 'returns names and IDs only at their selector operands' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { @(@{ Id = '123'; Name = 'test app.exe' }, @{ Id = '456'; Name = 'other.exe' }) }
            $line = 'taskkill /im te'
            [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain "'test app.exe'"
            $line = 'taskkill /PID 456 /PID 12'
            [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain '123'
            Should -Invoke Get-PS7QueryData -Times 2 -Exactly -ParameterFilter { $Kind -eq 'Processes' }
        }
    }
    It 'does not query local processes for filters, passwords, unknown options or remote targets' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { throw 'unexpected query' }
            foreach ($line in @('taskkill /FI ', 'taskkill /S remote /IM ', 'taskkill /P ', 'taskkill /BOGUS ', 'taskkill unexpected ')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            }
            Should -Invoke Get-PS7QueryData -Times 0
        }
    }
}
