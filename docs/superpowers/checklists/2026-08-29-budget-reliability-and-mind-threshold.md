# Budget reliability and Mind threshold acceptance checklist

> 2026-08-29 release-closure supersession: the prior delivery evidence is not
> physical closure. Gates G1–G5 in
> `docs/superpowers/plans/2026-08-29-dashboard-release-closure.md` are all
> release-blocking pre-build gates. They become **DONE** only with current
> production-owner test and performance evidence. The exact-SHA physical APK
> exercise is then recorded separately under post-build delivery record D1;
> it never authorizes an early build.
> The current closure investigation uses Fluvi Logs revision 51.

Source: the 2026-08-29 autonomous production brief, Fluvi Logs revision 50,
`MILESTONE_COMMITS.md`, and
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260829-081019.png`.

| ID | Requirement / source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| A1 | Budget mode entry (brief A1; screenshot) | Budget presentation and CoreDashboard mode boundary | Every new Budget-visible epoch publishes one compatible Header/progress/summary/distribution selection without an Avatar crossing. | deterministic controller/core tests, log trace | DONE |
| A2 | First long press (brief A2) | Budget presentation and limit-edit owner | A compatible transient update cannot clear the direct draft; target/scope replacement cannot write the old target. | injected-race controller/widget tests | DONE |
| A3 | Daily Rhythm collapse (brief A3) | Distribution card surface/pager | Daily Rhythm remains the active clipped child for every collapse progress; Partner stays unchanged. | controlled-progress raster/widget tests | DONE |
| A4 | Rhythm geometry (brief A4) | Rhythm/card layout resolver | Rhythm plot allocation is exactly 1.10× baseline and the exact delta is reclaimed from the chart region; outer envelope is unchanged. | geometry tests | DONE |
| B1 | Shared range ownership (brief B1–B5) | Query domain/controller/menu/Mind surface | Mind and Query menu bind one canonical two-ended amount refinement, identity, bounds and predicate. | domain/application/widget tests | DONE |
| B2 | Canonical amount range (brief B2/B15) | Shared range authority | Minimum is 1000 HUF; dynamic canonical maximum is finite, >= minimum, and clamps both current bounds. | bounds/dynamic-scope tests | DONE |
| B3 | Foreground performance and stale safety (brief B4/B6–B11/B16) | Query publication and Mind range control | Latest semantic range wins; raw movement has no repository work or full-dashboard rebuild; LogBox ownership stays stable. | counter/identity/application tests | DONE |
| B4 | Mind physical integration (brief B10/B12/B13/B14) | First Mind card | Bottom horizontal control reuses Query semantics/style, stays inside a narrow/low card, and does not steal vertical/collapse gestures. | widget test; exact-SHA physical check is recorded under D1 | DONE |
| V1 | Regression/performance baseline | Dashboard integration | Existing Avatar, Summary, distribution, LogBox and Header contracts remain intact. | focused existing suites and analyze | DONE |

## Post-build delivery record (does not authorize the build)

| ID | Requirement | Acceptance condition | Status |
| --- | --- | --- | --- |
| D1 | Exact-SHA human delivery | Pushed production SHA has a successful normal human APK; artifact is downloaded to `/storage/emulated/0/Download/fluvi` and its SHA-256 is recorded. | DONE |

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

### Mind amount range

The prior lower-only refinement is replaced by `QueryAmountRange`, which owns
the existing amount refinement keys, 1000-HUF (100000 scaled) floor, canonical
facet-domain maximum and clamping for both endpoints. It returns an immutable
`CurrentLedgerQueryScope`, so existing Query equality, cache key, generation
and native predicate remain authoritative.

The Query sheet and Mind bottom control share `QueryAmountRangeControl`. Raw
pointer movement stays widget-local; only `onChangeEnd` calls
`DashboardCoreController.applyQuery`, preserving the existing latest-wins
publication path and avoiding repository work per pixel. The Mind control
listens only to `CurrentQueryController`, so no Budget widget is subscribed to
pointer-rate updates.

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
that test file nor `DashboardCoreController` changed in this work. At that
historical checkpoint, Android physical repetition was still pending; the
current exact-SHA physical requirement is instead tracked exclusively by D1.

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

## Current r51 closure evidence (source/test gate; physical artifact pending)

### G1 Avatar foreground cost

Revision 51 records six Avatar crossings, six prepared-focus requests and six
preview publications, followed by `SCENE_WINDOW_PREPARE_STARTED`. The good
time path does not start this rich scene realization for each direct category
crossing. The direct Category frame was already exact and visible; the costly
scene was only visual augmentation. `DashboardCoreController` now retains only
the newest augmentation while the Avatar motion lane is active, then admits it
after release. The G1 regression drives three crossings and proves zero rich
preparations during motion and one afterwards; it preserves the final target
and no repository reads.

### G2 semantic selection commit

The r51 `targetHandle=8` Header/progress/partition/distribution bindings beside
`categories:` in the committed LogBox Query proved a split publication
authority. `BudgetTargetAvatarRail` no longer mutates Budget presentation
directly. `DashboardBudgetLogboxDrilldownCoordinator` resolves one prepared
target, Core atomically commits its focused Query frame, and only that visible
publication callback promotes the Budget target/Header/palette. A live frame
whose target handle is not the selected target is rejected. This keeps the
last compatible Budget frame while a newer Query generation is incomplete;
there is no restart, retry, or synthetic Avatar command.

### G3 shared two-ended amount range

The incorrect lower-only `QueryAmountThresholdSlider` was deleted.
`QueryAmountRange` owns the 1000-HUF floor, dynamic canonical domain and both
canonical Query refinements; `QueryAmountRangeControl` is the one public
two-handle RangeSlider instantiated by both the Query sheet and first Mind
card. Raw moves remain widget-local; the existing Query apply path receives
one immutable range at `onChangeEnd`.

### G4 Card2 physical owner

The remaining slab path was the absence of
`BudgetDistributionCardShell` in unified composition: a transparent PageView
then exposed the separately moving common Budget surface below it.
`BudgetDistributionCardShell` now always owns Card2's rounded surface,
shadow/border and matching interior clip; PageView remains persistent and
transparent beneath that single clip. The controlled Partner and Category
raster/identity regressions cover forward and reverse collapse while retaining
the accepted 44dp rhythm plot allocation.

### G5 approved category Header material

`dashboard_header_category_scale.dart` transcribes the approved
`category_palette_variation_lab.html` compressed V1 `Spectrum 40°` card
(lead 24°, tail 16°). Its color_12 anchors are regression-tested against the
HTML. `Cool` / `Kategória` is now an explicit Header setting. In Category mode
only window width is user-owned; `remaining = clamp(1 - spent / limit)` drives
the position, so zero spend samples the dark/right tenth and full spend the
white/left end. The cached scale feeds the existing retained Header
frame/shader input only at semantic Budget commits; no palette generation,
program creation, or root rebuild occurs per Avatar pixel.

## r51 pre-build closure (2026-08-29)

All release-blocking G1--G5 items are now **DONE**. The evidence was collected
against the current production-owner diff, after the final compact Mind-range
layout correction:

| Gate | Final acceptance evidence | Status |
| --- | --- | --- |
| G1 | `dashboard_core_ephemeral_focus_test.dart` drives three Avatar crossings and verifies no rich preparation during active motion, then one preparation after release. | DONE |
| G2 | Core/controller/Avatar-rail tests verify the visible committed Query identity reaches the Budget target only after the semantic commit and rejects late frames. | DONE |
| G3 | Domain, control, Query-sheet and CoreDashboard tests cover one two-ended range authority, 1000-HUF floor, dynamic bounds, delayed commit, and a narrow 180 x 146 Mind card without a layout exception. | DONE |
| G4 | Pager, surface and category-card suites keep the single Card2 shell/clip through both collapse directions while preserving the 44dp Rhythm lane. | DONE |
| G5 | Header-scale, engine and tuner suites verify the approved V1 anchors, Cool/category switch, 50%/100%/0% remaining positions, width ownership and stale-frame rejection. | DONE |

The final pre-build command completed **176 tests** successfully:

```text
flutter test test/app/fluvi_app_test.dart \
  test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart \
  test/features/dashboard/application/dashboard_budget_presentation_controller_test.dart \
  test/features/dashboard/presentation/budget_category_avatar_rail_test.dart \
  test/features/dashboard/query/domain/query_amount_range_test.dart \
  test/features/dashboard/query/presentation/query_amount_range_control_test.dart \
  test/features/dashboard/query/presentation/query_menu_sheet_test.dart \
  test/features/dashboard/presentation/core_dashboard_test.dart \
  test/features/dashboard/presentation/budget_distribution_pager_test.dart \
  test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart \
  test/features/dashboard/presentation/budget_category_distribution_card_test.dart \
  test/features/dashboard/presentation/dashboard_category_header_scale_test.dart \
  test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart \
  test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart
```

`flutter analyze` then completed with no issues in 101.3 seconds, and
`git diff --check` was clean. A full-suite run was also attempted. It exposed
the unchanged, pre-existing `dashboard_scroll_milestone_test.dart` selector /
milestone assertion failure; that source and its LogBox dependencies are
unchanged from `f4a3fe2d`. It is not counted as passing verification and does
not weaken any G1--G5 acceptance result. D1 remains the separate, mandatory
exact-SHA human delivery gate above.

### D1 exact-SHA artifact delivery

Production application commit
`05f4693555de5c4ff63ea4ab1bd6c2d048838cec` was pushed to
`origin/separated-core-modes`. GitHub Actions run
`33251374597` passed its Flutter gate (2:01), clean Android/Room plus native
dashboard gate (6:11), and `build-human-diagnostic-apk` (3:56). The latter
published `fluvi_HUMAN_DIAGNOSTIC_05f4693.apk` directly from that exact SHA.

The exact file was downloaded to
`/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_05f4693.apk`.
Local `sha256sum` and the GitHub release digest both record:

```text
c5c23437313d044dc5b833da1814a7a165b98c3c2d8877b1c733aeb81d1bea6f
```
