BeforeAll { Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force }
Describe 'Unavailable local data' {
    It 'does not cache read-denied <Kind> queries and permits recovery' -ForEach @(
        @{ Kind='Processes' }, @{ Kind='Services' }, @{ Kind='Tasks' }
    ) {
        InModuleScope PS7-Completion -Parameters @{ Kind=$Kind } {
            param($Kind)
            Clear-PS7CompletionCache
            Mock Invoke-PS7QueryProcess { throw [UnauthorizedAccessException]::new('fixture denial') }
            { Get-PS7QueryData $Kind } | Should -Throw
            { Get-PS7QueryData $Kind } | Should -Throw
            $script:Cache.Count | Should -Be 0
            Mock Invoke-PS7QueryProcess { @{ Data=@(); Dependencies=@() } }
            @(Get-PS7QueryData $Kind).Count | Should -Be 0
            $script:Cache.Count | Should -Be 1
        }
    }
}
