# Category movers reference-locked acceptance checklist

Reference: `/storage/emulated/0/spendee/source of truth/change.png` (opened
2026-09-27).  Every item below is a release condition unless explicitly marked
as user-only physical validation.

| ID | Source / intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- |
| REF-01 | §0, §39 / reference image | Exact source file exists and is directly inspected before implementation and final review. | file check + image inspection | DONE |
| DATA-01 | §1, §31 / projection + formatter | Current/reference labels derive solely from actual windows for historical/current Month, historical/current Year, AllTime and Day; no production July/June literals. | pure tests + source review | DONE |
| DATA-02 | §8, §32 / immutable projection | Projection publishes independently bounded top five decreases and increases, while mini-card global highest-impact continuity remains. | projection tests | DONE |
| DATA-03 | §17, §35 / presentation adapter | Cumulative current/reference chart points are prepared outside paint from immutable trend data. | pure fixture test | DONE |
| ARCH-01 | §37 / owners | No repository/query/raw-ledger/UI aggregation, no painter financial work, and local state remains local. | code review + existing tests | DONE |
| OUTER-01 | §3–4, §22–24 / primary-card body | Existing outer bounds, count visibility, dots, controls, nav and carousel are unchanged; white surface, subtle upper tint, crisp resolved border and 22px Movers contour match the reference family. | widget geometry/core-host test + source review | DONE |
| P1-01 | §5–6 / overview header | `Kategóriaváltozás`, dynamic scope/calendar, exact descriptive two-line copy and metrics are rendered. | widget test | DONE |
| P1-02 | §7–8 / overview selector | Real, semantic Csökkenés/Növekedés pills select the correct bounded lists and initialize from the carousel mover sign. | widget + projection tests | DONE |
| P1-03 | §9 / overview rows | Maximum five reference-density rows show rank, badge, label, semantic percent/delta and chevron; old diverging axis is absent. | widget test | DONE |
| P1-04 | §10 / overview footer | Exact explanatory lavender footer is present and layout uses stretch without dead whitespace. The inherited 210px envelope uses one local scroll surface because its fixed reference contents require more than 210px; normal/stretched envelopes remain fully composed. | widget/layout/core-host test | DONE |
| P2-01 | §11–12 / detail header | Back/category header, dynamic scope/calendar and exact explanatory text match page two. | widget test | DONE |
| P2-02 | §13–14 / KPI row | Exactly three equal KPI tiles show current total, percentage and signed delta; reference total is not a fourth tile. | widget test | DONE |
| P2-03 | §15–19 / chart | Dynamic legend, stepped cumulative current/reference chart, grid, endpoint values, Day horizontal marks and bounded stretch assignment match the reference. The same inherited compact envelope uses local scroll. | pure + widget/painter/core-host test | DONE |
| P2-04 | §20–21, §38 / detail footer/state/a11y | Exact footer, safe upstream fallback, back/rows/buttons/chart semantics and 44 px targets are present. | widget test | DONE |
| DEF-01 | §25–30 / canonical defaults | Segmented summary, separators off, straight nav, containedFlat nav and modeContent→direction→summary initialize and remain user-changeable. | unit tests | DONE |
| REG-01 | §24, §37 / scope guard | No balance calculations, query/data boundaries, carousel semantics, Summary navigation, count or BottomNav geometry regress. | focused regression suite + code review | DONE |
| VIS-01 | §39 / visual review | Both full reference pages and the Day mark are compared against change.png/golden evidence for hierarchy, colours, padding and card anatomy. The only responsive exception is the preserved 210px card envelope, whose complete anatomy scrolls locally instead of changing outer geometry. | reference reinspection + screenshot/golden/core-host evidence | DONE |
| FINAL-01 | §40–41 / delivery | Analyzer/tests pass, review complete, commit/push and normal human APK delivery complete. | command logs + Actions APK | NOT DONE |
| USER-01 | §39–41 / physical device | Physical acceptance remains user-only. | user | PENDING — USER ONLY |
