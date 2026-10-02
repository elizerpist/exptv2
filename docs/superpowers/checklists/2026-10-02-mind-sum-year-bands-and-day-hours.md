# Mind SUM year-band and Day hourly-bar repair checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

## Mandatory visual and behavior sources

- User screenshots:
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261002-033616.png` (SUM-A: only two month rows are visible)
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261002-033640.png` (SUM-B: third month row is clipped)
- SUM reference inputs:
  - `/storage/emulated/0/spendee/source of truth/suma.png`
  - `/storage/emulated/0/spendee/source of truth/sumb.png`
- Day reference input:
  - `/storage/emulated/0/spendee/source of truth/napiheatmap.png`
- Day behavior source: user report for `2026-07-02`: four transactions occurring in four distinct hours must produce four distinct populated hourly bars.
- Slider behavior source: user instruction: in every Mind time view the left/right slider limits are the cheapest/most-expensive transaction in the currently filtered data, and therefore change dynamically with the active filter scope.

## Architecture card

### Scope and sources

- User requirement: all twelve months must fit inside each rendered SUM year card for both SUM-A and SUM-B; Day must preserve one populated bar per actual local hour.
- Existing implementation: `MindSumReferenceSurface`, `MindDayHourlyComparisonProjection`, `MindDayHeatmapProjection` and their existing focused tests.

### Single source and write path

- SUM geometry source: `MindSumReferenceSurface` owns only reference-renderer band geometry; no settings/state write is needed.
- Day event source: `MindYearHeatmapPreparedMembership` carries each resident `DashboardLedgerEntry.bookedLocalTimeMinutes`; `MindDayHeatmapProjection` is the pure one-owner source of Day frame events; `MindDayHourlyComparisonProjection` is its pure 24-hour display aggregation.
- Existing range preview remains the sole write/publication path through `DashboardCoreController`; this fix must add no Query, repository, or per-drag acquisition.
- Slider extent source: audit and extend the existing canonical range-binding/extent owner. The result must be derived from the already resident exact filtered membership for SUM, Year, Month and Day, not from widget-local calculations.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| SUM card height | reference surface layout | widget build | deterministic from the fixed 4×3 grid geometry |
| full-day events | Day heatmap projection | prepared-frame lifetime | copied from resident membership with actual local minute |
| selected events | same Day projection | range-preview lifetime | pure range subset of the same full event set |
| hourly bar values | hourly comparison projection | widget build | pure aggregation, never Query/repository work |
| slider limits | canonical Mind amount-range binding | active filtered temporal target | emits the cheapest and most-expensive resident transaction amounts for that target; preview only changes the selected interval |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| 4×3 SUM-grid geometry | `_SumMonthGrid` | derive both A and B band heights from its one fixed geometry contract; do not add per-style grids | RenderBox tests assert all 12 cells lie in the year-card bounds |
| local-time event mapping | `MindDayHeatmapProjection` | preserve/repair the existing prepared-membership → frame path; do not infer hours in the widget | projection test with four different minute values yields four non-zero hourly buckets |
| range interaction | `DashboardCoreController` | reuse unchanged | existing liveness test stays green |
| range extents | existing canonical Mind range-binding/extent resolver | extend one owner for every Mind temporal target | Core test proves all four views publish their own resident min/max without a new acquisition |

## Acceptance checklist

| ID | Requirement / source | Intended code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| SUMROW-01 | SUM-A user screenshot | `mind_sum_reference_surface.dart` | each year band has all 12 4×3 month cards wholly inside its band, with no card behind the slider/footer | constrained RenderBox widget test | DONE |
| SUMROW-02 | SUM-B user screenshot | `mind_sum_reference_surface.dart` | identity card, mother card and 4×3 grid are tall enough for all three month rows; third row is not clipped | constrained RenderBox widget test | DONE |
| DAYHOUR-01 | 2026-07-02 user scenario | `mind_temporal_heatmap_projection.dart` → `mind_day_hourly_comparison_projection.dart` | four resident transactions in four different local hours create four different non-zero full-hour cells | pure projection RED/GREEN test | DONE |
| DAYHOUR-02 | Day renderer | `mind_day_all_vs_slider_heatmap_card.dart` | all four resulting populated bars are separately rendered; selected/full containment remains correct | focused widget test | DONE |
| SLIDERSCOPE-01 | user slider instruction | canonical Mind range-binding/controller owner | SUM, Year, Month and Day use the minimum and maximum exact transaction amount of their currently filtered resident membership as slider limits | Core/domain RED/GREEN test | DONE |
| SLIDERSCOPE-02 | user slider instruction | same owner + existing range footer consumers | changing time scope/filter replaces the limits immediately; range preview alters only the selected interval and starts no Query/repository/index work | mounted Core liveness/regression test | DONE |
| SAFE-01 | existing app architecture | focused Mind surfaces/projections | no new Query/repository/index work or slider state owner; existing preview/liveness behavior remains | focused Core + source inspection | DONE |
| VIS-01 | screenshot sources | final installed app | inspect final screenshot against the two SUM sources and user Day scenario | physical screenshot **PENDING — USER ONLY** | NOT DONE |
| REL-01 | delivery | branch/build | one app commit, online Human APK from the exact SHA, then factual docs commit | CI/release evidence | DONE |

## Delivery evidence

- Application commit: `e2bbfe74cd16ca066f97672cf32d884a5e6533bc`
- Push branch: `feature/balance-wave-defaults`
- Exact GitHub Actions run: `36962812694` — `test-flutter`, `test-core`, and
  `build-human-diagnostic-apk` succeeded for that application SHA.
- Human APK:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_e2bbfe7.apk`
- SHA-256:
  `d53a972ac12be0d9a1e8e6b4e419074cfd699227a5eed962de2a8bc1c6f5fedd`
- `VIS-01` intentionally remains `NOT DONE`: it requires the final, installed
  APK's physical screenshot comparison against the supplied references.
