# WinGet packaging

`manifest.yaml.template` is an unpublished singleton manifest template, not a
validated package. Confirm publisher ownership and identifier availability first.

1. Complete the specification's release gates and replace the pending LICENSE.
2. Build and test the installer in a disposable Windows VM with PowerShell 7.4+.
3. Publish versioned immutable assets on the confirmed GitHub repository.
4. Replace every template placeholder and verify SHA256 against the hosted asset.
5. Save as a `.yaml` file and run `winget validate --manifest <directory>` using
   the current WinGet schema. Test local installation and removal in the VM.
6. Submit manifests to microsoft/winget-pkgs following its current contribution
   rules (split singleton manifests if required by submission tooling).

The draft GitHub release workflow does not submit WinGet manifests. Existing
PowerShell sessions must be restarted after upgrading or uninstalling. Verify
that uninstall removes installer-owned prior versions while preserving user files.
