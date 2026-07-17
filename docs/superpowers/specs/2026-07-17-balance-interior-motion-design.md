# Balance Interior Motion Design

**Date:** 2026-07-17
**Status:** Revised design approved in conversation; pending implementation

## Mandatory References

- User instruction from 2026-07-17 requesting an independently toggleable interior animation for both Balance color regions.
- User correction from 2026-07-17: the feature must be dedicated to Balance interior motion, not the same background-morph panel/state, while using the same effects and controls 1:1 as Portal background morph.
- Android screenshot baseline: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-013843.png`.
- Android screenshot correction source: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-130441.png`, where the earlier implementation left a visible light/white center band because the interior morph respected a no-draw corridor.
- Existing prototype: `docs/prototypes/color_lab.html`.
- Source behavior to match 1:1 for effects and controls: `docs/prototypes/color_lab_portal_message_field.js` and `docs/prototypes/color_lab_portal_message_field_renderer.js`.
- Acceptance checklist: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`.

The screenshots remain required implementation inputs. The latest correction establishes that the center transition is not an empty protected white corridor: the interior morph must reach the center transition on both sides, using the left side's light green and the right side's light magenta/purple, while preventing green/magenta cross-over.

## Goal

Add one optional, dedicated Balance-only interior morph layer. It makes the left and right Balance interiors read as internal material murmur (`morajlik belül`), with two independently masked sides that meet at the center split without leaving a blank/light no-draw band, while preserving all existing portal effects.

The feature is dedicated: it has its own state, its own controls, its own palette derivation, and its own Balance masks. It must not be the same Portal background-morph panel, not the same enabled flag, and not the same rendered canvas. The effect catalog, labels, per-effect sliders, defaults, clamping, phase behavior, and matter sampling must match Portal background morph 1:1.

## Scope

The feature applies only in Balance mode because that mode has two colored interiors with a light center transition. It is off by default and can run at the same time as the current Balance energy/boundary animation, message morph, background response, full background morph, and transition effects.

This design does not alter the Balance split, money-flow ratio, boundary shape, header content, or the algorithms of the existing Portal background-morph feature. It removes the previous custom interior primitive catalog as the accepted target for this feature.

## Control Model

The Color Lab controls keep a dedicated optional-effect row for Balance interior motion:

- visible label: `PORTÁL BELSŐ MOZGÁS`;
- independent `KI` / `BE` toggle, defaulting to `KI`;
- one mode selector dedicated to the interior layer;
- a dynamic controls viewport dedicated to the selected interior mode;
- an active-mode reset that resets only the selected interior mode settings.

The interior mode selector must expose the same modes, in the same order, with the same labels as Portal background morph:

1. `solid-a` - `Nincs dinamikus effekt`;
2. `static-matter` - `Statikus köd/szigetek`;
3. `wandering-mist` - `Vándorló köd`;
4. `living-archipelago` - `Élő szigetvilág`;
5. `forming-clouds` - `Keletkező energiafelhők`.

For each mode, the interior panel renders the same slider/number controls as `PortalMessageField.controlsForMode(mode)`, with the same key, label, min, max, step, default, unit, normalization, and reset behavior. This replaces the earlier single `Erősség` and `Sebesség` controls.

Only one interior mode is active at a time. The selected mode and settings are shared by both sides, but each side uses its own deterministic phase offset and seed offset so the two interiors are not mirrored or synchronized.

## Effect Behavior

The dedicated interior model follows the Portal background-morph effect behavior 1:1:

- `solid-a` produces no dynamic internal matter and resolves to the side's light endpoint;
- `static-matter` is phase invariant;
- `wandering-mist`, `living-archipelago`, and `forming-clouds` advance with the same phase rules and same sampled matter behavior as Portal background morph;
- unknown mode identifiers fall back through the same normalization rule as Portal background morph.

The implementation may share a pure sampler/kernel with Portal background morph to avoid drift, but the Balance interior feature must keep separate state objects, phase maps, settings maps, DOM bindings, and render calls.

## Two-Side Palette Model

The revised feature has two dedicated color scales, one per Balance side:

- left side scale: left side's brightest Balance color point to left side's darkest Balance color point;
- right side scale: right side's brightest Balance color point to right side's darkest Balance color point.

The renderer samples the selected interior matter value inside each side and maps it through that side's own light-to-dark scale. It must not use the Portal background-morph pink/purple palette window for Balance interior rendering. It must not use fixed decorative accent colors.

The brightest/darkest endpoints are derived from the current resolved Balance palette for the specific side, so theme or Balance palette changes update both interior scales immediately.

## Rendering Architecture

Interior motion is a separate state and renderer unit. It participates in the existing shared Balance energy animation frame and must not start its own `requestAnimationFrame` loop.

The visual stack is:

1. resolved Balance base field;
2. dedicated left and right interior morph fields;
3. existing Balance center/boundary animation;
4. header content, controls, and interaction surfaces.

For each frame, current Balance geometry produces two mutually exclusive clip masks. The masks meet at the current center split: the left morph may draw up to the split using only the left light-to-dark scale, and the right morph may draw from the split using only the right light-to-dark scale. There is no protected blank/no-draw center corridor. Header corner clipping remains authoritative at the outer edge.

Disabling the feature, leaving Balance mode, hiding the relevant header, or selecting a mode with no animated work stops interior updates and clears only the interior contribution. Other portal layers retain their state and animation.

## Motion Behavior

Both regions run the same selected mode and normalized settings. The two sides differ by deterministic seed offset, phase offset, and preferred coordinate direction. Repeated renders with the same state and timestamp produce the same frame, avoiding flicker and random jumps.

The animation should read as internal colored material motion. It must not look like a second boundary, hard-edged particles, or a decorative overlay floating above the Balance field. Under reduced-motion preferences, animated modes render a stable representative frame without temporal progression.

## Failure and Fallback Behavior

- Unknown mode identifiers normalize exactly like Portal background morph.
- Invalid numeric controls clamp exactly like Portal background morph controls.
- Missing or degenerate Balance geometry skips the interior pass for that frame.
- A renderer failure must not suppress the base Balance fill, white boundary, or header content.

## Performance Constraints

- Use the existing Balance energy frame clock and visibility lifecycle.
- Share the pure morph sampler where practical so effect math does not drift from Portal background morph.
- Bound offscreen frame sizes using the same profile/render-scale rules as Portal background morph unless the implementation plan proves a safer tighter bound.
- When disabled, outside Balance mode, or not visible, perform no per-frame interior model, palette, or pixel work.

## Verification

Automated verification covers:

- dedicated default-off state independent from Portal background-morph state;
- exact mode order, labels, control schemas, defaults, normalization, and reset behavior matching Portal background morph;
- per-side light-to-dark palette derivation from the current Balance side colors;
- phase-invariant `static-matter` and moving animated modes matching Portal background morph signatures;
- left and right side independence through deterministic seed/phase offsets;
- inactive-mode and disabled short-circuiting with zero interior work;
- center-split masking with no blank/no-draw corridor and no green/pink/purple cross-over;
- integration checks for the dedicated control row, mode selector, dynamic controls, reset, and shared-loop render call.

Visual verification uses the mandatory screenshots as the baseline/correction sources and captures the same mobile header at multiple animation timestamps. Review must confirm visible internal moraj on both sides, no hard internal contours, no center white band caused by skipped drawing, no green/magenta cross-over, no text/control overlap, and no regression to existing Balance boundary motion.

## Acceptance Boundary

The feature is complete only when every current item in `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md` is `DONE` or explicitly deferred by the user. Passing tests or a served prototype alone does not override incomplete visual or behavioral requirements.
