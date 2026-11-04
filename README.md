# PS7-Completion

Tab completion for command-line tools in PowerShell 7.4+ on 64-bit Windows.

## Install

1. Download the Windows installer from the [latest release](https://github.com/JackScott7/PS7-Completion/releases/latest).
2. Run the installer and open a new PowerShell session.
3. Run `Import-Module PS7-Completion` to start using completions.

Install PowerShell 7.4 or later separately before importing the module. The
installer requires administrator permission and does not install PowerShell.
Release installers are unsigned, so Windows may display a publisher warning.

To load completions in every new session, add `Import-Module PS7-Completion`
to your [PowerShell profile](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_profiles).
The installer does not change your profile.

After upgrading or uninstalling, restart existing PowerShell sessions. Upgrades
retain previously installed module versions; a new session loads the newest
installed version by default. To install an older version, uninstall first.

## Supported tools

| Category | Tools |
| --- | --- |
| Windows and remote access | `ipconfig`, `tracert`, `nslookup`, `netstat`, `ping`, `ssh`, `winget`, `schtasks`, `sc.exe`, `taskkill`, `icacls`, `net`, `wsl`, `sfc`, `DISM`, `reg` |
| Source control and search | `git`, `gh`, `rg`, `jq` |
| Python | `python`, `pip`, `uv`, `uvx`, `uvicorn`, `twine`, `ruff`, `flask`, `fastapi`, `pytest`, `pipx` |
| JavaScript and Rust | `node`, `npm`, `npx`, `pnpm`, `yarn`, `dotnet`, `cargo`, `rustc`, `rustup` |
| Web and containers | `curl.exe`, `docker` (including `docker compose`) |
| Other tools | `tailscale`, `sqlite3`, `ffmpeg`, `nano` |

The framework includes 46 completion providers. It also supports your own tools,
including Python scripts run directly or through `python`. See the
[Wiki](https://github.com/JackScott7/PS7-Completion/wiki) for supported syntax,
configuration, custom completions, and technical details.

See the [changelog](CHANGELOG.md) for changes and supported release details.

PS7-Completion is licensed under [MIT](LICENSE).

## Executable names without `.exe`

To complete executable names without their `.exe` extension, enable this
separate feature when importing the module:

```powershell
Import-Module PS7-Completion -ArgumentList @{ ExtensionlessCommands = $true }
```

For example, `pyt` followed by Tab can complete to `python`. When several
executables share that name, the completion uses the one PowerShell resolves
first on `PATH`. Explicit paths and typed `.exe` extensions are left intact.
If an alias or function takes precedence over the executable, its extension is
retained so the completion does not select a different command. The feature
wraps the session's `TabExpansion2` function and restores it when the module is
removed. Add the import command to your profile to enable it in new sessions.

## Tool-provided completions

Some tools provide their own PowerShell completion scripts. Generate a script
from a trusted installed tool, then include its path when importing this module.
For example, for kubectl:

```powershell
kubectl completion powershell | Set-Content -Encoding utf8 "$HOME/kubectl-completion.ps1"
Import-Module PS7-Completion -ArgumentList @{
    NativeCompletionScripts = @("$HOME/kubectl-completion.ps1")
}
```

Add the import command to your profile to load it in future sessions. Regenerate
the script after updating the tool. These scripts execute as PowerShell code and
can call their tools or access external systems during completion. They register
directly with PowerShell, after the built-in providers, so a tool script takes
precedence if both register the same command. Only load scripts you trust.
