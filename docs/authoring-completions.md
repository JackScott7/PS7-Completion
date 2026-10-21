# Authoring providers

Add a registry entry with a stable provider ID, executable names, and a relative
script path under `Completions/`. Do not register names that shadow PowerShell
aliases (in particular, use `sc.exe`, not `sc`).

A provider file returns exactly one scriptblock. That scriptblock takes a context
and emits only CompletionResult objects:

```powershell
{
    param($Context)
    New-PS7StaticCompletion -Candidates @('--help', '--version') -WordToComplete $Context.WordToComplete
}
```

The framework constructs context using AST extents. Arguments exclude the command,
retain original quoting, stop at the cursor, and use a zero-based ArgumentIndex.
See [the context contract](specification.md#runtime-contract). Never evaluate an
argument, split input on spaces, or execute the command being completed.

Provider files load once per module instance on first completion. Keep file-scope
work minimal. Current helpers support static unquoted vocabulary only. Implement
and test safe quoting before emitting paths or dynamic names with spaces or shell
metacharacters. Dynamic queries also require the timeout and TTL cache specified
in the design; the scaffold cache is only an extension point.

Add tool tests under `tests/Completions` and fixture data under `tests/Fixtures`.
Cover empty prefixes, mixed case, quoted inputs, option values, cursor edits,
missing executables, permission failures and malformed data as applicable.
