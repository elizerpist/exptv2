# Summary navigation motion recovery design

## Root cause

Commit `2bccd10` made `_SummaryNavigationTextSlot` enable
`SummaryPillTextTransition` only for vertical plane changes.  This deliberately
removed animation work from rail previews and horizontal parent commits to
protect the rail/query hot path.  It also removed the requested navigation
motion.

## Architecture card

### Scope and sources

- User specification on 2026-08-02: restore only the presentation motion for
  rail ticks and horizontal SummaryPill navigation.
- Existing implementation: `TimeRefinementRail`, `DashboardSummaryPill`,
  `SummaryPillTextTransition`, `SummaryNavigationProjector`, and
  `CoreDashboard`.
- Strict boundary: `lib/shared/motion/centered_carousel/**`, query state,
  amount projection, and navigation commit semantics remain untouched.

### Single source and write path

| Concern | Owner | Write path |
| --- | --- | --- |
| Persistent time navigation | `DashboardTimeNavigationController` | existing rail settle and SummaryPill callbacks |
| Query scope/latest-wins reads | `CurrentQueryController` through `DashboardCoreController` | existing committed navigation listener |
| Amount text | `DashboardSummaryAmountController` | existing query/index projection |
| Presentation motion intent | `SummaryNavigationMotionController` | rail preview adapter and SummaryPill gesture renderer |
| Tick and axis animation controllers | `SummaryNavigationMotionRegion` | local widget lifecycle only |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Axis text transition | `SummaryPillTextTransition` | Extend the one current vertical/horizontal transition instead of adding a sibling transition. |
| Rail physics, snap, haptic and logical mapping | shared centered carousel | Reuse without modification; the adapter only emits a presentation callback after its existing preview callback. |
| Parent navigation calculation | `DashboardTimeNavigationController` | Expose a read-only parent preview from the same application algorithm used for actual commits; presentation never derives a candidate from strings. |

### Layer flow

```text
nearest rail logical-index change
  -> TimeRefinementRail presentation callback
  -> SummaryNavigationMotionController tick intent
  -> SummaryNavigationMotionRegion paint-only Y impulse

SummaryPill horizontal drag
  -> presentation progress/candidate rendering
  -> existing parent navigation callback
     -> existing query scope update
     -> committed X-axis text transition
```

No branch awaits another branch.  Rail preview continues to update only
navigation presentation; it cannot write a query scope or amount state.

## Motion design

- `SummaryNavigationTextBlock` is the single title + subtitle widget.  It is
  the only text child of both axis and tick motion layers; the amount is a
  sibling outside them.
- `SummaryNavigationMotionRegion` owns one unbounded tick controller.  A
  changed logical index applies an impulse capped at `-4 logical px`, then a
  critically damped spring settles to zero in roughly 96 ms.  It does not
  alter opacity, scale, constraints or layout.
- Tick intent is suppressed for the initial rail callback, duplicate preview,
  final settle, silent re-centre, rebase and reconfiguration.  It does not
  call haptics.
- `SummaryPillTextTransition` remains the common latest-wins clipped block
  transition.  Vertical plane changes use Y + fade.  Horizontal parent
  changes use X + fade with 190 ms `Curves.easeOutCubic`; forward exits left
  and enters right, backward reverses both signs.
- During a SummaryPill horizontal drag, the current and explicitly projected
  candidate block track `-1..1` progress with the same X/fade equation.
  Commit continues from that progress; cancellation returns to zero.  The
  SUM plane has only 4–6 px resistance, no candidate, haptic, commit or query.

## Boundary and performance rules

- `CoreDashboard` creates the presentation motion controller and passes it to
  its two presentation children.  It does not listen to it, so rail ticks do
  not rebuild the dashboard, rail, query controller or amount widget.
- The motion controller has no query, scope, database, haptic, carousel or
  navigation mutation dependency.
- The rail adapter observes the existing `onPreviewChanged` callback and
  preserves its post-frame navigation-preview coalescing.  The new callback
  merely delivers an old/new logical-index motion intent.
- `DashboardTimeNavigationController` exposes a pure read-only parent
  candidate using its actual parent-transition algorithm.  This introduces no
  animation state and does not mutate/re-centre/notify.

## Verification

- Unit tests for axis vectors, tick clamp/retarget behaviour and presentation
  controller intent rules.
- Widget tests for shared Y tick offset, amount isolation, duplicate/settle
  suppression, X-only parent transition, interactive progress/cancel,
  latest-wins transitions, SUM resistance and gesture isolation.
- Existing carousel controller/widget/physics tests and query preview/settle
  tests stay green; `git diff -- lib/shared/motion/centered_carousel` is empty.
- Performance evidence: the motion listener is scoped to the text region and
  no preview reaches `CurrentQueryController`.
