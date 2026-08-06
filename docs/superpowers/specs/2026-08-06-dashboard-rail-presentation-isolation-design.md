# Dashboard rail/presentation isolation design

Date: 2026-08-06

Status: approved by the user's prescriptive proof-first request.

Execution: one agent, inline; no delegated work.

## Job to be done

Preserve the milestone's prepared-index architecture and unchanged rail
mechanics, measure the first empty/populated motion divergence, and remove only
the presentation/layout/rebuild coupling that causes it.

## Ownership and reuse gate

The existing neutral owners remain canonical:

- `CenteredCarouselController` owns scroll/controller/activity mechanics;
- `CenterSnapScrollPhysics` owns the unchanged target simulation;
- `DashboardMotionKernel` owns dashboard semantic motion;
- `DashboardPresentationController` owns prepared-frame selection/coalescing;
- `DashboardVisibleFrameStore` owns atomic visible snapshot ordering;
- `DashboardDataRuntime` owns all index acquisition;
- `DashboardLogBoxViewport` owns the stable vertical viewport.

Instrumentation that describes generic carousel gestures, ScrollMetrics and
activity transitions belongs at the existing centered-carousel boundary as an
optional neutral observer. Dashboard density/frame fields belong in a
dashboard flight recorder. No second gesture, physics, selection, cache or
presentation engine will be introduced.

## Phase-one diagnostic contract

`DashboardRailFlightRecorder` is a typed, fixed-capacity recorder enabled only
by an injected profile/test configuration. Disabled mode returns before clock,
identity or event allocation work. Enabled mode stores compact typed samples;
string serialization occurs only after a fling settles.

The neutral carousel observer emits boundaries, not per-pixel logs:

- pointer down and aggregated move samples;
- pointer release summary;
- ballistic input plus stable geometry/identity snapshot;
- real ScrollMetrics changes;
- observed activity/attach/detach transitions;
- settle endpoint.

Dashboard presentation contributes:

- prepared frame density/digest at crossing;
- presentation apply start/end stopwatch values;
- fixed counter snapshots before and after notification/build/layout/paint;
- current display-frame number and UI frame timings.

The recorder never calls repository/index APIs, never notifies a widget and
never changes motion state.

## Deterministic harness

The profile harness uses one explicit pointer-event script rather than relying
only on `tester.fling`. Every repetition fixes start pixels/index, pointer-down
coordinate, move offsets, timestamps/cadence and release. The same trace is
applied to immutable fixture indexes that differ only in prepared frame
density.

Each required fixture runs at least 30 times. The report compares paired
medians/p95 and every endpoint, and fails independently on velocity,
ballistic-input, interruption, metrics or endpoint tolerance.

## Causal selection rule

The implementation follows one sequential rule:

1. find the earliest field that differs between paired traces;
2. prove its overlap with a concrete presentation listener/build/layout/paint
   region;
3. write a failing regression test at that boundary;
4. remove that coupling without changing gesture or physics behavior;
5. repeat the identical traces until the divergence and downstream endpoint
   difference disappear.

If physical endpoints already match and only render timing differs, the work
is render isolation. The physics result remains untouched.

## Allowed targeted presentation shape

The atomic `DashboardVisibleFrame` remains the correctness source. Its prepared
amount, count and LogBox values may be exposed through identity-based leaf
lanes so each consumer observes only its constant-time token/reference. A lane
publish is a pointer/identifier replacement; it cannot walk preview rows or
copy collections.

The rail consumes only catalog/index/controller/position/physics state. It
must not listen to visible amount/count/LogBox contents.

If measurement identifies LogBox structural work, the existing stable lazy
viewport will consume a preflattened immutable viewport-item description with
stable item IDs and a single stable lazy delegate. This changes presentation
description only, not the visual rows, amount/count semantics, paging, rail
geometry or prepared-index acquisition. Widget instances are never cached.

If measurement identifies lane fanout but not LogBox structure, the smaller
identity-based leaf-lane split is sufficient. The causal test decides the
minimum code area; no speculative dashboard rewrite is allowed.

## Geometry contract

Rail bounds, gesture surface, item extent, min/max scroll extent, padding,
transform, DPR and parent constraints are sampled before/during/after every
trace. A prepared frame change cannot update these values. LogBox remains in
its fixed positioned bounds and cannot participate in rail constraint
calculation.

No custom ScrollPosition is introduced. Existing framework ScrollPosition
identity is observed without replacing its implementation. Any metric/pixel
correction is inferred from real notifications and before/after snapshots; the
diagnostic layer does not intercept or alter `correctPixels`.

## Verification

The release gate is
`docs/superpowers/checklists/2026-08-06-dashboard-rail-presentation-isolation.md`.
All tests are deterministic unit, widget, architecture or integration tests;
there are no golden tests. Final profile output is machine-readable and keeps
emulator evidence separate from physical-device validation.
