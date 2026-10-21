# Changelog

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
