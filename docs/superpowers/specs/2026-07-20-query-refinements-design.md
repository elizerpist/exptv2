# Q1A Query Refinements Design

## Goal

Replace the current single amount-threshold refinement in the Q1A query menu prototype with a compact refinement panel that supports recurring filters, weekday/weekend filters, min/max amount range, and outlier filtering.

## Context

The active prototype is `docs/prototypes/color_lab.html`, Q row first screen `data-screen="alt-query-menu-category-vendor-hierarchy"`. Its `Szűrőfinomítás` section currently renders one selected `query-threshold-editor` with a single numeric value and slider. The new design keeps refinements in the same section, below the category-vendor hierarchy and above the footer.

## Requirements

| ID | Source | Requirement | Acceptance |
| --- | --- | --- | --- |
| QR-001 | User: `ismétlődő ki be` | Add an `Ismétlődő` refinement control | The panel exposes a three-state control: `Mind`, `Ismétlődő`, `Nem ismétlődő`; selecting either specific state counts as one active refinement. |
| QR-002 | User: `hétvége hétköznao` | Add a day-type refinement control | The panel exposes a three-state control: `Mind`, `Hétköznap`, `Hétvége`; selecting either specific state counts as one active refinement. |
| QR-003 | User: `min max range` | Replace the single threshold with min/max range | The panel renders two numeric inputs labeled `Min` and `Max` plus a range-like visual/slider surface; default example is `5 000 Ft - 50 000 Ft`. |
| QR-004 | User: `kiugró tételek` | Add an outlier toggle | The panel renders `Kiugró tételek` as an independent on/off control; enabled state counts as one active refinement. |
| QR-005 | Existing Q1A model | Keep refinements part of saved snapshots and footer count | Refinement state remains inside the Q1A route, uses `data-query-filter="refinement"` markers, updates `data-query-section-count="refinements"`, and contributes to `data-query-active-count`. |
| QR-006 | Existing compact Q1A UI | Do not add a nested page or modal | The section body is a compact vertical panel replacing the single threshold card, using existing query section/card visual language. |

## Layout

The `Szűrőfinomítás` body becomes a compact four-part panel:

1. Amount range row: min input, max input, and a muted range track below them.
2. Outlier toggle row: `Kiugró tételek` with a right-side `query-check`.
3. Day type segmented row: `Mind`, `Hétköznap`, `Hétvége`.
4. Recurring segmented row: `Mind`, `Ismétlődő`, `Nem ismétlődő`.

The section header status should summarize active refinements as a count, for example `4 feltétel`. Compact text chips inside the panel may show the active values, but the header should remain short.

## Runtime Model

Each control is route-scoped to Q1A. The runtime updates selected classes, `aria-pressed`, and active counts without adding global state outside the existing query menu prototype helpers. The amount range inputs and range visual stay synchronized; if the user enters `Min` greater than `Max`, the prototype clamps the edited value to the other bound.

## Testing

Static tests in `docs/prototypes/color_lab_static_test.js` should verify:

- the old single-threshold-only UI is gone from Q1A;
- min/max range controls and range visual exist;
- day type and recurring segmented controls exist with the exact labels above;
- outlier toggle exists and uses refinement data attributes;
- runtime functions bind the new controls and update refinement counts;
- the Q1A screen still omits the removed old Q1 screen.
