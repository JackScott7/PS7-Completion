BeforeDiscovery {
    $registry = Import-PowerShellDataFile (Join-Path $PSScriptRoot '../../src/PS7-Completion/Registry.psd1')
    $cases = foreach ($name in $registry.Keys) { @{ Name=$name; Commands=$registry[$name].Commands } }
}
BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Bundled provider inventory contract' {
    It 'returns bounded typed static results for every <Name> executable' -ForEach $cases {
        foreach ($command in $Commands) {
            $prefix = if ($Name -eq 'services') { 'q' } elseif ($Name -in 'schtasks','taskkill','ipconfig','icacls','net','sfc','dism','reg') { '/' } else { '-' }
            $line = "$command $prefix"
            $results = @([Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches)
            $results.Count | Should -BeGreaterThan 0
            $results.Count | Should -BeLessOrEqual 512
            foreach ($item in $results) {
                $item | Should -BeOfType ([Management.Automation.CompletionResult])
                $item.ToolTip | Should -Not -BeNullOrEmpty
            }
            (Get-PS7CompletionProvider | Where-Object Name -EQ $Name).Status | Should -Be 'Loaded'
        }
    }
}
