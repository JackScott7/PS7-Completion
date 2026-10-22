# Fixtures

Use synthetic offline data only. Do not copy private hostnames, credentials or
live process/service snapshots here.

`option-values.psd1` and `detailed-contexts.psd1` contain executable completion
cases. The latter records native capability snapshots verified on 2026-10-22:
Windows 10.0.26300 help, WinGet 1.29.380 source help, and OpenSSH for Windows 9.5p2
with the OpenBSD ssh_config reference. These are static supported inventories,
not runtime version probes or a certification of every older tool release.

## F2 supported subsets

- WinGet source: add/list/update/remove/reset/export/edit; common help, logging,
  interaction and proxy switches. Add supports name/arg/type aliases, trust level,
  header, agreements and the explicit flag. Edit supports name and explicit boolean
  aliases. Reset supports force. Source names, URLs and headers remain free text;
  sources are never enumerated. Newer help can differ from older documentation.
- Schtasks: schedule-dependent day/month/modifier, idle, event, delay, repetition,
  duration and end-time switches. Quoted comma-separated day/month values retain
  preceding members and exclude duplicates. Monthly ordinal modifiers select
  weekdays; LASTDAY suppresses days. ONCE/trigger schedules have no numeric modifier.
  Free-form dates, times, event channels and XPath expressions have no invented
  suggestions. Option filtering guides valid combinations; it is not a full native
  validator. Before /SC is known, common options remain available.
- sc.exe: separate key/value operands, query/service-name separation, repeated
  interactive type refinement, built-in service accounts and slash-separated local
  service dependencies. Dependency groups beginning with + remain free text.
  Remote contexts never enumerate local service names.
- Taskkill: quoted /FI name, per-field operator and STATUS finite-value grammar.
  Candidates replace the whole filter, using single spaces between grammar parts.
  Numeric fields, accounts, titles, DLLs and image names in filters remain free
  text. Filters never enumerate processes. Remote filters exclude STATUS and
  WINDOWTITLE. Only /PID and /IM enumerate local process data.
- SSH: case-insensitive directives, equals separators, double-quoted tokens,
  quoted # characters, comments, local Include paths, Match all, and conditional
  state across included files. Host resets conditional state. Other Match blocks
  suppress Includes until Host or Match all; conditions are never evaluated.
  Host aliases form a static inventory, not an effective per-host configuration.
  Wildcard and negated aliases are omitted. Unbalanced quoted lines are skipped;
  malformed Match lines conservatively suppress Includes. Environment/token
  expansion, user-home lookup beyond ~/, remote Includes and conditional execution
  remain unsupported. Existing size, depth, file-count and deadline bounds apply.

Reference links are recorded in `detailed-contexts.psd1`. Native help was read
only during implementation, never from a completion callback.
