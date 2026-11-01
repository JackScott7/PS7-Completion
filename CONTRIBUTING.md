# Contributing

Read [the specification](https://github.com/JackScott7/PS7-Completion/wiki/Specification) and
[provider authoring guide](https://github.com/JackScott7/PS7-Completion/wiki/Authoring-Completions) first.

Use PowerShell 7.4+ on Windows. Keep runtime dependencies in the PowerShell
standard library. Add offline Pester tests with each behavior change. Run
`./scripts/Test.ps1` and `./scripts/Build.ps1` before submitting a change.
Do not test by changing services, scheduling tasks, terminating processes, or
contacting remote SSH hosts. Use fixtures and mocks for system data.

Keep provider changes separate from packaging changes when practical. A release
requires all gates in the specification, not just passing scaffold tests.
For each release, update `CHANGELOG.md` with added features, changed behavior and
fixes, and run `./scripts/Test-ReleaseMetadata.ps1`. The release workflow uses
that entry as its notes. Update the Wiki when technical guidance changes.
Avoid em dashes in tracked project text.

Use small commits containing each behavior and its tests. The current delivery is
a private MVP; public WinGet publication is deferred. `scripts/Test.ps1 -SkipAnalyzer`
is used only for the PowerShell 7.4.0 compatibility job because analyzer 1.24 targets
a newer PowerShell assembly. The current-engine job must always run analysis.
Measure import/completion with `scripts/Measure-Completion.ps1`. Installer tests
run only on explicitly disposable GitHub-hosted runners.

For performance work, follow [the performance checklist](https://github.com/JackScott7/PS7-Completion/wiki/Performance-Plan).
Measure the built payload as well as source; the installed runtime is assembled
at build time while providers and the SSH parser remain lazy. Keep sample counts,
machine, engine and OS identical for comparisons. CI retains informational timing
artifacts; use `scripts/Compare-Performance.ps1 -EnforceTiming` on a controlled
machine to enforce regressions. Never accept fewer results or failed queries as
an improvement. Do not compare sandbox-denied lookups with unrestricted lookups.

Run `./scripts/Test.ps1 -Coverage` for per-provider command coverage in
`dist/coverage/providers.json` and the XML coverage report. Every registry entry
must have measured coverage. A percentage measures executed statements; review
positive and unsupported-context fixtures separately when adding behavior.
`./scripts/Test-Compatibility.ps1` runs fresh-shell checks and accepts multiple
PowerShell executable paths with `-Engine`. CI checks source and staged payloads
on minimum and current PowerShell. Offline capability snapshots do not certify
unrecorded native tool versions.

Run `./scripts/Measure-DataScale.ps1` to record cache/result counts and managed
heap deltas for synthetic process, service and task snapshots and a local SSH
include tree. Snapshot cases exercise normalization, not OS collectors. Heap
deltas are observations, not peak-memory guarantees; they may be negative after
garbage collection. Fixture files are retained beside the report for inspection.

To debug a provider, start `pwsh -NoProfile`, import the source manifest, and
reproduce with a synthetic command such as `winget ins`. Inspect
`Get-PS7CompletionProvider` for its status and clear data with
`Clear-PS7CompletionCache` before retrying. Use synthetic names and local fixture
files. Enable `$DebugPreference = 'Continue'` only for that synthetic reproduction:
debug messages can include exception details. Reset it to `SilentlyContinue`
afterwards. Do not attach real host names, process lists or configuration contents
to reports. Coverage and compatibility summaries contain no query data.

The manual Historical upgrade validation workflow builds the v0.1.1 baseline
from its tag and the current source as a 0.5.0 candidate on a disposable runner.
It checks installation, repair, upgrade, retained versions and uninstall with
user-file preservation. This is a candidate validation run, not a release.
Pass lifecycle inputs to `Test-Installer.ps1` with `-BuildMetadata` and
`-UpgradeBuildMetadata` on an authorized disposable runner.
