# Deferred committed-page presentation readiness acceptance checklist

## Architecture card

### Scope and sources

- User requirement: post-`99ebb88` physical Android trace proving a blank committed LogBox virtual page during ballistic scroll.
- Starting head: `99ebb88c968b6d2e1820074bc7c0f8ebde7d073f`.
- Protected Query scheduler work: `026f027c9aabf32557f7cd91c83793385d3217a7` and `99ebb88c968b6d2e1820074bc7c0f8ebde7d073f`.
- Existing implementation: `ExplicitCommittedPagingController`, `CommittedLogViewportCache`, `DashboardCoreController`, `DashboardLogBoxViewport`, and `DashboardLogBoxRenderSurface`.

### Single source and write path

- Exact decoded-but-not-published page: `ExplicitCommittedPagingController._deferredPage`.
- New-page acquisition: the existing serial cursor drain in `ExplicitCommittedPagingController`; it remains the sole repository owner.
- Bounded layout and atomic drawable publication: `CommittedLogViewportCache.prepareAndCommit`.
- Lifecycle signals and ready-ahead priority ownership: `DashboardCoreController`.
- Virtual geometry and fail-closed paint: `CommittedLogViewportCache` plus `DashboardLogBoxRenderSurface`.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| New page acquisition permission | `ExplicitCommittedPagingController` | one drain turn | requires the existing background, motion, raw-pointer and formal-interaction gates |
| Deferred exact page | same controller | exact request identity | retained until exact atomic commit or structural supersede |
| Deferred-page presentation permission | same controller | one presentation-only opportunity | requires current identity, known width, no raw pointer or structural motion; ballistic alone is allowed |
| Ready-ahead reservation | `DashboardCoreController` | current Query publication | stays bound until its target is settled; page 1 commit does not satisfy target 2 |
| Drawable ready frontier / resource gaps | `CommittedLogViewportCache` | current virtual geometry scope | derived from immutable manifest and contiguous committed ordinal |
| Interaction telemetry | `DashboardLogBoxViewport` | one scroll interaction | observes cache/controller state; never schedules I/O or paints content |

### Layer flow

Pointer/scroll UI → `DashboardCoreController` lifecycle signal → `ExplicitCommittedPagingController` → `CommittedLogViewportCache` atomic publication. The repository remains behind the paging controller; the painter remains cache-only and fail-closed.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DPP-01 | Physical root cause | paging controller | No new repository read starts during raw pointer contact, drag, or ballistic. | controllable 67-row/3-page RED-GREEN test | DONE |
| DPP-02 | Physical root cause | paging controller + core | An exact data-ready deferred page can prepare and atomically commit after raw pointer release while formal vertical interaction remains active. | controllable request/count test and diagnostic assertion | DONE |
| DPP-03 | User structural-motion case | core + paging controller | Pointer release remains blocked by structural motion, then motion-idle retries presentation only during ballistic. | deterministic motion-gate test | DONE |
| DPP-04 | User preemption case | cache + paging controller | A new raw pointer stops cooperative preparation at the next existing yield; no partial resource publishes and the same decoded page resumes without reread. | controllable page-preparation-policy test | DONE |
| DPP-05 | User stale case | paging controller | A structurally superseded deferred page cannot publish into new geometry. | supersede test | DONE |
| DPP-06 | Geometry invariant | cache + viewport tests | Deferred ballistic publication does not change virtual extent, max extent, geometry generation, controller/position/physics identity, or content dimensions. | widget and cache tests | DONE |
| DPP-07 | Existing behavior | core + query tests | Zero-move pointer release and Query-sheet reverse ordering keep their existing full ready-ahead behavior. | existing controller/query regressions | DONE |
| DPP-08 | Protected prior commits | core query tests | Query publication reservation/binding and same-target hotset promotion remain unchanged. | existing targeted regressions | DONE |
| DRD-01 | Misleading prepared-pixel trace | cache + viewport | `readyDrawableExtent` and ready-ahead pixels reflect contiguous resource readiness, not full virtual extent, in O(1). | cache/viewport diagnostic tests | NOT DONE |
| DRD-02 | Deduplicated miss trace | viewport + cache | Interaction summaries include current visible resource-gap evidence even when per-ordinal miss emission was previously deduplicated. | visible-gap summary test | NOT DONE |
| DRD-03 | Drawable-window event | cache | Logical visible window and resource-ready/missing ordinal fields are truthful without per-frame log spam. | focused cache diagnostics test | NOT DONE |
| ARC-01 | Global architecture gate | all changed files | No second paging owner/cache/scheduler or UI repository workflow; existing owners are extended. | boundary suite + source inspection | DONE |
| VRF-01 | Automated acceptance | focused and fast suites | Required tests, boundary script, and analyzer are green without weakened assertions. | Ubuntu-proot commands | DONE |
| APK-01 | Global delivery | GitHub Actions / Download | Each production commit has an exact-SHA normal human `lib/main.dart` APK downloaded and checksummed. | Actions + SHA-256 | NOT DONE |
| PHY-01 | Physical acceptance | normal human APK | The supplied manual workflow produces no blank region or virtual/cache miss; automated results are not presented as physical proof. | human Android trace | NOT DONE |
