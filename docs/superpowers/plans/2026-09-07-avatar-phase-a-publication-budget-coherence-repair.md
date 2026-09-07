# Execution plan — Avatar Phase-A publication and Budget coherence

## Goal

Repair the 5ba6c01 Avatar smooth-but-empty regression, then deliver an exact-SHA APK and SCIP graph without reopening Time or Mind/Slider behavior.

## Architecture / stack / global constraints

Flutter/Dart application with a single existing `DashboardVisibleFrameStore`, one `DashboardLogBoxPreparedSceneCache`, and one controller-owned Avatar focus path. No new cache, store, LogBox, controller, timer/cooldown, DB/index work, rich projection, or TextPainter work may be added at semantic crossings. Human APKs build online only.

## Steps

1. Freeze and deduplicate the current two Drive logs; record the evidence discrepancy rather than mixing later Drive data.
2. Audit source, lineage, graph consumers, and full tests; update the checklist and forensic record.
3. Add production-parent red regressions for warm-exact/global-hotset mismatch, cold pending replay, latest-wins stale completion, coherence, aggregate/empty, and edit identity.
4. Implement the smallest controller-owned exact-resource/pending-candidate transaction.
5. Add a quick-edit fail-closed identity boundary only if the upstream transaction leaves a real pre-publication edit window.
6. Run focused tests after each unit, then analyzer and broad suites in Ubuntu proot; verify Time/Mind files unchanged.
7. Commit atomically, push, monitor GitHub build, download and hash the human APK, regenerate SCIP in its tooling worktree, and report without claiming physical success.

Execution is inline because the controller, cache authority, and production-parent tests are tightly coupled; splitting them would create integration risk rather than parallel value.
