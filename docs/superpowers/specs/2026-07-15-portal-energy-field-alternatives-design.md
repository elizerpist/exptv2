# Portal Energy Field Alternatives Design

**Date:** 2026-07-15

**Approved direction:** User instructions ending with `ok, legyen több ötlet is, több alternatíva, mindegyiknél maximális kontroll sliderrel, a slider container scrollozható legyen` and final approval `ok`.

**Prototype:** `docs/prototypes/color_lab.html`

**Regression checks:** `docs/prototypes/color_lab_static_test.js`

## Goal

Rebuild the standalone Mind portal test header from a clean, color-faithful baseline. The portal represents a living energy field: color A starts on the left, color B starts on the right, and the field changes their geometry and visible share without changing their scale-selected color identity. The user can compare a precise static baseline with four distinct animated alternatives and tune every meaningful component of the active alternative.

## Root cause being removed

The current implementation applies a global rotation transform to the shared sampling coordinates before the base gradient, water, level, legacy mesh, and touch-ripple fields are evaluated. The modes therefore do not own independent geometry, and changing a global transform can suppress, wrap, flatten, or visually replace the effect a mode is meant to expose. The canvas also covers the CSS reference gradient, so the supposed original-gradient mode is no longer a reliable color reference.

The replacement has no shared rotation system, no level mode, no legacy mesh/plume mode, and no blended stack of old experiments. Every animated alternative maps its own scalar field directly to the same A/B endpoints. A static CSS A-to-B gradient remains the reference beneath the canvas and becomes fully visible whenever the static mode is selected or animation strength is zero.

## Non-negotiable behavior

- Preserve the accepted touch bloom, trail dots, pointer-following behavior, release fade, touch colors, touch radius, and interaction-opacity behavior.
- Do not change the portal drag surface: dragging on the header controls the touch effect and does not scroll the page.
- Do not add rotation, oscillation-angle controls, side-view level bands, flame-like repeated plumes, or a gray/white veil.
- Do not alter the three original mode-specific header sliders outside the standalone test header.
- The standalone header remains last-writer-wins: the last local Traffic, Limit, or Cool color slider moved selects the portal palette.
- The selected palette determines exact A and B endpoint colors. Animation changes only the field geometry, transition shape, and the visible A/B share.
- Setting animation strength to zero must produce the same pixels as the static A/B reference, apart from the existing glass/header decorations and an active touch effect.

## Visual and DOM structure

The standalone test area is ordered as follows:

1. Portal test header.
2. Local palette panel with exactly three color sliders: Traffic, Limit, and Cool.
3. Interaction-opacity control for the existing touch effect.
4. Mode selector with `Statikus A/B`, `Kettős árapály`, `Mágneses membrán`, `Lélegző lencse`, and `Celluláris mező`.
5. One scrollable animation-control container. It is hidden in static mode and shows only the active animated mode's controls.

The old header-background opacity, rotation panel, circular rotation pad, legacy controls, level controls, and old animation preset controls are removed.

## Color model

Each local palette slider samples two colors at a fixed symmetric distance from its current value:

- `A = palette(center - 14)`
- `B = palette(center + 14)`

The endpoints are clamped to the palette range. A and B are stored as explicit portal CSS variables and as RGB values used by the canvas. There is no independent center color in the new engine. The transition color is direct sRGB interpolation between A and B, which keeps endpoints identical to the selected palette shades.

The static reference is `linear-gradient(90deg, A 0%, B 100%)`. Animated modes compute a scalar `mix` in the inclusive range `0..1` for every pixel and render `mix(A, B, mix)`. Optional energy lighting is a bounded luminance modulation applied after interpolation; at zero lighting it is bit-for-bit neutral and it never introduces a white overlay.

## Rendering architecture

### Layer 0: static reference

The header pseudo-element renders the exact static A/B gradient. It is never animated. The canvas is transparent or hidden in static mode and when animation strength is zero.

### Layer 1: selected energy field

One low-resolution canvas renders only the active idle-energy alternative. It has a single state object with:

- active mode;
- per-mode settings retained while switching modes;
- accumulated mode time;
- resize-aware image buffer;
- the existing ripple list needed by the accepted touch refraction hook.

There is no global coordinate transform. Each renderer receives normalized `x`, `y`, time, A, B, and its own settings and returns a bounded A/B mix plus a bounded energy-light value.

### Layer 2: accepted touch interaction

The existing touch bloom and trail DOM/CSS remain above the canvas. Existing pointer handlers, trail spawning cadence, colors, fade timing, size, and release behavior are not redesigned. The existing background-refraction ripple hook may feed the new renderer through the same ripple state, but its visible timing and strength defaults stay unchanged.

## Modes

### 1. Statikus A/B

The canvas is not painted and is visually hidden. The exact static CSS gradient is visible. Only palette selection and interaction opacity are active. This is both a user-facing mode and the reference used for regression comparison.

### 2. Kettős árapály

Two broad, reciprocal energy masses represent A and B. Their centers travel on slow, phase-shifted paths without rotating the entire coordinate field. Each mass can enter the opposite side, retreat, and temporarily reach the far edge. A low-frequency deformation changes the lobe outlines so the motion reads as a coherent tide rather than two moving circles.

The final scalar combines:

- a left-to-right base ramp;
- A and B lobe influence;
- a slowly oscillating global A/B ratio;
- broad domain deformation;
- optional bounded energy lighting.

### 3. Mágneses membrán

A and B are separated by one broad flexible membrane. Three vertically distributed control nodes move at different phases and pull the transition boundary left or right. A second, lower-amplitude wave prevents a repeated sine profile. The result resembles two charged fields pressing into each other, with a continuous curved boundary rather than discrete blobs or stripes.

The final scalar combines:

- a left-to-right signed distance;
- three node displacements interpolated over Y;
- primary and secondary long waves;
- slow node wandering;
- boundary tension and softness;
- optional bounded energy lighting.

### 4. Lélegző lencse

An off-center elliptic pressure lens bends the A/B transition. The lens center wanders slowly, its radii breathe independently, and a smaller satellite pressure field can pull the transition in a second direction. The base left/right identity remains visible around the lens.

The final scalar combines:

- a left-to-right base ramp;
- signed elliptic distance;
- lens pressure and refraction strength;
- independent X/Y breathing;
- satellite-field influence;
- optional bounded energy lighting.

### 5. Celluláris mező

Three to seven broad cells move through a very low-frequency flow field. Cells are assigned alternating A/B polarity and merge through soft metaball influence. Their morphology changes slowly; there are no narrow repeated noise bands, fast vertical streaks, or flame-shaped plumes.

The final scalar combines:

- a left-to-right base ramp;
- weighted positive and negative cell pressure;
- slow cell advection;
- low-frequency curl and morphology noise;
- a soft merge threshold;
- optional bounded energy lighting.

## Control model

Every animated mode has a complete settings object, a reset preset, and a numbered row for every exposed value. Each row contains a range slider, a synchronized numeric input, its exact minimum/maximum/step, and a short Hungarian label. Switching modes preserves settings already changed in the other modes. Reset affects only the active mode and never changes palette selection or interaction opacity.

### Shared controls in every animated mode

| Key | Label | Range | Default | Purpose |
|---|---|---:|---:|---|
| `strength` | Animáció erő | 0..1 / 0.01 | 0.82 | Crossfades exactly from static reference to animated field. |
| `speed` | Sebesség | 0..2 / 0.01 | 0.42 | Scales only the future mode time; changing it does not jump phase. |
| `bias` | A/B alaparány | -0.35..0.35 / 0.01 | 0 | Moves the average transition without changing A or B. |
| `ratioSwing` | Aránykilengés | 0..0.35 / 0.01 | 0.12 | Maximum automatic A/B share change. |
| `ratioSpeed` | Aránysebesség | 0..1 / 0.01 | 0.18 | Speed of the non-drifting ratio cycle. |
| `fieldScale` | Mezőméret | 0.5..2 / 0.01 | 1 | Spatial scale of the active field. |
| `morphAmount` | Morfológia | 0..1 / 0.01 | 0.34 | Strength of slow shape change. |
| `morphSpeed` | Morfológia seb. | 0..1 / 0.01 | 0.16 | Rate of shape change, independent of travel speed. |
| `softness` | Határ puhaság | 0.02..0.48 / 0.01 | 0.22 | Width of the A/B transition. |
| `detail` | Felületi részlet | 0..0.5 / 0.01 | 0.10 | Adds only broad low-frequency detail. |
| `pulseAmount` | Energiaimpulzus | 0..0.35 / 0.01 | 0.08 | Bounded luminance breathing. |
| `pulseSpeed` | Impulzus seb. | 0..1 / 0.01 | 0.12 | Energy-light pulse rate. |
| `lightAmount` | Fénykiemelés | 0..0.25 / 0.01 | 0.05 | Boundary-local luminance detail; zero is neutral. |
| `renderScale` | Render minőség | 0.35..1 / 0.05 | 0.60 | Canvas resolution relative to header size. |
| `frameMs` | Render lépés | 16..100 / 1 | 42 | Minimum milliseconds between canvas frames. |

### Kettős árapály-specific controls

| Key | Label | Range | Default |
|---|---|---:|---:|
| `wanderX` | Vándorlás X | 0..0.48 / 0.01 | 0.28 |
| `wanderY` | Vándorlás Y | 0..0.38 / 0.01 | 0.18 |
| `intrusion` | Behatolás | 0..0.65 / 0.01 | 0.34 |
| `separation` | Mezőtávolság | 0..0.80 / 0.01 | 0.42 |
| `lobeARadius` | A mező sugár | 0.12..0.75 / 0.01 | 0.42 |
| `lobeBRadius` | B mező sugár | 0.12..0.75 / 0.01 | 0.40 |
| `lobeAEllipse` | A nyújtás | 0.50..2 / 0.01 | 0.95 |
| `lobeBEllipse` | B nyújtás | 0.50..2 / 0.01 | 1.05 |
| `phaseOffset` | Ellenfázis | 0..360 / 1 | 180 |
| `counterFlow` | Visszaáramlás | 0..1 / 0.01 | 0.72 |
| `warpAmount` | Mezőtorzítás | 0..0.50 / 0.01 | 0.16 |
| `warpScale` | Torzítás méret | 0.40..3 / 0.01 | 1.10 |
| `warpSpeed` | Torzítás seb. | 0..1 / 0.01 | 0.14 |

### Mágneses membrán-specific controls

| Key | Label | Range | Default |
|---|---|---:|---:|
| `nodeTop` | Felső pólus | -0.50..0.50 / 0.01 | 0.14 |
| `nodeMiddle` | Középső pólus | -0.50..0.50 / 0.01 | -0.08 |
| `nodeBottom` | Alsó pólus | -0.50..0.50 / 0.01 | 0.12 |
| `nodeWander` | Pólusvándorlás | 0..0.40 / 0.01 | 0.16 |
| `nodePhaseSpread` | Pólusfázis | 0..360 / 1 | 120 |
| `primaryAmplitude` | Fő hullámerő | 0..0.45 / 0.01 | 0.18 |
| `primaryWavelength` | Fő hullámhossz | 0.35..3 / 0.01 | 1.25 |
| `primarySpeed` | Fő hullámseb. | 0..1 / 0.01 | 0.16 |
| `secondaryAmplitude` | Mellékhullám-erő | 0..0.30 / 0.01 | 0.08 |
| `secondaryWavelength` | Mellékhullámhossz | 0.35..4 / 0.01 | 2.10 |
| `secondarySpeed` | Mellékhullám-seb. | 0..1 / 0.01 | 0.09 |
| `skew` | Membrándőlés | -0.50..0.50 / 0.01 | 0.08 |
| `tension` | Membránfeszülés | 0..1 / 0.01 | 0.62 |
| `warpAmount` | Felülettorzítás | 0..0.35 / 0.01 | 0.09 |
| `warpSpeed` | Torzítás seb. | 0..1 / 0.01 | 0.12 |

### Lélegző lencse-specific controls

| Key | Label | Range | Default |
|---|---|---:|---:|
| `centerX` | Lencseközép X | 0.10..0.90 / 0.01 | 0.55 |
| `centerY` | Lencseközép Y | 0.10..0.90 / 0.01 | 0.48 |
| `wanderX` | Középvándorlás X | 0..0.40 / 0.01 | 0.18 |
| `wanderY` | Középvándorlás Y | 0..0.40 / 0.01 | 0.14 |
| `radiusX` | Lencsesugár X | 0.08..0.80 / 0.01 | 0.34 |
| `radiusY` | Lencsesugár Y | 0.08..1 / 0.01 | 0.46 |
| `breathX` | Légzés X | 0..0.40 / 0.01 | 0.16 |
| `breathY` | Légzés Y | 0..0.40 / 0.01 | 0.12 |
| `breathSpeed` | Légzés seb. | 0..1 / 0.01 | 0.18 |
| `pressure` | Lencsenyomás | -1..1 / 0.01 | 0.48 |
| `refraction` | Mezőtörés | 0..0.60 / 0.01 | 0.20 |
| `edgeFalloff` | Peremlecsengés | 0.02..0.50 / 0.01 | 0.18 |
| `satelliteAmount` | Mellékmező erő | -1..1 / 0.01 | 0.22 |
| `satelliteRadius` | Mellékmező sugár | 0.05..0.50 / 0.01 | 0.18 |
| `satelliteDistance` | Mellékmező táv | 0..0.75 / 0.01 | 0.36 |
| `satellitePhase` | Mellékmező fázis | 0..360 / 1 | 140 |

### Celluláris mező-specific controls

| Key | Label | Range | Default |
|---|---|---:|---:|
| `cellCount` | Cellaszám | 3..7 / 1 | 5 |
| `cellSize` | Cellaméret | 0.12..0.75 / 0.01 | 0.36 |
| `cellVariation` | Méretváltozatosság | 0..0.70 / 0.01 | 0.25 |
| `advectionX` | Áramlás X | -0.50..0.50 / 0.01 | 0.16 |
| `advectionY` | Áramlás Y | -0.50..0.50 / 0.01 | 0.06 |
| `curlAmount` | Örvénymező | 0..1 / 0.01 | 0.35 |
| `curlScale` | Örvényméret | 0.35..3 / 0.01 | 1.10 |
| `mergeThreshold` | Összeolvadási küszöb | -0.50..0.50 / 0.01 | 0 |
| `polarityBalance` | Cellapolaritás | -0.50..0.50 / 0.01 | 0 |
| `cellWander` | Cellavándorlás | 0..0.50 / 0.01 | 0.22 |
| `cellMorph` | Cellamorfológia | 0..1 / 0.01 | 0.28 |
| `noiseScale` | Morfológia méret | 0.35..3 / 0.01 | 1.40 |
| `noiseAmount` | Morfológia erő | 0..0.50 / 0.01 | 0.12 |
| `noiseSpeed` | Morfológia seb. | 0..1 / 0.01 | 0.14 |
| `pressure` | Cellanyomás | 0..1 / 0.01 | 0.70 |

## Scroll and gesture behavior

The animation-control viewport has a fixed mobile-friendly maximum height and `overflow-y:auto`. It uses momentum scrolling and contains only the active mode's rows.

- A predominantly vertical gesture beginning on a slider scrolls the animation-control viewport.
- A predominantly horizontal gesture changes that slider.
- Vertical movement at the control viewport's top or bottom may continue to the page rather than becoming trapped.
- Numeric inputs remain focusable and editable.
- Swiping on the header itself continues to drive the portal touch trail and prevents page scrolling.

The existing window-scrolling interception is replaced for the new animation panel with nearest-scroll-container routing, so it cannot bypass the internal control viewport.

## State transitions

- Page load selects `Statikus A/B` and paints no idle canvas frame.
- Moving any local palette slider updates A and B immediately without changing the selected animation mode or any mode settings.
- Selecting an animated mode starts or resumes that mode's continuous phase without resetting other modes.
- Selecting static mode pauses canvas rendering and exposes the exact CSS reference.
- Setting `strength` to zero also exposes the exact CSS reference while retaining the active mode and its settings.
- Reset restores only the active mode defaults and does not move the three palette sliders or interaction opacity.
- Reduced-motion preference defaults to static mode and still permits an explicit user selection of an animated mode within the test lab.

## Performance

Only one canvas and one animation loop exist. The loop stops painting in static mode, when the header is disconnected, or when it is outside the document viewport. Rendering uses the selected render scale and frame interval. Mode algorithms use broad fields with bounded cell/node counts; no per-frame DOM creation is used for idle animation.

The accepted touch trail remains the only transient DOM creation path and keeps its existing child limit and cleanup behavior.

## Verification

Automated checks must cover:

- old rotation, level, legacy, and old preset controls are absent from the test lab;
- static mode is the initial selected mode;
- static mode hides/clears the idle canvas and preserves exact A/B variables;
- the three local palette sliders remain last-writer-wins;
- touch CSS and touch-handler source sections remain unchanged by the idle rewrite;
- all four animated modes exist and select independent renderer functions;
- every exposed setting has a synchronized slider and numeric input;
- mode switching shows only the active mode's controls and preserves other mode state;
- strength zero returns the static field;
- each control changes a deterministic sampled field value under a fixed time/coordinate test fixture;
- field outputs are finite and bounded for minimum and maximum control values;
- vertical slider gestures target the internal scroll viewport while horizontal gestures retain range behavior;
- inline JavaScript parses and the prototype loads over local HTTP without runtime errors.

Visual verification must include screenshots of the static reference and all four animated modes using the same Traffic palette position. The comparison must confirm color fidelity, broad coherent movement, absence of rotation seams/gray veil/flame bands, and unchanged touch glow/trail appearance.

## Scope boundary

This work changes only the standalone portal test header and its local controls in the HTML color lab. It does not migrate the selected animation into Flutter/Dart, change the production D-row headers, redesign the global color scales, or alter other prototype screens.
