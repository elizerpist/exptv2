# Live-count, Summary-variant and Avatar authority repair

## Scope and provenance

- Application investigation base: `fcc574b6cf2e58a181e0b841d6252a475ca9342c`
  on `fix/repair-shared-live-publication-authority-codex-20260904`.
- Repair branch: `fix/live-logbox-count-summary-variant-authority-codex-20260905`.
- Matching navigation index: tooling commit
  `11c4436e706091c086789f650a4b6bb43bec8910`, manifest `source_head` equal
  to the application base, `scip_dart 1.6.2`, raw index SHA-256
  `db20749aa85fd0ce10cfc62852fa0501b24f7d726746129779ea406159b18a5d`.

The index was used to find direct consumers only.  Every relationship below
was checked in the application source; it is not runtime-order evidence.

## Physical-log audit

All three documents were fully opened.  They identify session
`fluvi-1788601358588318`, `profile/fcc574b6...`, but do **not** make one
continuous trace.  Each retained document combines two live tails with a
999-event overlap; counts below are deduplicated by sequence number.

| Document | Unique retained range | Timestamp range | Marks | Limits |
| --- | --- | --- | --- | --- |
| Fluvi logs avatar fling | `4464–5464` | `11:40:45.22–11:43:54.10` | `4567`, `5463` avatar fling; `5464` filter stuck | no events `5465–8829` |
| Fluvi logs time fling | `8830–9830` | `11:44:50.47–11:45:30.00` | `9829` time fling; `9830` time target jump | no events `5465–8829` or `9831–10905` |
| Fluvi logs slider | `10906–11906` | `11:46:29.83–11:47:20.23` | `11905` Mind slider; `11906` no live list | no events `9831–10905` |

The Slider range records 32 Mind preview frames, accepted live publication,
readable Phase-A paint, three completed canonical applies, no per-tick
repository/index/canonical work, and final amount refinement.  Observed exact
counts include `0`, `21`, `2288`, and `2287`.  This disproves a slider
hit-test/filter/database diagnosis.

The Avatar range has accepted publication and matching logged semantic
identities, so the older cross-producer numeric-generation collision is not
present in this build.  It did expose a diagnostic contradiction: flight
summaries reported zero matching LogBox paints while separate
`AV|LOGBOX_TARGET_PAINTED` events existed.  The old rail source had no code
that incremented those summary counters, which proves an accounting gap—not
that a semantic event itself was a paint.

The Time range preserves the accepted resident semantic path: no query apply,
repository/index build, or rich-scene preparation per tick; one canonical
settle is recorded.  The target-jump mark and scene/settle misses remain a
separate unproven path.

## Source proof and rejected hypotheses

### Proven: live count used the committed lane

`DashboardVisibleFrameStore` retains committed `_value` deliberately while
accepted live frames flush a typed `countLane` alongside its LogBox lane.
`DashboardLogBoxHeader` had listened to `_value`, so its count could stay on
the committed structural frame while live rows and amount were exact.  The
repair changes only that narrow binding to `countLane`; it does not publish
live frames into `_value`, compute count from bounded payload rows, query a
repository, or rebuild an index.

### Proven and reproduced: segmented adapter disposal could retain shared
motion state

Classic `DashboardSummaryPill` explicitly reports inactive motion during
disposal.  The segmented adapter did not have an equivalent *adapter-level*
handoff.  Its conditional hierarchy tracks can disappear while the persistent
mode selector is still active, so a child disposal must not itself end the
shared Summary safety lane.  A persistent real `CoreDashboard` test starts
segmented motion, switches to classic, and red-failed because the shared
foreground motion remained active.  The repair introduces a small segmented
motion gate: the persistent mode selector can release its own active state,
conditional hierarchy removal cannot clear another selector's state, and the
gate host releases the shared lane exactly when the complete segmented adapter
unmounts.  The variant controller adds a presentation-only monotonic epoch;
`_DashboardSummaryRegion` captures variant/epoch in callbacks, rejects stale
callbacks, and the Core quiesces `summaryShell` synchronously before an
outgoing adapter disposes.

This proves a lifecycle ownership defect.  It does **not** prove that it was
the sole cause of every user-observed Avatar visual failure after a variant
round trip; fresh physical validation and the bounded transition diagnostics
are still required.

### Proven: Avatar flight paint counters were disconnected

The Core now emits immutable `DashboardAvatarTargetPainted` metadata only
after the existing strict LogBox query/revision/presentation/frame identity
and actual paint checks succeed.  It contains no selection/query authority.
The existing drilldown composition passes this metadata to the real Avatar
rail, which accounts matching direct/ballistic Phase-A paint separately from
optional Phase-B paint.  A terminal summary issued before a valid paint says
`awaitingExactPaint`; a later exact Core acknowledgement emits a reconciliation
event rather than silently leaving an apparent final zero.  Rejected or stale
metadata cannot choose or settle a target.

## Protected systems

No changes were made to Summary or Avatar physics, velocity/snap thresholds,
query/filter semantics, database/schema, financial calculations, paging
ownership, geometry formulas, Stack order, LogBox clipping/card design,
prepared-index architecture, Phase-A/Phase-B authority split, or the typed
producer/global publication order.

The existing Stack and geometry tests remain the protection for one active
Summary, rail participation, tuner behavior, LogBox boundaries, and stable
controllers.  The new transition test additionally preserves query and count
lane identity across a real classic → segmented → classic replacement.

## Graph-assisted impact review

The matching fcc graph identified the direct families, then CURRENT HEAD
source was inspected before deciding scope:

- `DashboardLogBoxHeader` has one production constructor consumer,
  `DashboardLogBoxViewport`; its direct focused consumer is the viewport test.
  Only the header's inner count `ValueListenableBuilder` changes, leaving the
  viewport, `ScrollController`, clipping, and custom render-surface owners
  unchanged.
- `SummaryPillVariantController` is used by `CoreDashboard` and the Header
  visual tuner.  The tuner still calls the same `select` method; CoreDashboard
  is the only new epoch/motion-boundary consumer.  No adapter is given query,
  visible-frame, or financial authority.
- `BudgetTargetAvatarRail` is produced by `BudgetDashboardCoreSurface` and
  covered directly by its rail test plus the production LogBox paint test.  The
  new Core notifier travels only through
  Core → drilldown coordinator → surface → rail and is read as diagnostic
  metadata after the existing strict render-extent identity check.

No changed source modifies `DashboardVisibleFrameStore` publication ordering,
geometry formulas, the dashboard Stack order, `ScrollController` ownership,
query/index construction, database code, or Summary/Avatar physics.  The graph
provided these one-hop neighborhoods; it was not treated as runtime causality.

## Automated evidence and limitations

- New focused header test proves total `2288` is selected rather than bounded
  payload `24`; it also covers stale count rejection, canonical reconciliation
  and cancellation fallback.
- The real production RangeSlider/LogBox test now proves visible count changes
  `1 → 0 → 1` during held live preview, stays at `1` through canonical
  completion, and retains both viewport and render-surface elements.
- The real CoreDashboard transition test red/green proves active segmented
  motion is released on replacement and records bounded transition evidence.
- The real Avatar rail/LogBox test red/green proves Phase-A post-paint is
  counted in the flight domain; a second test covers late post-settle
  reconciliation and retained exact same-target paint.  The Core re-entry
  regression first red-failed with no post-paint acknowledgement, then proves
  that a raw pointer re-entry can rearm only an unpainted exact target without
  retagging a retained exact paint.
- `dashboard_logbox_stable_render_surface_test.dart` has one exact baseline
  failure at `fcc574b6` and on this branch: `tester.state(find.byType(Scrollable))`
  sees too many elements.  It is recorded as inherited, not altered.

Physical correctness remains **PENDING — USER ONLY**.  Specifically unproven:
the complete physical classic → segmented → classic Avatar symptom, any
invisible-layer/geometry paint authority beyond the lifecycle boundary above,
the residual Time target jump, and Avatar smoothness/frame timing.

## Validation record before delivery

- Formatter over all 16 changed Dart files: pass, no files changed.
- `flutter analyze`: pass, no issues.
- Focused application Core/focus suite: 45 passing.
- Focused Avatar rail suite: 41 passing.
- Summary variant/experiment/presentation/motion group: 47 passing.
- Direct visible-store, Budget presentation, live-interaction, Avatar,
  distribution, CoreDashboard, and geometry group: 115 passing.
- Combined LogBox group: 66 passing with the one pre-existing stable-render
  failure above.  The exact fcc baseline command had 13 passing with that same
  one failure at the same assertion.
- Full dashboard application suite: 275 passing.
- Full dashboard presentation suite: 572 passing and 19 failures, matching
  the previously recorded inherited count.  The retained failures include the
  known golden/parity, Deep Drift range, Space Fabric ticker/golden, and stable
  render-surface families; no newly attributed failure is hidden in that set.
- Fresh combined changed-surface command (Core/focus, Avatar rail,
  CoreDashboard, production LogBox, header/viewport, segmented experiment and
  variant tests): 197 passing.

The new diagnostic paths are bounded by accepted Avatar target, terminal
flight, or variant transition—not per pixel or row.  Their device-time
overhead has not been profiler-measured, so no frame-time improvement or cost
is claimed.
