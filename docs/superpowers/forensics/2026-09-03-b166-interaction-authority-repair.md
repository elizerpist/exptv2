# b166 interaction-authority engineering journal

## [STEP 01]

Question: What is the common current admission failure behind Avatar filtering,
time settlement and Mind live-list preview?

Evidence:

- The b166 Avatar capture (`fluvi-1788418684814831`, retained seq 1136–2135)
  repeatedly has `AV|PREVIEW_REQUESTED → FOCUS_DERIVED_SCOPE_READY →
  AV|LIVE_ROOT_MISS → AV|PREVIEW_REJECTED`, while the Avatar handle advances
  and `BUDGET_PROGRESS_IDENTITY_MISMATCH` retains an older visible target.
- The b166 time capture (`fluvi-1788418566542137`, retained seq 1026–2025)
  contains repeated Summary live-root misses and rich-paint-gated settlement.
- The b166 slider capture (the same Avatar session, retained seq 1470–2469)
  ends a drag with `MIND|LIVE_ROOT_MISS` and
  `MIND|CANONICAL_COMMIT_REJECTED_PREVIEW_RETAINED`
  `reason=latestExactPreviewUnavailable` despite a stable domain.
- `budget_dashboard_core_surface.dart` routes the rail's target-acceptance
  callback through `previewBudgetTargetPainted`, and the Core has equivalent
  rich-root admission paths for time and Mind.

Conclusion: **CONFIRMED** architectural inversion.  Rich LogBox scene/paint
readiness currently participates in Phase-A semantic/list admission.  It is
not permissible for that optional Phase-B work to decide the current user
target.

Decision: Add red production-parent tests first, then change the existing
shared Core/visible-frame seam so a resident exact frame is authoritative
before rich preparation/paint.  Preserve stale-identity rejection and Avatar
physics.

Validation: source/log forensics complete; implementation and automated tests
pending.

## [STEP 02]

Question: Can shared rich-resource preparation remain bounded without letting
an Avatar warmup evict the reusable Mind non-amount universe?

Evidence:

- Before this change `DashboardLogBoxPreparedSceneCache` had one global
  live-interaction resource key. A new lane could replace it regardless of the
  logical input owner.
- The b166 captures show Avatar and Mind resource preparation cancelling or
  displacing one another immediately before `LIVE_ROOT_MISS`.
- The new regression first fails against b166 when an Avatar preparation is
  introduced after a Mind resource. The repaired test proves both roots remain
  addressable; same-lane replacement discards only the prior same-lane bank;
  superseded preparation releases only its stale candidate.

Conclusion: **CONFIRMED** shared ownership defect. One global key conflated
unrelated interaction lanes.

Decision: The existing bounded cache now owns one active resource per explicit
lane (`budgetAvatarPreview`, `mindAmountPreview`, reserved `timePreview`) and
one atomic replacement slot per lane. A successful replacement releases only
its lane predecessor; a failed/superseded replacement keeps the earlier
compatible resource. The cache cap and row/byte accounting remain the sole
retention boundary.

Affected source: `dashboard_logbox_prepared_scene_cache.dart`,
`dashboard_logbox_scene_window.dart`, `core_dashboard.dart`, and
`dashboard_core_controller.dart`.

Validation: `dashboard_logbox_prepared_scene_cache_test.dart` PASS (45 tests);
combined focused suite PASS (111 tests).

Status: CONFIRMED

## [STEP 03]

Question: Must rich LogBox staging or post-paint acknowledgement decide the
current Avatar, time or Mind semantic target?

Evidence:

- b166 red tests fail when a rich stager is unavailable: Mind returns false,
  Avatar focus returns false, and time candidate admission returns false even
  though an exact resident prepared index exists.
- The b166 physical captures have the same sequence: rich-root miss followed
  by no live publication or release rejection.
- The repaired Core publishes `DashboardVisibleFrameStore` Phase-A frames
  first. The renderer paints a bounded exact semantic row projection from
  resident ledger entries when rich rows are unavailable; no repository,
  index, SQL or text-layout work is started on the input path.

Conclusion: **CONFIRMED** architectural inversion. Rich scene readiness is a
Phase-B augmentation, not the admission condition for exact semantic/list
authority.

Decision: Mind and Avatar accept/publish Phase A even on a rich-root miss;
their canonical reconciliation starts asynchronously after exact acceptance.
The Summary selector settles the latest accepted target and recenters only
after that semantic settlement succeeds. Late rich work is identity-checked
and can enhance but cannot restore an older target.

Validation: `dashboard_core_ephemeral_focus_test.dart`,
`dashboard_logbox_query_preview_paint_test.dart`, Avatar rail tests and Summary
tests PASS; full changed-file analyzer PASS.

Status: CONFIRMED

## [STEP 04]

Question: Could canonical Avatar reconciliation make a matching optional rich
paint acknowledgement falsely stale after Phase-A acceptance?

Evidence:

- A canonical focus install can advance the visible presentation/frame epoch
  for the exact same Avatar target before the renderer reports its paint.
- The original acknowledgement target then compared the prior epoch and
  rejected the otherwise matching paint.

Conclusion: **CONFIRMED** acknowledgement-retag edge; it does not affect
semantic acceptance but corrupts Phase-B diagnostics and could recreate a
false rich-paint rejection.

Decision: Retarget the mutable acknowledgement metadata only when target
handle, focus generation, query key and visible identity remain exact. The
retarget cannot publish or select a semantic target.

Validation: production LogBox preview/paint test reports
`AV|LOGBOX_TARGET_PAINTED` for the canonical-reconciled target.

Status: CONFIRMED

## [STEP 05]

Question: Did this repair introduce failures in the affected dashboard suite?

Evidence:

- Changed-file `flutter analyze --no-pub` and full `flutter analyze --no-pub`
  complete with no issues.
- Focused interaction/cache/renderer/debug suite completes with 111 passing
  tests; logger/diagnostic suite completes with 37 passing tests.
- `flutter test --no-pub test/features/dashboard --reporter compact` ends with
  19 failures. b166 baseline comparison reproduces the same 18 Header/golden/
  ticker failures and the same pre-existing stable LogBox surface test failure.

Conclusion: No task-related failure was found in the affected or broad suite.
The unrelated Header/golden failures remain outside this scope.

Decision: Do not change Header, goldens or the existing stable-surface test in
this interaction-authority pass. Record the baseline honestly and continue to
commit/push/build validation.

Validation: commands and results are recorded in the completion handoff.

Status: CONFIRMED
