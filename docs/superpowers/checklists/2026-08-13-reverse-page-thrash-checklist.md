# Reverse committed-page thrash checklist

## Architecture card

- Scroll intent owner: `DashboardLogBoxViewport` receives the canonical signed
  `ScrollUpdateNotification.scrollDelta`.
- Acquisition owner: `ExplicitCommittedPagingController` remains the only
  keyset page reader; it does not infer gesture direction.
- Cache owner: `CommittedLogViewportCache` remains the only owner of complete
  page layouts, exact geometry and its five-page/byte-bounded working set.
- Reuse decision: extend the existing viewport demand decision. No second
  gesture recognizer, paging controller or retained-page store is introduced.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RPT-01 | Physical forward-thrash trace | viewport | Positive forward `ScrollUpdate` at the lower retained boundary never requests a previous page | RED/GREEN widget regression | DONE |
| RPT-02 | Reverse paging contract | viewport + paging controller | A negative update at that boundary requests the immediate prior ordinal once and the cache retains it | Widget/controller regression | DONE |
| RPT-03 | Directional retention contract | committed cache | A real backward visible window retains a just-committed prior page without expanding the hard bound | Cache regression | DONE |
| RPT-04 | `a6ecfc` frontier contract | paging/cache/viewport | Exact next page may still commit during a live ballistic interaction | Existing ballistic regression | DONE |
| RPT-05 | User constraints | touched sources | No changes to physics, page count/bytes, fake extent, controller identity or cache ownership | Diff + boundary/focused tests | DONE |
| RPT-06 | Delivery | query branch | Focused/broader tests, analyzer, one scoped commit and online APK | Command/Actions evidence | PARTIAL |
| RPT-07 | Physical acceptance | normal `lib/main.dart` APK | Forward pass has no previous page requests; deliberate reverse uses bounded sequential previous requests | Manual Android trace | NOT DONE |
