# Dashboard rail smoothness design

## Baseline and scope

The implementation starts at `bef62ae8c92d18ae1dde74dd521bb739fadd556b`
on branch `feature/dashboard-rail-smoothness`. The rail-preview behavior from
`1430c50666bc48deb2ea10f01592ccf567decf87` is a frozen compatibility boundary.

This slice removes background-work overlap and false diagnostics. It does not
redesign the rail or change its physics.

## Ownership map

```text
CenteredCarouselController
  owns ScrollController, ScrollPosition, physics callbacks and motion command
  emits semantic motion-start, preview-crossing, idle and settle signals

DashboardRailMotionCoordinator
  owns dashboard motion epoch, idle/settle dedupe and motion-active state
  does not own scrolling, offsets, physics or query data

CurrentQueryController
  owns committed query scope, cache, repository reads and live lease ownership
  cancels pending lease activation on an invalidating motion epoch

DashboardPresentationStore
  owns visible target and atomic visible snapshot acceptance
  caches old results but rejects cross-target visual publication

DashboardCoreController
  coordinates committed transitions and motion-aware adjacent prewarm
  does not duplicate query or rail ownership

DashboardLogPresentationAdapter
  owns pure immutable LogBox projection and phase timings

DashboardLogBoxViewport
  owns only its stable vertical scroll controller and lazy sliver rendering
```

## Causal changes

### 1. Latest-wins pending lease

The motion coordinator calls a public invalidation boundary on the query
controller at the start of every user drag/ballistic command. The query
controller increments its lease generation and cancels only the pending timer.
An already active lease is not cancelled on every preview tick. Its result may
update cache state, but the presentation store decides whether it is visible.

The pending activation callback validates lease generation, motion epoch,
scope, direction and refinements before subscribing.

### 2. Active result isolation

The query controller separates cache acceptance from visible acceptance. A
result for an old committed scope may be retained for a future cache hit, but
when a different preview target is visible it must not notify the dashboard
root, reproject LogBox rows, start an amount transition, or change rail state.

### 3. Amount policy

The amount presentation has three semantic modes:

- `directPreview`: immediate text replacement, duration zero;
- `noOp`: equal numeric value, no controller restart and no presentation notify;
- `semanticAnimated`: only for a non-motion, genuinely changed user-facing
  transition.

Diagnostic duration reflects the actual mode instead of a fixed 120 ms. The
existing latest-wins animation guards remain in place for the animated mode.

### 4. Idle and settle dedupe

The shared motion command becomes the source identity for dashboard motion
epochs. Raw `ScrollEndNotification` is not treated as a semantic idle by
itself. One idle and one settle can be emitted per epoch; repeated callbacks
are dropped with numeric counters.

### 5. Motion-aware adjacent prewarm

Current-parent preparation remains high priority. Adjacent parent prewarm is a
cancelable low-priority lane guarded by motion-active state and a generation.
It never publishes visible state. If motion begins, a scheduled task is
cancelled or stops before starting the next candidate; already active reads
may finish into cache but cannot project or notify the visible dashboard.

### 6. Compact diagnostics and LogBox phase timing

Bundle child decoding suppresses per-child D7 diagnostics unless verbose flow
logging is explicitly enabled. One aggregate bundle event reports child count,
empty/non-empty count, entry count and parse/projection duration.

The LogBox adapter records bounded numeric phase samples for lookup/select,
projection and publication. Widget build/layout/paint timing is collected only
in profile/debug instrumentation and never assembled as long hot-path strings.

## Test-first sequence

1. Add failing pending-lease invalidation test.
2. Add failing active-result visual-isolation test.
3. Add failing amount direct/no-op diagnostic tests.
4. Add failing idle/settle dedupe test.
5. Add failing motion-aware prewarm test.
6. Add failing aggregate bundle diagnostic test.
7. Add failing LogBox projection phase counter test.
8. Implement the smallest production changes in the ownership boundaries above.
9. Run the frozen rail and presentation regression suite.
10. Run deterministic 5k/20k/100k stress tests and profile measurements.

## Non-goals

- No physics tuning.
- No manual fling or second motion owner.
- No preview debounce.
- No full transaction-list preload.
- No viewport remount or query-key root key.
- No golden test.
