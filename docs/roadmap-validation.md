# Roadmap validation

Reviewed 2026-10-22 against `docs/specification.md`, README, runtime framework,
registry, tests, build/test scripts, installer, WinGet template and release workflow.
This is a requirements and implementation-plan review, not runtime certification.

Implementation update: the owner subsequently authorized a four-command API for
user providers and a private installable MVP. Public WinGet publication is deferred.
This document preserves the original roadmap review; [MVP status](mvp-status.md)
contains the current test/installer evidence and remaining limitations.

## Specification coverage

| Specification requirement | Roadmap owner | Acceptance evidence |
| --- | --- | --- |
| Windows, PS7.4+ Core, pure PowerShell, x64; deferred platforms/channels | M1, scope controls, S1 | Recorded support matrix and dependency review |
| Project/module identity, provisional publisher/WinGet ID | M5, S3 | Confirmed identity and real publication record |
| Separated module, providers, tests, packaging, scripts, docs | Baseline, M1–M6 implementation locations | File-level evidence records |
| Lazy registration; import has no external/system queries | M1 | Registration mocks and fresh-process import tests |
| Executable aliases and sc.exe-only registration | M1, M4, M6 | Registry tests and alias safety check |
| All five context fields and AST/cursor semantics | M2 | Quoted/partial/cursor/redirection fixtures |
| CompletionResult, prefix matching and safe quoting | M2 | Type checks and parse round-trip tests |
| Failure isolation and debug-only diagnostics | M2, M3, R3 | Throw/non-terminating/partial-output tests |
| Read-only local operations; never execute completed command | M3, M4 | Mocked query boundaries and execution assertions |
| 500 ms worker timeout; cooperative 500 ms SSH parser checks; 30-second TTL, cache keys/file metadata | M3, F3 | Deadline/cleanup, parser and invalidation tests |
| Two public commands, metadata fields and exclusions | M1, M3, R1 | Export/parameter/registration/cache tests |
| No restoration promises; explicit profile activation | M1, M5, S5 | Fresh-shell tests and reviewed user docs |
| SSH options, Host aliases and bounded Includes | M4, F1–F2 | SSH capability/config fixtures |
| WinGet commands and context options, no remote search | M4, F1–F2 | Command/option/operand matrix |
| Task operations/options and local task-name values | M4, F1–F2 | Existing/new/remote task contexts |
| sc.exe operations and local service values | M4, F1–F2 | Service-name and key/value contexts |
| taskkill options, /IM names, /PID IDs; no termination | M4, F1–F2 | Selector/filter contexts and no-mutation checks |
| Versioned installer path, elevation, stable AppId | M5, F5, R4 | Clean-VM installation reports |
| Retained versions, owned-file removal and restart/downgrade behavior | M5, F5, R4, S2 | Upgrade/uninstall/recovery matrix |
| No profile/PATH/module-path edits or implicit PS install | M5 | Before/after VM state comparison |
| GitHub assets, real hashes/URLs, WinGet validation/submission | M5, F5, R5, S3 | Payload/hash checks and public install evidence |
| Pester/analyzer/CI, offline tests and contributor guidance | M6, F6, S5 | CI results and capability-linked docs |
| Import/completion performance measurements | M6, F3, R3, S2 | Reference-machine median/p95 reports |
| License, publisher, signing decision, checksum release gates | M5, R5, S3 | Completed release decision/evidence record |

Every mandatory specification requirement has an MVP owner and a verification
method. Later phases add coverage, repeatability and stability; they do not defer
mandatory v0.1 behavior. Newly proposed details (measurement protocol, aggregate
query budget, compatibility freeze and candidate window) refine the roadmap and
are not claims that the original specification already prescribed them.

## Gaps corrected in the final roadmap

| Incomplete approach identified during review | Correction incorporated |
| --- | --- |
| Treating static suggestions as the MVP | M2–M4 require context-sensitive behavior and all specified dynamic data before MVP acceptance. |
| Adding dynamic values before safe quoting/timeouts | Explicit M2/M3 dependency; parser round trips, cancellable work and cache behavior precede dynamic provider shipment. |
| Giving each lookup 500 ms without a request bound | M3 caps aggregate query work and requires cleanup; chained calls cannot multiply the wait. |
| Catching thrown errors but leaking other output | M2 buffers and validates output and covers non-terminating errors and stream contamination. |
| Testing exclusion metadata rather than actual registration | M1 requires callback observations and fresh-process tests. Existing metadata checks alone are insufficient. |
| Saying “all options” without a supported inventory | M4 supplies a minimum inventory and requires per-tool-version arity/context tables; F1/F2 explicitly own extensions. |
| Suggesting existing entities for creation or remote targets | M4 distinguishes existing/new values and suppresses local data for remote contexts. |
| SSH Include support without recursion or locality limits | M4 requires cycle/depth/file/byte/time bounds and excludes automatic network-path reads. |
| Cache clear racing in-flight writes; failures cached as success | M3 specifies invalidation of in-flight results and explicit failure/expiry behavior. |
| Assuming installer source proves upgrade/uninstall correctness | M5/F5/R4/S2 require VM evidence, retained-version cleanup and preservation of added files. |
| Architecture label assumed to prove compatibility | M5 explicitly reconciles installer architecture directives with the declared support matrix. |
| Draft release treated as public WinGet availability | M5 separates implementation acceptance, submission, acceptance and public smoke tests. |
| Wildcard selection of old dist assets during release | R5 requires exact current-build assets; M5 requires clean version-consistent payloads. |
| License/signing left until v1 | M5 makes license and signing decision MVP publication gates. Signing itself is not invented as an existing requirement. |
| v0.10 confused with v0.1, or four divergent branches | Version semantics and sequential release-branch strategy are explicit. No Git branches were created by this documentation change. |
| Future releases merely labeled “polish” or “stable” | F/R/S work items provide specific implementation areas, migration matrices, candidate checks and stable-contract/support gates. |
| Adding Gallery/ARM64/new providers as accidental v1 blockers | Scope controls defer them and retain the specification's five-provider focus. |

## Remaining implementation decisions

These do not leave features unassigned: each has an owner and a deadline.

| Decision | Deadline/owner | Required output |
| --- | --- | --- |
| License, publisher ownership, package ID and signing policy | M5, before first publication | Recorded choice and completed files |
| Read-only query mechanism and cancellable execution strategy | M3, before dynamic integration | Prototype proving deadline and cleanup |
| SSH traversal and memory/result/cache bounds | M3/M4, before MVP acceptance | Explicit numerical limits and boundary tests |
| Exact tool option applicability and supported tool/OS versions | M1/M4, before MVP acceptance | Capability tables from verified syntax and fixtures |
| Reference performance environment | M6, before MVP acceptance | Machine details, measurement script and results |
| Stable support/triage ownership | R1/S1/S4, before v1 publication | Compatibility/support policy and named maintainer role |

Review result: **the roadmap covers the specification and has testable release
gates for all four milestones**. It does not assert implementation completeness,
successful installation, current package availability, or guaranteed performance.
