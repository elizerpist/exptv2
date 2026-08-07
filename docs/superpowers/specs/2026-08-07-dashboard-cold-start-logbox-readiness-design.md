# Dashboard cold-start LogBox readiness design

Date: 2026-08-07

Status: approved by the user's prescriptive final render-isolation
specification.

Execution: one agent, inline; no delegation.

## Job to be done

Keep the immutable prepared-data runtime and byte-identical rail mechanics,
then make the first real fling use the same complete render runtime as the
tenth fling. The spinner must represent interaction readiness rather than only
database/index readiness, and a child change must update one bounded LogBox
render surface instead of constructing an entry-density-dependent widget,
render-object, semantics and layer tree.

## Architecture card

| Concern | Decision |
|---|---|
| Feature boundary | Existing dashboard runtime, presentation, LogBox and app-shell modules. No new data runtime, repository, query owner or motion engine. |
| Canonical lifecycle owner | Replace `DashboardBootstrapController` with one `DashboardInteractionReadiness` owner. |
| Lifecycle state | `databasePending → indexBuilding → presentationPreparing → renderCriticalWarmup → ready`, with fail/retry metadata. |
| Data owner | Existing `DashboardDataRuntime` and immutable `PreparedDashboardIndex` remain canonical and unchanged in navigation semantics. |
| Motion owner | Existing `DashboardMotionKernel`, shared `CenteredCarouselController`, `ScrollPosition` and physics remain byte-identical. |
| Render owner | One stable `DashboardLogBoxViewport` owns one vertical controller and one bounded custom render surface. |
| Prepared payload | Existing immutable `PreparedLogViewportPayload` is extended only with bounded render primitives/geometry required by the surface; no widget cache. |
| Resource owner | Existing `PreparedVectorAssetAtlas` remains the sole category/vector resource owner and gains bounded device-scale LogBox raster resources rather than a sibling cache. |
| Interaction gate | Dashboard is mounted for its normal first layout during `renderCriticalWarmup`, but rail/Summary/temporal intents are disabled until the visible surface reports its first presented frame. |
| Cache policy | Current plane, current parent and adjacent parent bounded preview resources are pinned; all misses are prepared before `ready`. A post-ready rail-critical miss is a debug/test failure. |
| Failure semantics | Data/resource/render readiness failure retains the spinner/failure surface and never exposes a partially interactive dashboard. Retry advances the same owner. |
| Diagnostics | Existing bounded flight recorder is reused for motion; focused readiness/render diagnostics add first-use/cache/render/presented-frame records and physical export. |

## Proven pre-change event graph

```text
FluviAppShell.initState
  -> PreparedVectorAssetAtlas.prepare
       -> vector byte decode into ui.Picture
       -> gradient object table
  -> DashboardCoreController.bootstrap
       -> native index build/decode/projection
       -> immutable PreparedDashboardIndex publish
       -> first atomic DashboardVisibleFrame
  -> DashboardBootstrapController.ready
  -> spinner removed
  -> CoreDashboard mounted for the first time
       -> LogBox State/ScrollController/viewport/sliver created
       -> initial build/layout/paint/semantics/layers
  -> first populated child crossing
       -> prepared payload pointer swap
       -> SliverFillRemaining ↔ SliverList structure switch
       -> N transaction row Element/RenderObject/Semantics/RepaintBoundary trees
       -> N text layouts + gradient badge paints
       -> N tint saveLayers around decoded vector pictures
       -> group shadow/clip paint
       -> first raster/cache/allocation/GC work overlaps pointer/ballistic frames
```

`INDEX_BUILD_READY` therefore proves data readiness but not interaction/render
readiness. The old scripted fixture also mounted, settled, opened, reset and
pumped the dashboard before measuring its “first” fling and supplied a fixed
release velocity. It could prove physics determinism, but not cold real-pointer
scheduling parity.

## Target readiness flow

```text
databasePending
  -> indexBuilding
  -> presentationPreparing
       -> validate immutable current/adjacent bounded payload references
       -> build indexed category/partner/asset resource tables
       -> prepare bounded category raster resources
  -> renderCriticalWarmup
       -> mount the one normal current CoreDashboard surface
       -> interactions disabled; spinner remains above it
       -> stable LogBox render object performs normal first layout/paint
       -> frame-presented acknowledgement
  -> ready
       -> spinner removed
       -> interaction gate opens
```

This is not offscreen widget pre-rendering. Exactly one real current dashboard
surface is mounted in its final geometry. No alternate child page, hidden
LogBox, `IndexedStack` or complete frame catalog is rendered.

## Stable bounded LogBox surface

The current `SliverFillRemaining`/`SliverList` switch and transaction-row
widget tree are replaced by one stable surface with a bounded slot capacity.
The surface owns reusable text painters and paints only viewport-visible slots
plus a small overscan from the already prepared immutable payload.

```text
semantic child
  -> O(1) PreparedPresentationFrame reference
  -> PreparedLogViewportPayload reference
  -> stable LogBox render object.updatePayload(pointer)
  -> binary-search first visible prepared slot
  -> paint bounded visible slots
```

Total `entryCount` does not select the number of widget children, render
objects, semantics nodes, repaint layers or asset decodes. Empty and populated
payloads use the same render-object identity. The vertical scroll extent may
reflect the bounded loaded page and explicit committed paging, but it cannot
alter rail constraints or scroll metrics.

The renderer preserves:

- the floating count header and existing card geometry;
- row tap semantics and labels;
- lazy committed near-end paging;
- stable transaction identities;
- group header/gap/card visuals;
- bounded overscan and current scroll retention rules.

## Resource preparation

Vector decode alone is insufficient because the first paint still rasterizes
glyphs/pictures/gradients and the existing tinted painter uses `saveLayer` for
every icon. The canonical atlas prepares a bounded matrix of LogBox category
badge resources at the current device pixel ratio:

- one white category-icon raster per icon handle and supported LogBox scale;
- one badge-background raster per gradient handle and supported scale;
- no per-row tint `saveLayer` or vector decode during interaction.

This is bounded by catalog size, not transaction count. Device-scale resource
preparation occurs before the readiness owner can open interaction. General
brand/direction vector rendering remains on the existing prepared-picture path.

Reusable text layout objects live on the stable renderer. Payload changes
still require normal bounded text layout/paint for the visible slots; they may
not allocate a new render tree or initialize a cache/formatter/asset subsystem.

## Cache contract and memory budget

| Cache | Owner | Key | Lifetime | Bound/pinning | Interaction miss |
|---|---|---|---|---|---|
| prepared data | `DashboardDataRuntime` | revision/filter/direction | revision generation | existing immutable index | forbidden during navigation |
| prepared viewport payload | prepared index | query key/revision | index generation | current/adjacent frames; preview row cap | hard diagnostic after ready |
| category raster | vector atlas | icon/gradient handle + DPR + logical size | app/device-scale generation | catalog cardinality only | hard diagnostic after ready |
| renderer layout | stable LogBox render object | payload ID + width/text scale | mounted surface | current payload only | bounded normal visible-row layout |
| layer/surface | Flutter render pipeline | stable render object/RepaintBoundary | dashboard mount | one current LogBox surface | no structural creation after ready |

The implementation records estimated bytes for prepared row payloads and
category rasters and reports Flutter/native/graphics process memory from the
profile environment where available. No transaction widgets are prebuilt and
no cache grows with the complete database without a page/preview cap.

## Physical diagnostic contract

Motion callbacks continue to write only typed values into bounded memory.
After 10–20 gestures a diagnostic export aggregates:

- first ten gesture sample-gap/velocity/endpoint timelines;
- UI/raster `FrameTiming` summaries;
- LogBox selection/build/layout/paint/presented durations;
- row/render/semantics/layer create/update counts;
- first-use and rail-critical cache violations;
- allocation/GC fields where the runtime exposes them.

The export is never emitted to stdout during motion. Emulator/CI results remain
regression gates; only the new physical report can close the physical-device
acceptance row.

## Proof order

1. Preserve milestone hashes and baseline verification.
2. Add RED ownership/readiness/render-surface/first-use tests.
3. Replace the lifecycle owner and prove the spinner cannot end early.
4. Replace the density-dependent LogBox structure with the stable bounded
   renderer while preserving visuals, semantics and paging.
5. Prepare bounded canonical raster resources before readiness.
6. Add cold-first and device-export diagnostics without modifying physics.
7. Run non-golden tests, exact hash gates, profile workflow and physical export.

Release gate:
`docs/superpowers/checklists/2026-08-07-dashboard-cold-start-logbox-readiness.md`.
