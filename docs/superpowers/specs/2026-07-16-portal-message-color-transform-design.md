# Portal Message Color Transform Design

## Goal

Add a separately selectable message-color transformation to the standalone test portal. While Balance is visible, the current financial A/B background remains authoritative. While a portal message is visible, the selected mode may fully replace that background with a white–light-pink–purple A/B field. The transformation must compose independently with the existing foreground morph and message-background response labs.

## Scope and invariants

- HTML prototype only; Flutter code is out of scope.
- This extends only the standalone test portal below the D/Mind row.
- The accepted touch bloom, trail, ripple, release fade, and drag interception remain unchanged.
- The existing financial signature, Money-flow ratio, base energy mode, A/B colors, window opacity setting, and phase state are never overwritten by message-color controls.
- The message-color layer is a separate renderer. At its message endpoint it visually replaces, rather than merely tints, the financial field. At the Balance endpoint it is removed and the exact original field becomes visible again.
- The existing foreground morph selector and `Portal háttérreakció` selector remain independent. Any foreground mode, background response, and message-color mode may be combined.

## Panel and mode order

A compact panel named `Portal üzenetszín` appears immediately after `Portal háttérreakció`.

The dropdown order is exact:

1. `Semmi` (`none`) — default;
2. `Statikus portál A/B` (`static`);
3. `Kettős árapály` (`dual-tide`);
4. `Mágneses membrán` (`magnetic-membrane`);
5. `Lélegző lencse` (`breathing-lens`);
6. `Celluláris mező` (`cellular-field`).

`none` exposes only the dropdown and is an exact no-color-change baseline. `static` exposes the palette row without animation controls. Each dynamic mode exposes the palette row followed by an isolated copy of that mode's existing numbered animation controls.

## Portal palette and A/B sampling

The message-color scale is fixed and ordered:

- 0%: white `#fffdfd`;
- 50%: light pink `#ffc4e4`;
- 100%: purple `#8b5cf6`.

The scale uses deterministic piecewise RGB interpolation from white to light pink and then from light pink to purple. Its active palette row contains:

- one 0–100 center slider, default 50%;
- one numeric window-size input, valid range 10–100%, default 68%.

The sampled endpoints are:

```text
A = sample(center - window / 2)
B = sample(center + window / 2)
```

Sampling positions clamp to 0–100. The control shows the currently sampled A/B colors. The number field may remain completely empty while typing. It commits and clamps only on Enter, `change`, or blur; invalid/empty input restores the last committed value.

Palette center and window size are shared by `static` and all four dynamic modes. Dynamic animation settings and phases remain isolated per dynamic mode. Selecting `none` does not erase the last palette or dynamic settings.

## Rendering architecture and layer order

The portal header uses this paint hierarchy:

1. original financial CSS A/B field and existing idle-energy canvas;
2. dedicated message-color canvas at `z-index: 0`, initially transparent;
3. existing message-background response overlay at `z-index: 0`, later in DOM paint order;
4. accepted touch layer at `z-index: 1`;
5. foreground Balance/message content at `z-index: 3`.

The message-color canvas is pointer-transparent, clipped by the header, and uses normal blending. It renders opaque A/B color pixels internally. Its element opacity is controlled separately from its pixel colors.

For a real replacement at the message endpoint, the transition crossfades two sources in the same animation group:

- the original CSS field and existing idle canvas move from their current window-opacity value to zero;
- the message-color canvas moves from zero to that same window-opacity value.

The original A/B values and canvas state remain stored and running independently; only their temporary visual opacity changes. At the message endpoint the financial colors cannot bleed through the portal palette. Returning to Balance reverses the crossfade and clears the message-color canvas.

The base CSS pseudo-element gains a dedicated visual-opacity variable whose Balance value mirrors the current `Ablak opacity`. The existing window-opacity control remains the sole opacity control and updates the correct visible source. It never changes content or touch opacity.

The visual-opacity variable is a registered numeric custom property animated on the header itself; that header animation is stored in `activeAnimations` with the message-color canvas animation. If `Ablak opacity` changes while Balance is settled, it updates the financial field. If it changes while a message is settled, it updates the message-color canvas. During a transition it updates both endpoint magnitudes without changing transition progress.

## Static and dynamic rendering

`static` renders a full-size linear A→B portal gradient without time-based movement.

The four dynamic modes reuse the existing pure `MindPortalEnergy` field algorithms and control schemas, but receive:

- the sampled portal A/B colors instead of the financial A/B colors;
- a separate settings object per mode;
- a separate phase value per mode;
- a dedicated message-color canvas and lifecycle.

They must not call the base portal's mode setter or mutate `mindPortalIdleStates`. Dynamic rendering runs only while its layer is transitioning or visible. A mode's phase is preserved when switching away and resumes when selected again, avoiding an identical first frame on every activation.

## Transition and interaction behavior

Forward delivery follows:

```text
financial field visible → crossfade → portal message field visible
```

Returning follows the exact reverse path. The original field, message-color canvas, foreground panels, foreground accent, and selected message-background response enter the same `activeAnimations` group. A rapid opposite trigger therefore calls the existing `animation.reverse()` path for all visual parts without a snap or queued replay.

The color transformation duration follows the active foreground morph duration so both endpoints commit together. Under reduced motion, it becomes a 160 ms opacity-only crossfade; dynamic geometry renders a static deterministic frame.

While a message is already settled:

- changing message-color mode crossfades the old field into the new field over 180 ms;
- changing the center slider crossfades to the newly sampled palette over 180 ms;
- committing a window-size value does the same;
- changing a dynamic control updates that renderer with the same 180 ms field crossfade;
- foreground content and the message-background response do not replay.

A temporary pointer-free snapshot/secondary canvas supplies the outgoing field during live-preview crossfades. A new preview cancels and replaces the previous preview cleanly. Choosing `none` fades the message-color field out and restores the financial field without changing the message text.

## State and controls

The existing portal message controller gains an isolated message-color state containing:

- `messageColorMode`, default `none`;
- shared `messageColorCenter`, default 50;
- shared `messageColorWindow`, default 68;
- `messageColorSettingsByMode` for the four dynamic modes;
- `messageColorPhaseByMode` for the four dynamic modes;
- active render frame, transition animation, and preview animation handles.

The panel matches the width/material of the existing portal panels. Dynamic controls use the existing `min(30vh, 240px)` viewport and the same vertical-on-slider gesture router. Range changes are immediate. Manual dynamic numbers and the window-size number commit only on Enter, `change`, or blur. Reset behavior is:

- `none`: no reset control;
- `static`: reset center to 50 and window to 68;
- dynamic mode: reset only that mode's animation settings; shared palette center/window remain unchanged.

Mode switching and reset never alter foreground morph settings, background-response settings, financial signature controls, main energy-mode settings, window opacity, interaction opacity, or message state.

## Fallback behavior

- If Web Animations is unavailable, the requested endpoint is applied directly and deterministically.
- If canvas rendering is unavailable, `static` uses an equivalent CSS A/B gradient and dynamic modes fall back to that same static portal gradient.
- Invalid mode, palette, or renderer data falls back to `none`; it never writes the financial A/B state.
- Under `prefers-reduced-motion: reduce`, dynamic message-color modes stop geometry movement and use a deterministic still frame plus the 160 ms crossfade.

## Acceptance and verification

Automated verification must cover:

- exact six-mode order, labels, and `none` default;
- exact three palette stops and deterministic samples at 0, 25, 50, 75, and 100;
- center/window endpoint sampling, clamping, defaults, and deferred manual commit;
- exact `none` no-op behavior and `static` A/B output;
- reuse of the four approved dynamic schemas with isolated settings and phases;
- no writes to financial A/B, Money-flow, base energy mode/state, foreground, background-response, or touch variables;
- message endpoint fully hiding the original financial field and Balance endpoint restoring it;
- inclusion in the common active-animation reversal path;
- 180 ms settled-message mode/palette/control preview without content replay;
- reduced-motion and no-WAAPI/no-canvas fallbacks;
- active-mode-only rendering, reset behavior, and vertical controls scrolling;
- protected foreground, background-response, portal-energy, and touch regression suites;
- external/inline JavaScript parse, `git diff --check`, and HTTP source smoke.

Visual completion additionally requires Android-browser inspection of all six modes, several center/window combinations, all four moving fields, simultaneous use with each background-response family, message/Balance reversal, rapid opposite taps, live mode/slider changes, opacity behavior, scrolling/manual input, text readability, and unchanged touch/Money-flow restoration. Until that evidence exists, UI-facing checklist items remain `PARTIAL`.
