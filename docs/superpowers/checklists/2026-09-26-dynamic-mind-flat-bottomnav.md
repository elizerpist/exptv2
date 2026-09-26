# 2026-09-26 — Dynamic Mind scale and flat BottomNav stretch

Source authority: the user-approved 2026-09-26 prompts in this conversation.
The prompts are a complete implementation approval; visual/device acceptance remains user-only.

| ID | Requirement | Owner / code area | Acceptance evidence | Status |
| --- | --- | --- | --- | --- |
| DMS-01 | Live Mind-only dynamic mixed-scale setting; existing static path is default | `MindYearHeatmapPresentationSettings` | controller/settings and tuner tests | DONE |
| DMS-02 | Implement exactly five authored ten-stop palettes and score anchors 18/35/58/70/82 | palette resolver | complete exact-array and anchor tests | DONE |
| DMS-03 | Clamp outside anchors and interpolate corresponding stops continuously between anchors | palette resolver | intermediate-resolution tests | DONE |
| DMS-04 | Dynamic heatmap recolors only active cells, leaves empty cells neutral, and animates palette change | Mind heatmap viewport | mounted palette/empty-cell tests | DONE |
| DMS-05 | Legend, active slider gradient, and filled handles use the same resolved scale | Mind core surface/range renderer | mounted widget and resolver tests | DONE |
| DMS-06 | Slider gradient is normalized to the current active segment width while dragging | shared Mind slider presentation adapter | pure geometry anti-false-green test | DONE |
| DMS-07 | Handle-size option defaults normal and reduces only visible handle diameter by 10% | Mind settings/range renderer | visual-size and hit-target tests | DONE |
| FBS-01 | Live global shell setting `off / expandedHeader / modeContent`; default off | `DashboardShellPresentationSettings` | state/controller/tuner tests | DONE |
| FBS-02 | Stretch eligibility is exactly straight-edge plus contained-FAB BottomNav | shell geometry resolver | four-combination eligibility tests | DONE |
| FBS-03 | Derive stretch from resolved SearchPill top and physical BottomNav top; no guessed constant | layout bridge/resolver | relation test at reference and Android viewport | DONE |
| FBS-04 | Expanded-Header target affects expanded height proportionally only; collapsed geometry is unchanged | dashboard geometry resolver | collapsed/midpoint/full geometry tests | DONE |
| FBS-05 | Mode-content target grows the principal Balance/Mind/Budget visual envelope proportionally, not a spacer | resolver/mode surfaces | per-mode geometry tests | DONE |
| FBS-06 | At full expansion SearchPill top aligns to BottomNav top; count remains visible with existing gap | resolved Ledger layout | exact relation tests | DONE |
| FBS-07 | All three modes, all handle styles, and seamless Mind preserve shared downstream geometry and controllers | core dashboard/mode hosts | cross-mode regression tests | DONE |
| FBS-08 | No query, repository, financial, BottomNav, SearchPill semantic, scroll, or carousel-physics change | dependency boundary + regressions | focused regression and source audit | DONE |
| DEL-01 | One application commit, push, exact-source online human APK downloaded to Android Download folder | GitHub Actions/release | SHA-256, APK validation, embedded source identity | NOT DONE |
| DEL-02 | Exact final source SCIP graph and separate factual journal entry | tooling + journal | manifest source SHA, deterministic graph evidence | NOT DONE |
| DEL-03 | Device validation is never overstated | delivery report | `PENDING — USER ONLY` | DONE |

## Re-read gate before commit/build

Re-read this checklist and the two source prompts. Application implementation rows are complete; delivery rows `DEL-01` and `DEL-02` remain open until the exact application SHA is pushed, built, indexed and recorded. Existing user-untracked diagnostics and failure artifacts are outside this package and must remain untouched.
