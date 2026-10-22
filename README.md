# PS7-Completion

Tab completion for command-line tools in PowerShell 7.4+ on Windows.

## Install

1. Download the Windows installer from the [latest release](https://github.com/JackScott7/PS7-Completion/releases/latest).
2. Run the installer and open a new PowerShell session.
3. Run `Import-Module PS7-Completion` to start using completions.

To load completions in every new session, add `Import-Module PS7-Completion`
to your [PowerShell profile](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_profiles).
The installer does not change your profile.

## Supported tools

| Category | Tools |
| --- | --- |
| Windows and remote access | `ipconfig`, `tracert`, `nslookup`, `netstat`, `ping`, `ssh`, `winget`, `schtasks`, `sc.exe`, `taskkill` |
| Source control and search | `git`, `gh`, `rg`, `jq` |
| Python | `python`, `pip`, `uv`, `uvx`, `uvicorn`, `twine`, `ruff`, `flask`, `fastapi` |
| JavaScript and Rust | `node`, `npm`, `cargo`, `rustc`, `rustup` |
| Web and containers | `curl.exe`, `docker` (including `docker compose`) |
| Other tools | `tailscale`, `sqlite3`, `ffmpeg`, `nano` |

The framework includes 34 completion providers. It also supports your own tools,
including Python scripts run directly or through `python`. See the
[Wiki](https://github.com/JackScott7/PS7-Completion/wiki) for supported syntax,
configuration, custom completions, and technical details.

PS7-Completion is licensed under [MIT](LICENSE).
