# Execution plan — Summary ownership / Avatar Phase-A authority / latency

Base: `9e8a7b3a0a1f17bbd9433927e1d8a0afcd8413e9`.
Branch: `fix/summary-repeat-swipe-avatar-phase-a-frame-latency-codex-20260906`.

This executes inline because Summary ownership, Avatar publication and the
shared LogBox cache are tightly coupled to stable controller identity.  Splitting
them would introduce conflicting edits at the authority boundary.

1. **DONE — Freeze and audit evidence.**  Freeze the current three Drive
   exports in read-only local files, hash them, validate their common session
   and build, deduplicate each 999-event overlap, record gaps, and preserve the
   former same-SHA session as historical only.
2. **DONE — Map shared ownership.**  Verify the graph provenance and CURRENT
   source for the segmented geometry/background detector, upper coordinator,
   carousel preemption, private committed prearm, prepared-scene cache lookup,
   Avatar live-root activation and Phase-A renderer.
3. **DONE — Reproduce and test.**  Read the direct Summary/Avatar/cache/
   controller tests, add bounded diagnostic seams, and record clean-9e red
   probes. The Summary probe proves the glyph-sized interaction gap; the
   Avatar probe proves private prearm cannot satisfy painter readiness.
4. **DONE — Repair Summary boundary.**  Introduce geometry-derived disjoint
   interaction cells while preserving visual glyph placement and genuine
   background collapse. Add repeat-swipe, separator, mirrored and background
   regressions.
5. **DONE — Repair Avatar authority.**  Bind/validate the exact selected
   Phase-A payload through the existing prepared-scene cache before nonempty
   visible publication. Defer an unready candidate rather than publish an
   unreadable target. Phase B remains optional.
6. **PARTIAL — Measure before optimizing.**  Mind gets bounded pointer-to-
   preview instrumentation with existing paint-flow correlation; its passive
   probe is compile-time diagnostic opt-in. Avatar
   FrameTiming must be remeasured on the next profile APK before any physics or
   build/raster optimization is considered.
7. **DONE (local scope) — Protect and validate.**  Formatter, analyzer,
   changed focused groups, the application suite (`+278`) and the fast suite
   (`+291`) pass. The full presentation suite completes at `+582 -19`; its
   19 failures are normalized to the clean-9e header/golden/ticker and stable
   render-surface baseline. Remote CI remains the delivery authority.
8. **NEXT — Deliver.**  Review changed-symbol graph consumers, reread the
   checklist, make atomic application commits, push, monitor the exact GitHub
   Actions SHA, download/hash the normal human APK, then regenerate/validate/
   push SCIP from the separate tooling worktree.

No step is an approval checkpoint.  Continue through implementation and
delivery unless a revised user stop condition actually occurs.  Physical
validation remains **PENDING — USER ONLY**.
