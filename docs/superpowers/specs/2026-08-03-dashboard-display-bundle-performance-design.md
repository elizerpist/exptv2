# Dashboard display-bundle performance and determinism design

## Goal

Remove the content-dependent rail-preview regressions without changing any
`CenteredCarouselSpec` physics constant. A finite parent (MONTH/day or
YEAR/month) is represented by one immutable, complete, pinned display bundle;
the rail preview is then a synchronous lookup and an equal preview settles by
promotion rather than visual rebind.

## Root-cause evidence

- `CurrentQueryController` caches individual `LedgerQueryKey` results with a
  36-entry / 1000-row LRU. It has no parent/deck membership or pinning
  (`lib/features/dashboard/query/application/current_query_controller.dart`).
- The finite warmer performs one native first-page read per child, sequentially
  and publishes those entries independently. The LogBox coordinator owns a
  second 30-page/1000-row preview-state LRU
  (`dashboard_log_page_coordinator.dart`). Neither cache can state that a
  parent deck is complete.
- Empty result is only inferred from an empty `dayGroups` list. It is not an
  explicit child snapshot inserted for every calendar child, so absent and
  present-empty cannot be distinguished at the deck boundary.
- A settled cache-hit creates a new committed LogBox state through
  `_synchronizeCommittedQuery` and separately changes metrics provenance. The
  existing equality checks are local to each owner, so they do not centralize
  the preview-to-committed visual promotion decision.
- `DashboardCoreController.prefetchLogForRailTarget` is called by the rail's
  resolved target callback regardless of finite deck completeness.

## Architecture card

### Scope and sources

- User performance/determinism specification, 2026-08-03 §§1-42.
- Flutter profile/DevTools guidance: profile mode; UI and raster frames;
  optional build/layout/paint tracing; targeted RepaintBoundary use.
- Existing owners:
  - `DashboardTimeNavigationController`: navigation state and logical child.
  - `CenteredCarouselController` / `CenterSnapScrollPhysics`: gesture,
    physics, target and crossing semantics.
  - `CurrentQueryController`: committed query/watch owner.
  - `DashboardSummaryMetricsController` and `DashboardLogPageCoordinator`:
    current separate preview projections (to be adapted to the bundle owner).

### Single source and write path

| State | Owner | Write path | Publication rule |
| --- | --- | --- | --- |
| Parent display bundle cache | `DashboardParentDisplayBundleController` | repository batch result -> validate -> one cache insertion | finite bundle publishes only when complete |
| Displayed snapshot | `DashboardParentDisplayBundleController` | navigation preview/settle + bundle lookup | O(1) immutable snapshot selection |
| Committed detailed query/watch | `CurrentQueryController` | existing `DashboardCoreController` settle path | unchanged canonical query owner |
| Preview-to-commit promotion | `DashboardParentDisplayBundleController` | exact identity/content comparison | no visual notifier when equal |
| Rail target/crossings | existing centered-carousel engine | drag-end physics and scroll simulation | no data/cache side effect may change target |
| Profile trace | injected `DashboardPerformanceTrace` | numeric append / timeline only | disabled by default; no formatted FLOW strings on hot path |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Canonical scope/key creation | `CurrentLedgerQueryScope` | reuse; bundle key holds the existing typed parent scope/key |
| Child summary aggregation predicate | native `FluviLedgerReadService` | extend with one parent display-bundle read; do not duplicate SQL in Flutter |
| LogBox view-model projection | `DashboardLogViewModelProjector` | run once during bundle construction; preview uses stored VMs |
| Cache policy | separate item LRUs | replace finite-preview ownership with one bundle LRU and pin set |
| Rail target calculation | `centered_carousel_physics.dart` | expose a pure `RailFlingPlan` wrapper; constants unchanged |
| Diagnostic logger | `FluviDiagnosticLogger` | retain debug console; add a separate lightweight numeric/profile trace |

### Layer flow

`UI rail crossing -> navigation logical child -> displayed bundle controller ->
immutable DisplayedDashboardSnapshot -> metrics/LogBox selectors`

`parent scope -> native parent-bundle repository -> DTO decode/projection ->
complete immutable bundle -> bundle cache`

`settle -> CurrentQueryController committed watch -> central promotion rule ->
same visual snapshot or one changed snapshot`

No presentation widget reads a repository, performs projection, or owns an
LRU/workflow.

## Invariants

1. Finite MONTH deck has exactly `daysInMonth` entries; finite YEAR deck has
   exactly 12. Every missing native child is represented by an explicit empty
   `DashboardLogPreviewSnapshot`.
2. Cache lookup distinguishes `absent`, `present-empty`, and `present-data`.
3. Current direction/current parent bundle is pinned. Eviction is whole-bundle
   only; no active child can be evicted independently.
4. An incomplete finite bundle is never visible to rail preview and never
   receives `isComplete=true`.
5. A finite complete deck disables motion-target detail prefetch for its own
   children. SUM remains a bounded-window fallback.
6. Preview and committed snapshots with equal key, revision, metrics and log
   content promote without amount animation, LogBox bind, list replacement,
   scroll mutation or rail/header rebuild.
7. `RailFlingPlan` is a pure function of fixed inputs. Cache/result/row count,
   logger state and rendering cannot change its target.
8. Profile trace is numeric and opt-in. Normal logger string materialization is
   not performed by preview ticks when its panel is closed.

## Profile protocol

Use an Android physical device in profile mode. Capture cold and warm runs for
the controlled empty/9-row, mounted/unmounted, avatar/logger matrix from the
user specification. Keep tracing variants separate from baseline variants;
record UI/raster frame data, p50/p90/p99/worst and raw CSV/trace artifact.
`LOG_PREVIEW_FIRST_PAINT` is a profile-only numeric/timeline event, not proof
from `LOG_PREVIEW_BOUND`.

## Explicit non-goals

- No friction, velocity-band, multiplier, spring, snap, tolerance or
  `maxItemsPerFling` tuning.
- No per-preview SQL/platform read, view-model projection, formatting,
  eviction, scroll operation or root dashboard notification.
- No blanket RepaintBoundary additions; boundaries follow profile evidence.
