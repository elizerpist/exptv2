# Selectable Header and direction chrome

## Approved design

The current `FluviGlobalAppearance` remains the one dashboard-session
appearance authority. This feature adds only presentation fields to it:

- `FluviDirectionControlStyle`: legacy `splitButtons` or `slidingRail`;
- `FluviCollapseHandleStyle`: `standalone`, `headerNotch`, or
  `headerTranslucentPill`;
- active and inactive rail-label tones, with no inactive-white enum member;
- `showsHeaderModeLabelAboveValue`, defaulting to false.

No persistence, Query, financial, repository, controller, carousel, or
gesture-state owner is introduced.

## Architecture card

| Concern | Owner | Consumers | Contract |
| --- | --- | --- | --- |
| Appearance choices | `FluviGlobalAppearance` through `DashboardHeaderVisualController` | tuner, CoreDashboard, Header frames | immutable session state; each setter preserves unrelated choices |
| Lower-handle footprint | `DashboardGeometryResolver` | CoreDashboard layout | integrated styles have zero lower footprint; LogBox header moves up by the canonical `handleHeight` |
| Expansion input | existing controller plus `DashboardCollapseHandle` | standalone and integrated chrome | one tap/vertical-drag path, no style-specific controller |
| Sliding rail | `TransactionDirectionToggle` | action row only | one moving pill samples a gradient whose shader rect is the full rail, not the pill |
| Header value label | Header visual frame + shared trend layout token | Balance and Mind headers/charts | label consumes a shared internal chart/value reserve without changing outer Header dimensions |

## Presentation details

The two integrated handle variants are Header-bottom overlays with a centered,
local hit target. The notch is Header material chrome; the pill is a visibly
separate translucent capsule. Neither reserves the former lower 20px lane.

The sliding rail preserves action-row bounds, semantic direction buttons,
existing wallet/bag ownership, and drag forwarding. Its active RRect travels
between fixed halves. A pure rail-geometry object exposes the full gradient
rect and animated pill rect so the fixed-coordinate contract is testable.

The optional Balance/Mind label sits above the main value at the existing
left detail anchor. A shared Header layout token moves the value and chart
downward and reduces the chart plot height by the same reserve. Budget and
outer Header geometry are unchanged.

## Acceptance

The four choices are independent, start in legacy-compatible states, have
stable tuner keys, and are covered by state, geometry, interaction, widget,
and chart-layout tests. The final build must be from the exact application
commit; physical appearance and installation remain user validation.
