# Constraints — CTRLKirk Optimizer

Binding rules. These come from AGENTS.md (authoritative) and Austin's explicit
instructions. Never violate for a "simple" task.

## Hard safety rules
1. Every active setting defaults to UNCHANGED. Preview mandatory; `APPLY` /
   `RESTORE` typed consent required. `AUTO` is preview-only — never unattended apply.
2. Snapshot original existence/type/value before EVERY write; if logging or
   snapshot creation fails, STOP the run.
3. Restore only journaled values; preserve conflicts and unrelated values; verify
   by read-back. Never blanket-delete policy trees or import old `.reg` backups
   automatically (they lack exact-undo metadata).
4. Never re-enable the legacy guarded batch apply/undo/developer routines
   (forced cleanup, security weakening, network resets, old registry imports).
5. Security and Explorer layout stay unchanged unless explicitly opted in —
   icons, thumbnails, font smoothing, Quick Access pinning, Game Bar social
   features must not be silently disabled.
6. No automatic: app closing, file cleanup, security weakening, memory purge,
   power changes, reboot, third-party installs, or Defender exclusions.
7. Cleanup is ONLY unchanged, nonlinked files older than 7 days in the current
   user's TEMP dir, NON-elevated, exact-count `DELETE <n>` consent, and is
   permanently irreversible. No personal/system/browser-cache/event-log paths.
8. Profiles contain ONLY allowlisted setting IDs — never command strings, never
   unattended destructive actions.
9. Native command exit codes/failures must be logged (Invoke-NativeLogged).
   Command completion is not proof of repair or performance gain.
10. Never claim a clean system or a performance improvement that wasn't measured.
    Instant CPU/RAM readings are not benchmarks.

## Compatibility constraints
- Windows PowerShell 5.1 compatible (no PS7-only syntax).
- `wmic` is deprecated/removed on modern Windows — use CIM/PowerShell objects.
- Windows filenames cannot contain `:` — output names use dots.
- BAT metacharacters (parentheses, etc.) must be escaped in echo/menu text.
- Keep BAT + OptimizerSafety.ps1 + OptimizerFeatures.ps1 + OptimizerPaths.ps1 +
  MalwareScanner/ together in one folder.
- User-temp cleanup must run NON-elevated; HKLM settings need admin.

## Repo / release constraints
- No AI/Devin attribution in commits or PRs.
- Never commit secrets, user logs, saved profiles, or downloaded third-party exes
  (gitignored). RAMMap is Sysinternals — not redistributable.
- Push only with explicit authorization; no force-push/history rewrite.
- No license file currently exists (Austin's choice) — do not add one silently.

## Prohibited claims/actions
- Do not promise FPS gains; do not call instant readings "before/after" proof.
- Do not label scanner heuristics/ignore-matches as safe or malware verdicts.
- Do not tell users to run mutation-heavy paths as a test fixture — routine
  verification must not touch the real system.
