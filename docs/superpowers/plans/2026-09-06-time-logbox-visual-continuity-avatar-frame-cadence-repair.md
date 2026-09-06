# Implementation plan — Time LogBox visual continuity / Avatar frame cadence

Base: `a8ad6e5cae641a19a7a23acc917313a4c41ac851`.
Branch: `fix/time-logbox-visual-continuity-avatar-frame-cadence-codex-20260906`.

This work is deliberately inline.  The Time acknowledgement, render binding,
extent and controller lifecycle share the same ownership boundary; splitting
implementation among workers would create conflicts and make causality harder
to audit.  A later read-only review is appropriate after the focused diff is
stable.

1. **DONE — Evidence baseline.**  Recorded git identities, read a8ad
   lineage/docs/source/tests, inspect screenshots, fully fetch all three Drive
   files, globally deduplicate by sequence, and verify the matching graph.
2. **DONE — Source/impact map.**  Traced prepared Time publication from
   Core through the display coalescer, visible lanes, render-domain selection,
   custom paint, extent reporting and acknowledgement.  Verify every graph
   relation against CURRENT source.  Record what the existing `0|1`
   `paintedLiveSnapshots` field actually measures.
3. **DONE — Establish red regressions and truthful diagnostics.**  Built the
   persistent production-parent Time harness for one-frame and multi-target
   cases.  Add compact lifecycle/domain/extent diagnostics and tests for
   exact-empty, Phase-A-without-rich, stale acknowledgement, and handoff.
4. **DONE — Repair only proven Time/LogBox edges.**  Removed the product-
   rejected exact-empty decoration directly.  Apply a minimal shared
   visual-authority/extent/handoff correction only after the new reproducer
   identifies it.  Keep strict stale rejection and all stable owners.
5. **DONE — Measure Avatar, preserve slider.**  Added bounded FrameTiming and
   staged pipeline aggregation; make no physics change absent proof.  Rerun
   unchanged Mind/count production tests.
6. **DONE — Validate and review impact.**  The focused and broad baseline
   comparison is recorded: application is `278` PASS; presentation is `577`
   PASS / `19` normalized inherited failures versus exact a8ad `572` PASS /
   `19` failures.  Formatter and analyzer pass.  A late hot-path regression
   was corrected by making Phase-A geometry lazy under the bounded cache owner.
   All changed shared-symbol consumers were inspected through graph discovery
   plus CURRENT source.  The checklist records the remaining physical-only
   evidence honestly.
7. **NEXT — Commit and delivery.**  Commit logically atomic app changes with
   evidence bodies, push, monitor GitHub Actions, download/hash the normal
   human APK, then separately regenerate/validate/commit the matching SCIP
   graph or explicitly report it stale.
