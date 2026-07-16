# Portal Message Morph Design

## Goal

Turn the standalone test header into a prototype portal message relay. Its resting content is the B1-style Balance label and amount. A separate test button beside the header repeatedly switches the content between Balance and a portal test message through one of four selectable, fully tunable morph animations.

## Scope and invariants

- HTML prototype only. Flutter application code is out of scope.
- The feature belongs only to the standalone test portal under the D row.
- The accepted portal background, energy-field modes, selected A/B colors, canvas lifecycle, touch bloom, drag trail, ripple, release fade, and both opacity controls remain unchanged.
- Message animation affects only the foreground content layers. It must not fade, recolor, blur, mask, pause, or restart the portal background or touch layers.
- The trigger is a separate control beside the header, never a child of the touch/drag surface.
- Repeated presses switch indefinitely: Balance → message → Balance → message.

## Header and trigger layout

The current standalone portal area becomes one compact horizontal test row whose total width stays aligned with the existing 360 px portal control panels.

- The header occupies the available row width.
- A 44 px circular satellite trigger sits beside it, vertically centered, with an 8 px gap.
- The button is visibly separate from the header and does not generate portal touch marks.
- The button uses `aria-pressed="false"` for Balance and `aria-pressed="true"` for the message.
- Its accessible label alternates between `Tesztüzenet megjelenítése` and `Balance visszaállítása`.
- The existing header remains the only `touch-action: none` surface. The adjacent button and all control panels retain normal page scrolling behavior.

## Content states

Two persistent, position-matched foreground panels occupy the same header content slot. Neither panel is rebuilt during a switch.

### Balance state

- Eyebrow/label: `Balance`.
- Primary value: `-372 047 472 Ft`.
- Typography and alignment follow the B1 stage-0 hierarchy: small uppercase label above a strong amount.

### Message state

- Eyebrow/label: `Portal üzenet`.
- Primary message: `Új pénzügyi jel érkezett`.
- Secondary placeholder: `Tesztüzenet · koppints a visszatéréshez`.
- The primary line may wrap, but all content must stay inside the header at the current test-header height.

The inactive panel remains in the DOM with `aria-hidden="true"`. The active panel has `aria-hidden="false"`. The header exposes `data-portal-message-state="balance|message"` for deterministic inspection.

## Toggle and interruption behavior

The controller owns one logical target state and the active pair of content animations.

1. A trigger press flips the target state.
2. If no morph is running, the selected mode builds outgoing and incoming keyframes and starts both panels.
3. If the opposite transition is already running, the controller reverses the active animations from their current visual progress instead of snapping, restarting, or queuing another transition.
4. On completion, exact final opacity, transform, filter, mask, `aria-hidden`, and state attributes are committed.
5. Switching the selected morph mode does not change the currently displayed content.

The control is a manual infinite toggle, not an automatic timer loop.

## Morph alternatives

The first mode is the recommended default. Direction-specific frames are mirrored when returning to Balance so every mode has a coherent reverse transition.

### 1. Diffúz fókusz

The outgoing content loses focus, shrinks slightly, drifts a few pixels, and fades. The incoming content starts as a soft blurred shape and resolves after a configurable overlap. This is the calmest option and best matches the accepted touch pigment fade.

Controls:

1. `Időtartam` — 300–2400 ms, default 900 ms.
2. `Átfedés` — 0–100%, default 38%.
3. `Blur` — 0–32 px, default 16 px.
4. `Összehúzás` — 90–100%, default 96%.
5. `Vertikális sodródás` — -24–24 px, default 6 px.
6. `Utófény` — 0–100%, default 28%.
7. `Lágyság` — 1–5, default 2.4; controls the easing exponent.

### 2. Portal rekesz

The outgoing content closes toward a configurable focal point through a soft radial aperture. A restrained portal bloom marks the crossover, then the incoming content opens from the same point. The aperture clips only the text panels, never the portal window.

Controls:

1. `Időtartam` — 300–2400 ms, default 980 ms.
2. `Átfedés` — 0–100%, default 28%.
3. `Fókusz X` — 0–100%, default 50%.
4. `Fókusz Y` — 0–100%, default 50%.
5. `Rekesz minimum` — 0–40%, default 7%.
6. `Éllágyság` — 0–40%, default 18%.
7. `Blur` — 0–28 px, default 12 px.
8. `Bloom` — 0–100%, default 42%.

### 3. Energia-söprés

A soft luminous boundary travels across the text from left to right. The outgoing content dissolves behind the boundary and the incoming content resolves in its wake. Angle changes the boundary orientation without reversing the required left-to-right travel direction.

Controls:

1. `Időtartam` — 300–2400 ms, default 840 ms.
2. `Átfedés` — 0–100%, default 52%.
3. `Szög` — -60–60°, default 8°.
4. `Hullámszélesség` — 6–60%, default 24%.
5. `Éllágyság` — 0–40%, default 16%.
6. `Elmozdulás` — 0–36 px, default 10 px.
7. `Blur` — 0–24 px, default 9 px.
8. `Fényerő` — 0–100%, default 48%.

### 4. Spektrális visszhang

The outgoing panel separates into restrained translucent echoes that drift away from the content axis. The incoming echoes converge and resolve into one sharp panel. Echoes reuse the current text and are confined to the content viewport.

Controls:

1. `Időtartam` — 300–2400 ms, default 1120 ms.
2. `Átfedés` — 0–100%, default 44%.
3. `Visszhangok` — 2–5, default 3.
4. `Távolság` — 0–30 px, default 12 px.
5. `Terülési szög` — -45–45°, default 14°.
6. `Blur` — 0–28 px, default 13 px.
7. `Szellem opacity` — 0–100%, default 34%.
8. `Konvergencia` — 80–120%, default 94%.

## Message morph controls

A new compact panel named `Portal üzenetváltás` appears below the existing energy-field panel.

- It uses a dropdown labeled `Üzenet morph` with the four modes in the order above.
- Its active mode label appears in the panel heading.
- Only the active mode's controls are rendered.
- Every parameter has the existing numbered-control pattern: number badge, title, range input, and synchronized manual number input.
- The active controls viewport is vertically scrollable and uses the same phone-width and height cap as the energy-field controls.
- Each mode preserves its own settings when switching modes.
- `Aktív mód reset` restores only the selected message mode and never changes the portal colors, background animation, message state, or touch opacity.

## Animation architecture

A small pure message-morph module defines:

- stable mode IDs and Hungarian labels;
- per-mode control schemas and defaults;
- numeric normalization;
- overlap timing calculation;
- deterministic outgoing/incoming keyframe descriptors for both directions.

The HTML runtime owns DOM lookup, accessible state, Web Animations API playback, reversal, control rendering, and reset. CSS provides the content viewport, two panels, trigger button, temporary bloom/echo layers, and final-state fallbacks.

The module must not import or modify the portal energy renderer. The runtime initializes after the existing portal controls and uses a separate state object associated with the standalone test header wrapper.

## Reduced motion and fallback

- With `prefers-reduced-motion: reduce`, switching uses a 160 ms opacity-only crossfade while preserving the same content/state semantics.
- If `Element.animate` is unavailable, CSS final-state classes switch the panels without leaving both visible.
- Text remains readable at both endpoints regardless of the selected background opacity or energy mode.

## Acceptance and verification

Automated verification must cover:

- exact Balance and message placeholder content;
- trigger placement outside the drag surface and correct accessibility attributes;
- repeated Balance/message toggling and final `aria-hidden` states;
- reversal during an active transition without a queued duplicate transition;
- exact dropdown order and all four control schemas/defaults;
- synchronized range/manual controls, per-mode persistence, and active-mode-only reset;
- deterministic bounded keyframe/timing output at minimum, default, and maximum values;
- reduced-motion and no-Web-Animations fallbacks;
- unchanged portal touch/trail source contract and unchanged energy-mode schema;
- JavaScript parse, static prototype regression, HTTP smoke, and diff whitespace checks.

Visual completion additionally requires Android-browser inspection of all four morphs in both directions, rapid mid-animation reversal, button separation from the drag surface, internal controls scrolling, content containment, and unchanged touch/background behavior. Until that evidence exists, UI-facing checklist items remain `PARTIAL` even when automated checks pass.
