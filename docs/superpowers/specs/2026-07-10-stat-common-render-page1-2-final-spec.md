# Stat Common Render Page1-2 Spec

## Source Of Truth

This spec merges the approved requirements from the final common stats HTML prototypes into one Flutter implementation target.

Authoritative visual and behavior references:

- Page 1 / month-card view: `docs/prototypes/stats_common_2025_final_0710.html`
- Page 1 checklist: `docs/prototypes/stats_common_2025_acceptance.md`
- Page 2 / yearly summary view: `docs/prototypes/stats_common_2025_stat_page_2_final_0710.html`
- Page 2 checklist: `docs/prototypes/stats_common_2025_stat_page_2_acceptance.md`
- Sum mode Page 1 / year-card view: `docs/prototypes/stats_sum_mode_page1_yearcards.html`
- Sum mode Page 1 checklist: `docs/prototypes/stats_sum_mode_page1_yearcards_acceptance.md`

These HTML files and checklists are mandatory implementation references, not inspiration. Before implementing, reviewing, or marking this work complete, re-open every applicable HTML file above and compare the Flutter result against it for layout, colors, spacing, chart geometry, card rendering, magnet behavior, formulas, state transitions, and visible copy.

The approved Flutter implementation must match the HTML references pixel-for-pixel where they define the same UI. Where the references overlap but differ because Page 2 was finalized later, Page 2's Hungarian copy wins; Page 1's layout and month-card behavior still remain authoritative for normal Page 1.

The sum mode Page 1 HTML is not a mockup. Treat `stats_sum_mode_page1_yearcards.html` exactly like the annual Page 1 and Page 2 final HTML files: it is an authoritative, mandatory, pixel/reference implementation target. Do not reinterpret it as an idea, wireframe, alternative concept, or approximate layout. The Flutter sum mode Page 1 must match that HTML for layout, colors, spacing, year-card geometry, month-cell geometry, cell spacing, active-year interaction, threshold behavior, category/vendor filtering behavior, FastInfo graph behavior, magnet/score behavior, and formulas. Any visual or behavioral deviation from that HTML is a failed implementation unless the user explicitly approves the specific deviation after seeing it.

Sum mode does not need a separate Page 2 HTML. Page 2 is the same approved Page 2 yearly/monthly summary surface everywhere. In sum mode, Page 2 must reuse `stats_common_2025_stat_page_2_final_0710.html` and only change the data scope/calculation input; do not design or invent a separate sum-mode Page 2 surface.

Snapshot mode logic/layout mockup:

- `docs/prototypes/stats_common_2025_snapshot_mode.html`
- `docs/prototypes/stats_common_2025_snapshot_mode_acceptance.md`

The snapshot HTML is a mockup only. It is not a visual/design reference and must not override the approved Page 1/Page 2 design, colors, typography, spacing, card styling, magnet styling, or graph styling. Use it only to understand the logical layout: where snapshot controls live, what each control does, what state a snapshot stores, and how FAB drag/tap behavior works.

## Language Rules

The stats menu UI must be Hungarian on Page 1 and Page 2.

The only allowed English visible text in this feature is the app/brand name `Expense Tracker`. All other stats-menu labels, chart titles, legends, warnings, controls, sheets, tooltips, empty states, and page labels must be Hungarian.

The Page 1 HTML still contains some English chart copy. During Flutter implementation, keep the same chart math and geometry but use the approved Hungarian equivalents from Page 2:

- `Income vs spend` -> `Bevétel vs kiadás`
- `Covers spend` -> `Fedezi a kiadást`
- `Income short` -> `Kevés bevétel`
- `Break-even` -> `Nullszaldó`
- `Scope score` / `Scope score · Soft band` -> `Szűrés pontszám`
- `Threshold excess` -> `Küszöb feletti többlet`

## Scope

Build one common stats render mode with two horizontal swipe pages and three Page 1 layout modes:

- Page 1 `sum` mode: the approved year-card common stats view from `stats_sum_mode_page1_yearcards.html`.
- Page 1 `year` mode: the approved month-card common stats view from `stats_common_2025_final_0710.html`.
- Page 1 `month` mode: a focused/enlarged single month card. There is no separate HTML prototype for this mode; it reuses the exact Page 1 year-mode month-card logic, colors, day-cell heat behavior, threshold filtering, typography, and card language, but the content area contains only the selected month card.
- Page 2: the approved summary view from `stats_common_2025_stat_page_2_final_0710.html` in every mode.

Page 2 is not mode-specific visually. It is the same Page 2 component for `sum`, `year`, and `month`; only the data filter changes:

```text
layoutMode = sum   -> Page 2 receives the full selected summary period / multi-year aggregate input
layoutMode = year  -> Page 2 receives only the active year's transactions
layoutMode = month -> Page 2 receives only the active month's transactions
```

The Page 1 `month` mode does not need a separate HTML reference because its logic, colors, filters, and card/stat layouts are the same as the approved Page 1 year-mode month cards, with the data domain narrowed to one month.

Sum mode is not a return of the old multi-render-mode selector. It is a content-scope/Page 1 presentation state inside the single common stats render mode. It must not expose `Kategória scope`, `Hózárás`, `Hőtérkép`, or any A/B/C graph concept selector. It uses the same shell, header, FastInfo area, type toggle, SummaryPill, SearchPill, category scope, vendor scope, threshold/FAB behavior, and swipe model as the normal common stats page; only Page 1's card surface changes from month cards to year cards exactly as defined by the sum mode HTML.

Remove the old multi-render-mode model from the user-facing stats menu. There must be no `Kategória scope` / `Hózárás` / `Hőtérkép` selector in the threshold bottom sheet or anywhere else in the stats UI. Internally the implementation may keep an enum only if it has a single `common` value and cannot expose old modes.

Budget/limit statistics are out of scope for this spec. They must not be mixed into the threshold-filtered Page 1/Page 2 common stats logic.

## Current App Areas

Expected implementation areas:

- `lib/features/stats/stats_page.dart`: shell structure, active type, summary scope, selected categories, vendor filters, threshold state, swipe page state, FAB threshold entry.
- `lib/features/stats/data/stats_year_data.dart`: common render data model, filtered records, month data, score inputs, summary metrics.
- `lib/features/stats/data/stats_category_scope_series.dart`: expense score series and income pattern score series, renamed or replaced by common-series models if needed.
- `lib/features/stats/widgets/stats_fast_info_graph.dart`: Page 1 FastInfo chart drawing, Hungarian legends, approved graph geometry.
- `lib/features/stats/widgets/stats_year_calendar.dart`: Page 1 month-card painter and day-cell rendering.
- New or extended stats widget/painter for sum mode Page 1 year cards, matching `stats_sum_mode_page1_yearcards.html` exactly.
- New or extracted stats widget: Page 2 yearly summary content, if keeping it out of `stats_page.dart` improves clarity.
- `lib/features/shell/expt_shell.dart`: pass the vendor sheet callback and route the stat-tab FAB to the threshold control instead of add transaction.
- `lib/features/shell/widgets/expt_fab.dart`: allow the stat-tab FAB to use the joystick/threshold icon instead of the plus icon.
- `lib/features/transactions/widgets/search_pill.dart`: reused by stats below the SummaryPill.
- `lib/features/transactions/transaction_home_page.dart` and `lib/features/shell/expt_shell.dart`: existing `VendorFilterPanel` and shell vendor sheet behavior should be reused, not duplicated.
- `lib/features/transactions/state/transaction_store.dart` and `lib/features/transactions/data/transaction_filter.dart`: existing search/vendor filter state should be the source for vendor filtering unless implementation explicitly extracts a stats-local wrapper with identical behavior.

## UI Structure

The stats menu vertical order is fixed:

1. Header card + FastInfo graph surface.
2. `Bevétel` / `Kiadás` type toggle.
3. `SummaryPill`.
4. `SearchPill`.
5. Horizontal swipe content area:
   - Page 1: year cards in `sum`, month-card grid in `year`, enlarged single month card in `month`.
   - Page 2: the same summary cards/panels, filtered by the active `layoutMode`.

The two pages must not be stacked vertically. Page 2 is reached by horizontal swipe. The header/FastInfo, type toggle, SummaryPill, SearchPill, category scope, vendor scope, and threshold state are shared by both pages.

The horizontal swipe content area has a fixed viewport: it starts immediately below the SearchPill and ends at the top edge of the bottom navigation. Page 1 year cards, month cards, focused month card, and Page 2 statistics must all render inside this same area. This area has the same role and available screen space as the transaction home menu's logbox area; if content is taller than the viewport, the page content scrolls inside this area rather than pushing below the bottom nav or changing the header/search layout.

In `month` mode, the same viewport is reused: Page 1 shows only the selected month card enlarged inside this area, and Page 2 shows only that selected month's statistics inside this area. The top of the focused month content area must include a clear back button that returns to the previous `year` scope without clearing active type, category scope, vendor scope, threshold, SummaryPill state, or FastInfo reveal state. The header, FastInfo, type toggle, SummaryPill, SearchPill, category scope, vendor scope, and threshold controls remain in the same positions.

Page indicators should make the active swipe page clear. Page 2's approved dot treatment in the HTML is the reference. Page 1 should use the same indicator language, adapted so the first dot is active.

The SummaryPill is the primary visible navigation control for `sum`, `year`, and `month`, using the same mental model as the main menu's SummaryPill. Selecting a SummaryPill state changes the stats `layoutMode` and active period:

```text
SummaryPill sum   -> layoutMode = sum
SummaryPill year  -> layoutMode = year, activeYear = selected year
SummaryPill month -> layoutMode = month, activeYear + activeMonth = selected month
```

Card taps are secondary shortcuts into the same state, not a separate navigation model:

- in `sum` mode, tapping a year card sets `layoutMode = year` and `activeYear = tapped year`;
- in `sum` mode, tapping a month cell inside a year card sets `layoutMode = month`, `activeYear = that year`, and `activeMonth = that month`;
- in `year` mode, tapping a month card sets `layoutMode = month` and `activeMonth = tapped month`;
- these taps update the SummaryPill selection immediately.

The main menu SummaryPill mode and the stats SummaryPill mode must share the same period/layout state. If the user changes `sum/year/month` in the main menu and then enters stats, stats opens in the same mode. If the user changes `sum/year/month` in stats and returns to the main menu, the main menu reflects that same mode. This synchronization applies to active year and active month as well as the mode.

## Common Filters

All stats calculations are driven by the same active filter state:

```text
activeType = income | expense
period = SummaryPill-selected period
layoutMode = sum | year | month
activeYear = selected year when layoutMode is year or month
activeMonth = selected month when layoutMode is month
categoryScope = selected active-type categories, normalized to ALL when empty or all selected
vendorScope = selected vendors/sources from SearchPill vendor selector
threshold = joystick/FAB-selected Ft amount, stepped by 5000 Ft
```

The filters combine with AND:

```text
record is visible when:
  record.type == activeType
  record.date is inside the active stats period
  layoutMode == sum OR record.year == activeYear
  layoutMode != month OR record.month == activeMonth
  record.categoryId is inside categoryScope
  vendorScope is empty OR record.displayMerchant is inside vendorScope
  abs(record.amount) >= threshold
```

For score and chart math, use the same threshold-visible records unless a section below explicitly says "no-signal" rather than zero.

Category scope remains available from the header/menu control. Vendor scope is available from the `SearchPill` vendor selector sheet. Selected vendor filters must be visible as removable SearchPill capsules, the same mental model as the transaction home page.

Changing type between `Bevétel` and `Kiadás` must update available categories, vendor/source names, chart color semantics, magnet score, summary value, Page 1 month cards or sum-mode year cards, and Page 2 yearly summary. Threshold should keep its numeric value only if still inside the active observed range; otherwise clamp to the active range.

## SearchPill And Vendor Sheet

The stats menu must include the same SearchPill capability that already exists on the transaction side:

- free-text query input,
- category filter capsules where applicable,
- vendor/source filter capsules,
- vendor selector sheet opened from the SearchPill icon,
- clear actions on each capsule.

The vendor selector sheet must filter stats by vendor/source, not only display vendor names. Applying vendors must recompute:

- header score and magnet,
- FastInfo graphs,
- SummaryPill value,
- Page 1 month cards/day cells or sum-mode year cards/month cells,
- Page 2 KPI boxes,
- Page 2 category panel,
- Page 2 Top 5 vendor/source panel.

For income mode, the same UI should use "forrás" language where the user sees copy, but it may still use the existing merchant/vendor field internally.

## FAB Replaces Joystick Button

The separate joystick button is removed from the stats page. On the stats tab, the existing floating action button becomes the threshold joystick entry point.

The stats-tab FAB:

- does not show the plus icon;
- shows a clear joystick/threshold/tune icon;
- keeps the same visual size, surface style, press feedback, position, and theme behavior as the existing FAB;
- opens the threshold bottom sheet on tap;
- steps threshold exactly like the current joystick/slider control;
- updates all shared stats state live;
- does not open add-transaction while the active tab is stats.

The transaction home tab keeps the normal plus FAB behavior. This FAB behavior change is stats-tab-specific.

## Threshold Bottom Sheet

When the user taps the stats-tab FAB, the combined snapshot/threshold bottom sheet opens.

Without snapshot mode, the threshold sheet contains only:

- grabber/handle,
- current threshold label,
- threshold slider,
- numeric text input with `Ft` suffix.

With snapshot mode enabled, the same FAB sheet also contains the snapshot editor above the threshold controls:

- compact `Mentett nézetek` header,
- horizontally scrollable snapshot card row,
- first row item is a camera-icon add-new snapshot card,
- saved snapshot cards load on tap-select,
- no previous/next arrow navigation buttons,
- threshold slider and numeric input remain under the snapshot card row.

The render-mode selector row is removed. Old render-mode buttons and labels must not appear.

Threshold behavior:

```text
step = 5000 Ft
min = 0 Ft
max = adaptive observed active-scope maximum rounded up to 5000 Ft
manual input = digits only, snapped to nearest 5000 Ft, clamped to max
slider input = same snapped/clamped value
```

Threshold means "hide transactions below X Ft" for visible stats. At threshold 0, all scoped records are visible.

## Snapshot Mode

Snapshot mode is a fast recall layer for the common stats state. It does not introduce a new render mode and does not change Page 1/Page 2 visual design.

Logical mockup:

- `docs/prototypes/stats_common_2025_snapshot_mode.html`

This file is a functional/layout mockup only. It shows what lives where and what each control does. Do not copy its visual styling into the app unless that styling already matches the approved Page 1/Page 2 references.

Each snapshot stores:

```text
name
categoryScope
vendorFilter
activeType = income | expense
threshold
layoutMode = sum | year | month
activeYear
activeMonth
pageIndex = 0 | 1
```

Snapshot storage is selective. A saved snapshot has a checkbox-driven include mask that says which current settings will be applied when the snapshot is loaded. Unchecked fields are stored as absent and must not overwrite the user's current state on recall.

Snapshot data should be stored in a real local snapshot repository/database/table rather than an ad hoc encoded string. Suggested model:

```text
StatsSnapshot
  id
  name
  createdAt
  updatedAt
  includeCategoryScope: bool
  includeVendorScope: bool
  includeActiveType: bool
  includeThreshold: bool
  includeLayoutMode: bool
  includePageIndex: bool
  categoryScopeIds?: List<String>
  vendorScopeIdsOrNames?: List<String>
  activeType?: income | expense
  threshold?: int
  layoutMode?: sum | year | month
  activeYear?: int
  activeMonth?: int
  pageIndex?: 0 | 1
```

Snapshot recall:

- tapping a snapshot card instantly applies only the checked/stored fields;
- checked `categoryScope` applies the stored category selection;
- checked `vendorScope` applies the stored vendor/source selection;
- checked `activeType` applies income/expense;
- checked `threshold` applies the stored threshold;
- checked `layoutMode` applies `sum`, `year`, or `month` plus the stored active year/month needed by that mode;
- checked `pageIndex` applies Page 1 or Page 2;
- unchecked fields leave the current state untouched;
- recall recomputes header score/magnet, FastInfo, SummaryPill, SearchPill capsules, Page 1, and Page 2 immediately;
- snapshot recall must not expose old render modes.

Snapshot editor placement:

- the snapshot editor lives inside the stats-tab FAB bottom sheet;
- it must not occupy permanent space between SearchPill and the Page 1/Page 2 content viewport;
- the content viewport remains the SearchPill-bottom-to-bottom-nav-top area defined in this spec.

Snapshot card row:

- horizontal swipe scroll only;
- tap-select loads a snapshot;
- no arrow navigator buttons;
- the first card is an add-new snapshot card;
- add-new snapshot card uses a camera icon;
- tapping the add-new snapshot card opens a centered modal dialog, not another bottom sheet.

Add-new snapshot dialog:

- appears centered and focused over a dimmed background, like a normal dialog;
- contains a snapshot name text input;
- contains checkboxes for which current settings to save/load later;
- checkbox options include category scope, vendor scope when active, active income/expense type, threshold, layout mode (`sum`, `year`, `month`), and current page (`Page 1` or `Page 2`);
- for layout mode, saving `month` also stores the active year and active month; saving `year` stores the active year; saving `sum` stores no specific focused year/month unless another checked field needs it;
- saving creates a snapshot record using the checkbox include mask and the current state values for checked fields.

FAB joystick behavior:

- tapping the FAB opens/closes the combined snapshot/threshold sheet;
- dragging the FAB left or right steps through snapshots instantly;
- dragging right steps to the next snapshot;
- dragging left steps to the previous snapshot;
- stepping is an infinite loop: after the last snapshot comes the first, and before the first comes the last;
- every drag step emits a tick feedback signal;
- after a drag step, the same pointer gesture must not accidentally open the sheet.

## Header And Magnet

The header card, magnet strip, score label, score value, scope chip, and FastInfo reveal behavior must visually match the two approved HTML references.

Visible header copy must be Hungarian:

- app/brand may be `Expense Tracker`;
- score label should be `SZŰRÉS PONTSZÁM`;
- score value is shown as `N/100`;
- scope chip shows `MIND` for all categories or selected count/name state consistent with the reference.

Magnet rules:

- both income and expense use the approved soft score magnet design;
- marker position is `score / 100`;
- marker color uses score bands:
  - below 45: red/bad,
  - 45 to below 60: orange/neutral,
  - 60 and above: green/good;
- the magnet must not display old `HÓZÁRÁS`, `HEATMAP`, or drift-mode semantics.

## Page 1 Month Cards

Page 1 is the common month-card render from `stats_common_2025_final_0710.html`.

The month-card layout must match the HTML pixel-for-pixel:

- neutral month-card background from the accepted stats card color;
- no red/green month-card background tint;
- month name at the approved position;
- primary amount is the monthly closing/balance value;
- secondary amount is the threshold-filtered active scope total for the selected type;
- same card size, grid rhythm, calendar day positions, typography, shadows, and radius as the reference.

Day-cell rules:

- no red/green dot markers;
- below threshold: no visible heat marker;
- threshold hit: heat fill opacity scales from 0.1 to 1.0 by filtered day amount;
- one selected category: day heat uses that category color;
- multiple/all categories: day heat uses the approved heatmap/common color.

The Page 1 content must continue to respond to income/expense, category scope, vendor scope, threshold, and summary period.

Tapping a Page 1 month card in `year` mode changes to `month` mode for that month. In `month` mode, Page 1 is not the 12-card year grid; it is the selected month card enlarged with the same month-card design, neutral background, day-cell heat behavior, threshold filtering, category coloring, and typography. A back button is shown at the top of the month-mode content and returns to the previous `year` mode without clearing active type, category scope, vendor scope, threshold, SummaryPill period, or FastInfo reveal state. The selected month's transactions are the only records passed to Page 1's focused month view, header score functions, FastInfo functions, SummaryPill value, SearchPill filtering, and Page 2 month-mode statistics.

## Page 1 Sum Mode Year Cards

Sum mode Page 1 is the year-card render from `stats_sum_mode_page1_yearcards.html`.

This section is intentionally stricter than normal prose. The implementation instruction is:

```text
Open stats_sum_mode_page1_yearcards.html.
Implement what that file does.
Do not redesign it.
Do not approximate it.
Do not treat it as a mockup.
Do not preserve the common shell while inventing a different year-card body.
Do not change chart/slider/magnet formulas unless the HTML already does.
```

The sum mode Page 1 layout must match the HTML pixel-for-pixel:

- same common shell above the card area as normal Page 1: FastInfo, header, magnet, type toggle, SummaryPill, SearchPill, category scope, vendor scope, threshold/FAB behavior;
- the month-card grid is replaced by year cards only in the Page 1 content area;
- year cards use the same card visual language as the HTML: neutral background, radius, shadow, typography, active-year treatment, amount placement, and scope-total row;
- each year card contains month cells, not day cells;
- month cells render as `6` columns by `2` rows;
- month-cell grid height, year-card height, labels, active color, heat opacity, and spacing must match the HTML;
- month-cell visible spacing must follow the day-cell spacing model from the annual HTML: no grid gap between cells, with the visible colored inset produced by `inset: 1px`;
- one selected category uses that category color; multiple/all categories use the common heatmap color;
- threshold changes must hide/show month-cell heat live;
- tapping a year card changes the active year without clearing active type, category scope, vendor scope, threshold, SummaryPill period, SearchPill state, or current swipe page.

The sum mode data/reference HTML currently builds 20 years of test transactions (`2006-2025`) so the implementation can be verified with long-range data. Production code must not hard-code those years; it must derive the available year list from the filtered transaction period. The behavior to preserve is the 20-year-capable rendering and graph labeling, not the literal test fixture dates.

Sum mode Page 2 is not a separate design. Do not create a special sum-mode Page 2. Page 2 uses the same approved summary layout from `stats_common_2025_stat_page_2_final_0710.html` and receives the current sum-mode data scope as input.

## Page 1 FastInfo Graphs

The FastInfo graph area must match the approved HTML geometry. Do not add more graph concepts or tabs. The old A/B/C/etc experiment UI is removed; the approved common view is the only Page 1 FastInfo view.

Expense mode:

- upper chart title: `1. Szűrés pontszám`;
- upper chart is the soft-band score line;
- legend: `rossz`, `semleges 50`, `jó`;
- endpoint badge shows the current score as `N/100`;
- lower chart title: `2. Küszöb feletti többlet`;
- lower chart uses the approved threshold-excess histogram.

Income mode:

- upper chart title: `Bevétel vs kiadás`;
- centerline layout with green bars above the line when threshold-visible income covers expense and red bars below the line when income is short;
- legend: `Fedezi a kiadást`, `Kevés bevétel`, `Nullszaldó`;
- lower chart title: `2. Küszöb feletti többlet`;
- lower chart uses the same threshold-excess function as expense, but sourced from income events and rendered green.

Income x-axis rule:

- the income upper and lower charts show only months where there is threshold-visible income pattern data;
- months without visible filtered income are omitted, not rendered as zero bars.

Expense FastInfo must remain the accepted expense chart. Income changes must not alter the expense chart.

Sum mode FastInfo x-axis rule:

- sum mode charts are adaptive by year, not by month;
- every available year remains an input data point/bar;
- x-axis labels are thinned only as labels, never by dropping data points;
- `<= 10` years: show every year label;
- `11-16` years: show first, last, and every second year label;
- `17-30` years: show first, last, and every 5-year tick;
- `30+` years: show first, last, and every 10-year tick;
- month names must not appear on the sum mode FastInfo x-axis.

Month mode FastInfo x-axis rule:

- month mode charts are adaptive by day, not by month or year;
- every day in the active month remains an input data point/bar, including 31-day months;
- x-axis labels are thinned only as labels, never by dropping day data points;
- `<= 10` days: show every day label;
- `11-16` days: show first, last, and every second day label;
- `17-31` days: show first, last, and every 5-day tick;
- `32+` days, if a custom period is ever supported: show first, last, and every 10-day tick;
- month names must not appear on the month mode FastInfo x-axis.

## Score Math

### Expense Score

Expense score is threshold-sensitive pressure score from the approved HTML `expenseScopeScoreSeries`.

Input:

```text
qualifyingAmount(day) =
  sum(abs(expense records on that day))
  after period + category + vendor filtering
  if day scoped amount >= threshold
  else 0
```

Graph domain:

```text
first qualifying day ... last qualifying day
```

No qualifying days:

```text
scoreLine = one neutral/high point at 100
kontrollScore = 100
helperAmountLine = empty
monthTicks = empty
```

For 1-12 hit days, use the small-sample unsmoothed behavior:

```text
amountMax = max(qualifyingAmount over hit days, 1)
score = clamp(100 - qualifyingAmount / amountMax * 100, 0, 100)
```

For more than 12 hit days:

```text
behaviorWindow = 31 days
halfWindow = 15 days
emaPeriod = clamp(round(22 - 0.45 * hitDayCount), 7, 18)

rollingOccurrence(day) = count of qualifying days inside centered 31-day window
rollingAmount(day) = sum of qualifying amounts inside centered 31-day window

smoothedOccurrence = EMA(rollingOccurrence, emaPeriod)
smoothedAmount = EMA(rollingAmount, emaPeriod)

occurrenceValue = smoothedOccurrence / max(smoothedOccurrence) * 100
amountValue = smoothedAmount / max(smoothedAmount) * 100
pressure = 0.5 * occurrenceValue + 0.5 * amountValue
score = clamp(100 - pressure, 0, 100)
kontrollScore = latest score
```

### Income Magnet Score

Income score is a pattern-trend score, not annual average and not missing-month penalty.

Principle:

```text
50 = own visible income pattern is stable
below 50 = visible observed pattern worsens
above 50 = visible observed pattern improves
```

Pattern inputs:

```text
incomeEventAmounts(month) =
  positive scoped income event/day amounts inside the month

visibleIncome(month, threshold) =
  sum(event amount where threshold == 0 OR event amount >= threshold)
```

Months with no threshold-visible income are no-signal, not zero-valued worsening months.

Score formula:

```text
patterns = observed active-scope income months
latest = last pattern

if no latest visible value:
  score = 50
  noSignal = true

previousVisibleValues = visible values before latest, filtered to > 0

if no previous visible values:
  score = 50
  noSignal = true

previousWindowSize = min(3, previousVisibleValues.length)
previousPatternAvg = average(last previousWindowSize previous visible values)
recentPatternAvg = latest.visibleValue
baseline = max(1, previousPatternAvg, median(previousVisibleValues + recentPatternAvg))
trendDelta = (recentPatternAvg - previousPatternAvg) / baseline
trendAdjustment = clamp(trendDelta * 35, -30, 30)
score = clamp(50 + trendAdjustment, 0, 100)
```

Threshold filters the visible income pattern. It does not add volatility penalty, missing-month penalty, or future-month penalty.

## Threshold Excess Helper

The lower helper chart on both sides uses the approved threshold-excess function:

```text
if threshold <= 0:
  values are normalized as amount - min(amount)
else:
  excess = max(0, amount - threshold)
  normalized = excess / max(excess) * 100
```

The histogram baseline is at the bottom. Expense bars are red; income bars are green. For income, the x-axis uses only threshold-visible income pattern months.

## Page 2 Summary Surface

Page 2 uses the approved summary surface from `stats_common_2025_stat_page_2_final_0710.html`.

It uses the same data, header, FastInfo, active type, category scope, vendor scope, SummaryPill period, and threshold state as Page 1.

The Page 2 content must recompute dynamically on every filter change.

Page 2 keeps the same visual layout, stat boxes, category panel, Top 5 vendor/source panel, colors, progress bars, and threshold warnings in every `layoutMode`. Only the input dataset changes:

```text
sum mode   -> filtered records across the selected summary period / multi-year aggregate
year mode  -> filtered records in activeYear
month mode -> filtered records in activeYear + activeMonth
```

The summary value shown in the SummaryPill must not be duplicated as a Page 2 KPI tile.

### Page 2 KPI Layout

Every metric is its own box. Do not merge boxes.

Top row:

- exactly three highlighted, larger boxes in one row;
- values may wrap to two lines;
- if a top-row box has amount + detail, amount is first line and detail is second line.

Top row metrics:

- `Havi átlag`
- `Legnagyobb kiadás` / `Legnagyobb bevétel`
- `Legdrágább hónap` / `Legerősebb hónap`

Lower rows:

- two boxes per row;
- each metric remains a separate box;
- boxes stay inside the right and left screen margins;
- long values increase height instead of overflowing horizontally.

Lower metrics:

- `Napi tranzakcióátlag`
- `Napi kiadásátlag` / `Napi bevételátlag`
- `Költésmentes nap` / `Bevételmentes nap`
- `Átlagos kiadás` / `Átlagos bevétel`

Do not render separate top vendor/source, vendor count, filtered total, text-insight panel, or event-count tile outside these approved boxes.

### Page 2 Metrics

For the active filtered record set:

```text
total = sum(abs(record.amount))
monthlyAverage = total / numberOfMonthsInActiveScope
largest = record with max abs(amount)
topMonth = month with max sum(abs(amount))
dailyAverageTransactionCount = recordCount / dayCount
dailyAverageAmount = total / dayCount
zeroActivityDays = dayCount - count(unique active record days)
averageEventAmount = recordCount == 0 ? 0 : total / recordCount
```

`numberOfMonthsInActiveScope` and `dayCount` are derived from the active `layoutMode`: sum mode uses the months/days in the selected summary period, year mode uses the selected year's months/days, and month mode uses the selected month's single month/day count.

### Category Panel

The category panel must match the approved Page 2 HTML:

- multiple selected categories: title `Kategória rangsor`;
- exactly one selected category: title `Szűrt kategória`;
- exactly one selected category: do not render a 100% donut and do not show a redundant `100%` row value;
- multiple categories: render the centered donut at the approved doubled size;
- category rows are listed vertically under the donut;
- colors use category colors.

### Top 5 Vendor/Source Panel

The vendor/source panel must match the approved Page 2 HTML:

- expense mode title: `Top 5 kereskedő`;
- income mode title: `Top 5 forrás`;
- title includes the denominator as `shown / total`, e.g. `Top 5 kereskedő · 5 / 18`;
- list only the Top 5 within the current type + period + category scope + vendor scope + threshold;
- progress bars represent each listed item as a share of the listed Top 5 total;
- each progress bar uses the item's category color;
- do not render a separate "top vendor" KPI because it is readable from this panel.

## Threshold Warning

When `threshold > 0`, Page 2 must show the approved warning in three places:

- above the top KPI row,
- inside the category panel,
- inside the Top 5 vendor/source panel.

Text:

```text
X alatti tranzakciók rejtve
```

`X` is the compact formatted threshold amount, for example `5k Ft`.

The warning uses a yellow triangle/exclamation icon. The icon may be drawn with Flutter primitives/icons, but must visually match the approved warning treatment. Do not use a long explanatory paragraph.

## Swipe Behavior

The swipe model:

```text
layoutMode = sum,   pageIndex = 0 -> Page 1 sum-mode year-card view
layoutMode = year,  pageIndex = 0 -> Page 1 year-mode month-card grid
layoutMode = month, pageIndex = 0 -> Page 1 month-mode enlarged month card
any layoutMode,     pageIndex = 1 -> same Page 2 summary view, filtered by layoutMode
```

Horizontal swipe changes only the content page. It does not reset:

- active type,
- category scope,
- vendor scope,
- threshold,
- SummaryPill period,
- layoutMode,
- active year,
- active month,
- FastInfo reveal state.

The active page state should survive normal widget rebuilds while the stats tab remains alive.

## Acceptance Checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCR-REF-01 | User: "hivatkozz a html-re" | Spec/reference | Spec names `stats_common_2025_final_0710.html` as Page 1 authority | File inspection | DONE |
| SCR-REF-02 | User: "hivatkozz a html-re" | Spec/reference | Spec names `stats_common_2025_stat_page_2_final_0710.html` as Page 2 authority | File inspection | DONE |
| SCR-REF-03 | User: "a html fájlokhoz tartozik egy checklist is, az is legyen benne" | Spec/reference | Spec names the Page 1, Page 2, and sum-mode Page 1 prototype checklist files and treats them as mandatory implementation inputs | File inspection | DONE |
| SCR-REF-04 | User: "ez viszont nem mockup, hanem 100% egyezzen a html" | Spec/reference | Spec names `stats_sum_mode_page1_yearcards.html` as an authoritative non-mockup sum-mode Page 1 reference | File inspection | DONE |
| SCR-LANG-01 | User: "page 2 és page 1 magyar legyen, de az expense tracker angol, minden más magyar" | Copy | Page 1 and Page 2 stats UI copy is Hungarian, except `Expense Tracker` brand/app name | Widget tests + screenshot comparison | NOT DONE |
| SCR-STRUCT-01 | User: "stat menu részei..." | Stats shell | Order is header card + FastInfo, type toggle, SummaryPill, SearchPill, swipe content | Widget tests + screenshot comparison | NOT DONE |
| SCR-AREA-01 | User: "az area ahol a page 1 cardjainak és page 2 statisztikák helye van..." | Swipe content layout | Page 1 and Page 2 content share the fixed viewport between SearchPill bottom and bottom nav top, matching the transaction home logbox area's role/space | Widget tests + screenshot comparison | NOT DONE |
| SCR-MODE-01 | User: "kiveszed a multi render modeot, és egy common render mode lesz" | Render mode | Old multi render modes are removed from UI and no render-mode selector remains | Widget tests + code inspection | NOT DONE |
| SCR-SWIPE-01 | User: "belerakod a swipe-page tulajdonságot" | Page navigation | Page 1 and Page 2 are horizontally swipeable content pages, not vertically stacked | Widget tests + manual/screenshot verification | NOT DONE |
| SCR-FAB-01 | User: "joystick gomb megszűnik, helyét a fab gomb veszi át" | Shell/FAB | Stats-tab FAB opens threshold sheet and uses joystick/threshold icon instead of plus | Widget tests + manual verification | NOT DONE |
| SCR-SHEET-01 | User: "bottom sheet ... már nincsenek render modeok, csak slider és text input" | Threshold sheet | Threshold sheet contains only slider and numeric input controls; no render-mode buttons | Widget tests + screenshot comparison | NOT DONE |
| SCR-SNAPSHOT-01 | User: "snapshot mode" and follow-ups | Snapshot mode | Stats FAB sheet includes snapshot editor as logical layout from `stats_common_2025_snapshot_mode.html`: snapshot cards, camera add-new card, tap-select recall, stored category/vendor/type/threshold/layoutMode/page state, and FAB drag tick stepping | Model tests + widget tests + interaction verification | NOT DONE |
| SCR-SNAPSHOT-02 | User: "addnew snapshot ... popup ... dialog ... nevet ... bepipálja mit mentsen el" | Snapshot add dialog | Add-new snapshot opens a centered dialog with name input and checkboxes for which current settings to save/load | Widget tests + screenshot comparison | NOT DONE |
| SCR-SNAPSHOT-03 | User: "snapshotadatbázist is csinálni" | Snapshot storage | Snapshots are stored in a local snapshot repository/table with include-mask fields and optional payload fields | Model/repository tests + code inspection | NOT DONE |
| SCR-SEARCH-01 | User: "searchpill ... vendor selector sheettel" | SearchPill | Stats menu includes SearchPill with vendor selector sheet support | Widget tests | NOT DONE |
| SCR-VENDOR-01 | User: "vendor alapján is lehet szűrni, nem csak kategória alapján" | Filtering | Vendor/source filters affect all stats calculations on both pages | Model tests + widget tests | NOT DONE |
| SCR-MAG-01 | User: "mágnesnak ... pixelre" + HTML | Header/magnet | Header score/magnet matches reference geometry, colors, marker, score bands, and Hungarian copy | Screenshot comparison + model tests | NOT DONE |
| SCR-FAST-01 | User: "függvény számításnak, a grafikonnak ... pixelre" + Page 1 HTML | FastInfo graph | Expense and income FastInfo graphs match approved Page 1 math and layout | Model tests + screenshot comparison | NOT DONE |
| SCR-MONTH-01 | User: "monthcardoknak pixelre" + Page 1 checklist | Page 1 month cards | Month cards and day cells match Page 1 reference exactly | Screenshot comparison + painter/widget tests | NOT DONE |
| SCR-SUM-01 | User: "évcellák", "sum mode grafikonjai adaptóvak", "ez lesz ... nem mockup ... 100% egyezzen" + sum-mode HTML | Sum mode Page 1 | Sum mode Page 1 year cards, month cells, spacing, active-year interaction, 20-year-capable data behavior, threshold/category/vendor coloring, and adaptive year x-axis match `stats_sum_mode_page1_yearcards.html` exactly | Screenshot comparison + model/painter/widget tests | NOT DONE |
| SCR-SUM-02 | User: "page2-t nem kell megrajzolni, mert az ugyanaz mindnehol" | Sum mode Page 2 | Sum mode does not introduce a separate Page 2 design; Page 2 reuses the approved Page 2 summary layout and only receives sum-mode data scope | Code inspection + screenshot comparison | NOT DONE |
| SCR-MODES-01 | User: "van egyedi page 1 sum mode, egyedi page1 year mode, és egyedi page1 month mode" | Page 1 modes | Page 1 supports three explicit layout modes: sum year-cards, year month-card grid, and month enlarged month-card | Widget tests + screenshot comparison | NOT DONE |
| SCR-NAV-01 | User: "ezeket a summary pillel lehessen navigálni, mint a főmenuben" | SummaryPill navigation | SummaryPill navigates sum/year/month mode and selected period using the same model as the main menu | Widget tests + state tests | NOT DONE |
| SCR-NAV-02 | User: "ha a user a sum modera egy évre tappel... ha az éven belül egy hónapra..." | Card tap navigation | Tapping a year card focuses that year, tapping a month cell/card focuses that month, and SummaryPill updates immediately | Widget tests + state tests | NOT DONE |
| SCR-SYNC-01 | User: "a főmenu modeja, és a stat mód szinkronban legyen" | Shared period state | Main menu and stats share layoutMode/activeYear/activeMonth; changing one updates the other when entered | State tests + integration tests | NOT DONE |
| SCR-MONTHFOCUS-01 | User: "monthról nem készült prototípus, de ugyanaz a logika, csak egy kinagyított monthcard van benne" + "a month ha fókuszban van, a tetején legyen egy vissza gomb" | Month mode | Month mode renders a single enlarged month card with the same year-mode month-card logic and a top back button | Widget tests + model tests + screenshot comparison | NOT DONE |
| SCR-MONTH-AXIS-01 | User: "a skála lehet 31 napos is, ezért ide is dinamikus x tengely kell" | Month mode FastInfo x-axis | Month mode FastInfo keeps every day data point but thins day labels dynamically for up to 31-day months | Model tests + screenshot comparison | NOT DONE |
| SCR-PAGE2-01 | User: Page 2 final approval | Page 2 summary | Summary KPI/category/vendor layout matches final Page 2 HTML in every layoutMode | Screenshot comparison + widget tests | NOT DONE |
| SCR-PAGE2-SCOPE-01 | User: "minden modehoz tartozik egy page 2 is, de ez mindenhol ugyanaz, csak más az adatfilter (sum-year-month)" | Page 2 data scopes | Page 2 is the same layout for sum/year/month and receives only the matching filtered dataset | Model tests + screenshot comparison | NOT DONE |
| SCR-THRESH-01 | Page 1/Page 2 checklist | Threshold | Threshold filters visible records and drives charts/warnings consistently | Model tests | NOT DONE |
| SCR-WARN-01 | Page 2 checklist | Threshold warning | Page 2 warning appears in all three approved places with `X alatti tranzakciók rejtve` | Widget tests + screenshot comparison | NOT DONE |
| SCR-NOBUDGET-01 | Prior discussion | Scope control | Budget/limit stats are not added to threshold-filtered common stats pages | Code inspection | NOT DONE |

Implementation is complete only when every `NOT DONE` item above is verified and updated in the implementation checklist. Passing tests alone is not enough if screenshot/reference comparison still differs.

## Verification Requirements

Implementation must use both model tests and UI verification:

- model tests for threshold filtering, vendor filtering, expense score, income pattern score, threshold excess, Page 2 metrics;
- widget tests for shell order, SearchPill capsules, FAB behavior, threshold sheet content, page swipe;
- screenshot/manual comparison against the applicable authoritative HTML files for header, magnet, FastInfo graphs, normal month cards, sum-mode year cards, Page 2 summary layout, warning placement, and Hungarian copy.

Flutter tests/analyze in this environment must run through Ubuntu proot, not the Termux-host Flutter binary. APK builds remain GitHub Actions only.

## Explicit Non-Goals

- Do not implement old `Hózárás` or `Hőtérkép` as selectable stats render modes.
- Do not add new Page 3 budget/limit stats in this spec.
- Do not add extra graph alternatives, C variants, A/B tabs, or explanatory text panels.
- Do not duplicate the SummaryPill total as a Page 2 KPI tile.
- Do not replace the existing vendor selector sheet with a new custom sheet unless extraction is required to reuse it cleanly.
