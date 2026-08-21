# Header maximum-quality renderer and tap-wave architecture card

## Evidence and boundary

This work preserves the existing split:

```text
mode semantic presentation -> per-mode palette policy -> HeaderVisualFrame
                                                      -> one shared Header clock
                                                      -> narrow visual paint lane
```

`DashboardHeaderVisualController` remains the single time owner.  Neither
`DashboardBudgetPresentationController` nor carousel motion owns an animation
clock or tap-wave state.  `CenteredCarousel` physics is explicitly out of
scope.

The current local checkout does not contain a current user-facing `Fluvi Logs`
export.  Exhaustive name searches on 2026-08-21 found only historical CI and
profile files.  This blocks a log-derived CRITICAL disposition, but does not
replace source evidence with speculation.

Current source evidence in `dashboard_header_visual_engine.dart` proves that a
dynamic common Header lane and each enabled Portal lane independently:

1. sample a `columns * rows` procedural field on the UI isolate;
2. allocate/derive a color for every sampled node;
3. invalidate `ui.Vertices.raw` after every color update;
4. rebuild a native vertices object for the next draw.

The geometry is based on logical size and `renderScale`; DPR is recorded in
the diagnostic identity but is not part of the field-resolution formula.  The
`frameMs` control is an audited Color Lab frame interval (16..100 ms), not a
quality multiplier.  At `100`, an otherwise continuous field is intentionally
updated at 10 Hz.  The repair must make the intended high-resolution path
cheap and make temporal-update semantics explicit; it must not quietly reduce
spatial quality or change carousel motion.

## Tap-wave source audit

Source: `docs/prototypes/color_lab.html`, SHA-256
`35141d35c9661b00a8a964a1f00d74fd1edee8a8b87d45f6e2946da25254befd`.
The linked `color_lab_portal_energy.js` audit source is read-only in the
Spendee worktree at SHA `144d78c30dc4cc5e9f230903fd6274c98e62e118`.

The prototype binds only its Mind header, but the production capability is a
shared Header visual interaction.  It does not change the Header semantic
role.

* Trigger: primary `pointerdown`; pointer movement continues the interaction;
  `pointerup`, cancel, or leave releases it.
* Coordinates: Header-local normalized x/y, clamped to `[0, 1]`.
* Fixed overlay palette: `#ffa7e2` / `#ff8bda` / `#8b3eff` / white, with
  source alpha stops `.98/.86/.76/.46` at `0/5/11/19%`, transparent at `25%`.
* Overlay: screen composition, initial opacity `.96`, scale `.8`, blur `7`;
  release scale `1.42`, blur `20`, opacity/filter/transform release durations
  `1560/1560/1640 ms` with source CSS easing.
* Trail: bounded to 26 source DOM nodes; spawn distance/time gate `5.5%/24ms`;
  fixed multi-stop pink palette, 82 px source size, 1350 ms
  `cubic-bezier(.16,1,.3,1)` fade.
* Field ripple: at most 10 active source events, at least 58 ms apart; lifetime
  `1560 * 1.08 ms`; radial distortion and light pulse use the exact source
  equations transcribed in the production pure projection tests.

Production state will be bounded, owned by the shared Header controller, and
advanced from its existing clock.  It will not make an `AnimationController`
per touch or retain an unbounded list.

## Chosen implementation order

1. Add source-derived RED tests for renderer resource/phase boundaries and
   the touch-wave projection.
2. Move stable mesh raster resources out of the continuous color refresh path
   and prove semantic configuration changes happen once.
3. Add the shared tap-wave projection and visual layer under the existing card
   clip, then expose source/app-added tuning controls in the existing tuner.
4. Run focused and full regression suites in Ubuntu, push only focused commits,
   and obtain the normal GitHub human APK.
