BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Scale and refresh contracts' {
    BeforeEach { InModuleScope PS7-Completion { Clear-PS7CompletionCache } }
    It 'bounds and deduplicates large <Kind> snapshots' -ForEach @(
        @{ Kind='Tasks' }, @{ Kind='Services' }, @{ Kind='Processes' }
    ) {
        InModuleScope PS7-Completion -Parameters @{ Kind=$Kind } {
            param($Kind)
            Mock Invoke-PS7QueryProcess {
                $items = foreach ($i in 1..10000) {
                    if ($Request.Kind -eq 'Processes') { @{ Id=[string]$i; Name='fixture.exe' }; @{ Id=[string]$i; Name='fixture.exe' } }
                    else { "value$i"; "value$i" }
                }
                @{ Data=$items; Dependencies=@() }
            }
            $data = @(Get-PS7QueryData $Kind)
            $data.Count | Should -Be 4096
            if ($Kind -eq 'Processes') { $data[-1].Id | Should -Be '4096' }
            else { $data[-1] | Should -Be 'value4096' }
        }
    }
    It 'refreshes removed entities after TTL and does not repopulate a cleared cache for <Kind>' -ForEach @(
        @{ Kind='Tasks' }, @{ Kind='Services' }, @{ Kind='Processes' }
    ) {
        InModuleScope PS7-Completion -Parameters @{ Kind=$Kind } {
            param($Kind)
            Mock Invoke-PS7QueryProcess { @{ Data=@(@{ Id='1'; Name='old.exe' }); Dependencies=@() } }
            Get-PS7QueryData $Kind | Out-Null
            $script:Cache["$Kind|"].Created -= 31 * [Diagnostics.Stopwatch]::Frequency
            Mock Invoke-PS7QueryProcess { @{ Data=@(); Dependencies=@() } }
            @(Get-PS7QueryData $Kind).Count | Should -Be 0
            Clear-PS7CompletionCache
            Mock Invoke-PS7QueryProcess { Clear-PS7CompletionCache; @{ Data=@(@{ Id='2'; Name='late.exe' }); Dependencies=@() } }
            Get-PS7QueryData $Kind | Out-Null
            $script:Cache.Count | Should -Be 0
        }
    }
    It 'does not cache an SSH snapshot changed during collection' {
        InModuleScope PS7-Completion {
            Mock Read-PS7SshConfig { @{ Hosts=@('old'); Dependencies=@(@{ Path='fixture'; Stamp='before' }) } }
            Mock Get-PS7DependencyStamp { 'after' }
            Get-PS7QueryData SshHosts fixture | Out-Null
            $script:Cache.Count | Should -Be 0
        }
    }
    It 'refreshes a real process after it exits and the cached snapshot expires' {
        $fixture = Start-Process -FilePath (Join-Path $PSHOME 'pwsh.exe') -ArgumentList '-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 120' -WindowStyle Hidden -PassThru
        try {
            $fixtureId = [string]$fixture.Id
            InModuleScope PS7-Completion -Parameters @{ FixtureId=$fixtureId; Fixture=$fixture } {
                param($FixtureId, $Fixture)
                # Cache refresh is under test here. Hosted runner startup can
                # exceed the production completion budget; timeout behavior is
                # covered separately by the worker deadline tests.
                $script:ScaleOriginalQuery = ${function:Invoke-PS7QueryProcess}
                Mock Invoke-PS7QueryProcess { & $script:ScaleOriginalQuery -Request $Request -TimeoutMilliseconds 3000 }
                @(Get-PS7QueryData Processes | Where-Object Id -EQ $FixtureId).Count | Should -Be 1
                $Fixture.Kill()
                $Fixture.WaitForExit()
                @(Get-PS7QueryData Processes | Where-Object Id -EQ $FixtureId).Count | Should -Be 1
                $script:Cache['Processes|'].Created -= 31 * [Diagnostics.Stopwatch]::Frequency
                @(Get-PS7QueryData Processes | Where-Object Id -EQ $FixtureId).Count | Should -Be 0
            }
        }
        finally {
            if (-not $fixture.HasExited) { $fixture.Kill(); $fixture.WaitForExit() }
            $fixture.Dispose()
        }
    }
    It 'reports peak memory for a measured live query worker' {
        InModuleScope PS7-Completion {
            $result = Invoke-PS7QueryProcess -Request @{ Kind='Processes'; Measure=$true } -TimeoutMilliseconds 3000
            $result.Metrics.WorkerPeakWorkingSetBytes | Should -BeGreaterThan 0
        }
    }
    It 'bounds retained string characters as well as item count' {
        InModuleScope PS7-Completion {
            Mock Invoke-PS7QueryProcess { @{ Data=@(1..100 | ForEach-Object { ([string]$_).PadRight(32768, 'x') }); Dependencies=@() } }
            $data = @(Get-PS7QueryData Tasks)
            $data.Count | Should -Be 32
            ($data | Measure-Object -Character).Characters | Should -Be 1048576
        }
    }
    It 'rejects an oversized SSH include tree without caching partial hosts' {
        $config = Join-Path $TestDrive 'config'
        $lines = foreach ($i in 1..65) {
            $child = Join-Path $TestDrive "child$i"
            Set-Content $child "Host fixture$i"
            'Include "' + $child + '"'
        }
        Set-Content $config $lines
        InModuleScope PS7-Completion -Parameters @{ Config=$config } {
            param($Config)
            { Get-PS7QueryData SshHosts $Config } | Should -Throw
            $script:Cache.Count | Should -Be 0
        }
    }
}
