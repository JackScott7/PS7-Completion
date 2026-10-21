BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Service contexts' {
    It 'uses internal service names only in existing-service positions' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { @('Spooler','TestService') }
            foreach ($line in @('sc.exe create ', 'sc.exe \\remote stop ', 'sc.exe description Spooler ', 'sc.exe config Spooler binPath= ')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            }
            Should -Invoke Get-PS7QueryData -Times 0
            $line = 'sc.exe stop Spo'
            [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain Spooler
            Should -Invoke Get-PS7QueryData -Times 1 -Exactly -ParameterFilter { $Kind -eq 'Services' }
        }
    }
    It 'handles configuration and query values separately from service names' -ForEach @(
        @{ Line = 'sc.exe config Spooler st'; Expected = 'start=' }
        @{ Line = 'sc.exe config Spooler start= au'; Expected = 'auto' }
        @{ Line = 'sc.exe query state= in'; Expected = 'inactive' }
    ) {
        [Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText | Should -Contain $Expected
    }
}
