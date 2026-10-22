BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
    Register-PS7CompletionProvider -Name mom -CommandName mom.py -Path (Join-Path $PSScriptRoot '../../examples/mom.ps1')
    function Complete-PythonLine([string] $Line, [int] $Cursor = $Line.Length) {
        @([System.Management.Automation.CommandCompletion]::CompleteInput($Line, $Cursor, $null).CompletionMatches | ForEach-Object CompletionText)
    }
}
Describe 'Python script routing' {
    It 'routes <_> without launching Python or the script' -ForEach @(
        'mom.py a', '.\mom.py a', 'python mom.py a', 'python.exe mom.py a',
        'python3 mom.py a', 'python3.exe mom.py a', 'python -I -W ignore -X dev mom.py a',
        'python -Wignore -Xdev -- mom.py a', 'python "C:\my scripts\mom.py" a',
        '& "C:\Python\python.exe" .\mom.py a', 'python MOM.PY a'
    ) {
        Complete-PythonLine $_ | Should -Contain add
    }
    It 'does not route unsupported interpreter contexts: <_>' -ForEach @(
        'python -m mom.py a', 'python -c mom.py a', 'python -cmom.py a',
        'python -mmom.py a', 'python - mom.py a', 'python -Z mom.py a',
        'python -W mom.py a', 'python other.py a', 'python --help mom.py a',
        'python $scriptName a', 'python $(Get-Item mom.py) a', 'python mom.py add a'
    ) {
        Complete-PythonLine $_ | Should -Not -Contain add
    }
    It 'preserves interpreter and pip completion' {
        Complete-PythonLine 'python --ver' | Should -Contain '--version'
        Complete-PythonLine 'python -m p' | Should -Contain pip
        Complete-PythonLine 'python -m pip ins' | Should -Contain install
    }
    It 'truncates at the cursor and ignores later arguments' {
        $line = 'python mom.py ad ignored'
        Complete-PythonLine $line ('python mom.py ad'.Length) | Should -Contain add
    }
    It 'gives both invocations equivalent script arguments and original AST offsets' {
        Register-PS7CompletionProvider -Name contextpy -CommandName contextpy.py -ScriptBlock {
            param($context)
            if ($context.ArgumentIndex -ne 1 -or $context.PreviousArguments[0] -ne 'two words' -or
                $context.Arguments[0] -ne "'two words'" -or $context.Values[0] -ne 'two words' -or
                $context.Arguments[1] -ne 'ch' -or $context.Values[1] -ne 'ch' -or
                $context.CursorPosition -ne $context.CommandAst.Extent.EndOffset) { throw 'Wrong context' }
            New-PS7CompletionResult -Candidate checked -WordToComplete $context.WordToComplete
        }
        Complete-PythonLine "contextpy.py 'two words' ch" | Should -Contain checked
        Complete-PythonLine "python -I contextpy.py 'two words' ch" | Should -Contain checked
    }
    It 'shares lazy loading and replacement across invocation forms' {
        $file = Join-Path $TestDrive 'lazy.ps1'
        Set-Content $file '{ param($c) New-PS7CompletionResult -Candidate initial -WordToComplete $c.WordToComplete }'
        Register-PS7CompletionProvider -Name lazypy -CommandName lazypy.py -Path $file
        (Get-PS7CompletionProvider | Where-Object Name -EQ lazypy).Loaded | Should -BeFalse
        Complete-PythonLine 'python lazypy.py ini' | Should -Contain initial
        Set-Content $file 'throw "must not reload"'
        Complete-PythonLine 'lazypy.py ini' | Should -Contain initial
        Register-PS7CompletionProvider -Name lazypy -CommandName lazypy.py -Force -ScriptBlock {
            New-PS7CompletionResult -Candidate replaced
        }
        Complete-PythonLine 'python lazypy.py rep' | Should -Contain replaced
    }
    It 'isolates routed failures and attributes status to the script provider' {
        Register-PS7CompletionProvider -Name failpy -CommandName failpy.py -ScriptBlock {
            New-PS7CompletionResult -Candidate leaked
            Write-Warning 'discard the whole request'
        }
        Complete-PythonLine 'python failpy.py lea' | Should -Not -Contain leaked
        (Get-PS7CompletionProvider | Where-Object Name -EQ failpy).Status | Should -Be Failed
    }
}
