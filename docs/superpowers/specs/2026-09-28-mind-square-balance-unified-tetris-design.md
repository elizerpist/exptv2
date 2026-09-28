# Mind square 4×3 and Balance unified/Tetris design

## Authority and references

The current local branch is authoritative for ownership and existing behavior.
The user explicitly approved implementation through the three detailed task
specifications. The visual source for the four-section scaffold is the opened
Android screenshot at
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260928-082420.png`.
The written 60/40, 70/30 and 50/50 allocation contract is authoritative over
any screenshot ambiguity.

## Ownership / centralization card

| Concern | Owner | Writes | Must not own |
| --- | --- | --- | --- |
| Mind four-column style | `MindYearHeatmapPresentationSettings` and its controller | setting revision only | frame, Query, palette inputs, score |
| Mind annual geometry | `MindYearHeatmapFourColumnFit` | pure layout values | post-frame measurement or data access |
| Balance outer/body style | `BalancePresentationSettings` and its controller | setting revision only | selected financial data, Query, projection |
| Four-section allocation | `BalanceFourSectionLayout.resolve` | pure `Rect` slots | widget-local percentage duplicates |
| Header/body seam | existing `DashboardHeaderContentSeamShape` / Budget visual language | resolved physical chrome only | a new Balance-specific seam algorithm |

## Mind design

`fillHeight` preserves the existing direct 4×3 geometry: fixed horizontal
cell width and height calculated from the annual viewport. `squareCells`
sets `cellHeight == cellWidth`, retains the upper-grid anchor, and gives the
already existing direct layout selector the calculated lower free region. If
that region cannot hold its own height plus 8 logical pixels at either side,
the same selector appears in the established title row. Painter and hit target
use the same resolved width/height model. 3×4 has no footer rows; 2×6 retains
only Scope.

## Balance design

The default remains separate Balance cards. At the fully expanded unified
endpoint, a Balance-local parent surface spans Header top through effective
mode-content bottom. Its outer border/shadow are sole owners. The Header and
body use `DashboardHeaderContentSeamShape`; Header chrome disables its
independent depth/border at that endpoint. A shallow live Header color bridge
is painted inside the parent. The existing carousel and detail children retain
all business/data/controller ownership; only redundant outer content chrome is
suppressed while unified.

The subordinate unified body preference is available only while unified. Its
`fourSectionTetris` state replaces the carousel/detail/dots with pure neutral
placeholders. The slots are allocated from the Header-excluded body rect, then
visibly inset with a single shared gutter convention. It never reads Balance
financial projections, and leaving it restores existing selected-topic state.

## Boundaries and invariants

All added settings are render-only and revise only their current settings
notifier. No repository reads, Query changes, prepared-index projections,
Summary changes, slider changes, or new animation controllers are permitted.
The global geometry resolver, BottomNav, Direction, Summary, count row, and
carousel engine remain unchanged. The final package needs focused tests,
format, diff check, analyzer, source-reference reinspection, a pushed commit,
and the successful online human APK.
