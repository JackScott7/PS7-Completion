BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Bounded query cache' {
    BeforeEach { InModuleScope PS7-Completion { Clear-PS7CompletionCache } }
    It 'shares equivalent lexical SSH paths but keeps different directories distinct' {
        InModuleScope PS7-Completion -Parameters @{ Root = $TestDrive } {
            param($Root)
            Mock Read-PS7SshConfig { @{ Hosts=@('one'); Dependencies=@() } }
            $first = Join-Path $Root 'config'
            Get-PS7QueryData SshHosts $first | Out-Null
            Get-PS7QueryData SshHosts (Join-Path $Root './config') | Out-Null
            Get-PS7QueryData SshHosts (Join-Path $Root 'other/config') | Out-Null
            Should -Invoke Read-PS7SshConfig -Times 2 -Exactly
        }
    }
    It 'tracks shared SSH dependencies only once and invalidates file edits' {
        $root = Join-Path $TestDrive 'root'
        $child = Join-Path $TestDrive 'child'
        Set-Content $child 'Host first'
        Set-Content $root @("Include `"$child`"", "Include `"$child`"")
        InModuleScope PS7-Completion -Parameters @{ Root=$root; Child=$child } {
            param($Root,$Child)
            $parsed = Read-PS7SshConfig $Root
            $paths = @($parsed.Dependencies | ForEach-Object Path)
            $paths.Count | Should -Be @($paths | Sort-Object -Unique).Count
            Get-PS7QueryData SshHosts $Root | Should -Contain first
            Set-Content $Child 'Host updated-longer'
            Get-PS7QueryData SshHosts $Root | Should -Contain updated-longer
        }
    }
    It 'includes link targets in dependency identity even with equal size and timestamp' {
        InModuleScope PS7-Completion {
            $a = [pscustomobject]@{ PSIsContainer=$true; LastWriteTimeUtc=[datetime]'2026-01-01'; Attributes='ReparsePoint'; LinkTarget='C:\first' }
            $b = [pscustomobject]@{ PSIsContainer=$true; LastWriteTimeUtc=[datetime]'2026-01-01'; Attributes='ReparsePoint'; LinkTarget='C:\second' }
            (Get-PS7DependencyStamp -Path 'link' -Item $a) | Should -Not -Be (Get-PS7DependencyStamp -Path 'link' -Item $b)
        }
    }
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
            $path = [IO.Path]::GetFullPath('a', $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path)
            $script:Cache["SshHosts|$path"].Created -= 31 * [Diagnostics.Stopwatch]::Frequency
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
