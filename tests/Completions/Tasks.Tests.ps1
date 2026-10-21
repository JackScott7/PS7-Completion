BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Scheduled task contexts' {
    It 'offers operation-specific options and finite values' -ForEach @(
        @{ Line = 'schtasks /Create /s'; Expected = '/SC' }
        @{ Line = 'schtasks /Query /f'; Expected = '/FO' }
        @{ Line = 'schtasks /Create /SC da'; Expected = 'DAILY' }
        @{ Line = 'schtasks /Query /FO c'; Expected = 'CSV' }
    ) {
        [Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText | Should -Contain $Expected
    }
    It 'only enumerates existing local tasks for task-name operands' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { @('\Folder\Test Task') }
            foreach ($line in @('schtasks /Create /TN ', 'schtasks /Run /S remote /TN ', 'schtasks /Change /TR ', 'schtasks /Query /BOGUS ')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            }
            Should -Invoke Get-PS7QueryData -Times 0
            $line = 'schtasks /Run /TN \Fo'
            [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain "'\Folder\Test Task'"
            Should -Invoke Get-PS7QueryData -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Tasks' }
        }
    }
}
