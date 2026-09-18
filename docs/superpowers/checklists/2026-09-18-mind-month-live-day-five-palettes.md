# Mind Month live publication, Day activity, and five palettes — acceptance checklist

**Status vocabulary:** `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`. `DONE` requires
the named focused evidence; compilation alone is insufficient. This checklist
is the functional build gate for the user-approved DayScope design recorded in
journal commits `63368c5` and `894159f`.

**Sources:** user specification §§1–21; [engineering journal](../../FLUVI_ENGINEERING_JOURNAL.md);
application source `33facc5f`; matching SCIP tooling `0f81d535`;
`MILESTONE_COMMITS.md`. Drive revisions 5/51 are historical only and do not
prove the current Month lag.

## Architecture and scope authority

| ID | Source | Owner / area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | §§8,12,14 | `DashboardCoreController` temporal coordinator | Month, Year and Day accepted targets use one Core semantic publication transaction; no duplicate score/body authority | mounted Core contract | NOT DONE |
| ARC-02 | §§8,12 | existing `TimePlane.month` + `DayScope` | Day is a retained Month child; no `TimePlane.day`, navigation, Query or focus owner is added | host/domain test + diff | NOT DONE |
| ARC-03 | §§8,12,14 | `MindBehavioralScoreProjection` / `mindBehavioralScore` | Day reuses canonical daily point and the existing Header colour/text/chart consumers; no hourly score owner | parity/header test + source review | NOT DONE |
| ARC-04 | §§8,12,14 | prepared Mind contribution transport | local time minutes are carried once at the prepared boundary and used by one bounded Day projection | domain test + dependency review | NOT DONE |
| ARC-05 | §§11,15 | palette settings/resolver | five product choices and ten-stop tile/legend mapping remain one presentation-only resolver | resolver/tuner/frame-identity tests | NOT DONE |
| ARC-06 | §§11,15 | boundary suite | no Time/Avatar/Query/LogBox/Room/Kotlin/Budget/amount-snap ownership drift | boundary script + diff | NOT DONE |

## Month accepted-target liveness

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MON-LIVE-01 | MONTH-LIVE-01 | Core + Month frame + Header | accepted Month candidate publishes body, score, chart endpoint and colour in one/next frame before settle | mounted actual-paint RED→GREEN | NOT DONE |
| MON-LIVE-02 | MONTH-LIVE-02 | Core temporal candidate | Month-active parent-Year candidate has the same atomicity and no old-Year Month body | mounted production parent | NOT DONE |
| MON-LIVE-03 | MONTH-LIVE-03/06 | prepared membership / Month projection | exact Month admission narrows before Month filtering; no unrelated-year traversal, repository/index/Query/scene acquisition | work-counter test | NOT DONE |
| MON-LIVE-04 | MONTH-LIVE-04/05 | latest-wins publication | eight rapid Month/Year candidates converge without stale body/Header flash or settle correction | mounted paint/provenance test | NOT DONE |
| MON-LIVE-05 | MONTH-LIVE-07 | Year fast path | existing renderer-admitted Year remains the positive control | existing/new Year contract | NOT DONE |

## Day prepared data and semantics

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DAY-DATA-01 | DAY-DATA-01 | immutable Day projection | exactly 24 local-hour buckets; 0/59→00, 60→01, 1439→23; same-hour sums | pure projection RED→GREEN | NOT DONE |
| DAY-DATA-02 | DAY-DATA-02 | Day projection | only selected DayScope contributes; adjacent days do not leak | pure projection test | NOT DONE |
| DAY-DATA-03 | DAY-DATA-03 | range preview | range updates totals/count with ≤24 bucket visits and zero source rows/repository/index work | counter/range test | NOT DONE |
| DAY-DATA-04 | DAY-DATA-04 | Core prepared membership | direction/category/partner/search/focus membership is inherited from the admitted Core selection, never recreated in widgets | Core fixture test | NOT DONE |
| DAY-DATA-05 | §§12,14 | Day frame | active-hour count and header/footer day total are frame fields; empty Day is 24 neutral cells and zero total | unit test | NOT DONE |

## Day presentation and Header

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DAY-UI-01 | DAY-UI-01/03 | Day viewport | one bounded 4×6 grid, 24 positive square cells in chronological `00`…`23` order; no nested scroll/dayparts | constrained widget/bounds test | NOT DONE |
| DAY-UI-02 | DAY-UI-02 | Day viewport | left/right activity and summary rows plus matching `Összesen` footer have actual aligned bounds | widget geometry test | NOT DONE |
| DAY-UI-03 | DAY-UI-04/05 | Day viewport/resolver | active resolver paints Day tiles, empty stays neutral, palette does not replace frame, and hour cells own no tap/morph/route | widget/identity test | NOT DONE |
| DAY-HOST-01 | DAY-HOST-01 | Core dashboard / Mind surface | rail-closed Month renders only Month; rail-open DayScope renders only Day | production host test | NOT DONE |
| DAY-LIVE-01 | DAY-LIVE-01/05/06 | Core / score live projection | accepted Day targets are atomic/latest-wins and empty Days are valid | mounted Core test | NOT DONE |
| DAY-LIVE-02 | DAY-LIVE-02/04 | score projection | Day Header point equals canonical daily point despite hourly distribution | score parity test | NOT DONE |
| DAY-LIVE-03 | DAY-LIVE-03 | score series request | Day chart semantic domain is D−30…D and its endpoint is the current point | domain/Header chart test | NOT DONE |

## Palette reduction and preserved presentation

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PAL-01 | PAL-REDUCE-01/02 | settings/tuner | exactly Fluvi, B3M-MY3, Meadow Green, Fluvi stretched, B3M-MY3 stretched; removed labels/cases cannot render | enum/tuner RED→GREEN | NOT DONE |
| PAL-02 | PAL-REDUCE-03 | resolver/legend | every retained palette has ten exact authored anchors and ten resolver swatches; no five-step quantization | resolver/widget test | NOT DONE |
| PAL-03 | OLD-PRESENTATION | existing Mind surfaces | Month B3M-MYM real 5/6 rows, Sum cells, legend toggle, legend-free 4×3, Year inspection and compact-caption removal stay green | regression suite | NOT DONE |

## Performance, validation, and delivery

| ID | Source | Evidence | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PERF-01 | §§10,15 | Month target | record before/after prepared contribution touches and zero repository/index/Query/scene work | mounted counter test | NOT DONE |
| PERF-02 | §§12,15 | Day target/preview | target uses resident data; preview visits ≤24 buckets, source rows/repository/index = 0 | projection/Core counter tests | NOT DONE |
| PERF-03 | §15 | protected interaction | no controller/position/physics recreation or new ticker; Year positive control survives | topology/source review | NOT DONE |
| VAL-01 | §§10,13,17 | TDD | each production feature/fix has current-source RED observed before GREEN | command log | NOT DONE |
| VAL-02 | §17 | focused suites | temporal, score, Year, presentation, host, tuner and direct Core tests pass | Ubuntu/proot commands | NOT DONE |
| VAL-03 | §17 | structural suite | formatter, analyzer, fast suite, boundary script and diff check pass | exact command results | NOT DONE |
| VAL-04 | §§5,6 | evidence audit | Drive/current source/SCIP/CI evidence is classified proven/unproven/missing honestly | report/journal | NOT DONE |
| DEL-01 | §18 | commits/journal | every substantive application commit has a separate one-file `[skip ci]` journal commit | `git show --name-only` | NOT DONE |
| DEL-02 | §19 | CI/APK | final app SHA is pushed as build-triggering tip; tests/core/human artifact individually audited; profile reported honestly | workflow/release audit | NOT DONE |
| DEL-03 | §19 | SCIP | exact final application SHA is indexed and tooling tests pass | manifest/tooling suite | NOT DONE |

## Build gate

**FUNCTIONAL BUILD GATE = CLOSED.** It opens only after every ARC/MON/DAY/PAL/PERF/VAL functional row is `DONE` with its focused evidence green. No APK, build-triggering push or SCIP finalization occurs before then.
