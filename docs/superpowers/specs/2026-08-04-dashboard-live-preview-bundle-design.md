# Dashboard live preview bundle design

## Goal

Make the first mother → child open and every distinct ballistic semantic crossing render a complete cached dashboard snapshot within one frame, while leaving the centered rail motion engine and existing metrics calculations unchanged.

## Architecture card

### Scope and sources

- User requirement: the supplied 2026-08-04 live-preview-bundle specification.
- Baseline: commit `561fe92`.
- Existing motion engine: `lib/shared/motion/centered_carousel/`.
- Existing rail adapter: `lib/features/dashboard/widgets/time_refinement_rail.dart`.
- Existing navigation owner: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`.
- Existing visible-state owner: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`.
- Existing LogBox projection: `lib/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart`.
- Native query boundary: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt` and `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`.

### Single source and write path

- Source of truth for visible amount, count and rows: one immutable `DashboardPresentationSnapshot` in `DashboardPresentationStore`.
- Read model for uncommitted child data: bounded `DashboardChildPreviewBundle` owned by the summary/query presentation coordinator.
- Only visible write path: `DashboardPresentationStore.publish`, `setVisibleTarget` and `promote`.
- Committed query write path: `CurrentQueryController` stores detailed results in the same store.
- Preview write path: `DashboardSummaryMetricsController.publishChildPreview` resolves a bundle result and writes one full snapshot to the same store.
- Rail motion never writes query state, starts I/O, or waits for presentation.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Offset, velocity, simulation, crossing | `CenteredCarouselController` | Existing callbacks only; physics is frozen |
| Preview child selection | `DashboardTimeNavigationController` | One synchronous semantic state notification per changed child |
| Child preview bundle | Summary/query presentation coordinator plus bounded bundle cache | Built outside crossing callbacks; revision and direction guarded |
| Visible amount/count/LogBox snapshot | `DashboardPresentationStore` | Atomic full snapshot only |
| Committed query/watch | `CurrentQueryController` | Starts after visible preview publish |
| Paging | `DashboardLogPagingCoordinator` | Committed state only |

### Reuse and centralization decision

The existing centered carousel already emits nearest-index changes during drag and ballistic motion through `_setSelection` → `_emitPreview` → `onPreviewChanged`. The fix extends the dashboard adapter/presentation lane and does not add a second motion engine, debounce, scroll controller or physics implementation.

The existing `DashboardPresentationStore` remains the only visible-state owner. The new bundle is a read cache, not a competing query or widget owner.

### Layer flow

`CenteredCarouselController` → `TimeRefinementRail` → `DashboardTimeNavigationController.previewChildLogicalIndex` → `DashboardSummaryMetricsController` → `DashboardChildPreviewBundle` O(1) lookup → `DashboardPresentationStore` atomic snapshot → `DashboardLogPresentationAdapter` → stable `DashboardLogBoxViewport`.

Native path: `FluviLedgerReadService` batch projection → MethodChannel bundle decoder → summary coordinator cache. There is no native call from a crossing callback.

## Design decisions

1. A bundle contains immutable child results keyed by exact child `LedgerQueryKey`, the parent key, child period, core revision, direction/filter identity through the parent key, and the preview page size.
2. The native bundle read performs one parent-predicate row projection and groups rows into child buckets, capped to the preview page per child; finite month/year domains receive explicit empty snapshots.
3. The first parent result schedules bundle preparation in the prewarm lane. Bundle completion stores every child preview before the rail opens, without activating visible state.
4. Ballistic, drag and tap all converge on `publishChildPreview`. Distinct crossings publish immediately; no trailing debounce or idle/settle check is allowed.
5. A missing/cold bundle is a cache miss diagnostic, never a crossing-time read. The final implementation must keep the existing metrics fallback for compatibility, but production MethodChannel parents must provide the bundle before rail interaction.
6. Settle calls `promote`; if visual content is unchanged, it updates provenance only and emits no visual rebind.

## Error and invalidation rules

- A bundle with a different parent key, child period, direction, filter/refinement key or core revision is rejected.
- A delayed bundle result cannot publish if its request generation or revision is stale.
- A result whose child key does not equal the visible target is cached only and cannot activate.
- Empty child snapshots are real snapshots with `totalMinor=0`, `entryCount=0`, an empty immutable entry list and no placeholder state.

## Evidence required

- RED tests must fail before production implementation.
- Unit tests for bundle immutability, key/revision/direction invalidation and store lookup.
- Dashboard tests for cold first open, 2→3→4→5 ballistic preview, no-settle dependency, tap/fling path parity and settle no-op.
- Boundary and identity tests proving no rail physics/controller/position recreation.
- Full non-golden Flutter tests and `flutter analyze --no-fatal-infos` through Ubuntu proot.
- Logger-off online profile evidence; if a physical profile is unavailable, report that limitation rather than inventing p50/p90/p99 values.
