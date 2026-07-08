# Stats Main Menu Redesign Design

## Source Of Truth

Current approved implementation reference:

- `.superpowers/brainstorm/11665-1783356886/content/stats-current-concept-summary-v26.html`
- Browser URL while the local HTML server is running: `http://127.0.0.1:8765/stats-current-concept-summary-v26.html`
- `.superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html`
- Browser URL while the local HTML server is running: `http://127.0.0.1:8765/stats-heatmap-render-mode-v28.html`
- `.superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html`
- Browser URL while the local HTML server is running: `http://127.0.0.1:8765/stats-closing-render-mode-v29.html`

Every approved HTML reference listed in this spec or in `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md` is mandatory. Before implementing or reviewing stats UI code, re-open the relevant HTML and compare the Flutter result against it. HTML defines accepted layout, graph structure, colors, legends, category sheet states, and calculation notes.

Older pre-July stats redesign/joystick specs were removed to prevent conflicting implementation guidance.

Checklist ID ranges:

- `STAT-SHARED-*`: shared annual stats shell, header, SummaryPill, type pills, joystick, monthcard behavior.
- `STAT-CAT-*`: accepted `Kategória scope` render mode.
- `STAT-HEAT-*`: accepted annual `Hőtérkép` render mode. Month focus/detail remains deferred.
- `STAT-CLOSE-*`: accepted annual `Hózárás` render mode. Month focus/detail remains deferred.

## Scope

This design covers the stats tab annual main menu, the accepted `Kategória scope` render mode, the accepted annual `Hőtérkép` main-menu render mode, and the accepted annual `Hózárás` main-menu render mode.

Explicitly deferred:

- month focus/detail design,
- Heatmap month focus/detail design,
- Hózárás month focus/detail design.

No implementation should infer the deferred modes from older documents.

## Annual Main Menu

The annual stats main menu keeps the main-menu visual hierarchy:

- main-menu-style header card,
- `Bevétel` / `Kiadás` type pills,
- existing-style SummaryPill,
- annual 12 month-card area,
- joystick control.

The SummaryPill owns selected-period money display. The header card must not duplicate the SummaryPill total.

The active transaction type controls every calculation:

- `Bevétel` active: income records/categories/scope are used;
- `Kiadás` active: expense records/categories/scope are used.

## Header For Category Scope

For `Kategória scope`, the header follows the approved HTML:

- left chip shows passive scope state: `ALL` or the custom selected count;
- header label/value identifies the active scope mode/scope name;
- separate `40/100 Kontroll` style score readout sits above the magnet strip;
- magnet strip is visual only: red-orange-green gradient with a white marker;
- no score number, trend text, or human verdict is drawn inside the magnet strip;
- no long explanatory text is added to the header.

The category button keeps the same mental role as the main menu category button: it opens category selection. It is not the render-mode selector.

## Render Mode Selector

The three render modes are secondary controls, not foreground pills.

- Joystick tap opens the render-mode selector.
- Joystick long-press/drag adjusts threshold.
- Header category button opens the category scope sheet.

## Category Scope Sheet

The scope sheet uses the real category sheet visual language adapted for multi-select:

- top grabber,
- centered title,
- two-column category cards,
- 150 px card rhythm,
- avatar at the top,
- category name and status at the bottom,
- active border/background,
- bottom primary pill `Szűrőbeállítás`.

State model:

```text
scopeMode = all | custom
selectedCategoryIds = set<int>
availableCategoryIds = active-type categories
```

Normalization:

```text
0 selected -> scopeMode = all
N selected where N == availableCategoryIds.length -> scopeMode = all
1..N-1 selected -> scopeMode = custom
```

Opening default state must show an explicit active `ALL / Minden kategória` card. There is no empty-looking sheet state. If the user selects every category one by one, the sheet normalizes back to `ALL`; it must not remain a custom state with every category separately active.

In `ALL` mode, active-type uncategorized transactions are included. In `custom` mode, only selected category IDs are included.

## Graph Domain

FastInfo graphs must not extend flat to year end when the user has no transactions there.

For the selected year and active transaction type:

```text
domainStart = first active-type transaction date in selected year
domainEnd = last active-type transaction date in selected year
```

If no active-type transactions exist, use the full selected year as an empty-state fallback.

All FastInfo charts use this active graph domain unless a render-mode section explicitly narrows it further.

## Category Scope Data

For each date in the graph domain:

```text
scopeAmount(day) =
  sum(abs(record.amount))
  for active-type records on day
  where record.categoryId is included by the current scope

hit(day) = scopeAmount(day) >= threshold
hitValue(day) = hit(day) ? scopeAmount(day) : 0
```

The threshold is active-side specific and controlled by the joystick.

## Top Chart: Occurrence Vs Value Index

Approved title: `1. Előfordulás vs értékindex`

Purpose: show behavior frequency and financial pressure together, so a lower occurrence count is not falsely read as improvement when the remaining hits are much more expensive.

Axes:

- x-axis: active graph domain timeline with month ticks;
- y-axis: normalized 0-100;
- no HUF labels on this chart.

Lines:

- occurrence line: red `#EF4444`;
- value index line: turquoise `#0EA5A4`.

Occurrence calculation:

```text
occurrence(day) = rollingHitRate(hit, window) * 100
```

This is hit frequency only. It does not encode amount.

Value index calculation:

```text
rollingValue(day) = rollingSum(hitValue, window)
valueIndex(day) = rollingValue(day) / max(rollingValue over domain) * 100
```

If the max rolling value is zero, value index is zero.

The rolling window should be stable enough for trend reading. Implementation can use a fixed day window matching the accepted visual density, but it must be documented in code/tests and used consistently by occurrence, value index, score, and MACD.

## Top Chart Risk Background

Risk background is analog and segment-based, not monthly blocks.

For each adjacent sample segment:

- green `rgba(16,185,129,.55)`: occurrence and value index both improve;
- red `rgba(239,68,68,.55)`: occurrence and value index both worsen;
- orange `rgba(249,115,22,.55)`: mixed/diverging movement;
- no color: both signals are inside the flat/noise threshold.

This means multiple risk color changes can happen inside one month.

Legend design:

- transparent inline legend inside the graph under the title;
- no separate pill/card background;
- line swatches for occurrence and value index;
- small risk swatches for `Javul`, `Vegyes`, `Romlik`.

## Kontroll Score

The score is a derived 0-100 decision metric from the two top-chart lines. It is not a third graph line.

Base pressure:

```text
pressure = 0.4 * occurrence + 0.6 * valueIndex
```

The value side is heavier because fewer but more expensive hits should not look like good behavior.

Score behavior:

- if both occurrence and value index improve, score can improve;
- if occurrence improves but value index worsens or stays high, score must be limited;
- if both worsen, score must fall.

Implementation should compute a recent pressure window against the previous same-length window, apply a worsening penalty, and clamp the final score to 0-100. Tests must cover false-improvement cases.

## Behavior MACD

Approved label: `Alt: Behavior MACD`

Input:

```text
P = 0.4 * occurrence + 0.6 * valueIndex
MACD = EMA(P, 7) - EMA(P, 21)
signal = EMA(MACD, 5)
histogram = MACD - signal
```

Layout/design:

- MACD plot width aligns with the top chart plot width;
- x-axis uses the same active graph domain;
- histogram is the primary signal;
- positive histogram means worsening pressure in expense mode and is red;
- negative histogram means improving pressure in expense mode and is green.

Interpretation:

- shrinking positive histogram means worsening momentum is weakening;
- crossing below zero is a confirmed green turn.

## Bottom Chart: Monthly Scope Ft + Impact Line

Approved title: `2. Havi scope Ft + impact line`

Purpose: show monthly HUF totals, while the top chart shows occurrence/value trend.

Axes:

- x-axis: months inside the active graph domain;
- left y-axis: HUF monthly scope total;
- right/readout: orange `Ft/kiugrás` line value.

Bars:

- monthly stacked bars;
- each bar height is the full monthly scope HUF total;
- stack colors are category contribution layers.

Category stack rule:

- show top 3 categories by visible-domain HUF total;
- group every remaining category into `Egyéb`;
- `Egyéb` is gray `#CBD5E1`;
- total visible bar height must still equal the full monthly scope total.

Legend:

- inline, transparent, under the chart title;
- top 3 category swatches;
- `egyéb`;
- orange line swatch `Ft/kiugrás`;
- no separate pill/card legend container.

Impact line:

```text
monthlyImpact = monthlyScopeFt / monthlyThresholdHitDays
```

If a month has zero threshold-hit days, impact is null and the line skips that point.

The latest non-null impact value is rendered as an orange right-edge label, e.g. `18.4k`. It is not a separate FastInfo row.

## FastInfo

Stats FastInfo is passive graph canvas only:

- no cards,
- no pills,
- no category chips,
- no settings controls,
- no long human explanatory paragraphs.

For the accepted `Kategória scope` mode, the FastInfo stack is:

1. occurrence vs value index chart with risk background and inline legend,
2. Behavior MACD indicator aligned to the same plot width,
3. monthly stacked HUF bars plus orange `Ft/kiugrás` impact line.

## Heatmap Render Mode

Approved reference:

- `.superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html`
- Browser URL: `http://127.0.0.1:8765/stats-heatmap-render-mode-v28.html`

Approved stack:

- `M1`: header magnet strip = concentration marker;
- `S1`: upper special FastInfo function = cluster density;
- `S2`: small complementary FastInfo function = Heat Pulse;
- `H1`: lower monthly FastInfo function = monthly heat load.

The other drawn options in v28 are reference alternatives only. Do not implement `M2-M6`, `S3-S6`, `H2-H5`, or coloring B/C unless the user explicitly changes the selection.

Heatmap uses the same active transaction side and category scope model as category-scope mode:

- `Bevétel` active: income records and income categories;
- `Kiadás` active: expense records and expense categories;
- scope chip stays `ALL` or selected-count using the shared scope normalization rules;
- SummaryPill remains the period money display.

### Heatmap Month-Card Day Cells

The annual month-card day-cell coloring remains the current app implementation. Do not redesign this part from the HTML.

Current stats implementation:

```text
heatmapIntensity = clamp(scopeAmount(day) / threshold, 0..1)
```

If `heatmapIntensity > 0`, the stats year calendar draws a rounded overlay inside the day cell:

- `Kiadás`: base overlay color `AppColors.primary`, `#06B6D4`;
- `Bevétel`: base overlay color `AppColors.income`, `#22C55E`;
- base overlay alpha: `heatmapIntensity * 0.8`;
- white wash overlay: `AppColors.white`, `#FFFFFF`, alpha `(1 - heatmapIntensity) * 0.4`;
- if intensity is `0`, there is no heat overlay and the existing base day-cell appearance remains.

The `forró nap` count is still threshold-gated:

```text
hot(day) = scopeAmount(day) >= threshold && scopeAmount(day) > 0
```

### M1 Magnet Strip

M1 is a visual concentration marker, not a score or text container.

Color and rendering:

- strip gradient: gray `#E2E8F0` -> white `#FFFFFF` -> pale blue `#DDF8FD` -> cyan `#67E8F9` -> primary blue `#06B6D4`;
- subtle white repeating texture over the strip;
- marker: white `#FFFFFF` with subtle gray/dark outline and shadow;
- left side means scattered/low hot-day concentration;
- right side means clustered/high hot-day concentration;
- no number, verdict, trend text, or label inside the magnet strip.

### S1 Cluster Density

S1 is the upper special FastInfo function.

Purpose: show when threshold-hit days cluster inside the active graph domain.

```text
hot(d) = scopeAmount(d) >= threshold ? 1 : 0
density(t) = sum(hot, W) / activeDays(W)
```

Axes:

- x-axis: first active-scope transaction date to last active-scope transaction date;
- y-axis: rolling hot-day ratio, not HUF.

Window:

- short active range: 7 days;
- medium active range: 14 days;
- full-year active range: 21 days.

Color and rendering:

- density line: primary blue `#06B6D4`;
- area under the line: cyan/blue `#67E8F9` with transparency;
- cluster background zones: transparent primary blue `rgba(6,182,212,.13)`;
- hot-day rug ticks: primary blue `#06B6D4`;
- inactive/grid lines remain gray from the shared stats graph palette.

### S2 Heat Pulse

S2 is the small complementary indicator. It is not a separate decision chart; it confirms whether recent heat pressure is above or below baseline.

```text
over(d) = hot(d) ? min(scopeAmount(d) / threshold, 3.0) : 0
pulse(t) = EMA_short(over) - EMA_long(over)
```

Dynamic EMA windows:

- short active range: `3 / 7`;
- medium active range: `5 / 14`;
- full-year active range: `7 / 21`.

Color and rendering:

- positive/up bars: primary blue `#06B6D4`, meaning fresh heat pressure is above baseline;
- negative/down bars: gray `#CBD5E1`, meaning cooling;
- zero line: muted gray `rgba(100,116,139,.50)`.

### H1 Monthly Heat Load

H1 is the lower monthly/holistic FastInfo function.

Purpose: summarize the year month by month, combining frequency and severity.

```text
over(d) = hot(d) ? min(scopeAmount(d) / threshold, 3.0) : 0
heatLoad(month) = Σ over(d)
```

Axes:

- x-axis: months in the active year/domain;
- y-axis: monthly threshold-unit load, not direct HUF.

Bar semantics:

- bar height = threshold-hit frequency plus overshoot severity;
- stack segments represent overshoot bands.

Color and rendering:

- high / `3x cap`: primary blue `#06B6D4`;
- middle / `2x`: cyan `#67E8F9`;
- low / `1x`: pale blue `#DDF8FD`;
- empty month: gray `#E2E8F0`;
- hot-day count labels above bars: gray `#64748B`.

Heatmap mode must not use orange, red, or yellow risk colors. Those belong to the category-scope trend/risk design and must not leak into heatmap. Income-side month-card day cells still use the current green `#22C55E` overlay rule described above.

## Hózárás Render Mode

Approved reference:

- `.superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html`
- Browser URL: `http://127.0.0.1:8765/stats-closing-render-mode-v29.html`

Accepted annual stack:

- `M1`: header magnet strip = zárási drift;
- `S2`: small FastInfo function = Close Pulse;
- `H1`: lower monthly FastInfo function = havi zárás + threshold pontok.

The v29 `S1 · Zárási pálya` drawing is reference context only for now. It is not part of the accepted implementation stack unless the user explicitly reselects it.

Hózárás uses the shared active transaction side and category scope model, but the two measurements have different jobs:

- `closing(month)` is the whole active-side monthly close and is not scope-filtered;
- threshold dots and hit counts are scope-filtered, so they answer which selected-scope days crossed the threshold.

This preserves the annual "így zártuk a hónapot" reading while still allowing category-scope analysis through the points.

### Hózárás Header

Header label:

```text
HÓZÁRÁS
```

Header value:

```text
N romló hónap idén
```

Worsening compares adjacent active months only:

```text
closing(month) = activeTypeTotal(month)
delta(month) = closing(month) - previousActiveClosing

expense worse when delta(month) > 0
income worse when delta(month) < 0
```

The annual header must not explain a single month. Month-specific diagnosis belongs to the later focus-mode design.

### Hózárás Month Cards

Annual 12 monthcards remain visible.

For each month:

```text
closing(month) = sum(abs(record.amount))
  for active-type records in the month
```

Month closing amount rendering:

- income: `+formatHuf(closing)`, text `#059669`;
- expense: `-formatHuf(closing)`, text `#DC2626`;
- active income month overlay: `#22C55E` at alpha `0.08`;
- active expense month overlay: `#EF4444` at alpha `0.08`.

Threshold point logic:

```text
scopeAmount(day) =
  sum(abs(record.amount))
  for active-type records on day
  where record.categoryId is included by the current scope

thresholdPoint(day) =
  scopeAmount(day) >= threshold && scopeAmount(day) > 0
```

Point rendering:

- position: top of the day cell, `Offset(cell.center.dx, cell.top + 1)`;
- radius: `2.5`;
- expense: `#EF4444`;
- income: `#22C55E`.

This means a month can show a large closing amount without many threshold points if the spending/income is outside the selected scope, and it can show many threshold points even when the whole active-side monthly close is not the largest month.

### M1 Closing Drift Magnet

M1 is a visual annual drift marker, not a score, not a pill, and not a scope label.

It uses active months only. There is no empty future section if the year has not reached December or if the user's latest active transaction is earlier.

Math:

```text
delta(month) = closing(month) - previousActiveClosing
improvementDelta(month) =
  activeType == expense ? -delta(month) : delta(month)

maxAbsDelta = max(abs(delta(month))) over adjacent active months
normalizedDelta(month) =
  maxAbsDelta == 0 ? 0 : improvementDelta(month) / maxAbsDelta

drift = average(normalizedDelta(month))
markerPosition = clamp(0.5 + 0.5 * drift, 0, 1)
```

Interpretation:

- left = worsening closing drift;
- center = stable/flat closing drift;
- right = improving closing drift.

Color and rendering:

- gradient: red `#EF4444` -> pale red `#FEE2E2` -> white `#FFFFFF` -> pale green `#DCFCE7` -> green `#22C55E`;
- marker: white `#FFFFFF` with subtle outline/shadow;
- no number, text, or verdict inside the strip.

### S2 Close Pulse

Close Pulse is a momentum indicator for closing deterioration/improvement. It does not show HUF totals directly.

Input:

```text
pressureDelta(month) =
  activeType == expense ? delta(month) : -delta(month)
```

Positive `pressureDelta` always means the closing direction is getting worse:

- expense: a higher month close is worse;
- income: a lower month close is worse.

Pulse:

```text
closePulse(month) = EMA_short(pressureDelta) - EMA_long(pressureDelta)
```

Dynamic EMA windows by active-month count:

- fewer than 5 active months: `1 / 3`;
- 5-8 active months: `2 / 4`;
- 9-12 active months: `3 / 6`.

Axes and domain:

- x-axis: active months from first active-type transaction month to last active-type transaction month;
- y-axis: relative pulse/momentum around zero, not HUF.

Color and rendering:

- positive/up histogram bars: red `#EF4444`, worsening pressure;
- negative/down histogram bars: green `#22C55E`, improving pressure;
- zero line: muted gray `rgba(100,116,139,.50)`;
- grid: `#E2E8F0` / `#CBD5E1`;
- no text paragraph is placed under the chart.

### H1 Monthly Close + Threshold Points

H1 is the lower holistic monthly chart.

Bars:

```text
barHeight(month) = closing(month)
```

The bar is the full active-side monthly close, not the scope total.

Threshold markers:

```text
thresholdHitDays(month) =
  count(day where scopeAmount(day) >= threshold && scopeAmount(day) > 0)
```

Axes:

- x-axis: active months only;
- left y-axis: active-side monthly close in HUF;
- marker/count layer: number of scope threshold-hit days.

Color and rendering:

- expense bars: red `#EF4444` with light red `#FCA5A5`;
- income bars: green `#22C55E` with light green `#86EFAC`;
- threshold point color follows active side: expense `#EF4444`, income `#22C55E`;
- threshold count labels: gray `#64748B`;
- empty future months are not drawn in the FastInfo chart.

If a month improves versus the previous active month, the chart may use the accepted green improvement accent from v29, but the bar height always remains the real `closing(month)` amount.

### Hózárás FastInfo

Hózárás FastInfo remains passive graph canvas only:

- no cards,
- no pills,
- no category chips,
- no settings controls,
- no long human explanatory paragraphs.

The accepted stack is Close Pulse plus monthly close bars with threshold points. The header magnet carries the closing drift summary.

## Testing And Verification

Before any implementation is considered complete:

- re-open the mandatory HTML reference;
- inspect the implemented Flutter layout against the HTML;
- run targeted data tests for scope filtering, graph domain, occurrence/value index, score, MACD, top-3+other stacking, heatmap `density(t)`, Heat Pulse, monthly `heatLoad`, closing drift, Close Pulse, monthly close bars, closing threshold points, and all/custom scope normalization;
- run widget tests for header, SummaryPill, type pills, joystick render selector, category scope sheet, heatmap selected stack, closing selected stack, and FastInfo graph-only area;
- capture screenshots or golden-style evidence for graph/header/sheet visual matching.

APK build status is not proof of completion. Every checklist item in `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md` must be `DONE` or explicitly deferred by the user.
