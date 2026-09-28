# Stability, Mind Year, and Budget Surface Design

## Approved execution basis

The user supplied the complete acceptance contract and explicitly instructed
uninterrupted execution. This document records that approved design rather than
introducing a separate product decision.

## Boundaries

Cashflow Stability uses a renderer-local two-state view. Its immutable Balance
projection remains the only source of observations, median, deviation, and
band values. Balance membership is a typed presentation preference in the
existing Balance settings/controller; the core surface resolves the filtered
canonical card list before controller/data-source/indicator mapping.

Mind's four-column resolver becomes the single source for separate horizontal
and vertical heatmap-cell extents. Only direct 4×3 passes a vertical extent;
the 3×4 and 2×6 paths retain square-cell compatibility. Painter, MonthGroup
height, and hit geometry consume the same value object/contract.

Budget unified content reuses one neutral Header/content seamless-shape
mechanism extracted from the existing Mind surface. `BudgetContentLayout`
continues to be the only setting: `unifiedCard` selects the seamless shell,
while `split` retains separate surfaces.

## Reference constraint

`stabil1.png` and `stabil2.png` are mandatory visual evidence. They are absent
from the required path in this checkout, so no guessed Stability visual
renderer will be implemented. The exact reference-matching Stability items
remain blocked until the images are supplied at their prescribed paths.
