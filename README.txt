================================================================================
CTRLKirk Optimizer - Laptop Toolkit
================================================================================

START
Open "CTRLKirk Gaming Optimizer.bat" normally. Right-click -> Run as administrator
only when a selected machine-wide setting or repair requires it. User-temp
cleanup must run NON-elevated. Keep OptimizerSafety.ps1, OptimizerFeatures.ps1,
OptimizerPaths.ps1 and the MalwareScanner folder beside the BAT. Execution policy
is not bypassed.

MAIN MENU
[1] Standard: choose individual Windows settings; preview; type APPLY to apply.
[2] Advanced: adds background-app restrictions and individual Xbox service choices.
[3] AUTO: preview saved choices only. Never applies anything unattended.
[4] RAM / Memory Tools: manual troubleshooting tools, not automatic optimizations.
[5] Restore: inspect a snapshot and type RESTORE to restore recorded values.
[6] Recommended Tools: detect, inspect versions, explicitly install or launch tools.
[7] Laptop Workbench: dashboard, startup/apps, cleanup, maintenance, power, profiles.
[8] Security Inventory: read-only investigation, with optional Defender quick scan.
[9] Developer: read-only model/GPU/driver information and safety policy.
[0] Exit.

PREFERENCES AND QoL
All questions default to KEEP UNCHANGED; only Y selects a change. No forced
animations-off, app closing, registry bundle, power setting or security reduction.
Choose N for Xbox services and background-app restrictions if you use Xbox friends.
Game capture choices are separate; keep both unchanged if you want recording.
Explorer layouts, icons/thumbnails, font smoothing, Activity History and pinning
are not modified. Changes and their tradeoffs appear in the preview/report.

Standard/Advanced starts with: [1] Load a saved preference, [2] Create a new named
preference, [3] Answer manually for this run (default), or [0] Cancel. Loading skips
the questionnaire but still shows the plan and requires APPLY. Nothing is applied
just because a preference was loaded. AUTO lets you choose a preference and only
previews it. No saved preferences? Use Create or Workbench -> Saved preferences.

SAVE at the preview or in Workbench creates a named preference WITHOUT applying
settings. Example names: Gaming Laptop, Everyday, Xbox With Friends. Profiles
live in .devin\profiles\<name>.clixml. Reusing a name requires REPLACE; otherwise
the existing file is untouched. Old default.clixml preferences still appear as
default in the selection list. Selecting no changes saves a keep-everything plan;
it does not reset Windows to defaults. Skipped settings mean preserve their
current values, not forcibly enable/disable them. Profile choices cover supported
persistent settings, not automatic cleanup, repairs, app closing or installs.
Power choices can also be saved after an explicit power-plan apply. Only one power
plan can be selected per run. Profiles contain allowlisted option IDs, not scripts.

WORKBENCH [7]
  [1] Dashboard: CPU/load, memory, processes, disk space, active power scheme and
      top memory consumers. Measurements.clixml is saved for comparison. Use the
      SAME workload/power conditions; idle readings are not an FPS benchmark.
      Reliable temperatures are not available through Windows on every laptop;
      HWiNFO sensors can reveal heat/throttling while gaming.
  [2] Startup/apps: inventories startup entries, opens Windows Startup settings,
      or requests graceful closing of ONE selected app. Save work first. Nothing
      is force-killed. App save prompts can remain open; a close request is not
      proof the app exited. Changes made in Windows settings are external to
      optimizer snapshots. Undocumented startup flags are not rewritten.
  [3] Cleanup: previews files in your current TEMP folder whose modified AND
      access timestamps are older than seven days. Review CleanupPreview.csv.
      Type DELETE <count> to permanently delete ONLY that previewed list.
      There is NO recycle/undo for cleanup. Old temp files may still matter.
      Changed, locked or linked files are skipped; no directories are removed.
      Personal/system/project/network roots and reparse roots are blocked.
      Requires a non-admin run to avoid privileged file deletion.
      No blanket browser/shader-cache, Prefetch, event-log, crash-dump, Windows
      Update-cache or Recycle Bin purge. Windows Storage settings remain the
      supported option for broader cleanup.
  [4] Maintenance: separately confirmed system checks/repair and networking tools.
      CHECK runs DISM CheckHealth and SFC verifyonly; it can take time and writes
      Windows diagnostic logs. REPAIR runs DISM RestoreHealth then SFC scannow,
      requires admin, may use Windows Update/network and changes OS components.
      Repairs cannot be undone by optimizer snapshots. Commands and exit codes
      are logged; command completion is not proof of a healthy system.
      Network inspection is read-only. FLUSH clears only temporary DNS cache.
      No DNS server changes, Winsock/IP reset or TCP tweak bundle.
  [5] Power: list EXISTING OEM plans and optionally switch to existing Balanced
      or High Performance with preview/APPLY. The original active plan GUID is
      snapshotted and restored through menu 5. No plans are created/duplicated;
      sleep, hibernation, USB, CPU/core-parking and battery parameters are not
      edited. Modern Standby laptops may expose only Balanced. High Performance
      can increase heat/battery drain or worsen throttling; it is NOT assumed best.
  [6] Saved preferences: choose and save the feature choices without applying them.

RAM TOOLS [4]
Cached/standby memory is reusable already. Clearing it or trimming working sets
can increase disk reads and temporarily slow apps. A higher free-RAM number is
not a performance gain by itself. Manual cleanup asks for consent; no RAM tool
runs automatically in Standard/Advanced. Unsuccessful operations are described
plainly and codes are logged. A memory purge is not an undoable setting.
High priority can harm other apps; restarting the selected app resets it.
Explorer restart asks first because folder windows/file operations can be affected.
Memory compression is read-only; there is no blanket recommendation to disable it.

TOOLS [6]
Process Lasso, Quick CPU, HWiNFO and RAMMap are optional external tools.
Detection checks installed-app metadata/known paths and may miss portable copies.
DETAILS shows winget versions. INSTALL requires an exact version and a second
confirmation; prefer releases at least seven days old. winget/vendor agreements
may need acceptance; they are not silently accepted by the toolkit. Installs are
not reverted by registry snapshots; use the vendor uninstaller. No tuning preset
is applied automatically. LAUNCH checks a known executable's signature and shows
the signer before requiring OPEN; unknown install locations should be opened
through Start. Quick CPU settings can increase heat and battery drain. Process
Lasso cannot guarantee a faster game. RAMMap is diagnostic, not a cure for low RAM.

RESTORATION [5]
Before a persistent write, the original existence/type/value (or active power
scheme GUID) is saved durably. Writes and restoration are verified by read-back.
Only recorded values are restored; whole policy trees are NEVER deleted.
An originally absent value is removed individually. Unrelated values remain.
Newer conflicting values are left untouched and marked Conflict. An empty
registry container may remain. Snapshots from another account/computer, unknown
action IDs or invalid data are blocked. Pending entries help recover interrupted
writes. No automatic reboot. Restore is NOT a backup of personal files or a way
to undo repairs, cleanup, app closing, external installs or vendor tuning.
Old Backups\*.reg files lack exact-undo metadata and are not imported automatically.
Ask for a targeted review if an OLD version already changed your system.

REPORTS / DEBUGGING
All NEW output is grouped under Logs instead of scattered across the project:
  Logs\Sessions\Optimizer Log Oct 25th 2026.log
  Logs\Safety Runs\Oct 25th 2026 Safety Run 11.20am\
  Logs\Security Inventories\Oct 25th 2026 Security Inventory 11.25am\
Launcher sessions append to ONE log per day, with a timestamp at each start.
Run folders include the year so next year's output cannot be mistaken for this
one. A same-minute collision adds (2), (3), etc.; existing output is never replaced.
Windows does not allow ':' in names, so times use a dot. Each safety run contains:
  Developer.jsonl    - timestamped steps, commands, errors/results
  Report.html        - readable choices/results and measurements
  Snapshot.clixml    - original states for persistent apply/restore
  Snapshot.previous  - preceding journal revision for investigation
Cleanup also writes CleanupPreview.csv; dashboard writes Measurements.clixml.
OLDER logs/folders are deliberately not moved or deleted. Restore searches both
Logs\Safety Runs and the previous SafetyRuns folder, sorted by creation time
rather than alphabetically by the month name. Your existing links still work.
No snapshot is expected for ordinary previews or nonpersistent tools. Abrupt
termination can prevent a final report update; last events/pending journal help.
A report marked Finished is not a guarantee every optional step succeeded: inspect
Skipped, Conflict and Error results. No synthetic performance/savings claims.

SECURITY INVENTORY [8] / MalwareScanner\SimpleMalwareScanner_v4.bat
Inventory is read-only by default: script hosts, object-based scheduled tasks,
Run/RunOnce keys (including 32-bit machine entries), startup folders, service
paths, WMI consumers/bindings, Winlogon/AppInit, established connections, top-level
TEMP scripts, recent Downloads and Defender status. Objects are never executed.
All HTML is encoded. Missing/denied sections are marked incomplete, never clean.
Ignore-list entries remain literal substring labels for compatibility; matched
items stay visible and are NOT certified safe. Running PowerShell, using AppData
or matching a script heuristic is NOT proof of malware. Do not delete entries
just because they appear here. SCAN explicitly requests Defender QuickScan and
can quarantine/remove threats; it is not read-only and may take time. Check
Windows Security / Protection history for findings. No third-party scanner is
downloaded or launched automatically. OPEN optionally displays the local report.
Report.html and Developer.jsonl are in Logs\Security Inventories\<readable run>. These local reports
may include private paths/task arguments; inspect before sharing. Scanner exit 2
means incomplete checks, exit 1 a fatal error, exit 0 no check failures (NOT clean).

VERIFICATION
  powershell.exe -NoProfile -File .\OptimizerSafety.Tests.ps1
  powershell.exe -NoProfile -File .\MalwareScanner\Scanner.ps1 -SelfTest
Tests use simulated persistent changes, a disposable HKCU key and disposable
cleanup files. They exercise previews, profiles, conflicts/recovery, failure
handling, CMD navigation, RAM-helper parsing and scanner HTML/ignore handling.
No real optimization, power switch, repair, install, antivirus scan or RAM purge
runs in regression tests. Tests and read-only inventories do not establish a
performance improvement or guarantee a clean machine. The old batch bundles are
retained as inactive text; guarded menu routes cannot execute them.
