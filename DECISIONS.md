# Decision log — CTRLKirk Optimizer

Format: what / why / alternatives / consequences / still active?

## D1 — BAT is a launcher only; all logic in PowerShell
**What:** The 93 KB .bat retains the old routines as inert text but every active
menu route dispatches to `OptimizerSafety.ps1` / `OptimizerFeatures.ps1`.
**Why:** Batch cannot do atomic snapshots, structured logging, or safe restore.
**Alternatives:** pure batch (rejected — unsafe), compiled exe (rejected —
distribution friction).
**Consequences:** PS1 files must stay beside the BAT; execution policy not bypassed.
**Status:** active.

## D2 — Snapshot journal, not .reg backups, for undo
**What:** `Snapshot.clixml` records per-value existence/type/data before each
write; restore is value-by-value, conflict-aware, verified by read-back.
**Why:** `.reg` import can't remove values the run created and can't distinguish
"we changed it" from "user changed it."
**Alternatives:** System Restore only (too heavy), blanket .reg import (unsafe —
could delete pre-existing policies).
**Consequences:** restore covers only settings changed through the engine; cleanup,
repairs, installs are explicitly NOT restorable.
**Status:** active. Old `Backups\*.reg` remain unrestorable legacy.

## D3 — Everything opt-in; defaults = keep unchanged
**What:** Every question defaults to N/keep; only `Y` selects a change. Preview is
mandatory; APPLY/RESTORE typed consent required.
**Why:** User explicitly demanded feature tradeoffs (animations, Xbox, icons) be
user choices, not silent losses.
**Status:** active.

## D4 — AUTO mode is preview-only
**What:** AUTO loads a saved preference and previews it; never applies unattended.
**Why:** No silent system mutation, ever.
**Status:** active.

## D5 — Removed placebo/harmful tweaks entirely
**What:** No Prefetch deletion, event-log clearing, TCP Chimmon chimney/autotuning
tweaks, winsock/ip reset in the normal flow, `cleanmgr /sagerun`, wmic, forced app
closing, Defender exclusions, VBS/Memory Integrity off, blanket service disabling.
**Why:** Deprecated keys, security reductions, or zero/negative real effect.
**Consequences:** repairs moved to Workbench → Maintenance as separately confirmed
actions; DNS preserved by default.
**Status:** active. Do NOT re-enable legacy paths.

## D6 — Per-setting errors don't abort the run
**What:** A failed setting is journaled `Error` and the plan continues.
**Why:** One protected key (see KNOWN_ISSUES Dsh) previously killed the whole plan
mid-apply.
**Alternatives:** abort-on-first-error (was the original — too fragile).
**Consequences:** snapshot-save failures still abort (integrity boundary kept).
**Status:** active since Oct 25, 2026.

## D7 — Widgets: per-user TaskbarDa primary, HKLM Dsh as labeled fallback
**What:** `TaskbarDa=0` (HKCU Explorer\Advanced) is the recommended Widgets-off
option; the `HKLM\...\Dsh\AllowNewsAndInterests` policy option remains but is
labeled fallback because the key is protected on the author's machine.
**Why:** Dsh write was denied even elevated; TaskbarDa needs no admin and matches
the OS's own "hide Widgets button" toggle.
**Status:** active.

## D8 — Readable organized output names
**What:** `Oct 25th 2026 Safety Run 11.20am` style names under `Logs\...`; dot
instead of colon (illegal in Windows filenames); `(2)` collision suffixes.
**Why:** User explicitly rejected GUID/hex names as confusing.
**Status:** active.

## D9 — Named profiles store allowlisted IDs only
**What:** `.devin\profiles\<name>.clixml` contains option IDs; never command
strings. Load still requires fresh preview + APPLY.
**Why:** Safety boundary — a profile must never be able to smuggle arbitrary actions.
**Status:** active.

## D10 — Scanner is inventory-first, never a verdict
**What:** Read-only checks; ignore-list hits stay visible and labeled; incomplete
sections reported incomplete; Defender QuickScan behind explicit SCAN consent.
**Why:** Heuristics/PowerShell/AppData are not proof of malware; auto-running AV
without consent is unacceptable.
**Status:** active.

## D11 — No license on the public repo
**What:** Austin chose "no license" for the GitHub release.
**Consequences:** all-rights-reserved; others can view/report issues but not
legally redistribute. May revisit if he wants forks.
**Status:** active as of Oct 25, 2026.

## D12 — RAM cleanup is manual troubleshooting, not auto-optimization
**What:** Standby purge / working-set trim / priority changes only via menu [4]
with explicit consent; memory compression read-only.
**Why:** Clearing cached RAM is not a proven FPS gain and can cause reload stalls.
**Status:** active.
