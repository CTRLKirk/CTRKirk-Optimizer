# Project verification and safety

- Windows batch launcher: `CTRLKirk Gaming Optimizer.bat`.
- Active apply/restore engine: `OptimizerSafety.ps1`, compatible with Windows PowerShell 5.1. `OptimizerFeatures.ps1` supplies the workbench, cleanup, native-command logging and tool integration. Keep both files plus the shared `OptimizerPaths.ps1` alongside the BAT.
- Run regression coverage with `powershell.exe -NoProfile -File .\OptimizerSafety.Tests.ps1`.
- Tests use simulated values/power plans, a disposable HKCU registry key, disposable cleanup files/profiles, read-only real-setting previews, actual CMD menu navigation and generated RAM-helper parsing. They do not install tools, switch real power plans, repair Windows, run antivirus or execute RAM cleanup. Test reports are retained in Logs/Safety Runs and temporary test directories.
- Legacy apply/undo/developer sections remain in the BAT but are guarded and inactive. Do not re-enable blanket policy deletion, forced cleanup, security changes or old registry imports.
- Every active setting defaults to unchanged. Require a preview and explicit APPLY/RESTORE. AUTO is preview-only.
- Snapshot original value existence, type and data before each write; stop if logging/snapshot creation fails. Restore individual values only, preserve conflicts and unrelated values, and verify by read-back.
- Real optimization and external-installer execution are not part of routine verification. Never use the owner's current system as a performance/mutation test fixture.
- Active scanner: `MalwareScanner/Scanner.ps1`; the old BAT inventory is bypassed. `-InventoryOnly` is read-only; `-SelfTest` uses synthetic data. Defender requires explicit SCAN consent because remediation may occur. All report values must be HTML-encoded; never execute discovered command strings. Do not claim a clean system or treat ignore/heuristic labels as verdicts.
- Cleanup requires a current preview and exact DELETE count consent, only deletes unchanged nonlinked old files from user TEMP while non-elevated, and is not reversible. Never include personal directories, browser/shader caches, event logs or broad privileged cleanup.
- Save named project preferences under `.devin/profiles/`. Standard/Advanced offers load/new/manual/cancel; replacing a name requires REPLACE. Profiles contain only allowlisted setting IDs, with omitted IDs meaning preserve current values. Never add command strings or unattended destructive actions.
- `OptimizerPaths.ps1` centralizes English ordinal date names and atomic same-minute collision handling. New output belongs in `Logs/Sessions`, `Logs/Safety Runs`, and `Logs/Security Inventories`; launcher logs append daily. Restore must keep discovering old `SafetyRuns` snapshots, sorted by creation time, without moving/deleting historical files.
- Native process exit codes and failures are logged through Invoke-NativeLogged. Command completion is not proof of successful repair or a performance gain.
