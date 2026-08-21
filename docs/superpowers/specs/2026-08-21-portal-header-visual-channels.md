# Portal Header visual channels — architecture card

## Scope and sources

- User requirement: the Portal addendum following the shared Header visual
  engine task.
- Approved source: `docs/prototypes/color_lab.html` (SHA-256
  `35141d35c9661b00a8a964a1f00d74fd1edee8a8b87d45f6e2946da25254befd`).
- The current product checkout contains that identical HTML but not its linked
  prototype modules.  The identical local Spendee worktree supplies the linked
  audit source: `color_lab_portal_message_field.js`,
  `color_lab_portal_message_field_renderer.js`,
  `color_lab_portal_interior_motion.js`, and
  `color_lab_portal_interior_motion_renderer.js`.
- Existing implementation: `dashboard_header_visual_engine.dart` and
  `dashboard_header_visual_tuner.dart`.

## Source audit verdict

| Property | Portal inner motion | Portal background morph | Same? |
| --- | --- | --- | --- |
| selector id | `data-portal-interior-motion-mode-select` | `data-portal-message-field-mode-select` | no |
| source state | `portalInteriorMotionState` | `messageFieldMode/settings/phase` | no |
| mode order/ids | five `PortalMessageField.modeOrder` values | five `PortalMessageField.modeOrder` values | yes |
| labels/default | source field labels; `wandering-mist` | source field labels; `wandering-mist` | yes |
| per-mode settings/defaults | delegates directly to `PortalMessageField` | owns `PortalMessageField` settings | yes |
| time math | delegates to `PortalMessageField.advancePhase` | directly calls `advancePhase` | yes |
| renderer | translucent darker-side overlay, optional rotated sampling plane | opaque full A→B material field | no |
| reset | active mode field settings; rotation survives | active mode field settings; solid also resets center/window | no |

The shared mechanism is therefore one pure five-mode material-field catalog.
It has two independent channel configurations and two narrow paint adapters.
No second financial palette owner is introduced: `DashboardHeaderVisualFrame`
continues to provide A, B, opacity, and canonical target gradient data.

## Single source and write path

| State | Owner | Lifetime | Write path |
| --- | --- | --- | --- |
| Header palette A/B/opacity | existing mode color policy → `DashboardHeaderVisualFrame` | semantic publication | existing Budget presentation and tuner width/opacity control |
| Portal inner selection/settings/rotation | `DashboardHeaderVisualController` | dashboard | tuner intent → controller |
| Portal background selection/settings/center/window | `DashboardHeaderVisualController` | dashboard | tuner intent → controller |
| phase | existing one `Ticker` in `DashboardHeaderVisualController` | dashboard | ticker elapsed delta only |
| visual output | narrow Header painter | paint frame | immutable controller/frame reads only |

UI only collects tuner intent and renders immutable data.  There is no
repository, Room, bridge, cache, query, SVG, prewarm, or financial aggregation
path in either Portal channel.

## Composition and exclusions

The background field paints first, then the existing common effect recipe, then
the interior translucent overlay, all under the existing card clip; static
Header semantic content remains above them.  The source does not display the
two visual endpoints simultaneously because its Portal semantic state swaps
canvases.  That semantic state is excluded by the user; production keeps the
independent source configurations and composes both visual channels in the one
non-semantic Header surface.  This composition is the user-authorized product
adaptation, not an invented second state machine.

Excluded: Portal button/content replacement, navigation, message workflow,
`Portal háttérreakció`, and Balance→Portal transition controls.  The latter
belong to different source selectors and are not controls of either requested
five-mode channel.

## Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Header clock | `DashboardHeaderVisualController` | extend | one ticker identity test |
| A/B palette | `DashboardHeaderVisualFrame` | consume | policy/live-edit tests |
| five-mode field math | new neutral Portal field catalog | share | source equivalence tests |
| inner/background state | controller channel configurations | keep separate | independent-selector/reset tests |
| Header card clipping | `DashboardCoreModeHeaderScaffold` | preserve | painter/widget tests |

## Verification

- Pure source catalog and deterministic field samples at 0/25/50/75/100%.
- Controller state, one-clock, idling and no-semantic-publication tests.
- Tuner interaction tests for both sections and reset isolation.
- Header painter/repaint identity tests.
- Existing dashboard boundary script, Flutter focused suite, analyzer, CI and
  normal human APK delivery.
