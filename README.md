# CTRKirk Optimizer

A Windows laptop optimization toolkit built for weaker hardware — with an emphasis on **honesty, consent, and reversibility** over "apply 200 tweaks and pray."

Most optimizer scripts silently disable things you might actually use (Xbox/Game Bar, notifications, animations, thumbnails) and offer no real undo. This one asks first, previews everything, snapshots every value it changes, and restores only what it touched.

## What it does

**Settings optimizer (Standard / Advanced)**
- Every option defaults to **keep unchanged** — only `Y` selects a change
- Full preview shown before anything is written; requires typing `APPLY`
- Every tradeoff is stated plainly (e.g., "disabling Xbox services breaks friends/party chat — choose N if you use them")
- Named preference profiles: save your choices once, reload them months later

**True restoration**
- Original value existence, type, and data snapshotted *before* every write
- Restores individual values only — never deletes whole policy trees
- Values that didn't exist before are removed individually; newer conflicting changes are preserved and marked `Conflict`
- Verified by read-back after every write and every restore

**Laptop Workbench**
- Dashboard: CPU/RAM/process/disk readings and saved measurements
- Startup app inventory (opens Windows' own Startup settings — nothing force-killed)
- Old temp-file cleanup with a mandatory preview and exact-count consent
- Maintenance: DISM/SFC health checks and repair as *separately confirmed* actions
- Power plan switching with snapshot/restore of the original plan

**RAM tools** — manual, honest troubleshooting tools (standby list purge, working-set trim, process priority). The tool tells you upfront: clearing cached RAM is not an FPS boost and can make apps reload data.

**Security inventory** — read-only scan of persistence locations (Run/RunOnce, WMI subscriptions, scheduled tasks, Winlogon, AppInit, service paths, startup folders, network connections). Optional Defender QuickScan requires explicit consent. Heuristic findings are labeled as findings, never "malware."

**Recommended tools** — detects Process Lasso, Quick CPU, HWiNFO, RAMMap; inspect or install/launch with explicit confirmation. No silent tuning.

## What it deliberately does NOT do

- No forced reboots, forced app closing, or unattended changes (`AUTO` is preview-only)
- No security weakening (no Defender exclusions, VBS/Memory Integrity off, or policy tree deletion)
- No placebo tweaks: no Prefetch deletion, no event-log clearing, no TCP Chimney, no `wmic` (uses CIM)
- No promised FPS gains — reports distinguish "command succeeded" from "actually faster"

## Usage

```
Open "CTRLKirk Gaming Optimizer.bat" normally.
Right-click -> Run as administrator only when a machine-wide setting requires it.
(User-temp cleanup must run NON-elevated.)
```

Keep `OptimizerSafety.ps1`, `OptimizerFeatures.ps1`, `OptimizerPaths.ps1`, and the `MalwareScanner/` folder beside the BAT.

Requirements: Windows 10/11, Windows PowerShell 5.1+.

## Output

```
Logs/Sessions/Optimizer Log Oct 25th 2026.log
Logs/Safety Runs/Oct 25th 2026 Safety Run 11.20am/
    Developer.jsonl   - timestamped technical log
    Report.html       - readable results and tradeoffs
    Snapshot.clixml   - original values for restoration
Logs/Security Inventories/<readable run>/
```

## Safety model

- Snapshot before write; verified read-back; conflict-aware restore
- Profiles contain allowlisted option IDs only — no commands
- Per-setting errors are logged and don't abort the rest of the plan
- Cleanup is permanent by design and clearly warned; it only touches unchanged old files in your own TEMP folder, non-elevated

## Verification

```powershell
powershell.exe -NoProfile -File .\OptimizerSafety.Tests.ps1
powershell.exe -NoProfile -File .\MalwareScanner\Scanner.ps1 -SelfTest
```

Tests use simulated values and disposable registry keys/files — no real system mutation, installs, or scans.

## Feedback welcome

This started as a personal project — I built it for my own weak laptop because I needed it, and it's what I actually run on my own rig. It was tailored to me first; I decided to release it to get some opinions on it.

If something breaks, the `Developer.jsonl` in the affected run folder will show exactly where — please include it in any issue.
