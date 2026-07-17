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
- The two side masks meet at the current center split; there is no protected blank/no-draw corridor. The left side may draw into the center transition only with its own green scale, and the right side only with its own magenta/purple scale.
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
