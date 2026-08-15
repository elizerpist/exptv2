# LogBox terminal inset and diagnostics milestone — implementation plan

## Goal

Keep the physically approved dashboard interaction behavior while moving
bottom-navigation protection from viewport size into a terminal scroll inset,
then close only locally proven end-of-data and diagnostic anomalies.

## Execution order

1. Add RED tests for pure terminal extent, shell/viewport bounds, pre-drag
   virtual extent, end-of-data demand, and diagnostic scopes.
2. Restore shell `extendBody` ownership, preserve one viewport, and add a
   terminal sliver based on its real incoming constraint and `MediaQuery`
   obstruction.
3. Make a known committed virtual extent authoritative in `railPreview` too;
   only the painter domain changes on first gesture.
4. Reject impossible reverse intent before it becomes deferred work; coalesce
   identical deferred diagnostics.
5. Correct diagnostic names/scopes without changing framework physics.
6. Audit retention/empty warmup; include only a clearly local safe guard.
7. Verify, update `MILESTONE_COMMITS.md`, commit, push, monitor the exact
   normal human APK, download it, and record its SHA-256.

## Review checkpoints

- After each RED test: confirm its failure demonstrates the named ownership
  defect rather than resource readiness.
- Before commit: re-read the acceptance checklist; leave any non-local cache
  redesign item explicitly not done rather than broadening scope.
- Before final report: verify the exact pushed SHA and APK artifact.
