BeforeAll {
    $manifest = Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1'
    $originalPath = $env:PATH
    $first = Join-Path $TestDrive 'first'
    $second = Join-Path $TestDrive 'second'
    $null = New-Item -ItemType Directory -Path $first, $second
    $null = New-Item -ItemType File -Path (Join-Path $first 'ps7fixture.exe'), (Join-Path $second 'ps7fixture.exe')
    $env:PATH = "$first;$second;$originalPath"
}
AfterAll {
    Remove-Module PS7-Completion -ErrorAction SilentlyContinue
    $env:PATH = $originalPath
}
Describe 'Extensionless executable completion' {
    It 'uses the first executable in PATH and removes duplicate results' {
        Import-Module $manifest -Force -ArgumentList @{ ExtensionlessCommands = $true }
        $results = (TabExpansion2 'ps7fix' 6).CompletionMatches
        @($results | Where-Object ListItemText -Match '^ps7fixture').Count | Should -Be 1
        $results[0].CompletionText | Should -Be 'ps7fixture'
        $results[0].ToolTip | Should -Be (Join-Path $first 'ps7fixture.exe')
        $env:PATH = "$second;$first;$originalPath"
        try { (TabExpansion2 'ps7fix' 6).CompletionMatches[0].ToolTip | Should -Be (Join-Path $second 'ps7fixture.exe') }
        finally { $env:PATH = "$first;$second;$originalPath" }
    }
    It 'preserves explicit paths and extensions' {
        (TabExpansion2 'ps7fixture.ex' 13).CompletionMatches.CompletionText | Should -Contain 'ps7fixture.exe'
        $line = Join-Path $first 'ps7fix'
        (TabExpansion2 $line $line.Length).CompletionMatches.CompletionText | Should -Match '\.exe'
    }
    It 'keeps the executable extension when an alias takes precedence' {
        Set-Alias -Name ps7fixture -Value Get-Item -Scope Global
        try { (TabExpansion2 'ps7fix' 6).CompletionMatches.CompletionText | Should -Contain 'ps7fixture.exe' }
        finally { Remove-Item Alias:\ps7fixture -Force }
    }
    It 'continues to complete arguments' {
        (TabExpansion2 'python --ver' 12).CompletionMatches.CompletionText | Should -Contain '--version'
    }
    It 'restores the prior completion function on removal' {
        Remove-Module PS7-Completion
        (TabExpansion2 'ps7fix' 6).CompletionMatches.CompletionText | Should -Contain 'ps7fixture.exe'
    }
}
