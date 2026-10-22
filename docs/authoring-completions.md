# Authoring providers

Users register providers without editing the module. Import PS7-Completion, then:

```powershell
Register-PS7CompletionProvider -Name mytool -CommandName mytool,mytool.exe -Path ./mytool.ps1
```

Alternatively pass `-ScriptBlock { param($context) ... }`. Scriptblocks run in
their original scope; use `.GetNewClosure()` if you need to capture local variables
when constructing a provider in another function. Names are simple identifiers;
executable names cannot contain paths or shadow existing PowerShell aliases.
Use `sc.exe`, not `sc`. Registration may replace another module's native completer.
The module cannot detect or restore it. Restart the shell to change exclusions.

Duplicate provider IDs require `-Force`. Replacement must retain the same executable
names to avoid abandoned callbacks. Another enabled provider cannot own the same
command. Excluded bundled providers can be replaced explicitly by a custom provider.
Get-PS7CompletionProvider reports Enabled, Loaded, Status and Source. Status is
Registered (lazy file), Loaded, Excluded or Failed; a later successful request
recovers a failed provider. Clear-PS7CompletionCache clears bundled query data only.

A provider file returns exactly one scriptblock. That scriptblock takes a context
and emits only CompletionResult objects:

```powershell
{
    param($Context)
    if ($Context.ArgumentIndex -eq 0) {
        New-PS7CompletionResult -Candidate @('build', 'test', 'deploy') -WordToComplete $Context.WordToComplete
    }
}
```

The framework constructs context using AST extents. Arguments exclude the command,
retain original quoting, stop at the cursor, and use a zero-based ArgumentIndex.
See [the context contract](specification.md#runtime-contract). Never evaluate an
argument, split input on spaces, or execute the command being completed.

The context also exposes `Values` (safely decoded literal arguments),
`PreviousArguments` (only completed arguments before the current slot) and
`IsSupported`. Unsupported expression contexts never invoke your provider. Values
are parsed, never evaluated; variables, subexpressions and splatting are unsupported.
Numeric literals, quoted words and escaped literal characters are supported.

## Python scripts: direct and interpreter invocation

Register the script filename once. Put the registration after the module import
in your PowerShell profile to enable it in future sessions:

```powershell
Import-Module PS7-Completion
Register-PS7CompletionProvider -Name mom -CommandName mom.py -Path "$HOME/completions/mom.ps1"
```

The provider file contains a single scriptblock; [examples/mom.ps1](../examples/mom.ps1)
implements the top-level commands and options from the task manager example.
The same provider handles `mom.py a<Tab>` and `python mom.py a<Tab>` (both suggest
`add`). Direct execution requires your existing PATH/PATHEXT/file association
setup; the framework does not change it or execute the script during completion.

The bundled Python provider routes literal `.py` filenames for `python`,
`python.exe`, `python3` and `python3.exe`, including quoted interpreter paths.
Script paths such as `./mom.py` and `"C:/my scripts/mom.py"` match the registered
basename case-insensitively: registering `mom.py` applies to that filename in
any directory, without reading or resolving the script. Use distinct filenames
when different scripts need different providers.

For routed requests, `Arguments`, `Values`, `PreviousArguments` and `ArgumentIndex`
are relative to the script, just as for direct invocation. `CommandAst` remains
the original full invocation and `CursorPosition` remains absolute. Literal
interpreter switches and `-W`/`-X` operands before the script are skipped; `--`
ends interpreter options. Unknown interpreter syntax fails conservatively.
`-c`, `-m` and stdin mode do not route to script providers. `python -m pip`
(also `python -mpip`) delegates to the enabled provider owning `pip`, with the
same target-relative context and completion behavior as direct `pip` invocation.
This includes lazy loading, custom replacement, exclusions and failure handling;
the bundled file is not loaded separately. Script-name completion itself is not added.

Routing requires the bundled `python` provider to remain enabled and unreplaced.
Direct `mom.py` completion remains independent. `py`, wrapper functions/aliases,
and module-mode routing beyond pip are outside this feature. Provider files remain lazy,
and `-Force` replacement updates both invocation forms in the current session.

New-PS7CompletionResult performs literal case-insensitive prefix matching, preserves
case-distinct candidates, escapes PowerShell metacharacters, and limits results to
512. Optional ToolTip and ResultType parameters control presentation. You may return
standard CompletionResult objects directly, but then own insertion safety yourself.
Do not print logs, Write-Host, warnings or other objects: a request with any invalid
output or error is discarded. Debug diagnostics are off by default.

Provider files load once per module instance on first completion. Keep file-scope
work minimal. Custom code is trusted PowerShell code running **in the current
session**, not a sandbox; the framework cannot prevent side effects or forcibly
time out arbitrary callbacks. Custom providers must stay fast, read-only and local.
The private worker/cache API is intentionally not exported as a general code runner.
Processes, services and tasks use a killable worker with a 500 ms shared work
budget. SSH uses a bounded local parser in the current session with cooperative
500 ms traversal checks; filesystem calls cannot be interrupted by these checks.
Bundled queries use a 30-second cache TTL, at most 128 cache entries and 4096
fetched values per query. Worker termination/disposal adds a small amount of time
beyond its deadline.

For bundled contributions, add a registry entry and a provider under Completions.
Registry files must contain data only; all entries validate before any callback is
registered. No custom registry file or module source edit is required for users.

For a local API smoke test (no executable is launched):

```powershell
$line = 'mytool bu'
[System.Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null).CompletionMatches
```

Add tool tests under `tests/Completions` and fixture data under `tests/Fixtures`.
Cover empty prefixes, mixed case, quoted inputs, option values, cursor edits,
missing executables, permission failures and malformed data as applicable.
