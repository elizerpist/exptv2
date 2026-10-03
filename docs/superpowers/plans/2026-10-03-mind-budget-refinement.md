# Mind + Budget Presentation Refinement Implementation Plan

> **For agentic workers:** Execute inline because the Mind preference migration,
> its persisted adapter, and its viewports are sequentially coupled; the Balance
> savings component must also consume the existing Budget ring primitive.

**Goal:** Deliver the approved combined Mind and Budget presentation refinement
from application baseline `4cb562ced2db` without changing financial admission,
range filtering, Query ownership, or unrelated modes.

**Architecture:** `MindYearHeatmapPresentationSettings` remains the sole Mind
presentation authority.  Its former 4×3 boolean becomes the one three-state
monthly-amount presentation enum, persisted through the existing dashboard
preferences adapter with a legacy boolean migration.  The Year viewport owns
only ephemeral veil-open state. `BalancePresentationSettings` remains the
single session presentation owner for Savings display mode; one reusable
Savings card reuses `BudgetCategoryAvatarSelectionChrome`, the existing Budget
3D ring and material primitive, without an avatar or new painter.

**Tech Stack:** Flutter/Dart, Android SharedPreferences method channel,
existing widget/golden tests, GitHub Actions Human Diagnostic APK.

## Architecture card

| State / mechanism | Existing or changed owner | Write path | Reuse boundary |
| --- | --- | --- | --- |
| Mind Year grid and amount presentation | `MindYearHeatmapPresentationController` | Settings radio → controller → preferences adapter | `MindYearHeatmapViewport` renders immutable frames only |
| Year veil visibility | `MindYearHeatmapViewport` state | month-region tap / veil tap | ephemeral UI state; never persisted or financial |
| Mind Day selector visibility | `MindYearHeatmapPresentationController` | Settings switch → controller | both Day renderers receive the one boolean |
| Mind monthly totals | resident `MindYearHeatmapFrame` | existing amount-preview publication | compact formatter and existing day frame only |
| Month/SUM header geometry | shared `MindSumYearBandHeader` geometry helper | no data write | Month consumes the same layout constants/style |
| Budget borders | `DashboardBorderController` | existing settings tuner | add a Budget-specific header surface; retain content surface |
| Savings display mode | `BalancePresentationController` | Savings-card tap → existing controller | one card component for SUM/Month/Year |
| Savings 3D ring | `BudgetCategoryAvatarSelectionChrome` | immutable percentage input | no duplicate Material/progress painter |

## Acceptance checklist

| ID | Requirement source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MY-01 | Parts 1.1–1.3 | `mind_year_heatmap_viewport.dart`, tuner | no Year-card 3×4/4×3/2×6 chooser, space, or hit target; Settings alone selects all layouts | viewport/tuner widget test | DONE |
| MY-02 | Parts 2, 4 | Mind presentation settings, preferences stores, `MainActivity.kt` | canonical hidden/inline/veil enum is revisioned/equatable/persisted; legacy boolean restores as hidden/inline | unit + adapter tests | DONE |
| MY-03 | Parts 3–4 | Year viewport/month group | old day-cell information card and targets are absent; inline totals use the current resident slider-filtered month frame in the same muted mini-header row | widget geometry/live-frame test | DONE |
| MY-04 | Part 5 | Year viewport | any month opens one all-month neutral translucent veil; white labels/totals update from frame; veil tap closes and absorbs input | widget interaction test + 4×3 veil golden | DONE |
| MM-01 | Part 6 | temporal viewports, Sum header primitive | Month `Összesen` header shares SUM year-header metrics/alignment; heatmap remains wholly non-scrollable and footer-visible | geometry/widget test | DONE |
| MD-01 | Part 7 | Mind settings, both Day views | existing two-button selector has one visibility setting, default off, and no trailing reservation when hidden | widget/settings test | DONE |
| MH-01 | Part 8 | header chart + trend layout/painter | selected temporal label is beneath the plot, inside header bottom inset, and crosshair reaches it | chart geometry/golden test | DONE |
| MH-02 | Part 9 | header visual tuning | fresh Mind header opacity is 75%; existing configured values are unchanged | unit test | DONE |
| BU-01 | Part 10 | border profile + Budget header shell | fresh Budget header and content borders are off while corresponding tuner controls still work | profile/widget test | DONE |
| BS-01 | Parts 11–13, 16–17 | Balance presentation settings and extended-sheet cards | SUM/Month/Year use one shared Savings component and controller-owned Percentage/Amount mode; card tap toggles it | settings/widget tests + shared routing test | DONE |
| BS-02 | Parts 14–15 | shared Savings component | percentage mode uses `BudgetCategoryAvatarSelectionChrome` with percentage center text, not an avatar or generic circle | structural/widget + golden test | DONE |
| RG-01 | Parts 18–19 | affected Mind/Budget tests and boundaries | slider, Year grids, Day views, Budget avatar ring/limits, Balance, Query semantics retain coverage | 126 focused Mind tests, Budget/boundary suites, 434-test fast suite | DONE |
| REL-01 | Parts 20–21 | changed source/tests + CI | formatting, analysis, complete checklist re-read, pushed production commit, exact Human APK download/hash | `d15a150a`; local analyzer/434-test suite; GitHub run 37125699829; verified Human APK | DONE |

## Implementation order

1. Add red settings/persistence tests for the Mind enum, Day selector visibility,
   Mind default opacity, and Budget border defaults; run to prove baseline
   failures.
2. Implement the Mind presentation-state migration and persistence adapter,
   then make those settings tests green.
3. Add red Year viewport tests for hidden/inline/veil, retired day info card,
   and layout-only Settings routing; implement one veil renderer over the
   existing body and make them green.
4. Add red geometry tests for Month/SUM header sharing and the header selected
   label/crosshair; extract only the neutral shared layout measures needed and
   make them green.
5. Add red Savings/Budget tests; extend the existing Balance presentation
   controller, replace divergent Savings cards with one component that reuses
   the approved Budget selection chrome, and make them green.
6. Run focused regression suites, visual evidence/goldens for modified states,
   project validation, commit, push, and obtain the exact online Human APK.

## Delivery evidence

- Application commit: `d15a150aab042d6916d79a5715a159ea4b1dabb9`.
- GitHub Actions run `37125699829`: `test-flutter`, `test-core`, and
  `build-human-diagnostic-apk` succeeded.
- Downloaded Human Diagnostic APK:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_d15a150.apk`
  (89,341,559 bytes; SHA-256
  `b53809bf883652f7d77764f7f9b9de251da5153fc017d6bb46e8f7772e5053de`).
- ZIP integrity passed and `libapp.so` contains the exact application SHA.
