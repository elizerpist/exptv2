# Cache-independent live Budget projection plan

1. Add deterministic red tests for warmed versus forced-miss temporal and
   avatar routes, without pumping background work to idle.
2. Derive one `DashboardBudgetLiveAnalysisProjection` (repository naming may
   differ) from the existing live interaction frame plus the current Budget
   target owner. It carries generation, revision, direction, exact scope and
   handle; it never stores a second date or target.
3. Make Budget header/progress/partition and Spending Rhythm consume that
   projection. Retained visible scenes continue to feed LogBox only.
4. Give Card2 an exact-current synchronous prepared geometry path on a drawable
   cache miss. Keep sibling warming as cancellable, tiny maintenance grants.
5. Verify the focused LogBox first-viewport path follows avatar crossings even
   while the rich scene completion is withheld and stale completions lose.
6. Introduce a pure Partner layout resolver that reserves the named Rhythm
   lanes first, then allocates a smaller donut and scrollable legend.
7. Reproduce each cascade progress, identify the actual opaque slab owner and
   correct its hierarchy/clip/material rather than covering it.
8. Raster-test the actual SUM `SweepGradient` path and correct only the shader
   transform/coordinate mapping needed for the canonical top seam.
9. Run focused suites, analysis, diff check and online Android human-APK CI.
   Physical device work remains explicitly unclaimed unless performed.

## Architecture boundary

`DashboardLiveInteractionFrame` remains the sole interaction provenance.
`DashboardVisibleFrame` remains a retained LogBox rendering resource. The
Budget live analysis projection is an immutable, typed view of the former and
the already-owned Budget target; it is not navigation state, cache state, or a
second controller for temporal selection.
