# v0.1 private MVP evidence

Delivery scope confirmed by the owner on 2026-10-22: keep the repository private,
use MIT, push small meaningful commits to `upstream`, and deliver a working,
tested, installable framework with user-registerable completion code. Public
WinGet publication is deferred. No repository visibility change is required.

## Implemented

| Roadmap area | Implementation/evidence |
| --- | --- |
| M1 foundation | Whole-registry/config validation before registration; lazy bundled provider files; metadata/status; inline/file user registration and replacement rules. Core/Registration and Core/Context tests include fresh-shell exclusion checks. |
| M2 context/results | Literal AST decoding, cursor boundaries, escaped/quoted input, no expression evaluation, safe insertion and buffered failure handling. Core/Context and Core/Module tests plus special-character round trips. |
| M3 queries/cache | Killable read-only worker, shared 500 ms work budget, cleanup, 30-second monotonic TTL, file dependencies, generation-safe clearing and 128-entry bound. Core/Queries tests exercise expiry, failures, clearing and termination. |
| M4 providers | All five bundled providers use argument-aware logic; local SSH aliases/tasks/services/processes; static WinGet syntax. Provider-specific tests cover positive and wrong-position cases. See providers.md for supported subsets. |
| M5 private packaging | Versioned ZIP/EXE from isolated payloads; matching versions; MIT; hashes and manifest generation. Disposable Windows CI proves install, reinstall, upgrade, retained-version discovery and uninstall preserving added files. |
| M6 validation | Pester and analyzer, build tests, interactive Tab smoke checks, performance script, current/minimum PowerShell CI, documentation and user example. Specific results below. |

The two-command original design was amended at the owner's request. The public
API is Get-PS7CompletionProvider, Clear-PS7CompletionCache,
Register-PS7CompletionProvider and New-PS7CompletionResult. Custom providers do not
need to modify the installed module or its registry.

## Verified results

- Local Pester suite: 68 tests passed, including the documented user-provider
  example and excluded-alias regression checks.
- PSScriptAnalyzer: no warning/error diagnostics for runtime and scripts at that run.
- [Initial CI run](https://github.com/JackScott7/PS7-Completion/actions/runs/39674031963):
  validation and installer jobs passed at commit `54e1d59`.
- [Final compatibility CI](https://github.com/JackScott7/PS7-Completion/actions/runs/39676759257):
  all three jobs passed at `6a30e01`: full Pester suite on PowerShell 7.4.0,
  full suite plus analyzer on the current runner engine, and installer lifecycle.
  Analyzer 1.24 itself requires a newer assembly than 7.4.0, so it runs on the
  current-engine job; no runtime tests are omitted on the minimum engine.
- [Private v0.1.0 draft](https://github.com/JackScott7/PS7-Completion/releases/tag/untagged-82bfaf6ab8f75af738fd):
  Windows x64 installer, module ZIP, SHA256SUMS and generated WinGet manifest from
  the tested `6a30e01` source. The repository and draft remain private; the manifest
  is preparation for future distribution, not a publicly usable package.
- Installer test uses a disposable GitHub-hosted Windows Server 2025 runner. It
  installs 0.1.0, reinstalls it, upgrades to a synthetic 0.1.1 payload, confirms new
  shell discovery and removes both owned versions while retaining a user-added file.
  The synthetic 0.1.1 installer is test evidence, not a product release.
- Real interactive PSReadLine Tab checks were performed in a `pwsh -NoProfile`
  terminal: custom `demo.exe bu` → `build`, WinGet `ins` → `install`, schtasks `/Ru`
  → `/Run`, sc.exe `quer` → `query`, taskkill `/PI` → `/PID`. Both bare and `.exe`
  registered names were exercised, plus SSH `-J`. Commands were canceled rather
  than executed. History saving was disabled in that test session.
- Read-only local worker smoke tests: 347 processes in 342 ms, 313 services in
  305 ms, 192 tasks in 353 ms on the local machine. These are snapshots, not timing
  guarantees. The original slower service path was replaced before final delivery.

## Performance reference and limits

`scripts/Measure-Completion.ps1` records fresh-process module-import duration (not
PowerShell startup) and warm CompleteInput calls. Reference: PowerShell 7.6.7,
Windows 10.0.26300, Intel64 Family 6 Model 186 Stepping 2, 16 logical processors.
Results from the optimized import path (30 imports, 100 warm calls per provider):

| Measurement | Median ms | p95 ms |
| --- | ---: | ---: |
| Cold import | 103.00 | 110.13 |
| ssh static | 4.21 | 6.05 |
| winget static | 3.98 | 4.78 |
| schtasks static | 1.13 | 1.31 |
| sc.exe static | 1.17 | 1.54 |
| taskkill static | 1.25 | 1.56 |

Warm completion meets the 50 ms target. **Cold import remains about 10 ms above
the proposed 100 ms p95 target on this machine**; this is recorded as an outstanding
performance target, not a passed gate. Import performs no network or system-data
queries. Arbitrary custom callbacks are trusted in-session PowerShell and are not
subject to the private worker's timeout. Worker termination/disposal adds latency
beyond the 500 ms work deadline (about 40–60 ms in the timeout regression).

## Deferred or not certified

- Public package-ID availability, public release URLs, WinGet submission and public
  install/upgrade/uninstall checks: deferred by the owner's private-delivery decision.
- Current private development artifacts are unsigned; no signing certificate or
  public signing policy is implied. Checksums are supplied.
- Canceled elevation, all unsupported OS/architecture combinations, abrupt installer
  interruption, and every possible modified-owned-file recovery scenario have not
  been certified. Standard elevated lifecycle is covered by the disposable runner.
- No exhaustive native CLI coverage, remote completion, automatic profile editing,
  third-party completer restoration or sandbox for custom scripts is claimed.

Build locally with scripts/Build.ps1, or obtain private CI/draft-release artifacts.
`dist/latest-build.json` identifies only the current build's artifacts. A full
public release should revisit the unchecked roadmap gates rather than treating
private MVP completion as public distribution approval.
