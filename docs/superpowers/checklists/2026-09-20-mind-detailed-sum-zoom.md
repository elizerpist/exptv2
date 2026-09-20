# Mind detailed Sum zoom acceptance checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DSUM-01 | Superseded by physical feedback | `mind_temporal_heatmap_viewports.dart` | Historical three-page Sum contract | Physical feedback rejects it | NOT DONE — superseded; exact annual Sum page and PageView must be removed |
| DSUM-02 | User final prompt | new pure detail model | Home zoom is Jan–Dec, focal zoom changes temporal range and never zooms farther out | RED/GREEN domain test | DONE |
| DSUM-03 | User final prompt | detail model/widget | Low zoom aggregates; closer zoom exposes increasingly real frame detail without data/query writes | Domain + widget test | DONE |
| DSUM-04 | User final prompt | detailed chart widget | One year fills available plot; two share; 3+ uses vertical scrolling at the two-year minimum | Mounted geometry test | DONE |
| DSUM-05 | User final prompt | detailed chart widget | Every detailed band has Hungarian month initials and monetary Y ticks | Mounted widget test | DONE |
| DSUM-06 | Physical Android feedback | detailed chart widget | Toggle is direct two-state local presentation state | Mounted topology test | DONE |
| DSUM-07 | Physical Android feedback | pager/chart gesture layer | Pinch/pan, vertical band scroll and slider drag have a single effective owner | Production-parent noisy pinch test | PARTIAL — production-parent noisy pinch/pan/scroll controls are GREEN; Android recognizer cadence remains user-only |
| POP-01 | User final prompt | `mind_anchored_info_card.dart` | Sum month and Year day popup uses actual cell anchor, moves with a new tap and clamps to page bounds | Mounted Sum/Year tests | DONE |
| LINE-01 | User final prompt/reference | aggregate/detail chart layout | Sum exact and Year monthly charts retain constraint-derived useful plot height with no added fixed dead space | Mounted bounds test | DONE |
| KEEP-01 | Prior approved feature contract | Mind temporal viewports | Year bar/line, Month rhythm, Day timeline, permanent inline legend and contained BottomNav remain intact | Focused regression suite | DONE |
| ARC-01 | structuring-apps | all changed paths | One immutable data source; local state has one owner/write path | Boundary/direct source review | DONE |
| ARC-02 | structuring-apps | detail/popup modules | Shared LOD and popup policy are each single implementations | Domain/widget tests + source review | DONE |
| PERF-01 | User prompt/milestone | projection/chart | Zoom/toggle/selection causes no repository, Room, Query, Time or score work | Instrumented widget/domain assertions | DONE |
| DELIV-01 | User workflow | GitHub/SCIP/journal | Application commit, journal-only child, exact CI/APK/SCIP evidence | Git/Actions/artifact audit | DONE — workflow `35476787935` is recorded as profile-gate FAIL; APK and exact-source SCIP are present |
| PHYS-01 | User workflow | Android | Physical validation | User-only | BLOCKED — explicitly reserved for the user |

## 2026-09-20 — physical Sum zoom repair acceptance inventory

### Architecture card

- **Financial source/read model:** resident `MindYearHeatmapPreparedContribution`
  data is retained by `MindSumHeatmapProjection`; its preview produces one
  immutable current-range Sum detail series. No widget, gesture callback,
  Query, repository, Room or Core writes that source.
- **Presentation write paths:** `_MindSumHeatmapContentState` is the sole
  writer of the local `heatmap`/`detailed` surface choice, via the top-right
  toggle. `_MindDetailedSumYearBandState` is the sole writer of its local
  time window. The range slider remains the sole range writer.
- **Shared-mechanism decision:** detail bucketing/LOD is one pure domain
  policy shared by chart rendering/tests; anchored-info-card remains the one
  popup policy. `DashboardPagedVerticalBoundaryHandoff` remains owned by Year
  only after Sum removes its PageView; no second handoff implementation.
- **Layer flow:** prepared contribution → Sum projection → immutable frame →
  pure detail LOD → detail renderer. Gesture state never crosses back into
  Core/Query/repository layers.

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUM-TOPO-01 | Physical feedback | `mind_temporal_heatmap_viewports.dart` | Sum exposes exactly heatmap and detailed surfaces; exact annual page, PageView, controller and swipe affordance are absent; generic Mind placeholder dots are not a Sum page indicator | Mounted topology RED→GREEN + source review | DONE |
| SUM-TOPO-02 | Physical feedback | Sum content state | Only the top-right toggle writes the surface; a toggle retains the admitted frame/range identity | Mounted interaction test | DONE |
| SUM-GEST-01 | Physical feedback | Sum surface/detail chart | Production-parent noisy two-pointer pinch changes only detail time window; collapse progress, visual surface and frame identity stay fixed | Production-parent widget RED→GREEN | DONE |
| SUM-GEST-02 | Protected interaction contract | detail chart/scroll boundary | Zoomed horizontal one-pointer drag pans; home horizontal drag does nothing; 3+ year vertical scroll and genuine one-pointer outward handoff remain valid | Mounted gesture controls | DONE |
| SUM-DATA-01 | Physical feedback | Sum projection/frame | Frame retains range-filtered transaction-time observations, including multiple same-day times, with no repository/Room query | Domain projection RED→GREEN | DONE |
| SUM-LOD-01 | Physical feedback | detail domain model | Home overview has an explicit coarse anchor budget; zoom progressively shrinks bucket span; deep window represents every eligible transaction and preserves extrema without fabrication | Dense pure-model RED→GREEN | DONE |
| SUM-RANGE-01 | Scope/performance lock | Sum projection/detail renderer | Range preview refreshes immutable detail series without repository, Room, Query mutation or index rebuild | Projection hot-path test | DONE |
| SUM-LAYOUT-01 | Existing accepted feature | detail renderer | 1-year expanded, 2-year split, 3+-year minimum band/vertical scrolling and axes remain | Mounted regression test | DONE |
| SUM-NOREG-01 | Scope lock | Year/Month/Day/range | Year pager, Month rhythm, Day timeline and one range owner remain intact | Focused smoke suites | DONE |
| ARC-03 | structuring-apps | affected domain/presentation files | One read-model and one LOD policy; no UI data workflow or duplicate gesture/handoff engine | Boundary/source review + focused test | DONE |
| DELIV-02 | User workflow | GitHub/SCIP/journal | Exact final application CI/APK/SCIP and journal evidence | Actions/artifact/graph audit | NOT DONE |
| PHYS-02 | User workflow | Android | User accepts the exact next APK | User-only | BLOCKED |
