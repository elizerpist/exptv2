# Mind entry, Day timeline, and Balance carousel acceptance checklist

## Architecture card

### Scope and sources

- User requirement: the 2026-09-21 Phase A + Phase B Fluvi instruction, with
  one final APK build after the inline work.
- Evidence: frozen `Fluvi mind heatmap` export, document
  `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, 410 bytes, SHA-256
  `f2a8e253293807c212c2ccf1167179afb30c8d1a73087e7dcca4253723ac9c69`.
- Existing implementation: `DashboardCoreController` owns Mind lifecycle and
  immutable prepared projections; the Mind surface supplies rendering-only
  acknowledgements; `MindYearHeatmapPresentationSettings` is the single Mind
  presentation authority; `CenteredCarousel`/`CenteredCarouselController`
  own drag, ballistic, snap, and pointer interruption.

### Single source and write path

| State | Owner | Write path | UI role |
| --- | --- | --- | --- |
| Mind entry flow correlation | `DashboardCoreController` | committed mode entry and Core admissions | reports immutable frame acknowledgements only |
| Mind Header/body frame | existing Core notifiers | existing prepared projection publication | renders current identity only |
| Day layout choice | `MindYearHeatmapPresentationSettingsController` | presentation setter | selects layout only |
| Balance aggregate/latest item | existing prepared Core presentation authority | existing Core publication only | no repository or ledger access |
| Balance carousel motion | shared centered-carousel engine | stable feature controller | renders typed Balance cards |

### Reuse and boundary decisions

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| Cold-entry correlation | `DashboardCoreController` | extend the bounded Core trace; do not add a widget trace owner |
| Header/body acknowledgement | Mind header/body render seams | add correlated acknowledgement inputs only |
| Day visual alternative | `MindYearHeatmapPresentationSettings` | extend its enum/controller; do not create a Day store |
| Amount and financial totals | prepared/current-scope Core projection | consume only; no renderer data query |
| Drag, fling, snap, interruption | `CenteredCarousel` | reuse unchanged; Balance supplies geometry/content adapter only |
| Carousel motion profile | `CenteredCarouselMotionProfiles.timeRefinementRail` | exact shared object identity; no copied constants |

### Layer flow

`Balance/Mind UI → existing dashboard presentation contracts → DashboardCoreController → existing prepared projections → repositories/adapters`.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| A1-TRACE | §10/14 cold-entry contract | Core trace + Mind header/body seams + diagnostics filter | One bounded flow has session/build/flow/mode/revision/scope/query/frame/cold-warm fields and all request-to-both-paint stages plus one summary. | MIND-COLD-01/02 and console filter tests | DONE |
| A2-RED | §10/13 cold reproducer | dashboard Core production-parent tests | A real cold Balance→Mind switch uses no post-switch manual `primeMindAmountPreviewDomain`; stale identity is rejected; a warm repeat is distinguished. | MIND-COLD-02 observed RED (`REQUEST_ACCEPTED` only) then GREEN; MIND-COLD-01 uses production route | DONE |
| A3-CAUSE | 2026-09-21 frozen physical cold trace | Core semantic admission versus live LogBox resource lane | Semantic Header/body publication is independent of broad row/TextPainter readiness; no timer, eager repository work, or cache-size workaround. | Cold `mind-entry:1` had 939,833 µs to `PREPARED_BASE_READY` with zero repository/index work; MIND-COLD-03 held-resource RED→GREEN | DONE |
| A4-HEADER | §10/14 | dynamic Mind Header seam | Header current-frame publication, first layout, and first paint correlate to the same entry and frame identity. | MIND-COLD trace stages | DONE |
| A5-BODY | §10/14 | Mind body surface seam | Body current frame, first layout, and first paint correlate; terminal only follows both correct paints. | MIND-COLD trace stages | DONE |
| A6-DIAG | §10 on-screen retention | diagnostic route/filter/export | `MIND_ENTRY` is retained by the Mind heatmap copy/export flow without unbounded frame spam. | debug console Mind Heatmap filter test | DONE |
| A7-LIVE-SPLIT | 2026-09-21 repair contract | `DashboardCoreController` | Immutable-base source/installation and structural-domain publication are separately correlated from `mind-live-root` request/join/reuse/ready; only Core starts either lane. | MIND-COLD-03 plus Core/read-path source test | DONE |
| A8-READABLE-FAIL-CLOSED | 2026-09-21 repair contract | existing Mind range/LogBox resource bind | A drag before live resource readiness cannot stage the readable live LogBox bank; once ready the existing exact Phase-A path is used. | held-resource MIND-COLD-03 and warm LogBox preview regressions | DONE |
| D1-LABEL | §12/13 Day label | Day timeline painter/layout helper | A wrapped label has explicit paint bounds inside plot and `bottom < markerTip - positiveGap` at left/centre/right. | DAY-TIMELINE-LABEL geometry test | DONE |
| D2-TOPOLOGY | §12/13 Day topology | Day viewport | No Day PageView/controller, hourly grid, cells, dots, or pager gesture owner remains; timeline mounts directly. | DAY-TOPOLOGY widget test and source search | DONE |
| D3-SETTINGS | §8/13/14 Day layouts | existing Mind presentation settings/controller/tuner | One canonical enum defaults to combined and supports copy/equality/hash/setter/UI controls. | settings/controller and tuner tests | DONE |
| D4-COMBINED | §13/14 | Day timeline viewport | Default combined mode preserves current info/stat cards and timeline. | DAY-LAYOUT widget test | DONE |
| D5-ONLY | §12/13/14 | Day timeline viewport | Timeline-only hides stats, shows current Day total top-right from current frame, and materially enlarges chart without query/frame mutation. | DAY-LAYOUT widget bounds and same-frame test | DONE |
| B1-OWNER | §14 Balance Header | existing prepared Core presentation owner | Current-scope income and expense are independently prepared from the same structural time scope; net is `income - expense`; renderer has no repository/ledger access. | `BALANCE-HEADER RED` Core fixture + controller source inspection | DONE |
| B2-HEADER | 2026-09-21 physical Balance feedback | Header detail seam and semantic colour tokens | Existing Header material remains owner; positive/negative net uses the canonical on-action foreground rather than the identical Balance background token. | `BALANCE-HEADER-VISIBILITY` RED→GREEN widget test | DONE |
| B3-LATEST | §14 Balance latest card | prepared/current-scope Core presentation owner | One stale-safe latest-transaction item is prepared upstream from bounded prepared LogBox preview; Balance surface does not query. | `BALANCE-HEADER RED` + Balance surface widget test | DONE |
| B4-CAROUSEL | §12/13/14 Balance carousel | Balance surface adapter + shared centered carousel | Exactly five cyclic items, latest initially centred, four empty prototypes, and exactly three visible slots. | Balance widget/controller test | DONE |
| B5-MOTION | §8/13/14 shared motion | Balance adapter | One stable controller/ScrollPosition and exact `timeRefinementRail` identity; ballistic fling and new-pointer interruption work. | Balance widget test + shared controller/identity/widget tests | DONE |
| B6-BOUNDS | 2026-09-21 physical Balance feedback | Balance geometry/renderer | Selected centre is authored at the full `subheaderOne` structural height (scale 1); neighbours are shorter through existing scale, with real unclipped layout/hit/semantic bounds and one selected semantic item. The upper cascade intentionally has no placeholder surface; the lower `zone2` placeholder remains. | `BALANCE-UPPER-VISUALS` RED→GREEN geometry/widget test and collapsed CoreDashboard regression | DONE |
| NR1-PHYSICS | §8/11/15 protected milestone | shared/Budget source | Budget/Time/Avatar physics constants and owners remain unchanged from `6e962187`. | Shared/Budget regression run and source diff | DONE |
| V1-DELIVERY | current repair delivery | commits/CI/APK/SCIP | Atomic application + journal commits, one final exact-SHA normal APK, and exact-source SCIP manifest are available. | New source requires a new Actions run, APK and final graph. | PARTIAL |
| V2-PHYSICAL | §4/20 | Android device | User alone validates final physical behavior. | User report | PENDING — USER ONLY |
