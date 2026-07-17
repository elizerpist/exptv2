# Balance Interior Motion Design

**Date:** 2026-07-17
**Status:** Revised design approved in conversation; pending implementation

## Mandatory References

- User instruction from 2026-07-17 requesting an independently toggleable interior animation for both Balance color regions.
- User correction from 2026-07-17: the feature must be dedicated to Balance interior motion, not the same background-morph panel/state, while using the same effects and controls 1:1 as Portal background morph.
- Android screenshot baseline: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-013843.png`.
- Android screenshot correction source: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-130441.png`, where the earlier implementation left a visible light/white center band because the interior morph respected a no-draw corridor.
- Android screenshot layer-correction source: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-132149.png`, where the split-mask fix removed the original white center gradient because the interior morph became a replacement layer instead of a top overlay.
- Existing prototype: `docs/prototypes/color_lab.html`.
- Source behavior to match 1:1 for effects and controls: `docs/prototypes/color_lab_portal_message_field.js` and `docs/prototypes/color_lab_portal_message_field_renderer.js`.
- Acceptance checklist: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`.

The screenshots remain required implementation inputs. The latest correction establishes the intended layer model: the original animated Balance gradient remains the lower layer, including the turquoise-white-magenta-purple transition, and the interior morph is a separate upper overlay. The overlay is one common field, not two side-clipped fields.

## Goal

Add one optional, dedicated Balance-only interior morph overlay. It makes the Balance field read as internal material murmur (`morajlik belül`) while preserving the original animated turquoise-white-magenta-purple Balance gradient underneath.

The feature is dedicated: it has its own state, its own controls, its own palette derivation, and its own Balance masks. It must not be the same Portal background-morph panel, not the same enabled flag, and not the same rendered canvas. The effect catalog, labels, per-effect sliders, defaults, clamping, phase behavior, and matter sampling must match Portal background morph 1:1.

## Scope

The feature applies only in Balance mode because that mode has two colored interiors with a light center transition. It is off by default and can run at the same time as the current Balance energy/boundary animation, message morph, background response, full background morph, and transition effects. The interior layer must not replace or flatten the lower Balance gradient.

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

The revised feature keeps two dedicated tint endpoints for the upper overlay:

- A-region overlay tint: the known darker green endpoint from the current Balance palette;
- B-region overlay tint: the known darker purple/lilac endpoint from the current Balance palette.

The renderer samples one shared interior matter field across the full Balance header. It maps that shared matter to an alpha/tint overlay: green-tinted where the lower Balance field reads as A/turquoise, purple-tinted where it reads as B/magenta-lilac, with a smooth tint transition. It must not use the Portal background-morph pink/purple palette window for Balance interior rendering. It must not use fixed decorative accent colors.

The dark tint endpoints are derived from the current resolved Balance palette, so theme or Balance palette changes update the overlay immediately.

## Rendering Architecture

Interior motion is a separate state and renderer unit. It participates in the existing shared Balance energy animation frame and must not start its own `requestAnimationFrame` loop.

The visual stack is:

1. resolved Balance base field;
2. one common translucent interior morph overlay;
3. existing Balance center/boundary animation;
4. header content, controls, and interaction surfaces.

For each frame, the lower Balance renderer first draws the original animated money-flow palette (`#49cfc5 → #8defe5 → #f8e8f3 → #f7b2f5 → #d8b4fe`) with its existing smooth center transition. The interior renderer then draws a translucent overlay over the full Balance canvas. It does not clip to left/right masks and it does not clear, replace, or repaint the base gradient. Header corner clipping remains authoritative at the outer edge.

Disabling the feature, leaving Balance mode, hiding the relevant header, or selecting a mode with no animated work stops interior updates and clears only the interior contribution. Other portal layers retain their state and animation.

## Motion Behavior

The overlay runs one selected mode and one normalized settings set across the full Balance field. Repeated renders with the same state and timestamp produce the same frame, avoiding flicker and random jumps.

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
- preservation of the original lower Balance gradient before overlay rendering;
- phase-invariant `static-matter` and moving animated modes matching Portal background morph signatures;
- one shared overlay field with no left/right clipping;
- inactive-mode and disabled short-circuiting with zero interior work;
- translucent overlay rendering using darker green and darker purple tint endpoints without removing the white center gradient;
- integration checks for the dedicated control row, mode selector, dynamic controls, reset, and shared-loop render call.

Visual verification uses the mandatory screenshots as the baseline/correction sources and captures the same mobile header at multiple animation timestamps. Review must confirm the original turquoise-white-magenta-purple lower gradient is visible, the upper morph reads as internal movement rather than replacement color, no text/control overlap occurs, and existing Balance boundary motion is preserved.

## Acceptance Boundary

The feature is complete only when every current item in `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md` is `DONE` or explicitly deferred by the user. Passing tests or a served prototype alone does not override incomplete visual or behavioral requirements.
