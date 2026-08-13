# Committed vertical frontier through fling checklist

## Committed vertical frontier architecture card

### Scope and sources

- User requirement: remove the artificial committed-page frontier stop during
  a vertical drag or ballistic fling without changing scroll physics.
- Current physical evidence: a decoded next page is deferred until
  `ScrollEndNotification`, so the stable `ScrollPosition` reaches the exact
  currently published `maxScrollExtent` before the drawable frontier grows.
- Existing implementation paths:
  - `lib/features/dashboard/runtime/application/explicit_committed_paging_controller.dart`
  - `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
  - `lib/features/dashboard/application/dashboard_core_controller.dart`
  - `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`

### Single source and write path

- Source of truth: `CommittedLogViewportCache` owns complete committed pages,
  prepared layouts and exact drawable geometry.
- Sequential acquisition owner: `ExplicitCommittedPagingController` owns the
  keyset cursor and may advance it only after an atomic page commit.
- Input orchestration: `DashboardCoreController` keeps vertical interaction
  state only for speculative scene/query work; it must not stop exact frontier
  readiness.
- Publication rule: an exact page becomes drawable only after its complete
  bounded cooperative preparation; no speculative extent is published.

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Exact vertical page presentation | `CommittedLogViewportCache` | private cooperative prepare then atomic commit | Extend existing cache task; no second cache/task owner | Paging/cache tests |
| Keyset page demand | `ExplicitCommittedPagingController` | sequential cursor ownership | Retain controller path; remove only vertical-input pause policy | Paging tests |
| Vertical input priority | `DashboardCoreController` | suppress speculation, not frontier work | Keep current lifecycle signal for speculative work only | Controller/widget inspection |

### Layer flow

`DashboardLogBoxViewport` intent/demand -> `DashboardCoreController` orchestration ->
`ExplicitCommittedPagingController` sequential acquisition -> repository ->
`CommittedLogViewportCache` exact presentation and publication.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CVF-01 | Physical root cause | paging controller/cache | Exact next page commits while vertical input remains active; no idle wait or second read | RED/GREEN controller test | DONE |
| CVF-02 | Cursor invariant | paging controller | Active-input forward demand commits ordinals sequentially without duplicates or gaps | RED/GREEN controller test | DONE |
| CVF-03 | Rail isolation | paging controller/cache | Rail/structural motion still rejects stale page work before publication | Focused regression test | DONE |
| CVF-04 | Fling contract | viewport | A same stable ballistic interaction can observe exact frontier growth beyond the old extent | Non-golden widget regression | DONE |
| CVF-05 | User constraints | controller/cache/viewport | No physics, identity, fake extent, render-time layout, or working-set policy change | Code inspection + boundary tests | DONE |
| CVF-06 | Diagnostics | cache/controller | Ordinary frontier paging emits no vertical-input deferred/resumed lifecycle events | Focused diagnostic assertion | DONE |
| CVF-07 | Delivery | query branch | Focused suites, broader relevant suites, analyzer, clean scoped commit, pushed online APK | Command evidence + GitHub Actions | PARTIAL — local verification is green; commit, push and online APK remain pending |
| CVF-08 | Physical acceptance | normal `lib/main.dart` profile APK | Device confirms page commit/frontier growth before ballistic ends and no cache misses | Manual Android trace | NOT DONE |
