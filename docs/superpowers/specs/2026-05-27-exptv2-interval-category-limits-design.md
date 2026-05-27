# Exptv2 Interval Category Limits Design

## Goal

Copy the expt0926 Stage1 category budget bar system into Flutter, but implement it correctly for the app's three global time windows: monthly, yearly, and all-time sum. The SummaryPill swipe remains the source of truth for the current time window, and every category/overview limit is stored separately per window.

## Source Behavior From expt0926

The active React Native path is `BackHeaderStage1` in `backheader-stage1.js`. Stage0's arrow sets `stage1Visible=true`; Stage0 slides up by 160 px and Stage1 renders behind it. Stage1 builds `budgetData` from an overview item plus expense category items. The visible bar is a 70 px rounded bar at horizontal margin 20, uses category slot colors/icons, swipes left through bars, swipes right back to overview, and opens `BudgetPicker` on tap. If a limit exists, the bar shows `spent / limit`, a thin progress bar, and a bell/alert state. Progress color is white under 80%, orange above 80%, and red at or above 100%.

## Time Windows And Period Keys

The current Flutter app already has `SummaryWindow.monthly`, `SummaryWindow.yearly`, and `SummaryWindow.allTime`. These windows must drive both the SummaryPill and the Stage1 category bars.

Window mapping:
- `monthly`: period key `YYYY-MM`, filters records where `record.yearMonthKey == periodKey`.
- `yearly`: period key `YYYY`, filters records where `record.yearMonthKey.startsWith(periodKey)`.
- `all_time`: period key `all`, includes all records.

The first implementation uses `DateTime.now()` for the active month/year, matching the existing summary calculation. When calendar/month selection is rebuilt later, the same `LimitManager` interface can accept the selected date without changing the backend schema.

## Backend Storage

A new Room table `category_limits` stores all interval-specific limits.

Columns:
- `id`: generated primary key.
- `targetType`: `overview` or `category`.
- `targetId`: `0` for overview, `transactionCategoryID` for category rows.
- `transactionType`: `income` or `expense`.
- `window`: `monthly`, `yearly`, or `all_time`.
- `periodKey`: `YYYY-MM`, `YYYY`, or `all`.
- `hasLimit`: boolean.
- `limitAmount`: double.
- `alertActive`: boolean.
- `createdAt`: epoch millis.
- `updatedAt`: epoch millis.

Unique identity:
`targetType + targetId + transactionType + window + periodKey`.

The legacy category fields `hasLimit`, `limitAmount`, and `alertActive` stay for compatibility, but Stage1 bars and the new limit editor use `category_limits` as the source of truth.

## Flutter Data Flow

`TransactionStore` loads categories, transactions, and category limits. A new `LimitManager` derives `CategoryBudgetBarData` from:
- active transaction type,
- active summary window,
- categories,
- transactions,
- stored category limits,
- reference date.

The resulting bar list is always:
1. Overview bar for the active transaction type and window.
2. Active-type category bars with spent values calculated for the same window.

Saving a limit calls a MethodChannel-backed repository method. After save, the store reloads limits and recomputes bars.

## UI Components

New focused widgets:
- `CategoryBudgetStage`: Stage1 background layer behind the header card.
- `CategoryBudgetBar`: the expt0926-style 70 px rounded swipeable/tappable bar.
- `CategoryProgressBar`: thin progress strip with white/orange/red fill.
- `CategoryLimitEditorSheet`: limit setting menu based on expt0926 `BudgetPicker`.

`TransactionHeaderCard` keeps its copied Stage0 design. When expanded, `TransactionHomePage` shows `CategoryBudgetStage` behind the header. The bar opens the limit editor on tap.

## Error Handling

Invalid backend limit writes reject missing target/window/type/period data and negative limits. A zero or blank limit saves as `hasLimit=false`, `limitAmount=0`, while preserving the selected alert state as false. If a category is deleted, future bar calculations simply ignore orphaned category limits.

## Testing

Tests cover:
- MethodChannel calls for list/upsert category limits.
- `LimitManager` filtering and period key behavior for monthly/yearly/all-time.
- Progress color thresholds.
- Store save/reload of interval-specific limits.
- Stage1 bar rendering, swipe navigation, and limit editor save behavior.

## Scope Boundaries

This does not implement calendar-selected months yet. It builds the backend and UI around a reference date so the future calendar work can plug in cleanly. It also does not implement notification firing; `alertActive` is stored and displayed so notification behavior can be connected later.
