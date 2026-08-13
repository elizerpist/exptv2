# Vertical input pause signal crash fix checklist

Source: source-proven crash/livelock report for `query` at `777569ad`.

Architecture card:

- Single owner: `ExplicitCommittedPagingController` owns the one-shot
  vertical-idle waiter along with its sequential committed-page request.
- Cache ownership: `CommittedLogViewportCache` still owns all page text/layout
  resources and atomic publication.
- Lifecycle source: `DashboardCoreController` reports input-idle; it neither
  owns a waiter nor directly commits pages.
- Reuse decision: repair the existing waiter lifecycle. No cache, paging,
  controller, or physics owner is added.

| ID | Requirement | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VIPC-01 | One-shot waiter | paging controller | Completed waiter detaches before completion and cannot be reused by later input | second-pause RED/GREEN test | DONE |
| VIPC-02 | Re-pause race | paging controller | New input after an old release waits on a new signal without spin or reread | same-page re-pause test | DONE |
| VIPC-03 | Scope reset safety | paging controller | Pending and completed waiters are released once; stale page cannot publish | scope-reset tests | DONE |
| VIPC-04 | Dispose safety | paging controller | Dispose releases a waiter and no callback continues into disposed state | dispose test | DONE |
| VIPC-05 | Semantic diagnostics | controller/cache diagnostics | One DEFERRED and one RESUMED event per real pause/resume | focused event-count assertion | DONE |
| VIPC-06 | Physical crash acceptance | normal `lib/main.dart` APK | Repeated vertical pause/resume never crashes, spins, or emits a defer/resume storm | manual Android trace | NOT DONE |
