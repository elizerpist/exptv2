# Budget category inventory bootstrap checklist

## Architecture card

- Source of truth: `CategoryRepository.watchCategories()` is the sole source
  of the current application category inventory. Its repository ordering is
  preserved.
- Read model: one app-shell-owned `CategoryCollectionController` publishes an
  immutable category list to `DashboardBudgetCategoryPresentation`.
- Write path: category CRUD remains in `CategoryRepository`; this feature adds
  no write path.
- Bootstrap/error owner: `FluviAppShell` starts the collection after demo seed
  and before `DashboardInteractionReadiness`; a first-load error fails the
  existing bootstrap surface.
- Presentation boundary: the Budget adapter and rail receive immutable view
  data only. They have no repository, Query, direction, or database access.
- Reuse decision: retain the existing prepared avatar renderer and
  `CenteredCarousel` motion owner unchanged; this change replaces only the
  upstream category input owner.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCI-01 | Root-cause prompt §3–5 | `core/categories/application` | One collection controller subscribes once, awaits the first inventory emission, publishes immutable meaningful changes, and disposes its subscription. | Unit tests with counting fake repository. | DONE |
| BCI-02 | Root-cause prompt §6–8 | `FluviApp`, `FluviAppShell` | Shell owns/injects one category repository/controller and starts it after demo seed, before readiness. A first-load error uses existing bootstrap failure. | App-shell bootstrap widget tests. | DONE |
| BCI-03 | Root-cause prompt §9, §12 | Budget presentation | Avatar input maps every `FluviCategory` in repository order and is independent of Query facet state and ledger direction. | Presentation unit tests. | DONE |
| BCI-04 | Root-cause prompt §10–11 | Budget rail/core dashboard | The rail receives prepared immutable items only; existing avatar visual, geometry, centered-carousel profile, and tick isolation are unchanged. | Existing rail/geometry/profile/rebuild tests. | DONE |
| BCI-05 | Root-cause prompt §14 | Root/controller/presentation | Bounded startup/input diagnostics report load start, ready/failure, and item changes; no per-tick logging. | Unit/widget diagnostics assertions. | DONE |
| BCI-06 | Root-cause prompt §15–19 | Tests/boundaries | No Query interaction is needed at cold bootstrap; direction and rail motion perform no category I/O; protected Query/LogBox ownership remains unchanged. | App/widget tests and boundary suite. | DONE |
| BCI-07 | Root-cause prompt §20–23 | Existing Budget card1 | Existing card1 bounds remain unchanged while real category avatars appear after cold demo bootstrap. | Geometry widget test plus human APK check. | PARTIAL — automated geometry/ownership coverage is green; normal Android visual verification remains required. |
| BCI-08 | Delivery constraint | Git/build | One focused local commit only; no push, merge, golden test, or production input harness. Human APK status is reported truthfully. | Git/build inspection. | PARTIAL — online APK is intentionally blocked by this task's no-push instruction. |
