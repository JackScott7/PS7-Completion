#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][switch] $DisposableRunner, [string] $BuildMetadata, [string] $UpgradeBuildMetadata)
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
$next = if ($UpgradeBuildMetadata) { Get-Content -LiteralPath $UpgradeBuildMetadata -Raw | ConvertFrom-Json }
else { & (Join-Path $PSScriptRoot 'Build.ps1') -Installer -Version "$($nextVersion.Major).$($nextVersion.Minor).$($nextVersion.Build + 1)" }
if ([version]$next.Version -le [version]$base.Version) { throw 'Upgrade version must be newer than baseline.' }
foreach ($build in @($base,$next)) {
    $metadataPath = Join-Path (Split-Path $build.Installer) 'lifecycle-build.json'
    $build | ConvertTo-Json | Set-Content $metadataPath
    & (Join-Path $PSScriptRoot 'New-WinGetManifest.ps1') -BuildMetadata $metadataPath -OutputDirectory (Join-Path (Split-Path $build.Installer) 'manifest') | Out-Null
}
function Invoke-InstallerFile([string] $File, [string] $Log) {
    $process = Start-Process -FilePath $File -ArgumentList @('/SP-', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$Log`"") -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Installer failed with exit code $($process.ExitCode). See $Log" }
}
$logRoot = Join-Path $root 'dist/installer-evidence'
New-Item -ItemType Directory $logRoot -Force | Out-Null
try {
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
# Reinstallation must repair a modified installer-owned file.
$ownedFile = Join-Path $installRoot "$($base.Version)/PS7-Completion.psm1"
Set-Content -LiteralPath $ownedFile '# damaged fixture'
Invoke-InstallerFile $base.Installer (Join-Path $logRoot 'repair.log')
if ((Get-FileHash $ownedFile).Hash -ne (Get-FileHash (Join-Path $base.Payload 'PS7-Completion.psm1')).Hash) { throw 'Reinstall did not repair owned file.' }
$userFile = Join-Path $installRoot "$($base.Version)/user-added.txt"
Set-Content -LiteralPath $userFile 'Must survive uninstall'
Invoke-InstallerFile $next.Installer (Join-Path $logRoot 'upgrade.log')
if (-not (Test-Path $baseManifest)) { throw 'Upgrade removed the retained version.' }
foreach ($file in Get-ChildItem -LiteralPath $next.Payload -Recurse -File) {
    $relative = [IO.Path]::GetRelativePath($next.Payload, $file.FullName)
    $installed = Join-Path $installRoot "$($next.Version)/$relative"
    if (-not (Test-Path -LiteralPath $installed) -or (Get-FileHash $installed).Hash -ne (Get-FileHash $file.FullName).Hash) { throw "Upgrade payload mismatch: $relative" }
}
$version = & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -NonInteractive -Command 'Import-Module PS7-Completion -ErrorAction Stop; (Get-Module PS7-Completion).Version.ToString()'
if ($LASTEXITCODE -ne 0 -or $version -ne $next.Version) { throw 'New shell did not discover the upgraded version.' }
$uninstaller = Join-Path $installRoot '.installer/unins000.exe'
Invoke-InstallerFile $uninstaller (Join-Path $logRoot 'uninstall.log')
if (Test-Path $baseManifest) { throw 'Uninstall retained an installer-owned old manifest.' }
if (Test-Path (Join-Path $installRoot "$($next.Version)/PS7-Completion.psd1")) { throw 'Uninstall retained the new manifest.' }
if (-not (Test-Path -LiteralPath $userFile)) { throw 'Uninstall removed a user-added file.' }
if ($beforePath -ne $env:PATH -or $beforeModulePath -ne $env:PSModulePath) { throw 'Search paths changed.' }
@{ Result = 'Passed'; Base = $base.Version; Upgrade = $next.Version; ExplicitUpgrade = [bool]$UpgradeBuildMetadata;
    BaseSHA256=(Get-FileHash $base.Installer).Hash; UpgradeSHA256=(Get-FileHash $next.Installer).Hash;
    PowerShell = $PSVersionTable.PSVersion.ToString(); OS = $PSVersionTable.OS } | ConvertTo-Json | Set-Content (Join-Path $logRoot 'result.json')
}
catch {
    @{ Result='Failed'; Base=$base.Version; Upgrade=$next.Version;
        Error=$_.Exception.Message; PowerShell=$PSVersionTable.PSVersion.ToString(); OS=$PSVersionTable.OS } |
        ConvertTo-Json | Set-Content (Join-Path $logRoot 'result.json')
    throw
}
# Keep the fixture and logs for inspection. The disposable VM is discarded by CI.
