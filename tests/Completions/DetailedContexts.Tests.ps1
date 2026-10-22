BeforeDiscovery { $capabilities = Import-PowerShellDataFile (Join-Path $PSScriptRoot '../Fixtures/detailed-contexts.psd1') }
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    . (Join-Path $PSScriptRoot '../../src/PS7-Completion/Workers/SshConfig.ps1')
}
Describe 'F2 detailed provider contexts' {
    It 'completes <Line>' -ForEach @($capabilities.Positive | Where-Object Expected) {
        @([Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText) | Should -Contain $Expected
    }
    It 'suppresses unrelated candidates for <Line>' -ForEach $capabilities.Negative {
        @([Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText) | Should -Not -Contain $Forbidden
    }
    It 'never queries system data for static filter grammar or source options' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { throw 'Unexpected query' }
            foreach ($line in @('taskkill /FI "PID g', 'taskkill /FI "STATUS eq R', 'winget source list --n', 'winget source add -a ', 'sc.exe config Example obj= Lo')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null)
            }
            Should -Invoke Get-PS7QueryData -Times 0
        }
    }
    It 'completes service dependency lists without suggesting self or duplicates' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { @('Example','Spooler','OtherService') }
            $line = 'sc.exe config Example depend= Spooler/O'
            $results = @([Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText)
            $results | Should -Contain 'Spooler/OtherService'
            foreach ($word in @('Spooler/S','E','+Group')) {
                $line = 'sc.exe config Example depend= ' + $word
                $matches = @([Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches | ForEach-Object { $_.CompletionText })
                $matches | Should -Not -Contain 'Spooler/Spooler'
                $matches | Should -Not -Contain 'Example'
            }
        }
    }
    It 'reads quoted comments, equals directives and Match all without evaluating conditions' {
        $include = Join-Path $TestDrive 'include # file'
        Set-Content -LiteralPath $include 'Host included'
        $config = Join-Path $TestDrive 'config'
        Set-Content $config @('hOsT = "alpha#tag" beta *.wild !excluded', 'Match exec "throw never-execute"', "Include `"$include`"", 'Match all', "Include = `"$include`" # comment", 'Host "broken', 'Host final')
        (Read-PS7SshConfig $config).Hosts | Should -Be @('alpha#tag','beta','final','included')
    }
    It 'preserves conditional state across includes and resets it at a Host block' {
        $conditional = Join-Path $TestDrive 'conditional'
        Set-Content $conditional 'Match exec "never execute"'
        $hidden = Join-Path $TestDrive 'hidden'
        Set-Content $hidden 'Host hidden-alias'
        $shown = Join-Path $TestDrive 'shown'
        Set-Content $shown 'Host shown-alias'
        $root = Join-Path $TestDrive 'root'
        Set-Content $root @("Include `"$conditional`"", "Include `"$hidden`"", 'Host root-alias', "Include `"$shown`"")
        (Read-PS7SshConfig $root).Hosts | Should -Be @('root-alias','shown-alias')
    }
}
