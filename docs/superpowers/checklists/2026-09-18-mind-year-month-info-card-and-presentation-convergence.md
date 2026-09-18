# Mind Year MonthCard information and presentation convergence — acceptance checklist

**Status vocabulary:** `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`. A row becomes
`DONE` only after the named evidence is green. This checklist is the delivery
gate for the user request recorded in journal commit `ae7809c6`.

**Approved references:** user specification §§1–21; `origin/spendeetest:balance_latest_layout.html`,
`createMindMonthlyActivityPrototypeScreen`; current application source
`43b5fc1090cfd35562df84d8d65838a297c0b689`. The HTML is layout authority
only; its data fixture never enters Fluvi financial data.

## Architecture and data authority

| ID | Source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-INFO-01 | §§8.1,12.1 | `MindYearHeatmapViewport` | one viewport-local inspected `(year, month)` write path; never twelve card states or persistence | mounted state lifecycle tests | DONE |
| ARC-INFO-02 | §§8.2–8.6,14.A | `MindYearHeatmapFrame` / Core projection publication | full monthly bank remains full-ledger; separate immutable scoped twelve-month read model is published before a tap | projection/Core regression test | DONE |
| ARC-INFO-03 | §§8.4,12.7 | `DashboardQueryFacetChips` precedence + `CategoryVisualResolver` | scope labels and colours reuse the canonical focus/facet authority, without a second palette/map | focus/facet render tests | DONE |
| ARC-INFO-04 | §§11,15 | Core plus Year presentation | inspection tap performs no repository read, index build, Query apply, Time commit or LogBox scene work | production-parent counters | DONE |
| ARC-PRES-01 | §§8.11–8.12,14.F | presentation settings + palette resolver | exactly seven palette choices, each exactly ten authored stops; Year/Month/Sum/legend share one resolver | pure resolver + tuner/all-plane identity tests | DONE |
| ARC-PRES-02 | §§8.9,14.I | `MindMonthHeatmapViewport` | standalone Month derives actual five/six calendar rows from calendar geometry; no fake row | constrained widget tests | DONE |
| ARC-PRES-03 | §§8.13,14.H | Year four-column fit | 4×3 solves actual temporal constraints and legend visibility, without stale fixed height policy | constrained bounds/scroll test | DONE |
| ARC-PRES-04 | §§8.10,14.J | `_CompactMindAmountRangeSurface` | compact caption only changes presentation; range semantics and standard control remain owned where they are | range-control test | DONE |
| ARC-NRG-01 | §§11,15 | boundary test suite | no Time/Avatar/Query/LogBox/Room/Kotlin/Budget/score/amount snapping ownership drift | `verify-fluvi-boundaries` + scoped diff | DONE |

## Year MonthCard inspection

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| INFO-01 | §12.2, YEAR-INFO-01 | Year viewport/card | every real month is semantic tappable; a clean tap opens local inspection and does not enter Month plane | mounted production-parent test | DONE |
| INFO-02 | §12.2, YEAR-INFO-04 | Year viewport/card | second tap closes; A→B returns A and opens only B | interaction test | DONE |
| INFO-03 | §12.4, YEAR-INFO-03 | Year layout | inspected outer slot rect and annual scroll extent remain unchanged in 3×4 and 4×3 | Rect/scroll-extent test | DONE |
| INFO-04 | §12.5, YEAR-INFO-02 | Year viewport | heatmap→info transition has a measurable intermediate state, settles without ticker leak, and has one card-local/viewport-local animation owner | intermediate-frame test | DONE |
| INFO-05 | §12.6 | Month card semantics | endpoint exposes one selected semantic node with full financial text; no duplicate card/heatmap hit target | semantics/bounds test | DONE |
| INFO-06 | §12.3, YEAR-INFO-01 | Year viewport | tap leaves navigation, Summary selector, current Query and LogBox temporal identities unchanged | production parent assertions | DONE |
| INFO-07 | §14.E, YEAR-INFO-13 | selection lifecycle | selection survives same-year direction/palette/legend/surface/range/focus changes; invalidates before a different-year frame can paint | identity/stale test | DONE |
| INFO-08 | YEAR-INFO-14 | Year scroll/handoff | vertical child scrolling never opens a card; a clean tap still works and existing boundary handoff is unchanged | drag/tap mounted test | DONE |
| INFO-09 | YEAR-INFO-15–17 | both annual surfaces/layouts | card and direct surface styles plus 2×6/3×4/4×3 have in-bounds positive info paint at 360/390/412/430 | geometry/bounds tests | DONE |

## Financial information and active scope

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FIN-01 | §§8.2–8.3,14.B | full monthly aggregate bank | `Hó végi maradék = net`, `Összbevétel`, `Összkiadás` use current approved aggregate authority | exact fixture test | DONE |
| FIN-02 | §§8.2–8.3, YEAR-INFO-06 | Year presentation/Core | all three base values remain identical after Income ↔ Expense on the same inspected month | production-parent direction test | DONE |
| FIN-03 | §§8.5–8.6,14.A | scoped aggregate read model | category/partner/search effective membership yields a distinct bounded 12-month amount, pre-amount-range | Core/domain test | DONE |
| FIN-04 | §§12.7,14.C, YEAR-INFO-07 | card scope section | one visible category uses canonical label/tint and exact month amount; base bank remains unfiltered | mounted card test | DONE |
| FIN-05 | §§12.7,14.C, YEAR-INFO-08 | card scope section | one partner uses `categoryColorId`, exact partner month amount; base bank remains unfiltered | mounted card test | DONE |
| FIN-06 | §§12.8,14.C, YEAR-INFO-09–10 | card scope section | category+partner represents actual intersection and mirrors ephemeral-over-applied facet precedence | Core + semantics test | DONE |
| FIN-07 | YEAR-INFO-11–12 | scope presentation | search/range alone never invent a coloured facet row; slider does not recalculate the scope read model | production-parent counters test | DONE |

## Presentation corrections

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PAL-01 | §14.F, PALETTE-01 | settings | enum/tuner contains only Fluvi, B3M-MY3, Meadow Green, Soft Rainbow, Peachy Delight, Fluvi stretched, B3M-MY3 stretched | enum/tuner test | DONE |
| PAL-02 | §14.F, PALETTE-02 | resolver | every approved list has ten exact reachable endpoint/anchor colours with adjacent interpolation and neutral empty state | resolver tests | DONE |
| PAL-03 | §14.G, PALETTE-03–04 | legend/body | legend ON is one bounded ten-swatch row from active resolver; OFF has zero lane; palette changes retain financial-frame identity | widget/identity tests | DONE |
| LAY-01 | §14.H, YEAR-4X3-LEGEND-OFF-01 | four-column fit/surface | 4×3 has no scroll and recomputes from real viewport when legend is OFF; actual width/height limiter is asserted and no dead lane remains | constrained Rect test | DONE |
| MONTH-01 | §§8.9,14.I, MONTH-B3M-REAL-ROW-01 | Month viewport | July 2026 takes five real rows, a six-row month takes six; square 7-column grid is centered at `min(available,282)` | geometry test | DONE |
| MONTH-02 | §14.I, MONTH-B3M-HEAD-02 | Month viewport | title/day-count and month/active-day are two left/right header rows; grid uses 4px gaps, 3px inset, 6px radius, top-left 7px/900 label | production composition bounds/style test | DONE |
| RANGE-01 | §14.J, COMPACT-RANGE-01 | compact range surface | compact Mind footer removes only standalone `Összeg`; Min./Max./slider bounds stay, standard Query heading stays | widget test | DONE |

## Validation and delivery

| ID | Source | Evidence | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VAL-01 | §§13,17 | TDD | every changed feature begins with a current-source RED and is observed GREEN | exact focused command logs | DONE |
| VAL-02 | §17 | focused suites | domain, palette, temporal viewport, Year viewport, mode host, facet chips, focus seed/core and range tests pass | Ubuntu/proot commands | DONE |
| VAL-03 | §17 | structural suite | `flutter analyze --no-pub`, `test-fluvi-fast.sh`, `verify-fluvi-boundaries.sh`, `git diff --check` have factual results | exact command logs | DONE |
| VAL-04 | §§15,17 | performance | inspected-card actions report source rows/repository/index/Query/Time counts; no new animation/controller multiplication | counter/topology tests + source review | DONE |
| DEL-01 | §§18–19 | commits/journal | every substantive application commit has a non-duplicate journal-only `[skip ci]` commit changing only the journal | `git show --name-only` | NOT DONE |
| DEL-02 | §19 | CI/human APK | final application commit is first build-triggering tip; online app checks and exact normal APK marker/hash are recorded; inherited profile result is factual | workflow/artifact audit | NOT DONE |
| DEL-03 | §19 | SCIP | regenerated tooling manifest has `source_head == final application SHA` and tooling tests run | manifest + tooling test | NOT DONE |

## Build gate

| Group | Status |
| --- | --- |
| Year inspection and immutable scoped data | DONE |
| Seven ten-stop palettes and legend | DONE |
| Four-column / Month / compact footer corrections | DONE |
| Focused, structural and performance verification | DONE |
| Build/CI/APK/final SCIP | NOT DONE |

**FUNCTIONAL BUILD GATE = OPEN.** Every functional row is `DONE` with focused
evidence green. Delivery rows remain pending and must be completed in the
prescribed application-push, CI/APK and final-SCIP order.
