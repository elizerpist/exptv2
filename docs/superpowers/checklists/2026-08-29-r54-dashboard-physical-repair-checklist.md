# Dashboard physical repair — revision 54 acceptance checklist

**Status: active release gate.** This record supersedes the closure claim in
`2026-08-29-budget-reliability-and-mind-threshold.md` for the Dashboard
production package. The earlier `G1`–`G5` and delivery `DONE` labels are
invalidated by post-APK physical evidence. A green test or an earlier APK is
not acceptance evidence for any row below.

## Baseline and mandatory inputs

| Item | Recorded value |
|---|---|
| Repository / branch | `elizerpist/exptv2` / `separated-core-modes` |
| Starting local and remote SHA | `4e62e81801520e409ce3b73c4e6dcc5894f42e2f` |
| Previous production parent | `05f4693555de5c4ff63ea4ab1bd6c2d048838cec` |
| Fluvi Logs | Google Doc **Fluvi logs**, revision **54**, rechecked 2026-08-29 |
| Physical references | `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260829-150200.png` (limit/header), `Screenshot_20260829-150556.png` (collapse slab), `Screenshot_20260829-150735.png` (Mind range), `Screenshot_20260829-151147.png` (protected working Header colours) |
| Architecture boundary | `MILESTONE_COMMITS.md`, especially the foreground-input-safe Query/LogBox and prepared-scene baseline |

No Android build and no production push is permitted while a pre-build row is
anything other than `DONE`. There will be one final exact-SHA Android build
only after the whole matrix is green.

## Shared architecture contract

| ID | Source | Intended owner / code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| ARC-01 | Global centralization gate; G1, G2, G3, G5 | Existing typed Dashboard/Query controllers and coordinators | UI collects intent only; one existing or extracted neutral authority owns edit identity, amount domain, and priority scheduling. No duplicate Budget or Mind query state. | Owner-path tests plus source review | DONE |
| ARC-02 | G2/G3 cross-cutting priority | `DashboardCoreController`, drilldown and preparation scheduling | New raw pointer preempts stale ballistic/speculative work without a global motion input lock. | Bounded diagnostic counter tests | DONE |
| ARC-03 | G4/G6 surface model | Budget mode composition, Card2 shell and PageView viewport | Each physical card owns colour/border/radius/shadow once; a content clip is not a surface. | Topology and full-composition raster tests | DONE |
| ARC-04 | P1 / MILESTONE baseline | Header visual engine and palette policy | Retain one ticker, retained backend/program/shader and current category palette identity. | Header visual-engine + rapid-crossing tests | DONE |

## Phase 0 — red physical-proxy gates

| ID | Source instruction | Real owner path / intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| RG-G1 | r54 Screenshot A and G1 | `BudgetTargetAvatarRail` → quick-edit gesture → edit controller → presentation | The first selected-avatar long press reaches a stable recognizer and exact edit context even when Header projection is unavailable. | Production-parent widget/race tests | DONE |
| RG-G2 | Fluvi Logs r54, G2 | Avatar rail → drilldown → focus/query/scene pipeline | 1, 5, 8+ crossings and reversal expose no raw-pixel-scaled I/O/scene/layout work and preserve a coherent semantic bundle. | Ballistic counter integration test | DONE |
| RG-G3 | User report + Fluvi Logs r54, G3 | Time rail / SummaryPill gesture arena and maintenance scheduler | A Summary pointer wins during or immediately after time ballistic; trace exposes the exact former blocker. | Real gesture takeover tests | DONE |
| RG-G4 | r54 Screenshot B, G4 | Full Budget Dashboard split/unified composition | Dense collapse samples identify the real grey-pixel RenderObject/layer and reject a slab in Rhythm, handle and LogBox boundary samples. | Production composition raster/provenance test | DONE |
| RG-G5 | r54 Screenshot C, G5 | Query sheet + Mind host + canonical domain provider | Same semantic scope has deep-equal range values and two actionable endpoints in both hosts; transient facet replacement cannot create 1000/1000. | Cross-host widget/controller parity tests | DONE |
| RG-G6 | r54 Screenshot D, G6 | `BudgetDashboardCoreSurface` / pager | Unified has one common physical surface and a content-only pager viewport; Split has exactly one Card2 shell. | Topology + controller identity tests | DONE |
| RG-G7 | G7 | Partner layout resolver and Rhythm chart | Actual plot allocation is exactly 1.10× starting allocation (44→48.4, compact 35.2→38.72 if governing), with equal outer envelope. | Numeric resolver tests | DONE |
| RG-P1 | r54 Screenshot E, P1 | Header palette/visual engine | Existing category colour behaviour survives rapid Avatar crossing, time change and stale publication. | Existing and strengthened Header regressions | DONE |

## Pre-build release matrix

| ID | Source / code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|
| G1 | Screenshot A; `budget_category_avatar_rail.dart`, quick edit / presentation controllers | Recognizer permanently exists on selected physical Avatar; semantic edit context is independent of Header readiness; first tick creates one session; draft cannot regress through compatible render/query publications; stale writes cannot target another category. | Required cold-frame, unavailable-Header, scope, mutation-race and A→B→A tests; bounded trace. | DONE |
| G2 | r54 Avatar counters; rail, drilldown, focus, Query and scene preparation | Avatar crossing is a cheap prepared promotion, not mini navigation; crossing count/velocity/category feedback are unchanged; no raw-pixel repository/scene work. | Time-vs-Avatar counter comparison and 1/5/8+/reverse ballistic tests. | DONE |
| G3 | r54 Summary maintenance; SummaryPill/time rail and scheduling | Exact lock owner proven and removed; each direct Summary pointer interrupts time ballistic/local return/stale maintenance immediately. | Gesture-arena trace + immediate / 16 / 50 / 100 ms / maintenance tests. | DONE |
| G4 | Screenshot B; full Budget Dashboard composition | Exact grey slab pixel owner proven and repaired; Partner upper region remains intact because its layer/layout owner differs; no slab under dense collapse in Split or Unified. | Full-stack raster/provenance samples, 1→0→1 and interrupted reversal. | DONE |
| G5 | Screenshot C; Query sheet / Mind | Query Menu and Mind use one `QueryAmountRangeControl`, one scope-keyed canonical amount-domain authority and the same applied Query state; explicit unavailable state never masquerades as 1000/1000. | Cross-host parity, host-to-host commit, cold/transient/domain modes tests. | DONE |
| G6 | Screenshot D; unified Budget surface and pager | Unified topology is one common physical card with content-only PageView clip; Split is one Card2 shell; layout toggles retain Avatar/page/focus/controller/position identity. | Surface topology and split→unified→split tests. | DONE |
| G7 | G7; partner geometry / Rhythm renderer | Plot height is another exact +10% of current allocation (44→48.4; compact 35.2→38.72 where applicable), outer Card2 is unchanged, gain equals upper loss. | Numeric allocation tests at 208, 217, split and unified constraints. | DONE |
| P1 | Screenshot E; Header visual engine | Current Category Header colours, contrast, ticker and retained visual identities remain exactly correct. | Palette/backend/program/shader/ticker regression matrix. | DONE |

## Final-only delivery gate

| ID | Source | Acceptance condition | Verification | Status |
|---|---|---|---|---|
| D1 | Flutter delivery policy + this repair mission | After all rows above are `DONE`, one final SHA is pushed once, one prescribed normal human APK workflow succeeds, the APK is downloaded to `/storage/emulated/0/Download/fluvi`, and its SHA-256 is recorded. No intermediate APK build exists. | Exact pushed SHA, Actions run, local file and `sha256sum`. | NOT STARTED |
