# Exptv2 Calendar Canvas Menu Design

## Goal

Rebuild the expt0926 header calendar menu in Flutter/Dart with matching visual design, menu modes, controls, colors, and behavior. The calendar body must be high performance: all month cards and all day cells are rendered by one canvas layer, not by a widget grid.

## Source References

The React Native source of truth is:

- `/storage/emulated/0/androidapps/expt0926/calendarmenu.js`
- `/storage/emulated/0/androidapps/expt0926/monthcard.js`
- `/storage/emulated/0/androidapps/expt0926/heatmapmonth.js`
- `/storage/emulated/0/androidapps/expt0926/monthswipe.js`
- `/storage/emulated/0/androidapps/expt0926/backheader-stage0-clean.js`

The Flutter integration points are:

- `lib/features/transactions/transaction_home_page.dart`
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- `lib/features/transactions/models/transaction_record.dart`
- `lib/features/transactions/models/transaction_category.dart`
- `lib/features/transactions/state/transaction_store.dart`
- `lib/core/theme/app_colors.dart`

## Scope

This feature adds the calendar menu only. It does not change transaction persistence, category editing, notification scraping, or Kotlin database tables. The menu reads the current transaction/category lists already loaded by `TransactionStore`.

The calendar header controls are normal Flutter widgets. The calendar body is a single `CustomPaint` surface that draws:

- the 12 month cards,
- each month card background, border, shadow, title, optional monthly summary text,
- weekday labels,
- all day numbers,
- today circles,
- threshold rings,
- summary corner indicators,
- heatmap overlays,
- dominant category circles.

No month card or day cell may be represented as a repeated Flutter widget in the calendar body.

## Menu Layout

The menu is a slide-up overlay opened from the existing header calendar button.

The header calendar button stays at the same visual position copied from expt0926 stage0:

- top: 37
- right: 27
- visual size: 43 x 43 in the original clean header variant
- icon: calendar outline, color equivalent to gray200/gray600 depending current header design

The menu matches `calendarmenu.js`:

- absolute overlay across full width,
- white background,
- top left/right radius 30,
- border width 1,
- border color `#e2e8f0`,
- no bottom border,
- content clipped inside the top radius,
- z order above page content and below modal editors.

The original line positions are `line2Position = 286` and `line5Position = 700`. In Flutter this should be adaptive but preserve the same shape: the menu starts near the summary/content line and extends down toward the bottom navigation area. Opening and closing use a fast slide animation equivalent to the React Native 80 ms open / 60 ms close feel.

The menu header height is 50. Its layout is:

- left spacer around 100 px,
- centered year navigation with previous/next chevrons and year text,
- right mode selector capsule.

Year controls:

- previous and next buttons are 48 x 48 touch areas,
- chevron color `#64748b`,
- year text color `#1e293b`, font size 16, weight 600,
- year swipe may be added by horizontal drag on the canvas/header; threshold is 30 px or velocity above 300, matching the old gesture rule.

## View Modes

The menu supports exactly four modes, in this order:

1. `normal`
2. `summary`
3. `heatmap`
4. `category`

Mode titles match the original Hungarian labels:

- normal: `Küszöbérték nézet`
- summary: `Összefoglaló`
- heatmap: `Hőtérkép`
- category: `Domináns kategória`

The title is centered above the canvas, with font size 18, weight 700, color `#1e293b`, and top padding equivalent to the original title area. UI labels use the accented Hungarian text above exactly; test keys and identifiers stay ASCII.

### Mode Selector Design

The selector container matches the old design:

- row layout,
- gap 4,
- white background `#ffffff`,
- border `#e2e8f0`,
- radius 15,
- horizontal padding 8,
- vertical padding 4.

Base mode button:

- 20 x 20,
- circle radius 10 except heatmap square,
- border width 1,
- border `#e2e8f0`.

Active mode button:

- 24 x 24,
- border width 2,
- border `#06b6d4`,
- shadow black with opacity around 0.4, offset 0/3, blur 4.

Mode fill styles:

- normal: circle, inner `#f8fafc`, thick gray border `#9ca3af` when inactive, turquoise border when active.
- summary: circle split by color, green `#22c55e` base with red `#ef4444` right half.
- heatmap: square, white base `#ffffff` with turquoise `#06b6d4` right half, square corners in both active and inactive states.
- category: circle filled orange `#f97316`.

Mode switching ignores taps while a mode transition is already active, matching the old 300 ms guard.

## Canvas Month Card Design

The calendar body draws 12 months for the selected year in a two-column layout: six rows, two months per row. Each month card mirrors `monthcard.js`:

- width: 48% of content width,
- margin bottom: 15,
- background `#f8fafc`,
- border radius 15,
- border `#e2e8f0`, width 1,
- shadow black opacity 0.1, offset 0/2, blur 3,
- content clipped to card bounds.

Compact card mode applies to normal, heatmap, and category:

- approximate min height 140,
- vertical padding 8.

Expanded card mode applies to summary:

- approximate min height 200,
- vertical padding 12,
- monthly balance text appears below month title.

Month title:

- font size 12,
- weight 600,
- color `#1e293b`,
- centered,
- bottom margin 2.

Month names use English names in the original calendar menu when `locale="en"`. The Flutter implementation keeps the same default visual text for this feature.

Weekday labels:

- `M T W T F S S`, Monday first,
- font size 8,
- weight 600,
- color `#64748b`,
- uppercase,
- letter spacing 0.2.

Day text:

- font size 10,
- weight 600,
- color `#64748b`,
- centered.

Today styling in normal and summary:

- circle fill `#06b6d4`,
- white day text,
- shadow turquoise opacity 0.3, offset 0/2, blur 3.

## Mode Rendering Rules

### Normal Mode

Normal mode uses daily expense threshold.

Input data:

- daily expense is the sum of absolute values of negative transactions for a day.
- income does not count toward threshold.

Threshold range:

- min and max are calculated from all daily expense sums in all loaded transactions.
- if no expenses exist, min 0 and max 1000.
- custom min/max values override calculated values.

Initial threshold value is 1000.

A day meets threshold when `dailyExpense >= thresholdValue`.

Rendering:

- matching non-today days draw a gray circular border `#9ca3af`, width 1, full day-cell bounds, transparent fill.
- today with threshold still uses the turquoise today circle and does not show gray border.

Controls:

- bottom floating slider panel appears only in normal mode and only when min != max.
- label text: `Küszöbérték: <amount> Ft`.
- label is tappable and becomes numeric input.
- slider min/max are threshold min/max, step 1.
- slider active track and thumb use `#06b6d4`; inactive track uses `#e2e8f0`; thumb size 20 x 20.
- min and max labels are editable; invalid min corrects to 0, invalid max corrects to at least min + 1.

### Summary Mode

Summary mode displays monthly balance and daily transaction type indicators.

Monthly stats:

- expense is sum of absolute negative amounts,
- income is sum of positive amounts,
- balance is income minus expense,
- if balance is positive, monthly balance text is green `#059669`, prefixed with plus,
- if balance is negative, monthly balance text is red `#dc2626`, prefixed with minus.

Card overlay:

- if the month has transactions, paint a subtle overlay across the card:
- positive balance: `rgba(34, 197, 94, 0.1)`,
- negative balance: `rgba(239, 68, 68, 0.1)`,
- radius 15.

Day indicators:

- only summary mode shows corner indicators.
- if a non-today day has income, draw a small green circle in top-left: `#22c55e`, size 5, radius 2.5, top 1, left 4.
- if a non-today day has expense, draw a small red circle in top-right: `#ef4444`, size 5, radius 2.5, top 1, right 4.
- today keeps the turquoise today circle and does not show corner indicators.

### Heatmap Mode

Heatmap mode colors days by daily expense intensity.

State:

- `heatmapMinValue` starts at 0.
- `heatmapMaxValue` starts at 50000.
- `heatmapCurrentValue` starts at 10000 and controls where maximum turquoise appears.

A day at or below min stays original gray/background. A day above min is normalized using:

`percentage = min(1, (dailyExpense - heatmapMinValue) / (heatmapCurrentValue - heatmapMinValue))`

Canvas rendering follows the optimized overlay behavior from `monthcard.js`:

- very low values up to min + 15% of the active range get a full white square overlay,
- values above that get a turquoise overlay with opacity `percentage * 0.8`,
- also draw a white overlay with opacity `max(0, (1 - percentage) * 0.4)`,
- overlays use day cell radius 3.

The standalone `getHeatmapColor` 10-step gradient in the old file is reference material, but the final old month card uses the overlay model; the Flutter canvas should match the overlay model.

Controls:

- bottom floating slider panel appears in heatmap mode.
- label text: `Aktuális színezés: <amount> Ft`.
- label is tappable and becomes numeric input.
- slider min/max are heatmap min/current/max state, step 100.
- custom slider track background is gray `#e2e8f0` with a white-to-turquoise gradient from the left edge to the thumb.
- gradient colors match the old list:
  - `rgb(255, 255, 255)`
  - `rgb(230, 245, 250)`
  - `rgb(204, 234, 244)`
  - `rgb(179, 224, 239)`
  - `rgb(153, 213, 234)`
  - `rgb(128, 203, 229)`
  - `rgb(102, 192, 223)`
  - `rgb(6, 182, 212)`
- gradient stops: 0, 0.225, 0.375, 0.6, 0.75, 0.875, 0.95, 1.0.
- min label is editable and corrects to at least 0.
- max label is editable and corrects to at least min + 1000.

### Category Mode

Category mode colors each expense day by dominant expense category.

For each day:

- consider only expense transactions,
- group absolute expense amount by `transactionCategoryID`,
- choose the category with the highest expense sum,
- draw a full day-cell circle with that category color,
- draw day number in white.

Category color lookup:

- use `TransactionCategory.slotColor` / `backgroundColor` from current Flutter category model,
- fallback colors match old defaults as closely as possible:
  - 1 red `#ef4444`,
  - 2 orange `#f97316`,
  - 4 green `#22c55e`,
  - 6 pink `#f472b6`,
  - 11 sky `#38bdf8`,
  - 15 slate `#64748b`,
  - 21 magenta `#ec4899`,
  - unknown gray `#9ca3af`.

Category mode has no bottom slider panel.

## Data Flow

`TransactionHomePage` owns menu visibility. It passes `TransactionStore.transactions` and `TransactionStore.categories` to the calendar menu.

A new calendar data/model layer precomputes annual data:

- selected year,
- month list,
- day grid for each month,
- monthly income/expense/balance/count,
- daily income/expense flags,
- daily expense amount,
- threshold match,
- heatmap overlay values,
- dominant category id/color.

Precomputation should be pure Dart and independently testable. Painting receives immutable render data and does no expensive transaction filtering inside `paint`.

## Rendering Architecture

Files to create during implementation:

- `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- `lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart`
- `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart`
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- `lib/features/transactions/models/calendar_menu_mode.dart`
- `lib/features/transactions/models/calendar_render_models.dart`
- `lib/features/transactions/data/calendar_render_builder.dart`

Files to modify during implementation:

- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- `lib/features/transactions/transaction_home_page.dart`
- tests under `test/transactions/`.

`CalendarCanvasPainter` is responsible only for drawing. It must not mutate state or read stores. It receives render models, selected mode, threshold/heatmap values, and viewport metrics.

Hit testing is manual:

- month card rects are stored by the canvas widget after layout,
- tapping a rect calls the month selection callback with year and month,
- future month-specific menus can reuse this hit map.

## Performance Requirements

The implementation must prioritize frame stability:

- one `CustomPaint` for all month cards and day cells,
- wrap canvas in `RepaintBoundary`,
- avoid per-day Flutter widgets,
- cache text painters where practical per paint pass,
- recompute render data only when year, transactions, categories, mode, threshold, heatmap range, or category refresh inputs change,
- avoid work in `paint` beyond drawing and simple lookup.

The first implementation uses a vertical `SingleChildScrollView` around one tall canvas. That keeps the body one canvas while allowing the annual grid to scroll.

## Testing Requirements

Tests must cover behavior before production implementation:

- header calendar button opens/closes the menu,
- mode buttons switch mode and expose correct title,
- normal mode threshold slider changes threshold and changes threshold match data,
- heatmap slider changes current heatmap value and affects overlay opacity data,
- summary mode calculates monthly balance and daily corner indicator flags,
- category mode chooses dominant category by highest daily expense,
- render builder creates 12 months and Monday-first day grids,
- widget test confirms the calendar body is a `CustomPaint` and does not create repeated day-cell widgets.

Canvas visual fidelity should be tested by painter/model assertions rather than screenshot-perfect tests. The online GitHub workflow remains the source of Android build verification.

## Acceptance Criteria

- The calendar icon in the header opens a slide-up calendar menu.
- The menu header, year navigation, mode selector, title, and slider panel visually match expt0926.
- The four modes exist and use the same labels, colors, and control rules as the original.
- The annual calendar body renders 12 month cards and all day cells on one canvas.
- Normal, summary, heatmap, and category rendering rules match the old `monthcard.js` behavior.
- Month cards and day cells are not repeated widgets.
- Analyze, Flutter tests, and GitHub debug APK build pass on `main`.
