# Stats Focus Month Charts Design

## Goal

The statistics screen needs a cleaner annual calendar surface and a focused monthly detail view. View modes move out of the visible app surface into a general stats dropdown. Tapping a month opens a focused month menu with one enlarged month card and visual charts for that month.

## Annual Stats Menu

The annual stats screen keeps the existing calendar rendering and year navigation. A top-left general menu trigger opens a dropdown containing all calendar view modes plus placeholder export actions:

- Küszöbérték nézet
- Összefoglaló
- Hőtérkép
- Domináns kategória
- Export CSV
- Export PDF

The active mode is shown inside the dropdown. Export actions are placeholders and show immediate snackbar feedback. The visible inline view-mode button row is removed from the stats surface.

## Focus Month View

When the user taps a month card, the same overlay switches into focused month state. The panel size and position remain unchanged. The header keeps the general stats dropdown and adds a back button to return to the annual view. The selected month card is rendered as one enlarged card and continues to respect the shared calendar view mode.

## Monthly Charts

The focused month view shows visual chart cards below the enlarged month card:

- Cashflow: three-bar chart for income, expense, and net balance.
- Napi ritmus: sparkline/area chart for daily spending across the month.
- Kategóriák: donut chart with top category bars.
- Heti bontás: weekly income/expense bar chart.
- Kiemelések: compact insight tiles for transaction count, daily average expense, most expensive day, and largest expense.

The charts compute from existing `TransactionRecord` and `TransactionCategory` data. Missing data renders as empty/zero states instead of blocking the focused view.

## Testing

Widget tests cover the dropdown, hidden inline mode selector, export placeholder feedback, focused month navigation, shared mode switching in the focused state, and presence of all monthly chart sections. Existing calendar layout and canvas tests remain valid.
