# Project context — CTRLKirk Optimizer

## Purpose
A Windows 10/11 laptop optimization toolkit for weak hardware, built because the
author personally needed it on his own rig. Published publicly at
https://github.com/CTRLKirk/CTRKirk-Optimizer (no license — all rights reserved).

Core philosophy: **honesty, consent, and reversibility over tweak count.** Most
"optimizer" scripts silently disable features users rely on (Xbox/Game Bar,
notifications, thumbnails) and offer no real undo. This tool asks first, previews
everything, snapshots every value it changes, and restores only what it touched.

## Current status (verified Nov 22, 2026)
- Public repo live; tag `v1.0` with release zip `CTRKirk-Optimizer-v1.0.zip`.
- All regression tests passing (`OptimizerSafety.Tests.ps1`, `Scanner.ps1 -SelfTest`).
- One real end-to-end apply/restore cycle verified on the author's machine
  (Edge startup boost: preview → apply → restore → absent again).
- No performance/FPS gain has been benchmarked or promised.

## Architecture (high level)
- `CTRLKirk Gaming Optimizer.bat` (~93 KB) — launcher + menu only. All legacy
  apply/undo/developer batch routines remain as text but are **guarded/inactive**;
  active routes dispatch to `OptimizerSafety.ps1` / `OptimizerFeatures.ps1`.
- `OptimizerSafety.ps1` — the settings engine: catalog of allowlisted options,
  snapshot-before-write journal (`Snapshot.clixml`), verified read-back, conflict-aware
  restore, named preference load/save, readable report generation.
- `OptimizerFeatures.ps1` — workbench: dashboard, startup tools, temp cleanup,
  maintenance (DISM/SFC), power-plan switch, recommended-tool detection/launch,
  profile management.
- `OptimizerPaths.ps1` — readable, collision-safe output path generation.
- `MalwareScanner/Scanner.ps1` — read-only persistence inventory + optional
  Defender QuickScan (explicit consent); HTML report is fully encoded.
- `OptimizerSafety.Tests.ps1` — regression suite (disposable keys/files only).

## Requirements
Windows 10/11, Windows PowerShell 5.1+. BAT + all .ps1 files + `MalwareScanner/`
must stay together in one folder. Run BAT normally; admin only for machine-wide
settings/repairs. User-temp cleanup must run NON-elevated.

## Docs that already exist (do not duplicate)
- `README.md` — GitHub-facing overview (public).
- `README.txt` — detailed user manual (shipped in release zip).
- `AGENTS.md` — project safety/verification rules (authoritative for agents).
- `MalwareScanner/README_v4.txt` — scanner docs.
- These knowledge files — internal durable project memory.
