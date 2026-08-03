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

## Requirements inventory

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RMO-01 | User §§1, 12, 14, 24.8, 24.11, 24.13 | Bundle, summary and LogBox coordinators | For every preview and settle frame, navigation, amount, count and LogBox carry one identical `queryKey`; correct finite-bundle content is synchronous, with no `—`, relabelled old rows or empty transient state. | Existing deck tests extended with atomic-key and no-placeholder assertions. | NOT DONE |
| RMO-02 | User §§3–4, 8–10 | Shared carousel controller, widget and dashboard rail adapter | Startup, rail-open and ordinary layout do not cause a jump, animate, ballistic activity, selection sequence or semantic settle. Initial logical child is already at the physical anchor before first attach; raw PageStorage restoration is disabled. | Startup/rail-open/initial-anchor/widget trace tests; runtime numeric trace. | NOT DONE |
| RMO-03 | User §§5–7, 24.3–4, 24.12 | Shared carousel physics and controller | Native `Scrollable` drag plus exactly one pure custom `ScrollPhysics` simulation owns a drag fling. Existing velocity bands, maximum item step, cyclic mapping and boundary target remain deterministic for data/no-data/logger variants. | Physics purity, duplicate factory-call, low-velocity and data-detached target tests. | NOT DONE |
| RMO-04 | User §§5, 10–11, 24.3, 24.14 | Shared carousel motion state | `RailMotionOrigin` and epoch make programmatic initialisation/dimension correction non-semantic; one user motion epoch emits at most one depth-0 semantic settle and duplicate idle/end signals are suppressed. | Single-owner, duplicate-idle and stale-epoch tests. | NOT DONE |
| RMO-05 | User §§4–5, 22 | Shared carousel diagnostics and dashboard performance trace | Controller attach, position count, activity transition, programmatic request, ballistic start and semantic settle append fixed-size numeric events to a bounded ring. Motion path performs no verbose query/flow-string formatting. | Unit tests for ring capacity/content and debug-log-disabled trace inspection. | NOT DONE |
| RMO-06 | User §§10, 20–21, 24.6–7 | `TimeRefinementRail`, `DashboardMotionHost`, Core Dashboard | A rail has one stable controller and position through 100 preview swaps, expand/collapse and query emission. Preview or LogBox changes cannot rebuild/recreate the rail viewport/physics; rail and LogBox are separately repaint-bounded. | Widget identity/position-count tests and rebuild instrumentation. | NOT DONE |
| RMO-07 | User §§12–13, 20–21 | Rail adapter and dashboard presentation | Each framework-reported child crossing synchronously selects the O(1) immutable preview; tick pulse/haptic remain paint-only/non-awaited and do not move the scroll position or modify target choice. | Ten-crossing callback sequence plus haptic/tick A/B trace tests. | NOT DONE |
| RMO-08 | User §§2, 14, 19, 24.11 | Core, query and LogBox application layer | A matching preview promotes immediately at settle (`visualChange=false`, `listRebound=false`, `amountAnimationStarted=false`) before any live read; identical fresh results update only freshness metadata. | Promotion and identical-result no-rebind tests. | NOT DONE |
| RMO-09 | User §§15–18, 24.9–10 | New live-query lease coordinator and `CurrentQueryController` | Committed display scope is immediate; live observation is latest-wins after quiescence. Active drag/ballistic has zero watch requests, initial reads, first-page binds or live projections. Ten rapid flings start no intermediate lease/read and exactly one final lease. | Fake-time lease tests, core integration regression and numeric trace counters. | NOT DONE |
| RMO-10 | User §§17–19 | Query controller/repository bridge | An old live lease remains until an allowed replacement is active; stale results cannot bind. Equal `(queryKey, revision, digest)` never publishes a new list, amount/count or LogBox page. | Recording-repository generation and stale-result tests. | NOT DONE |
| RMO-11 | User §§20–22 | Motion host, rail/log display lanes, query debug | Query/status/log changes do not notify the rail motion lane. Long readable FLOW logging is disabled for motion; numeric ring export is lazy. | Rebuild-count test and logger-off/ring-on test. | NOT DONE |
| RMO-12 | User §23, §25 | Performance trace and Android profile workflow | Profile-mode physical-device evidence records UI/raster p50/p90/p99/worst, jank count, allocations and the A–K matrix. No debug timing is represented as final performance evidence. Full-data vs detached target is identical and the recorded p90/p99 deltas meet the stated goals. | Profile capture artifact and documented measured table; no golden tests requested. | BLOCKED — requires a physical device profile run after implementation. |
| RMO-13 | User §25 and delivery instruction | CI/release delivery | Targeted and relevant broader tests/analyze pass in Ubuntu proot; branch commits are pushed; GitHub Actions APK succeeds; exact APK/checksum is copied to `/storage/emulated/0/Download/fluvi/`. | Command output, Actions URL/checksum and local file hash. | NOT DONE |

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

