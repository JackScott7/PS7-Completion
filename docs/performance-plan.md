# Performance implementation checklist

Work proceeds in this order. Checked items mean the implementation and validation
are complete; timing targets are tracked separately and are not assumed to pass.

- [x] **1. Benchmarks:** separate shell startup, import, first Tab, warm completion,
  uncached/cached local queries, routing and result processing; record counts,
  failures, environment and median/p95 for all 34 bundled providers.
- [x] **2. Cold import:** profile import phases; reduce eager loading and evaluate
  a build-assembled runtime. Compare import plus first Tab, not import alone.
- [x] **3. Uncached lookup:** measure worker startup/collection/serialization,
  reduce avoidable work and retain the 500 ms deadline and kill/reap behavior.
- [x] **4. Resolution and caching:** index provider ownership, normalize cache
  keys, reduce duplicate SSH dependency work and verify invalidation/clearing.
- [x] **5. Result processing:** reduce redundant sorting/filtering while preserving
  deterministic command-first ordering, case-distinct values and safe quoting.
- [x] **6. Regression checks:** publish CI benchmark artifacts; provide opt-in
  same-machine comparisons with timing tolerances and correctness checks.

Targets: import p95 <100 ms; warm static/cached completion p95 <50 ms. The dynamic
query work deadline remains 500 ms, with cleanup latency reported separately.
No DNS/network requests, execution of completed commands, stale-on-error caching,
or background workers surviving a timeout are introduced to improve timings.

Baseline: v0.1.4 recorded 253.49 ms import p95 and 1.22–5.15 ms warm static p95
for the original five providers. The broader suite below will establish comparable
before/after data; historical measurements alone cannot prove an optimization.

## Implementation and validation

All six implementation items are included in v0.1.5.
273 Pester tests and PSScriptAnalyzer pass. The assembled payload passes import,
lazy-provider and Python-routing checks. Existing timeout/reaping, exclusions,
quoting and provider tests remain enabled. New tests cover cache-key equivalence,
file invalidation, dependency deduplication, link-target identity, large candidate
sets, failed registration and performance-comparison failure cases.

1. `scripts/Measure-Performance.ps1` records all 34 static providers, each provider's
   first completion in fresh shells, shell startup, import, warm requests, direct
   and Python-routed providers, synthetic SSH data and optional live local queries.
   It records raw samples, counts, errors/timeouts and whether a cache hit was primed.
   First Tab includes PowerShell's completion-engine startup, not just provider loading.
2. `scripts/Build.ps1` assembles helper functions into the installed module at build
   time. Source remains split for maintenance; bundled providers remain lazy. The
   SSH parser is loaded on first query. A scratch-copy import profile identified
   helper loading and registry validation as the largest internal phases; no
   runtime profiling or system queries were added to normal import.
3. Process/service collection uses bounded .NET loops and disposes handles; task
   traversal now bounds visited folders as well as result counts. Opt-in worker
   metrics separate collection, serialization and parent parsing. The serialization
   probe adds an extra serialization only to diagnostic requests. An empty worker
   estimates process startup. Normal queries retain disposable processes and their
   500 ms work deadline: collection savings do not justify replacing kill/reap
   isolation with an uninterruptible in-session lookup or a persistent worker yet.
4. Command ownership is indexed and updated only after successful registration.
   SSH keys use lexical absolute paths, preserving distinct link paths and their
   invalidation dependencies. Metadata reuse lasts for one bounded parse only;
   cached data still checks dependencies on every request. Link targets participate
   in stamps, and duplicate dependencies are stored once.
5. Result processing uses native collections instead of consecutive pipeline sorts.
   Large candidate sets use native sorting and a prefix lower-bound search; only
   matching values are formatted. Small sets avoid that setup. Input arrays remain
   unchanged. Case-distinct values, culture-sensitive command-menu ordering, literal
   matching, quoting, full-output validation and the 512-result limit are retained.
6. `scripts/Compare-Performance.ps1` rejects incompatible environments/protocols,
   failed samples, lost static candidates and unprimed cache hits. Timing regressions
   are reported by default and enforced with `-EnforceTiming`; default tolerance is
   the larger of 25% or 5 ms above baseline p95. CI saves informational JSON artifacts
   for the assembled payload without making hosted-runner timing a pass/fail gate.

## Same-machine results (2026-10-22)

Baseline: v0.1.4 runtime. Candidate: assembled v0.1.5 payload. Both used
PowerShell 7.6.7, Windows 10.0.26300, Intel64 Family 6 Model 186 Stepping 2,
16 logical processors and normal user permissions on the same machine.
Protocol: three fresh processes per provider (102 import measurements), 20 warm
samples per case and three cold samples per local query. This is an initial
comparison, not a broad hardware certification; repeat with more cold samples for
release acceptance. Live process counts can change naturally between samples.

| Measurement | Before median / p95 ms | After median / p95 ms |
| --- | ---: | ---: |
| Module import | 152.02 / 159.20 | 82.75 / 90.67 |
| Large result formatting (4096 inputs, 512 results) | 36.96 / 41.14 | 32.15 / 33.31 |
| Processes, uncached | 286.76 / 317.87 | 283.70 / 305.49 |
| Services, uncached | 264.39 / 276.31 | 279.86 / 289.08 |
| Tasks, uncached | 358.55 / 376.23 | 362.58 / 364.67 |
| SSH fixture, uncached | 13.58 / 55.29 | 10.15 / 26.16 |
| SSH fixture, cached | 0.13 / 0.24 | 0.18 / 1.79 |

Import meets the proposed 100 ms p95 target in this run. All 34 warm-static cases
remain below 50 ms p95 (maximum 33.73 ms). The average of the per-provider first-Tab
medians changes from 87.18 to 82.29 ms; the maximum first-Tab p95 changes from
119.41 to 123.54 ms. Import savings were not simply moved onto first completion.

No correctness failures or timing regressions exceeded the configured tolerances.
Service lookup and cached SSH timings did not improve; do not describe every row
as faster. Empty-worker startup is about 210 ms median, explaining why uncached
system lookups remain much slower than cache hits. Further worker-startup changes
need their own lifecycle/cancellation design and measurements.

Local raw evidence (ignored build outputs): `dist/performance/before-unrestricted.json`,
`after-final.json` and `comparison-final.json`. The earlier sandbox run contains
permission-denied service/task probes and is excluded from this comparison.

## Reproduce

```powershell
$build = ./scripts/Build.ps1
./scripts/Measure-Performance.ps1 `
    -Manifest (Join-Path $build.Payload 'PS7-Completion.psd1') `
    -ColdSamples 5 -WarmSamples 100 -LiveQueries `
    -OutputPath ./dist/performance/current.json

# Baseline must use the same machine, engine, OS, protocol and access permissions.
./scripts/Compare-Performance.ps1 `
    -Baseline ./dist/performance/baseline.json `
    -Current ./dist/performance/current.json -EnforceTiming `
    -OutputPath ./dist/performance/comparison.json
```

The benchmark invokes completion APIs and fixed read-only data queries, not the
completed commands. JSON records counts/timings rather than host aliases, process
names or task paths. Machine and module paths are included for reproducibility;
review artifacts before sharing them outside your environment.
