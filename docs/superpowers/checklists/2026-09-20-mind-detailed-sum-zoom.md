# Mind detailed Sum zoom acceptance checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DSUM-01 | User final prompt | `mind_temporal_heatmap_viewports.dart` | Sum retains heatmap/exact annual/detailed pages in 0/1/2 order | Mounted pager test | DONE |
| DSUM-02 | User final prompt | new pure detail model | Home zoom is Jan–Dec, focal zoom changes temporal range and never zooms farther out | RED/GREEN domain test | DONE |
| DSUM-03 | User final prompt | detail model/widget | Low zoom aggregates; closer zoom exposes increasingly real frame detail without data/query writes | Domain + widget test | DONE |
| DSUM-04 | User final prompt | detailed chart widget | One year fills available plot; two share; 3+ uses vertical scrolling at the two-year minimum | Mounted geometry test | DONE |
| DSUM-05 | User final prompt | detailed chart widget | Every detailed band has Hungarian month initials and monetary Y ticks | Mounted widget test | DONE |
| DSUM-06 | User final prompt | detailed chart widget | Top-right mini line/heatmap toggle is local and leaves range/frame identity unchanged | Mounted interaction test | DONE |
| DSUM-07 | User final prompt | pager/chart gesture layer | Pinch/pan, page swipe, vertical band scroll and slider drag have a single effective owner | Focused gesture tests | DONE |
| POP-01 | User final prompt | `mind_anchored_info_card.dart` | Sum month and Year day popup uses actual cell anchor, moves with a new tap and clamps to page bounds | Mounted Sum/Year tests | DONE |
| LINE-01 | User final prompt/reference | aggregate/detail chart layout | Sum exact and Year monthly charts retain constraint-derived useful plot height with no added fixed dead space | Mounted bounds test | DONE |
| KEEP-01 | Prior approved feature contract | Mind temporal viewports | Year bar/line, Month rhythm, Day timeline, permanent inline legend and contained BottomNav remain intact | Focused regression suite | DONE |
| ARC-01 | structuring-apps | all changed paths | One immutable data source; local state has one owner/write path | Boundary/direct source review | DONE |
| ARC-02 | structuring-apps | detail/popup modules | Shared LOD and popup policy are each single implementations | Domain/widget tests + source review | DONE |
| PERF-01 | User prompt/milestone | projection/chart | Zoom/toggle/selection causes no repository, Room, Query, Time or score work | Instrumented widget/domain assertions | DONE |
| DELIV-01 | User workflow | GitHub/SCIP/journal | Application commit, journal-only child, exact CI/APK/SCIP evidence | Git/Actions/artifact audit | NOT DONE |
| PHYS-01 | User workflow | Android | Physical validation | User-only | BLOCKED |
