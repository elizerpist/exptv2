# FastInfo Live Metrics Design

## Goal

FastInfo cards must stop showing saved placeholder numbers. A selected FastInfo card is a metric identity, and its visible value is calculated from current app data every time the transaction state changes. The same metric can appear as a compact pill or as a larger box. The box version should use the extra space for secondary context and a richer visual such as progress, sparkline, bars, ring, or status.

The next build should also seed an empty database with five years of realistic transaction history so scroll, summary, limits, charts, and FastInfo metrics can be tested against several thousand rows.

## Current State

`FastInfoCardDefinition` contains static `pillValue`, `boxValue`, `boxSubtitle`, `progress`, and `visualType` fields. `FastInfoSlot.fromCard` copies those values into persisted settings, and `FastInfoPanel` renders the saved values directly.

`TransactionStore` already holds transactions, categories, recurring ghosts, limits, active window state, and several cached summaries. The FastInfo panel is rendered inside `TransactionHomePage`, so it can receive live metric output without adding a new native bridge.

`ExpenseSeedData` already generates seeded categories, limits, and about 13 months of transactions. It should be expanded to the last five years and versioned so the next build has the larger dataset when bootstrapping an empty database.

## Architecture

Add a Flutter-side metric resolver layer:

- `FastInfoMetricSnapshot`: immutable input assembled from `TransactionStore`, including transactions, categories, limits, recurring ghosts, active summary window, active period reference, active type, and precomputed totals where useful.
- `FastInfoMetricResult`: render model containing `label`, `pillValue`, `boxValue`, `boxSubtitle`, `progress`, `visualType`, and optional chart series.
- `FastInfoMetricsResolver`: maps a `FastInfoSlot.id` to the appropriate calculation and returns a `FastInfoMetricResult`.

`FastInfoSlot` should remain a persisted configuration object. Existing saved `value`, `extra`, and `progress` fields can still be parsed for backwards compatibility, but runtime rendering should prefer resolver output.

`FastInfoPanel` should accept an optional resolver/snapshot or resolved config. In normal home rendering, `TransactionHomePage` passes live resolved values. In settings, `FastInfoOptionsPanel` can use either the same resolver when a store is available or deterministic preview data when only layout editing is needed.

## Metric Behavior

High-priority cards should get specific calculations first:

- daily, weekly, monthly expense totals
- remaining daily/monthly budget and current limit usage
- income, expense, savings, and balance estimates
- trend versus previous comparable period
- last transaction and largest transaction
- top category, merchant concentration, category count, transaction count
- recurring/ghost transaction status where data exists

For catalog cards without a dedicated resolver, return an honest fallback: `Nincs adat`, `0 Ft`, or a generic count/amount based on available data. Do not show catalog placeholder values as live data.

## Pill vs Box

Pill output should be compact:

- one-line value
- short labels only when needed
- no chart or only a tiny status marker if already supported

Box output should be richer:

- title
- primary value
- subtitle explaining context, period, or comparison
- visual based on metric type
- optional chart series for sparkline/bar visuals

The same selected card id should be valid in either a pill slot or a box slot. The renderer decides how much detail to show based on slot type.

## Seed Data

Update `ExpenseSeedData`:

- Generate transactions for the five years ending at the current seed horizon.
- Keep deterministic random generation so tests and performance comparisons are repeatable.
- Preserve realistic category distribution and recurring-like merchant patterns.
- Generate enough rows to exceed several thousand transactions, with monthly income and varied expenses.
- Expand monthly limits for the generated periods.
- Bump `ExpenseSeedData.version` so an empty database in the next build receives the new dataset.

Existing non-empty user databases should not be silently wiped unless the current seed logic already does that. The implementation must inspect `seedIfEmpty` before deciding whether version bump alone affects existing seeded installs.

## Performance

The resolver must avoid expensive full recomputation during scroll or animation:

- Build metrics from cached store data.
- Reuse `TransactionStore` summary/window helpers where practical.
- Keep resolver output immutable and cheap to compare.
- Cache repeated period aggregations inside the resolver or a small helper when one render needs multiple related cards.

The expected data size is several thousand transactions over five years, not hundreds of thousands. A single pass over transactions when the store changes is acceptable; per-frame recomputation is not.

## Testing

Add tests for:

- resolver calculations for daily/monthly totals, remaining budget, trend, last transaction, and fallback metric
- pill and box rendering of the same card id with different detail density
- FastInfo panel updates immediately when transaction data changes
- settings panel still assigns, clears, and hides assigned cards from the pool
- native settings backwards compatibility for old saved slot values
- seed generation covers five years and produces several thousand transactions

Run targeted FastInfo tests, seed tests, `flutter analyze`, and full `flutter test` before implementation is considered complete.

## Open Constraints

The first implementation should prioritize correct live values and stable rendering. Deep bespoke math for every catalog card can be staged after the core resolver exists, as long as no card displays fake placeholder values.
