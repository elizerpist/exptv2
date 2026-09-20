# Summary liveness, Sum density and Year profitability acceptance checklist

## Architecture card

### Scope and sources

- User requirements: 2026-09-20 exact `cd1368dd` Summary freeze / Sum
  pan-detail / 1-or-2 Sum density prompt, plus the 3-column Year
  profitability-month-card request.
- Frozen evidence: the three document identities and SHA-256 values recorded
  in the 2026-09-20 engineering-journal entries; `cd1368dd` is the exact
  physical build via `USER_MARK`.
- Existing owners: `CenteredCarouselController` for carousel motion,
  `MindYearHeatmapPresentationController` for Mind presentation settings,
  `MindYearHeatmapMonthlyAggregates.netForMonth` for existing monthly closing
  balance semantics, and the existing palette resolver for day-cell colors.

### Single source and write path

- Summary motion state: `CenteredCarouselController`; production repair is
  prohibited until a production-parent RED test proves the first orphan-Hold
  liveness boundary.
- Sum density / profitability preferences: immutable
  `MindYearHeatmapPresentationSettings`, written only by its existing
  presentation controller. They never write Query, frame, range, or finance
  state.
- Profitability classification: `MindYearHeatmapMonthlyAggregates.netForMonth`
  only. The tint is a MonthCard background paint input, not a new aggregate.

### State ownership

| State | Owner | Lifetime | Rule |
| --- | --- | --- | --- |
| Carousel command/liveness | `CenteredCarouselController` | controller | stale commands may never settle newer semantics |
| Sum visible-band preference | presentation controller | screen presentation | revision-only publication; no Query mutation |
| Year profitability enabled/opacity | presentation controller | screen presentation | affects only 3×4 MonthCard background |
| Financial net | immutable Year frame monthly aggregates | admitted frame | no presentation calculation authority |

### Reuse / centralization

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| Carousel Hold lifecycle | `CenteredCarouselController` | extend only if RED reproduces the physical failure |
| Sum band geometry | current line layout + bar hard-coded height | extract one pure geometry resolver used by both chart renderers |
| Mind presentation setting | settings/controller | extend; do not create another owner |
| Month financial result | monthly aggregates | consume `netForMonth`; do not recalculate |
| Heatmap colors | palette resolver | unchanged; tint must not feed its inputs |

### Verification

- Production-parent Summary persistent-Hold RED/GREEN plus Time/Avatar shared
  carousel regressions.
- Sparse-2027 source/LOD diagnostics and fixed-span overlap/edge tests before
  any Sum crop implementation.
- Domain setting tests, mounted detailed/bar geometry tests, 3×4 tint widget
  tests, 4×3 isolation test, analyzer, fast/boundary suites, CI/APK/SCIP.

## Requirements

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUMM-01 | exact physical Summary log | centered carousel / Summary host | production-parent test reproduces the accepted-pointer + persistent-Hold liveness boundary before shared production mutation | RED test | NOT DONE |
| SUMM-02 | Summary repair contract | centered carousel | completed orphan Hold cannot strand selector; active pointer/ballistic/stale controls remain correct | GREEN shared + Summary tests | NOT DONE |
| SUM-FORENSICS-01 | paired 2027 screenshots/log | detailed Sum chart | bounded per-band counts/digests/edge-neighbour diagnostics reach existing Mind debug filter | mounted diagnostics test | NOT DONE |
| SUM-FORENSICS-02 | pan-detail contract | LOD/chart | sparse fixture distinguishes legitimate calendar sparsity from origin-dependent source/LOD loss | fixed-span overlap and edge-continuity RED/GREEN | NOT DONE |
| SUM-DENSITY-01 | 1/2 request | Mind presentation settings/controller/tuner | default is two; single settings choice writes presentation revision only | domain/tuner tests | NOT DONE |
| SUM-DENSITY-02 | density geometry contract | shared Sum presentation geometry | one resolver drives detailed and overlay bands; 1 fits one full band, 2 fits two incl. X axis, overflow scrolls | mounted renderer tests | NOT DONE |
| SUM-DENSITY-03 | scope lock | Sum heatmap | density has no heatmap, Query, frame or financial semantic effect | heatmap/frame identity regression | NOT DONE |
| YEAR-PROFIT-01 | profitability request | Year 3×4 MonthCard | every 3-column month remains rounded MonthCard; 4×3 remains unchanged | mounted layout/isolation test | NOT DONE |
| YEAR-PROFIT-02 | profitability request | existing monthly aggregates + Year renderer | positive net green, negative net red, zero neutral; no second calculation | model/widget fixture test | NOT DONE |
| YEAR-PROFIT-03 | settings request | settings/controller/tuner | enabled/disabled and opacity slider update only MonthCard tint live | settings and mounted slider tests | NOT DONE |
| YEAR-PROFIT-04 | scope lock | palette/day painter/Year 4×3 | tint never changes cell/text/border/shadow/icon opacity or financial values; 4×3 unchanged | color/semantics + 4×3 regression | NOT DONE |
| ARC-01 | structuring-apps / milestone | all changed paths | one owner/write path; no Query/repository/Room/gesture duplication | source audit + boundary suite | NOT DONE |
| DELIV-01 | user workflow | branch/build/graph | each app commit has journal child; final exact source has CI/APK/SCIP | GitHub + artifact/graph audit | NOT DONE |
| PHYS-01 | user workflow | Android | exact resulting APK is physically checked by user | user only | BLOCKED |
