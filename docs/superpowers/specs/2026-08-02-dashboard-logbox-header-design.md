# Dashboard LogBox Header Design

## Scope and accepted references

- User request: build only the upper LogBox area below the dashboard handler;
  show the current query's transaction count immediately, with debug telemetry.
- Screenshot reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260802-223318.png`.
- Implementation reference:
  `/data/data/com.termux/files/home/spendeetest-review-611a529-bBdUSa/lib/features/transactions/transaction_home_page.dart`
  (`_TransactionListHeader`) and
  `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
  (`spendee-test-transaction-count`).
- Existing Fluvi paths:
  `lib/core/design/dashboard_layout_metrics.dart`,
  `lib/core/design/dashboard_geometry_resolver.dart`,
  `lib/core/design/dashboard_layout_frame.dart`,
  `lib/features/dashboard/presentation/core_dashboard.dart`, and
  `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`.

## Architecture card

### Single source and write path

- Source of truth: `SummaryAmountPresentation.entryCount`.
- Owner: `DashboardSummaryAmountController`; it publishes the same immutable
  presentation used by `DashboardSummaryPill`.
- Write path: current query result or compatible child-summary index →
  `DashboardSummaryAmountController._publish` → `presentation`.
- The LogBox header only reads the presentation. It must not call the query
  controller, modify time navigation, own a count cache, or create a watch.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Query/child-summary count | `DashboardSummaryAmountController` | dashboard | immutable `SummaryAmountPresentation` |
| Header rendering | `DashboardLogBoxHeader` | widget | read-only `ListenableBuilder` |
| Debug dedupe signature | `DashboardLogBoxHeader` | widget | logging-only; never a data source |
| Geometry | `DashboardGeometryResolver` | frame | one bounds result for handler and LogBox header |

### Reuse and layer decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Count publication | `DashboardSummaryAmountController` | Reuse; it preserves immediate preview semantics and zero-query rail previews. |
| Bounds calculation | `DashboardGeometryResolver` | Extend with `logBoxHeaderBounds`; no local position arithmetic. |
| Caption typography/surface | `FluviVisualTokens` and `FluviRoundedBox` | Add/use one semantic caption token; the header itself is transparent, so no duplicate surface primitive. |
| Debug sink | `DashboardQueryDebug` | Reuse its debug-only FLOW sink; emit only a deduplicated presentation change. |

### Layer flow

`DashboardSummaryAmountController` → `SummaryAmountPresentation` →
`DashboardLogBoxHeader`.

The stack order is rail → LogBox header → collapse handler. The header is
geometrically below the handler; retaining the handler as the final layer
keeps its gesture hitbox above any future LogBox content.

## Presentation design

- The header starts exactly at `collapseHandleBounds.bottom` and is 28 logical
  pixels high, matching the Spendee list-header rhythm.
- It contains only centered, muted text: `N tranzakció listázva`.
- It has no card/background, list rows, search, filter, scroll controller, or
  interaction in this slice.
- The displayed count follows `SummaryAmountPresentation.entryCount`, including
  cached child-summary preview values. It updates independently of the query
  read and does not wait for a settled result.
- `DashboardLogBoxHeader` is a `RepaintBoundary` and is the only leaf that
  listens to the amount presentation for this count.

## Debug telemetry

On a changed presentation signature only, emit:

`[FLOW][D11] LOG_BOX_ENTRY_COUNT_BOUND`

with scope/query key, flow id, entry count, preview/loading/stale flags, and
`source=summaryAmountPresentation`. No pointer, animation-frame, or repeated
same-presentation logging is allowed.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LBH-01 | User + screenshot | geometry/frame/core dashboard | Transparent count header is directly below the handler in collapsed, rail-closed, and rail-open geometry. | Geometry + widget test | DONE |
| LBH-02 | User immediate-update requirement | LogBox header + summary amount controller contract | Count renders the same `entryCount` stream as SummaryPill, including preview, without a query write/watch. | Widget/controller test | DONE |
| LBH-03 | Screenshot + Spendee list header | LogBox header widget/tokens | 28 px centered muted caption; no list/search/filter/rows in this change. | Widget/golden inspection | DONE |
| LBH-04 | User layer-order requirement | `CoreDashboard` stack | Handler remains the top input layer; header has no competing gesture region. | Widget hit-test/order test | DONE |
| LBH-05 | User debug-log request | LogBox header + `DashboardQueryDebug` | One D11 record per changed presentation, no repeated same-signature/frame log. | Widget diagnostic test | DONE |
| LBH-06 | Structuring Apps | geometry/tokens/presentation | One geometry resolver and one count source; presentation has no repository/query dependency. | Boundary/direct inspection | DONE |
| LBH-07 | Delivery | relevant tests/golden | Checklist re-read; focused and regression verification are green. | Test output + golden view | DONE |
