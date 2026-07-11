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
| SCR-LANG-01 | `2026-07-10-stat-common-render-page1-2-final-spec.md` | `lib/features/stats/**` | Page 1 and Page 2 stats UI copy is Hungarian except `Expense Tracker` | Widget tests + source scan + visual comparison | PARTIAL |
| SCR-STRUCT-01 | same | `lib/features/stats/stats_page.dart` | Order is header/FastInfo, type toggle, SummaryPill, SearchPill, swipe viewport | Widget test + screenshot/manual comparison | PARTIAL |
| SCR-AREA-01 | same | `StatsPage` layout | Page 1/Page 2 content shares fixed viewport between SearchPill and bottom nav | Widget test + screenshot/manual comparison | PARTIAL |
| SCR-MODE-01 | same | `StatsRenderMode`, threshold sheet, `StatsPage` | Old `Kategória scope` / `Hózárás` / `Hőtérkép` UI selector is removed; only common render remains | Widget test + code inspection | DONE |
| SCR-SWIPE-01 | same | `StatsPage` content pager | Page 1 and Page 2 are horizontal swipe pages, not vertical stacks | Widget test | DONE |
| SCR-FAB-01 | same | `ExptShell`, `ExptFab`, `StatsPage` | Stats-tab FAB uses threshold/joystick icon and opens stats threshold/snapshot sheet; home tab keeps plus/add transaction | Widget test + code inspection | PARTIAL |
| SCR-SHEET-01 | same | Threshold bottom sheet | Threshold sheet has slider + numeric input and no render-mode buttons | Widget test | DONE |
| SCR-SNAPSHOT-01 | same | Snapshot model/repository/sheet | FAB sheet contains snapshot editor row with camera add card, tap-select recall, and snapshot state fields | Model + widget tests | PARTIAL |
| SCR-SNAPSHOT-02 | same | Snapshot add dialog | Add-new snapshot opens centered dialog with name input and include-mask checkboxes | Widget test | DONE |
| SCR-SNAPSHOT-03 | same | Snapshot repository/storage | Snapshots persist in local repository/table with include-mask fields | Repository/model tests | NOT DONE |
| SCR-SEARCH-01 | same | `StatsPage`, `SearchPill`, shell vendor sheet | Stats menu includes SearchPill and vendor selector sheet support | Widget test | DONE |
| SCR-VENDOR-01 | same | Stats filtering/model | Vendor/source filters affect header score, FastInfo, summary, Page 1, Page 2 | Model + widget tests | PARTIAL |
| SCR-MAG-01 | same | Header/magnet stats model | Header score/magnet uses approved score bands and Hungarian copy | Model + widget/screenshot comparison | PARTIAL |
| SCR-FAST-01 | same | `stats_fast_info_graph.dart`, data helpers | Expense/income FastInfo graph math and labels match approved common render | Model + widget/painter tests + visual comparison | PARTIAL |
| SCR-MONTH-01 | same | `stats_year_calendar.dart` | Page 1 year-mode month cards/day cells match approved HTML behavior | Painter/widget tests + visual comparison | PARTIAL |
| SCR-SUM-01 | same | New/extended sum-mode widgets/data | Sum mode year cards and month cells match authoritative sum-mode HTML | Model + widget/painter tests + visual comparison | PARTIAL |
| SCR-SUM-02 | same | Page 2 routing | Sum mode reuses the same Page 2 layout with sum-mode data scope | Widget/model tests + code inspection | PARTIAL |
| SCR-MODES-01 | same | Stats layout state | Page 1 supports `sum`, `year`, `month` layout modes | Widget/state tests | DONE |
| SCR-NAV-01 | same | SummaryPill integration | SummaryPill navigates `sum/year/month` layout state | Widget/state tests | DONE |
| SCR-NAV-02 | same | Page 1 card taps | Year/month card taps update active period and SummaryPill state | Widget/state tests | DONE |
| SCR-SYNC-01 | same | Shared period state | Main menu and stats share layoutMode/activeYear/activeMonth | State/integration tests | NOT DONE |
| SCR-MONTHFOCUS-01 | same | Month mode content | Month mode shows enlarged single month card with top back button | Widget/painter tests + visual comparison | PARTIAL |
| SCR-MONTH-AXIS-01 | same | FastInfo axis helpers | Month-mode FastInfo keeps all day points and thins day labels dynamically | Model tests | NOT DONE |
| SCR-PAGE2-01 | same | Page 2 widget/data | Page 2 KPI/category/vendor layout matches final Page 2 HTML | Widget/model tests + visual comparison | PARTIAL |
| SCR-PAGE2-SCOPE-01 | same | Page 2 filtering | Same Page 2 component receives sum/year/month filtered datasets | Model tests | PARTIAL |
| SCR-THRESH-01 | same | Stats filtering | Threshold filters visible records consistently across all stats | Model tests | DONE |
| SCR-WARN-01 | same | Page 2 warning | Threshold warning appears in all three approved places with `X alatti tranzakciók rejtve` | Widget test + visual comparison | PARTIAL |
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

2026-07-11 targeted implementation verification:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Result: `No issues found!`

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Result: `+759 All tests passed!`
