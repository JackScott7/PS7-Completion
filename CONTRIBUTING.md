# Contributing

Read [the specification](docs/specification.md) and
[provider authoring guide](docs/authoring-completions.md) first.

Use PowerShell 7.4+ on Windows. Keep runtime dependencies in the PowerShell
standard library. Add offline Pester tests with each behavior change. Run
`./scripts/Test.ps1` and `./scripts/Build.ps1` before submitting a change.
Do not test by changing services, scheduling tasks, terminating processes, or
contacting remote SSH hosts. Use fixtures and mocks for system data.

Keep provider changes separate from packaging changes when practical. A release
requires all gates in the specification, not just passing scaffold tests.

Use small commits containing each behavior and its tests. The current delivery is
a private MVP; public WinGet publication is deferred. `scripts/Test.ps1 -SkipAnalyzer`
is used only for the PowerShell 7.4.0 compatibility job because analyzer 1.24 targets
a newer PowerShell assembly. The current-engine job must always run analysis.
Measure import/completion with `scripts/Measure-Completion.ps1`. Installer tests
run only on explicitly disposable GitHub-hosted runners.
