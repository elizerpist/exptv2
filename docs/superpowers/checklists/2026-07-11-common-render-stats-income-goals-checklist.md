# Common Render Stats + Bevételi Célok Implementation Checklist

Date: 2026-07-11
Base branch: `origin/integration/latest-main-build`
Working branch: `feature/common-render-stats-income-goals`

## Required References

- `docs/superpowers/specs/2026-07-10-stat-common-render-page1-2-final-spec.md`
- `docs/superpowers/specs/2026-07-11-income-category-goals-design.md`
- `docs/prototypes/stats_common_2025_final_0710.html`
- `docs/prototypes/stats_common_2025_acceptance.md`
- `docs/prototypes/stats_common_2025_stat_page_2_final_0710.html`
- `docs/prototypes/stats_common_2025_stat_page_2_acceptance.md`
- `docs/prototypes/stats_sum_mode_page1_yearcards.html`
- `docs/prototypes/stats_sum_mode_page1_yearcards_acceptance.md`
- `docs/prototypes/stats_common_2025_snapshot_mode.html`
- `docs/prototypes/stats_common_2025_snapshot_mode_acceptance.md`

## Baseline

Fresh baseline command before implementation:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart test/transactions/budget_progress_manager_test.dart test/transactions/transaction_store_budget_goals_test.dart test/stats/stats_year_data_test.dart test/stats/stats_page_test.dart'
```

Result before edits: `+107 All tests passed`.

## Stat Common Render Requirements

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| SCR-LANG-01 | `2026-07-10-stat-common-render-page1-2-final-spec.md` | `lib/features/stats/**` | Page 1 and Page 2 stats UI copy is Hungarian except `Expense Tracker` | Widget tests + source scan + visual comparison | DONE |
| SCR-STRUCT-01 | same | `lib/features/stats/stats_page.dart` | Order is header/FastInfo, type toggle, SummaryPill, SearchPill, swipe viewport | Widget test + screenshot/manual comparison | DONE |
| SCR-AREA-01 | same | `StatsPage` layout | Page 1/Page 2 content shares fixed viewport between SearchPill and bottom nav | Widget test + screenshot/manual comparison | DONE |
| SCR-MODE-01 | same | `StatsRenderMode`, threshold sheet, `StatsPage` | Old `Kategória scope` / `Hózárás` / `Hőtérkép` UI selector is removed; only common render remains | Widget test + code inspection | DONE |
| SCR-SWIPE-01 | same | `StatsPage` content pager | Page 1 and Page 2 are horizontal swipe pages, not vertical stacks | Widget test | DONE |
| SCR-FAB-01 | same | `ExptShell`, `ExptFab`, `StatsPage` | Stats-tab FAB uses threshold/joystick icon and opens stats threshold/snapshot sheet; home tab keeps plus/add transaction | Widget test + code inspection | DONE |
| SCR-FAB-02 | Current conversation: restore prior joystick logic | `ExptFab`, `StatsPageController`, `ExptShell` | Stats FAB long-press vertical drag changes the fixed 5 000 Ft threshold upward/downward with the prior 1x/2x/6x distance acceleration; horizontal drag still steps snapshots | FAB + controller + shell widget tests | DONE |
| SCR-SHEET-01 | same | Threshold bottom sheet | Threshold sheet has slider + numeric input and no render-mode buttons | Widget test | DONE |
| SCR-SNAPSHOT-01 | same | Snapshot model/repository/sheet | FAB sheet contains snapshot editor row with camera add card, tap-select recall, and snapshot state fields | Model + widget tests | DONE |
| SCR-SNAPSHOT-02 | same | Snapshot add dialog | Add-new snapshot opens centered dialog with name input and include-mask checkboxes | Widget test | DONE |
| SCR-SNAPSHOT-03 | same | Snapshot repository/storage | Snapshots persist in local repository/table with include-mask fields | Repository/model tests + native database inspection | DONE |
| SCR-SEARCH-01 | same | `StatsPage`, `SearchPill`, shell vendor sheet | Stats menu includes SearchPill and vendor selector sheet support | Widget test | DONE |
| SCR-VENDOR-01 | same | Stats filtering/model | Vendor/source filters affect header score, FastInfo, summary, Page 1, Page 2 | Model + widget tests | DONE |
| SCR-MAG-01 | same | Header/magnet stats model | Header score/magnet uses approved score bands and Hungarian copy | Model + widget/screenshot comparison | DONE |
| SCR-FAST-01 | same | `stats_fast_info_graph.dart`, data helpers | Expense/income FastInfo graph math and labels match approved common render | Model + widget/painter tests + visual comparison | DONE |
| SCR-MONTH-01 | same | `stats_year_calendar.dart` | Page 1 year-mode month cards/day cells match approved HTML behavior | Painter/widget tests + visual comparison | DONE |
| SCR-SUM-01 | same | New/extended sum-mode widgets/data | Sum mode year cards and month cells match authoritative sum-mode HTML | Model + widget/painter tests + visual comparison | DONE |
| SCR-SUM-02 | same | Page 2 routing | Sum mode reuses the same Page 2 layout with sum-mode data scope | Widget/model tests + code inspection | DONE |
| SCR-MODES-01 | same | Stats layout state | Page 1 supports `sum`, `year`, `month` layout modes | Widget/state tests | DONE |
| SCR-NAV-01 | same | SummaryPill integration | SummaryPill navigates `sum/year/month` layout state | Widget/state tests | DONE |
| SCR-NAV-02 | same | Page 1 card taps | Year/month card taps update active period and SummaryPill state | Widget/state tests | DONE |
| SCR-SYNC-01 | same | Shared period state | Main menu and stats share layoutMode/activeYear/activeMonth | State/integration tests | DONE |
| SCR-MONTHFOCUS-01 | same | Month mode content | Month mode shows enlarged single month card with top back button | Widget/painter tests + visual comparison | DONE |
| SCR-MONTH-AXIS-01 | same | FastInfo axis helpers | Month-mode FastInfo keeps all day points and thins day labels dynamically | Model tests | DONE |
| SCR-PAGE2-01 | same | Page 2 widget/data | Page 2 KPI/category/vendor layout matches final Page 2 HTML | Widget/model tests + visual comparison | DONE |
| SCR-PAGE2-SCOPE-01 | same | Page 2 filtering | Same Page 2 component receives sum/year/month filtered datasets | Model tests | DONE |
| SCR-THRESH-01 | same | Stats filtering | Threshold filters visible records consistently across all stats | Model tests | DONE |
| SCR-WARN-01 | same | Page 2 warning | Threshold warning appears in all three approved places with `X alatti tranzakciók rejtve` | Widget test + visual comparison | DONE |
| SCR-NOBUDGET-01 | same | Stats pages | Budget/limit stats are not mixed into threshold-filtered common stats pages | Code inspection | DONE |

## Bevételi Célok Requirements

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| ICG-01 | `2026-07-11-income-category-goals-design.md` | Domain copy + editor | Bevételi kategóriánál the UI uses `Bevételi cél`, not kiadási limit wording | `flutter test test/transactions/transaction_home_limits_test.dart --name "income category editor labels the amount as income goal"` + code inspection | DONE |
| ICG-02 | same | Center badge progress | Bevételi overview and category circle progress is `actualIncome / goal`, clamped at 100% | `flutter test test/transactions/income_goal_presentation_test.dart` + backheader widget tests | DONE |
| ICG-03 | same | Center badge color | Bevételi cél 100%+ is success/green, not warning/danger/red | Code inspection of `IncomeGoalPresentation.effectiveProgressColor`, `category_budget_stage.dart`, `backheader_style_surface.dart` | DONE |
| ICG-04 | same | Backheader visual | Existing circle progress visual remains, only income semantics change | Code inspection: existing `CategoryBudgetStage`/`BackheaderStyleSurface` rendering retained, only progress/status sources changed | DONE |
| ICG-05 | same | Expandált státuszfelirat | Income status text is only `X hiányzik`, `Cél megvan`, `+X plusz`, `Nincs cél` | `flutter test test/transactions/income_goal_presentation_test.dart` | DONE |
| ICG-06 | same | `centerRemainingText` slot | Income status appears at `backheader-center-remaining-amount`, same location as expense `X maradt` | `flutter test test/transactions/category_budget_stage_test.dart --name "income|expense category keeps remaining copy"` | DONE |
| ICG-07 | same | Storage compatibility | Existing `category_limits` with `transactionType=income` is reused; no new table needed for income goals | `flutter test test/transactions/transaction_home_limits_test.dart --name "income side uses income goal and income category allocation"` + code inspection | DONE |
| ICG-08 | same | Expense regression | Expense limit behavior, colors, and `X maradt` remain unchanged | `flutter test test/transactions/category_budget_stage_test.dart --name "expense category keeps remaining copy"` | DONE |
| ICG-09 | same | Overview income goal | Budget's income-side pair is `Összbevételi cél`, `targetType=overview`, `transactionType=income` | `flutter test test/transactions/transaction_store_budget_goals_test.dart --name "income backheader starts with income goal then income categories"` + `transaction_home_limits_test.dart --name "income side uses income goal"` | DONE |
| ICG-10 | same | Income backheader list | Income side has no separate `Megtakarítás`; list is `Összbevételi cél` + income category goals | `flutter test test/transactions/transaction_store_budget_goals_test.dart --name "income backheader starts with income goal then income categories"` | DONE |

## Completion Rule

This feature package is complete only when every row above is `DONE`, or a non-DONE row has an explicit user-approved deferral. Passing tests, analyzer, or an APK build is not sufficient by itself.

## Latest Verification

### Recovery audit before completion work

Audit date: 2026-07-11.

- GitHub branch and local `HEAD` both point to `9101537eac46582ffd7d3de6c6389c04dba68d47`; the successful GitHub Actions run for that commit does not include the current local working-tree changes.
- Local-only state at audit start: 10 modified tracked files and 5 untracked files; none were staged or uploaded.
- `SCR-SNAPSHOT-03` remains `NOT DONE`: the local draft stores one JSON string in `SharedPreferences`, while the accepted spec requires a real local snapshot repository/database/table rather than an ad hoc encoded string.
- `SCR-MONTH-01` remains `PARTIAL`: the Flutter month-card painter omits the authoritative HTML's `zárás` caption and threshold-filtered secondary scope row.
- `SCR-SUM-01` remains `PARTIAL`: the local year card omits the authoritative HTML's closing amount/caption, selected-year styling, scope-total row, and single-category color rule.
- `SCR-PAGE2-01` remains `PARTIAL`: the local category panel does not render the required centered donut for multiple categories, and the top largest-event tile omits the reference detail line.
- `SCR-LANG-01` and visual rows remain `PARTIAL` until source scan, widget evidence, and reference screenshots/geometry checks are all complete.
- `SCR-SYNC-01` and `SCR-MONTH-AXIS-01` move to `DONE` based on new local regression tests, subject to the fresh full-suite verification below.
- Completion work may not change any remaining `PARTIAL`/`NOT DONE` row to `DONE` without the verification method named in that row.

2026-07-11 targeted implementation verification:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Result: `No issues found!`

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Result after the recovered implementation: `+795 All tests passed!` (8 minutes 6 seconds).

Additional acceptance evidence:

- `test/stats/stats_ui_reference_test.dart` verifies the accepted Page 1 month-card geometry, sum-mode year-card geometry, shared pager viewport, active primary-color page indicator, Page 2 KPI/donut layout, single-category behavior, focused-month reuse, and three checked-in visual baselines under `test/stats/goldens/`.
- `test/stats/stats_category_scope_series_test.dart` locks the single canonical expense-score dataflow: period/category/vendor scope, raw per-day expense aggregation, daily threshold, unsmoothed 1-12 samples or 31-day rolling window plus EMA, pressure, then score. Record-level display filtering does not create a second score calculation.
- Final review regressions lock fixed 5 000 Ft threshold snapping, active-scope maximum clamping, live snapshot-sheet threshold synchronization, and income helper bars sourced from threshold-hit daily income samples rather than monthly totals.
- `test/shell/expt_fab_test.dart` locks horizontal snapshot stepping and the restored vertical threshold joystick bands: slow `1x`, medium `2x`, fast `6x`, positive above the activation point and negative below it. `StatsPageController` and shell widget tests verify the stats-only wiring.
- Fresh post-review stats suite: `+89 All tests passed!`; FAB joystick suite: `+4 All tests passed!`.
- `test/stats/stats_snapshot_native_repository_test.dart` and Android DAO/migration tests cover the structured MethodChannel payload, normalized Room tables, include masks, ordering, and additive `10 -> 11` migration. The Android tests still require GitHub Actions because local ARM64 AAPT2 cannot start in Termux.
- All four prototype static acceptance scripts pass: common Page 1, final Page 2, sum-mode Page 1, and snapshot-mode logic.
- Fresh post-review analyzer result: `No issues found! (ran in 64.2s)`.
- `git diff --check` passes.

GitHub Actions verification for commit `8a61e720605998f751a9f53133beae3c76d532b6`:

- Run: `https://github.com/elizerpist/exptv2/actions/runs/29153051207`
- Result: `success`.
- Successful steps include Dart analyze, the complete Flutter suite, all 88 Android unit tests, Room v10 -> v11 migration validation, debug APK build, and release publication.
- Published APK: `https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug-8a61e72.apk`.

Every requirement row is now `DONE`; the feature package satisfies the completion rule above.
