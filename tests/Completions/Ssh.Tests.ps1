BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    . (Join-Path $PSScriptRoot '../../src/PS7-Completion/Workers/SshConfig.ps1')
}
Describe 'SSH configuration parsing' {
    It 'handles comments, multiple literal aliases, includes and cycles' {
        $root = Join-Path $TestDrive 'config'
        $child = Join-Path $TestDrive 'extra'
        Set-Content $root @('Host alpha beta *.invalid !negated # ignored', "Include `"$child`"", 'Match exec "never execute"', 'Include missing', 'Host gamma')
        Set-Content $child @('Host delta', "Include `"$root`"")
        $result = Read-PS7SshConfig $root
        $result.Hosts | Should -Be @('alpha','beta','delta','gamma')
        $result.Dependencies.Count | Should -BeGreaterThan 1
    }
    It 'tracks missing files and wildcard directories for invalidation' {
        $root = Join-Path $TestDrive 'config'
        $included = Join-Path $TestDrive '*.conf'
        Set-Content $root "Include `"$included`""
        Set-Content (Join-Path $TestDrive 'one.conf') 'Host one'
        (Read-PS7SshConfig $root).Hosts | Should -Contain one
        (Read-PS7SshConfig (Join-Path $TestDrive 'missing')).Dependencies[0].Stamp | Should -Match '\|missing$'
    }
    It 'refuses network paths without reading them' {
        (Read-PS7SshConfig '\\server\share\config').Hosts.Count | Should -Be 0
    }
    It 'rejects oversized configs' {
        $path = Join-Path $TestDrive 'large'
        [IO.File]::WriteAllText($path, ('x' * 1048577))
        { Read-PS7SshConfig $path } | Should -Throw '*size limit*'
    }
}
Describe 'SSH argument contexts' {
    It 'only queries hosts in destination position' {
        InModuleScope PS7-Completion {
            Mock Get-PS7QueryData { @('alpha','beta') }
            foreach ($line in @('ssh -p ', 'ssh -i ', 'ssh -J ', 'ssh alpha ', 'ssh -unknown ')) {
                [void][Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null)
            }
            Should -Invoke Get-PS7QueryData -Times 0
            $line = 'ssh -p 22 user@al'
            [Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null).CompletionMatches.CompletionText | Should -Contain 'user@alpha'
            Should -Invoke Get-PS7QueryData -Times 1 -Exactly
        }
    }
}
