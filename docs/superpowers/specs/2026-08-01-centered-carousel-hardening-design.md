# Centered Carousel Hardening Design

## Goal

Keep the current dashboard geometry while making the shared carousel engine
physically velocity-proportional, effectively unbounded for generated values,
strictly single-selected, clipped to five complete slots, and reusable for
cyclic avatar data.

## Architecture

`CenteredCarousel<T>` remains the only scroll renderer. It accepts either the
legacy bounded `items` list or a `CenteredCarouselDataSource<T>`, while the
controller owns physical index, logical index, virtual anchoring, rebase,
preview/settled callbacks, haptic ticks, and selection state. Physics owns
friction projection, velocity-to-step caps, attenuated spring velocity, and
speed-dependent spring stiffness. Adapters only map logical values to domain
items and render metrics.

Generated and cyclic modes use a 200001-slot physical belt anchored at 100000;
generated years map `anchorYear + logicalIndex`, and cyclic lists normalize the
logical index modulo their finite length. Rebase runs only after scrolling ends
and preserves the logical value without callbacks or haptics.

## Visual policy

The rail viewport is centered and sized to five fixed item slots when the
viewport permits it, with hard clipping. The existing `itemExtent`, horizontal
gap, rail top, search, summary, and bottom navigation geometry remain intact.
Scale is piecewise and continuous: 1.00 at distance 0, 0.84 at distance 1,
0.72 at distance 2, and 0.62 at distance 3 or farther. Opacity follows
1.00, 0.82, 0.64, and 0.48 at the same distances. Only the nearest physical
slot receives selected styling.

All non-circular controls use the shared fixed 18 logical pixel rounded-box
radius. The existing reference action height is promoted to the shared
selector-height token so the income/expense controls and time tiles have one
height source without shifting the dashboard's upper layout.

## Verification

Unit tests cover data sources, velocity target calculation, snap velocity,
piecewise metrics, controller callbacks/haptics/rebase, and bounds. Widget
tests cover cyclic/generated rendering, five complete clipped slots, tap/drag/
fling/resize behavior, one highlighted item, and shared selector dimensions.
Golden tests are intentionally not run or added per the current instruction.

