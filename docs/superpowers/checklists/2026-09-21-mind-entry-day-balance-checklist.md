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
| V1-DELIVERY | current repair delivery | commits/CI/APK/SCIP | Atomic application + journal commits, one final normal APK whose journal-only build identity maps to the application source, and exact-source SCIP manifest are available. | Actions `35701267409`, downloaded human APK, final graph manifest and tooling commit. | DONE |
| L1-OWNER | 2026-09-23 linked Balance brief | Core linked presentation + Balance surface | One immutable, resident-data Balance presentation owns scoped Cashflow, latest list, rankings and direction/scope provenance; the UI only selects/render topics. | focused Core boundary/reuse test plus source import inspection | DONE — Core-owned immutable DTO/cache; renderer boundary test |
| L2-LINK | 2026-09-23 master-detail contract | existing Balance upper carousel + lower card host | The selected center card deterministically selects Cashflow, Latest transaction, Top category or Top partner detail; fifth slot remains a prototype. | focused surface widget test | DONE — all five selection endpoints and linked-payload continuity |
| L3-CASHFLOW | 2026-09-23 Cashflow contract | existing primary projection/card | Small card shows scope-local net; lower card preserves SUM/YEAR/MONTH behavior and DAY no-chart shell. | existing primary projection/card regressions plus linked-card test | DONE — primary/projection/card regressions |
| L4-LATEST | 2026-09-23 Latest contract | Core linked projection + Balance cards | Small preview and bounded lower list are scoped to the active Summary period and choose the newest across both directions with existing ordering. | Core + widget scoped-list test | DONE — newest cross-direction bounded list test |
| L5-CATEGORY | 2026-09-23 user clarification | Core linked projection + ranking card | Top category uses only the active Income/Expense direction, ranks by absolute total amount, and small preview equals first-ranked item. | directional ranking unit and ranking-card widget test | DONE — directional amount-rank projection/composition tests |
| L6-PARTNER | 2026-09-23 user clarification | Core linked projection + ranking card | Top partner uses only the active Income/Expense direction, ranks by transaction count, and small preview equals first-ranked item. | directional ranking unit and ranking-card widget test | DONE — directional transaction-count rank tests |
| L7-VISUAL | 2026-09-23 screenshot references | Balance ranking-card renderer | White card, featured rank one, colorful entry-derived badge/icon, remaining ranks and right-aligned value follow the supplied references without a nested time switch. | composition widget test + screenshot/reference inspection | DONE — source screenshots inspected; five-row composition test |
| L8-HOT-PATH | 2026-09-23 performance contract | Core visible-frame publication | Summary/direction crossings synchronously use resident prepared membership with zero repository/index/scene/timer dependency. | next-frame no-source-work Core test | DONE — next-frame scoped direction test verifies zero source work |
| L9-NO-TOUCH | 2026-09-23 scope lock | diff/regression boundary | Header Compound chart remains Header-only; carousel physics/controller/position, Mind, Budget, Summary, global geometry, Query and repository owners are unchanged. | focused regressions + diff inspection | DONE — 122 guard tests plus targeted diff review |
| V2-PHYSICAL | §4/20 | Android device | User alone validates final physical behavior. | User report | PENDING — USER ONLY |
| C1-COMPOUND-MODE | 2026-09-23 Compound prompt | Balance Header settings/projection | The Header tuner offers exactly four modes including `Compound`; no Header amount authority changes. | `balance_presentation_settings_test.dart` Compound contract | DONE |
| C2-COMPOUND-SUM-YEAR | 2026-09-23 Compound prompt | `DashboardBalanceHistoryViewProjection` | Compound uses truthful all-time monthly closes for SUM and filters those absolute closes to the selected YEAR without future-month fabrication. | Compound SUM/YEAR pure-projection assertions | DONE |
| C3-COMPOUND-MONTH-DAY | 2026-09-23 Compound prompt | `DashboardBalanceHistoryViewProjection` | Compound preserves raw adaptive transaction order for selected MONTH and existing DAY fallback. | Compound MONTH/DAY pure-projection assertions | DONE |
| C4-COMPOUND-INVARIANTS | 2026-09-23 Compound prompt | existing Header chart adapter | All-time Header amount, point inspection and static X labels stay independent of Compound projection selection. | Header settings/surface regression assertions | DONE |
| M1-OWNER | Category Movers prompt §§7/12/13/16 | Core linked Balance presentation | One existing Balance carousel selection maps the upper hero and lower Movers renderer; Core publishes a query/direction/revision/time/as-of coherent immutable payload from resident prepared membership. | linked identity + 108-test Core hot-path suite | DONE |
| M2-MATH | Category Movers prompt §10 | Balance-specific pure Movers projection | Movers rank by absolute integer money delta, with deterministic ties and finite `New`/zero/-100% semantics. | Movers calculation/tie tests | DONE |
| M3-WINDOWS | Category Movers prompt §11 | Balance-specific pure Movers projection | Day, Month, Year and Sum use the specified calendar windows from `logicalAsOfDate`, never wall clock. | Movers temporal-window tests | DONE |
| M4-QUERY-HIERARCHY | Category Movers prompt §12/22 | Core resident membership → Movers projection | Selected direction and existing focus/query membership remain exact; one prepared canonical category id per entry prevents parent/child double count. | linked direction/identity and Core hot-path tests | DONE |
| M5-CARDS | Category Movers prompt §§8/9/15 | existing Balance upper/lower card slots | Upper hero shows the first money-impact mover; lower shows bounded diverging ranked rows, and a row opens an in-card immutable category trend with Back. | linked-card and Balance surface widget tests | DONE |
| M6-GESTURES-HOTPATH | Category Movers prompt §§18/25 | Balance surface/Core publication | Card gestures stay local, global mode/Query/LogBox remain unchanged, and build/paint/gesture paths only consume the immutable payload. | Material-free cold-entry regression, host/shared/Budget and Core hot-path suites | DONE |
| M7-INDICATORS | Category Movers prompt §17 | Balance Zone2 indicator renderer | Six real Balance insight indicators use the existing selected topic; exactly one is semantically active and no empty/prototype indicator is fabricated. | `MOVERS-INDICATORS` surface widget test | DONE |

## 2026-09-23 — Period Closings and Balance Momentum architecture card

### Single source and write path

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Closings buckets and Momentum rates | `DashboardBalanceLinkedProjection` | one exact linked-presentation identity | Core builds once from resident Income + Expense memberships |
| Logical comparison clock | `DashboardCoreController` | controller lifetime | one resolved initial `DateTime` publishes immutable date and local minute |
| Selected upper topic | `BalanceDashboardCoreSurface` | mounted Balance surface | local only; never changes Query or Summary |
| Selected closing bucket | `BalanceLinkedDetailCard` | mounted lower-card renderer | local only; never acquires data |
| Carousel gesture/motion | existing `CenteredCarousel` | stable Balance controller/position | unchanged shared owner |

### Reuse and boundary decision

`DashboardBalanceLinkedPresentation` is extended rather than creating a second
Query, repository, cache, controller or renderer-side aggregation. Closings
and Momentum are separate immutable read models because their mathematics and
visuals differ; they share the existing linked-presentation identity, resident
memberships, cache, one carousel and one lower-card shell. The Budget
eight-bucket `SpendingRhythmDayPart` stays a distinct owner.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PC1-OWNER | user §§11,20,22 | linked projection + Core cache | Closings and Momentum are immutable, bounded Core DTOs built once from resident Income and Expense memberships; widgets do no aggregation/I/O. | pure projection + Core no-source-work tests and source import check | DONE |
| PC2-SUM | user §12.2 | Closings projection | SUM has one truthful sparse real-year bucket with exact Income, Expense and net. | CLOSING-SUM unit fixture | DONE |
| PC3-YEAR-MONTH | user §12.2 | Closings projection | YEAR has 12 non-cumulative monthly buckets; MONTH has real calendar day buckets, including 28/29/30/31-day months. | CLOSING-YEAR/MONTH leap and zero fixtures | DONE |
| PC4-DAYPARTS | user §12.2 | Balance-local Closings projection | DAY has exactly six named local dayparts with all specified boundary minutes; Budget's eight buckets are unchanged. | CLOSING-DAY boundary fixture plus Budget guard | DONE |
| PC5-CLOSINGS-UI | user §§12.3–12.5,26 | one existing lower-card dispatch + Balance carousel preview | Preview reports truthful `N / M pozitív`; lower card uses centered symmetric zero axis, diverging discrete bars, compact local selection and no Summary mutation. | renderer sign/bounds/selection widget tests | DONE |
| BM1-CLOCK | user §§9.6,13.3 | `DashboardCoreController` | Core retains date and local minute from the one injected/resolved initial time; no independent wall-clock/timer read occurs. | deterministic injected-time Core test | DONE |
| BM2-WINDOWS | user §14 | Momentum projection | SUM/YEAR/MONTH/DAY use specified comparable windows, leap/month clamps and historical anchors from resident all-history membership. | SUM/YEAR/MONTH/DAY window fixtures | DONE |
| BM3-MATH-STATE | user §§13,15,19 | Momentum projection | Integer financial totals yield finite normalized pace/momentum; four quadrants, five exact-zero states and unavailable history are explicit. | quadrant/zero/insufficient unit fixtures | DONE |
| BM4-MOMENTUM-UI | user §§16–18,26 | one existing lower-card dispatch + Balance carousel preview | Preview and lower card use the same DTO; lower view is a symmetric four-quadrant map with one correctly located point and three rate metrics, never a time-series chart. | map sign/axis/metrics/empty widget tests | DONE |
| BC1-SIX-TOPICS | user §§1,21,26 | Balance topic mapping/surface/detail dispatch | Exactly Cashflow, Closings, Momentum, Latest, Top category and Top partner exist; prototype is absent and both new topics select the one lower card. | six-topic mapping/wrap/semantics widget tests | DONE |
| BC2-IDENTITY-HOTPATH | user §§20,21,25,29 | Core publication + existing carousel adapter | Data refresh retains selected logical index, controller and ScrollPosition; selecting either new topic performs zero repository/index/scene/TextPainter work. | production Core counters and carousel identity test | DONE |
| BC3-BOUNDS-GESTURES | user §22,26 | Closings/Momentum lower renderers | Normal and compact bounds avoid overflow/clipped hit surfaces; bar/map gestures are local and never compete with global/carousel movement. | compact and interaction-bound widget tests | DONE |
| BC4-NO-TOUCH | user §§9.7,30 | diff/regression boundary | Cashflow, Header/Compound, Mind, Budget taxonomy, shared carousel engine/profile, Summary/global geometry, Query and repository remain unchanged. | protected shared/Budget/Mind suites plus diff review | DONE |
| BC5-DELIVERY | user §§33–37 | commits, CI, APK and codegraph | One application commit, journal-only follow-up, exact final-source SCIP, successful human APK and hash are delivered; physical validation is honestly pending. | commit/Actions/APK/manifest checks | DONE |

## 2026-09-23 — Combined Balance expansion acceptance card

The current behavioural base is `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`.
It already contains Closings and Momentum; the incoming prompt portions that
describe a six-slot/prototype-only source are stale. The bundle therefore adds
four topics to the current six real topics, and enriches the existing Closings
preview without giving it a second aggregate path.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BX1-TOPICS | Ghost/Forecast §§10,14–17 | Balance topic list, indicator IDs, lower dispatch | Ten real topics preserve Cashflow/Closings/Momentum/Latest/Category/Partner and add Retention, Stability, Fix terhek and Forecast; no prototype returns. | mounted surface and detail selection tests | DONE |
| BX2-PLACEHOLDERS | Ghost/Forecast §§15,17 | Balance-local static placeholder renderer | Ghost/Forecast have no amount/count/transaction/data model, no computation and no nested page gesture; copy truthfully states that the engines are not connected. | copy/source and mounted widget tests | DONE |
| BX3-RETENTION | Retention §§4,13–14 | immutable linked DTO/projection + renderer | Dual-direction formula, noIncome/noData distinction, SUM aggregate, selected YEAR siblings and continuous MONTH/DAY month siblings are exact. | pure RED→GREEN and widget tests | DONE |
| BX4-STABILITY | Stability §§4,13–15 | immutable linked DTO/projection + renderer | Complete-month samples, deterministic even median/MAD-style band, 3-sample unavailable state and distribution-band visual are exact. | pure RED→GREEN and widget tests | DONE |
| BX5-BREAK-EVEN | Break-even §§1,13–14 | existing Closings preview | The compact strict-positive fraction uses the same immutable Closings buckets as the lower card, with scope-correct unit wording and no `0 / 0`. | DTO/copy tests | DONE |
| BX6-OWNERSHIP | both prompts §§12,15,24–26 | Core/surface lower-envelope seam | One Core payload/cache, carousel controller/position/physics and lower card remain; selection causes no data work and bounds stay compact-safe. | Core counters/controller/bounds tests | DONE |
| BX7-DELIVERY | user final build requirement | app commit, Actions, APK, SCIP, journal | All five requested features are in one app-code build; final graph matches exact app SHA and journal follows separately. | CI/APK/hash/manifest/git evidence | PARTIAL — final application commit, one remote build/APK, exact-source SCIP and journal evidence are pending. |
