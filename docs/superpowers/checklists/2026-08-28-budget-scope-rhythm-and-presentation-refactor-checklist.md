# Budget scope rhythm and presentation refactor — acceptance checklist

**Status:** active — all implementation items begin `NOT DONE`.  
**Accepted design:** `docs/superpowers/specs/2026-08-28-budget-scope-rhythm-and-presentation-refactor-design.md`  
**Baseline:** `3127abc018ddea7694661e25015790dcd773bf9e`; Drive *Fluvi Logs* revision 45.

| ID | Source | Intended owner / area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BASE-01 | User prompt | worktree | Branch is `separated-core-modes`; pre-existing prototype work is untouched | status/diff before and after | DONE |
| ARC-01 | AGENTS architecture gate | dashboard runtime/application/presentation | One indexed prepared fact source, one scope projector, one layout solver, one expansion coordinator, two non-overlapping settings owners | dependency/boundary tests + inspection | NOT DONE |
| ARC-02 | AGENTS architecture gate | presentation | Widgets contain rendering/intent only; no native/Room/repository rhythm work | boundary test + import inspection | NOT DONE |
| RHY-DATA-01 | User prompt + approved correction | Kotlin classifier/index + Dart contracts | Exactly eight canonical 3-hour local-time buckets, exhaustive and non-overlapping | native/Dart parity tests, boundary tests | NOT DONE |
| RHY-DATA-02 | User prompt | native query, codec, prepared snapshot | Timestamp-faithful day-part values survive preparation; daily total equals the eight values | codec/invariant fixtures | NOT DONE |
| RHY-DATA-03 | User prompt | Kotlin/Dart codec | Versioned lockstep transport validates offsets, sort order, length, money range and payload bounds without legacy reinterpretation | codec corruption/parity tests | NOT DONE |
| RHY-DOM-01 | User prompt | `DashboardSpendingRhythmProjector` | DAY creates all eight selected-day parts including zeros | unit fixture | NOT DONE |
| RHY-DOM-02 | User prompt | projector | MONTH creates every actual selected calendar day; YEAR exactly Jan–Dec | 28/29/30/31 and 12-month tests | NOT DONE |
| RHY-DOM-03 | User prompt | projector | SUM creates the full continuous concrete-year history span with internal zero years; >31 is not truncated | historical-domain tests | NOT DONE |
| RHY-DOM-04 | User prompt | controller/projector | No clock, timer, `last N`, or rolling 7-day/6-month/5-year path remains reachable | static/source and historical-context tests | NOT DONE |
| RHY-PUB-01 | User prompt | controller/visible frame | Every accepted visible temporal or target crossing publishes prepared scope rhythm with no repository/widget scan | controller/cache/preview tests | NOT DONE |
| RHY-LAYOUT-01 | User prompt | layout token/solver | Existing `11.0` authored rhythm track is the named `maxBarWidth`; six bars never widen beyond it | source-contract/layout tests | NOT DONE |
| RHY-LAYOUT-02 | User prompt | layout solver | Named measured `minGap`, supported minimum width and mathematically derived `minBarWidth` make 31 days fit, with equal non-negative gaps | solver matrix | NOT DONE |
| RHY-LAYOUT-03 | User prompt | chart/layout | Only SUM >31 is horizontally scrollable; it uses persistent controller and fixed 31-slot pitch | widget/controller identity tests | NOT DONE |
| RHY-VIS-01 | User prompt | analysis/chart | Self-normalization, zero-inclusive mean, meaningful average reference and safe all-zero state are correct | value/paint-model tests | NOT DONE |
| RHY-VIS-02 | User prompt | axis model/chart | DAY all labels; MONTH 1/5/10/15/20/25/last; YEAR Jan–Dec; SUM concrete labels move with bars | axis tests | NOT DONE |
| CARD-01 | User prompt | Partner composition | Partner rhythm uses full usable card width and meaningful lower plot; outer height, donut and row typography remain protected | widget geometry test/screenshot | NOT DONE |
| CARD-02 | User prompt | Category composition | Category card geometry is unchanged; Partner list stays scrollable | regression widgets | NOT DONE |
| SUM-01 | User prompt | ring settings/controller | Exactly `current`, `coloredScaleWhiteArc`, `coloredScaleMovingSphere`; default current preserves existing output | settings/painter regression tests | NOT DONE |
| SUM-02 | User prompt | shared ring strategy/material | New styles use canonical clockwise shared geometry, smooth scale, white fixed .75/.90 spheres, and correct exclusive moving indicator | geometry/material/painter tests | NOT DONE |
| SUM-03 | User prompt | ring state | Visual marker clamps only paint coordinate; raw typical ratio and Budget semantics do not change | state/painter tests | NOT DONE |
| HEALTH-01 | User prompt | healthy visual resolver | `fixedGreen`/`targetAccent` controls only YEAR healthy and SUM scale healthy material; warning yellow/danger red remain hue-preserved, DAY/MONTH unchanged | resolver/regression tests | NOT DONE |
| GEST-01 | User report | gesture coordinator/card surfaces | Actual pointer drags on card/heading/donut/chart backgrounds drive the same Header expansion controller/sign mapping as Header/handler | real widget-pointer tests, both directions | NOT DONE |
| GEST-02 | User prompt | list/handoff coordinator | Partner list scrolls first and transfers residual same-pointer boundary motion without controller/position recreation | boundary-handoff identity tests | NOT DONE |
| GEST-03 | User prompt | gesture arena | Donut/row taps, avatars, PageView, Summary selectors and SUM chart horizontal scroll remain child-owned; vertical chart drag can expand Header | conflict-matrix tests | NOT DONE |
| PART-01 | User prompt | Header partition lane/settings | Default-off optional contour paints one thin white outer RRect only, tracks all heights and changes no geometry | painter/settings tests | NOT DONE |
| TEXT-01 | User prompt | Header contrast primitive/settings | None, sharp opposite shadow and true opposite outline work for black/white foreground with unchanged metrics and single semantics | layout/semantics matrix tests | NOT DONE |
| TUNER-01 | User prompt | Header visual tuner | SUM, healthy-colour, contour and contrast controls are independent and use existing tuner/persistence convention | controller/widget tests | NOT DONE |
| REG-01 | User prompt | protected dashboard | DAY pace, MONTH, YEAR cells, SUM ratio, Summary normal/mirror/reset, LogBox and expansion geometry are unchanged outside scope | protected suites | NOT DONE |
| DOC-01 | User prompt | docs | Plan/checklist records old rolling evidence, architecture, constants, ownership and physical validation truthfully | docs reread | PARTIAL |
| VER-01 | User prompt + AGENTS | test/CI | Focused/protected tests, proot analysis, diff check and prescribed GitHub Android build pass; human APK is downloaded and hashed after production push | command/build evidence | NOT DONE |
| DEL-01 | User prompt | git/remote | Focused buildable commits, final status and pushed SHA are reported without unrelated prototype modification | git diff/status/log | NOT DONE |
