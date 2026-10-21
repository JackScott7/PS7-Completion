# Bundled provider support in v0.1

Providers support the explicit subsets below, not every native CLI feature. They
never execute the command being completed. Unknown options conservatively suppress
provider suggestions. PowerShell itself may still offer filesystem fallbacks.
All dynamic data is local; remote-target contexts suppress local entity names.

| Provider | Commands and supported argument behavior |
| --- | --- |
| ssh / ssh.exe | Flags `-4 -6 -A -a -C -N -T -t -V -v`; recognizes operands for `-F -i -J -L -p -R -l -o -D`. Suggests literal Host aliases only at destination position, including `user@` prefixes; honors a literal `-F` config or `-F none`. Stops after a destination. |
| winget / winget.exe | `install show search list upgrade uninstall export import source`; common help/query/identity/source/exact flags where applicable; scope and architecture values; import/export file operands remain free text. Basic source subcommands are static. No package enumeration, remote search, or remote source queries. |
| schtasks / schtasks.exe | `/Create /Delete /Query /Change /Run /End /ShowSid`; operation-specific flags, finite `/SC`, `/FO`, `/RL` values; existing task paths after `/TN` except creation. Recognizes `/S /U /P` operands and avoids local names for remote targets. |
| sc.exe (provider ID `services`) | `query queryex start stop qc config create delete description`; existing internal service names in applicable positions; `key= value` syntax for query/config/create with finite type/state/start/error/tag values. Creation names, binary paths and descriptions remain free text. |
| taskkill / taskkill.exe | `/PID /IM /FI /F /T /? /S /U /P`; local PID/image values after their respective selectors, including repeated selectors. Filter expressions and credentials remain free text. |

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
