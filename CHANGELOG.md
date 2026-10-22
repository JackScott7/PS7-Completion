# Changelog

## 0.1.5 - Performance and regression checks

### Added

- Measure cold import, first and warm completion for all 34 providers, Python
  routing, query misses and hits, worker timing, and large result sets.
- Compare results on the same machine with correctness checks and optional timing
  enforcement. CI retains benchmark reports for review.
- Validate that release version, changelog, and release notes agree before building
  and publishing assets.

### Changed

- Assemble runtime helpers when building the installer and load the SSH parser on
  first use. In the recorded same-machine comparison, import p95 fell from
  159.20 to 90.67 ms and large-result formatting p95 from 41.14 to 33.31 ms.
- Index provider ownership, normalize SSH cache paths, avoid duplicate metadata
  reads within a parse, and reduce result sorting and filtering overhead.
- Bound task-folder traversal and reduce process/service collection overhead while
  retaining the disposable query worker and its 500 ms work deadline.

### Fixed

- Include SSH link targets in cache dependency stamps so a retargeted link
  invalidates cached results.
- Preserve command-first ordering, case-distinct candidates, safe quoting and the
  512-result limit through the optimized result path.

The figures above come from three fresh processes per provider and 20 warm samples
per case on one Windows 10.0.26300 / PowerShell 7.6.7 machine. See
[performance evidence](docs/performance-plan.md) for the protocol and mixed lookup
results.

## 0.1.4 - Python routing and installer-only distribution

- Distribute only the Inno Setup installer and checksums; remove module ZIP output.
  WinGet continues to target the same installer. Builds without `-Installer` stage
  and validate the payload without producing release assets.

- Delegate `python -m pip` to the registered pip provider for parity with direct
  `pip`, including full argument context, exclusions and custom replacements.

- Route registered `.py` providers through the bundled Python completer, sharing
  script-relative context with direct script invocation. Preserve interpreter and
  `python -m pip` completion, lazy loading and provider failure isolation.
- Document registration for both invocation forms and add a task-manager example.

## 0.1.3 - baseline network and developer tools

- Add Windows ipconfig, tracert, nslookup, and netstat providers.
- Add curl.exe, Cargo, and Docker with nested Compose support: 34 providers total.
- Preserve command-first ordering and suppress suggestions inside free-form or
  forwarded arguments.
- Match operand-value tables case-sensitively, keeping curl `-H` headers separate
  from `-h` help topics.

## 0.1.2 - expanded built-in providers

- Add Windows `ping`, `uvx`, `uvicorn`, `twine`, and `ruff`, bringing the total to 27.
- Order completion menus with commands first and options/arguments second.
- Add 17 static built-in providers for developer tools, with command-specific
  options, finite operand values, and Python-to-pip delegation.
- Record WinGet installation identities and portable/Python-package distinctions.

## 0.1.1 - SSH completion patch

- Support local SSH config symbolic links and junctions.
- Read SSH configuration in-process to reduce first-completion latency.

## 0.1.0 - private MVP

- Register custom inline or lazy-file completion providers without editing the module.
- Construct safely quoted CompletionResult values through a public helper.
- Validate provider ownership, configuration and registry data before registration.
- Parse literal AST context, preserve token boundaries and isolate provider failures.
- Add context-aware SSH, WinGet, scheduled-task, service and taskkill completion.
- Bound local dynamic queries using a disposable PowerShell worker and TTL cache.
- Build versioned MIT-licensed ZIPs/installers, checksums and WinGet manifest templates.
- Test Windows installer reinstall, upgrade, retained versions and owned-file removal.

The repository remains private by owner request. Public WinGet distribution is
deferred. See docs/mvp-status.md for measured evidence and remaining release work.
