# Committed vertical runway — acceptance checklist

## Architecture card

| Concern | Existing owner | Change | Single write path |
| --- | --- | --- | --- |
| Sequential keyset requests and idle prewarm intent | `ExplicitCommittedPagingController` | Retain one exact-scope hotset intent across closed foreground gates | Controller serial drain |
| Prepared pages, text resources, retention and geometry | `CommittedLogViewportCache` | Split private prepared frontier from Flutter-exposed runway frontier | Complete cache page commit and explicit runway publication |
| Scroll demand and physical input | `DashboardLogBoxViewport` | Reports interaction start/update/end and geometry consumption only | Stable framework position |
| Lifecycle gates | `DashboardCoreController` | Triggers idempotent retry only at existing lifecycle boundaries | Existing orchestration callbacks |

No new cache, cursor owner, ScrollController, ScrollPosition or physics path is allowed. Render code reads only cache-exposed exact geometry and never creates text layouts.

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VCR-01 | Root cause A | Paging controller | Gate-closed root retains exact hotset intent; idle retry starts once without timer | RED/GREEN controller tests | DONE |
| VCR-02 | Root cause A | Core lifecycle | Post-layout, motion-idle, query/editor release and pipeline-idle retry current intent idempotently | Controller/core/query tests | DONE |
| VCR-03 | Root cause A | Paging controller | Scope/revision/query supersession prevents old intent/page publication; foreground promotion still reuses one request | Controller tests | DONE |
| VCR-04 | Root cause B | Cache | Prepared frontier can advance privately without changing exposed frontier/extent or geometry notifier | RED/GREEN cache tests | DONE |
| VCR-05 | Root cause B | Cache + viewport | Low-watermark/idle rules publish all currently contiguous prepared pages in one exact runway batch | Cache/widget tests | DONE |
| VCR-06 | User invariants | Cache retention + renderer | Exposed visible pages/root remain drawable; five movable pages and fail-closed text/cache behaviour persist | Regression/boundary tests | DONE |
| VCR-07 | Delivery | Git/CI/APK | Two focused commits, analysis/tests/push/build, physical verification explicitly pending | Verification evidence | PARTIAL — local tests/analyzer complete; normal physical APK test remains required |
