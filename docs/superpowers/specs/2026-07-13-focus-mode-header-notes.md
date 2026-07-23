# Focus mode header current-app notes

Source: current color-lab discussion on 2026-07-13. This note preserves the active B/C/D focus-mode header direction so later prototype and app implementation work does not mix it with older backheader/fastinfo concepts.

## Global focus-mode header rules

- The B/C/D common-header rows are the current app direction for the focus mode header.
- The header card expands downward and pushes all content below it down by the same amount.
- Each header card has a small white bottom handle. Dragging this handle downward expands to the next snap stage.
- On drag release after a tick, the header remains at the reached stage. If the user drags without reaching the next tick and releases, it collapses to stage 0.
- Current correction COLOR-LAB-218 supersedes the avatar portions of COLOR-LAB-217.
- B2 and D2 stage1 do not render category avatars.
- B2 stage1 is a non-glossy reserve summary: `Tartalék` progress at the top, a compact balance-ratio row between the progress and the card row, and the three A1C fastinfo cards pinned to the header bottom.
- The small ratio/subvalue text under the Balance amount is removed from B2 to avoid duplicate balance-ratio information.
- Stage2 is stage1 plus extra area: B3 duplicates the full B2 reserve-summary layer at the same stage1 height, then adds the income-side `Bevétel vs kiadás` graph in the lower extra stage2 area.
- C2 keeps the glossy budget extended-info container. The only remaining stage1 avatar strip in the focus-mode header row is the C2 budget avatar/content area inside that glossy container.
- C2 bottom-anchored budget progress: the `Elköltve …` / `Maradt …` labels and the A-row partition progress bar sit together at the bottom of the glossy container, not at the top.
- Current correction COLOR-LAB-228 raises the C2/C3 budget glossy layer to 130px height to stop clipping the category progress circle/ring.
- C2/C3 budget partition progress uses a 10px bar height.
- C2/C3 budget partition track/padding visual is transparent/no shadow; only the colored segments should read, with the free tail at zero opacity in the budget glossy container.
- D3 Mind mode stage2 and C3 Budget mode stage2 can be internally scrollable. The stage2 card itself stays clipped; the heatmap/pie extra layer inside it scrolls.
- The stage3 screens do not render avatar carousels. In the current prototype naming this covers the balance-mode stage3 screen (user referred to it as A3) and the C3/D3 generated mode rows.

## Balance mode stage1

- Balance mode stage1 keeps the existing header title and value, but removes the small subvalue under the Balance amount.
- Its expanded content is not a glossy container. It is a direct header layout with:
  - top `Tartalék` progress bar,
  - compact `balance arány` row between the progress bar and the A1C card row: left-aligned title, right-aligned mini income/expense columns with green `32%` over `bevétel` and red `68%` over `kiadás`,
  - bottom three-card A1C fastinfo summary (`Havi kiadás`, `Legnagyobb kiadás`, `Átlagos napi költés`).

## Balance mode stage2

- Balance mode stage2 keeps the expanded header geometry and balance-only top text.
- It repeats the full Balance mode stage1 content first.
- Its lower extra area is a 264px high glass graph stack:
  - top: the current income-side `Bevétel vs kiadás` centerline interval graph,
  - bottom: a merged pattern chart using the stats menu lower helper-bar logic; green income pattern bars grow upward from the centerline, red expense pattern bars grow downward from the centerline.
- Source logic:
  - `lib/features/stats/widgets/stats_fast_info_graph.dart`
  - `lib/features/stats/data/stats_category_scope_series.dart`
- App behavior to preserve:
  - active type is income,
  - title is `Bevétel vs kiadás`,
  - legend items are `Fedezi a kiadást`, `Kevés bevétel`, and `Nullszaldó`,
  - the chart is a centerline bar chart where green bars above the centerline mean income covers expense and red bars below the centerline mean too little income.

## Budget mode stage1

- Budget mode stage1 shows the current Budget context using the existing header title and x/y amount.
- Do not duplicate the Budget title or x/y amount.
- The extended info lives in one glossy container and contains the category avatar/content area plus a bottom-anchored `Elköltve … / Maradt …` + A-row partition progress block.
- The budget glossy layer is 130px high after the latest clipping correction; this is 5% taller than the previous 124px state while keeping the same top position.
- The bottom-anchored budget partition progress is increased to 10px height for clearer reading inside the smaller glossy layer.
- The avatar area uses a smaller top inset and larger vertical window so the center category progress ring is not clipped by either the glossy container top or the partition bar area.
- The budget partition track/padding visual has zero opacity: transparent background, transparent border, no shadow, and a hidden free-tail segment in this compact glossy context.
- C2/C3 budget avatar badge enlargement is reverted: use the previous 36/46/66px badge sizes, 17/22/30px icon sizes, 12px carousel gap, and 66px strip height.
- The partition/progress behavior should be derived from the app budget header code:
  - `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
  - `lib/features/transactions/models/budget_progress_segment.dart`
  - `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- There is no avatar focus slider in this header. If the C2 category avatar/content area is used for category limit adjustment, the interaction is a longtap vertical joystick:
  - longtap category avatar,
  - swipe up increases the limit,
  - swipe down decreases the limit,
  - haptic tick while stepping.

## Budget mode stage2

- Budget mode stage2 keeps the cloned budget stage1 glossy layer first.
- The lower C3 area receives a scrollable category pie/donut panel based on:
  - `lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart`
  - `CategoryDonutChart`
  - `lib/features/stats/stats_page.dart::stats-category-donut`
- The current/focused category is highlighted both on the donut ring and in the category list.
- The list may be longer than the visible header area, so the C3 pie layer scrolls internally.

## Mind mode stage1

- Mind mode stage1 receives the app’s expense-side score graph when the expense tab is active.
- Source logic:
  - `lib/features/stats/widgets/stats_fast_info_graph.dart`
- App behavior to preserve:
  - active type is expense,
  - reference chart structure from `/storage/emulated/0/spendee/scorechart.png`,
  - readable 100 / 50 / 0 y-axis and month x-axis,
  - grid/neutral line,
  - segmented score path,
  - one endpoint dot.
- Prototype design direction: keep the app logic, but remove the noisy colored background zones/plumes and the duplicate chart-internal score badge/number. The header value already shows `82 / 100`.
- SVG grid, axis, and trend paths must explicitly use `fill: none`; otherwise open axis/grid paths can render as black filled polygons over the trend.
- The score graph should live directly in a clean glass chart surface. Do not wrap it in a smaller inner chart card/background.

## Mind mode stage2

- Mind mode stage2 keeps the stage1 score graph cloned into the top stage2 area.
- The remaining D3 stage2 area gets a separate scrollable heatmap layer based on the app yearly calendar model:
  - `lib/features/stats/widgets/stats_year_calendar.dart`
  - `StatsYearCalendar`
  - `StatsMonthCard.cardHeight`
  - `StatsYearData`
  - day-cell `heatmapIntensity`
- Prototype layout: glossy monthcards instead of a flat white sheet, 12 months, 4 rows × 3 columns, compact score badge, weekday labels, 7×6 day grid, and bottom score/amount.
- The heatmap cell color is dynamic: user selects a color/slot, then taps a monthcard/heatmap; the chosen category color becomes the heatmap overlay color and each day keeps its own opacity/intensity.
- The full preview includes multiple monthcard variants (`frost`, `aurora`, `graphite`) for visual comparison.
- Current correction COLOR-LAB-227: in D3, the yearly heatmap grid sits inside a score-chart-like glass panel so the background is easier to parse. Monthcard headers are compact month-name-only rows; the score number is not shown in the header badge.
- A separate content-height preview screen exists in the color lab to show all 12 monthcards at once because the D3 phone-height stage2 layer is scrollable.

## stage2 / stage3 expanded header

- Stage2/stage3 is the taller expanded header state.
- The bottom avatar carousel is removed from the expanded header screens.
- Header content may differ per mode, but the small white bottom handle remains common.
