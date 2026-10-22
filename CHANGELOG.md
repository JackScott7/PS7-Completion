# Changelog

## Unreleased

- Add all-provider cold/warm benchmarks, local query/result-count reporting,
  worker timing diagnostics and opt-in same-machine regression checks.
- Assemble runtime helpers during builds and load the SSH parser on first use.
- Index command ownership, normalize SSH cache paths, deduplicate per-parse
  filesystem reads and include link targets in dependency invalidation.
- Bound task-folder traversal, reduce process/service collection overhead and
  dispose process handles after enumeration while retaining isolated query workers.
- Reduce result sorting overhead, add a large-set prefix search, and retain
  command-first ordering, safe quoting, case-distinct candidates and result limits.
- Retain performance JSON artifacts in CI without imposing noisy timing thresholds
  on shared hosted runners.

## 0.1.4 — Python routing and installer-only distribution

- Distribute only the Inno Setup installer and checksums; remove module ZIP output.
  WinGet continues to target the same installer. Builds without `-Installer` stage
  and validate the payload without producing release assets.

- Delegate `python -m pip` to the registered pip provider for parity with direct
  `pip`, including full argument context, exclusions and custom replacements.

- Route registered `.py` providers through the bundled Python completer, sharing
  script-relative context with direct script invocation. Preserve interpreter and
  `python -m pip` completion, lazy loading and provider failure isolation.
- Document registration for both invocation forms and add a task-manager example.

## 0.1.3 — baseline network and developer tools

- Add Windows ipconfig, tracert, nslookup, and netstat providers.
- Add curl.exe, Cargo, and Docker with nested Compose support: 34 providers total.
- Preserve command-first ordering and suppress suggestions inside free-form or
  forwarded arguments.
- Match operand-value tables case-sensitively, keeping curl `-H` headers separate
  from `-h` help topics.

## 0.1.2 — expanded built-in providers

- Add Windows `ping`, `uvx`, `uvicorn`, `twine`, and `ruff`, bringing the total to 27.
- Order completion menus with commands first and options/arguments second.
- Add 17 static built-in providers for developer tools, with command-specific
  options, finite operand values, and Python-to-pip delegation.
- Record WinGet installation identities and portable/Python-package distinctions.

## 0.1.1 — SSH completion patch

- Support local SSH config symbolic links and junctions.
- Read SSH configuration in-process to reduce first-completion latency.

## 0.1.0 — private MVP

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
