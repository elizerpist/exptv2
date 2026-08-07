# Dashboard readiness deadlock and cache-contract repair

## Scope and sources

Source: the user's “FLUVI DASHBOARD — CÉLZOTT READINESS DEADLOCK + CACHE
CONTRACT JAVÍTÁS” instruction and the physical-device diagnostic JSON supplied
in the same conversation.

Existing implementation:

- `lib/features/dashboard/application/dashboard_interaction_readiness.dart`
- `lib/app/shell/fluvi_app_shell.dart`
- `lib/features/dashboard/presentation/core_dashboard.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- `lib/core/assets/prepared_vector_asset_atlas.dart`

The existing bounded CustomPaint LogBox, prepared payloads, and rail motion
system stay in place. This is a startup lifecycle and render-resource-contract
repair only; it adds no golden test and changes no rail/controller/position or
physics source.

## Proven current state flow

```text
DashboardInteractionReadiness.start
  -> indexBuilding: DashboardCoreController.bootstrap
  -> presentationPreparing: PreparedVectorAssetAtlas.prepare + DPR raster prep
  -> renderCriticalWarmup: mount AbsorbPointer(CoreDashboard)
       -> DashboardLogBoxRenderSurface.initState: emits four STARTED events
       -> didChangeDependencies: independently reads global atlas with View DPR
          -> StateError on cache lookup (physical report has categoryRaster miss)
          -> render surface build never schedules its post-frame callback
          -> text layouts never start and no COMPLETED events are emitted
  -> DashboardInteractionReadiness awaits _renderSurfacePresented.future
  -> ready (unreachable)
```

The direct call graph proves a circular lifecycle dependency. The readiness
owner waits for `markLogBoxFramePresented`; the surface emits that only after a
post-frame callback and text-cache warmup. The only error bridge is inside that
later warmup, so the earlier atlas-lookup exception is neither reported to
readiness nor converted to `failed`.

The diagnostic proves the failing atlas lookup is a DPR key mismatch, not an
unprepared atlas: `categoryRaster` has a preceding COMPLETE event from
`PreparedVectorAssetAtlas.instance.prepareLogBoxRasters`, while
`logBoxRastersFor(View.of(context).devicePixelRatio)` immediately records the
only cache miss. `logBoxRastersFor` throws only when no set is published or
when its DPR does not match; the preceding completion excludes the first
condition. The current code uses the same static atlas instance, but it
computes the key twice in different owners and does not hand the prepared set
to the renderer.

## Architecture card

### Single source and write path

- Readiness source of truth: `DashboardInteractionReadiness`.
- Render-resource source of truth: `PreparedVectorAssetAtlas.instance`.
- Only startup write path: `FluviAppShell` prepares the atlas once, captures
  the exact immutable `PreparedLogBoxRasterSet`, and supplies that same set to
  the dashboard render surface through the readiness resource bundle.
- Failure owner: `DashboardInteractionReadiness`; any deterministic resource,
  attach, layout, or text-cache failure transitions it to `failed` and emits a
  structured readiness failure event.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Prepared visible frame | `DashboardInteractionReadiness` | bootstrap attempt | published only after atomic-frame validation |
| Raster set and DPR | `DashboardInteractionReadiness` resource bundle | bootstrap attempt / mounted surface | exact immutable instance passed to the surface |
| Render-critical task state | `DashboardInteractionReadiness` | bootstrap attempt | explicit `pending` → `running` → `completed` or `failed` |
| Exact-width text layouts | `DashboardLogBoxRenderSurface` / cache | stable surface state | starts only after normal layout exposes exact constraints |
| Rail input gate | `FluviAppShell` | dashboard session | open only when readiness is `ready` |

### Cache-contract audit

The cache is one static-catalog raster set, not a per-row cache. Category,
asset, icon, tint, dimensions, render mode and direction are fixed inputs of
the set: the full `CategoryColorCatalog` and `CategoryIconCatalog` are
rasterized together with the fixed light Fluvi token colors, 34 logical-pixel
badge, 18 logical-pixel icon and 128 logical-pixel group surface. There is no
filter, frame revision, presentation generation, scale other than DPR, or
direction-dependent raster selection. Its effective key is therefore the
single device-pixel ratio and its store is
`PreparedVectorAssetAtlas.instance`.

The bug was not eviction: no second preparation or disposal occurs between
the recorded warmup completion and the miss. The repair removes the renderer's
second key calculation and runtime cache lookup. It consumes the exact
immutable set produced by the warmup, so warmup/runtime key parity and cache
instance parity are identity properties rather than best-effort comparisons.

### New terminating state flow

```text
databasePending
  -> indexBuilding: atomic PreparedDashboardIndex/current frame
  -> presentationPreparing: atlas and exact current-DPR raster set
  -> renderCriticalWarmup:
       surface attached -> exact-width normal layout -> text layouts prepared
       (each explicit task has pending/running/completed/failed state)
  -> ready
```

Only deterministic application-side work belongs to the barrier. The first
normal layout is the point where exact surface width becomes available. Paint,
compositor/layer, raster-thread, semantics and user-interaction callbacks do
not gate readiness and are not registered as pending warmup tasks. A surface
or text warmup exception is delivered to readiness immediately and produces
the failure UI instead of an infinite spinner.

### Layer flow

`FluviAppShell` (composition) → `DashboardInteractionReadiness` (lifecycle
and task state) → immutable render-resource bundle → `CoreDashboard` →
`DashboardLogBoxViewport` → stable `DashboardLogBoxRenderSurface`.

The UI reports attach/layout/text task completion; it performs no storage,
network, import or domain workflow. The existing controller remains the sole
owner of frame data and diagnostics.

### Verification

- Unit: deterministic phase/task transitions, delayed required task, failure
  propagation, timeline pairing and resource identity.
- Widget: cold shell reaches `ready`, blocks input before it, allows it after
  it, and has no bootstrap current-viewport cache miss.
- Boundary: surface contains no global raster-cache lookup; frozen rail files
  have no diff.
- Performance: existing navigation crossing suite remains zero I/O; no golden
  test is added.

