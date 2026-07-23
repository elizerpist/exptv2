# Balance Interior Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rejected four-primitive `PORTÁL BELSŐ MOZGÁS` implementation with a dedicated Balance interior morph layer whose effects and controls match Portal background morph 1:1, rendered separately inside the left and right Balance regions.

**Architecture:** Rework `PortalInteriorMotion` into a dedicated wrapper around the existing Portal background-morph matter model. Keep separate interior state, settings, phase maps, controls, palettes, masks, and render call; share pure `PortalMessageField` effect/control semantics so behavior does not drift. Render two independently seeded masked pixel fields into the existing Balance energy canvas, one per side.

**Tech Stack:** Static HTML/CSS, browser Canvas 2D, plain JavaScript CommonJS/browser modules, Node `assert` tests, existing Color Lab static tests.

## Global Constraints

- Mandatory reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-013843.png`.
- Scope is Balance mode only; default state is off.
- The feature is dedicated; it must not reuse Portal background-morph DOM state, enabled flag, canvas, or palette window.
- Effects and controls must match `PortalMessageField` 1:1: `solid-a`, `static-matter`, `wandering-mist`, `living-archipelago`, `forming-clouds`.
- For every mode, control key, label, min, max, step, default, unit, normalization, and reset must match `PortalMessageField.controlsForMode(mode)`.
- Left and right sides share selected mode/settings but use deterministic nonmatching seed and phase offsets.
- Each side has its own light-to-dark scale derived from that side's current Balance colors.
- Revised layer model approved on 2026-07-17: the original animated turquoise-white-magenta-purple Balance gradient remains the lower layer, and the interior morph is one common translucent upper overlay.
- The upper overlay must not clip to left/right masks, must not clear or replace the lower gradient, and must tint with the known darker green in A areas and known darker purple/lilac in B areas.
- The upper overlay has extra rotation controls: `Rotáció` KI/BE and `Rotáció sebesség`; these rotate only the morph sampling plane.
- Rotated sampling must use a width-based virtual square with off-window overscan so vertical movement has width-distance travel, not only the visible header height.
- Reuse the existing Balance frame clock; do not add another `requestAnimationFrame` loop.
- Add no runtime dependency.
- Completion requires `COLOR-LAB-384` through `COLOR-LAB-395` to be `DONE` or explicitly deferred.

## File Structure

- Modify `docs/prototypes/color_lab_portal_interior_motion.js`: dedicated state, mode/settings parity with `PortalMessageField`, side palette derivation, phase advancement, side-specific settings.
- Modify `docs/prototypes/color_lab_portal_interior_motion_test.js`: pure model tests proving 1:1 mode/control parity, dedicated defaults, palette endpoints, phase/seed behavior.
- Modify `docs/prototypes/color_lab_portal_interior_motion_renderer.js`: replace primitive drawing with two masked pixel-field passes using `PortalMessageFieldRenderer`-equivalent sampling.
- Modify `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`: renderer parity, masking, inactive short-circuit, side independence, and pixel-change tests.
- Modify `docs/prototypes/color_lab.html`: replace effect/strength/speed controls with dedicated mode selector, dynamic Portal background-morph controls, reset, state sync, phase advancement, and render options.
- Modify `docs/prototypes/color_lab_static_test.js`: static DOM/source integration contracts.
- Modify `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`: update evidence/statuses after verification.

---

### Task 1: Dedicated Interior Model Parity

- [x] Write failing tests in `color_lab_portal_interior_motion_test.js` for exact mode order/labels/controls/default settings matching `PortalMessageField`.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_test.js` and confirm RED on old `driftingMist`/`innerCurrent` API.
- [x] Replace the model API with dedicated `MODE_IDS`, `DEFAULT_INTERIOR_MOTION_STATE`, `createInteriorSettingsByMode`, `normalizeInteriorMotionState`, `settingsForMode`, `controlsForMode`, `deriveInteriorPalettes`, `createSideRenderOptions`, and `advanceInteriorPhase`.
- [x] Run the model test and confirm GREEN.

### Task 2: Masked Pixel-Field Renderer

- [x] Write failing renderer tests proving `renderPortalInteriorMotion` calls no primitive painters, returns left/right pixel work, uses two non-crossing masks that meet at the center split, and changes animated modes over phase.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js` and confirm RED against the primitive renderer.
- [x] Rework the renderer to build left/right masks and render sampled Portal background-morph matter through each side's light-to-dark palette.
- [x] Run renderer tests and confirm GREEN.

### Task 3: Dedicated UI Controls and Shared Loop Integration

- [x] Write failing static tests for the exact five options, dynamic controls viewport, reset button, no old strength/speed controls, separate interior settings/phase maps, and one shared-loop renderer call.
- [x] Run `node docs/prototypes/color_lab_static_test.js` and confirm RED.
- [x] Update `color_lab.html` to render and sync the dedicated mode selector and per-mode dynamic sliders/numbers from `PortalInteriorMotion.controlsForMode(mode)`.
- [x] Update `drawMindPortalEnergyFrame` to advance interior phases and pass side palettes/settings to the renderer without adding a scheduler.
- [x] Run static tests and confirm GREEN.

### Task 4: Verification and Evidence

- [x] Run `node docs/prototypes/color_lab_portal_message_field_test.js`.
- [x] Run `node docs/prototypes/color_lab_portal_message_field_renderer_test.js`.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_test.js`.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`.
- [x] Run `node docs/prototypes/color_lab_static_test.js`.
- [x] Run `node --check` on changed JavaScript files.
- [x] HTTP-smoke `docs/prototypes/color_lab.html#mindHeaderScaleLab` from the local server.
- [x] Update checklist rows honestly; do not mark Android visual rows DONE without actual Android screenshots or explicit deferral.
- [x] Commit the implementation.

### Task 5: Common Overlay Layer Redesign

**Files:**
- Modify: `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab_portal_interior_motion_renderer.js`
- Modify: `docs/prototypes/color_lab.html`
- Modify: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`

**Interfaces:**
- Consumes: `PortalInteriorMotion.normalizeInteriorMotionState(state)`, `PortalInteriorMotion.deriveInteriorPalettes(options)`, `PortalMessageField.sampleMatter(mode, x, y, phase, settings)`.
- Produces: `PortalInteriorMotionRenderer.renderPortalInteriorMotion(ctx, options)` as a shared overlay renderer returning `{ rendered, overlayPixelCount }`.

- [x] Write failing renderer tests requiring a single unmasked overlay: zero `clip()` calls, `rgba(...)` fill styles with alpha below 1, and an `overlayPixelCount` result.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js` and confirm RED against the split-mask renderer.
- [x] Write failing static integration tests requiring the renderer call to happen after `ctx.putImageData(image, 0, 0)`, without a `boundary` object, and with current Balance colors passed for tint derivation.
- [x] Run `node docs/prototypes/color_lab_static_test.js` and confirm RED.
- [x] Replace split-mask rendering with one full-canvas overlay pass. Sample `PortalMessageField.sampleMatter` once per pixel, derive dark green/purple tint endpoints from the current Balance colors, use a smooth horizontal tint mix, and draw only `rgba(...)` pixels so the lower gradient remains visible.
- [x] Update `drawMindPortalEnergyFrame` to pass `leftColors`, `rightColors`, and `split`/transition data only; remove live boundary mask construction from the interior renderer call.
- [x] Run renderer/static tests and confirm GREEN.
- [x] Run the full targeted verification suite, HTTP smoke, and `git diff --check`.
- [x] Open the Color Lab preview with a new cache-buster and commit the redesign.

### Task 6: Upper Overlay Rotation Controls and Overscan Sampling

**Files:**
- Modify: `docs/prototypes/color_lab_portal_interior_motion_test.js`
- Modify: `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab_portal_interior_motion.js`
- Modify: `docs/prototypes/color_lab_portal_interior_motion_renderer.js`
- Modify: `docs/prototypes/color_lab.html`
- Modify: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`

**Interfaces:**
- Consumes: existing `PortalInteriorMotion.normalizeInteriorMotionState(state)` and `PortalInteriorMotionRenderer.renderPortalInteriorMotion(ctx, options)`.
- Produces: top-level `rotationEnabled` and `rotationSpeed` in the interior state, plus `PortalInteriorMotionRenderer.projectInteriorOverlaySamplePoint(options)` for testing the rotated width-based virtual sampling field.

- [x] Write failing model tests for `rotationEnabled`, `rotationSpeed`, and `normalizeRotationSpeed`.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_test.js` and confirm RED.
- [x] Write failing renderer tests proving rotation changes projected sample coordinates, speed 0 leaves projection unrotated, and the virtual sample field uses width-based overscan for short headers.
- [x] Run `node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js` and confirm RED.
- [x] Write failing static tests for the `Rotáció` toggle and `Rotáció sebesség` range/number controls, disabled-state sync, and renderer call receiving normalized rotation state.
- [x] Run `node docs/prototypes/color_lab_static_test.js` and confirm RED.
- [x] Add rotation state and normalization to `PortalInteriorMotion`.
- [x] Add virtual-square rotated sample projection to the renderer and use it before `PortalMessageField.sampleMatter`.
- [x] Add the rotation controls to `color_lab.html` and sync them with the interior state.
- [x] Run model, renderer, and static tests and confirm GREEN.
- [x] Run the full targeted verification suite, syntax checks, HTTP smoke, and `git diff --check`.
- [x] Open the Color Lab preview with a new cache-buster and commit.
