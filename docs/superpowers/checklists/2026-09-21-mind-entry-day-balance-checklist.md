# Mind entry, Day timeline, and Balance acceptance checklist

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
| Balance aggregate/latest/history | `DashboardCoreController` immutable all-time presentation | canonical query/revision/prepared-index lifecycle only | renders prepared values; no repository or ledger access |
| Balance carousel motion | shared centered-carousel engine | stable feature controller | renders typed Balance cards |

### Reuse and boundary decisions

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| Cold-entry correlation | `DashboardCoreController` | extend the bounded Core trace; do not add a widget trace owner |
| Header/body acknowledgement | Mind header/body render seams | add correlated acknowledgement inputs only |
| Day visual alternative | `MindYearHeatmapPresentationSettings` | extend its enum/controller; do not create a Day store |
| Balance totals/latest/history | one all-time Core presentation keyed by non-temporal query provenance | consume only; no renderer data query or Summary-time subscription |
| Header trend visual | shared Header trend kernel extracted from Mind chart | typed score/money adapters only | no financial aggregation, ticker or expansion ownership |
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
| B1-OWNER | superseded by 2026-09-21 all-time contract | `DashboardCoreController` | Earlier current-scope Balance contract is obsolete and must not be used for delivery. | B7–B9 Core contracts and production Summary-navigation test | DONE |
| B2-HEADER | 2026-09-21 physical Balance feedback | Header detail seam and semantic colour tokens | Existing Header material remains owner; positive/negative net uses the canonical on-action foreground rather than the identical Balance background token. | `BALANCE-HEADER-VISIBILITY` RED→GREEN widget test | DONE |
| B3-LATEST | superseded by 2026-09-21 all-time contract | `DashboardCoreController` | Earlier current-scope latest-card contract is obsolete and must not be used for delivery. | B8 Core contract and positive prepared-revision test | DONE |
| B4-CAROUSEL | §12/13/14 Balance carousel | Balance surface adapter + shared centered carousel | Exactly five cyclic items, latest initially centred, four empty prototypes, and exactly three visible slots. | Balance widget/controller test | DONE |
| B5-MOTION | §8/13/14 shared motion | Balance adapter | One stable controller/ScrollPosition and exact `timeRefinementRail` identity; ballistic fling and new-pointer interruption work. | Balance widget test + shared controller/identity/widget tests | DONE |
| B6-BOUNDS | 2026-09-21 physical Balance feedback | Balance geometry/renderer | Selected centre is authored at the full `subheaderOne` structural height (scale 1); neighbours are shorter through existing scale, with real unclipped layout/hit/semantic bounds and one selected semantic item. The upper cascade intentionally has no placeholder surface; the lower `zone2` placeholder remains. | `BALANCE-UPPER-VISUALS` RED→GREEN geometry/widget test and collapsed CoreDashboard regression | DONE |
| NR1-PHYSICS | §8/11/15 protected milestone | shared/Budget source | Budget/Time/Avatar physics constants and owners remain unchanged from `6e962187`. | Shared/Budget regression run and source diff | DONE |
| P0-PROFILE | 2026-09-21 profile-gate audit | Core score/range preview lifecycle + profile test | Classify the `score.range != heatmap.range` slider failure against pre-`b799af3b` behavior; repair separately only if branch-introduced. | Pre-`b799af3b` Actions comparison, Core/store RED (`150000` vs `100000`), focused GREEN; final remote A–K run remains required | PARTIAL |
| B7-ALL-TIME | 2026-09-21 Balance clarification §4–7 | immutable Core Balance presentation | Header is `allTimeIncome - allTimeExpense` for current non-temporal query/filter identity; Summary Sum/Year/Month/Day changes neither identity nor notifier publication. | Real Core Summary target navigation, identity/publication counters, and a materially different all-time fixture | DONE |
| B8-LATEST-ALL-TIME | 2026-09-21 Balance clarification §8 | immutable Core Balance presentation | Latest card is the newest admitted item across both directions in the same all-time query universe; it changes only with real data/query/revision change. | Old-period/newer-outside prepared fixture plus post-frame-gate positive revision update | DONE |
| B9-HISTORY | 2026-09-21 Balance clarification §9–10 | Core all-time Balance history projection | Points are cumulative income minus expense; real first/last dates map to fixed plot edges; Summary movement cannot rebuild or alter the series. | Two-month/two-year, one-point/empty, cumulative-finance, immutable-object and notification tests | DONE |
| B10-HEADER-PARITY | 2026-09-21 Balance clarification §11–13 | shared Header trend kernel + Balance header composition | Mind output remains golden-compatible; Balance uses the same plot/style/reveal and money adapter, with amount at `left=16, top=16`. | Unchanged Mind chart/golden suite plus explicit Balance geometry/style/reveal tests | DONE |
| B11-WHITE-CARDS | 2026-09-21 Balance clarification §14 | Balance carousel card renderer | All five card surfaces use `FluviVisualTokens.surface`; no carousel motion/geometry owner changes. | All-five decoration/token RED→GREEN test and shared-carousel identity suite | DONE |
| B12-BOUNDARY | structuring-apps architecture gate | Balance Core/UI boundary | Presentation has no repository/ledger dependency, Core is the only Balance write owner, and the shared trend renderer owns no financial logic. | Focused single-runtime boundary/source-inspection test | DONE |
| P1-LOCAL-GEOMETRY | 2026-09-21 Balance polish §1/8/12 | Balance surface-local bounds | The upper Balance rail is exactly 10% taller; the same absolute delta moves/shrinks only its lower card, preserving the inter-card gap, lower bottom and dots. | `BALANCE-GEOMETRY-10PCT`, Core Balance geometry assertions | DONE |
| P1-CARD-MATERIAL | 2026-09-21 Balance polish §1/8/12 | Balance carousel card renderer | Every cyclic card reads the live `balanceContent` border and `contentCard` shadow scopes while retaining the canonical white fallback. | `BALANCE-CARD-MATERIAL` with two tuner profiles | DONE |
| P1-CHART-SETTINGS | 2026-09-21 Balance polish §1/14 | Balance-only session presentation controller and header adapter | Defaults preserve all-time history/static labels; Adaptive, all-time and truthful completed-month closing projections do not alter all-time Header/latest authority. | settings/projection + surface/tuner tests | DONE |
| P1-HEADER-INPUT | 2026-09-21 Balance polish §1/12/13 | Core mode host Header relay and brand lane | The real passive Header relay selects Balance X/Y inspection without stealing vertical pan; the one tuner button is above Header and its old label inset is absent. | `BALANCE-HEADER-ROUTE/BUTTON` host test | DONE |
| P1-CAROUSEL-CONTROLS | 2026-09-21 Balance polish §1/10/12/14 | Balance-local carousel adapter | 0–30% width is exact from the approved baseline; neutral-to-12% spacing stays in real three-slot hit/layout bounds with stable controller/position and shared motion identity. | `BALANCE-CHART-LABELS/CAROUSEL-CONTROLS`, shared/Budget suite | DONE |
| P1-NO-REFACTOR | 2026-09-21 Balance polish §1/11 | diff/source boundary | Mind chart, shared Header kernel, shared carousel, global layout/resolver, Budget/Time/Query/repository owners remain unchanged. | source diff + Mind no-change tests | DONE |
| P2-OWNER | 2026-09-22 lean Balance primary brief §8–12 | Core primary notifier + prepared membership projection | A small immutable, identity-keyed dual-direction primary presentation is built synchronously from resident directional prepared membership; UI/painter have no data capability and the all-time Header/latest presentation stays unchanged. | focused Core publication/reuse/no-source-work test | DONE |
| P2-SUM-YEAR | 2026-09-22 §13–14 | Balance primary projection + lower-card renderer | SUM renders paired annual Income/Expense values; YEAR renders twelve paired monthly values, including truthful zero periods. | projection and surface tests | DONE |
| P2-MONTH | 2026-09-22 §13–15 | Balance primary projection + step renderer | MONTH has one day point per calendar day, with period-local Income/Expense cumulative steps from zero and exact final metrics; DAY mounts no new chart. | month-rebase/final-total and Day-out-of-scope tests | DONE |
| P2-NEXT-FRAME | 2026-09-22 §13/15 | Core visible-frame callback | Sum/Year/Month target changes synchronously publish the matching resident presentation on the next normal Flutter frame with zero repository calls/index builds and no async scene/painter/timer gate. | production Core representative navigation test | DONE |
| P2-ENVELOPE | 2026-09-22 §11–15 | existing lower Balance card content | The existing lower card is populated without changing its bounds, lower bottom, upper relationship, dots, cascade or upper-carousel owner; local pair/day selection does not navigate Summary. | Balance surface geometry/interaction regressions | DONE |
| P2-NO-TOUCH | 2026-09-22 §11/17 | regression boundary | Balance Header, carousel controller/position/profile, Mind, Budget, Summary physics, global geometry, Query and repository owners remain unchanged. | relevant focused regressions and diff review | DONE |
| V1-DELIVERY | current repair delivery | commits/CI/APK/SCIP | Atomic application + journal commits, one final exact-SHA normal APK, and exact-source SCIP manifest are available. | New source requires a new Actions run, APK and final graph. | PARTIAL |
| V2-PHYSICAL | §4/20 | Android device | User alone validates final physical behavior. | User report | PENDING — USER ONLY |
