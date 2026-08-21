# Header raster + Avatar motion repair — architecture card

## Evidence gate

The requested current local Fluvi diagnostic log was not present in the
`separated-core-modes` worktree, any registered Fluvi worktree, or the
accessible Android shared storage during the initial audit.  Its required
chronological CRITICAL-event table is therefore **BLOCKED** pending the exact
file.  This is not silently treated as clean evidence.

Two independent current-source defects are nevertheless directly proven:

1. `_DashboardHeaderVisualPainter` and
   `DashboardHeaderPortalMaterialPaintLane` sample fields on a grid of four
   *logical* pixels, then paint every sample using `Canvas.drawRect`.  The
   cache/grid is not DPR-aware and has no interpolation.  At a DPR of 3, a
   maximum-quality cell is still about 12 physical pixels wide, so visible
   rectangular blocks are an expected coarse-field artefact, not a slider
   state issue.
2. `BudgetTargetAvatarRail._onPreviewChanged` invokes the Budget LogBox
   drilldown for every semantic crossing.  That reaches
   `DashboardCoreController._requestEphemeralFocus`, which synchronously calls
   `DashboardEphemeralFocusDeriver.deriveFast` and starts an immutable-index
   publication.  TimeRail has no corresponding query/focus path.  This breaks
   the documented Motion Kernel → Prepared Data → Visible Frame → Committed
   Query boundary while a ballistic simulation is running.

## Source-proven differential graph

| Consumer | Physical motion | Crossing work before repair | Crossing work after repair |
| --- | --- | --- | --- |
| TimeRail | `ScrollPosition` → shared `CenteredCarousel` → `DashboardMotionKernel` | retained catalog lookup + narrow visible-frame publication | unchanged |
| Budget avatar rail | `ScrollPosition` → shared `CenteredCarousel` → prepared rail item | `setTargetHandle` → `commitBudgetTarget` → `_requestEphemeralFocus` → synchronous `deriveFast` + prepared-index publication | `setTargetHandle` → latest-value-wins display-frame Header preview; the existing focus/query bridge runs only for the settled user target or an explicit target command |

`centered_carousel_physics.dart` is intentionally outside this repair and its
diff is required to remain empty.  No crossing path performs repository,
Room/SQL, bridge, SVG, LogBox or query work after the repair.

## Required ownership after repair

```text
Avatar crossing
  -> existing CenteredCarousel physics (unchanged)
  -> retained Budget catalog O(1) target lookup
  -> latest-per-display-frame visual preview publication
  -> Budget header palette + localized Header repaint

Avatar settlement / explicit drilldown intent
  -> existing committed LogBox focus/query pathway
```

The Header renderer retains field geometry/scalars independently from the
immutable frame palette.  Palette-only A/B changes must not create a second
Ticker, effect controller, field grid, SVG, image raster, or semantic Header
tree.  The visual layer smooths a field between source samples rather than
displaying the sampling cells.

## Protected boundaries

- `CenteredCarousel` motion/physics, controller and `ScrollPosition` identities
  remain unchanged.
- `DashboardMotionHost`, `DashboardExpansionController`, prepared snapshots,
  scene caches, paging and LogBox ownership remain unchanged.
- Avatar target/Header feedback stays live during drag and fling.  Only the
  committed focus/query path is removed from the crossing hot path.
- Header animation remains a single controller-driven leaf paint lane.
