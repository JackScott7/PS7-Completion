# PS7-Completion

Native command completion for Windows and PowerShell 7.4+. **Early scaffold, not
a published v0.1 release.** Five lazy providers currently offer static suggestions:
`ssh`, `winget`, `schtasks`, `sc.exe`, and `taskkill`.

See [the specification](docs/specification.md) for the architecture, full v0.1
acceptance scope, packaging lifecycle, and outstanding release gates.

Follow the [release roadmap](docs/roadmap.md) from MVP through v0.5, v0.10 and v1.0.
The [roadmap validation](docs/roadmap-validation.md) maps specification requirements
to milestones and records gaps corrected during review.

## Try locally

```powershell
Import-Module ./src/PS7-Completion/PS7-Completion.psd1
Get-PS7CompletionProvider
Clear-PS7CompletionCache
```

To exclude providers, use this instead on the first import in a fresh shell:

```powershell
Import-Module ./src/PS7-Completion/PS7-Completion.psd1 -ArgumentList @{ Exclude = @('ssh', 'services') }
```

Provider IDs are `ssh`, `winget`, `schtasks`, `services`, and `taskkill`. Exclusion
does not restore previous completers; restart the shell when changing exclusions.
Static suggestions do not yet account for argument position or query system data.

## Development

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser
./scripts/Test.ps1
./scripts/Build.ps1
# Requires Inno Setup 6 and ISCC.exe on PATH:
./scripts/Build.ps1 -Installer
```

Artifacts go to `dist/`. The installer targets x64 Windows, requires elevation,
and installs under `C:\Program Files\PowerShell\Modules\PS7-Completion\<version>`.
It does not install PowerShell or edit profiles. After installation, add
`Import-Module PS7-Completion` to your PowerShell 7 profile explicitly.

WinGet is the planned recommended installation method. The proposed identifier
`JackScott7.PS7-Completion` is unconfirmed and unavailable through this scaffold.
See [packaging instructions](packaging/winget/README.md). License selection is
pending; the draft workflow does not publish a public release automatically.
