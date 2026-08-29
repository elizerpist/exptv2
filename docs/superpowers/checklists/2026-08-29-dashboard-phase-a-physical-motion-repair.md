# Dashboard Phase A Physical Motion Repair Checklist

Baseline: `separated-core-modes` at `b1ec0798a2608d3a8b9a4c81a023f936255d7c86`.
Source: approved user Phase A requirements, Fluvi Logs revision 49,
`MILESTONE_COMMITS.md`, supplied Android screenshots, and
`docs/superpowers/specs/2026-08-29-dashboard-phase-a-physical-motion-repair-design.md`.

| ID | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|
| A-COLL-01 | Card2 pager/cascade | Partner stays Partner through full collapse and expansion. | Controlled progress test passes; Android slow/fast repetitions still required. | PARTIAL |
| A-COLL-02 | Card2 pager/cascade | Category stays Category through full collapse and expansion. | Controlled progress test passes; Android repetitions still required. | PARTIAL |
| A-COLL-03 | expansion/pager boundary | Vertical motion emits no semantic Card2 page change or pager navigation. | Event collector/source test passes; Android still required. | PARTIAL |
| A-COLL-04 | `CoreDashboard`/pager | PageController and attached ScrollPosition identities remain stable. | Assertions at every controlled progress value pass; Android still required. | PARTIAL |
| A-LAYER-05 | cascade/pager/surface | No grey/neutral Card2 slab occurs. | Actual-composition raster passes; Android still required. | PARTIAL |
| A-LAYER-06 | cascade/pager/surface | Slab removal is owner/clip correction, not a cover/snapshot. | Source/path review passes; Android still required. | PARTIAL |
| A-LAYER-07 | pager viewport | Inactive Category/Partner sibling never occupies visible Card2. | Partner/Category raster samples pass; Android still required. | PARTIAL |
| A-EDGE-08 | physical shell | Card2 radius stays stable. | One physical shell/rounded clip topology passes; physical raster sequence still required. | PARTIAL |
| A-EDGE-09 | physical shell | Card2 border stays stable. | One physical shell topology passes; physical raster sequence still required. | PARTIAL |
| A-EDGE-10 | physical shell | Card2 shadow stays coherent. | One physical shell topology passes; physical raster sequence still required. | PARTIAL |
| A-EDGE-11 | cascade composition | No sibling edge flash. | Dynamic clip/competing shell removed; Android still required. | PARTIAL |
| A-EDGE-12 | cascade composition | No repeated edge brightness shimmer. | Dynamic clip/opacity topology removed; Android still required. | PARTIAL |
| A-HEADER-13 | motion host/Header | Smooth Header uses one master progress owner. | Existing topology suite passes; Android still required. | PARTIAL |
| A-HEADER-14 | Header renderer/backend | Header resource identity stays stable during resize. | Controlled resize identity test passes; Android still required. | PARTIAL |
| A-AVATAR-15 | avatar rail | Avatar ballistic remains natural. | Real WidgetTester ballistic passes; Android comparison still required. | PARTIAL |
| A-AVATAR-16 | avatar hot path | Avoidable heavy work does not scale with pixel updates. | Existing root-build/crossing protection passes; physical profiling still required. | PARTIAL |
| A-INPUT-17 | Summary/avatar | Summary accepts direct input while Avatar ballistic is active. | Real Avatar ballistic → Summary fling test passes; Android still required. | PARTIAL |
| A-INPUT-18 | Summary/avatar | No approximately two-second Summary lock. | Immediate direct-input test passes; timed Android repetition still required. | PARTIAL |
| A-INPUT-19 | motion lanes | Summary direct input does not require global idle. | Direct lane source/test passes; Android still required. | PARTIAL |
| A-INPUT-20 | direct input | Latest Avatar/Summary direct input wins. | Avatar→Summary→Avatar test passes; Android still required. | PARTIAL |
| A-PROTECT-21 | live interaction | Cache-independent latest-wins presentation remains correct. | Focused live-interaction suite passes; Android still required. | PARTIAL |
| A-PROTECT-22 | pager | Horizontal Card2 page drag works. | Pager widget test passes; Android still required. | PARTIAL |
| A-PROTECT-23 | Partner surface | Partner list vertical scroll works. | Scroll handoff widget test passes; Android still required. | PARTIAL |
| A-PROTECT-24 | LogBox | Stable LogBox controller/position/physics and scroll work. | Core suite passes; dedicated invariant suite still required. | PARTIAL |
| A-PHYSICAL-25 | Android delivery | All A requirements pass on normal human APK. | Exact-SHA Action, downloaded APK, SHA-256, device matrix. | BLOCKED |
| B-GATE-01 | palette source | No Phase B production work before A-PHYSICAL-25 is done. | Diff/checklist review. | BLOCKED |

`A-PHYSICAL-25` is not done until an exact pushed production APK has been
installed and the listed gestures have been physically exercised. A missing
device or unavailable build service leaves it `BLOCKED`, not accepted.
