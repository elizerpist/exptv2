# Balance Money-Flow Portal Design

## Goal

Add a fourth, Balance-specific signature to the standalone portal test header. It uses the A1 turquoise–pink visual language, but its slider represents the income/expense money-flow ratio instead of selecting a color-window position. Add three Balance-only energy-field alternatives for comparison while leaving every existing signature, animation mode, and accepted touch interaction unchanged.

## Scope

- HTML prototype only: `docs/prototypes/color_lab.html`.
- Pure portal field math and schemas: `docs/prototypes/color_lab_portal_energy.js`.
- Regression coverage: `docs/prototypes/color_lab_portal_energy_test.js` and `docs/prototypes/color_lab_static_test.js`.
- The standalone test header receives the feature; existing B/C/D screen rows and Flutter code are out of scope.
- Existing `Traffic`, `Limit`, and `Cool` signature behavior stays byte-for-byte compatible unless a shared helper must be extended without changing its outputs.
- Existing `Statikus A/B`, `Kettős árapály`, `Mágneses membrán`, `Lélegző lencse`, and `Celluláris mező` behavior stays unchanged.
- The accepted touch bloom, trail size, colors, decay, drag capture, ripple, and interaction-opacity behavior stays unchanged.

## Approved palette

The Balance signature uses five ordered stops derived from the A1 turquoise–pink header:

1. darker turquoise `#49cfc5`;
2. lighter A1 turquoise `#8defe5`;
3. whitish/light-pink neutral seam `#f8e8f3`;
4. A1 pink `#f7b2f5`;
5. light purple `#d8b4fe`.

The order is always left-to-right and semantic:

- turquoise side = income;
- pink/purple side = expense;
- whitish/light-pink seam = the current income/expense split.

The implementation uses dedicated, named Balance palette constants so the five colors can be verified and adjusted without affecting the other three signatures.

## Money-flow ratio model

The fourth slider is labeled `Money flow` and its visible value is formatted as `income–expense`, for example:

- slider 100 → `100–0`;
- slider 50 → `50–50`;
- slider 0 → `0–100`.

The semantic slider value is the income percentage. Expense is always `100 - income`.

Both semantic colors must remain visible at all values. The rendered seam therefore maps the semantic 0–100 input into a visual 8–92% interval:

```text
visualSplit = 8 + (incomePercent / 100) * 84
```

This gives:

- `0–100`: 8% turquoise / 92% pink-purple;
- `50–50`: 50% turquoise / 50% pink-purple;
- `100–0`: 92% turquoise / 8% pink-purple.

The five-stop spatial gradient is generated relative to `visualSplit`. The seam stays centered on that point, turquoise stops remain to its left, and pink/purple stops remain to its right. Stops are clamped and monotonically ordered so no ratio or animation can reverse the two semantic sides.

Unlike the existing signatures, Money flow has no color-window-size meaning. Its row retains the compact four-column geometry but uses a synchronized numeric ratio input in the final column instead of a window-size input. Range and numeric input update each other and always show the same income percentage.

## Balance-specific animation contract

The three new modes are appended to the existing dropdown and are available for any currently selected signature, but they activate Balance rendering semantics only when `Money flow` is the active signature. Selecting one of them activates the Money-flow signature if needed, preventing a misleading Traffic/Limit/Cool palette from being shown under a Balance-only field name.

All three modes share these invariants:

- the time-averaged split remains anchored to `visualSplit`;
- local deformation has zero or compensated mean so it does not silently change the selected financial ratio;
- turquoise always owns the left boundary and pink/purple always owns the right boundary;
- local lobes may cross the seam, but neither side can cross the opposite outer edge or topologically exchange sides;
- luminance/chroma motion is local and bounded; there is no gray veil, full-header flash, rotation, or missing-content seam;
- animation strength zero renders the exact static five-stop Money-flow gradient;
- every meaningful parameter has a numbered range slider and synchronized numeric input in the existing scrollable controls viewport.

### 1. Balance membrane

Recommended default Balance animation. A vertically varying membrane moves around the selected split. Several low-frequency nodes deform the boundary, creating a calm energy-surface motion. The deformation is normalized around the ratio anchor.

Primary controls include strength, speed, seam softness, node amplitudes/phases, vertical wavelength, local warp, tension, highlight strength, render scale, and frame interval.

### 2. Balance counterflow

Alternating turquoise and pink/purple lobes push locally through the seam at different vertical positions. A turquoise intrusion is compensated by a pink intrusion so the selected overall ratio remains legible. The result resembles slow interlocking yin-yang currents without allowing the semantic sides to swap.

Primary controls include intrusion depth, lobe count, lobe radius/ellipse, counterphase, vertical drift, compensation, seam softness, local warp, highlight strength, render scale, and frame interval.

### 3. Balance charges

The seam moves only subtly. Independent darker/lighter charge pockets drift inside each side, making both reservoirs feel alive while preserving the ratio silhouette most strongly. Charges modulate the appropriate side's turquoise or pink/purple palette segment and cannot inject the opposite semantic color.

Primary controls include seam drift, charge count, charge size, wander, luminance range, chroma range, side phase offset, morphing, highlight strength, render scale, and frame interval.

## Rendering architecture

The pure renderer gains a Balance-field contract alongside the existing two-endpoint `sampleField` path:

- a pure ratio-to-visual-split helper;
- a pure five-stop Money-flow palette sampler;
- one deterministic sampler per new Balance mode;
- a result that exposes the deformed semantic split/side coordinate plus bounded local light/chroma data.

The browser canvas reads the active signature and ratio from the test header. Existing modes continue down the current two-endpoint renderer unchanged. Balance modes use the five-stop sampler and the same canvas lifecycle, visibility checks, reduced-motion handling, performance controls, and requestAnimationFrame loop.

No second canvas or animation loop is introduced.

## UI behavior

- The signature panel contains four rows: `Traffic`, `Limit`, `Cool`, `Money flow`.
- The latest changed signature remains last-writer-wins for the test header.
- `Money flow` displays `50–50` initially and has a synchronized manual income-percent input.
- The dropdown gains `Balance membrán`, `Balance ellenáram`, and `Balance töltések` after the existing modes.
- Only the active mode's controls are rendered.
- Switching away and back preserves that mode's control values.
- Active-mode reset restores only that mode's settings; it does not change ratio or touch opacity.
- Slider/control containers remain vertically scrollable on mobile. Only the header drag surface captures swipe.

## Verification

Automated verification must cover:

- exact mode order and labels, with all five existing entries unchanged and three new entries appended;
- four signature rows and Money-flow range/manual-input synchronization;
- ratio formatting and exact 8–92 visual mapping at 0, 50, and 100;
- monotonic five-stop ordering at extreme and intermediate ratios;
- deterministic, bounded output from every new sampler;
- side ownership at both outer edges for every sampled phase and ratio;
- no semantic side swap under maximum animation controls;
- strength zero matching the static five-stop Money-flow reference;
- every exposed control measurably affecting its intended field output;
- existing portal unit/static tests remaining green;
- inline and external JavaScript parse checks;
- HTTP smoke verification of the fourth signature and three dropdown entries.

Visual completion additionally requires Android-browser screenshots at `0–100`, `50–50`, and `100–0`, plus one screenshot of each new animated mode. Direct mobile inspection must confirm the 8% minority band, readable ratio, stable left/right semantics, internal control scrolling, and unchanged touch trail.

Until that visual evidence exists, UI-facing checklist items remain `PARTIAL` even when automated checks pass.
