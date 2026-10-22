BeforeDiscovery { $capabilities = Import-PowerShellDataFile (Join-Path $PSScriptRoot '../Fixtures/option-values.psd1') }
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'F1 option value capability matrix' {
    It 'completes supported finite operands: <Line>' -ForEach $capabilities.FiniteValues {
        [Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText | Should -Contain $Expected
    }
    It 'suppresses finite values in unsupported contexts: <Line>' -ForEach @(
        @{ Line='winget search --scope=ma'; Forbidden='--scope=machine' }
        @{ Line='winget install --id=ma'; Forbidden='machine' }
        @{ Line='schtasks /Create /SC DAILY /D MO'; Forbidden='MON' }
        @{ Line='schtasks /Create /SC MONTHLY /MO LASTDAY /D MO'; Forbidden='MON' }
        @{ Line='sc.exe config Example binPath= au'; Forbidden='auto' }
        @{ Line='sc.exe config Example start=au'; Forbidden='start=auto' }
        @{ Line='ssh -- -i'; Forbidden='-i' }
    ) {
        @([Management.Automation.CommandCompletion]::CompleteInput($Line,$Line.Length,$null).CompletionMatches.CompletionText) | Should -Not -Contain $Forbidden
    }
    It 'completes literal paths with quoting for separate and attached operands' {
        $folder = Join-Path $TestDrive 'literal [files]'
        New-Item -ItemType Directory $folder | Out-Null
        $file = Join-Path $folder "key's file.json"
        Set-Content -LiteralPath $file -Value '{}'
        foreach ($prefix in @('ssh -i ', 'ssh -F ', 'ssh -i', 'ssh -F', 'winget import -i ', 'winget export --output ', 'winget import --import-file=')) {
            $line = $prefix + "'" + $folder + "\key"
            # For attached forms quote the complete native argument.
            if ($prefix -in @('ssh -i','ssh -F','winget import --import-file=')) {
                $split = $prefix.LastIndexOf(' ') + 1
                $line = $prefix.Substring(0,$split) + "'" + $prefix.Substring($split) + $folder + '\key'
            }
            $matches = @([Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches)
            $matches.ListItemText | Should -Contain ($prefix.Substring($prefix.LastIndexOf(' ') + 1) + $file)
            foreach ($match in $matches) {
                $tokens = $null; $errors = $null
                [void][Management.Automation.Language.Parser]::ParseInput(('native ' + $match.CompletionText),[ref]$tokens,[ref]$errors)
                $errors.Count | Should -Be 0
            }
        }
    }
    It 'does not enumerate remote paths or paths through reparse points' {
        InModuleScope PS7-Completion {
            @(Complete-PS7LocalPath '\\server\share\').Count | Should -Be 0
            @(Complete-PS7LocalPath '//server/share/').Count | Should -Be 0
        }
    }
    It 'skips linked directories and missing paths' {
        $target = New-Item -ItemType Directory (Join-Path $TestDrive 'target')
        Set-Content (Join-Path $target.FullName 'secret') 'fixture'
        $link = Join-Path $TestDrive 'link'
        New-Item -ItemType Junction -Path $link -Target $target.FullName | Out-Null
        try {
            InModuleScope PS7-Completion -Parameters @{ Link = $link; Missing = (Join-Path $TestDrive 'missing/') } {
                @(Complete-PS7LocalPath ($Link + '\')).Count | Should -Be 0
                @(Complete-PS7LocalPath $Missing).Count | Should -Be 0
            }
        } finally { [IO.Directory]::Delete($link) }
    }
    It 'accepts literal attached drive paths while rejecting expressions' {
        InModuleScope PS7-Completion {
            ConvertFrom-PS7Literal '-FC:\config' | Should -Be '-FC:\config'
            { ConvertFrom-PS7Literal '-F:$(throw "never execute")' } | Should -Throw
            { ConvertFrom-PS7Literal '-F:$env:USERPROFILE' } | Should -Throw
        }
    }
    It 'uses the last attached SSH config and respects end of options' {
        $config = Join-Path $TestDrive 'hosts'
        Set-Content $config 'Host fixture-host'
        $line = "ssh -Fnone -F$config -- fixture-"
        [Management.Automation.CommandCompletion]::CompleteInput($line,$line.Length,$null).CompletionMatches.CompletionText | Should -Contain fixture-host
    }
}
