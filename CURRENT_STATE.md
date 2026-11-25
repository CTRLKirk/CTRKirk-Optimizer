# Current state — CTRLKirk Optimizer

Snapshot: 2026-11-22. Source of truth is code + git, not this file.

## Works (verified)
- Preview flow end-to-end: every option defaults to keep; preview never writes.
- Apply + restore round-trip verified live (Edge startup boost).
- Per-setting error resilience: denied HKLM key marks `Error`, plan continues.
- Named preferences: create/load/manual/cancel, overwrite protection.
- Restore discovers both `Logs\Safety Runs` and legacy `SafetyRuns`.
- Regression suite passes: `powershell.exe -NoProfile -File .\OptimizerSafety.Tests.ps1`
- Scanner self-test passes: `powershell.exe -NoProfile -File .\MalwareScanner\Scanner.ps1 -SelfTest`
- Public repo + v1.0 release published.

## Incomplete / not done
- No FPS/performance benchmarking anywhere.
- v1.0 zip predates the final README wording (cosmetic).
- No signed binary/installer — BAT+PS1 distribution only.
- HKLM Dsh key protection on author's machine unresolved (mitigated, not fixed).

## Broken
- Nothing known open. Legacy batch apply/undo paths are intentionally inert.

## Next (candidate)
- Collect external review feedback.
- Optionally rebuild v1.0 zip if README freshness matters, or cut v1.0.1.
- Do NOT expand the tweak catalog without the same snapshot/consent treatment.
