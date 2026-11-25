# Codemap — CTRLKirk Optimizer

## Directory layout
```
CTRLKirkOptimizer/
├── CTRLKirk Gaming Optimizer.bat   # Entry point: menu, session logging, dispatches to PS1
├── OptimizerSafety.ps1             # Settings engine: catalog, journal, apply, restore, reports
├── OptimizerFeatures.ps1           # Workbench: dashboard/startup/cleanup/maintenance/power/tools/profiles
├── OptimizerPaths.ps1              # Readable output path helpers (dot times, ordinal dates, collisions)
├── OptimizerSafety.Tests.ps1       # Regression suite (all simulated/disposable)
├── AGENTS.md                       # Safety + verification rules (binding for agents)
├── README.md / README.txt          # Public overview / detailed manual
├── .gitignore                      # Excludes Logs/, SafetyRuns/, Backups/, profiles, downloaded exes, zips
├── MalwareScanner/
│   ├── Scanner.ps1                 # Active scanner (PS; BAT bypasses legacy batch scanner)
│   ├── SimpleMalwareScanner_v4.bat # Launcher for Scanner.ps1
│   ├── ignore_list.txt             # Literal substring ignore list (visible in report, not "safe")
│   ├── README_v4.txt
│   └── Reports/                    # Local scanner reports (gitignored)
├── Logs/                           # Gitignored runtime output
│   ├── Sessions/                   # One daily session log
│   ├── Safety Runs/<readable>/     # Developer.jsonl, Report.html, Snapshot.clixml, Snapshot.previous
│   └── Security Inventories/<readable>/
├── SafetyRuns/                     # LEGACY run dir — still searched by Restore, do not move/delete
├── Backups/                        # LEGACY .reg backups — NOT restorable, do not auto-import
├── .devin/profiles/                # Named preference .clixml files (gitignored, user-private)
└── Tools/                          # Downloaded third-party exes (gitignored)
```

## Dependency graph (runtime)
```
CTRLKirk Gaming Optimizer.bat
  └─ powershell.exe -File OptimizerSafety.ps1 -Mode <Mode> [...]
       └─ dot-sources OptimizerPaths.ps1 + OptimizerFeatures.ps1
  └─ powershell.exe -File OptimizerFeatures.ps1 via OptimizerSafety dispatch
       └─ dot-sources OptimizerPaths.ps1
MalwareScanner\SimpleMalwareScanner_v4.bat
  └─ powershell.exe -File Scanner.ps1
```

## OptimizerSafety.ps1 internals (line-referenced)
- `$script:Catalog` (~line 20): array of settings via `New-Setting` (Id, Label, Key,
  Name, Value, Tradeoff, Advanced flag, optional Kind='PowerScheme'). Two PowerScheme
  entries appended separately. ~16 registry + 2 power-plan entries.
- `Write-Event`/`Add-Result`: Developer.jsonl + report row sinks.
- `Get-ValueState`/`Set-ValueState`: registry value read/write incl. absent-exists,
  type, PowerScheme variant.
- `Save-Journal`: atomic Snapshot.clixml write via `.pending` + `.previous` replace.
- `Invoke-Setting`: per-setting apply — journal Pending→Applied; **per-setting errors
  caught by caller loop** (marked `Error`, run continues).
- `Assert-Journal`/`Restore-Journal`: validates snapshot, restores values, conflict detection.
- `Get-Plan`: allowlist validation, rejects >1 power scheme.
- `Write-Report`: HTML report (all values HtmlEncoded).
- `Invoke-SelfTests`: in-script unit tests over the disposable HKCU key.
- Main flow (~line 380+): mode dispatch → preference source → plan → preview →
  APPLY gate → admin check for HKLM → journal → per-setting apply → report.

## OptimizerFeatures.ps1 internals
- `Invoke-NativeLogged`: wraps external commands, captures exit codes to dev log.
- Preferences: `Save-Preferences`, `Get-PreferencePath`, `Get-SavedPreferences`,
  `Select-Preference`, `Get-PreferenceSource` (load/new/manual/cancel),
  `Save-NamedPreferences` (atomic .pending write, REPLACE confirmation upstream).
- `Get-PowerPlans`: enumerates existing schemes via powercfg.
- Workbench: `Show-Dashboard`, `Show-StartupTools`, `Get-CleanupCandidates`/
  `Test-CleanupCandidate`/`Remove-CleanupPlan`/`Show-CleanupTools`,
  `Show-MaintenanceTools`, `Show-RecommendedTools`, `Invoke-FeatureMode` dispatcher.
- Cleanup rule: files in user TEMP only, modified+access time >7 days, unchanged since
  preview, non-elevated only; writes `CleanupPreview.csv`; DELETE <exact count> required.

## OptimizerPaths.ps1
- English ordinal date names (`Oct 25th 2026`), `HH.MMPM` times (colons illegal in
  Windows filenames), same-minute collision suffixes `(2)`, atomic creation.
- Run dirs: `Logs\Safety Runs`, `Logs\Security Inventories`, `Logs\Sessions`.

## MalwareScanner/Scanner.ps1
- Object-based CIM/registry/COM queries (no fragile CSV parsing); sections: script
  hosts, scheduled tasks, Run/RunOnce, startup folders, service paths, WMI
  consumers/bindings, Winlogon/AppInit, connections, TEMP scripts, Downloads, Defender.
- `Get-IgnoreEntries`: `REM` alone or `REM `+space is a comment; `REMyTool.exe` is
  a valid entry.
- `Invoke-Check`: failures mark section incomplete — never reported as clean.
- Exit codes: 0 no check failures (≠ clean), 1 fatal, 2 incomplete.
- `-InventoryOnly` read-only; `-SelfTest` synthetic data; Defender scan requires
  explicit SCAN consent.

## Output data flow
```
Session start → Logs\Sessions\Optimizer Log <date>.log (appended daily)
Engine run   → Logs\Safety Runs\<date> Safety Run <time>\
               Developer.jsonl (every step/error), Report.html (user-facing),
               Snapshot.clixml (journal), Snapshot.previous (prior revision)
Scanner run  → Logs\Security Inventories\<date> Security Inventory <time>\
Cleanup      → CleanupPreview.csv inside run dir
Profiles     → .devin\profiles\<name>.clixml (allowlisted option IDs only)
```

## Config references
- `.gitignore`: excludes Logs/, SafetyRuns/, Backups/, MalwareScanner/Reports/,
  .devin/profiles/, Tools/*.exe, CTRKirk-Optimizer-*.zip, nul, *.tmp
- `ignore_list.txt`: substring ignore list for scanner (see Get-IgnoreEntries).
