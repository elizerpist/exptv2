# Committed-page scheduler over-yield checklist

## Architecture card

- Existing resource and publication owner: `CommittedLogViewportCache` owns
  private exact-width layouts and the sole atomic committed-page write path.
- Existing scheduling mechanism: the cache-owned
  `_CommittedPagePreparationTask`; no parallel task, page cache or cursor owner
  is introduced.
- Time source: the task measures contiguous synchronous preparation and the
  cache keeps end-to-end `observedPageReadyMicros` for the demand planner.
- Layer flow: viewport demand → `ExplicitCommittedPagingController` sequential
  acquisition → `CommittedLogViewportCache` private preparation → atomic
  drawable cache publication.
- Reuse decision: extend the existing cache-local cooperative task and its
  injected scheduler seam. No shared second consumer exists.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CPY-01 | Physical 24-row trace | preparation task | Actual contiguous time, not a two-row cap, is the primary yield boundary | Deterministic policy + cache tests | DONE |
| CPY-02 | Cooperative-preparation contract | preparation task | Budget exhaustion yields only when later private work remains | Deterministic policy + cache tests | DONE |
| CPY-03 | Terminal slice rule | preparation task | Final required item commits without a scheduler handoff | Deterministic policy + cache tests | DONE |
| CPY-04 | Diagnostic requirement | cache diagnostic | Wall, UI, aggregate/largest scheduler wait and yield count are separated | Injected wait diagnostic test | DONE |
| CPY-05 | Existing page contract | cache/controller | Atomic, exact-width, stale/preempted and serial-cursor behavior remains | Focused 89-test suite | DONE |
| CPY-06 | Previous `4f0acd4b` regression | viewport/cache | Forward scroll does not request previous pages; backward remains bounded | Viewport/cache/controller regression suite | DONE |
| CPY-07 | User constraints | touched sources | No physics, retention, Query, rail, native or planner semantic changes | Final diff + boundary inspection | DONE |
| CPY-08 | Delivery | query branch | Tests, analyzer, scoped commit, push and online normal APK evidence | Commands/Actions | DONE |
| CPY-09 | Physical acceptance | normal `lib/main.dart` APK | Device trace confirms reduced scheduler suspension and natural fling | Manual device trace | NOT DONE |
