# Known issues / limitations — CTRLKirk Optimizer

## Open

### KI-1: HKLM `...\Policies\Microsoft\Dsh` write denied even when elevated
- **Seen:** Oct 25, 2026 (run `Oct 25th 2026 Safety Run 11.59am` / `12.35pm`).
- **Symptom:** `SetValue` throws UnauthorizedAccessException on
  `HKLM:\SOFTWARE\Policies\Microsoft\Dsh\AllowNewsAndInterests`.
- **Facts:** key exists; ACL grants Administrators FullControl; the run WAS
  elevated (Edge HKLM policies applied fine). Something on the machine protects
  that specific policy key — cause not definitively identified.
- **Mitigation:** per-user `TaskbarDa` option added as primary; Dsh kept as labeled
  fallback; per-setting error handling (D6) means the plan continues.
- **Status:** open — engine handles it gracefully; root cause unknown.

### KI-2: No performance benchmarking
- Reports show instant CPU/RAM/process readings only. No FPS or sustained-load
  measurement exists. Tool intentionally avoids claiming gains.
- **Status:** accepted limitation by design.

### KI-3: Legacy artifacts unrestorable
- `Backups\*.reg` and old `SafetyRuns\` snapshots predate the journal format;
  Restore discovers them read-only for inspection but they cannot guarantee
  exact undo.
- **Status:** documented; by design.

### KI-4: Delivery mechanism is BAT+PowerShell
- Reviewers may suggest a packaged exe/module. Known tradeoff for distribution
  simplicity. **Status:** accepted for v1.0.

### KI-5: `AllowTelemetry=0` clamps on Home/Pro
- Fully effective only on Enterprise/Education SKUs.
- **Status:** documented in code comments; harmless.

## Resolved

### KR-1: Menu option [6] closed instantly (CMD parse error)
- Cause: unescaped `)` in the winget-missing message broke the `if` block.
- Fixed Oct 2026; session logging moved earlier so launcher exits are captured.

### KR-2: Aggressive confirmation screen died on unescaped parens
- Choice-summary lines contained `(your choice)` etc. inside `if (...)` blocks.
- Fixed by escaping; verified with all-keep/all-disable simulations.

### KR-3: RAM menu output was jargon-heavy hex codes
- Replaced with plain-English results; technical detail moved to logs.

### KR-4: Per-setting failure aborted whole apply plan
- Original design threw on first error → partial apply, stuck `Pending` entry.
- Fixed Oct 25, 2026 (D6): per-setting catch → `Error` status, continue.

### KR-5: Profile empty-selection didn't clear choices
- Fixed; empty selection now saves a keep-everything plan.

### KR-6: Scanner issues (historical)
- Fragile localized CSV parsing → object-based CIM queries.
- `findstr /b "REM"` treated `REMyTool.exe` as comment → boundary fix.
- `-ScanType 2` was a FULL scan mislabeled quick → corrected to QuickScan.
- Added WMI subscriptions/RunOnce/Winlogon/AppInit persistence checks.
- HTML escaping added; incomplete checks never reported clean.

### KR-7: GUID-heavy filenames
- Replaced with readable ordinal names under organized Logs subfolders.

## Historical context (pre-rewrite, for reviewers)
The original script applied a broad tweak bundle (service disables, DNS changes,
network resets, Prefetch deletion, event-log clearing) with `.reg` backup "undo"
that could not restore created values. The active engine replaced all of that;
legacy code remains in the BAT as inert text only.
