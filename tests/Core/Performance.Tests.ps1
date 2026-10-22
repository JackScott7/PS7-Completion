BeforeAll {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    Import-Module (Join-Path $root 'src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Performance behavior invariants' {
    It 'filters before capping while preserving distinct case and safe insertion' {
        $candidates = @(1..4096 | ForEach-Object { 'noise-{0:d5}' -f $_ }) + @('target','Target','target','target two')
        $actual = @(New-PS7CompletionResult -Candidate $candidates -WordToComplete tar)
        $actual.Count | Should -Be 3
        $actual.CompletionText | Should -Contain "'target two'"
        @($actual | Where-Object { $_.CompletionText -ceq 'target' }).Count | Should -Be 1
        @($actual | Where-Object { $_.CompletionText -ceq 'Target' }).Count | Should -Be 1
    }
    It 'keeps the 512-result limit after filtering and deduplication' {
        $values = @(1..2000 | ForEach-Object { 'value-{0:d5}' -f $_ })
        $result = @(New-PS7CompletionResult -Candidate ($values + $values) -WordToComplete value)
        $result.Count | Should -Be 512
        $result[0].CompletionText | Should -Be 'value-00001'
        $result[-1].CompletionText | Should -Be 'value-00512'
    }
    It 'handles nulls, case variants and absent prefixes in the large-set search' {
        $values = @($null,'') + @(1..800 | ForEach-Object { "noise$_" }) + @('Zoom','zoom','zoom space')
        $result = @(New-PS7CompletionResult -Candidate $values -WordToComplete ZOO)
        $result.Count | Should -Be 3
        $result.CompletionText | Should -Contain "'zoom space'"
        @(New-PS7CompletionResult -Candidate $values -WordToComplete zzz).Count | Should -Be 0
        $values[0] | Should -BeNullOrEmpty
        $values[-1] | Should -Be 'zoom space'
    }
    It 'indexes ownership only after successful registration' {
        { Register-PS7CompletionProvider -Name badperf -CommandName badperf.py -Path (Join-Path $TestDrive missing.ps1) } | Should -Throw
        InModuleScope PS7-Completion { $script:CommandOwners.ContainsKey('badperf.py') | Should -BeFalse }
    }
}
Describe 'Performance comparison gates' {
    BeforeEach {
        $baseline = Join-Path $TestDrive before.json
        $current = Join-Path $TestDrive after.json
        $report = @{
            SchemaVersion=1; Environment=@{Machine='fixture'; PowerShell='7.4'; OS='Windows'; Processor='fixture';LogicalProcessors=2}
            Parameters=@{ColdSamples=3; WarmSamples=20; LiveQueries=$false}
            Import=@{P95Ms=100}; ShellStartup=@{P95Ms=200}
            FirstCompletion=@{}; WarmCompletion=@{ssh=@{Timing=@{P95Ms=2};ResultCounts=@(3,3);Failures=0}}
            Routing=@{};Queries=@{};ResultFormatting=@{Timing=@{P95Ms=10};ResultCounts=@(512);Failures=0};FailedProviders=@()
        }
        $report | ConvertTo-Json -Depth 8 | Set-Content $baseline
    }
    It 'reports noise-tolerant timing changes and enforces only when requested' {
        $report.Import.P95Ms=160
        $report.WarmCompletion.ssh.Timing.P95Ms=3
        $report | ConvertTo-Json -Depth 8 | Set-Content $current
        $result = & (Join-Path $root 'scripts/Compare-Performance.ps1') -Baseline $baseline -Current $current
        $result.TimingRegressions | Should -Contain Import
        $result.TimingRegressions | Should -Not -Contain 'WarmCompletion/ssh'
        { & (Join-Path $root 'scripts/Compare-Performance.ps1') -Baseline $baseline -Current $current -EnforceTiming } | Should -Throw '*regressions*'
    }
    It 'rejects fast results that lost candidates' {
        $report.WarmCompletion.ssh.ResultCounts=@(0,0)
        $report | ConvertTo-Json -Depth 8 | Set-Content $current
        { & (Join-Path $root 'scripts/Compare-Performance.ps1') -Baseline $baseline -Current $current } | Should -Throw '*no results*'
    }
    It 'rejects comparisons from different machines' {
        $report.Environment.Machine='another'
        $report | ConvertTo-Json -Depth 8 | Set-Content $current
        { & (Join-Path $root 'scripts/Compare-Performance.ps1') -Baseline $baseline -Current $current } | Should -Throw '*environment*'
    }
}
