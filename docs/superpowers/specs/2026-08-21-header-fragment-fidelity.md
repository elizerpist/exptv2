# Header Fragment Fidelity Design

## Goal

Replace the maximum-quality Header's sparse `ui.Vertices` field backend with
a retained Flutter runtime-fragment-shader backend. The shader evaluates the
existing Color Lab field and bounded tap-ripple distortion per fragment,
without changing carousel motion or Header semantic ownership.

## Evidence

- Production source at `c042cdc7882de149794d473bec66cd44a179c53e` evaluates
  the common field at `round(logicalSize * renderScale / 4)` mesh nodes.
  `devicePixelRatio` is recorded but does not increase those nodes.
- At 412 x 188 logical px and scale 1.0 this is about 103 x 47 = 4,841
  samples; the Color Lab canvas path is 412 x 188 = 77,456 samples.
- Portal profiles add source scale `.55`/`.48` before the same Flutter-only
  `/4` mesh reduction.
- `docs/prototypes/color_lab.html` references companion Color Lab modules
  that are absent on this branch. The identical HTML and source modules in
  the read-only Spendee reference worktree are the audit reference; that
  worktree remains untouched.
- A current 502,852-byte Fluvi log export described by the user could not be
  located in the accessible filesystem despite searching home, temporary and
  shared-storage paths. This does not block the source-proven spatial issue,
  but prevents a local chronological log audit.

## Architecture card

| Concern | Existing/new owner | Contract |
| --- | --- | --- |
| Shared clock and tap state | `DashboardHeaderVisualController` | One dashboard-lifetime time source; bounded ripple/trail state. |
| Palette/data | existing `DashboardHeader*ColorPolicy` | Publishes immutable A/B frame only; no shader owns Budget data. |
| High-fidelity field | new retained Header runtime-shader renderer | Per-fragment source math and fixed ripple slots. No per-pixel Dart loop. |
| Low-quality compatibility | existing mesh lane | Explicit fallback only if shader setup fails; never maximum-quality selection. |
| Portal channels | retained shader instances using same program | Preserve independent channel state, but remove their second `/4` sampling reduction. |
| Semantic/Header UI | existing scaffold/content | Shader only invalidates the existing visual repaint boundary. |

## Source reference

- Main HTML: `docs/prototypes/color_lab.html` (SHA-1
  `3ab66463478348f39d416504a06b6763ddcdd2f4`).
- Companion source reference: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/prototypes/color_lab_portal_energy.js`
  and `color_lab_portal_interior_motion_renderer.js` (read-only).
- Official Flutter API: runtime shaders use `FragmentProgram.fromAsset`, a
  retained `FragmentShader`, `#include <flutter/runtime_effect.glsl>` and
  `FlutterFragCoord`; non-sampler uniforms are set in declared order.

## Delivery bounds

- No CenteredCarousel physics, velocity, friction, snapping or TimeRail
  changes.
- No per-frame repository/Room/bridge/SVG/prewarm/domain work.
- No WebView production fallback in this change.
- No per-tap ticker, controller, shader, unbounded uniform list or cache.
