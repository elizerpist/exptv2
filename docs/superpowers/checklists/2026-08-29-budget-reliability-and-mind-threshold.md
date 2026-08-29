# Budget reliability and Mind threshold acceptance checklist

Source: the 2026-08-29 autonomous production brief, Fluvi Logs revision 50,
`MILESTONE_COMMITS.md`, and
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260829-081019.png`.

| ID | Requirement / source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| A1 | Budget mode entry (brief A1; screenshot) | Budget presentation and CoreDashboard mode boundary | Every new Budget-visible epoch publishes one compatible Header/progress/summary/distribution selection without an Avatar crossing. | deterministic controller/core tests, log trace, Android exercise | PARTIAL |
| A2 | First long press (brief A2) | Budget presentation and limit-edit owner | A compatible transient update cannot clear the direct draft; target/scope replacement cannot write the old target. | injected-race controller/widget tests | PARTIAL |
| A3 | Daily Rhythm collapse (brief A3) | Distribution card surface/pager | Daily Rhythm remains the active clipped child for every collapse progress; Partner stays unchanged. | controlled-progress raster/widget tests | PARTIAL |
| A4 | Rhythm geometry (brief A4) | Rhythm/card layout resolver | Rhythm plot allocation is exactly 1.10× baseline and the exact delta is reclaimed from the chart region; outer envelope is unchanged. | geometry tests | PARTIAL |
| B1 | Shared threshold ownership (brief B1–B5) | Query domain/controller/menu/Mind surface | Mind and Query menu bind one canonical minimum-amount refinement, identity, bounds and predicate. | domain/application/widget tests | PARTIAL |
| B2 | Canonical threshold range (brief B2/B15) | Shared threshold authority | Minimum is 1000 HUF; dynamic canonical maximum is finite, >= minimum, and clamps the current value. | bounds/dynamic-scope tests | PARTIAL |
| B3 | Foreground performance and stale safety (brief B4/B6–B11/B16) | Query publication and Mind slider | Latest semantic threshold wins; raw movement has no repository work or full-dashboard rebuild; LogBox ownership stays stable. | counter/identity/application tests | PARTIAL |
| B4 | Mind physical integration (brief B10/B12/B13/B14) | First Mind card | Bottom horizontal control reuses Query semantics/style and does not leak or steal vertical/collapse gestures. | widget/Android verification | PARTIAL |
| V1 | Regression/performance baseline | Dashboard integration | Existing Avatar, Summary, distribution, LogBox and Header contracts remain intact. | focused existing suites, analyze, Android exercise | PARTIAL |
| D1 | Delivery | docs/git/GitHub Actions | Evidence is documented, source-coherent commits are pushed, exact-SHA human APK is downloaded. | diff/check, CI, file hash | DONE |

## Evidence recorded before delivery

### Mode entry

Fluvi Logs revision 50 records CORE_MODE_SWITCHED from mind to budget at
09:18:16.090, followed by distribution-hotset preparation and a
distribution-scope bind, but no matching BUDGET_HEADER_VALUE_BOUND or
BUDGET_PROGRESS_BOUND. Later avatar selection does emit both Header and
progress binds. The missing boundary was therefore the Budget-visible mode
entry itself, not missing canonical analysis.

DashboardCoreModeController.committedModeEpoch is now a monotonic visibility
identity. CoreDashboard calls
DashboardBudgetPresentationController.publishForVisibleBudgetEpoch before the
distribution preparer. That one RAM-only publication writes Header, ring,
selection and partition from the same state. The bounded
BUDGET_VISIBLE_PUBLICATION_REPLAYED trace records epoch, generation, target,
scope and availability. Controller tests cover an unchanged target on a new
epoch; the CoreDashboard regression drives Mind -> Budget -> Mind -> Budget
without an Avatar selection and observes the two real mode-entry replay
epochs. The existing distribution publication test covers asynchronous
preparation.

### Limit edit

The previous unavailable branch in _liveSelectionFor called
invalidateIfContextChanged(null), which cleared _active; this reproduced the
first-long-press reset. Null now means an unknown transient gap, not a
different semantic target. A concrete incompatible key still ends the edit,
and finishEdit still verifies the current key before writing.

While a matching direct session exists, the last compatible immutable
analysis/selection is retained through that gap, preserving the edited
denominator and ring. The YEAR vector follows the same rule: a null context
retains its twelve-month draft, while a concrete context/revision replacement
ends it. The bounded
BUDGET_LIMIT_EDIT_ACTIVE_ANALYSIS_RETAINED trace identifies this case.
The raw visible/live authority is independently resolved for persistence, so
a retained Header can never authorize a release after a concrete new
target/scope/revision is already visible but its Budget snapshot is not yet
compatible. A core revision deliberately survives navigation-only preparation,
so it cannot order scopes alone: a retained live-interaction frame is used only
when it is at least as new as the same-direction visible navigation epoch and
core revision. A newer visible frame wins.
The injected stale-preparation test proves the second semantic tick remains
accepted and the Header/ring do not become unavailable; the release-race
regression proves the old key receives no write after a new visible scope
arrives, including an equal-core-revision retained live frame from an older
navigation epoch.

### Daily Rhythm and geometry

The current Card2 path owns one shell (BudgetDistributionCardShell) around
the persistent PageView; the interior is one rounded clip. The controlled
Partner and Category raster tests sample all collapse progress points without
background/sibling exposure. The Daily Rhythm's former dense zero tracks are
transparent outlined tracks, not an opaque neutral rectangle.

The usable plot lane changed from 40 dp to 44 dp (1.10 × 40). Its 4 dp delta
is taken from the Partner upper chart region: at the 217 dp reference envelope
the donut is 110 dp -> 106 dp and the Rhythm footer is 62 dp -> 66 dp. No
outer Card2 constraint changed.

### Mind threshold

The prior menu slider used the existing minimumAmountScaled100 refinement.
QueryAmountThreshold now owns that same key, 1000-HUF (100000 scaled) floor,
canonical facet-domain maximum and clamping. It returns an immutable
CurrentLedgerQueryScope, so existing Query equality, cache key, generation and
native predicate remain authoritative.

The menu's lower range handle and the Mind bottom slider use this authority.
Mind raw pointer movement remains local to QueryAmountThresholdSlider; only
onChangeEnd calls DashboardCoreController.applyQuery, preserving the existing
latest-wins publication path and avoiding repository work per pixel. The Mind
control listens only to CurrentQueryController, so no Budget widget is
subscribed to pointer-rate updates.

The Android canonical predicate remains `amount_scaled_100 >= minimum`: the
brief's “above” wording is therefore normalized to the existing inclusive
Query semantics, rather than giving the two surfaces different boundary
rules.

### Automated verification

The focused Budget, distribution/raster, Partner geometry, Query menu/shared
threshold, CoreDashboard and mode-host suites completed successfully: 109
tests passed. `flutter analyze` completed with no issues in 190.7 seconds.

`dashboard_core_query_application_test.dart` has one proven inherited failure:
`RED: a seven-target chip hotset defers clear-all before its Query index build`
times out after 30 seconds. It was reproduced unchanged in a detached
worktree at starting SHA `3c719dd4680796e11533831d58058f9a48d055d1`; neither
that test file nor `DashboardCoreController` changed in this work. Android
physical repetition remains required before these items can become DONE.

### Delivery

Production commit `ac98fdaf224e1609ebe00523b248ded2947b8a7e` was pushed to
`origin/separated-core-modes`. GitHub Actions run `33243180357` completed its
dashboard paths, Flutter, native Room and human physical-device diagnostic APK
jobs successfully for that exact SHA. The release asset
`fluvi_HUMAN_DIAGNOSTIC_ac98fda.apk` was downloaded to
`/storage/emulated/0/Download/fluvi/`; its SHA-256 is
`89e47271f174e787aeabb2d75270e944df5c67d4b8735e8dbe6a7d0eee8d29de`.

The separate emulated A--J dashboard profile gate was still in progress when
this delivery evidence was recorded. It is not substituted for manual Android
physical acceptance.
