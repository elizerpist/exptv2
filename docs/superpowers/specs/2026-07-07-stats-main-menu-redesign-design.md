# Stats Main Menu Redesign Design

## Scope

This design covers only the stats tab annual main menu. Month focus/detail is explicitly deferred and must not be implemented in this branch.

Approved visual references:

- `.superpowers/brainstorm/11665-1783356886/content/stats-exact-header-monthcards-v3.html`
- `.superpowers/brainstorm/11665-1783356886/content/stats-summary-pill-navigation-v4.html`
- `.superpowers/brainstorm/11665-1783356886/content/stats-render-mode-header-fastinfo-v10.html`
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- `lib/features/transactions/widgets/summary_pill.dart`
- `lib/features/transactions/widgets/transaction_type_pills.dart`

## Annual Layout

The stats tab main menu uses the same visual stack as the transaction main menu:

- `TransactionHeaderCard` at the top with the existing 188 px header geometry.
- `TransactionTypePills` below the header. The pills select the stats data side only: `Bevétel` or `Kiadás`.
- `SummaryPill` below the type pills. It shows the active annual period and the active type's annual total.
- A 12-month annual card grid below the SummaryPill. Month focus is not opened in this branch.

The month cards keep the current calendar painter visual language: 2 columns, 6 rows, 48% card width, 4% gap, 200 px card height, 15 px row gap, gray50 fill, gray200 border, radius 15, shadow, centered title, weekday row, and day grid.

## Render Modes

The stats main menu has three render modes:

- `Kategória scope`: threshold-based category-scope measurement.
- `Hózárás`: former summary mode. Month cards show the monthly closing amount, and threshold/activity markers remain as dots above day cells like the existing summary painter.
- `Hőtérkép`: active-side daily intensity.

The three render modes are not shown as a foreground pill row. Joystick tap opens the compact render-mode selector. Joystick long-press and vertical drag adjusts the threshold value.

## Header Feedback

In stats, the header card is not a duplicate of the SummaryPill. The SummaryPill owns the selected period amount. The header card gives short text feedback about the active render mode, threshold, scope, and yearly-level conclusion.

Header examples by mode:

- `Kategória scope`: label `SCOPE TREND`, value like `Gyorskaja 20 → 8 nap` or `Minden kategória: 96 nap`.
- `Hózárás`: label `HÓZÁRÁS`, value like `4 romló hónap idén`.
- `Hőtérkép`: label `HEATMAP`, value like `96 forró nap 5k felett`.

Because this branch is annual-only, the header must not say what took a specific month. Month-specific explanations belong to the later focus design.

## Category Scope

The header right category button keeps the same mental role as the transaction main menu category button. In stats it opens a category sheet adapted for multi-select scope:

- The sheet filters categories by the active transaction type.
- Tapping a category toggles inclusion and does not close the sheet.
- The bottom primary pill applies the filter and closes the sheet.
- Empty scope means all active-type categories are included.

The scope is used for threshold measurement so unrelated categories do not distort behavior tracking. For example, measuring fast food does not include a clothing purchase on the same day.

## FastInfo

Pulling down the stats header reveals a stats-specific FastInfo variant. It is a passive graph canvas area:

- no cards,
- no pills,
- no filter controls,
- no category buttons,
- no settings controls.

The graph depends on the active render mode:

- `Kategória scope`: monthly threshold-hit trend line.
- `Hózárás`: monthly closing bars with threshold/activity points.
- `Hőtérkép`: annual intensity distribution.

## Data Rules

The active transaction type determines every calculation:

- income active: daily and yearly income are used;
- expense active: daily and yearly expense are used.

Threshold-hit calculation uses the selected category scope:

`scopeDailyAmount(activeType, selectedCategoryIds, date) >= threshold`.

If no selected category ids exist for the active type, all active-type categories are included.

For transactions without a category id, the record is included only when the scope is empty/all-categories.

## Non-Goals

- No month focus/detail screen.
- No export implementation.
- No changes to transaction main-menu behavior.
- No persistent controls inside the pulled FastInfo graph area.

## Testing

Tests must cover:

- stats annual data builder filters by active type and category scope;
- threshold-hit days are calculated from selected categories, not full day totals;
- header feedback text changes by render mode;
- StatsPage no longer renders `CalendarMenuOverlay` as the main stats body;
- StatsPage renders header, type pills, SummaryPill, annual 12-month grid, joystick, and FastInfo graph;
- joystick tap opens the render mode selector;
- header category button opens a multi-select scope sheet;
- `Hózárás` retains dot-based day markers instead of heatmap fill.
