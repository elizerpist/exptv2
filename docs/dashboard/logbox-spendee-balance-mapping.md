# LogBox — Spendee Balance mapping

## Source audit

The visual source is the actual Spendee Balance implementation, not a
screenshot or reconstructed approximation:

- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart`
  - `SpendeeBalanceTransactionLog`: lazy `CustomScrollView`, bounded
    `cacheExtent` (360), query-generation guarded load-more trigger and empty
    surface.
  - `_BalanceTransactionDaySliver`: 20 logical-pixel day-header band, 10
    logical-pixel inter-day gap, stable group keys and a grouped sliver.
  - `_BalanceTransactionRow` and `_BalanceTransactionRowContents`: 55 logical
    pixel row height, `12 × 8` row padding, 10 logical-pixel column gap,
    top separator and name/value alignment.
  - `_BalanceTransactionAvatar`: 34 logical-pixel category badge with a
    gradient and a fixed icon size.
  - `_BalanceTransactionValue`: right-aligned, one-line amount treatment.
- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart`
  - canonical Balance layout constants: day radius 18, row min-height 55,
    avatar 34, row padding `EdgeInsets.symmetric(horizontal: 12, vertical: 8)`
    and group elevation.
- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart`
  - the Balance host keeps the transaction log as its own lazy scroll region
    and uses a query identity to discard stale list work.

## Layout port

| Balance element | Spendee source value/structure | Fluvi implementation |
| --- | --- | --- |
| Day header | 20 high band; title has 7 top inset, 10px bold secondary copy | Same spatial structure via Fluvi typography/token roles |
| Day group | Joined day material, 18px visual corners, rows joined by a 1px divider | One outer `DecoratedSliver`, shared `SliverClipRRect` and transparent row `Material`/`InkWell` surfaces using `AppRadii.logGroup`; this preserves a single visual background while clipping the group and its ripple to the same shape |
| Transaction row | 55px min height; horizontal 12 / vertical 8 padding | Same geometry as a fixed/minimum-height Fluvi row |
| Divider | 1px at the top of every non-first row | Fluvi `FluviVisualTokens.border` separator inset after avatar |
| Avatar | 34px; fixed icon, gradient badge | `CategoryVisualBadge` with `colorId` + `iconId`; no local color, SVG path or icon mapping |
| Copy/value | merchant + category at left; amount + local time right-aligned | Same two-line spatial structure with Fluvi typography, local read-model time and central money formatter; overflow remains layout-stable |
| Day spacing | 10px after each non-final group | Same 10px spatial gap |
| Loading/empty | compact state in the list viewport; no retained stale list under a new query | compact non-shimmer Fluvi placeholder, explicit empty/error state |
| Paging | near-end guard, query generation, bounded cache extent | page coordinator guards cursor/query/revision; Sliver lazy rendering |

## Intentional Fluvi substitutions

- Spendee’s raw `Color`, `BorderRadius.circular(17/18)` and bespoke icon slot
  rendering are **not** copied. Fluvi uses `FluviVisualTokens`, `AppRadii.logGroup`
  and `CategoryVisualBadge`/`CategoryVisualResolver`.
- Spendee row-owned surface fragments exist to preserve its row swipe action.
  Fluvi does not port that interaction here: the required Fluvi result is one
  joined outer material per day, so the group owns its surface, border, clip
  and ripple shape.
- Spendee's edit control is not ported because Fluvi currently has no
  committed entry-details/edit destination. Its reserved action slot is not
  painted; the source's merchant/category and amount/time copy structure is
  still retained.
- No Spendee storage, `TransactionStore`, offstage log-cache widget tree or
  balance-frame state is ported. Fluvi keeps `CurrentQueryController` as its
  canonical scope owner and caches only immutable data/pages.

## Explicit non-ports

- No sticky date header: the audited Balance transaction log does not install
  a sticky header.
- No full-list `AnimatedSwitcher`, hidden/offstage lists, or per-row entry
  queues: none improve the required scope-correct, lazy Fluvi rendering.
