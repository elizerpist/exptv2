# Live LogBox count and Summary-variant authority design

## Authorization and boundary

This design records the user-approved request **FLUVI — FIX LIVE LOGBOX COUNT
BINDING AND FORENSICALLY REPAIR SUMMARY-VARIANT / AVATAR VISUAL AUTHORITY
WITHOUT REGRESSING TIME PERFORMANCE**.  The implementation base is the
physically tested `fcc574b6cf2e58a181e0b841d6252a475ca9342c`; visual physical
validation remains **PENDING — USER ONLY**.

No new visual alternative is being designed.  The existing LogBox visual
language, bounds, clipping, card geometry, Summary/Avatar physics, and Stack
order are the approved reference.  The work is an authority/lifecycle repair,
so an HTML visual companion would not clarify a product decision and is not
introduced.

## Existing ownership to reuse

- `DashboardVisibleFrameStore` already has the exact committed `_value` and
  typed `countLane`, `amountLane`, and LogBox lanes.  The count repair must
  consume that existing lane rather than create a parallel count source.
- `DashboardLogBoxHeader` is the narrow presentation consumer.  Its existing
  `RepaintBoundary` is the correct invalidation boundary; the viewport,
  scroll controller, scene cache, and custom render surface stay owners of
  their respective resources.
- `SummaryPillVariantController` is presentation-only.  Both Summary adapters
  continue to project `DashboardCoreController` navigation and visible-frame
  authority; neither can acquire financial, Avatar, or LogBox ownership.
- `DashboardMotionHost` remains the sole geometry/ticker host.  A transition
  may add a small, neutral presentation-transition boundary only if the
  reproducer proves a callback/lifecycle handoff defect.

## Design decisions

1. **Effective count selection.**  The header selects the latest
   identity-valid `countLane` frame during a live interaction and the
   committed frame otherwise.  Selection requires the same accepted
   query/revision/publication identity as the visible LogBox path.  It never
   changes `_value`, queries data, rebuilds an index, or reads bounded payload
   length as the total count.
2. **Canonical reconciliation.**  When the matching canonical frame arrives,
   the selector converges without an intermediate zero or a stale preview
   rollback.  A stale lane value cannot replace the newer accepted owner.
3. **Variant forensics before repair.**  A persistent production dashboard
   reproducer first records variant epoch, outgoing/incoming adapter state,
   motion lanes, geometry generation/bounds, binding, and actual paint
   acknowledgement.  No lifecycle/Stack change is allowed until that test or
   bounded runtime trace proves the failed edge.
4. **One active adapter.**  Any subsequently proven repair must make removal
   of the old Summary adapter explicit: inactive motion, no stale callbacks,
   no semantics/hit-test/paint ownership, and shared canonical navigation
   state retained by the incoming adapter.
5. **Paint accounting is factual.**  Phase-A and Phase-B acknowledgements
   are counted in their actual domains.  Diagnostics must not turn a
   semantic notification into a paint claim.

## Protected composition

The production `Stack` order is retained:

`DashboardCoreModeHost < action controls < Summary < physical rail < LogBox
< collapse handle < tuner overlay`.

The `DashboardGeometryResolver` remains the geometry owner.  Variant changes
may switch `hasPhysicalRail`, but cannot introduce hard-coded per-variant
coordinates, a second controller/store, a full-dashboard reset, or a
transparent input-catching layer.

## Evidence state at design time

- The three fully opened Drive documents are session
  `fluvi-1788601358588318` / `profile/fcc574b6…`; each is two 1,000-event
  retained snapshots with a 999-event overlap.  Their deduplicated ranges
  are Avatar `4464–5464`, Time `8830–9830`, and Slider `10906–11906`.
- Slider evidence proves live/canonical amount filtering works and the header
  observes the wrong lane.  This repair is authorized directly.
- The physical classic → segmented → classic Avatar presentation failure and
  the discrepancy between Avatar summary and paint events remain unproven.
  They are forensic work until a deterministic reproducer identifies the
  exact ownership edge.
