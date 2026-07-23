# Portal Message Background Response Design

## Goal

Add an independently selectable background response to the standalone portal message relay. The response makes message delivery feel like an event in the energy field, while preserving the selected A/B financial colors and leaving the accepted touch interaction untouched. The lab must also provide an exact `Nincs háttéreffekt` baseline.

## Scope and invariants

- HTML prototype only; Flutter code is out of scope.
- This extends only the standalone test portal under the D row.
- Foreground Balance/message morph modes remain unchanged and independently selectable.
- Background responses never rewrite the static A/B gradient, portal signature values, Money-flow ratio, canvas renderer settings, or touch-layer styles.
- The new response is a separate visual layer below foreground content and below the touch bloom/trail, but above the base gradient/canvas.
- Every response participates in the same manual Balance ↔ message toggle and in-flight reversal as the foreground morph.
- `Nincs háttéreffekt` produces no response animation, no residual inline style, and pixel-equivalent background behavior to the current portal.

## Layer order

The standalone header uses this fixed paint hierarchy:

1. static A/B CSS reference and optional existing energy canvas;
2. new message-background response overlay at `z-index: 0`;
3. accepted touch bloom/trail/ripple layer at `z-index: 1`;
4. foreground Balance/message content viewport at `z-index: 3`.

The response overlay has `pointer-events: none`, `overflow: hidden` through the header boundary, and no event listeners. Therefore it cannot capture drag, scroll, trigger, or slider gestures.

## Dropdown and default

A separate compact panel named `Portal háttérreakció` appears below `Portal üzenetváltás`.

The dropdown order is:

1. `Nincs háttéreffekt` (`none`) — default baseline;
2. `Energiakompresszió` (`energy-compression`) — recommended production direction;
3. `Refrakciós hullám` (`refraction-wave`);
4. `Határfény` (`seam-flare`);
5. `Mélységi fókusz` (`depth-focus`);
6. `Kromatikus riasztás` (`chromatic-alert`).

`none` hides the active controls viewport. Every animated mode renders only its own numbered range/manual-input controls, preserves its settings when another mode is selected, and supports an active-mode-only reset. Selecting a mode never changes the foreground morph selection.

## Shared temporal model

Each animated mode defines:

- `duration`: total Balance-to-message or message-to-Balance response time;
- `strength`: peak effect amount;
- `peak`: normalized point where the response reaches maximum energy;
- `hold`: percentage of peak energy retained while the message remains visible;
- `decay`: curvature of the peak-to-hold or peak-to-zero release.

Forward delivery follows `rest → peak → message hold`. Returning to Balance follows `message hold → peak → rest`. If `hold` is zero, the response is transition-only and fully disappears while the message remains visible.

If the user taps again before the transition finishes, the existing foreground animations and the background response animation reverse together from their current progress. No response animation is queued or restarted.

Changing background mode while the message is already visible crossfades the old hold state into the newly selected hold state without replaying or changing the message content. Changing to `none` clears the overlay in 180 ms.

## Response modes and controls

### 0. Nincs háttéreffekt

Exact baseline. No active control rows. The overlay is fully transparent, has no running Web Animation, and retains no filter, transform, clip-path, mask, or blend override.

### 1. Energiakompresszió

The field appears to inhale toward a configurable center. A restrained white/pink energy bloom peaks behind the content, then releases to the selected hold strength. It changes apparent energy density and luminance, not A/B hue ownership or ratio.

Controls:

1. `Időtartam` — 300–2400 ms, default 900 ms.
2. `Erősség` — 0–100%, default 62%.
3. `Csúcspont` — 20–80%, default 48%.
4. `Középpont X` — 0–100%, default 50%.
5. `Középpont Y` — 0–100%, default 50%.
6. `Kompresszió` — 0–40%, default 18%.
7. `Bloom` — 0–100%, default 44%.
8. `Mezőskála` — 70–130%, default 92%.
9. `Üzenetállapot tartás` — 0–100%, default 18%.
10. `Lecsengés` — 0–100%, default 66%.

### 2. Refrakciós hullám

A circular energy front expands from a configurable origin. Soft alternating rings imply that the A/B surface bends like water. The layer supplies highlights and refraction cues without sampling or recoloring the underlying field.

Controls:

1. `Időtartam` — 400–2600 ms, default 1120 ms.
2. `Erősség` — 0–100%, default 58%.
3. `Csúcspont` — 20–80%, default 52%.
4. `Forrás X` — 0–100%, default 50%.
5. `Forrás Y` — 0–100%, default 50%.
6. `Hullámsugár` — 20–180%, default 122%.
7. `Gyűrűszélesség` — 2–30%, default 12%.
8. `Gyűrűk` — 1–5, default 2.
9. `Töréserő` — 0–40%, default 16%.
10. `Blur` — 0–24 px, default 8 px.
11. `Üzenetállapot tartás` — 0–100%, default 10%.
12. `Lecsengés` — 0–100%, default 70%.

### 3. Határfény

The semantic A/B meeting zone becomes a luminous, softly wandering membrane. For Money flow, its anchor follows the existing 8–92% mapped income/expense split; for the other signatures it uses the current A/B midpoint. It may widen and branch locally but cannot move the financial split or swap sides.

Controls:

1. `Időtartam` — 300–2200 ms, default 820 ms.
2. `Erősség` — 0–100%, default 58%.
3. `Csúcspont` — 20–80%, default 46%.
4. `Fénysáv szélesség` — 2–45%, default 14%.
5. `Határvándorlás` — 0–30%, default 8%.
6. `Elágazás` — 0–100%, default 32%.
7. `Bloom` — 0–100%, default 48%.
8. `Vertikális fázis` — 0–360°, default 110°.
9. `Üzenetállapot tartás` — 0–100%, default 24%.
10. `Lecsengés` — 0–100%, default 68%.

### 4. Mélységi fókusz

The header edges gain a soft vignette while the area behind the content becomes brighter and optically closer. This is the quietest persistent message state and is suitable when the message should remain readable for longer.

Controls:

1. `Időtartam` — 300–2200 ms, default 880 ms.
2. `Erősség` — 0–100%, default 48%.
3. `Csúcspont` — 20–80%, default 50%.
4. `Fókusz X` — 0–100%, default 50%.
5. `Fókusz Y` — 0–100%, default 48%.
6. `Fókuszsugár` — 20–100%, default 62%.
7. `Peremsötétítés` — 0–100%, default 36%.
8. `Mélységskála` — 90–110%, default 97%.
9. `Középfény` — 0–100%, default 30%.
10. `Blur` — 0–20 px, default 5 px.
11. `Üzenetállapot tartás` — 0–100%, default 34%.
12. `Lecsengés` — 0–100%, default 72%.

### 5. Kromatikus riasztás

An experimental lilac/pink pulse briefly overlays the A/B field. The base endpoints remain visible and unchanged. Overlay opacity is hard-bounded to 45%, preventing the response from replacing the financial colors or becoming confused with a new data state.

Controls:

1. `Időtartam` — 300–2200 ms, default 760 ms.
2. `Erősség` — 0–100%, default 56%.
3. `Csúcspont` — 20–80%, default 42%.
4. `Overlay opacity` — 0–45%, default 24%.
5. `Rózsaszín arány` — 0–100%, default 58%.
6. `Lila arány` — 0–100%, default 42%.
7. `Terjedés` — 20–160%, default 96%.
8. `Pulzusszám` — 1–4, default 2.
9. `Blur` — 0–24 px, default 9 px.
10. `Üzenetállapot tartás` — 0–100%, default 12%.
11. `Lecsengés` — 0–100%, default 64%.

## Rendering architecture

A separate CommonJS/browser-compatible pure module owns:

- the exact six-mode order and labels;
- frozen control schemas and defaults;
- numeric normalization;
- forward/backward response descriptors;
- peak and message-hold timing;
- bounded overlay keyframes and endpoint rest styles.

The module emits only overlay-safe properties such as opacity, transform, filter, clip-path, mask-position, and CSS custom properties. It cannot emit or write the portal canvas, A/B colors, touch variables, content properties, or event state.

The existing message runtime adds the optional response animation to the same `activeAnimations` group as outgoing content, incoming content, and content accent. Therefore the existing in-flight `animation.reverse()` path reverses every visible part together. Endpoint commit applies the selected overlay rest style only for the message state and clears it for Balance or `none`.

## Controls and mobile interaction

- The response panel matches the width and material of the existing foreground morph panel.
- The active controls viewport uses the same `min(30vh, 240px)` cap and vertical gesture router.
- Only the test header remains `touch-action: none`; dropdowns, sliders, manual inputs, reset, and the trigger remain normally tappable/scrollable.
- Range changes are immediate. Manual values allow temporary empty text and commit/clamp on Enter, change, or blur.
- Mode switching and reset never alter foreground morph settings, portal signature, background window opacity, interaction opacity, or message state.

## Reduced motion and fallback

- Under `prefers-reduced-motion: reduce`, animated background modes become a 160 ms opacity-only response to the selected hold strength; `none` remains exact zero.
- Without Web Animations, endpoint rest styles still distinguish message/Balance deterministically, but no transitional response runs.
- If a response descriptor is invalid or unavailable, the controller falls back to `none` rather than touching the base portal.

## Acceptance and verification

Automated verification must cover:

- exact six-option order with `none` default;
- `none` returning zero frames and empty rest styles;
- exact schemas/defaults/bounds for all five animated modes;
- every exposed control measurably changing its own response descriptor;
- bounded opacity, scale, blur, clip/mask geometry, and monotonically ordered offsets;
- forward message and backward Balance descriptors plus message hold state;
- Money-flow seam anchor mapping at 0, 50, and 100;
- shared active-animation reversal and endpoint cleanup;
- foreground mode/settings independence and active-background-mode-only reset;
- reduced-motion and no-Web-Animations fallbacks;
- protected portal-energy and touch source contracts remaining green;
- JavaScript parse, HTTP source smoke, and diff whitespace checks.

Visual completion additionally requires Android-browser inspection of all six choices, both toggle directions, rapid reversal, zero-effect parity, hold at 0% and above 0%, slider/manual controls, internal scrolling, content readability, and unchanged touch/background semantics. Until that evidence exists, UI-facing checklist items remain `PARTIAL`.
