# Forensic journal — Time LogBox visual continuity / Avatar frame cadence

## Baseline and provenance

- App base/ref: `a8ad6e5cae641a19a7a23acc917313a4c41ac851`, parent
  `fcc574b6cf2e58a181e0b841d6252a475ca9342c`.
- Repair branch/worktree: `fix/time-logbox-visual-continuity-avatar-frame-cadence-codex-20260906` at
  `/data/data/com.termux/files/usr/tmp/fluvi-time-logbox-visual-continuity-20260906`.
- Matching graph: tooling commit `ada3c52733c424657bd6b36116d2f2f31e098637`,
  manifest source `a8ad6e5…`, raw index SHA-256
  `a6b803ae60b6bdbcf02062fa81a0cf2393e8de93b3ad7507463fcd0974373951`.
- Physical APK under investigation:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_a8ad6e5.apk`,
  SHA-256 `005d5938c44f8c07e623a26ba1ea925c2df7bf23bbbcaa9fdbfe7bb906b40c4f`.

## Fresh Drive audit

All three documents were fully opened.  They contain overlapping views of one
session: `fluvi-1788648924946593`, `profile/a8ad6e5cae64`, revision 2.

| Document | Retained snapshots | User marks | Audit result |
| --- | --- | --- | --- |
| Fluvi logs avatar fling | `11515–12514`, `11516–12515` | `12514–12515` | Fully read |
| Fluvi logs time fling | `11517–12516`, `11518–12517` | `12516–12517` | Fully read |
| Fluvi logs slider | `11520–12519`, `11521–12520` | `12518–12520` | Fully read |

Global parser result: 6,000 raw copies, 1,006 unique `seq` values
`11515–12520`; 1,004 sequence IDs were duplicated, yielding 4,994 excess
copies; no duplicate sequence had differing text.  The runtime tail lacks the
current Mind drag; its status is **PHYSICAL PASS — FRESH TRACE MISSING**.

## Confirmed facts

1. `TM|FLIGHT_SUMMARY` at seq 11561 records month flight 3 with 14 accepted
   live publications, 12 live-root misses, zero query/index/scene work, and
   a later `SUMMARY_SETTLE_REJECTED_UNPAINTED_OR_SUPERSEDED` at seq 11562.
2. `LOGBOX_RENDER_DOMAIN_CHANGED` includes committedVertical → railPreview
   at 11556, railPreview → committedVertical at 11622, and later reversals
   while the payload lane remains preview.  This is an investigation target,
   not causal proof by itself.
3. Seq 11753 correctly rejects a stale Summary paint identity with different
   query, presentation epoch, frame generation and viewport ID.  Strict stale
   rejection must remain.
4. Avatar retained flights report matching exact paints and zero tick
   repository/index/scene/canonical work.  Their semantic inter-tick cadence
   is not FrameTiming evidence.
5. CURRENT source calls `_paintExactEmptySemanticPreview` for zero-row
   Phase-A payloads.  It paints the screenshot's rounded two-bar marker while
   `DashboardLogBoxTerminalExtent` retains a viewport-sized structural host.
   This is the proven rejected visual path.

## Corrected interpretation

The current source formats `paintedLiveSnapshots` as
`_segmentedLatestPaintedTarget == null ? 0 : 1`.  It is an existence flag, not
a count of live frames.  Therefore the log cannot by itself establish that 13
accepted targets failed to paint.  New target lifecycle evidence must classify
each accepted target before a Time visual root cause is claimed.

## Rejected hypotheses so far

- The current fresh tail does not justify reopening Mind query/hit-test/count
  code; the user reports a physical pass and the drag is not retained.
- Semantic inter-tick spacing does not establish Avatar physics or frame jank.
- No graph edge is accepted as runtime ordering or visual evidence.

## Source-proven repair seam

The persistent production-parent reproducer separated the broad physical
symptom into two source-level defects.

1. **Exact empty was a direct visual defect.**
   `_DashboardLogBoxSurfacePainter` selected
   `_paintExactEmptySemanticPreview` for a zero-row Phase-A payload.  That
   painter drew the rounded two-bar shell while `DashboardLogBoxTerminalExtent`
   correctly retained a viewport-sized *structural* host.  The host was not
   the defect; treating it as permission to draw a synthetic empty card was.
   The normal exact-empty painter is now transparent and supplies no fake row
   semantics.  The existing header remains the sole user-visible zero-count
   communication.

2. **The render-domain selector could make a dormant committed fallback own
   geometry before a real vertical gesture.**  An exact committed cache plus a
   missing optional rich scene selected `committedVertical`, even when the
   same payload had a complete readable Phase-A bank.  The render surface then
   used the committed virtual extent while Phase A was the intended immediate
   visible resource.  This created two possible geometry authorities across
   preview/committed ownership.  `hasCompleteReadablePhaseAFor` is a cache-only
   identity lookup.  The selector now retains `railPreview` while that exact
   Phase-A bank can paint; committed fallback is used only when neither rich
   Phase B nor readable Phase A is drawable, or after actual vertical input.
   `dashboardLogBoxSurfaceExtentForDomain` is shared by surface and viewport
   so the selected paint domain also owns its content extent.

The Core Time acknowledgement path additionally now has explicit terminal
outcomes (`exactPainted`, `exactEmptyPainted`, `coalescedBeforePaint`,
`cancelledByNewInteraction`) and requires a full exact paint identity before
canonical settlement.  The old "already painted" fast path compared only the
temporal candidate; it now compares query/revision/presentation/frame/
viewport/interaction identity as well.  This prevents a later visit to the
same query from being silently treated as the old frame.

These changes do not prove that every physical delay in the retained tail had
one cause.  They prove the two visual paths above and remove their deterministic
reproducers without weakening stale rejection.

## Late hot-path review and correction

The initial readable Phase-A implementation built immutable row/group geometry
eagerly for every sparse deferred payload.  An existing canonical-query test
then stalled before reaching its later assertion.  A bounded experiment that
withheld only that geometry made the same test advance in roughly eight seconds,
which isolated materialization rather than query semantics as the added work.

The final form keeps the geometry immutable but lazy: a deferred payload exposes
no drawable Phase-A geometry until `DashboardLogBoxPreparedSceneCache` selects
that exact bounded payload for its live resource window and explicitly arms it.
The render/layout path observes the already-armed bank only; it neither formats
rows nor creates layout during paint.  A direct regression proves that sparse
payload construction alone does not arm the bank and that the bounded resource
owner does.  This preserves the Time/Avatar/Mind hot-path constraint without
introducing a second formatting or caching system.

## Avatar frame-cadence measurement

No Avatar physics, velocity, friction, threshold, coalescing or controller
logic was changed.  The shared centered-carousel diagnostics now offer bounded
FrameTiming and scalar latency accumulators.  The real Avatar rail records
only during an active physical diagnostic flight:

- raw-scroll to semantic-crossing latency;
- semantic-crossing to accepted store publication;
- accepted store publication to exact LogBox paint;
- acknowledged-frame vsync to raster-finish upper bound;
- bounded build/raster/total FrameTiming percentiles and missed-frame count;
- Avatar-rail build count and stable controller/position/physics identities.

The human diagnostic build script already provides
`FLUVI_PHYSICAL_RAIL_DIAGNOSTICS=true`.  Automated widget tests validate the
bounded aggregation contract, not device frame smoothness.  Therefore Avatar
root cause remains **UNPROVEN** until the next physical trace supplies real
FrameTiming samples; no physics adjustment is justified.

## Automated validation and baseline comparison

All Flutter commands were executed in the Ubuntu proot environment.

- `dart format --output=none --set-exit-if-changed <17 changed Dart files>` —
  PASS (`Formatted 17 files (0 changed)`).
- `flutter analyze` — PASS, no issues (`60.2s`).
- `./scripts/test-fluvi-fast.sh` with the Ubuntu-proot Flutter SDK on `PATH`
  — PASS, `290` tests.  The first direct invocation intentionally records
  `flutter: command not found`; rerunning with the mandated SDK path is the
  authoritative result.
- `flutter test dashboard_logbox_query_preview_paint_test.dart --reporter expanded`
  — PASS, `24` tests.
- Focused Core/Summary set — PASS, `74` tests.
- Focused Time/LogBox/Avatar/shared-diagnostics batch — `198` passed and one
  inherited stable-render-surface harness failure.  The exact a8ad control
  produces the same `Bad state: Too many elements` at line 87.
- Dashboard application suite — PASS, `278` tests.
- Dashboard presentation suite — repair `577` passed, `19` failed; exact
  `a8ad` control `572` passed, `19` failed.  The five extra passes are added
  repair coverage.  The normalized failure names/classes match the inherited
  golden/Header/ticker/stable-render-surface set; pixel-diff counts vary by
  render run, and no golden was regenerated.

The isolated stable-render-surface failure is identical on repair and control:
`Bad state: Too many elements` at
`dashboard_logbox_stable_render_surface_test.dart:87`.  It is retained as an
inherited harness failure, not suppressed or relabelled as fixed.

## Current classification

| Area | Classification |
| --- | --- |
| Mind slider/count | PHYSICAL PASS — FRESH TRACE MISSING; regression preserved |
| Exact-empty two-bar shell | PROVEN source path; repaired with automated pixel/semantics regression |
| Dormant committed fallback taking visual extent authority | PROVEN production-parent reproducer; repaired |
| Eager sparse Phase-A geometry materialization | PROVEN targeted test slowdown; repaired by bounded lazy immutable geometry |
| Every physical Time delay / target jump | UNPROVEN pending the new human APK and trace |
| Stale Summary paint rejection | PROVEN strict rejection; retained, with current-target settlement guard |
| Avatar accepted/paint accounting | PROVEN coherent in fresh retained flights; retained |
| Avatar unevenness | UNPROVEN; bounded FrameTiming pipeline added, no physics change |
| Existing broad-suite 19 failures | INHERITED, normalized against exact a8ad control |

## Impact review

Graph provenance was used for location/consumer discovery and every relation
below was rechecked in CURRENT source.  The repaired shared surface is limited
to `DashboardLogBoxRenderSurface`, `DashboardLogBoxViewport`,
`resolveDashboardLogBoxRenderDomain`, `DashboardLogBoxTerminalExtent`,
`DashboardLogBoxPreparedSceneCache`, and the Summary acknowledgement owner in
`DashboardCoreController`.  Direct product consumers are Time, Avatar, Mind
and vertical scrolling; their existing focused regressions were run.  Avatar
uses the small neutral shared diagnostics accumulator also used by the rail
flight recorder; no financial/publication owner changed.

The final source-verified direct consumer inventory is: render-domain selection
is consumed only by the stable surface and viewport (plus their diagnostics),
and both now pass the same complete-readable-Phase-A decision; the surface and
viewport share the same payload/committed extent functions; the Core only
consumes the post-layout extent acknowledgement and no longer guesses a
cache-owned render domain; the generic FrameTiming accumulator is consumed by
the existing rail flight recorder and the Avatar diagnostic rail.  Focused
Time, Mind, Avatar, vertical-scroll/cache and shared-diagnostic tests protect
the intentionally unchanged consumers.  No database, query, index, controller,
physics, typed-epoch, or Phase-A/Phase-B ownership code was changed.
