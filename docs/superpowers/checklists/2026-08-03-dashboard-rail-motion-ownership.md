# Dashboard rail motion ownership acceptance checklist

## Frozen display contract

`DashboardParentDisplayBundleController` remains the synchronous, immutable
display authority while a rail is open. A child preview never waits for a
repository watch, a native bridge callback or a query read. The current
`D12 → LOG_PREVIEW_BOUND` path is a regression baseline, not a replacement
candidate.

## Boundary card

| Concern | Sole owner | Explicit non-owner boundary |
| --- | --- | --- |
| Physical anchor, scroll position, native drag, ballistic activity, target calculation | `lib/shared/motion/centered_carousel/*` | Dashboard widgets and query code do not call `jumpTo`, `animateTo`, `goBallistic`, or compute a fling target. |
| Logical child preview and one semantic settle per user motion epoch | `CenteredCarouselController` low-level motion contract, adapted by `DashboardTimeNavigationController` | `TimeRefinementRail` only renders, collects pointer intent and forwards synchronous child callbacks. |
| Visible amount, count and first LogBox page | Parent display bundle plus summary/log display coordinators | A live repository cache miss never changes this display baseline. |
| Latest-wins observation/paging lease | New dashboard application lease coordinator | The rail physics, item builder and preview callback perform no I/O, scheduling, string logging or lease activation. |
| Human-readable diagnostics | Lazy export of bounded numeric traces | Motion hot paths never interpolate flow/query strings, print or copy a trace buffer. |

## Plane-alignment regression architecture card

| State | Owner | Publication and boundary |
| --- | --- | --- |
| Committed plane, parent scope and selected semantic child | `DashboardTimeNavigationController` | Its `railSourceRevision` changes for committed source transitions only; preview ticks never publish it. |
| Physical anchor for a replacement source | `CenteredCarouselController` and `CenteredCarouselScrollController` | The application controller stages a logical child. The shared carousel maps it to the next `ScrollPosition` initial pixels without moving the attached position. |
| Rail widget replacement | `TimeRefinementRail` | A narrow `ValueListenableBuilder` rebuilds only the rail on `railSourceRevision`; the source-keyed subtree replaces one viewport while retaining the shared controller and physics owner. |
| Query/display state | Existing Core/query/display coordinators | The transition remains a normal committed scope change; it receives no synthetic preview, settle or malformed physical-index selection. |

Layer flow: `Summary intent → DashboardTimeNavigationController → committed rail source revision → TimeRefinementRail → CenteredCarousel lifecycle`. No presentation layer derives a physical index or commands scroll motion.

## Requirements inventory

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RMO-01 | User §§1, 12, 14, 24.8, 24.11, 24.13 | Bundle, summary and LogBox coordinators | For every preview and settle frame, navigation, amount, count and LogBox carry one identical `queryKey`; correct finite-bundle content is synchronous, with no `—`, relabelled old rows or empty transient state. | Core finite-bundle child-loop, summary amount/count and LogBox no-rebind tests; full suite green. | DONE |
| RMO-02 | User §§3–4, 8–10 | Shared carousel controller, widget and dashboard rail adapter | Startup, rail-open and ordinary layout do not cause a jump, animate, ballistic activity, selection sequence or semantic settle. Initial logical child is already at the physical anchor before first attach; raw PageStorage restoration is disabled. | Two-second rail-open test asserts anchor + logical offset, one attached position and zero programmatic/ballistic/semantic trace events. | DONE |
| RMO-03 | User §§5–7, 24.3–4, 24.12 | Shared carousel physics and controller | Native `Scrollable` drag plus exactly one pure custom `ScrollPhysics` simulation owns a drag fling. Existing velocity bands, maximum item step, cyclic mapping and boundary target remain deterministic for data/no-data/logger variants. | Pure repeated-factory, low-velocity, max-step and 100-run target-determinism tests. | DONE |
| RMO-04 | User §§5, 10–11, 24.3, 24.14 | Shared carousel motion state | `RailMotionOrigin` and epoch make programmatic initialisation/dimension correction non-semantic; one user motion epoch emits at most one depth-0 semantic settle and duplicate idle/end signals are suppressed. | Two-fling widget test asserts one final-epoch settle; controller dedupes by epoch and the unused `ScrollEndNotification` path is removed. | DONE |
| RMO-05 | User §§4–5, 22 | Shared carousel diagnostics and dashboard performance trace | Controller attach, position count, activity transition, programmatic request, ballistic start and semantic settle append fixed-size numeric events to a bounded ring. Motion path performs no verbose query/flow-string formatting. | Ring-capacity unit test plus rail-open and fling trace assertions; default FLOW diagnostics are opt-in and D12/preview/tick call sites are gated before string construction. | DONE |
| RMO-06 | User §§10, 20–21, 24.6–7 | `TimeRefinementRail`, `DashboardMotionHost`, Core Dashboard | A rail has one stable controller and position through 100 preview swaps, expand/collapse and query emission. Preview or LogBox changes cannot rebuild/recreate the rail viewport/physics; rail and LogBox are separately repaint-bounded. | 100 preview rebuilds preserve controller, position and physics identity; query-only MotionHost and open-rail header-collapse identity tests pass; rail and LogBox are separately repaint-bounded. | DONE |
| RMO-07 | User §§12–13, 20–21 | Rail adapter and dashboard presentation | Each framework-reported child crossing synchronously selects the O(1) immutable preview; tick pulse/haptic remain paint-only/non-awaited and do not move the scroll position or modify target choice. | Multi-crossing preview/tick and haptic-throttle tests; physics target suite remains deterministic. | DONE |
| RMO-08 | User §§2, 14, 19, 24.11 | Core, query and LogBox application layer | A matching preview promotes immediately at settle (`visualChange=false`, `listRebound=false`, `amountAnimationStarted=false`) before any live read; identical fresh results update only freshness metadata. | Existing cached-preview promotion and identical committed LogBox-bind identity tests; full suite green. | DONE |
| RMO-09 | User §§15–18, 24.9–10 | New live-query lease coordinator and `CurrentQueryController` | Committed display scope is immediate; live observation is latest-wins after quiescence. Active drag/ballistic has zero watch requests, initial reads, first-page binds or live projections. Ten rapid flings start no intermediate lease/read and exactly one final lease. | Latest-wins and active-ballistic coordinator unit tests plus the Core recording-repository ten-rapid-child-commit test prove zero intermediate watches and one final lease. | DONE |
| RMO-10 | User §§17–19 | Query controller/repository bridge | An old live lease remains until an allowed replacement is active; stale results cannot bind. Equal `(queryKey, revision, digest)` never publishes a new list, amount/count or LogBox page. | Existing stale-generation coverage plus new full first-page content-digest test: equal live content preserves state identity, while an equal-ID changed partner label binds once. | DONE |
| RMO-11 | User §§20–22 | Motion host, rail/log display lanes, query debug | Query/status/log changes do not notify the rail motion lane. Long readable FLOW logging is disabled for motion; numeric ring export is lazy. | MotionHost query-only widget test, preview shell rebuild test and numeric trace test pass; hot D12/preview/tick logging is gated. | DONE |
| RMO-12 | User §23, §25 | Performance trace and Android profile workflow | Profile-mode physical-device evidence records UI/raster p50/p90/p99/worst, jank count, allocations and the A–K matrix. No debug timing is represented as final performance evidence. Full-data vs detached target is identical and the recorded p90/p99 deltas meet the stated goals. | Profile capture artifact and documented measured table; no golden tests requested. | BLOCKED — requires a physical device profile run after implementation. |
| RMO-13 | User §25 and delivery instruction | CI/release delivery | Targeted and relevant broader tests/analyze pass in Ubuntu proot; branch commits are pushed; GitHub Actions APK succeeds; exact APK/checksum is copied to `/storage/emulated/0/Download/fluvi/`. | Current change set: 94 focused tests and `flutter analyze` pass in Ubuntu proot. The commit/push/online APK is the remaining delivery step. | PARTIAL |
| RMO-14 | User report 2026-08-03: SUM year selection → YEAR month selection → MONTH day selection | `DashboardTimeNavigationController`, `TimeRefinementRail`, `DashboardMotionHost` | A committed plane or parent-scope transition immediately supplies the rail with exactly that plane's datasource and selected child: SUM displays years, YEAR displays months of the selected year, MONTH displays days of the selected year-month. The same transition must never turn `2026` into a synthetic `2182`/`2184` scope. | Controller regression `plane transitions prepare...`; rail widget regression validates 12-month then 31-day sources; production `CoreDashboard` regression validates the same boundary below the motion host. | DONE |
| RMO-15 | User report 2026-08-03: massive lag and cross-plane query churn | Shared carousel lifecycle boundary and rail presentation selector | A source transition may reattach one viewport at its prepared initial anchor, but it must not issue `jumpTo`, `animateTo`, ballistic motion, preview, settle or live-query work. Preview updates remain excluded from the rail source rebuild boundary. | Shared controller test asserts a pending source target maps to next-attach pixels with an empty trace; rail widget asserts one attached position and zero ballistic, semantic-settle and programmatic-motion trace events across SUM → YEAR → MONTH. | DONE |
| RMO-16 | Structuring Apps architecture gate and user boundary instruction | Time navigation application/presentation/shared carousel boundaries | Navigation state remains solely owned by `DashboardTimeNavigationController`; the widget only listens to a committed-source selector and renders it. The shared carousel retains all physical positioning/physics ownership, with no dashboard-specific motion copy. | Regression architecture card above; dependency inspection shows UI receives `ValueListenable<int>` and no query/repository or scroll-command dependency. | DONE |
| RMO-17 | User report 2026-08-03: startup seed races the first dashboard read, then amount/count start as `—` | App shell bootstrap, demo seed, `DashboardCoreController` initialization | No dashboard query, display-deck read or live watch begins before the debug seed has committed. The first interactive dashboard frame has one exact selected scope, concrete amount/count, and a matching first LogBox page. | App-bootstrap test records `seed → controller(autoStart=false)` order; Core bootstrap test binds exact first page and finite deck without a watcher; app-shell fallback test prevents permanent blank transport failure. No golden test. | DONE |
| RMO-18 | User clarification 2026-08-03: SummaryPill right-to-left swipe must increase the Year parent whether the child rail is open or closed | SummaryPill intent boundary, Core parent-navigation coordinator, adjacent parent deck cache | A qualifying horizontal SummaryPill swipe in `TimePlane.year` is accepted in both rail states. Once its prewarmed target is ready, navigation, amount/count, and LogBox atomically move to `yearCursor + 1`; a cold target is explicitly traced and has one latest-wins preparation, never a silent no-op. | SummaryPill widget test covers right-to-left intent for open/closed rails; Core recording-repository test stages target deck/page then commits 2027/2028 atomically. No golden test. | DONE |
| RMO-19 | User report 2026-08-03: Year/month and Month/day child rails are non-smooth; cache/boundary question | Bootstrap/display-deck coordinator and bounded year-child cache | Entering a finite plane prepares the active parent deck plus its adjacent parents before their SummaryPill swipe is needed. SUM/year children receive a bounded authoritative coverage deck (explicit populated or verified-empty snapshots), so preview uses O(1) data and never starts storage/bridge work. The shared carousel physics and tick semantics remain unchanged. | Current/adjacent finite-deck and 401-year SUM coverage tests; rail target/identity and every-selected-child query-key tests. No golden test. | DONE |
| RMO-20 | User report 2026-08-03: completed preview is followed by repeated watch/read work and jank | `DashboardLiveQueryLeaseCoordinator`, current-query/display boundary | Display snapshot readiness is independent of live-watch readiness. A settled child promotes its exact preview immediately; only the final quiescent scope owns one detailed live lease. A new rail epoch cancels an unstarted candidate, and identical fresh content never rebinds the display. | Rapid-fling, prepared-scope, identical-content and active-motion coordinator coverage; recording repository sees zero intermediate watch/read calls. | DONE |
| RMO-21 | User request 2026-08-03: relevant debug logging for tuning | App bootstrap, parent navigation, deck/prewarm and live-lease diagnostics | Debug mode records one structured boundary event for bootstrap start/seed-ready/initial-display-ready; parent swipe candidate/accept/block/commit; deck cache hit/miss/prewarm ready; and live-lease candidate/cancel/activate/result-drop. Rail ticks retain only the existing bounded numeric trace: no per-tick FLOW string construction or `debugPrint`. Logs contain plane, parent/child scope, revision, generation/epoch, cache state and duration where applicable. | Direct code inspection of opt-in boundary gates plus focused Core/query/LogBox tests; numeric rail trace tests retain hot-path coverage. | DONE |

## Bootstrap, parent-swipe and cache boundary card

| Concern | Sole owner | Explicit non-owner boundary |
| --- | --- | --- |
| Debug data readiness and the first selected time scope | App-shell bootstrap coordinator | `DashboardCoreController` must not independently refresh or watch while seed/bootstrap is unresolved. |
| Immediate amount/count/first LogBox page | Immutable display bundle or bounded year-coverage deck | `CurrentQueryController` live-watch cache is not the display-readiness signal. |
| SummaryPill parent swipe | `DashboardCoreController` parent-navigation coordinator | `DashboardSummaryPill` only emits one directional intent; it never reads, waits for I/O, or decides cache readiness. |
| Current/adjacent deck warmup | Parent/coverage display-cache coordinator | The rail, physics and selected-child callback never start a warmup. |
| Detailed observation | Latest-wins lease coordinator | It may update freshness after a quiescent boundary but cannot delay or replace a ready display snapshot. |
| Human-readable tuning logs | Boundary diagnostics exporter | The carousel hot path remains numeric-ring-only; no readable log is formed per item crossing. |

Boundary flow: `seed/DB ready → atomic initial display deck → interactive dashboard → O(1) child preview → semantic settle promotion → latest-wins live lease`.

### Required tuning events

- `BOOTSTRAP_STARTED`, `BOOTSTRAP_SEED_READY`, `BOOTSTRAP_INITIAL_SCOPE_READY`, `BOOTSTRAP_DISPLAY_READY`, `BOOTSTRAP_FAILED`
- `PARENT_SWIPE_CANDIDATE`, `PARENT_SWIPE_ACCEPTED`, `PARENT_SWIPE_BLOCKED`, `PARENT_PREWARM_READY`, `PARENT_SWIPE_COMMITTED`
- `DISPLAY_DECK_LOOKUP`, `DISPLAY_DECK_PREWARM_REQUESTED`, `DISPLAY_DECK_PREWARM_READY`, `YEAR_COVERAGE_LOOKUP`
- `LIVE_LEASE_CANDIDATE`, `LIVE_LEASE_CANCELLED`, `LIVE_LEASE_ACTIVATED`, `LIVE_RESULT_IGNORED_IDENTICAL`, `LIVE_RESULT_DROPPED_STALE`

Each boundary event records compact identifiers/integers for plane, parent/child
scope, core revision, cache state, generation/motion epoch and elapsed time.
Full scope/query strings are rendered only by an explicit diagnostic export.

## Current audited evidence (before implementation)

- `CenteredCarousel` schedules `jumpToIndex` from both controller replacement
  and `LayoutBuilder` viewport changes.
- `TimeRefinementRail._syncMotionBaseline` schedules a second post-frame
  `jumpToIndexSilently` and defers preview propagation by a post-frame
  callback.
- `CenteredCarouselController.updateConfiguration`, `recenterSelected` and
  `rebaseIfNeeded` call public `ScrollController.jumpTo`; its controller is
  constructed with the default raw offset and default `keepScrollOffset`.
- `CenterSnapScrollPhysics.createBallisticSimulation` currently calls target
  observer callbacks and freezes mutable plan state, so it is not pure.
- A baseline rail widget test emits repeated `R2`/snap events without an
  accepted user selection, proving that callback gating alone did not remove
  physical activity.
- `DashboardCoreController` calls `CurrentQueryController.setTimeScope` at
  settle; a cache miss immediately invokes `_startWatching`, repository
  subscription and initial read. Query notifications reach `DashboardMotionHost`.
