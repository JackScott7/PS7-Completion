# Developer provider installation identification

Checked on 2026-10-22 using `winget list --disable-interactivity`, filtered to
these tools, and `winget show --id <ID> --exact --source winget` for matched
packages and GitHub CLI. WinGet source matches identify a distribution; they do
not prove that WinGet performed the original installation. Catalog `show`
versions may be newer than installed versions. No tools were installed or upgraded.

`Get-Command` resolved the active executable, with local version/help and Python
package metadata checks where WinGet had no match. These are development-machine
observations, not runtime dependencies or pinned supported-version requirements.

| Provider | Installed identity / origin evidence |
| --- | --- |
| git | `Git.Git` 2.55.0.3; Git for Windows, Git Development Community; active Program Files Git cmd executable. |
| gh | No installed WinGet entry or PATH command. Official catalog `GitHub.cli`, GitHub Inc., MSI from github.com/cli/cli; catalog version 2.103.0. Provider follows the official CLI syntax. GitHub Desktop is a different application. |
| ripgrep | `BurntSushi.ripgrep.MSVC` 15.2.0, BurntSushi; active WinGet Links `rg.exe`; MSVC x86_64 Windows release ZIP. |
| jq | No WinGet installed match; portable Utils `jq.exe`, reports jq-1.8.1. Original download source unverified. |
| python | Python Install Manager `Python.PythonInstallManager` 26.4.240.0; active manager bin alias resolves Python 3.15.0. Also installed: `Python.Python.3.13` 3.13.12, `Python.Python.3.14` 3.14.3, and manager-owned 3.15/free-threaded runtimes. Python Software Foundation. |
| pip | No standalone WinGet match; active Python manager bin command, Python 3.15 site-packages pip 26.2.1. |
| uv | No WinGet installed match; Python 3.14 Scripts executable and site-packages uv 0.10.0 (Astral). |
| flask | No WinGet installed match; Python 3.14 Scripts executable, Flask 3.1.3 package. Flask 3.1.3 also exists under active Python 3.15. |
| fastapi | No WinGet installed match; Python 3.14 Scripts executable, fastapi 0.141.1 and fastapi-cli 0.0.32 package metadata. |
| tailscale | `Tailscale.Tailscale` 1.102.4; Tailscale Inc., MSI from pkgs.tailscale.com; active Program Files executable. |
| node | WinGet lists Node.js 24.4.0 via an ARP installed-app record, without catalog/source match. Active custom nodejs directory reports v24.4.0; original installer source unverified. |
| npm | No separate WinGet match; npm.ps1 alongside Node; reports 11.19.1. |
| sqlite3 | `SQLite.SQLite` 3.53.4; SQLite portable tools ZIP from sqlite.org; active WinGet Links executable. DB Browser for SQLite is a separate application. |
| ffmpeg | No WinGet installed match; custom FFmpeg/bin executable reports N-120402-g7c5319e692-20250729. Original build distributor unverified. |
| rustc | Active cargo/bin Rustup proxy reports 1.98.1. WinGet also lists standalone `Rustlang.Rust.GNU` 1.95.0.0; that record does not identify the active compiler. |
| rustup | `Rustlang.Rustup` 1.29.1; Rust project installer from static.rust-lang.org; active cargo/bin executable also reports 1.29.1. |
| nano | No WinGet installed match; custom nano executable reports GNU nano for Windows 64 bits v7.2-22.1 (2023-04-15). Original distributor unverified. |

Upstream syntax references include [GitHub CLI](https://cli.github.com/manual/),
[jq](https://jqlang.org/manual/), [uv](https://docs.astral.sh/uv/reference/cli/),
and [FastAPI CLI](https://fastapi.tiangolo.com/fastapi-cli/).
Local installed help was also checked for uv optional arguments, Flask route
sorting, Tailscale ping options, and FastAPI run options. No provider invokes
these help/version/WinGet queries during module import or completion.
