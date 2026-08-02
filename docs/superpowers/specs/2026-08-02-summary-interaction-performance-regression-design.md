# Summary interaction performance regression design

## Goal

Restore the previously smooth vertical SummaryPill swipe, horizontal parent
swipe, and child rail fling without changing time-navigation, rail physics,
query, amount, haptic, or shell-to-text choreography semantics.

## Root-cause evidence

The diagnostic sample does not show a query during preview: every rail query
starts only after `R2 SCROLL_ACTIVITY_IDLE` and `R3
SELECTION_SETTLED_CALLBACK`. The 50--279 ms read times therefore do not
explain work on each rail-center frame.

The presentation hot paths do contain synchronous full-subtree rebuilds:

- `DashboardSummaryPill` calls `setState` for every drag update and every
  100 ms shell-return animation frame. Its `build` recreates the complete
  pill, including amount and chevron slots.
- `SummaryNavigationMotionRegion` calls `setState` for every rail tick even
  though a tick only needs to change the paint transform. That recreates the
  axis lane while the shared carousel is settling visual centers.

The second behavior was already mechanically possible before the most recent
motion work, but making the whole pill move horizontally increased the number
of pointer-frame rebuilds enough to expose it as a regression. The fix is to
remove both rebuilds from their hot paths, rather than alter carousel physics
or query timing.

## Architecture card

### Scope and sources

- User requirement: restore lag-free horizontal/vertical SummaryPill swipes
  and child-rail fling; then commit, push, build, and download the APK.
- Existing implementation:
  - `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
  - `lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart`
  - `lib/features/dashboard/application/dashboard_core_controller.dart`
  - `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Relevant prior working behavior: `6d844dc` presentation-motion baseline.

### Source of truth and write paths

| State | Owner | Write path | Boundary |
| --- | --- | --- | --- |
| SummaryPill shell offset | `DashboardSummaryPill` local presentation state | gesture updates and local return controller | Never writes navigation or query state |
| Rail tick displacement | `SummaryNavigationMotionRegion` local animation controller | existing semantic rail-tick intent | Never writes haptic or query state |
| Navigation | `DashboardTimeNavigationController` | existing movement/settle methods | Canonical scope owner |
| Query | `CurrentQueryController` | `DashboardCoreController._handleRailChanged` | Starts only after a committed revision |
| Amount | `DashboardSummaryAmountController` | existing query/index presentation flow | Independent from shell/text motion |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Child drag, fling, snap, rebase, haptic | `CenteredCarouselController` | Preserve; no feature-local replacement |
| Navigation/query commit path | `DashboardCoreController` + `CurrentQueryController` | Preserve; presentation does not call either owner |
| Shell and tick paint transforms | Existing `DashboardSummaryPill` / `SummaryNavigationMotionRegion` | Extend their local presentation lanes; do not introduce another gesture or motion controller |

### Layer flow

`Gesture/rail UI -> DashboardTimeNavigationController -> DashboardCoreController -> CurrentQueryController -> repository/native adapter`

The repaired paint-only lane is independent:

`Gesture/rail semantic intent -> local ValueNotifier/AnimationController -> Transform repaint`

No arrow from either presentation lane enters navigation, query, haptic, or
amount state.

## Design

### Shell lane

`DashboardSummaryPill` retains one local `ValueNotifier<Offset>`. Drag input
and the existing 100 ms `easeOutCubic` return controller update that notifier.
A `ValueListenableBuilder` rebuilds only the outer `Transform.translate`, with
the full pill supplied as its stable child. The gesture hitbox remains outside
the transform. Shell/text staging, generation checks, callbacks, and timing
remain unchanged.

### Rail tick lane

`SummaryNavigationMotionRegion` tracks the last staged-text snapshot. A pure
rail-tick notification re-targets the existing unbounded tick controller but
does not call `setState`; the existing `AnimatedBuilder` repaints only its Y
transform. The region rebuilds its axis lane only for a changed staged-text
snapshot or normal parent-provided content, preserving the current -4 px,
no-queue tick behavior.

### Query and amount invariants

No query path is changed. Preview continues to mutate only preview navigation
state, and a child query continues to begin only after the shared carousel
emits its settled selection. Amount presentation remains outside the text
transition and continues to update immediately from its current owner.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SIP-01 | User regression report | `dashboard_summary_pill.dart` | Drag and return frames repaint only the shell transform; navigation, amount, and chevron builders do not run once per frame | New widget regression test, code inspection | DONE |
| SIP-02 | User regression report | `summary_navigation_motion_region.dart` | A rail tick retargets only the tick transform and does not rebuild the text axis lane | Focused widget regression test, code inspection | DONE |
| SIP-03 | Prior accepted shell choreography | SummaryPill presentation | Full pill still follows X/Y drag; 100 ms return completes before the 190 ms text transition | Existing and focused choreography tests | DONE |
| SIP-04 | User log and prior query contract | navigation/query controllers | Preview has zero query writes; each actual settle uses the existing single query path | Existing controller/rail regression tests | DONE |
| SIP-05 | Prior accepted rail contract | centered carousel/rail | Velocity, friction, multi-item fling, snap, tap-retarget, rebase, and one haptic source remain unchanged | Protected rail/controller test suites | DONE |
| SIP-06 | User delivery request | CI and artifact | Verified commit is pushed; GitHub Actions debug APK succeeds and is copied to `/storage/emulated/0/Download/fluvi/` | GitHub run result, checksum, filesystem inspection | NOT DONE |
| SIP-07 | Architecture gate | presentation/application boundaries | Presentation remains free of repository/query writes and no duplicate gesture/physics engine is introduced | Boundary suite and dependency inspection | DONE |

## Verification evidence

- Red/green: `shell return repaints only the transform` failed before the
  notifier extraction (navigation builder calls `8 -> 10`) and passes after
  it. The test also requires the shell repaint boundary.
- Red/green: `rail ticks repaint only the Y lane` failed before the cached
  staged-text snapshot because the `SummaryPillTextTransition` widget instance
  was replaced. It passes after the tick-only listener path no longer calls
  `setState`.
- Focused presentation/query/rail suite: 27 tests passed.
- Protected centered-carousel physics, widget, boundary, and motion golden
  suite: 31 tests passed.
- `flutter analyze --no-fatal-infos`: exit 0; three pre-existing informational
  diagnostics remain in `fluvi_diagnostic_event.dart` and
  `fullscreen_controller_web.dart`.
