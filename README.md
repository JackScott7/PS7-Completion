# PS7-Completion

Native command completion for Windows and PowerShell 7.4+. Version **0.1.5**
supports custom providers and 34 bundled providers. It parses argument context,
quotes completion values, and loads provider files only when needed.

| Category | Included commands |
| --- | --- |
| Windows and remote access | `ipconfig`, `tracert`, `nslookup`, `netstat`, `ping`, `ssh`, `winget`, `schtasks`, `sc.exe`, `taskkill` |
| Source control and search | `git`, `gh`, `rg`, `jq` |
| Python | `python`, `pip`, `uv`, `uvx`, `uvicorn`, `twine`, `ruff`, `flask`, `fastapi` |
| JavaScript and Rust | `node`, `npm`, `cargo`, `rustc`, `rustup` |
| HTTP and containers | `curl.exe`, `docker` (including `docker compose`) |
| Other tools | `tailscale`, `sqlite3`, `ffmpeg`, `nano` |

Completion menus put commands first, then options/arguments, alphabetically within
each group. Providers offer documented syntax subsets without executing the tool
being completed. See [0.1.5 release notes](docs/releases/v0.1.5.md).

This repository remains private. WinGet publication is deferred by project-owner
decision; do not run the planned WinGet install command expecting a public package.
See [MVP evidence and limitations](docs/mvp-status.md).

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

Provider IDs are listed in the [provider reference](docs/providers.md). Exclusion
does not restore previous completers; restart the shell when changing exclusions.
Bundled providers include local SSH aliases, task names, service names, process
names/PIDs, and context-specific flags. See the [supported syntax](docs/providers.md).

## Register your own tool

```powershell
Register-PS7CompletionProvider -Name mytool -CommandName mytool,mytool.exe -ScriptBlock {
    param($context)
    if ($context.ArgumentIndex -eq 0) {
        New-PS7CompletionResult -Candidate 'build','test','deploy' -WordToComplete $context.WordToComplete
    }
}
# Now type: mytool bu<Tab>
```

For lazy loading, put a scriptblock in a `.ps1` file and register it with
`Register-PS7CompletionProvider -Name mytool -CommandName mytool,mytool.exe -Path ./mytool.ps1`.
Use either form on the first registration. `-Force` replaces an existing provider
with the same executable names. Registration lasts for the current shell; add your
registration code after the module import in your own profile for future sessions.
See [the authoring guide](docs/authoring-completions.md) and [example](examples/mytool.ps1).

For a Python script, register `-CommandName mom.py`. The same provider then handles
both `mom.py ...` and `python mom.py ...`, with script-relative arguments. See the
[Python script guide](docs/authoring-completions.md#python-scripts-direct-and-interpreter-invocation)
and [mom provider example](examples/mom.ps1). Interpreter routing uses the enabled
bundled Python provider; direct invocation uses your existing PATH/PATHEXT setup.

## Development

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser
./scripts/Test.ps1
./scripts/Build.ps1
# Requires Inno Setup 6 and ISCC.exe on PATH:
./scripts/Build.ps1 -Installer
./scripts/Measure-Completion.ps1
# Broader cold/warm benchmark, including read-only system lookups:
./scripts/Measure-Performance.ps1 -LiveQueries -OutputPath ./dist/performance/current.json
```

See the [six-step performance checklist](docs/performance-plan.md) for the benchmark
protocol, measured results and regression comparison command. Build payloads use an
assembled runtime to reduce import overhead; editable source keeps separate helpers.

Each build creates an isolated directory under `dist/builds/`; `dist/latest-build.json`
lists its exact installer and checksum files. Without `-Installer`, the build only stages and validates the module payload. The installer targets x64 Windows, requires elevation,
and installs under `C:\Program Files\PowerShell\Modules\PS7-Completion\<version>`.
It does not install PowerShell or edit profiles. After installation, add
`Import-Module PS7-Completion` to your PowerShell 7 profile explicitly.

The installer is the only user-facing package. WinGet installs the same EXE using
its Inno Setup unattended mode; no separate ZIP is distributed. The installer retains old
versions on upgrade; restart PowerShell to load the newest version. Uninstall
removes installer-owned versions while preserving added files. Remove your profile
import manually after uninstall if you no longer use the module.

The proposed future WinGet identifier is `JackScott7.PS7-Completion`.
See [packaging instructions](packaging/winget/README.md). Licensed under [MIT](LICENSE).
Current development installers are unsigned. CI validates installer lifecycle on
disposable hosted Windows runners; it never installs the module on your workstation.
