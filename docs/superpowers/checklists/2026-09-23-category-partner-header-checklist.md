# Category/Partner drill-down and Balance Header delivery checklist

Status legend: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

| ID | Source requirement | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CP-01 | Prompt 1 §§12–14, 29 | `DashboardBalanceLinkedProjection`, linked presentation, lower detail state | Existing category/partner ranking is unchanged; entity selection/back are local and never mutate Summary, Query, focus or carousel state. | Projection + mounted parent tests, identity spies | DONE |
| CP-02 | Prompt 1 §§15–18, 26–28 | Bounded category insight DTO/projection and category detail renderer | Scope/direction hero, share, child temporal profile, count-weighted size buckets, exact median/boundaries and DAY low-sample fallback are truthful and category-only. | Focused pure and widget tests | DONE |
| CP-03 | Prompt 1 §§19–28 | Bounded partner insight DTO/projection and partner detail renderer | Scope activity plus all-history cadence, median/Q1/Q3, relationship facts and bounded recent rows are truthful and partner-only. | Focused pure and widget tests | DONE |
| CP-04 | Prompt 1 §§29–38 | Existing lower Balance card | Replacement keeps a still-present entity current, clears a missing entity; vertical scrolling/taps/bounds remain valid with no source work on local interaction. | Mounted detail, rebuild-isolation and source-boundary tests | DONE |
| HP-01 | Prompt 2 §§12–14 | Header tuning + Balance palette catalog/window sampler | Exactly nine named palettes, exact ARGB order, manual 0–100 position and 10–100 window, perceptual three-stop sampling. | Catalog/window/controller tests | DONE |
| HP-02 | Prompt 2 §§10, 13, 18 | Reactive Balance Header policy, `CoreDashboard`, tuner | Balance reacts immediately through the existing visual controller/ticker; palette changes never alter Balance financial authority. | Policy/tuner/Core tests | DONE |
| HP-03 | Prompt 2 §§15–17 | Header physical shell and material paint path | Global opacity is linear 0…1, applied once over an opaque clipped white base for Balance/Budget/Mind in static and Fragment paths; content remains opaque. | Composition/pixel-oriented renderer/widget tests | DONE |
| HP-04 | Prompt 2 §§11, 18 | Header architecture | No second controller/ticker and no query/repository/index/financial-projection work from visual tuning. | Identity/source inspection + focused tests | DONE |
| DL-01 | Both prompts §§39–47 / §§19–21 | Delivery workflow | One coherent application commit after both bundles, validation, one final online human APK, exact-source SCIP, then separate journal-only evidence commit. | Git/CI/APK/graph/journal records | NOT DONE |
| DL-02 | Both prompts | Product hand-off | Do not claim Android physical acceptance. | Final report | NOT DONE |

## Re-read gate before commit/build

Re-read this checklist and the two approved prompt contracts.  The app commit and
single final online build may begin only when CP-01…CP-04 and HP-01…HP-04 are
`DONE`; physical validation remains explicitly excluded from that automation.
