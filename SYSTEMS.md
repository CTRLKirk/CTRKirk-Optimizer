# Systems — CTRLKirk Optimizer

Each subsystem: responsibility, key files, interactions, risk notes.

## 1. Launcher (CTRLKirk Gaming Optimizer.bat)
- **Responsibility:** self-elevation prompt, session log init, main menu 0–9,
  routing to PowerShell modes, legacy inert code.
- **Interactions:** calls `OptimizerSafety.ps1 -Mode <X>`; features dispatched via
  OptimizerSafety → OptimizerFeatures. RAM helper script generated to `%TEMP%\CKOptimizer`.
- **Risk:** ~93 KB single file; legacy sections are text-only (guarded). Menu
  parsing bugs historically caused window-close (fixed paren-escaping issues).

## 2. Settings engine (OptimizerSafety.ps1)
- **Responsibility:** the ONLY path that writes persistent system settings.
  Catalog → plan → preview → APPLY → journal → per-setting apply → report.
- **Key mechanics:** `Snapshot.clixml` journal (pending→applied/error/restored/
  conflict); `Developer.jsonl` events; `Report.html`; restore via menu 5.
- **Interactions:** dot-sources Paths + Features; Get-Metrics for before/after.
- **Risk:** highest-impact subsystem — every write must be journaled first.
  Per-setting try/catch (D6) means a partial plan is possible; journal keeps it
  recoverable.

## 3. Workbench features (OptimizerFeatures.ps1)
- **Responsibility:** dashboard, startup inventory/close requests, temp cleanup,
  DISM/SFC maintenance, power-plan switching, recommended tools, profiles.
- **Interactions:** Invoke-FeatureMode dispatch from engine; native commands via
  Invoke-NativeLogged.
- **Risk:** cleanup is irreversible (bounded to user TEMP, non-elevated); repairs
  change OS components and are NOT snapshot-reversible; power switch snapshots
  only the active scheme GUID.

## 4. Path/naming helper (OptimizerPaths.ps1)
- **Responsibility:** readable date/time names, collision-safe unique dirs.
- **Interactions:** used by engine and scanner output.
- **Risk:** low; pure path generation. Must stay dependency-free.

## 5. Security scanner (MalwareScanner/Scanner.ps1)
- **Responsibility:** read-only persistence/network inventory + optional Defender
  QuickScan; HTML + JSONL reports.
- **Interactions:** independent of optimizer engine; reads same Logs tree for
  Security Inventories; uses ignore_list.txt.
- **Risk:** must never execute discovered commands; incomplete sections must
  never render as "clean"; Defender scan has real remediation side-effects.

## 6. Regression suite (OptimizerSafety.Tests.ps1)
- **Responsibility:** end-to-end safety verification — disposable HKCU key,
  simulated values/plans, preview flows, real CMD menu navigation, profile flows,
  legacy snapshot discovery, scanner synthetic tests.
- **Constraint:** must NEVER mutate the real system (no real applies, installs,
  repairs, scans, RAM purge).

## 7. RAM tools (BAT menu 4 → generated ck_ram helper)
- **Responsibility:** manual standby purge, working-set trim, process priority,
  Explorer restart, startup list, memory-compression status.
- **Risk:** memory purge is not undoable and can cause reload stalls; high
  priority can starve other apps.
