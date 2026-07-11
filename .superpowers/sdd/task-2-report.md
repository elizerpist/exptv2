# Task 2 Report: Common Stats Header And Navigation

## Scope And Authority

- Task brief: `.superpowers/sdd/task-2-brief.md`
- Plan: `docs/superpowers/plans/2026-07-11-commonstats-full-bugfix.md`, Task 2 and Global Constraints
- Checklist: `docs/superpowers/checklists/commonstats.md`
- Canonical period label: `TransactionStore.activePeriodLabel`
- Visual references inspected:
  - `docs/prototypes/stats_common_2025_final_0710.html`
  - `docs/prototypes/stats_common_2025_acceptance.md`
  - `docs/prototypes/stats_common_2025_stat_page_2_final_0710.html`
  - `docs/prototypes/stats_common_2025_stat_page_2_acceptance.md`
  - `docs/prototypes/stats_sum_mode_page1_yearcards.html`
  - `docs/prototypes/stats_sum_mode_page1_yearcards_acceptance.md`
- Override rule: the later commonstats checklist controls white year cards and chevron-only Page 2 navigation; horizontal content swipes recall snapshots only.

## Acceptance Checklist

| Requirement ID | Source | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| `COMMONSTATS-BUG-001` | Checklist row 001; later correction over sum HTML | `_StatsSumYearCards` | Every sum-view year card uses a white body surface. | Widget decoration assertion and `stats_sum_year_cards.png` golden. | `DONE` |
| `COMMONSTATS-BUG-002` | Checklist row 002; `TransactionStore.activePeriodLabel` | Stats `SummaryPill` | Period copy exactly matches the main menu: `Sum`, `2026`, `Január 2026`; no type/scope suffix. | Widget state test across all-time, year, and month. | `DONE` |
| `COMMONSTATS-BUG-003` | Checklist row 003 | Year/month tap handlers | Year-card body opens the selected year and its month-card grid; a month card then opens that month. | End-to-end widget tap test with store-state assertions. | `DONE` |
| `COMMONSTATS-BUG-005` | Checklist row 005 as corrected by 018 | Page switch transition | Page 2 open/close uses a bounded, uninterrupted slide transition and cached render frame. | Widget transition-position assertions, focused suite, frame-cache regression. | `DONE` |
| `COMMONSTATS-BUG-006` | Checklist row 006; main-menu `_TransactionListHeader` | `_StatsPageHeader` | Filtered count header is 28 px high, padded 24/4/24/0, centered 12 px gray text, above scroll content. | Widget geometry/style comparison assertions. | `DONE` |
| `COMMONSTATS-BUG-007` | Checklist row 007; Page 2 HTML dot dimensions | `_StatsPageHeader`, `_StatsPageIndicator` | Exactly one floating two-dot indicator exists; active width animates 18 to 6 and inactive 6 to 18 without moving during page scroll. | Widget count, intermediate-width, and scroll-position tests. | `DONE` |
| `COMMONSTATS-BUG-018` | Checklist row 018, overrides old swipe spec | `_StatsPageSwitcher`, content gesture surface | Left/right content drag recalls previous/next snapshot only and never opens Page 2; empty snapshots are a safe no-op; right-edge chevron alone opens/closes Page 2 from approximately viewport midpoint. | Gesture tests with repository fixtures, empty repository, chevron position and slide assertions. | `DONE` |
| `TASK2-VSCROLL` | Task brief | Page 1 and Page 2 content wrappers | Both pages preserve independent vertical scrolling. | Drag/scroll offset tests on both pages. | `DONE` |
| `TASK2-REPAINT` | Task brief | `_StatsPageSwitcher` children | Page 1 and Page 2 are isolated by keyed `RepaintBoundary` widgets. | Widget tree assertions. | `DONE` |

## Root Cause

The existing `PageView` owns horizontal gestures and embeds a separate indicator in each page. That structure makes snapshot-only horizontal gestures impossible, duplicates the indicator, and ties it to each page's scroll/content tree. The stats `SummaryPill` also builds its own type-qualified label instead of consuming the canonical store label, and sum year cards still use the older gray HTML surface.

## TDD Evidence

### RED

- Canonical period label: `flutter test test/stats/stats_page_test.dart --plain-name "stats period label exactly mirrors the main menu period label"` failed in 4 seconds because `Sum` had zero matching widgets.
- White sum year cards: `flutter test test/stats/stats_ui_reference_test.dart --plain-name "sum mode uses 154px two-column year cards with 70px month grid"` failed in 5 seconds with actual `AppColors.gray50` against expected `AppColors.white`.
- Explicit page switcher: `flutter test test/stats/stats_page_test.dart --plain-name "right-edge chevron opens and closes Page 2 with bounded slide"` failed in 13 seconds because `stats-content-switcher` did not exist.
- Review regression RED: the strengthened lower-grid tap test failed because tapping `stats-year-month-cell-2025-1` produced `Január 2025` instead of the required year state `2025`.
- An earlier runner attempt was intentionally not counted as RED: the test setup awaited `TransactionStore.setSummary*` and stalled. It was corrected to the repository's established `unawaited(...)` plus bounded-pump pattern before the valid RED runs above.

### GREEN

- Focused behavior tests passed individually for exact labels, white year cards, drilldown, count geometry, snapshot swipes, empty-snapshot no-op, chevron transition, and floating indicator/vertical scrolling.
- Full widget/reference verification:

  ```text
  flutter test --no-pub test/stats/stats_page_test.dart test/stats/stats_ui_reference_test.dart
  01:27 +47: All tests passed!
  ```

- Focused analyzer verification:

  ```text
  flutter analyze --no-pub lib/features/stats/stats_page.dart test/stats/stats_page_test.dart test/stats/stats_ui_reference_test.dart
  No issues found! (ran in 19.4s)
  ```

- All Flutter commands ran through Ubuntu proot. No APK build, push, or workflow run occurred.

## Screenshot And Golden Evidence

- Updated and directly inspected `test/stats/goldens/stats_sum_year_cards.png`: both year-card bodies are white; the selected card keeps the cyan border/heat treatment.
- The fixed 28 px header changes the full-page geometry, so the two affected existing baselines were also regenerated and directly inspected:
  - `test/stats/goldens/stats_year_page1.png`
  - `test/stats/goldens/stats_page2.png`
- Full reference suite passed against all three regenerated images.

## Self-Review

- Canonical score/filter construction in `_resolveRenderFrame` was not changed. Page transitions continue to resolve the Task 1 cache and the existing frame-reuse widget test remains green.
- `PageView` and `PageController` are absent from the production page. Exactly one `_StatsPageIndicator` is constructed, inside the fixed `_StatsPageHeader`.
- Horizontal drag-end has one route: velocity direction to `_stepSnapshot`. Snapshot swipe recall calls `_applySnapshot(..., applyPageIndex: false)`, so even snapshots that store Page 2 cannot open it through a swipe. Direct snapshot-card recall retains the existing stored-page behavior.
- `_StatsPageSwitcher` uses a 220 ms bounded `AnimatedSwitcher`/`SlideTransition`; Page 2 enters from the right and returns to the right on close. Chevron geometry is fixed to the right edge and vertically centered in the content viewport.
- Page 1 and Page 2 are keyed `RepaintBoundary` children. Both scroll positions were advanced in tests while the fixed header position remained unchanged.
- Main-menu count geometry was copied exactly: 28 px height, `EdgeInsets.fromLTRB(24, 4, 24, 0)`, gray500 12 px/700 centered count copy.
- Scope stayed limited to stats page/tests/goldens/report. Existing unrelated `color_lab` and untracked planning/checklist files were not edited or staged.
- Independent review reported two Important and one Minor concern:
  - Important, confirmed and fixed: nested sum-year month cells bypassed the year view. Their inner `GestureDetector`/month callback was removed, and the keyed visual cells now delegate the pointer to the enclosing year-card gesture. The lower-grid regression test went RED then GREEN.
  - Important, not reproduced: reviewer inferred the indicator was centered from golden pixels. Direct widget geometry proves its right edge equals header right minus the required 24 px padding; the assertion is now explicit and green.
  - Minor, fixed in tests: close transition now asserts Page 2 has moved right at the bounded 90 ms midpoint before it is removed at 240 ms.
- Post-review focused tests passed, followed by the fresh 47-test full run and clean analyzer result above.

## Commit

Local commit subject: `fix(stats): correct header and page navigation`. The final SHA is reported in the Task 2 handoff because this report is part of that commit.
