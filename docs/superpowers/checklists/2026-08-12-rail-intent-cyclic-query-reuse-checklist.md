# Rail Intent, Cyclic Parent, and Query Reuse Checklist

## Architecture card

| State | Owner | Write path |
| --- | --- | --- |
| Committed rail visibility and temporal anchor | `DashboardNavigationController` | Existing committed navigation publication only |
| Latest requested rail visibility | `DashboardCoreController` | Monotonic intent epoch; reconciles to one scene-covered commit |
| Parent adjacency semantics | `DashboardNavigationController` | Dedicated cyclic parent derivation for Summary navigation and its hotset |
| Directional query candidate | `DashboardCoreController` / `DashboardDataRuntime` | Immutable candidate; native/data trace required before any partition reuse |

## Acceptance checklist

| ID | Requirement | Code area | Acceptance | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RI-01 | Rail visibility latest intent wins | Core controller | Open/close bursts publish the final requested visibility; stale work cannot overwrite it | Controlled async transition and widget callback tests | DONE |
| RI-02 | Cyclic restricted Summary parent navigation | Time navigation/controller hotset | Restricted parents wrap both directions using allowed semantic values | Domain + wrapped-hotset regression tests | DONE |
| RI-03 | Query pipeline source proof | Core/runtime/native/codec | Trace whether an unchanged direction is acquired, serialized, decoded, and materialized | Source trace plus partition transport/native tests | DONE |
| RI-04 | Safe unchanged-direction reuse, if RI-03 proves it | Runtime/native/index | One immutable index may reuse only immutable unchanged partition resources | Reuse, immutability, codec and native partition tests | DONE |
| RI-05 | Preserve existing readiness architecture | Core/cache/paging | No scene misses; physics, paging, directional query ownership unchanged | Canonical fast suite and boundary tests | DONE |
| RI-06 | Delivery | CI/release/download | One final code push receives one verified online build and downloaded APK | GitHub Actions and SHA-256 | IN PROGRESS |

## Scope constraints

- No rail physics, controller/ScrollPosition identity, SQL ownership, Query UI,
  or fail-closed renderer change.
- No structural sharing until the current native/data path proves that the
  unchanged directional partition is rebuilt.

## Source-proof record

The pre-change candidate path assembled the complete directional query set in
`DashboardCoreController.prepareQueryDraft`, then sent both filters through
`DashboardDataRuntime`, `MethodChannelDashboardDataRuntimeRepository` and
`MainActivity`. `FluviLedgerReadService.preparedDashboardIndex` built one OR
predicate over both directions, serialized both direction lanes in the binary
payload, and Dart decoded/materialized both lanes in
`DashboardPreparedIndexBinaryCodec`.

The new narrow transport requests exactly one `LedgerDirection` only when its
opposite partition has the same immutable core revision and exact filter key.
The result is recomposed into one immutable `PreparedDashboardIndex`; no second
dashboard/index owner or mutable shared staging state is introduced.
