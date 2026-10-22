# PS7-Completion specification

Status: v0.1 private MVP contract, amended 2026-10-22 to support user-registered
completion code. See [implementation evidence](mvp-status.md).

## Product and scope

PS7-Completion is a pure PowerShell module providing native executable argument
completion on Windows with PowerShell 7.4 or later (Core edition). The initial
installer targets x64 Windows. ARM64 packaging and Windows PowerShell 5.1 are out
of scope. The owner has requested that the repository stay private and that this
delivery stop at a tested installable MVP. Public WinGet publication is therefore
deferred, as is PowerShell Gallery distribution.

Project, module, and release artifact names use `PS7-Completion`. The proposed
WinGet identifier is `JackScott7.PS7-Completion`; package availability must be
confirmed before any future public publication. Repository/publisher:
https://github.com/JackScott7/PS7-Completion (JackScott7). License: MIT.

## Layout

| Path | Responsibility |
| --- | --- |
| `src/PS7-Completion/PS7-Completion.psd1` | Version, requirements, explicit exports |
| `src/PS7-Completion/PS7-Completion.psm1` | Framework import and lazy registration |
| `src/PS7-Completion/Public/` | Public commands |
| `src/PS7-Completion/Private/` | Context, matching, loading, cache, formatting |
| `src/PS7-Completion/Completions/` | One provider script per tool |
| `src/PS7-Completion/Registry.psd1` | Provider IDs, executable names, relative paths |
| `tests/Core/`, `tests/Completions/`, `tests/Fixtures/` | Pester tests and offline data |
| `packaging/windows/installer.iss` | Inno Setup definition |
| `packaging/winget/` | Unpublished manifest templates and submission instructions |
| `scripts/Build.ps1`, `scripts/Test.ps1` | Build and validation entry points |
| `.github/workflows/` | Windows CI and manual draft release workflow |
| `docs/authoring-completions.md` | Provider contribution contract |

## Runtime contract

Import loads only framework helpers and registry metadata, then registers native
completer callbacks. Provider scripts are loaded and cached on first use. Import
must not run external commands, access the network, or enumerate system data.
Register `sc.exe` only; never replace the PowerShell `sc` alias. Other providers
register bare executable names and `.exe` variants.

Providers receive one context object:

| Field | Contract |
| --- | --- |
| `WordToComplete` | PowerShell-provided partial word |
| `CommandAst` | Original CommandAst, never evaluated |
| `CursorPosition` | Absolute cursor offset |
| `Arguments` | Argument source text through the cursor, excluding executable; quoted boundaries preserved |
| `ArgumentIndex` | Zero-based argument position; next position after trailing whitespace |
| `Values` | Decoded literal arguments; no expression evaluation |
| `PreviousArguments` | Decoded arguments strictly before the current slot |
| `IsSupported` | False for expression contexts the framework cannot interpret safely |

Use AST extents, never whitespace splitting or Invoke-Expression. Ignore arguments
after the cursor; truncate the current argument at the cursor. Preserve source
quoting in Arguments; providers must interpret literals without evaluating user
expressions. Providers return only System.Management.Automation.CompletionResult
objects. Shared matching uses ordinal case-insensitive literal prefix comparison,
not wildcard matching. Dynamic candidates need safe PowerShell quoting.

Provider failure must not break interactive completion: return no results and
write diagnostic detail only to the debug stream. No provider may execute the
command being completed or perform mutating operations. Dynamic queries must be
local, read-only, bounded, and tolerate unavailable commands and access denial.
Processes, services and tasks use a 500 ms shared worker deadline. SSH config
uses a bounded in-process parser with cooperative 500 ms traversal checks.
Bundled dynamic queries use a 30-second cache TTL.
The worker is terminated and reaped on timeout; OS termination/disposal latency is
additional to the work budget. Custom providers are trusted in-session code, not
sandboxed or forcibly time-limited; their authors own query behavior and latency.
Cache keys must include provider, query parameters, and relevant file metadata.

## Public interface and configuration

* `Get-PS7CompletionProvider`: list Name, Commands, Enabled, Loaded, and Status.
* `Clear-PS7CompletionCache`: clear provider data caches; it does not unregister
  callbacks or unload provider implementations.
* `Register-PS7CompletionProvider -Name <id> -CommandName <names> -ScriptBlock <code>`:
  register user completion code without modifying the module. Alternatively use
  `-Path <file.ps1>` for lazy loading of a file returning one scriptblock. `-Force`
  replaces an existing ID only with the same executable names. Conflicting enabled
  providers and alias names are rejected; registrations last for the shell session.
* `New-PS7CompletionResult -Candidate <strings> -WordToComplete <prefix>`: create
  prefix-filtered, safely quoted results. Optional ToolTip and ResultType parameters
  control presentation. Direct CompletionResult output remains supported.
* `Import-Module PS7-Completion -ArgumentList @{ Exclude = @('ssh', 'winget') }`:
  skip registration for those provider IDs. Unknown IDs are errors.

Exclusions apply at first import. Restart the shell to change registration choices.
No automatic detection, restoration, or unregistration of third-party completers
is promised. Import order may overwrite an existing completer. Remove-Module does
not guarantee restoration. Configuration is never written to profiles automatically.

## Provider acceptance scope

| Provider | Required v0.1 behavior |
| --- | --- |
| ssh | Common options and literal Host aliases from user SSH config; ignore wildcard/negated aliases; handle comments, missing files and bounded Include traversal; no network lookup |
| winget | Top-level commands and context-specific options; no remote package search during completion |
| schtasks | Operations and operation-specific options; local task names where a task-name argument is expected |
| sc.exe | Operations and local service names in applicable positions |
| taskkill | Options, local process names after /IM and process IDs after /PID; never terminate processes |

Context-sensitive options, local dynamic data, safe literal formatting and bounded
query caching are implemented. [Provider support](providers.md) documents the exact
subset and unsupported syntax; no provider claims exhaustive native CLI coverage.
Get-PS7CompletionProvider additionally reports Source (BuiltIn or Custom) and Status
(Registered, Loaded, Excluded or Failed). Output limits are 512 suggestions per
request, 4096 query values and 128 cache entries. See authoring docs for SSH limits.

## Distribution and lifecycle

Build a versioned module payload and Inno Setup installer. Install with elevation
under `{autopf64}\PowerShell\Modules\PS7-Completion\<version>`. Do not modify PATH,
PSModulePath, profiles, or install PowerShell implicitly. Use a stable installer
AppId across releases and an uninstall record outside the version directory.
Retain previous installed versions during upgrades; PowerShell selects the newest
version in a new session. Uninstall removes installer-owned files across versions,
not arbitrary user files. Already loaded sessions need restarting after changes.
Downgrades are unsupported; uninstall then install the intended version.

After publication, intended commands are:

```powershell
winget install --id JackScott7.PS7-Completion --exact
winget upgrade --id JackScott7.PS7-Completion --exact
winget uninstall --id JackScott7.PS7-Completion --exact
```

Activation is separate: users explicitly add `Import-Module PS7-Completion` to
their PowerShell 7 profile. Installing files alone does not activate native
completers. Release assets are hosted on GitHub; versioned WinGet manifests must
contain the real immutable installer URL and SHA256, and be validated before a
separate submission to microsoft/winget-pkgs. Templates are not publishable.

## Quality and release gates

CI runs Pester 5 and PSScriptAnalyzer on Windows and validates the staged module payload; installer CI builds the distribution EXE.
Test lazy loading, exclusions, prefix matching, quoted and partial arguments,
cursor-in-middle behavior, trailing whitespace, failure isolation, and all provider
contracts. Dynamic tests use fixtures/mocks and never kill processes or modify
services/tasks. Check import cost and completion latency before release; target
warm static completion under 50 ms and cold import under 100 ms on a documented
Windows reference machine (report measurements, not an unverified guarantee).

Before future public publication: confirm name/ID availability; validate installer on a clean
VM for elevated silent install, upgrade, uninstall, retained versions and restart
behavior; verify package discovery in PowerShell 7; validate WinGet manifests;
decide public signing policy and publish checksums. Current private development
installers are explicitly unsigned. Draft release automation is not acceptance.
The private-MVP scope defers public package submission, not implementation tests.

## References

* [PowerShell module search paths](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.5)
* [Inno Setup privilege requirements](https://jrsoftware.org/ishelp/topic_setup_privilegesrequired.htm)
* [WinGet installer manifest schema](https://github.com/microsoft/winget-pkgs/blob/master/doc/manifest/schema/1.28.0/installer.md)
