# Virtual Vertical Geometry Redesign

This is a factual handoff for an engineer who has GitHub access but no prior
conversation context. It supersedes neither Query correctness nor the prior
live-paging recovery; it records why that recovery was physically incomplete.

## Scope, commits, and status

- Starting query head: 324f212e78e0a376415e8e65476d4f481986838a
  (docs: record pre-query vertical paging restoration).
- Starting production parent: 674c95634a3fbbd24b5ce0f8fddc8988ccb6614c
  (fix: restore pre-query live vertical paging contract).
- This implementation: 155f18b62da6fd894f2992567a6d8dd25042f3a9
  (refactor: decouple committed scroll geometry from page readiness).
- The prior report 2026-08-14-pre-query-vertical-paging-restoration.md is an
  INCOMPLETE prior recovery. It correctly restored live same-axis demand, but
  retained a dynamic ready-geometry frontier coupled to Flutter content extent.

Physical acceptance status: NOT VERIFIED BY CI. The normal human APK must be
exercised on device before any claim about smoothness or 60 fps.

## Verified physical failure

On the Expense / All committed scope (2458 entries, pageSize 24), the initial
materialized bank supplied pages 0 through 5, at approximately 9330 px of ready
extent. Each subsequent complete page materially changed the Scrollable world:

    page 6 committed: ready extent 9330 -> 10790
                      maxScrollExtent 8812 -> 10272
    page 7 committed: ready extent 10790 -> 12340
                      maxScrollExtent -> 11822

The supplied physical interaction summaries correlated this exactly:

| Interaction | Pages published | Content dimension changes | goBallistic calls |
| --- | ---: | ---: | ---: |
| 3 | 0 | 0 | 1 |
| 4, 5, 6, 7, 14, 24, 29 | 2 | 2 | 3 |
| 18 | several | 3 | 4 |

The prior recovery already showed reads, preparation and publication while an
interaction was active. Thus suppressing same-axis paging was no longer the
primary defect. The remaining causal chain was:

    complete page commit
      -> cache records another ready geometry page
      -> committed render surface reads contentHeight
      -> SizedBox height / sliver scroll extent grows
      -> ScrollPosition content dimensions change
      -> active ballistic activity re-evaluates via goBallistic

The old source path was CommittedLogViewportCache.contentHeight (an alias of
ready/drawable geometry) through DashboardLogBoxRenderSurface's committed
surfaceHeight binding and SizedBox(height: binding.surfaceHeight). Commit
498f2984b5526bde4694e0f68e8c46ba07a5c0d6 (refactor: virtualize committed
logbox pages) is the inspected historical architecture boundary that made
loaded page geometry the scroll world. The important verified fact is the
still-current source/trace relationship above; no physics defect was
established.

## Flutter framework contract inspected

Installed SDK: Flutter 3.41.4, framework revision ff37bef603, engine
e4b8dca3f1, Dart 3.11.1.

Primary installed source inspected:

- packages/flutter/lib/src/widgets/scroll_position.dart:
  ScrollPosition.applyContentDimensions (lines 642--683) detects changed min/max
  dimensions and calls applyNewDimensions.
- The same file's ScrollPosition.applyNewDimensions (lines 733--737) calls
  activity.applyNewDimensions().
- packages/flutter/lib/src/widgets/scroll_activity.dart:
  BallisticScrollActivity.applyNewDimensions (lines 615--617) calls
  delegate.goBallistic(velocity).
- packages/flutter/lib/src/widgets/scroll_position_with_single_context.dart:
  goBallistic (lines 149--155) asks ScrollPhysics.createBallisticSimulation and
  installs a new ballistic activity if a simulation exists.

Therefore a changed maxScrollExtent is an active-ballistic lifecycle input, not
a harmless renderer detail. The repair makes page resource publication
geometry-neutral instead of changing physics, friction, velocity, or
ScrollPosition identity.

## Replacement model

    Room daily aggregates already read for the prepared index
      -> compact ordered (day, entryCount) seed per directional partition
      -> immutable exact CommittedVerticalGeometryManifest per committed scope
      -> atomic committed frame + manifest handoff
      -> CommittedLogViewportCache:
           immutable full geometry + <= five movable materialized page resources
      -> stable single-surface extent
      -> viewport offset maps through manifest to visible prepared pages

The three concepts now have separate owners and generations:

| Concept | Owner | Mutability / generation |
| --- | --- | --- |
| Full virtual geometry | PreparedDashboardDirectionalPartition seed, then the CommittedVerticalGeometryManifest held by CommittedLogViewportCache | Immutable for an exact committed scope; geometryGeneration changes only on a new scope/manifest. |
| Page row and text resources | CommittedLogViewportCache | Bounded/cache-retained; renderGeneration and resourceChanges advance on commit/eviction. |
| Visible paint window | DashboardLogBoxRenderSurface painter | Derived from viewport offset plus manifest; it never invents geometry or text. |

CommittedVerticalGeometryManifest.compile walks ordered newest-to-oldest daily
counts, splits them into logical 24-row pages, and records every page's row
count, page-local group count, top, extent, and bottom.

    extent = rowCount * rowHeight
           + groupCount * dayHeaderHeight
           + max(groupCount - 1, 0) * dayGroupGap

A day spanning a page boundary is a local group in each page, exactly matching
the grouped payload representation. The compiler validates that seed rows equal
the authoritative committed count, has no transaction payload or TextPainter,
and covers empty, partial-last-page, and exact-boundary cases. It is not an
average-height estimate, placeholder, or fake infinite extent.

## Prepared-index transport and Query safety

The native FluviLedgerReadService already receives daily aggregate rows for the
prepared dashboard index. It now maps those existing rows into compact
FluviPreparedDashboardGeometryDayBucket values; it does not issue a per-page or
full-ledger query. The Dart/Kotlin binary prepared-index codec is version 4 and
validates ordered, direction-owned seeds.

PreparedDashboardDirectionalPartition owns the decoded immutable seed.
Directional partition reuse carries its seed with it, so an Expense Query change
does not rebuild an unchanged Income seed. DashboardCoreController derives the
exact scope manifest from the currently published prepared index and hands it
to ExplicitCommittedPagingController.commitMetadata together with the committed
frame identity. Non-synthetic production input with a nonempty frame and
missing seed fails closed. A deliberately marked synthetic test fixture receives
a deterministic immutable stand-in only so old sparse fixtures do not
masquerade as the native production transport.

This retains CurrentQueryController, QueryComposerController, directional
applied Query state, candidate staging, atomic Apply, PreparedDashboardIndex
and PreparedDashboardDirectionalPartition ownership, one serial keyset owner,
one committed cache, pinned root, five movable pages, 2 MiB bound, compact
cursor anchors, signed reverse gate, and fail-closed stale/superseded responses.
No Query/domain reversion, second cache, second cursor, alternate physics, or
ScrollController/ScrollPosition replacement was introduced.

## Geometry-neutral cache, surface, and painter

On seed, the cache installs a complete manifest and increments
geometryGeneration once. Its contentHeight, pageTopForOrdinal, and
pageOrdinalForOffset all delegate to that manifest. An arriving page is
validated against its expected ordinal, count, local grouping, query/revision,
and generation before it can publish. A mismatch logs
VERTICAL_VIRTUAL_GEOMETRY_MISMATCH and fails closed; it never changes the
manifest to fit a payload.

A successful page only changes bounded resources and invokes resourceChanges.
The render surface listens through CustomPainter.repaint; normal page commit
does not invoke its structural setState, alter committed SizedBox height, or
change sliver extent. The painter performs an O(log pages) manifest lookup for
the visible offset and paints only intersecting retained prepared pages. A
missing virtual resource logs VERTICAL_VIRTUAL_PAGE_MISS; it does not paint
stale rows or shrink the world. No TextPainter is created in build, layout, or
paint.

The page preparation path is privately resumable. It measures actual contiguous
UI work through an injectable clock/probe, yields only between private
row/header preparation slices, takes no terminal yield, and atomically publishes
only a complete page. Structural/query supersession disposes private text
resources. It uses no SchedulerBinding.scheduleTask continuation for geometry;
active committed resource work remains ahead of rail/Query speculation while
rail-critical ownership itself is preserved.

## RED -> GREEN evidence

The original RED coverage required APIs that did not exist at 324f212:

- an exact manifest compiler from daily counts;
- page commits that leave contentHeight and geometryGeneration unchanged;
- a committed surface whose height is full-scope geometry rather than current
  ready content; and
- a ballistic probe with no readiness-induced content-dimension/goBallistic
  restart.

The old stable-surface expectation observed a ready-frontier height of 544 in
place of the exact synthetic virtual extent of 75, demonstrating the former
coupling rather than using a timing threshold. New or changed tests prove:

1. Exact rows/groups/tops/extents for spanning days, boundaries, partial final
   pages, and empty scopes.
2. Page commit/eviction changes resource generation but not virtual extent,
   page tops, or geometry generation.
3. Complete-only atomic page publication, mismatch rejection, root safety,
   five-page/2 MiB retention, and signed reverse gating.
4. Stable surface and ballistic metrics across commits.
5. Resumable sliced text preparation, terminal publication, and structural
   disposal.
6. Binary seed round-trip/version validation, no-new-SQL count assertion,
   directional seed reuse, Query atomicity, and synthetic fixture fail-closed
   distinction.
7. Controller, ScrollPosition, and physics identity continuity.

Fresh local verification in Ubuntu proot:

    focused virtual geometry/cache/planner/surface/viewport/paging/index suite
      PASS (67)
    ./scripts/test-fluvi-fast.sh
      PASS (176)
    ./scripts/verify-fluvi-boundaries.sh
      PASS
    flutter analyze
      PASS (0 issues)
    git diff --check
      PASS

The local Android ARM64/proot attempt at :fluvi-core:testDebugUnitTest was
blocked before Kotlin test execution because the local AAPT2 daemon cannot
start. The remote Fluvi Verification run 31828136833 for 155f18b6 completed
the clean Room core and native dashboard bridge jobs successfully. Its normal
human-device APK job also completed successfully. The downloaded artifact is:

    /storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_155f18b.apk
    SHA-256 10ff1e7481894fab2f33ec9d9c99b0617f4367ebe7923418e0e840c558903d24

## Diagnostics and physical acceptance plan

Low-frequency diagnostics now include VERTICAL_VIRTUAL_GEOMETRY_ACTIVATED,
VERTICAL_VIRTUAL_GEOMETRY_MISMATCH, VERTICAL_VIRTUAL_PAGE_MISS, and interaction
start/end virtual extent, max-scroll-extent, geometry/resource generations,
page-preparation slice statistics, dimension changes, and goBallistic count.
They do not log per frame or per row.

For a human Expense / All long forward fling, pages may publish during the same
ballistic interaction, but page publication must satisfy:

    virtualExtentAtStart == virtualExtentAtEnd
    maxScrollExtentAtStart == maxScrollExtentAtEnd
    geometryGenerationAtStart == geometryGenerationAtEnd
    page-induced contentDimensionChangeCount == 0

An actual new pointer gesture may interrupt a ballistic activity. It is not a
page-induced restart. Required miss counters remain zero:
RAIL_CRITICAL_CACHE_MISS, TEXT_LAYOUT_MISS, VERTICAL_CACHE_MISS,
VERTICAL_ROOT_NOT_DRAWABLE, VERTICAL_VIRTUAL_PAGE_MISS, and
VERTICAL_VIRTUAL_GEOMETRY_MISMATCH.

The observed zero-velocity chained-gesture issue is deliberately not modified
here. It remains a separate physical acceptance item unless a human test proves
the geometry repair also removed it.
