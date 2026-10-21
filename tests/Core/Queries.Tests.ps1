BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Bounded query cache' {
    BeforeEach { InModuleScope PS7-Completion { Clear-PS7CompletionCache } }
    It 'reads SSH aliases in process without starting a worker' {
        $config = Join-Path $TestDrive 'config'
        Set-Content $config 'Host strawberryvps'
        InModuleScope PS7-Completion -Parameters @{ Config = $config } {
            param($Config)
            Mock Invoke-PS7QueryProcess { throw 'Worker was started.' }
            Get-PS7QueryData SshHosts $Config | Should -Be 'strawberryvps'
            Should -Invoke Invoke-PS7QueryProcess -Times 0
        }
    }
    It 'keeps a time limit on in-process SSH parsing' {
        $config = Join-Path $TestDrive 'config'
        Set-Content $config 'Host strawberryvps'
        InModuleScope PS7-Completion -Parameters @{ Config = $config } {
            param($Config)
            $script:QueryClock = [Diagnostics.Stopwatch]::StartNew()
            Start-Sleep -Milliseconds 501
            try { { Get-PS7QueryData SshHosts $Config } | Should -Throw '*deadline*' }
            finally { $script:QueryClock = $null }
        }
    }
    It 'caches successful empty results' {
        InModuleScope PS7-Completion {
            Mock Invoke-PS7QueryProcess { @{ Data = @(); Dependencies = @() } }
            @(Get-PS7QueryData Processes).Count | Should -Be 0
            @(Get-PS7QueryData Processes).Count | Should -Be 0
            Should -Invoke Invoke-PS7QueryProcess -Times 1 -Exactly
        }
    }
    It 'separates kinds and paths and expires entries after 30 seconds' {
        InModuleScope PS7-Completion {
            Mock Invoke-PS7QueryProcess { @{ Data = @('value'); Dependencies = @() } }
            Mock Read-PS7SshConfig { @{ Hosts = @('value'); Dependencies = @() } }
            Get-PS7QueryData SshHosts a | Out-Null
            Get-PS7QueryData SshHosts b | Out-Null
            Get-PS7QueryData Services | Out-Null
            $script:Cache['SshHosts|a'].Created -= 31 * [Diagnostics.Stopwatch]::Frequency
            Get-PS7QueryData SshHosts a | Out-Null
            Should -Invoke Read-PS7SshConfig -Times 3 -Exactly
            Should -Invoke Invoke-PS7QueryProcess -Times 1 -Exactly
        }
    }
    It 'does not cache failures or results cleared in flight' {
        InModuleScope PS7-Completion {
            Mock Invoke-PS7QueryProcess { throw 'timeout' }
            { Get-PS7QueryData Processes } | Should -Throw
            $script:Cache.Count | Should -Be 0
            Mock Invoke-PS7QueryProcess { Clear-PS7CompletionCache; @{ Data = @('old'); Dependencies = @() } }
            Get-PS7QueryData Processes | Out-Null
            $script:Cache.Count | Should -Be 0
        }
    }
    It 'invalidates dependencies and bounds cache growth' {
        InModuleScope PS7-Completion {
            Mock Read-PS7SshConfig { @{ Hosts = @(); Dependencies = @(@{ Path = 'fixture'; Stamp = 'old' }) } }
            Mock Get-PS7DependencyStamp { 'new' }
            Get-PS7QueryData SshHosts a | Out-Null
            Get-PS7QueryData SshHosts a | Out-Null
            Should -Invoke Read-PS7SshConfig -Times 2 -Exactly
            foreach ($i in 1..130) { Get-PS7QueryData SshHosts "path$i" | Out-Null }
            $script:Cache.Count | Should -Be 128
        }
    }
    It 'kills and reaps a timed-out worker' {
        $worker = Join-Path $TestDrive 'slow.ps1'
        $pidFile = Join-Path $TestDrive 'worker.pid'
        Set-Content $worker "param([string]`$RequestBase64)`n[IO.File]::WriteAllText('$pidFile', [string]`$PID)`nStart-Sleep -Seconds 20"
        InModuleScope PS7-Completion -Parameters @{ Worker = $worker } {
            param($Worker)
            { Invoke-PS7QueryProcess -Request @{} -WorkerPath $Worker -TimeoutMilliseconds 500 } | Should -Throw '*deadline*'
        }
        if (Test-Path $pidFile) { Get-Process -Id ([int](Get-Content $pidFile)) -ErrorAction Ignore | Should -BeNullOrEmpty }
    }
}
