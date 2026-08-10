# Query direction and Apply correctness checklist

## Architecture card

### Scope and sources

- User requirement: production Query direction and Apply-pipeline correctness fix.
- Functional baseline: `e64e84aededa61f7f41124100309e819eceb269e`.
- Current implementation: `query` at `f7c88f4fe951a3275826512bb6b5dec1935fdc37`.
- Runtime evidence: dashboard is expense while the Query prepared-index key is
  income; native prepared-index validation rejects `acquisitionReason=query`.

### Single source and write path

- Applied scope: `CurrentQueryController`.
- Direction composition write path: `DashboardCoreController.selectDirection()`.
- Draft: `QueryComposerController`; it never writes the applied scope.
- Apply workflow: `DashboardCoreController.applyQuery()`.
- Facet/read persistence: `QueryMenuRepository` → Android bridge → Fluvi core.
- Error/retry owner: `DashboardCoreController.applyQuery()` with sheet-local
  in-flight presentation state in `FluviAppShell`.

### Reuse and centralization

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Applied Query state | `CurrentQueryController` | Extend; no second owner |
| Direction transition | `DashboardCoreController` | Centralize there |
| Wire reason validation | Android dashboard bridge | Extract one native allow-list policy |
| SQL facet semantics | `FluviLedgerReadService.queryMenuFacets()` | Preserve; add parity coverage |
| Diagnostics | `FluviDiagnosticLogger` | Extend semantic lifecycle stages |

### Layer flow

`FluviAppShell → DashboardCoreController → DashboardDataRuntime → MethodChannel → MainActivity → Fluvi core/Room`

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QDA-01 | Direction invariant | `DashboardCoreController` | Direction change keeps dashboard, presentation and applied Query direction equal when no composer edit session is open | Core controller unit test | DONE |
| QDA-02 | Query open correctness | composer + facet controller | Opening after an expense switch yields an expense draft and expense facet request | Unit tests / request capture | DONE |
| QDA-03 | Native Apply contract | Android dashboard bridge | Only bootstrap, databaseRevision and query can build an index | Android unit test written; local Robolectric/Gradle run is blocked before tests by the Termux AAPT2 daemon | BLOCKED |
| QDA-04 | Atomic Apply | core + shell | Successful query preparation publishes once, completes the composer and closes the sheet; failure keeps it open | Controller/widget tests | DONE |
| QDA-05 | Apply lifecycle | core + shell | One in-flight apply cannot start duplicate generations and retry works after failure | Focused controller/widget test | DONE |
| QDA-06 | Facet parity | Fluvi core | Direction and temporal prefilter produce count/categories/partners/months from the exact intended scope | Robolectric Room test written; local run is blocked before tests by the Termux AAPT2 daemon | BLOCKED |
| QDA-07 | Diagnostics | app shell/controllers | Bounded Query open/facet/apply lifecycle emits canonical identities/counts | Code inspection + focused tests | DONE |
| QDA-08 | Protected dashboard | runtime/motion | Paging, rail physics, carousel/scene ownership stay unchanged | Diff inspection + 124-test fast suite | DONE |
