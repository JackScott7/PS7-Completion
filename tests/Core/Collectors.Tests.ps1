BeforeAll {
    . (Join-Path $PSScriptRoot '../../src/PS7-Completion/Workers/Collectors.ps1')
}
Describe 'Bounded worker collectors' {
    It 'limits service results, skips inaccessible entries and disposes all controllers' {
        $services = @(1..5000 | ForEach-Object {
            $item = [pscustomobject]@{ ServiceName="service$_"; Disposed=$false }
            $item | Add-Member ScriptMethod Dispose { $this.Disposed = $true }
            $item
        })
        $services[2] | Add-Member ScriptProperty ServiceName { throw 'access denied' } -Force
        $result = @(Get-PS7ServiceValue $services)
        $result.Count | Should -Be 4095
        $result | Should -Contain 'service4096'
        $result | Should -Not -Contain 'service4097'
        @($services | Where-Object { -not $_.Disposed }).Count | Should -Be 0
    }
    It 'traverses task folders only until the 4096 task limit' {
        $folder = [pscustomobject]@{}
        $folder | Add-Member ScriptMethod GetTasks { param($flags) @(1..5000 | ForEach-Object { [pscustomobject]@{ Path="\fixture$_" } }) }
        $folder | Add-Member ScriptMethod GetFolders { param($flags) @() }
        $scheduler = [pscustomobject]@{ Folder=$folder }
        $scheduler | Add-Member ScriptMethod GetFolder { param($path) $this.Folder }
        Mock Close-PS7TaskObject {}
        $result = @(Get-PS7TaskValue $scheduler)
        $result.Count | Should -Be 4096
        $result[-1] | Should -Be '\fixture4096'
        Should -Invoke Close-PS7TaskObject -Times 4097 -Exactly
    }
    It 'limits traversal through large folder trees' {
        $folder = [pscustomobject]@{}
        $folder | Add-Member ScriptMethod GetTasks { param($flags) @() }
        $folder | Add-Member ScriptMethod GetFolders { param($flags) @([pscustomobject]@{ Path='\next' }) }
        $scheduler = [pscustomobject]@{ Folder=$folder; Calls=0 }
        $scheduler | Add-Member ScriptMethod GetFolder { param($path) $this.Calls++; $this.Folder }
        Mock Close-PS7TaskObject {}
        @(Get-PS7TaskValue $scheduler).Count | Should -Be 0
        $scheduler.Calls | Should -Be 4096
    }
}
