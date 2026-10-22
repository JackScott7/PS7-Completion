# v0.1.4 release evidence

Scope: normal private patch release, not acceptance of the v0.5/v1.0 milestones.
The earlier [MVP record](mvp-status.md) is historical, including its ZIP artifacts.
Current distribution uses only the installer, checksums and WinGet metadata.

Local validation on 2026-10-22: the full 262-test Pester 5.7.1 suite and
PSScriptAnalyzer 1.24.0 pass on PowerShell 7.6.7. This includes direct/hosted Python
script contexts, pip parity, exclusions, replacements, lazy loading, unsafe-input
rejection and failure isolation. Build tests verify staged payloads without ZIPs.

Performance protocol: 30 fresh-process imports and 100 warm requests for each
original provider, Windows 10.0.26300, Intel64 Family 6 Model 186 Stepping 2,
16 logical processors, PowerShell 7.6.7. The module contains all 34 providers.

| Measurement | Median ms | p95 ms |
| --- | ---: | ---: |
| Import | 241.81 | 253.49 |
| SSH static | 3.69 | 5.15 |
| WinGet static | 3.50 | 4.23 |
| Scheduled tasks static | 1.07 | 1.22 |
| Services static | 1.13 | 1.25 |
| Taskkill static | 1.23 | 1.42 |

Warm completion meets the 50 ms target in this sample. Cold import does not meet
the proposed 100 ms target and remains an explicit limitation of this private
patch. These measurements do not certify every new provider or compare directly
with the historical five-provider registry. F3/F4 performance acceptance remains open.

The tag-triggered Release workflow gates publication on current/minimum PowerShell
tests, analyzer checks, exact-EXE silent install/reinstall/upgrade/uninstall,
installed-file equality and downloaded-asset hashes. Its retained installer logs
and result.json provide OS/engine/version evidence. Synthetic next-version upgrade
tests do not substitute for the future v0.1-to-v0.5 migration matrix.

Public WinGet availability, canceled elevation, abrupt interruption, unsupported
platform combinations and every modified-owned-file recovery scenario are not
certified. Custom callbacks remain trusted in-session code. Installer tests run
only on disposable hosted machines, never on the developer workstation.
