#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][switch] $DisposableRunner, [string] $BuildMetadata)
$ErrorActionPreference = 'Stop'
if (-not $DisposableRunner -or $env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') {
    throw 'Installer lifecycle tests require an explicitly disposable GitHub-hosted runner.'
}
$root = Split-Path $PSScriptRoot -Parent
$installRoot = Join-Path $env:ProgramFiles 'PowerShell/Modules/PS7-Completion'
if (Test-Path -LiteralPath $installRoot) { throw 'Refusing to test over an existing module installation.' }
$beforePath = $env:PATH
$beforeModulePath = $env:PSModulePath
$base = if ($BuildMetadata) { Get-Content -LiteralPath $BuildMetadata -Raw | ConvertFrom-Json } else { & (Join-Path $PSScriptRoot 'Build.ps1') -Installer }
if (-not $base.Installer -or -not (Test-Path -LiteralPath $base.Installer)) { throw 'A built installer is required.' }
$nextVersion = [version]$base.Version
$next = & (Join-Path $PSScriptRoot 'Build.ps1') -Installer -Version "$($nextVersion.Major).$($nextVersion.Minor).$($nextVersion.Build + 1)"
function Invoke-InstallerFile([string] $File, [string] $Log) {
    $process = Start-Process -FilePath $File -ArgumentList @('/SP-', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$Log`"") -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Installer failed with exit code $($process.ExitCode). See $Log" }
}
$logRoot = Join-Path $root 'dist/installer-evidence'
New-Item -ItemType Directory $logRoot -Force | Out-Null
Invoke-InstallerFile $base.Installer (Join-Path $logRoot 'install.log')
$baseManifest = Join-Path $installRoot "$($base.Version)/PS7-Completion.psd1"
if (-not (Test-Path $baseManifest)) { throw 'Initial installation is missing.' }
foreach ($file in Get-ChildItem -LiteralPath $base.Payload -Recurse -File) {
    $relative = [IO.Path]::GetRelativePath($base.Payload, $file.FullName)
    $installed = Join-Path $installRoot "$($base.Version)/$relative"
    if (-not (Test-Path -LiteralPath $installed) -or
        (Get-FileHash -LiteralPath $installed).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
        throw "Installed payload mismatch: $relative"
    }
}
Invoke-InstallerFile $base.Installer (Join-Path $logRoot 'reinstall.log')
$userFile = Join-Path $installRoot "$($base.Version)/user-added.txt"
Set-Content -LiteralPath $userFile 'Must survive uninstall'
Invoke-InstallerFile $next.Installer (Join-Path $logRoot 'upgrade.log')
if (-not (Test-Path $baseManifest)) { throw 'Upgrade removed the retained version.' }
$version = & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -NonInteractive -Command 'Import-Module PS7-Completion -ErrorAction Stop; (Get-Module PS7-Completion).Version.ToString()'
if ($LASTEXITCODE -ne 0 -or $version -ne $next.Version) { throw 'New shell did not discover the upgraded version.' }
$uninstaller = Join-Path $installRoot '.installer/unins000.exe'
Invoke-InstallerFile $uninstaller (Join-Path $logRoot 'uninstall.log')
if (Test-Path $baseManifest) { throw 'Uninstall retained an installer-owned old manifest.' }
if (Test-Path (Join-Path $installRoot "$($next.Version)/PS7-Completion.psd1")) { throw 'Uninstall retained the new manifest.' }
if (-not (Test-Path -LiteralPath $userFile)) { throw 'Uninstall removed a user-added file.' }
if ($beforePath -ne $env:PATH -or $beforeModulePath -ne $env:PSModulePath) { throw 'Search paths changed.' }
@{ Result = 'Passed'; Base = $base.Version; Upgrade = $next.Version; PowerShell = $PSVersionTable.PSVersion.ToString(); OS = $PSVersionTable.OS } | ConvertTo-Json | Set-Content (Join-Path $logRoot 'result.json')
# Keep the fixture and logs for inspection. The disposable VM is discarded by CI.
