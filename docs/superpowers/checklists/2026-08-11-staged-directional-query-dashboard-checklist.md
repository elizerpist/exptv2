# Staged Directional Query Dashboard Checklist

## Architecture card

### Scope and sources

- User requirement: stage full dashboard candidates during Query editing; Apply
  atomically swaps a prepared candidate; Cancel discards it; chips use bounded
  prepared neighbours; income and expense filters remain independent.
- Existing owners: `CurrentQueryController`, `QueryComposerController`,
  `DashboardCoreController`, `DashboardDataRuntime`,
  `DashboardLogBoxPreparedSceneCache`, and the Android dashboard bridge.
- Behavioral comparison: `e64e84aededa61f7f41124100309e819eceb269e` only.

### Single source and write path

| State | Owner | Publication rule |
| --- | --- | --- |
| Applied directional filters | `CurrentQueryController` | `DashboardCoreController` atomically replaces one direction after index/scene activation |
| Editable filter | `QueryComposerController` | Never changes the active index or applied filters |
| Prepared draft candidate/cache | `DashboardCoreController` | Staged only; exact session/key/revision candidate may be consumed or discarded |
| Active index and scene bank | `DashboardCoreController` + existing runtime/cache | Atomically installed only after the candidate structural bank is ready |
| SQL acquisition | Android bridge / `FluviLedgerReadService` | One typed dual-filter prepared-index request |

### Reuse and centralization

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| Staged scene construction | `DashboardLogBoxPreparedSceneCache` | Reuse `prepareWindow` / `activateWindow`; no second cache |
| Index preparation/cancellation | `DashboardDataRuntime` / `PreparedDashboardIndexBuilder` | Extend to exact candidate requests; no UI-owned I/O workflow |
| Applied Query ownership | `CurrentQueryController` | Evolve its single scope into one directional pair, not two controllers |
| Query wire codec | `CurrentLedgerQueryScopeWireCodec` | Extend with one typed directional-pair codec |

### Verification

- Dart unit/controller: directional ownership, staged latest-wins/cancel/apply,
  chip neighbour cache, revision invalidation.
- Dart widget: no count flash; Apply only begins dismissal after prepared
  publication; Cancel has no applied mutation.
- Kotlin/Room/bridge: dual direction predicates and independent prepared frame
  identities.
- Boundary: presentation invokes controller intent only; no Room imports or
  second cache/controller owner.

## Acceptance checklist

| ID | Source requirement | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SQ-01 | Draft live-prepare | Shell/core/runtime/cache | Exact draft index and inactive structural scene candidate start concurrently with facets | Controlled Dart candidate test | DONE |
| SQ-02 | Prepared Apply / zero-work Cancel | Shell/composer/core | Apply consumes exact candidate; Cancel only discards staged work | Controller and widget tests | DONE |
| SQ-03 | Bounded candidate and chip neighbours | Core/cache | Recent candidates and one-chip removals are revision-scoped and bounded | Cache/LRU tests | DONE |
| SQ-04 | Independent direction queries | Query controller/composer | One controller retains independent income and expense templates | Controller regression tests | DONE |
| SQ-05 | Dual-filter prepared index | Dart runtime/Android bridge/core SQL | One index has independent income/expense predicates and frame identities | Dart codec plus Kotlin/Room bridge tests | PARTIAL — Dart transport/index tests pass; Android/Room test execution awaits GitHub CI because Termux/proot cannot start AAPT2. |
| SQ-06 | Direction-specific navigation | Core/time navigation | Direction switch changes active availability without SQL/index acquisition | Navigation regression tests | DONE |
| SQ-07 | Preserve protected architecture | Dashboard/rail/paging | Physics, paging, fail-closed scenes and first-fling behavior remain unchanged | Existing focused suites | DONE |
| SQ-08 | Delivery | CI/release/download | Code is pushed, online build verified, normal human APK downloaded and hash checked | GitHub Actions and SHA-256 | NOT DONE |
