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
| RMO-13 | User §25 and delivery instruction | CI/release delivery | Targeted and relevant broader tests/analyze pass in Ubuntu proot; branch commits are pushed; GitHub Actions APK succeeds; exact APK/checksum is copied to `/storage/emulated/0/Download/fluvi/`. | The preceding baseline was delivered by [run 30834186844](https://github.com/elizerpist/exptv2/actions/runs/30834186844) for `7ca8720`. This follow-up regression fix needs its own pushed CI build and APK download. | NOT DONE |
| RMO-14 | User report 2026-08-03: SUM year selection → YEAR month selection → MONTH day selection | `DashboardTimeNavigationController`, `TimeRefinementRail`, `DashboardMotionHost` | A committed plane or parent-scope transition immediately supplies the rail with exactly that plane's datasource and selected child: SUM displays years, YEAR displays months of the selected year, MONTH displays days of the selected year-month. The same transition must never turn `2026` into a synthetic `2182`/`2184` scope. | Controller regression `plane transitions prepare...`; rail widget regression validates 12-month then 31-day sources; production `CoreDashboard` regression validates the same boundary below the motion host. | DONE |
| RMO-15 | User report 2026-08-03: massive lag and cross-plane query churn | Shared carousel lifecycle boundary and rail presentation selector | A source transition may reattach one viewport at its prepared initial anchor, but it must not issue `jumpTo`, `animateTo`, ballistic motion, preview, settle or live-query work. Preview updates remain excluded from the rail source rebuild boundary. | Shared controller test asserts a pending source target maps to next-attach pixels with an empty trace; rail widget asserts one attached position and zero ballistic, semantic-settle and programmatic-motion trace events across SUM → YEAR → MONTH. | DONE |
| RMO-16 | Structuring Apps architecture gate and user boundary instruction | Time navigation application/presentation/shared carousel boundaries | Navigation state remains solely owned by `DashboardTimeNavigationController`; the widget only listens to a committed-source selector and renders it. The shared carousel retains all physical positioning/physics ownership, with no dashboard-specific motion copy. | Regression architecture card above; dependency inspection shows UI receives `ValueListenable<int>` and no query/repository or scroll-command dependency. | DONE |

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
