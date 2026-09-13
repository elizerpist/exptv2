# Mind Year Heatmap physical repair architecture card

## Ownership and reuse gate

The repair does not create a second direction/query/filter mechanism.  The
existing `DashboardCoreController` remains the sole workflow coordinator;
`CurrentQueryController`, navigation, and the resident `PreparedDashboardIndex`
remain canonical state.  The annual heatmap's direction membership comes from
the existing `base.partitionFor(direction).focusMembershipSeed`, then one
`DashboardFocusMembershipSeed.select` for category, partner, search and other
non-amount refinements.  `MindYearHeatmapProjection` is the existing bounded
annual secondary amount-range projection.  Widgets render a published frame
and collect intent only.

There is no existing reusable local-calendar grid geometry authority.  Add a
small immutable, pure Mind domain geometry model adjacent to the annual
projection, if the RED tests confirm the need.  It owns only `(year, month)`
weekday offset, real-day slot mapping and row count; it contains no ledger
data, filter state or paint color.  The viewport/painter consumes this model,
so a slider repaint never recomputes date layout.

The existing `FluviDiagnosticLogger` is the only bounded diagnostic store, and
`DebugConsoleDialog` is the only on-screen panel.  A filter projection in that
dialog may select the `MIND_HEATMAP|` family without making another buffer,
panel or export route.  It must retain existing All/copy/capture capacity
semantics.

## Direction atomicity boundary under test

`TransactionDirectionController` updates toggle chrome during
`DashboardCoreController.selectDirection`, while the heatmap currently reads
the direction from committed navigation.  The code path is a candidate causal
boundary, not a conclusion: a mounted production-parent, frame-by-frame test
and correlated diagnostics must determine whether it is the first divergence.
Only that proven owner may change.  No shared direction rewrite is authorized.

## Static versus dynamic render work

Static: annual row grouping, month title, first weekday, slot map and calendar
row count.  Dynamic: one custom paint field per month driven by the existing
live annual frame.  The static shell must not rebuild for an amount-only frame;
the painter must not draw non-existent leading/trailing slots.  Avoid
`IntrinsicHeight`/`IntrinsicWidth` and avoid a substitute magic aspect ratio.
