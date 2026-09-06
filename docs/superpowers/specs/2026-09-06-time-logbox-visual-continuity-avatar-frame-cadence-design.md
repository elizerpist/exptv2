# Time LogBox visual continuity and Avatar frame-cadence design

## Authorization and visual reference

This design records the user's approved 2026-09-06 repair request.  The exact
physical baseline is `a8ad6e5cae641a19a7a23acc917313a4c41ac851`; the repair
branch starts from that commit.  Physical validation of any successor remains
**PENDING — USER ONLY**.

The visual reference is the two current Android screenshots in
`/storage/emulated/0/Pictures/Screenshots`:

- `Screenshot_20260906-005507.png`: populated March 2026 LogBox, with normal
  cards beginning directly below the facet row;
- `Screenshot_20260906-005458.png`: rejected September 2026 exact-empty
  visual, with a large blank area and a centred white two-bar shell.

No new product visual is designed.  The zero-count header is the existing
empty-state communication.  The body keeps one structural render host but is
transparent for an exact-empty target.  A separate HTML mockup would not
clarify this source-owned rendering/extent defect, so none is introduced.

## Existing ownership that must be reused

- `DashboardVisibleFrameStore` remains the single typed publication authority.
- `DashboardLogBoxViewport` retains its State, vertical controller, scroll
  position, sliver hierarchy, scene cache and one custom render surface.
- `DashboardLogBoxPreparedSceneCache` supplies prebuilt Phase-A readable rows;
  no text shaping or rich projection moves into `paint`.
- The selected bounded resource owner, rather than sparse payload construction,
  arms immutable Phase-A row/group geometry; paint consumes only that ready bank.
- `DashboardLogBoxRenderDomain` remains the single selector for
  `railPreview` versus `committedVertical`.
- `DashboardLogBoxTerminalExtent` remains the one scroll-tail calculation;
  no terminal inset is folded into row geometry.
- Summary and Avatar remain presentation/input adapters of the existing core;
  neither receives a second frame store, renderer, controller or query path.

## Evidence-driven decisions

1. **Exact empty is directly repairable.**  Current source calls
   `_paintExactEmptySemanticPreview` for a zero-row Phase-A payload, and the
   terminal extent deliberately retains a viewport-sized structural host.
   The combination exactly explains the rejected two-bar shell.  The repair
   will retain the host but paint no user-visible decoration or fake row
   semantics.
2. **Time paint counts need a truthful lifecycle model first.**  The current
   flight summary's `paintedLiveSnapshots` is an existence flag, not a count.
   New target diagnostics/reproducers must distinguish `exactPainted`,
   `exactEmptyPainted`, `coalescedBeforePaint`, `rejectedStale`, and
   `cancelledByNewInteraction`.  No conclusion about 13 lost paints follows
   from the existing `0|1` field alone.
3. **Domain and extent are one visual decision.**  A paint identity and its
   extent snapshot must describe the same payload, presentation, viewport,
   geometry generation and render domain.  The repair may alter a proven
   ordering/fencing edge, but cannot loosen stale identity rejection.
4. **Avatar gets measurement before tuning.**  The existing retained avatar
   flights show exact semantic/paint accounting and no heavy tick work.
   Bounded FrameTiming and staged latency aggregation may be added, but
   physics changes are forbidden unless that data proves a specific defect.
5. **Slider/count are protected.**  The user reports a physical pass while
   the retained tail lacks the drag.  Existing production regressions are run
   unchanged; no slider/query/count implementation is changed without a new
   failing reproducer.

## Non-duplication / centralization gate

The repair extends the present LogBox render-binding and diagnostics seams.
It must not create a Time-only painter, a second empty renderer, a per-variant
viewport, a parallel extent calculator, a second visible-frame store, or a
new formatting pipeline.  Small neutral lifecycle data belongs at the shared
render/acknowledgement boundary so Time, Avatar, Mind and vertical scrolling
continue to agree on one contract.
