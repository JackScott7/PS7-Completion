# WinGet packaging

The Inno Setup EXE is the only user-facing installation package. Direct downloads
and WinGet use that same versioned EXE; no module ZIP is built or published.
`scripts/Build.ps1 -Installer` produces the EXE and SHA256 checksums, and the
manifest generator records that EXE's URL/hash with `InstallerType: inno` and
machine scope. Validate unattended install, upgrade and uninstall through WinGet
in the disposable environment before claiming support for a released package.

`manifest.yaml.template` is an unpublished singleton manifest template, not a
validated public package. Publisher/repository are JackScott7/PS7-Completion and
the license is MIT. The repository remains private by owner request, so public
WinGet submission is deferred. Confirm identifier availability before a future submission.

1. Complete the specification's public release gates and make release assets publicly accessible through an explicitly approved distribution decision.
2. Build and test the installer in a disposable Windows VM with PowerShell 7.4+.
3. Publish versioned immutable assets on the confirmed GitHub repository.
4. Run `scripts/New-WinGetManifest.ps1` with the build metadata and verify its SHA256 against the hosted asset.
5. Save as a `.yaml` file and run `winget validate --manifest <directory>` using
   the current WinGet schema. Test local installation and removal in the VM.
6. Submit manifests to microsoft/winget-pkgs following its current contribution
   rules (split singleton manifests if required by submission tooling).

The draft GitHub release workflow does not submit WinGet manifests. Existing
PowerShell sessions must be restarted after upgrading or uninstalling. Verify
that uninstall removes installer-owned prior versions while preserving user files.
