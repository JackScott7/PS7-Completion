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
