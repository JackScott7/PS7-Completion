# Bundled provider support in v0.1.5

Providers support the explicit subsets below, not every native CLI feature. They
never execute the command being completed. Unknown options conservatively suppress
provider suggestions. PowerShell itself may still offer filesystem fallbacks.
All dynamic data is local; remote-target contexts suppress local entity names.
Completion menus list commands/subcommands first, followed by options and other
arguments, with alphabetical ordering within each group across all providers.

| Provider | Commands and supported argument behavior |
| --- | --- |
| ssh / ssh.exe | Flags `-4 -6 -A -a -C -N -T -t -V -v`; recognizes operands for `-F -i -J -L -p -R -l -o -D`. Suggests literal Host aliases only at destination position, including `user@` prefixes; honors a literal `-F` config or `-F none`. Stops after a destination. |
| winget / winget.exe | `install show search list upgrade uninstall export import source`; common help/query/identity/source/exact flags where applicable; scope and architecture values; import/export file operands remain free text. Basic source subcommands are static. No package enumeration, remote search, or remote source queries. |
| schtasks / schtasks.exe | `/Create /Delete /Query /Change /Run /End /ShowSid`; operation-specific flags, finite `/SC`, `/FO`, `/RL` values; existing task paths after `/TN` except creation. Recognizes `/S /U /P` operands and avoids local names for remote targets. |
| sc.exe (provider ID `services`) | `query queryex start stop qc config create delete description`; existing internal service names in applicable positions; `key= value` syntax for query/config/create with finite type/state/start/error/tag values. Creation names, binary paths and descriptions remain free text. |
| taskkill / taskkill.exe | `/PID /IM /FI /F /T /? /S /U /P`; local PID/image values after their respective selectors, including repeated selectors. Filter expressions and credentials remain free text. |

Windows `ping` / `ping.exe` is also bundled (provider ID `ping`). It supports
`-t -a -f -R -p -4 -6 /?`, and consumes values for
`-n -l -i -v -r -s -j -k -w -S -c`. Targets remain free text; completion never
sends packets or resolves hosts. Windows `-r` requires a count; `-R` is a flag.
This provider does not implement Linux/WSL ping syntax.

Additional Windows network providers support the bare command and `.exe` name:

| ID | Supported subset |
| --- | --- |
| ipconfig | `/all`, `/allcompartments`, `/flushdns`, `/displaydns`, `/registerdns`, `/?`; renew/release (IPv4/IPv6) and show/setclassid operations leave adapter/class operands free text. No adapter enumeration. |
| tracert | `-d -R -4 -6 /?`; hop-count, source-route, timeout, source-address operands (`-h -j -w -S`); stops after the target. |
| nslookup | Noninteractive `-option=value` syntax: type/querytype/class values, timeout/retry/port/domain/srchlist, debug/recurse/search/vc/defname toggles. Stops at the hostname; interactive prompt commands are not supported. |
| netstat | Common Windows flags and `-p` protocol values; adds IP/ICMP protocol families when `-s` precedes `-p`; stops at the repeat interval. Combined short flags are not parsed. |

## Developer tools

The following 24 providers use literal syntax tables, with no native process,
network request, project import, repository scan, or package discovery during
completion. Each supports the bare command and `.exe` spelling, except curl
(registered as `curl.exe` only to avoid aliases) and npm,
which supports `npm`, `npm.cmd`, and `npm.ps1`. Python and pip also support
`python3[.exe]` and `pip3[.exe]`. Provider IDs are in the first column.

| ID | Command and supported subset |
| --- | --- |
| curl | `curl.exe`: common HTTP, download/upload, header/data/form, auth/proxy/TLS, timeout/retry options; request-method and help-category values. URLs, credentials and filenames stay free text. |
| cargo | build, check, run, test, new, init, add, remove, clean, doc, update, search, install, uninstall, publish; common global and command-specific operands, color/edition values. Stops at `--` for forwarded arguments; toolchain prefixes, command aliases and external subcommands are not parsed. |
| docker | build/run/exec, ps/images, pull/push, logs/inspect, stop/start/restart, rm/rmi, info/version, login/logout. Compose supports up/down/build/ps/logs/config/pull/push/start/stop/restart/exec/run/version with file/project/env/profile options before the subcommand. Stops at image/container/service in run/exec; no daemon access or container/image/service discovery. Standalone legacy `docker-compose` is not registered. |
| git | `git`: status, add, commit, diff, log, clone, fetch, pull, push, branch, switch, checkout, restore, remote add/remove/rename, stash push/pop/list/apply; root `-C`/`-c` operands. No branch or remote enumeration. |
| gh | `gh`: auth login/status/logout, pr list/view/create/checkout, issue list/view/create, repo clone/view/list, workflow list/view/run. PR state values. No API requests. |
| ripgrep | `rg`: common search/output flags; pattern, file, glob, type, context, replacement operands; color values. |
| jq | Input/output flags; filter-file and indentation operands; two operands for `--arg`, `--argjson`, `--slurpfile`, `--rawfile`. No jq-language completion. |
| python | Interpreter flags and module names after `-m`; delegates literal `python [-I etc.] -m pip` to pip. Stops at scripts, inline code, and other module bodies. |
| pip | install, uninstall, list, freeze, show, check, download, cache dir/info/list/purge/remove; list format values. No package enumeration. |
| uv | init, add, remove, sync, lock, run, venv; python list/install/find/pin/uninstall; tool run/install/list/uninstall/upgrade; pip install/list/freeze/uninstall/check/compile/sync. |
| uvx | Tool-run options including from/with/python, index/cache/config operands and color values. Stops after the tool name; no tool discovery, installation, or forwarded-tool completion. |
| uvicorn | Server options before/after the app import string; host/port/reload/workers/TLS operands and loop/http/ws/lifespan/interface/log-level values. No app import. |
| twine | check, upload, register; strict checks, upload flags and repository/credential/certificate operands. No credential reads, package inspection, or upload. |
| ruff | check, format, rule, config, linter, clean, server, version; common global options, rule/path/config operands and output-format/target-version/color values. No project reads or lint execution. |
| flask | Root app/env-file/debug options; run, routes, shell; routes sort values. No application imports or custom command discovery. |
| fastapi | dev and run, host/port/app/entrypoint/root-path operands, reload flags, run workers. |
| tailscale | up, down, status, ip, ping, version, logout, set; common flags and operands. No peer discovery. |
| node | Interpreter flags, eval/print/require/import/env-file operands, input-type values. Stops at script or inline-code arguments. |
| npm | install, ci, uninstall, update, run, test, start, exec, init, list, audit/fix, outdated, view. No package or script-name discovery. |
| sqlite3 | CLI startup flags and cmd/init/separator/nullvalue operands. Stops at database filename; no SQL or interactive dot-command completion. |
| ffmpeg | Common input/output, codec, bitrate, filter, map, timing and encoding flags; loglevel values. No codec/device probing. |
| rustc | Compiler flags and operands; edition, crate-type, error-format values. |
| rustup | show, update, default, toolchain list/install/uninstall, target/component list/add/remove, run. No installed-toolchain enumeration. |
| nano | GNU nano Windows flags and syntax/tabsize/rcfile/directory operands. |

These are intentionally bounded subsets. Unknown flags/subcommands suppress
suggestions; an exact `--` ends completion. Option names are case-sensitive
(e.g. ripgrep `-F` is a flag, `-f` needs a file). Recognized `--option=value`
operands are consumed; attached short values and combined short flags are not
parsed. Free-form operands never receive unrelated flag suggestions. Options
are scoped to their documented command node; not every inherited/global flag
is repeated at every depth. Forwarded commands (uv run/tool run, npm run/exec,
rustup run) stop at the first positional. PowerShell filesystem fallback may
still occur when a provider returns nothing.

See [installation identification](provider-origins.md) for the WinGet inventory,
local executable checks, versions, and upstream references used for these tools.

The option tables in `Completions/*.ps1` define arity (operand versus flag) and
applicability. `tests/Completions` contains positive and wrong-position cases for
these tables. This is static syntax support; the module does not probe installed
tool help during import/completion or promise identical options in every release.

SSH config reads are limited to fixed local drives: no UNC paths, network drives
or links to non-local targets. Local symbolic links and junctions are supported,
with at most 32 nested link resolutions. Limits: Include depth 8, 64 visited files, 1 MiB per
file, 4 MiB total, 4096 aliases, plus cooperative 500 ms traversal checks. Includes support quoted
paths, `~/`, relative paths resolved under the user's `.ssh` folder, and wildcard
filenames in a literal directory. Wildcards in directory components, environment
expansion and conditional Match execution are not supported. Match blocks are
skipped until the next Host. Literal aliases are collected, not a full OpenSSH
configuration evaluation. Comments, cycles, missing and inaccessible files are
handled without executing config directives. Cache dependencies include files and
Include directories so edits/new matching files can invalidate a cached result.

Native syntax references checked during implementation:

- [OpenSSH client](https://man.openbsd.org/ssh) and [configuration](https://man.openbsd.org/ssh_config)
- [WinGet install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)
- [Scheduled tasks](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/schtasks)
- [Service query](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/sc-query)
- [Taskkill](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/taskkill)

For troubleshooting, inspect Get-PS7CompletionProvider, clear data with
Clear-PS7CompletionCache and retry in a fresh shell with the intended exclusions.
Debug messages may contain local paths; do not paste sensitive output into issues.
No result on a slow/unavailable query is intentional; there is no stale-data fallback.
