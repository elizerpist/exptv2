# Dashboard cold-start LogBox readiness root-cause audit

Date: 2026-08-07

## Baseline

| Item | Value |
|---|---|
| milestone | `fb6aaec4573fd8728bfc5e1f14ca062ec74fd0fe` |
| previous final | `9c066f3ecbfa6d64e2a264e11d4878cb84ec7ba3` |
| physical comparator | `c35c680276385deda5a7fad6e116c486634bd4eb` |
| milestone branch | `milestone/best-runtime-before-cold-start-logbox-render-isolation` |
| work branch | `refactor/dashboard-cold-start-logbox-readiness` |
| baseline tests | 262/262 PASS in Ubuntu proot |
| baseline analyze | `No issues found` in Ubuntu proot |

### Frozen hashes

| Ownership | File | SHA-256 |
|---|---|---|
| rail widget | `lib/features/dashboard/widgets/time_refinement_rail.dart` | `685f5871c53f488ce05a00be19699d9d7134d14849853f87b57c38bbce9478e7` |
| rail presentation adapter | `lib/features/dashboard/presentation/widgets/time_refinement_rail.dart` | `5cb67e0aaf92b44430534d28da68832daa9ff52bd95989e0262e60a5a15feaa9` |
| centered carousel | `lib/shared/motion/centered_carousel/centered_carousel.dart` | `d629b7ba139e134d91091b36cb17bff6bf37c70621556ff2fb8d799d0fff621` |
| controller/position owner | `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | `a7268aa7294adf2a85d1254526de90e06c7595eaae4b39b398c0296173b3ee0c` |
| physics | `lib/shared/motion/centered_carousel/centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| prepared index | `lib/features/dashboard/runtime/domain/prepared_dashboard_index.dart` | `470ff2f595d57460abc453eca04480f4cc3f02a76a20d24a9829911463ad27e5` |
| prepared frame | `lib/features/dashboard/runtime/domain/prepared_presentation_frame.dart` | `240a1571da37bc6810b2985c169b60e9f6f1730355d1ecaf80a0a40119733cfb` |
| LogBox viewport | `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart` | `cb31b8f24023f03a1979f2cff62307a351efe01817b71b1ad1eaa22fae0417ac` |
| LogBox VM | `lib/features/dashboard/logbox/application/dashboard_log_view_models.dart` | `679317ae1bd044556658648043cfeff0ae26cc5d46e0707f4e23e720a97ed1d1` |
| LogBox state | `lib/features/dashboard/logbox/application/dashboard_log_viewport_state.dart` | `3ea39f1f74cde215c673e1d1238de52208d42708a51d17fa6cb8aaaf8bf33a62` |
| bootstrap owner | `lib/features/dashboard/application/dashboard_bootstrap_controller.dart` | `076d28a06709883085a9ded6b542bfd5603a0e34706072abd8ad2243e0380ef9` |
| core controller | `lib/features/dashboard/application/dashboard_core_controller.dart` | `5cb3aa841196ff3c7abf6a033c599e4055d41cc0370124101d9a680ae1759a02` |
| data runtime | `lib/features/dashboard/runtime/application/dashboard_data_runtime.dart` | `13041dc43a95306c147a297a257a34911c9a70e643ebe9679eb73752a794a691` |
| shell | `lib/app/shell/fluvi_app_shell.dart` | `981a20cd59235195a5684c7dd0f31fe451e5e21d413c5be74409c44cc4cdfa12` |
| vector atlas | `lib/core/assets/prepared_vector_asset_atlas.dart` | `1fed323ff2e9edfc31664ab19bd239f8e7728b6d7e0cccabdf285ebc335c804b` |

Flutter framework `ScrollPosition` is used directly; the application has no
custom position implementation to hash.

## What the spinner currently does

At the milestone, `_FluviAppShellState` created
`DashboardBootstrapController` with exactly two
operations:

1. `PreparedVectorAssetAtlas.instance.prepare()` decodes the vector bytes to
   process-retained `ui.Picture` instances and constructs gradient objects.
2. `DashboardCoreController.bootstrap()` resolves the database revision,
   builds/decodes/projects one immutable `PreparedDashboardIndex`, publishes
   the first atomic `DashboardVisibleFrame`, and validates its key/revision
   coherence.

Immediately after those operations, `DashboardBootstrapController` changes to
`ready`. Only then does `FluviAppShell.build` create `CoreDashboard`. The spinner
therefore cannot cover any `CoreDashboard`, LogBox, layout, paint, raster,
semantics or layer first-use work.

## What remains lazy after the spinner

The first Dashboard mount or populated frame must still create/use:

- `DashboardLogBoxViewport` State and vertical `ScrollController` attachment;
- `CustomScrollView`, viewport and its initial sliver/render hierarchy;
- a structural `SliverFillRemaining` → `SliverList.builder` replacement when
  the frame changes from empty to populated;
- one `DashboardLogRow` widget/Element/RenderObject/Semantics/InkWell/Material
  subtree per built prepared row;
- automatic per-row repaint boundaries from the sliver delegate;
- several text layouts/glyph rasters per row;
- category badge gradient shader/background paint;
- the first draw/raster of each decoded vector icon;
- a tinted vector `saveLayer` per icon paint;
- group rounded-card shadow/blur/clip paint and layers;
- the first semantics and hit-test structures;
- associated allocation and possible GC/raster cache population.

The vector atlas is therefore a **decode cache**, not a ready-to-paint LogBox
resource cache.

## Current LogBox density coupling

The payload is bounded to the prepared preview page, but the renderer still
turns every built row into a structurally heavy tree. A different QueryKey uses
different transaction keys, so row subtrees are destroyed/created across child
crossings. Empty and populated frames also use different sliver types.

At `c35c680` a 24-row payload expanded to 71 sliver children because group
headers and gaps were separate children. Current code improves that to 24 row
children and binary-searches group paint data, but the common heavy row,
semantics, layer, text, gradient and tinted-vector path remains. The physical
problem on both revisions therefore predates the latest temporal-navigation
change.

Year/month is worse because a monthly child commonly exposes more preview rows
and more day groups than a daily child. That increases:

- row widget/render/semantics/layer creation;
- text/glyph layout/raster work;
- category icon tint saveLayers;
- distinct group card shadows and blur regions;
- allocation pressure and dirty LogBox pixels.

This is presentation/render density coupling, not data acquisition latency and
not an input to the rail physics model.

## Pre-fix timing evidence and missing proof

The deterministic density trace proves exact release velocity, ballistic input
and endpoint parity when velocity is supplied by the test. It also shows the
post-notify frame cost is not the previously reported constant ~10 µs pointer
swap:

- a 9-row month/day first apply measured `3634 µs`, tenth `458 µs`;
- an empty year/month trace reached `12998 µs` p99 apply;
- a populated month/day run measured first `4038 µs`, tenth `615 µs`;
- a 24-row monthly payload built 40 row widgets across its measured runs.

These debug/widget timings are causal source evidence, not final profile or
physical proof. The prior profile harness performed `pumpAndSettle`, opened and
reset the rail, pumped multiple frames and then applied a deterministic release
velocity before recording its “first” fling. It consequently warmed exactly
the surface/resources under investigation and could not observe pointer sample
loss or delayed release processing.

## Root cause

The earliest common root cause is the readiness/render ownership mismatch:

> The application declares the dashboard ready when data and decoded vector
> pictures are ready, before the one visible LogBox render surface and its
> density-dependent row/text/vector/shadow/semantics/layer resources have been
> created and painted. The first populated child interactions therefore act as
> implicit render/cache warmers. Their work scales with visible LogBox payload
> density and shares UI/raster frames with real pointer sampling and ballistic
> handoff.

The fix must change that ownership boundary and the density-dependent render
surface. Moving only the pointer swap, warming a synthetic gesture, delaying
content, hiding LogBox or tuning physics cannot remove the cause.

## Cache inventory before the change

| Cache | Owner | Warmup | Bound | Interaction-time behavior |
|---|---|---|---|---|
| immutable dashboard index | data runtime | spinner/bootstrap | revision window | O(1) frame lookup; no motion I/O |
| bounded preview payload | prepared index | index build | 24 preview rows/frame | reference lookup is ready; widget/render projection is not |
| vector picture decode | vector atlas | spinner/bootstrap | 53 unique pictures | first raster/tint still occurs after spinner |
| gradient objects | vector atlas | spinner/bootstrap | category catalog | first shader/background raster still occurs after spinner |
| text/glyph/layout | Flutter engine/render tree | first row paint | engine-managed | first populated interactions warm it |
| sliver/row/render tree | LogBox widget | first mount/frame | current built rows | rebuilt with QueryKey/density changes |
| raster/layers | Flutter engine | first LogBox paint | engine-managed | first row/group/icon surface warms it |

## Implemented ownership change

The old `DashboardBootstrapController` was removed. One
`DashboardInteractionReadiness` now owns this ordered barrier:

```text
databasePending
  -> indexBuilding
  -> presentationPreparing
       -> immutable viewport payload available
       -> vector pictures decoded
       -> DPR-specific badge/icon/group-card rasters prepared
  -> renderCriticalWarmup
       -> mount the one real CoreDashboard in final geometry
       -> AbsorbPointer remains closed and spinner remains visible
       -> stable LogBox surface builds, lays out and paints once
       -> exact viewportId presented acknowledgement
  -> ready
       -> mark post-ready diagnostics active
       -> remove spinner and open interaction
```

The acknowledgement is rejected when it is premature, stale, duplicated or
belongs to a different viewport payload. Retry uses the same lifecycle owner.
No hidden/offstage dashboard, `IndexedStack` or offscreen child widget is
created.

## Implemented stable LogBox path

The structural empty/populated switch, `SliverList` and one
`DashboardLogRow`/`Material`/`InkWell`/repaint-boundary subtree per entry were
removed from the horizontal-preview renderer. The retained viewport contains:

- one State and vertical `ScrollController`;
- one `CustomScrollView` and stable two-sliver hierarchy;
- one `RenderCustomPaint` surface;
- one width-specific, bounded cache of already-laid-out row/header paragraphs;
- binary-search selection of the first visible prepared row/group;
- at most the prepared 24-row page, with only the visible rows plus 90 logical
  pixels of overscan painted;
- at most 24 bounded custom semantics nodes;
- stable hit testing against the prepared row geometry.

Badge gradients, white category icons and the group shadow/card surface are
rasterized once at the active DPR before interaction. They occupy exactly
three GPU images: one bounded badge texture atlas, one bounded icon texture
atlas and one nine-slice group surface. A sprite lookup returns a retained
image/source-rect pair, so row painting performs neither a new image allocation
nor one `Picture.toImage` readback per category. The hot paint path uses
`drawImageRect` and `drawImageNine`; it performs no vector decode, gradient
construction, blur/shadow construction or tint `saveLayer`.

The first exact-commit online profile exposed an important readiness-build
fault before any gesture was measured: the initial implementation created one
badge image and one icon image per category, sequentially. On the CI software
renderer that meant more than one hundred `Picture.toImage` operations and the
Dashboard correctly remained non-interactive past the 15-second test barrier.
The fix was not a longer timeout. The cache was changed to the three bounded
atlas surfaces above; unit tests enforce that surface count.

The total period `entryCount` is metadata. A month with 94 or 100,000 total
entries still supplies no more than the bounded 24 preview rows to the
horizontal path. Explicit committed near-end vertical paging remains the only
way to append detail rows.

## Cache inventory after the change

| Cache | Owner | Key | Lifetime / eviction | Bound / pinning | READY-time miss behavior |
|---|---|---|---|---|---|
| immutable dashboard index | `DashboardDataRuntime` | revision + filter/refinement/direction | current revision generation; latest-wins replacement | all prepared summary frames, preview capped per frame | navigation never acquires data |
| prepared LogBox payload | `PreparedDashboardIndex` | QueryKey + revision + viewport ID | index generation | 24 rows/frame; current index retains current/adjacent lookup data | missing payload is a hard invariant failure |
| vector pictures | `PreparedVectorAssetAtlas` | canonical asset handle | process lifetime | 53 unique decoded pictures | unavailable atlas cannot open readiness |
| DPR LogBox rasters | `PreparedVectorAssetAtlas` | category handle + DPR + fixed logical size | one active DPR generation; previous generation disposed | exactly three images: badge atlas, icon atlas, nine-slice group surface | `RAIL_CRITICAL_CACHE_MISS` hard diagnostic |
| text layout objects | stable LogBox State | row `entryId` + precomputed `textLayoutId` + surface width | viewport State lifetime; removed pin entries and the complete State are disposed | current/adjacent SUM/year/month payloads, hard cap 8,192 unique rows; four paragraphs/row plus unique day headers | layout is completed behind the readiness spinner; a miss after READY is a hard diagnostic/profile failure |
| renderer/layer surface | Flutter render tree | stable widget/render identity | one dashboard mount | one LogBox RepaintBoundary and one CustomPaint | recreation after readiness is a first-use violation |
| diagnostic rings | core controller | chronological slot | dashboard session; overwrite-oldest | 2,048 motion + 2,048 render events in physical mode | never allocates an unbounded log or writes motion stdout |

The raster cache replaces its previous DPR generation instead of growing. The
profile report exports prepared-index bytes, raster bytes, process RSS and ring
capacities; Flutter/native/graphics subdivision is reported only where the
runtime exposes it.

## Local post-change evidence

Fresh Ubuntu-proot verification after the implementation:

- `flutter analyze --no-fatal-infos`: `No issues found`;
- full non-golden Flutter suite: 282/282 PASS in 3:26;
- final focused readiness/render/profile/boundary suite: 26/26 PASS;
- month/day and year/month density matrix: 30 identical repetitions per
  pair, including empty, 2, 4, 9, 24-preview, 94-total and 100,000-total
  fixtures.

Every density case produced the same scripted values:

- drag-end velocity: `-2032.8611936301181 px/s`;
- ballistic input: `2199.9966122376204 px/s`;
- logical delta: `10`;
- pixel distance: `524.5201793722808`;
- activity interruptions: `0`;
- rail metric corrections: `0`.

The dense 100,000-entry month painted the same bounded preview surface as the
94-entry month (maximum prepared preview: 24). The true first-READY and tenth
fling widget fixtures pass in both month/day and year/month planes with zero
post-ready first-use work, cache miss, data I/O or controller/position/physics
recreation.

These are deterministic architecture and scheduler gates, not physical-device
smoothness proof. The corrected profile fixture now runs the cold-first
scenario first in the process, performs no pre-interaction reset or nine-fling
warmup, and records first/second/fifth/tenth timelines for all four density
lanes. Physical acceptance remains open until the exported profile-APK report
is returned from the target device.

## Exact AOT evidence and diagnostic correction

GitHub Actions run `31160799254` executed candidate `cbf46d5655bd25a8758ae6775b18f8ad4d8766ae`.
The Flutter test/analyze, native/core, candidate A–J profile and diagnostic APK
jobs completed successfully. The profile proves, for every one of ten flings
in all four density lanes:

- 51 pointer samples over 420 logical pixels and 190,909 microseconds;
- pointer-gap p50/p95 `3,000/3,000 µs`, maximum `3,819 µs`;
- drag-end velocity `-2032.863147504286 px/s`;
- ballistic input `2199.97920477585 px/s`;
- logical delta `9`;
- zero activity interruption, scroll-metric correction, data I/O and critical
  cache miss.

Thus the synthetic density endpoint is invariant. It is still not evidence
about physical touch delivery: `WidgetTester.fling` supplies the same event
trace by construction.

The first/tenth standalone scenario had the same input and endpoint, but not
the same software-renderer frame profile:

| Metric | first | tenth |
|---|---:|---:|
| UI p50 / p95 / p99 | 1.297 / 13.597 / 18.396 ms | 1.054 / 4.922 / 6.974 ms |
| raster p50 / p95 / p99 | 135.213 / 170.235 / 199.046 ms | 134.142 / 146.286 / 148.040 ms |
| total stable-surface paint counter | 15,744 µs | 6,398 µs |
| first-use violations / critical misses | 0 / 0 | 0 / 0 |

The raster values come from the CI software renderer and fail the physical
frame target; they are not relabeled as device smoothness evidence. The UI
difference also means first/warm performance remains unaccepted until the
target-device report is returned.

This run exposed a diagnostic wiring defect: `LOGBOX_FRAME_PRESENTED` sampled
the outer repaint-boundary probe (`logPaintMicros`, typically 0–1 µs), while
the retained `RenderCustomPaint` recorded its real work in
`logSurfacePaintMicros`. A red/green widget test now makes the presented-frame
event, release-window work and gesture paint total consume the actual surface
counter. No motion or physics behavior changed.

The same run also exposed that the historical comparison job checked out
`f33152b`, not this task's required `fb6aaec` milestone, and allowed the old
fixture's own first/tenth duration assertion to fail the candidate workflow.
The job now checks out `fb6aaec`, records the baseline assertion outcome as
evidence, requires at least one profile JSON artifact, and does not treat the
known baseline behavior under investigation as a candidate-code failure.

## Exact cold-first failure and the remaining concrete first-use operation

Exact candidate run `31163562199` executed commit
`5c83afa6ff67e89d9e283de3d01501858c82d101`. The native/core and Flutter jobs
passed, and the historical baseline artifact was produced correctly. The
candidate profile failed its unchanged first/tenth motion-duration gate:

| Scenario | Motion duration |
|---|---:|
| first fling | 4,429,695 µs |
| tenth fling | 3,662,422 µs |
| absolute difference | 767,273 µs |
| permitted 15% tolerance | 664,454 µs |

Input samples, release velocity, ballistic input, target, settle index and
semantic traversal were identical. The failure was therefore not hidden by a
physics or endpoint tolerance.

The corrected `RenderCustomPaint` evidence identified the remaining work. On
the first child sequence, the LogBox painter spent `4,527`, `2,368`, `981`,
`4,113`, `5,051`, `1,754` and `1,057` microseconds on newly encountered
payloads; repeated payloads commonly fell into the `300–800` microsecond range.
Source inspection then exposed the exact operation: although the payload
pointer swap was O(1), `_DashboardLogBoxSurfacePainter` still called
`TextPainter.layout` four times for every painted row and once per encountered
day header. New child strings caused paragraph shaping/layout and font-cache
work inside the same paint frames as the first rail fling. The tenth fling
reused engine-cached paragraphs/glyph work and was consequently faster.

This is the concrete work that remained after the spinner. It also explains
the density slope: month children encounter more row/header text paragraphs
than day children, and populated children encounter more than empty children.

## Final text-layout ownership

`DashboardLogBoxTextLayoutCache` now owns the paragraph lifecycle. Before the
readiness acknowledgement it:

1. derives the current/adjacent SUM/year/month pin window from the immutable
   `PreparedDashboardIndex` for both directions;
2. deduplicates rows by stable entry identity;
3. validates a precomputed constant-time `textLayoutId` rather than hashing or
   comparing row strings in paint;
4. prepares title, secondary label, amount and time paragraphs at the exact
   live surface width, plus unique day-header/empty paragraphs;
5. yields in cancellable bounded chunks while the spinner owns interaction;
6. fails closed if the pin set exceeds 8,192 unique rows;
7. repaints the one normal visible surface and only then acknowledges READY.

The canonical LogBox build/paint source contains no `.layout(` call. A child
crossing now performs only row-ID lookup and `TextPainter.paint` on an existing
paragraph. Missing prepared text after READY increments
`logTextLayoutFallback`, emits `RAIL_CRITICAL_CACHE_MISS`, asserts in
debug/test and fails the exact profile gate. The previous paint-time layout
route was removed rather than retained as a release fallback.

The cache is not an offscreen widget renderer: it creates no Widget, Element,
RenderObject, layer, image or hidden viewport. It retains only bounded
paragraph/layout objects. The physical report exports prepared row/header
counts and a conservative retained-byte estimate independently of counters
that profile scenarios reset at motion start.
