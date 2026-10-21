; Build through scripts/Build.ps1 -Installer. AppId must remain stable.
#ifndef ModuleVersion
  #error ModuleVersion is required
#endif
#ifndef SourceDir
  #error SourceDir is required
#endif
[Setup]
AppId={{D1452431-C5FC-4982-8B42-334EFA8ABBC0}
AppName=PS7-Completion
AppVersion={#ModuleVersion}
AppPublisher=PS7-Completion contributors
DefaultDirName={autopf64}\PowerShell\Modules\PS7-Completion
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=PS7-Completion-{#ModuleVersion}-windows-x64
Compression=lzma2
SolidCompression=yes
UninstallFilesDir={app}\.installer
CloseApplications=no
RestartApplications=no

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}\{#ModuleVersion}"; Flags: ignoreversion recursesubdirs createallsubdirs
