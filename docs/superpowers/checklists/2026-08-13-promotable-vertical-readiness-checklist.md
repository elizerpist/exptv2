# Promotable committed vertical readiness — acceptance checklist

## Architecture card

### Scope and sources

- User requirement: current request beginning at verified `d588b5ea`.
- Comparison points: `e64e84a`, `5f3898`, `610925`, and current `d588b5ea`.
- Existing implementation paths:
  - `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
  - `lib/features/dashboard/runtime/application/explicit_committed_paging_controller.dart`
  - `lib/features/dashboard/application/dashboard_core_controller.dart`
  - `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`

### Single source and write path

- Prepared page/text-resource source of truth: `CommittedLogViewportCache`.
- Sequential cursor/request source of truth: `ExplicitCommittedPagingController`.
- Scroll demand source: `DashboardLogBoxViewport`.
- Structural and Query foreground ownership: `DashboardCoreController`.
- Only drawable publication path: complete exact-width private page → cache atomic commit.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Preparation urgency/progress | `CommittedLogViewportCache` private operation | Exact page identity | Never exposes partial rows or headers |
| Sequential cursor/demand | `ExplicitCommittedPagingController` | Exact committed scope | Advances only after atomic page commit |
| Background-hotset scheduling | `ExplicitCommittedPagingController` | Exact scope, idle only | Reuses same request/task when demand promotes it |
| Pointer/gesture intent | `DashboardLogBoxViewport` | Interaction | Sends only demand; owns no page data/resources |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Committed page preparation | `CommittedLogViewportCache` | identity, text resource disposal, atomic publication | Extend its private task with urgency | Cache tests cover promotion and stale disposal |
| Keyset paging/prewarm | `ExplicitCommittedPagingController` | one serial cursor chain | Extend existing drain; no parallel owner | Controller tests cover no duplicate request/cursor advancement |

### File-size justification

`CommittedLogViewportCache` is already a cohesive resource/geometry/retention owner. The urgency operation remains a private helper in that owner; no new cross-layer cache or renderer is introduced. A separate cache would violate the single-owner invariant.

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CVR-01 | Commit 1 | Cache private preparation operation | Background task dynamically promotes without restart, reread, or disposal | Cache RED/GREEN test | DONE |
| CVR-02 | Commit 1 | Cache publication | Critical task remains private until complete and still rejects stale width/scope | Cache tests | DONE |
| CVR-03 | Commit 1 | Paging controller | Cursor remains serial and advances only after atomic promoted commit | Controller tests | DONE |
| CVR-04 | Commit 1 | Diagnostics | Start/promotion/final urgency and scheduler-wait breakdown are bounded and attributable | Diagnostic tests/code inspection | DONE |
| CVR-05 | Commit 2 | Paging controller + core gate | Idle root prewarms only immediate bounded forward hotset; no Query/rail/input barrier | Controller/core tests | DONE |
| CVR-06 | Commit 2 | Paging/cache reuse | User demand promotes/reuses in-flight background work with one native read | Controller/cache tests | DONE |
| CVR-07 | User invariants | All touched paths | Query independence, five-page bound, controller/position/physics and fail-closed rendering are unchanged | Focused cache/paging/viewport/query regressions + inspection | DONE |
| CVR-08 | Delivery | Git/test/CI | Two scoped commits, tests/analyzer, push/build evidence, physical APK pending explicitly | Verification log | PARTIAL |
