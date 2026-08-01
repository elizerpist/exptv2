# Fluvi Cascaded Header Reveal Design

## Goal

Make the split dashboard's two white header cards reveal as one cascaded,
layered motion: the upper card keeps its current motion profile, while the
lower card starts behind it, then follows the same position, width, opacity,
and scale language with a staggered master progress.

## Accepted reference and current source

- Android references inspected:
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260801-111338.png`
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260801-111340.png`
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260801-111342.png`
- Existing motion source:
  - `lib/core/design/dashboard_geometry_resolver.dart`
  - `lib/core/motion/dashboard_motion_host.dart`
  - `lib/features/dashboard/presentation/core_dashboard.dart`
- Existing upper-card reference profile:
  - expanded top `subheaderOneTop`;
  - collapsed shift `-18.0`;
  - collapsed scale `0.90`;
  - opacity driven by the same dashboard collapse progress.
- Existing expanded endpoints remain authoritative and unchanged.

## Architecture

`HeaderCascadeMotion` is a pure shared calculator in the design layer. It
accepts one normalized `masterProgress` (`0.0` collapsed, `1.0` expanded) and
immutable geometry, and returns complete `CascadedCardMotion` values for the
upper and lower layers. `DashboardGeometryResolver` owns the conversion from
the existing collapse controller progress to this reveal progress and places
the result in `DashboardLayoutFrame`. `CoreDashboard` only paints the supplied
motions.

The split mode Stack paints `lower`, then `upper`, then `header`. The unified
mode continues using its existing single-card rendering path, so the cascade
does not alter that mode's layout contract.

## Motion contract

- upper interval: `0.00..0.72`, `Curves.easeOutCubic`;
- lower interval: `0.18..1.00`, `Curves.easeOutCubic`;
- lower hidden overlap: `32.0` logical pixels;
- lower nested inset: `18.0` logical pixels;
- lower collapsed top: `upperTop + upperHeight - lowerHiddenOverlap`;
- lower width grows through animated inset plus the existing subtle scale;
- all opacity, position, inset, and scale values are continuous functions of
  the same master progress;
- progress reversal reuses the same calculation in reverse;
- expanded top, left, right, width, height, radius, and downstream layout stay
  unchanged.

## Verification

Golden tests are intentionally omitted by user request. The calculator gets
unit coverage for intervals, monotonic position/inset/opacity, exact endpoints,
and reverse continuity. Dashboard geometry and widget tests verify the supplied
motions, the lower card's movement, and the split Stack's semantic layer
presence. Static inspection verifies there is one master reveal progress and no
independent lower-card animation controller.

## Implementation notes

1. The old lower card was effectively opacity-only because it used a static
   `zone2Bounds` position and only a small independent shift/scale while its
   opacity was staged. It had no relation to the moving upper card's bottom
   edge and no animated nested horizontal inset.
2. The upper uses the `0.00..0.72` interval; the lower uses `0.18..1.00`.
3. `lowerRevealAnchorTop` is calculated as
   `upperTop + upperHeight - lowerHiddenOverlap`.
4. `lowerHiddenOverlap` is `32.0` logical pixels.
5. `lowerNestedInset` is `18.0` logical pixels.
6. The split Stack paints `lower`, then `upper`, then `header`, so each front
   surface masks the hidden portion of the layer behind it.
7. Unit tests cover the motion states and monotonic/reversible math; dashboard
   widget tests cover the rendered collapsed lower rect. Golden tests were
   intentionally omitted.
