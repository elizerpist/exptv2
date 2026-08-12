# Query foreground candidate vs. chip-hotset retention checklist

## Architecture card

- **User requirement:** A foreground Query draft/Apply candidate must not
  self-evict behind six speculative chip-removal banks; Income and Expense
  remain separate applied-query templates.
- **Existing owners:** `DashboardCoreController` owns applied chip-neighbour
  scheduling and candidate data; `DashboardLogBoxPreparedSceneCache` is the
  sole owner of retained scene banks and TextPainter resources.
- **Write path:** dashboard direction commit and Query editor lifecycle update
  controller-owned protection; the controller forwards one protected-key set
  to the existing scene cache.
- **Reuse decision:** extend the existing candidate/hotset lifecycle and
  cache-bound enforcement. No parallel data or scene cache is introduced.
- **Layer flow:** UI intent -> `DashboardCoreController` -> existing prepared
  candidate/data runtime -> `DashboardLogBoxPreparedSceneCache` -> atomic
  activation.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QHR-01 | Current physical trace / root cause A | `DashboardCoreController` | Protected applied chip hotset is explicit and matches the authoritative dashboard direction. | Direction lifecycle regression with real scene cache. | DONE |
| QHR-02 | Root cause B | `DashboardLogBoxPreparedSceneCache` | Successful candidate preparation guarantees `hasCandidateWindow`; impossible retention fails explicitly. | Bounded-cache regression test. | DONE |
| QHR-03 | Root cause C | `DashboardCoreController` | Apply emits prepared-hit and activates only an exact retained complete bank. | Restage/activation regression test. | DONE |
| QHR-04 | User lifecycle contract | `DashboardCoreController` | Editor open suspends speculative protection; Cancel restores the active direction's hotset without rollback publication. | Controller/cache lifecycle tests. | DONE |
| QHR-05 | Protected architecture | Controller/cache boundaries | No extra cache, no activation weakening, no rail/physics/paging modification. | Focused architecture inspection and existing dashboard suites. | DONE |
| QHR-06 | Verification | tests/analyze/online APK | Focused tests, broader dashboard tests, analysis and online normal APK build provide evidence. | Local test/analyze evidence complete; online human APK build pending. | PARTIAL |
