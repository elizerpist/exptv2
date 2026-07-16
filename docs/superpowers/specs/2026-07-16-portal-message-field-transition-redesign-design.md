# Portal Message Field and Transition Redesign

## Status and precedence

This specification records the design approved on 2026-07-16 after the first
Portal message-color prototype was tested. It supersedes the message-state
field geometry and simple source-crossfade sections of:

- `2026-07-16-portal-message-color-transform-design.md`;
- the implicit foreground-accent ownership described by
  `2026-07-16-portal-message-morph-design.md`;
- the `none`/accent interaction described by
  `2026-07-16-portal-message-background-response-design.md`.

The previous documents remain historical references. Their accepted Balance
content, text-morph alternatives, touch interaction, palette stops, control
editing behavior, accessibility, reversal, and mobile-scroll contracts remain
in force unless this document explicitly replaces them.

## Goal

Keep Balance and Portal message presentation as two deliberately different
visual states, then animate a real transformation between them. The Portal
message state no longer uses a left-A/right-B gradient. It is an A-colored
energy field containing independently wandering B-colored fog and islands.

The relay is split into three independently switchable animation layers:

1. foreground text morph;
2. local text-background morph;
3. full-header background morph.

The accepted touch bloom, trail, ripple, drag capture, and delayed release fade
remain a fourth, protected interaction system and are not redesigned here.

## Non-negotiable state model

There are always two distinct endpoints:

- **Balance endpoint:** the currently selected financial A/B signature and its
  existing Balance animation remain authoritative;
- **Portal endpoint:** the white–light-pink–purple Portal palette is rendered
  using the new A-base/B-matter field described below.

These endpoints are not selectable alternatives and are never composited as a
permanent hybrid. The trigger changes which endpoint is visible. The new
background-transition menu controls how the visible Balance field becomes the
Portal field and how it returns.

Disabling the full-background morph disables only the transition animation.
The forward trigger still switches immediately to the Portal endpoint, and the
return trigger still switches immediately to the Balance endpoint. Therefore
the two endpoint backgrounds remain different in every configuration.

## Three independently controlled layers

### 1. Foreground text morph

The foreground layer owns only the persistent Balance and Portal message text
panels. It retains the accepted `Diffúz fókusz`, `Portal rekesz`,
`Energia-söprés`, and `Spektrális visszhang` choices and their settings.

- `Szöveg-morph` has an explicit on/off switch.
- When on, only the selected foreground descriptor affects the text panels.
- When off, the target panel is committed immediately with no blur, bloom,
  color, mask, transform, or ghost layer.
- The foreground module must not create an unconditional colored accent behind
  the text.

### 2. Local text-background morph

This optional layer owns every glow, pigment response, refraction, or colored
reaction visually concentrated around the changing text. It is no longer an
implicit side effect of the foreground morph.

- `Szövegháttér-morph` has its own on/off switch, mode dropdown, settings,
  reset, animation handle, and endpoint cleanup.
- The default switch state is on so a newly triggered Portal message has a
  readable portal reaction before the user edits any settings.
- Explicit off is authoritative: the layer has no running animation, no ghost,
  no hold style, no pseudo-element contribution, and no remaining opacity,
  filter, mask, transform, background, or custom-property value.
- The old foreground accent is removed from the foreground controller. The
  text-background controller is the only owner of this visual reaction.
- Existing response modes that do not depend on message-field geometry may be
  retained. Any fixed A/B seam assumption must be removed or expressed as a
  local text-centered field rather than a left/right Portal split.

The reaction may remain spatially local, but its render host covers the entire
header. A soft halo is allowed to reach the header boundary naturally; a hard
inset rectangle is not.

### 3. Full-header background morph

This layer owns the visual transformation between the current Balance field
and the Portal message field.

- `Háttér-morph` has its own on/off switch.
- When on, its selected transition renderer participates in the shared toggle
  and reversal lifecycle.
- When off, it performs the immediate endpoint switch defined above.
- Its panel contains a `Portal végállapot` dropdown for the settled Portal
  field and a separate `Balance → Portal átmenet` dropdown for the transition.
- Settled Portal-field movement and Balance→Portal transformation are separate
  state/configuration objects. Changing one never resets the other.

## Full-header paint and clipping architecture

Every colored background and reaction surface is a direct full-size child of
the header and is clipped only by the header's outer border radius:

1. existing Balance background/CSS and idle-energy canvas;
2. settled Portal message-field canvas;
3. full-header transition compositor above both endpoint sources;
4. optional full-header-hosted, text-centered background reaction;
5. accepted touch interaction visuals, unchanged;
6. padded foreground content viewport containing only the two text panels.

The Balance/message content viewport may retain its typography padding. It may
not contain or clip any colored canvas, message accent, background response, or
transition surface. The visual layers use `position: absolute; inset: 0`, are
pointer-transparent, and inherit only the header's outer clipping.

This removes the current anomaly in which a colored text reaction ends at the
content viewport's `16px 17px` inset and leaves static strips at the top,
bottom, and sides.

## Portal endpoint color model

The Portal palette remains exact:

- 0%: `#fffdfd`;
- 50%: `#ffc4e4`;
- 100%: `#8b5cf6`.

The existing center and deferred 10–100 window-size controls continue to
sample two colors:

```text
A = sample(center - window / 2)
B = sample(center + window / 2)
```

Their meaning changes from two spatial anchors to two material colors:

- A fills the entire Portal field;
- B exists only where the animated scalar matter mask is non-zero.

For each pixel:

```text
portalColor(x, y, t) = directColorMix(A, B, matterMask(x, y, t))
```

`matterMask` is bounded to 0–1. This is a direct color interpolation, not a
gray/black veil and not an alpha-blended dark overlay. Overall window opacity
continues to affect only the background canvases, never text or touch output.

No Portal mode may establish a permanent left/right color owner, a single
horizontal seam, equally spaced flame tongues, or a rotating linear-gradient
axis. B matter can cross the whole header, but A remains the base material and
the two colors never exchange semantic roles.

## Portal endpoint mode menu

The old `Kettős árapály`, `Mágneses membrán`, `Lélegző lencse`, and
`Celluláris mező` Portal-message implementations are invalid for this field and
are removed from this dropdown. They are not renamed or cosmetically reused.
Balance-side modes remain untouched.

Exact new order:

1. `Nincs dinamikus effekt` (`solid-a`);
2. `Statikus köd/szigetek` (`static-matter`);
3. `Vándorló köd` (`wandering-mist`) — recommended default;
4. `Élő szigetvilág` (`living-archipelago`);
5. `Keletkező energiafelhők` (`forming-clouds`).

### Nincs dinamikus effekt

The settled Portal endpoint is a homogeneous A field. It is still a distinct
Portal background; only B matter and time-based motion are absent. Palette and
overall background-opacity controls remain available.

### Statikus köd/szigetek

A deterministic frozen two-dimensional matter mask places broad B regions in
the A field. It is a valid still-frame comparison, not a paused frame from a
dynamic mode.

Controls, expressed as `min–max; default`:

1. `B-fedettség` — 0–80%; 34%;
2. `B-erősség` — 0–100%; 72%;
3. `Anyagskála` — 20–180%; 100%;
4. `Peremlágyság` — 0–100%; 76%;
5. `Részletesség` — 0–100%; 28%;
6. `Véletlenmag` — 0–9999; 137.

### Vándorló köd

Several broad, low-frequency B fog masses are advected through a slow curl
field. Their centers wander on non-repeating bounded paths while domain warping
changes their silhouettes. Motion has no dominant horizontal or vertical axis.

Controls, expressed as `min–max; default`:

1. `B-fedettség` — 0–80%; 36%;
2. `B-erősség` — 0–100%; 74%;
3. `Ködskála` — 20–200%; 118%;
4. `Peremlágyság` — 0–100%; 82%;
5. `Sodródási sebesség` — 0–100%; 22%;
6. `Curl erősség` — 0–100%; 44%;
7. `Alakváltozás` — 0–100%; 28%;
8. `Részletesség` — 0–100%; 24%;
9. `Véletlenmag` — 0–9999; 311.

### Élő szigetvilág

A small population of soft metaball-like B islands follows independent
Brownian/curl paths. Nearby islands may merge and later divide while the total
B coverage remains bounded. No island is tied to a side of the header.

Controls, expressed as `min–max; default`:

1. `Szigetszám` — 2–12; 6;
2. `Átlagos méret` — 8–80%; 34%;
3. `Méreteltérés` — 0–100%; 42%;
4. `B-erősség` — 0–100%; 78%;
5. `Peremlágyság` — 0–100%; 66%;
6. `Vándorlási sebesség` — 0–100%; 30%;
7. `Összeolvadási vonzás` — 0–100%; 55%;
8. `Alakváltozás` — 0–100%; 36%;
9. `Véletlenmag` — 0–9999; 521.

### Keletkező energiafelhők

Overlapping B clouds are born at distributed positions, grow, wander, soften,
and dissolve. Birth times and paths are staggered so the output cannot become
a repeated flame or conveyor-belt pattern.

Controls, expressed as `min–max; default`:

1. `Aktív felhősűrűség` — 1–10; 4;
2. `Élettartam` — 2–30 s; 14 s;
3. `Születési átfedés` — 0–100%; 58%;
4. `Növekedés` — 0–100%; 46%;
5. `B-erősség` — 0–100%; 76%;
6. `Felhőskála` — 10–120%; 46%;
7. `Peremlágyság` — 0–100%; 78%;
8. `Sodródási sebesség` — 0–100%; 24%;
9. `Útvonal-szabálytalanság` — 0–100%; 52%;
10. `Véletlenmag` — 0–9999; 887.

All controls use the established numbered slider plus synchronized manual-input
pattern. Only the active mode's controls are shown; settings and phase are
preserved per mode. The controls viewport remains vertically scrollable on a
phone and does not inherit the header's drag interception.

## Balance-to-Portal transformation menu

The new `Balance → Portal átmenet` dropdown belongs to the full-background
morph layer. Exact order:

1. `Pigmentterjedés` (`pigment-spread`) — recommended default;
2. `Szigetes átalakulás` (`island-takeover`);
3. `Folyékony színátírás` (`liquid-remap`).

These are transition algorithms, not settled Portal idle modes.

### Pigmentterjedés

The Portal A color diffuses through multiple soft, noise-warped fronts while B
fog appears with an adjustable delay behind the transformed regions. It should
feel like pigment entering a liquid, not a radial wipe.

Controls, expressed as `min–max; default`:

1. `Időtartam` — 300–3000 ms; 1100 ms;
2. `Forrásszám` — 1–12; 5;
3. `Forrásszórás` — 0–100%; 62%;
4. `Frontlágyság` — 0–100%; 78%;
5. `Diffúzió` — 0–100%; 56%;
6. `Domain warp` — 0–100%; 48%;
7. `Portal-B késleltetés` — 0–80%; 24%;
8. `Átfedés` — 0–100%; 38%;
9. `Lágyság` — 1–5; 2.4.

### Szigetes átalakulás

Portal-colored islands nucleate at distributed points, grow, merge, and replace
the Balance field. The final takeover resolves into the currently selected
Portal endpoint mode without a visible geometry jump.

Controls, expressed as `min–max; default`:

1. `Időtartam` — 300–3000 ms; 1200 ms;
2. `Magpontok` — 2–14; 6;
3. `Kezdősugár` — 1–30%; 7%;
4. `Növekedési ráta` — 10–200%; 96%;
5. `Összeolvadás` — 0–100%; 58%;
6. `Peremlágyság` — 0–100%; 74%;
7. `Útvonal-vándorlás` — 0–100%; 38%;
8. `B megjelenése` — 0–100%; 46%;
9. `Átfedés` — 0–100%; 42%;
10. `Lágyság` — 1–5; 2.3.

### Folyékony színátírás

The current Balance pixels continuously remap toward their Portal target
colors through a low-frequency warped progress field. Color conversion and
geometry conversion have separately adjustable timing but settle together.

Controls, expressed as `min–max; default`:

1. `Időtartam` — 300–3000 ms; 980 ms;
2. `Színváltás kezdete` — 0–60%; 12%;
3. `Geometriaváltás kezdete` — 0–60%; 28%;
4. `Warp skála` — 20–200%; 108%;
5. `Warp erősség` — 0–100%; 46%;
6. `Áramlási sebesség` — 0–100%; 24%;
7. `Peremlágyság` — 0–100%; 68%;
8. `Átfedés` — 0–100%; 52%;
9. `Lágyság` — 1–5; 2.2.

## Transition renderer

At the start of a full-background morph, the compositor obtains:

- a source frame representing the actually visible current endpoint;
- a target frame representing the destination endpoint at that moment.

Each transition mode produces a bounded two-dimensional progress mask
`P(x,y,t)`. The compositor directly interpolates source pixels toward target
pixels according to that mask. This provides a visible color transformation;
it is not merely two full layers with a global opacity crossfade.

At the forward endpoint, the transition canvas clears and the live Portal
renderer owns the background. At the reverse endpoint, it clears and the
untouched Balance renderer becomes visible. The hidden renderer's A/B values,
Money-flow ratio, selected mode, settings, and phase are never overwritten.

An opposite trigger during an active transition reverses the same foreground,
text-background, and full-background animation group from its current visual
progress. It must not snap, queue another transition, or briefly show both
endpoint fields unbounded. A fresh settled-state transition captures the
currently visible dynamic frame, avoiding discontinuity when Portal fog has
moved since delivery.

## Switch, mode, and preview behavior

- Every one of the three layer switches preserves the last selected mode and
  settings while off.
- Switching a layer off during its own active animation cancels that animation,
  clears its transient styles, and deterministically commits the shared target
  state without changing the other two layer switches.
- Turning a layer on while an endpoint is settled does not replay the entire
  delivery. It prepares that layer for the next toggle.
- Changing the settled Portal-field mode or any of its controls while a Portal
  message is visible uses the accepted short field-only preview crossfade; text
  and local text-background effects do not replay.
- Changing the transition mode while an endpoint is settled affects the next
  toggle. During an active toggle it is deferred until that toggle settles.

## Fallbacks and performance

- `prefers-reduced-motion` uses a 160 ms endpoint crossfade for enabled text and
  background layers; the local reaction becomes opacity-only. The Portal field
  renders a deterministic still frame.
- Without canvas, the Portal endpoint is a solid A field and the background
  transformation is an immediate endpoint switch. Content and accessibility
  state still commit correctly.
- Without Web Animations, all enabled layers use deterministic endpoint commits
  and every disabled layer remains genuinely absent.
- Use one resize-aware live Portal canvas and one temporary full-header
  transition compositor. Stop or throttle hidden/offscreen work and reuse
  buffers rather than allocating a canvas for every fog island.
- All generated mask values, colors, alpha, blur, scale, and geometry are
  clamped. Invalid descriptors fall back to the correct endpoint, never to a
  half-visible hybrid.

## Verification contract

Automated verification must cover:

- exact three-layer switch ownership and independent settings;
- true zero-output text-background off state, including absence of the old
  unconditional foreground accent;
- full-header visual layers outside the padded content viewport;
- exact new Portal mode order and removal of the four invalid message modes;
- A-everywhere/B-mask color semantics at deterministic test pixels;
- distinct deterministic frames and per-control sensitivity for every new
  Portal dynamic mode;
- absence of fixed left/right seams, horizontal bands, repeated flame lanes,
  and out-of-range pixels in sampled renderer frames;
- exact three-mode transition order, forward/reverse endpoints, source/target
  preservation, and per-control sensitivity;
- immediate but distinct endpoint switching when full-background morph is off;
- shared in-flight reversal and switch-off cleanup without queued animations;
- unchanged Balance signatures, Money-flow semantics, touch source contract,
  content accessibility, manual-input behavior, and slider-container scrolling;
- JavaScript syntax, inline-script parse, static DOM/source assertions, HTTP
  source smoke, and `git diff --check`.

Visual completion additionally requires Android-browser screenshots and direct
interaction inspection of all five Portal endpoint modes, all three background
transitions in both directions, every layer on/off independently and in useful
combinations, rapid reversal, full-header edge coverage, local reaction
containment, text readability, preserved touch trails, and scrollable controls.
Until that evidence exists, the new UI-facing checklist items remain `PARTIAL`.
