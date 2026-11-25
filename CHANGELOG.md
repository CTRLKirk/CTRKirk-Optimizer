# Changelog — CTRLKirk Optimizer

## v1.0 — 2026-10-25 (public release)
- Initial public commit + release zip `CTRKirk-Optimizer-v1.0.zip`.
- Consent-first settings engine: preview → APPLY, per-value snapshot journal,
  verified restore, conflict detection.
- Named preference profiles (load/new/manual/cancel; REPLACE confirmation).
- Laptop Workbench: dashboard, startup tools, bounded temp cleanup,
  DISM/SFC maintenance, existing-plan power switching.
- RAM tools menu (manual, consented) + recommended-tool detection.
- Scanner rebuilt: object queries, read-only inventory, encoded HTML,
  explicit Defender QuickScan consent, persistence checks (WMI/RunOnce/
  Winlogon/AppInit).
- Readable dated output under `Logs/` with collision-safe names.
- Legacy batch routines inert/guarded.

## Post-v1.0 (unreleased, on main)
- README "personal project" wording added (commit 969bdc5).
- `.gitignore` covers release zips.

Note: per-setting error resilience (D6) and Widgets TaskbarDa/Dsh split (D7)
were committed BEFORE the v1.0 zip was built; verified by downloading the
release asset and checking `OptimizerSafety.ps1` contains both changes.
