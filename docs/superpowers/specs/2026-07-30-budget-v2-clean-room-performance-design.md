# Budget V2 clean-room performance refactor — design

## Decision and evidence

- User decision, 2026-07-30: **C** — rebuild Budget V2 as its own screen,
  outside the Balance runtime, with maximum practical interaction performance.
- Migration rules: [`docs/migration-guide.md`](../../migration-guide.md), read
  before this design. In particular: clean feature boundary, immutable data
  snapshots, separate physical/settled/committed interaction state, cancelled
  obsolete work, and no heavy work while direct manipulation is active.
- Mandatory visual reference re-read before implementation and final review:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.
  Its header, five-avatar belt, vendor card, type controls, search/filter and
  transaction log are retained product behaviour, not loose inspiration.
- The prior three-mode host refactor intentionally did not alter the hot path:
  `BudgetV2FrameData -> SpendeeBalanceDashboard -> BalanceFrameResolver ->
  TransactionStore.applyBudgetV2AvatarFilter`. That chain is the source of
  post-settlement stalls and is removed from the Budget V2 route.

## Retained behaviour

1. The Budget V2 visual language and accessible keys remain compatible with the
   device reference and current production-contract tests.
2. The belt contains the overview target plus every active category, supports
   swipe, chart-driven selection, immediate pointer pre-emption, and long-press
   limit editing.
3. Overview/category selection is the primary log filter; vendor selection is
   tertiary; search, type, period, filter-chip removal, log actions and limit
   persistence retain their existing outcomes.
4. A category commit still synchronizes the shared `TransactionStore` filter so
   leaving Budget V2 never leaves a stale cross-mode query. That synchronization
   is a cheap final acknowledgement, never an input-frame operation.

## New ownership boundary

`SpendeeBudgetV2Dashboard` becomes a public standalone feature under
`widgets/experimental/budget_v2/`. `SpendeeBudgetModeHost` selects it directly
for `SpendeeDashboardMode.budgetV2`; it does not create the legacy interaction
coordinator, `BalanceFrameInput`, `BudgetV2FrameData`, `SpendeeBalanceDashboard`
or `BalanceFrameResolver` for this route.

The standalone dashboard may reuse visual leaf widgets (brand, header surface,
Budget V2 card art, category icons and transaction-row widgets), but owns all
Budget V2 state, query data and lifecycle itself. It may not call the Balance
dashboard or frame resolver as an adapter.

## Data design

`BudgetV2SnapshotCache` produces immutable `BudgetV2Snapshot` values from a
`TransactionStore` source revision. A snapshot contains exactly one prepared
period record list, overview/category bars, per-avatar vendor distributions,
weekly values, and indexed query data for the visible log. It is refreshed only
when store source/type/period/filter inputs genuinely change; it is never
rebuilt from raw transactions during a drag frame.

The dashboard maintains local Budget V2 query state:

- source scope: type, period, search and any external filter state;
- selected avatar (primary category); and
- selected vendor (tertiary merchant).

The snapshot derives views by indexed lookup/filtering from prepared data. A
final avatar publication updates the local query immediately and then performs
the lightweight store acknowledgement. The existing `applyBudgetV2AvatarFilter`
is changed so it does not synchronously prewarm/rebuild a Balance log before
notifying listeners.

## Interaction state machine

Each gesture has a monotonically increasing generation.

```text
pointer down -> physical rail owner -> local motion/paint only
                         | release / animation end
                         v
                    settled avatar
                         | idle debounce, generation still current
                         v
            committed local query + lightweight store acknowledgement
```

- **Physical state** owns continuous offset and is painted without widget-tree
  rebuilds.
- **Settled state** changes only when a rail target is centred.
- **Committed state** changes at most once per gesture after the idle boundary.
- Pointer-down increments the generation, stops inertia and cancels every
  pending commit. A stale timer/computation cannot publish.

## Rendering design

The avatar rail uses a repaint-driven `Flow`/render layout for the seven
retained logical slots. Continuous drag changes only transforms and paint state.
The SVG/icon children have stable keys and repaint boundaries; a crossed slot
only replaces the newly entering child, while a selection change updates the
former and new selected-orb presentation. No `itemBuilder` recreates SVG/icon
subtrees on every controller tick.

The screen splits static header/belt/card/log regions with repaint boundaries
and narrow listenables. The drag frame does not rebuild the chart, vendor card,
transaction log, `TransactionHomePage`, or `TransactionStore`.

## Performance contract

1. Direct pointer frames make no `TransactionStore` mutation, notification,
   `BudgetV2Snapshot` resolve, `BalanceFrameResolver` call, or log query.
2. A gesture emits no more than one final primary-filter commit.
3. New pointer input cancels a pending commit before drag recognition and is
   accepted immediately.
4. The production diagnostic trace reports bounded per-gesture data: source
   revision, records/bars count, number of physical frames, settled index,
   commit count and final commit duration. It never logs per-frame spam.
5. A real-data-size widget test plus a physical device trace/screenshot are
   required evidence; a successful build alone is insufficient.

## Explicit non-goals

- Rewriting the ordinary Budget, Balance, Balance V2 or Mind screen.
- Changing business calculations, category colors, persisted limits or the
  user-visible Budget V2 composition shown in the reference.
