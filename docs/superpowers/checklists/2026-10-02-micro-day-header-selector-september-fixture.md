# Mind micro-day ribbon, Header selector and September fixture checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

## Preflight

- Branch: `feature/balance-wave-defaults`
- Starting remote/head: `3455b5fe21d78fb1d222f647b424d5a5926c5a3a`
- Underlying latest application source: `98c0200d904151e48380233232957ac1641c60be`
- Retained unrelated worktree material: `test/features/dashboard/presentation/failures/`
  is untracked and excluded from this work.
- Required evidence reviewed: `docs/FLUVI_ENGINEERING_JOURNAL.md` (including
  the final Header-selector entry), `MILESTONE_COMMITS.md`, current source
  owners and their focused tests listed below.

## Architecture card

| Concern | Existing owner | Decision |
| --- | --- | --- |
| Mind SUM visual choice | `MindYearHeatmapPresentationController` | Add exactly one presentation-only `microDayRibbon` enum value and reuse its revisioned setter. |
| SUM daily data/range preview | `MindSumHeatmapProjection` → `MindSumHeatmapFrame` | Render `dailyPointsForYear` from the existing resident filtered frame; no repository, Query or second slider. |
| Daily palette | `MindYearHeatmapPaletteResolver` + `MindHeatmapPaletteScope` | Resolve a once-per-frame daily min/max support model; retain the existing palette, resolution and dynamic-scale path. |
| Header motion | `CenteredCarouselController` / `CenteredCarousel` | Add a bounded Header adapter using the unchanged `timeRefinementRail` profile and a persistent controller. |
| Core-mode semantic write | `DashboardCoreModeController` | Keep it canonical; add at most an atomic exact-target method used by both ring navigation and crossing callbacks. |
| Demo data | `DemoDatasetGenerator` | Append deterministic September 2026 expense drafts after the existing fixture ordinals; preserve every existing generated draft byte-for-byte. |

## Acceptance checklist

| ID | Requirement/source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MDR-01 | Prompt 1 settings | Mind presentation settings + tuner | `Mikronapok` is the fourth existing SUM setting, revisioned through the one controller. | settings/tuner widget tests | DONE |
| MDR-02 | Prompt 1 routing | SUM viewport + dedicated surface | Only the new setting mounts a dedicated micro-day ribbon; Current/SUM-A/SUM-B retain their current surfaces. | routing widget test | DONE |
| MDR-03 | Prompt 1 geometry | micro-day support model/surface | A 365/366-day real-calendar year packs chronologically into five rows, twelve contiguous month groups, no fake days or dedicated inter-month gap. | pure geometry + leap/widget tests | DONE |
| MDR-04 | Prompt 1 live data | micro-day support model/surface | Year total and daily palette cells use the same slider-filtered resident SUM frame; day normalization is daily, not monthly. | preview/range regression + source-boundary inspection | DONE |
| MDR-05 | Prompt 1 visual/accessibility | micro-day surface | Compact header, Hungarian month labels, grouped semantics, no in-body `3×4`/`4×3`/`2×6` controls and no nested vertical scroll. | widget/semantics/layout tests | PARTIAL — automated widget/semantics coverage is green; fresh installed-device/raster review remains VIS-01. |
| HMS-01 | Prompt 2 interaction | Header mode selector | Tap is inert; bounded vertical up/down drag/fling cycles the canonical three modes with directional physical icon motion. | mounted Header RED→GREEN tests | DONE |
| HMS-02 | Prompt 2 publication | Header adapter + mode controller | `onSelectedChanged` crossing synchronously changes mode epoch, Header binding and committed content before settlement. | production-parent crossing test | DONE |
| HMS-03 | Prompt 2 ownership | Header adapter + shared carousel | One persistent carousel controller/ScrollPosition/physics; interruption is latest-wins; Header expansion and tap-wave remain isolated. | identity/interruption/isolation tests | DONE |
| HMS-04 | Prompt 2 hot path | existing Core test harness | Rapid crossings add no repository/Room/index/Query/SVG/TextPainter work and preserve Dashboard/Query/LogBox owners. | production-parent counters + fast suite | DONE |
| SEP-01 | Prompt 3 fixture | `DemoDatasetGenerator` | Append only expense entries for every 2026-09 day; existing drafts and schema stay unchanged. | deterministic generator test | DONE |
| SEP-02 | Prompt 3 hourly shape | `DemoDatasetGenerator` | Each day has 8–14 active hours with 2–5 varied transactions/hour, frequent consecutive runs and wide/tight amount clusters. | data-quality contract test | DONE |
| SEP-03 | Prompt 3 integrity | generator/version tests | All existing expense categories/valid partners recur, IDs are unique, all new dates are September and all new directions are expense. | deterministic generator test | DONE |
| ARC-01 | architecture gate | changed source | No duplicate mode state, physics, slider, query, repository or data schema path. | focused boundary/source inspection | DONE |
| REL-01 | user delivery instruction | branch/release | The implementation commit and its necessary profile-interaction test follow-up are pushed; the exact final `766710ea` normal Human APK is built, downloaded to `/storage/emulated/0/Download/fluvi`, and hashed. | CI + local SHA-256 | DONE |
| GRAPH-01 | Prompt 2 | SCIP tooling | Exact final `766710ea` application SHA is indexed and the manifest/hash/tool test are recorded. | tooling output | DONE |
| VIS-01 | Prompt 1/2 | installed app | Supplied micro-day concept is visually checked on the delivered APK; Header physical acceptance remains user-only. | fresh device evidence | PARTIAL — APK is delivered; user device inspection/physical acceptance is still required. |

## Ordered inline implementation

1. Write and run failing Mind micro-day, Header-selector and September-fixture
   tests against this baseline.
2. Implement the smallest owner-preserving Mind and Header adapters plus the
   additive deterministic fixture.
3. Run focused green tests, source/boundary checks, the Flutter fast suite and
   native generator tests; inspect the full diff against this list.
4. Commit the combined application change once, push once, regenerate exact
   source SCIP, run the one normal CI/Human APK delivery loop, then add only
   factual journal evidence in a separate `[skip ci]` commit.
