BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'WinGet static contexts' {
    It 'selects commands, options, and finite operands by position' -ForEach @(
        @{ Line='winget ins'; Expected='install' }
        @{ Line='winget install --sc'; Expected='--scope' }
        @{ Line='winget install --scope ma'; Expected='machine' }
        @{ Line='winget install --id Example.App --ar'; Expected='--architecture' }
        @{ Line='winget export --out'; Expected='--output' }
        @{ Line='winget import --imp'; Expected='--import-file' }
        @{ Line='winget source ad'; Expected='add' }
        @{ Line='winget source add --ar'; Expected='--arg' }
    ) {
        [Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText | Should -Contain $Expected
    }
    It 'does not suggest commands in operands or options of other subcommands' {
        foreach ($line in @('winget install --id ins', 'winget search --scope ma', 'winget import --out', 'winget unknown ins')) {
            $results = @([Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches)
            @($results | Where-Object CompletionText -In install,machine,--output).Count | Should -Be 0
        }
    }
    It 'never performs package searches during completion' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { throw 'Unexpected dynamic query' }
            $line = 'winget search --name '
            [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            Should -Invoke Get-PS7QueryData -Times 0
        }
    }
}
