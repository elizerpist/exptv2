# Query prepared year-window correctness checklist

## Architecture card

### Scope and sources

- User requirement: restore the symmetric `PreparedDashboardIndex` backing
  window for restrictive Query Apply without weakening its correctness guards.
- Functional baseline: `e64e84aededa61f7f41124100309e819eceb269e`.
- Current source: `query` branch at `0a1c9f126636ca8b7dbe665fbb2a1ce4bd0b5f18`.
- Runtime evidence: a 2025-only, expense/category Query builds natively, then
  Dart projection rejects `2025..2025` with “Prepared dashboard year window
  must be symmetric.”

### Ownership and reuse

| Concern | Existing owner | Decision |
| --- | --- | --- |
| Structural backing coverage | `DashboardIndexRequestTemplate` | Restore the one symmetric request policy for every acquisition reason |
| Logical temporal restriction | `DashboardTemporalAvailability` | Preserve as derived Query/navigation data; never use it to resize backing coverage |
| Sparse-index guard | `PreparedDashboardIndexAssembly.zeroUniverse()` | Preserve unchanged |
| Binary request/header parity | prepared-index binary codec | Preserve unchanged |
| Apply publication | `DashboardCoreController.applyQuery()` | Preserve atomic success/failure behavior |

### Data flow

`Query draft → DashboardCoreController → DashboardIndexRequestTemplate →
PreparedDashboardIndex request → native sparse index → binary projection →
DashboardTemporalAvailability-backed navigation publication`

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QPW-01 | §§2–6 | `DashboardIndexRequestTemplate` | Bootstrap, revision and Query requests use `initialYear ± radius`; a restrictive filter never shrinks that window | 12-test local runtime suite: PASS | DONE |
| QPW-02 | §§5, 13 | Index assembly/binary codec | Symmetry guards and binary header checks remain intact | Binary/index tests: PASS; guard source and focused diff inspected | DONE |
| QPW-03 | §§10–14 | `DashboardTemporalAvailability` + catalog | 2013..2037 backing coverage with a 2025-only filter exposes only 2025 to navigation | Core Apply, availability and semantic-catalog regressions: PASS | DONE |
| QPW-04 | §§12, 15–16 | `DashboardCoreController` + composer | 2025/category Apply publishes, updates current scope and closes the composer only after success | Core controller and sheet-Apply widget regressions: PASS | DONE |
| QPW-05 | §§17–19 | Protected systems | No paging, rail physics, scroll, scene or Query UI behavior changes | Focused diff is clean; complete fast/remote CI verification pending | PARTIAL |
| QPW-06 | Default delivery instruction | GitHub CI/release | Focused commit pushed; normal human APK built online and downloaded to `/storage/emulated/0/Download/fluvi` | CI logs + SHA-256 | NOT DONE |
