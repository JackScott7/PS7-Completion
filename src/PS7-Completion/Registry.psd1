@{
    ssh = @{ Commands = @('ssh', 'ssh.exe'); File = 'Completions/ssh.ps1' }
    winget = @{ Commands = @('winget', 'winget.exe'); File = 'Completions/winget.ps1' }
    schtasks = @{ Commands = @('schtasks', 'schtasks.exe'); File = 'Completions/schtasks.ps1' }
    services = @{ Commands = @('sc.exe'); File = 'Completions/sc.ps1' }
    taskkill = @{ Commands = @('taskkill', 'taskkill.exe'); File = 'Completions/taskkill.ps1' }
}
