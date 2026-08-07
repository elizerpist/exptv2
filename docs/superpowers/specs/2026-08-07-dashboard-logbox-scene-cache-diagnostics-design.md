# Dashboard LogBox scene cache and profile diagnostics design

## Scope and immutable baseline

This design implements the user-approved `FLUVI DASHBOARD — dab4347 PERFORMANCE MILESTONE` brief. The baseline is `dab434747b6722c7f6362ef934ab52a4c2a4749f`, retained locally as `milestone/dashboard-dab4347-performance` and annotated tag `dab4347-logbox-performance`.

The rail motion kernel, rail widget, centered-carousel engine/controller/physics, prepared index, presentation controller, and visible-frame store are performance-frozen. This work must not modify them. Golden tests are excluded.

## Evidence and root cause

The local physical screenshot `Screenshot_20260807-154337.png` shows icon and badge raster rows with all text absent. `Screenshot_20260807-154341.png` is a nearby populated scope where the same row surface has text.

The source chain is deterministic:

1. `DashboardLogBoxRenderSurface._announceSurfaceLaidOut` sets `_layoutWarmupReported` on the first normal layout and starts the only call to `_prepareCriticalTextLayouts`.
2. That call invokes `DashboardLogBoxTextLayoutCache.preparePinned` with `DashboardCoreController.renderCriticalLogBoxPayloads`.
3. The latter derives its payload set from the temporal anchor at that instant (SUM, year, and month parent catalogs around that anchor, both directions).
4. Later parent navigation changes the anchor but never starts another `preparePinned` call or rotates the pin set.
5. `_DashboardLogBoxSurfacePainter._paintItem` paints the badge and icon before querying `textLayouts.rowFor(row)`. A null result records a cache miss and returns without painting text.

Therefore startup at 2026-07 followed by navigation to 2026-02 and selection of a populated day can select a frame absent from the initial pin set. It is a cache-coverage lifecycle defect, not a rail-motion or raster defect.

The profile console defect is separate and also source-proven: the shell shows the floating button for `kDebugMode || FLUVI_PHYSICAL_RAIL_DIAGNOSTICS`, while the logger, logger native ingestion, bridge stream, and shell subscription all require `kDebugMode`. In profile `kDebugMode` is false, so the visible console has no live producer. The report-copy action also performs an unhandled clipboard call with no readable fallback.

## Ownership and state flow

`DashboardCoreController` remains the application coordinator. It derives an immutable `DashboardLogBoxSceneWindow` from the installed prepared index and a candidate temporal anchor. The window contains only bounded preview payloads that can be reached immediately: current parent catalog, adjacent parents, the current plane transition targets, and both directions.

`DashboardLogBoxPreparedSceneCache` is the sole presentation-side owner of width-specific paragraphs and scene resources. A `PreparedLogBoxScene` is keyed by viewport id, query/content identity, exact surface width, and text layout generation; it retains only the preview rows, headers, raster handles, geometry inputs, and semantics metadata for that frame. It never creates an offscreen widget or a per-transaction render object.

```
bootstrap -> index published -> initial scene window prepared after normal layout -> readiness ready

parent intent -> input gate -> target scene window prepare -> complete scene bank -> presentation commit -> scene window activated -> input enabled

rail child crossing -> prepared frame -> prepared scene -> O(1) row layout lookup -> paint
```

Plane and direction targets are already members of the active window; parent rotation prepares the new edge before committing it. The old visible scene is retained until the atomic switch. The active retained cache is capped at 8,192 unique row layouts and 384 scenes. A separately reported, bounded staging budget of twice that maximum exists only during a structural rotation so that a failed preparation can preserve the old complete scene bank; it is not a database-sized retained cache.

The renderer never calls `TextPainter.layout`, formats data, decodes assets, or reads data during a rail crossing. A selected scene must exist before any part of a row is drawn, making avatar/text presentation atomic. A scene/text miss is a diagnostic invariant violation, never normal control flow.

## Diagnostics policy

One compile-time policy is authoritative:

```
kFluviOnscreenDiagnosticsEnabled = kDebugMode || bool.fromEnvironment('FLUVI_ONSCREEN_DIAGNOSTICS')
```

It controls the floating trigger, Dart logger, native event stream, physical-report availability, and console. It is false in normal release builds. The console uses the existing bounded ring and adds live status plus readable Logs/Physical report sections. Clipboard and provider failures are shown rather than swallowed.

## Validation strategy

Unit/widget tests first prove the pre-fix lifecycle gap, scene-window rotation, atomic text availability, cache key/instance parity, no crossing work, and profile diagnostic policy/UX. Deterministic 700/10k/50k/100k fixtures measure index construction separately from rail interaction and enforce configured scene/text bounds. Flutter tests and analysis run in Ubuntu/proot. The profile APK is built in GitHub Actions with the explicit diagnostic defines, downloaded to `/storage/emulated/0/Download/fluvi`, hashed, and zip-validated. Physical smoothness remains a device acceptance step and is not inferred from an emulator.
