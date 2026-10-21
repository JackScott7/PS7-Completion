# PS7-Completion roadmap

Validated against [the specification](specification.md) and the current scaffold
on 2026-10-22. Updated after implementation: checked items have local/CI evidence
in [MVP status](mvp-status.md). Unchecked broad release items still contain pending
work; they are not all blockers for the owner-approved private-MVP delivery.

Scope amendment: the owner requested user-registerable providers, MIT licensing,
small commits pushed to the private upstream, and a tested installable MVP while
keeping the repository private. The API therefore has four public commands,
including Register-PS7CompletionProvider and New-PS7CompletionResult. Public WinGet
publication is deferred; no visibility change or public package submission is planned.

## Milestones and branch strategy

MVP means **v0.1.0 with the complete v0.1 specification**, including distribution.
v0.5.0 improves coverage and reliability; v0.10.0 is the release-candidate baseline;
v1.0.0 establishes a supported stable contract. Versions are semantic version
components: v0.10 follows v0.5; it is not another spelling of v0.1.

| Planned release branch | Result | Starts after |
| --- | --- | --- |
| `release/0.1` | MVP: five useful providers and installable distribution | Foundation work on `main` |
| `release/0.5` | Broader argument coverage and repeatable compatibility checks | MVP acceptance |
| `release/0.10` | Feature freeze, migration validation, release candidates | v0.5 acceptance |
| `release/1.0` | Stable public/provider contracts and support process | v0.10 acceptance |

These are planned release branches; Git is initialized with `main` tracking
`upstream/main` at the owner-provided repository. Develop each milestone on short-lived
feature branches merged into `main`, then cut its release branch for stabilization.
Do not create four diverging implementations. Fixes made during stabilization must
also reach `main`; tag accepted releases `v0.1.0`, `v0.5.0`, `v0.10.0`, and `v1.0.0`.
Prerelease tags must have explicit prerelease metadata consistent with the module
manifest; do not use a four-component numeric version to imitate SemVer labels.

Each milestone inherits every earlier acceptance gate. A release cannot trade an
unfinished earlier requirement for a later feature. Optional distribution channels
and additional providers do not block these four milestones.

## Current baseline

The framework supplies validated lazy callbacks, AST context, four public commands,
custom providers, context-sensitive built-in providers, literal quoting, isolated
queries, TTL caching, versioned builds and installer lifecycle CI. Test and measurement
results, specific limitations and the private-delivery boundary are in MVP status.

## Branch `release/0.1` — achieve the MVP

### M1. Foundation and configuration

- [ ] Preserve Windows, PowerShell 7.4+ Core, pure PowerShell runtime and x64
  installer scope. Verify minimum and selected current supported PowerShell
  versions; record exact OS/tool versions in the test evidence.
- [x] Validate registry IDs, executable lists and provider paths before registering
  any callback. Resolve paths inside the module; reject missing/invalid entries.
  Register bare and `.exe` forms except `services`, which registers only `sc.exe`.
- [x] Keep import free of external processes, network access and system-data
  enumeration. Load each provider once on first request and validate its contract.
- [x] Validate the configuration shape, supported keys and Exclude values. Unknown
  IDs must fail before registration. Export the four amended public commands
  and all provider metadata fields: Name, Commands, Enabled, Loaded, Status.
- [x] Define truthful Status values for enabled, excluded, loaded and failed states.
  Document first-import exclusions, restart behavior, import-order collisions and
  the absence of automatic restoration/detection of other completers.

Implementation: module entry point, registry, public commands, private loader;
tests must observe registration calls and use fresh processes for exclusion tests.
An Enabled=false metadata assertion alone does not prove registration was skipped.

### M2. Context, matching and result safety

- [x] Complete the five-field context contract (plus additive literal helpers): raw WordToComplete, original
  CommandAst, absolute CursorPosition, source-preserving Arguments excluding the
  executable, and zero-based ArgumentIndex. Ignore later arguments and truncate
  the current argument at the cursor; trailing whitespace selects the next slot.
- [x] Handle empty/incomplete input, quoted command paths, invocation operator,
  quoted/escaped words, cursor edits, pipelines and redirection boundaries without
  evaluating expressions. Unsupported expression forms return no provider results.
- [x] Use ordinal case-insensitive literal prefix matching; deduplicate candidates
  and provide deterministic ordering, meaningful list text and tooltips.
- [x] Add literal extraction and insertion helpers. Quote/escape dynamic names
  correctly for the actual replacement span, including spaces, apostrophes,
  backticks and metacharacters. Do not double-quote existing quoted tokens.
  Round-trip completion text through the parser in tests without executing it.
- [x] Buffer provider output, validate every result type and discard invalid or
  partial results on failure. Capture non-terminating errors and unwanted output
  streams as well as thrown errors; normal completion must stay silent, with
  diagnostic detail available only through debug output.

Implementation: split context, matching, literal formatting and invocation helpers
under `Private/`; preserve the documented external provider context.

### M3. Bounded read-only data and caching

- [x] Implement a shared query runner with a **500 ms wall-clock query work deadline**,
  cancellation and disposal. An abandoned background job/runspace is not a timeout
  implementation. Bound the aggregate dynamic-query work per completion request
  to the same budget; do not allow sequential queries to multiply the wait. OS
  termination/disposal adds latency after the deadline; arbitrary custom callbacks
  are trusted in-session code and do not run inside this private query runner.
- [x] Use local PowerShell/Windows read-only data access for tasks, services and
  processes. Do not launch `ssh`, `winget`, `schtasks`, `sc.exe`, or `taskkill` from
  their completers, and never execute a command assembled from user input.
- [x] Add **30-second TTL** cache entries keyed by provider, normalized query
  parameters and relevant file metadata. Use a monotonic clock for TTL; bound cache
  size, invalidate changed SSH inputs, and do not persist sensitive host/process data.
- [x] Treat unavailable dependencies, denied access, malformed data and timeout as
  empty results with optional debug detail. Cache successful empty results; do not
  cache a failure as success or return expired data without an explicit future policy.
- [x] Make Clear-PS7CompletionCache clear data only, without unloading providers or
  unregistering callbacks. Prevent in-flight queries from repopulating cleared data.
- [x] Test the clock, cache-key separation, file changes, timeout cleanup, repeated
  failures, cache limits and explicit clearing with fixtures/mocks.

Implement M2 and M3 before enabling any dynamic provider path.

### M4. Deliver all five provider contracts

The following is the minimum implementation inventory. For each supported native
tool version, check its command syntax/help during implementation and record the
supported options and their arity in a fixture-backed capability table. Static
metadata must distinguish commands, flags, option values and positional values.
Do not describe unsupported native options as supported.

| Provider | MVP options/features | Required implementation and acceptance |
| --- | --- | --- |
| `ssh` | Common switches including the scaffold's `-4`, `-6`, `-A`, `-F`, `-i`, `-J`, `-L`, `-p`, `-R`, `-v`; destination Host aliases | Track option operands so host suggestions never appear as port, identity, forwarding or jump operands. Parse user config and an explicit literal `-F` config; support comments, multiple aliases, missing files and bounded Include traversal. Exclude wildcard/negated aliases. Deduplicate literal hosts; handle a literal `user@` destination prefix. Never perform DNS/network lookup or execute config commands. |
| `winget` | `install`, `show`, `source`, `search`, `list`, `upgrade`, `uninstall`, `export`, `import`, help/version; command-specific option tables | Suggest commands only in command position and flags only in valid contexts. Initial option inventory includes applicable `--id`, `--name`, `--source`, `--exact`, `--version`, `--scope`, help and file arguments; verify applicability per subcommand. Complete finite values such as scope from metadata, suppress command suggestions at free-text operands. No remote package/source enumeration. |
| `schtasks` | `/Create`, `/Delete`, `/Query`, `/Change`, `/Run`, `/End`, `/ShowSid`, help; applicable options and `/TN` names | Encode operation-specific `/TN`, `/TR`, `/SC`, `/ST`, `/F` and output options with correct arity. Enumerate local task paths only for operations that target existing tasks; creation accepts a new task name. Preserve task folders and spaces. Remote target contexts return no local task names. |
| `services` (`sc.exe`) | `query`, `queryex`, `start`, `stop`, `qc`, `config`, `create`, `delete`, `description`; applicable service operands/options | Return internal service names, not display names, only where an existing service is expected. New service names stay free text. Recognize `key=` option syntax and value positions; never suggest a service in a configuration value slot. Remote server contexts return no local service data. Do not register `sc`. |
| `taskkill` | `/PID`, `/IM`, `/FI`, `/F`, `/T`, help; process IDs and image names | Return numeric PIDs only after `/PID`, local image names only after `/IM`, and no process names at filter operands. Handle repeated selectors and case-insensitive options. Recognize remote-target options to avoid presenting local data for remote targets. Never terminate a process. |

SSH Include traversal must have explicit tested depth, file-count, byte and elapsed
limits; detect cycles, resolve paths deterministically, and handle inaccessible
includes. Reject network/UNC config paths for automatic reads to preserve the
local-only contract. If richer SSH conditional syntax is unsupported, document
its treatment and skip it safely; never evaluate `Match exec` or similar directives.

Each provider needs positive and negative context tests, unavailable-data cases,
mixed-case prefixes and quoted values. Unknown syntax must fail conservatively
rather than suggest unrelated arguments. M4 does not promise exhaustive native CLI
coverage or package-ID completion.

### M5. Installation, activation and release assets

- [ ] Select the license and publisher, replace LICENSE placeholder, confirm name
  and proposed WinGet ID availability, and set repository/release URLs.
- [ ] Build a versioned module ZIP and Inno Setup EXE from one staged payload.
  Match manifest, directory, installer, tag and WinGet versions; fail on unresolved
  placeholders, stale assets or unexpected payload files. Publish SHA256 for both.
- [ ] Preserve stable AppId, machine-wide elevation, standard module directory and
  uninstall metadata outside version folders. Reconcile installer architecture
  directives with the declared x64-only support matrix and test unsupported hosts.
- [ ] Prove silent install, reinstall, upgrade, uninstall and retained-version
  behavior in a disposable VM. Remove only installer-owned files across versions;
  preserve added user files. Test canceled elevation, failure cleanup, loaded-shell
  behavior, new-shell discovery and the documented uninstall/reinstall downgrade path.
- [ ] Leave profiles, PATH and PSModulePath unchanged; do not install PowerShell
  implicitly. Document prerequisite checks, explicit profile import and restart
  requirements. Installation must not run completion queries.
- [ ] Record the signing decision before publication. If signing, verify signatures
  and timestamping before computing hashes; if unsigned, document that explicitly
  and test the intended installation path without promising warning-free installs.
- [ ] Validate real WinGet manifests against the release installer URL/hash, test
  local manifest installation, and submit to winget-pkgs. Track acceptance separately
  from GitHub publication. Verify public install/upgrade/uninstall after availability.
  Do not advertise WinGet availability while submission is pending.

MVP implementation acceptance requires all internal gates and a tested manifest;
the **distributed MVP milestone** additionally requires WinGet acceptance and a
public installation smoke test. External submission delays do not waive this gate.

### M6. MVP verification and documentation

- [ ] Run Pester 5, PSScriptAnalyzer and archive build in Windows CI; analyze runtime
  and build/release scripts. Test both minimum and selected current supported PS7.
- [ ] Add executable-specific tests under `tests/Completions/`, core edge cases under
  `tests/Core/`, and synthetic fixtures. Mock data sources; never mutate live
  services/tasks/processes as part of provider tests.
- [ ] Run real interactive Tab completion in a disposable environment, separately
  from parser/API tests. Cover every registered executable name and `sc` alias safety.
- [ ] Measure cold import and warm static completion on a recorded reference
  machine. Proposed repeatable protocol: 30 fresh-process imports and 100 warm
  requests per provider; report median and p95. Target p95 under 100 ms import and
  50 ms warm static completion; investigate and explicitly resolve misses before
  acceptance. Separately prove the 500 ms dynamic-query deadline and cleanup.
- [ ] Update README, authoring guide, contribution instructions, changelog and
  troubleshooting to reflect actual supported syntax, exclusions, cache semantics,
  prerequisites, install/upgrade/remove behavior and remaining limitations.

**Exit evidence:** linked test results, provider capability tables, reference-machine
measurements, interactive checklist, VM lifecycle report, immutable release assets,
license/signing decision and WinGet publication record. No unresolved MVP behavior
may be reclassified as a v0.5 enhancement merely to close the milestone.

## Branch `release/0.5` — broaden coverage and harden operation

- [ ] **F1: Complete option-value behavior for the supported inventory.** Add safe
  local path completion for SSH `-i`/`-F` and applicable WinGet import/export paths;
  handle provider-supported `--option=value`, repeated options, attached operands
  and end-of-options syntax only where the native tool supports them. Add finite
  value suggestions for validated scheduling and service configuration options.
  Every addition updates capability fixtures and wrong-position tests.
- [ ] **F2: Improve detailed provider contexts.** Add fixture-backed WinGet nested
  `source` command options and version capability tables; expand schtasks schedule
  combinations, sc query/configuration key-value handling and taskkill filter
  grammar suggestions. Expand SSH alias/config syntax coverage without evaluating
  conditional commands. Exact supported subsets must remain explicit.
- [ ] **F3: Strengthen data handling at scale.** Exercise large SSH include trees,
  task folders and process/service lists; bound results and memory, deduplicate
  consistently, and test refresh during file changes or process exit. Keep the
  existing timeout, TTL and clear semantics; any API change needs migration notes.
- [ ] **F4: Make compatibility repeatable.** Add automated fresh-shell tests for
  multiple supported PS7/tool versions, missing executables and read-denied data;
  verify first-import exclusions and repeated imports without claiming restoration.
- [ ] **F5: Repeat packaging validation.** Automate VM install/upgrade/uninstall
  reports and test upgrade from v0.1 to v0.5, retained versions, user-added files and
  ZIP payload import. Build WinGet manifests from explicit release metadata and
  reject placeholder/hash/version mismatches before submission.
- [ ] **F6: Improve contributor feedback.** Add provider contract checks, per-provider
  coverage reports and a documented debugging recipe that does not emit private
  data by default. Preserve the amended four-command public API.

Implementation areas: provider metadata/helpers, fixture matrix, isolated-process
tests, packaging validation scripts and CI. **Exit:** all MVP gates plus fixtures
for every advertised option/value rule, scale results within documented bounds,
and successful v0.1 → v0.5 lifecycle evidence. No new provider is required.

## Branch `release/0.10` — stabilize the v1 candidate

- [ ] **R1: Freeze the intended v1 contract.** Review public parameter behavior,
  metadata fields/status meanings, provider context, return types, exclusions,
  query/cache semantics and error behavior. Publish a compatibility document;
  resolve breaking changes now with explicit pre-1.0 migration notes.
- [ ] **R2: Close all accepted provider gaps.** Reconcile documentation and capability
  tables against tests for the five tools. Every advertised feature must pass;
  unsupported syntax is documented, not represented by a blanket "full support" claim.
- [ ] **R3: Exercise resilience.** Run bounded randomized parser inputs and repeated
  completion/clear/failure cycles. Verify no expression execution, network access,
  leaked background workers, stream contamination or unbounded cache growth.
- [ ] **R4: Validate upgrades across releases.** Test v0.1 → v0.10 and v0.5 → v0.10,
  repeated installs, uninstall after multiple retained versions and missing/modified
  owned files. Review installer identity, architecture, hashes and signing policy.
- [ ] **R5: Freeze and verify release inputs.** Record dependency/compiler versions,
  use clean staging, validate archive/installer payload equality, verify downloaded
  asset hashes, and audit workflow permissions and secret handling. Release jobs
  must select the current build's exact assets, not every file found in dist.
- [ ] **R6: Publish release candidates with a triage window.** Record candidate
  versions, testers, supported Windows/PS7/tool combinations and feedback outcomes.
  Run a minimum 14-calendar-day candidate period; restart the affected regression
  checks and extend the window for material runtime/installer changes.

**Exit:** all inherited gates; frozen compatibility document; complete migration
matrix; candidate evidence; no unresolved critical/high issue affecting advertised
behavior, data preservation, execution safety or installation. This is still a
pre-1.0 release, not the stable-support announcement.

## Branch `release/1.0` — ship the stable release

- [ ] **S1: Adopt the stable contract.** Finalize support policy and versioning:
  breaking public/provider contract changes require a major release; compatible
  additions use minor releases; fixes use patches. Record supported Windows, PS7
  and native tool versions and how support is retired. Do not silently raise the
  PowerShell minimum during stabilization.
- [ ] **S2: Complete final regression and migration.** Re-run all prior gates on the
  exact v1 candidate, including v0.1/v0.5/v0.10 → v1 upgrade and subsequent uninstall,
  fresh install and manual activation. Resolve all release-blocking defects and
  record any non-blocking limitations with reproducible scope.
- [ ] **S3: Publish the verified artifacts.** Align version metadata, changelog,
  license and documentation; verify signatures according to the adopted policy,
  publish immutable ZIP/installer/checksums, submit manifests and verify public
  WinGet install/upgrade/uninstall. Never replace a released binary in place.
- [ ] **S4: Establish maintenance.** Publish issue/security reporting instructions,
  triage ownership, supported-version policy and a patch-release checklist. Document
  manual uninstall/reinstall recovery and preserve prior asset availability; do
  not imply automatic rollback or live-session activation.
- [ ] **S5: Complete contributor and user docs.** Provide tested first-install,
  activation, exclusion, provider authoring, troubleshooting and upgrade examples.
  Verify all links, names, version examples and capability statements against v1.

**Exit:** stable contract and support owner recorded, all inherited evidence passes
for the exact shipped artifacts, public WinGet availability verified and no known
release-blocking defect. A tag or successful draft workflow alone is insufficient.

## Dependency and scope controls

Implementation order: M1 → M2 → M3 → M4 → M6 acceptance; M5 packaging can proceed
alongside runtime work but publication waits for M4/M6. Then F1–F6 → R1–R6 → S1–S5.
License/publisher/signing decisions in M5 should be resolved early, not on release day.

Deferred beyond this roadmap unless the specification is explicitly amended:
PowerShell Gallery, ARM64 installers, per-user installation, additional providers,
cross-platform support, Windows PowerShell 5.1, persistent configuration commands,
automatic profile edits, completer restoration/detection and remote/network queries.
Gallery may later reuse the same module payload, but is not a v1 acceptance gate.

Maintain an evidence record per release with: requirement ID, implementation files,
test IDs, exact environment/tool versions, artifact hashes, result, outstanding
issue and reviewer. Mark a checkbox complete only when its evidence is linked.
See [the roadmap validation](roadmap-validation.md) for specification traceability
and corrections incorporated during review.
