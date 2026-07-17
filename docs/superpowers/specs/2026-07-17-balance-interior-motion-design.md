# Balance Interior Motion Design

**Date:** 2026-07-17
**Status:** Approved in conversation; pending implementation

## Mandatory references

- User instruction from 2026-07-17 requesting an independently toggleable interior animation for both Balance color regions.
- Android screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-013843.png`.
- Existing prototype: `docs/prototypes/color_lab.html` and its portal color, energy, background, message, transition, and renderer modules.
- Acceptance checklist: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`.

The screenshot is a required implementation input. It shows visible activity around the broad white Balance boundary while most of the turquoise-green and pink-purple interiors remain visually uniform. The new effect must add motion inside those two fields without replacing or contaminating the existing boundary animation.

## Goal

Add one optional, independently controlled interior-motion layer to the Color Lab test header in Balance mode. The layer makes both colored interiors visibly alive while preserving the white boundary corridor, the current mother-color gradients, and all existing portal effects.

## Scope

The feature applies only in Balance mode because that mode supplies two distinct colored regions and a separating white boundary. It is off by default and can run at the same time as the current boundary, energy, message, background-response, and transition effects.

This design does not alter the Balance split, money-flow ratio, boundary shape, header content, or the algorithms of existing effects. It does not add free-form color pickers or allow several interior effects to stack simultaneously.

## Control model

The Color Lab controls gain an optional-effect row consistent with the existing portal-effect rows:

- visible label: `PORTÁL BELSŐ MOZGÁS`;
- independent `KI` / `BE` toggle, defaulting to `KI`;
- one effect selector;
- one `Erősség` slider;
- one `Sebesség` slider.

Only one interior effect can be active at a time. The selected effect, strength, and speed are shared by both sides. The two sides use separate deterministic seeds, phase offsets, and movement directions, so they do not look mirrored or synchronized.

## Initial effects

1. **Vándorló köd (`driftingMist`)**: broad translucent gradient bodies drift slowly through each region.
2. **Belső áramlás (`innerCurrent`)**: elongated, softly feathered streams travel through the interiors.
3. **Lágy hullám (`softTide`)**: low-frequency bands expand and recede without creating hard stripes.
4. **Lassú örvény (`slowVortex`)**: wide curved fields turn gently around separate regional centers.

Every option represents a distinct motion model rather than a renamed parameter preset.

## Rendering architecture

Interior motion is a separate state and renderer unit. It participates in the existing shared animation loop and must not start its own `requestAnimationFrame` loop.

The visual stack is:

1. resolved Balance mother colors;
2. interior-motion layer;
3. white boundary corridor and its existing animation;
4. header content, controls, and interaction surfaces.

For each frame, the current Balance geometry produces two mutually exclusive clip masks. A protected corridor covers the full visible white boundary plus a small feather allowance. The left and right interior render passes are clipped to their own masks and cannot draw inside that corridor or the opposite region. Header corner clipping remains authoritative at the outer edge.

Disabling the feature, leaving Balance mode, or hiding the relevant header stops its updates and clears only the interior-motion contribution. Other portal layers retain their state and animation.

## Color derivation and compositing

Colors are derived from the currently resolved mother colors rather than from a fixed decorative palette.

- The green region receives one lighter and one deeper green component while retaining the mother hue family.
- The pink-purple region receives one component shifted toward pink and one shifted toward violet-purple.
- Each component is strongest near its soft center, then blends progressively back toward its own mother color.
- The outer feather reaches the mother color with zero effective contrast, preventing visible blob edges.
- Blur, alpha, and color mixing are clipped before compositing, so no tinted halo can cross the white corridor.

`Erősség` controls contrast and opacity within conservative limits. It does not change the Balance split or boundary width. `Sebesség` controls temporal progression only; it does not change density, color, or mask geometry.

The implementation should reuse the existing portal color-resolution utilities so theme or Balance color changes update the interior palette immediately.

## Motion behavior

Both regions run the same selected effect and normalized speed. Their deterministic seeds, phase offsets, and preferred directions differ. Repeated renders with the same state and timestamp produce the same frame, avoiding flicker and random jumps.

Animation remains broad and low-frequency. It must read as movement within a colored material, not as particles, hard-edged shapes, or a second competing boundary. Under reduced-motion preferences, the renderer shows a stable representative frame without temporal movement.

## Failure and fallback behavior

- An unknown effect identifier falls back to `driftingMist`.
- Invalid numeric controls are clamped to documented safe ranges.
- Missing or degenerate Balance geometry skips the interior pass for that frame.
- A renderer failure must not suppress the base Balance fill, white boundary, or header content.

## Performance constraints

- Use the existing frame clock and visibility lifecycle.
- Reuse paths, gradients, seeded parameters, and offscreen resources where practical.
- Bound primitive counts for every effect.
- Respect the prototype's existing device-pixel-ratio cap.
- When disabled or outside Balance mode, perform no per-frame interior work.

## Verification

Automated verification covers:

- state defaults, toggle behavior, one-active-effect selection, and control clamping;
- deterministic side-specific seeds, phases, and directions;
- mother-color-derived component generation and edge blending;
- unknown-effect fallback and inactive-mode short-circuiting;
- renderer pixel checks proving temporal change inside both colored regions;
- renderer pixel checks proving that the protected white corridor remains free of green, pink, and purple contamination;
- integration checks for the new control row and all four options.

Visual verification uses the mandatory screenshot as the baseline and captures the same mobile header at multiple animation timestamps. Review must confirm visible interior activity on both sides, no hard internal contours, no boundary bleed, no text/control overlap, and no regression to existing boundary motion.

## Acceptance boundary

The feature is complete only when every item in `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md` is `DONE`. Passing tests or a served prototype alone does not override incomplete visual or behavioral requirements.
