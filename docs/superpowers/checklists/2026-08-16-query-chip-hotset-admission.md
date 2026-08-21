# Query-chip hotset admission

| ID | Source | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HAA-01 | User: admission before native/index build | `DashboardLogBoxPreparedSceneCache` capability + `DashboardCoreController` planner call | A structurally unadmittable seventh hotset member is deferred before `prepareQuery` | Core/controller regression with build counters | DONE |
| HAA-02 | User: cache retains capacity ownership | scene-window coordinator contract | Controller receives an admission result; it does not duplicate cache limits | Cache planner/unit + boundary inspection | DONE |
| HAA-03 | User: deterministic priority | Query-chip target ordering | Sorted category then partner removals precede clear-all; overflow is deterministic | Unit regression | DONE |
| HAA-04 | User: no build-and-drop broad candidate | query chip prewarm | Deferred broad/unfiltered target has zero partition/index builds until admitted | Counting repository regression | DONE |
| HAA-05 | User: protected leases stay safe | prepared scene cache | Overflow does not evict or dispose protected banks/resources | Existing lease suite + new overflow regression | DONE |
| HAA-06 | User: preserve prepared chip Apply | controller/query semantics | Admitted removal remains chip prepared hit and Apply prepared hit | Query application regression | DONE |
| HAA-07 | User: preserve scrolling/first paint | existing presentation/paging contracts | No renderer, paging, controller, position, or physics change | Diff + protected regression suites | DONE |
| HAA-08 | User: diagnostics | query hotset planner | Deferred capacity path is explicit; unexpected retention reject stays visible | Diagnostic assertions | DONE |
| HAA-09 | Global delivery | GitHub Actions / normal APK | Commit, push, exact SHA normal APK download, SHA-256 | CI job + downloaded artifact | DONE |
| HAA-10 | User: physical Android verification | normal `lib/main.dart` APK | Human validates deferred/prepared hotset and unchanged scrolling | Physical checklist | PARTIAL |

## Architecture card

- **Single source of scene capacity and protected leases:** `DashboardLogBoxPreparedSceneCache`.
- **Single source of logical priority:** `DashboardCoreController`, from the applied Query's canonical chip-removal targets.
- **New flow:** controller produces ordered identities → cache returns/installs an admitted subset → controller dispatches only admitted speculative data/index work.
- **Foreground Apply:** remains an exact candidate path and may request admission at foreground priority; it never copies cache limits.
- **No visual/paging owner changes:** render surface, viewport, committed paging and swipe paths stay untouched.

## Plan
