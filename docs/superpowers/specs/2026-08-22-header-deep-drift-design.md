# Header runtime proof and Deep Drift design

## Header runtime proof and Deep Drift architecture card

### Scope and sources

- User requirement: normal production Header must prove the active runtime-shader backend, keep per-fragment spatial evaluation at every normal tuner quality, repair source-proven Color Lab mismatches, and add the shared `Mélységi áramlás` effect.
- Accepted reference paths: `docs/prototypes/color_lab.html`, its read-only linked `color_lab_portal_energy.js` source in the local Spendee reference worktree, and the user's current physical diagnostic-log report.
- Existing implementation paths: `dashboard_header_visual_engine.dart`, `dashboard_header_fragment_backend.dart`, `dashboard_header_tap_wave.dart`, `dashboard_header_portal_material_field.dart`, and `shaders/dashboard_header_field.frag`.

### Single source and write path

- Current palette and semantic frame: `DashboardHeaderVisualController` and `DashboardHeaderVisualFrame`.
- Continuous time: the existing dashboard-lifetime Header clock in `DashboardHeaderVisualController`.
- GPU resources: `DashboardHeaderFragmentBackend`; exactly one retained `FragmentProgram` and retained shader instance.
- Deep Drift geometry: a render-only fixed-slot skeleton owned by the fragment input cache. It consumes the existing elapsed time and tuner settings, and writes no dashboard/domain state.
- Tuner intent: existing `DashboardHeaderVisualController.setEffectControl`; RAM-only `DashboardHeaderVisualTuning` remains the only write path.
- Legacy mesh: failure fallback only, selected only when the retained shader cannot be used.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Header A/B palette | Existing mode policy/frame | Semantic selection | Narrow Header input update |
| Effect/tuner values | Existing visual controller | Dashboard lifetime | Explicit tuner action only |
| Shader readiness/failure | Fragment backend | Header paint-resource lifetime | One semantic diagnostic event |
| Deep Drift 15-slot skeleton | Fragment input cache | Header resource lifetime | Render input only; no notifier |
| Tap wave | Existing bounded tap-wave state | Source-defined lifetime | Shared clock repaint only |

### Centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Animation time | `DashboardHeaderVisualController` | Reuse; no Deep Drift ticker/controller | phase identity tests |
| GPU program | `DashboardHeaderFragmentBackend` | Reuse one shader asset/program | program identity tests |
| Effect metadata/tuner controls | `DashboardHeaderEffectCatalog` | Add Deep Drift spec here | catalog/widget tests |
| Dynamic colors | Existing Header visual frame | Reuse A/B; no Deep Drift palette owner | A/B live-input tests |

### Layer flow

`mode policy → immutable Header frame → fragment input cache/skeleton → retained shader → clipped Header paint`, with the existing Canvas tap overlay/trail above the shader.

### Current Color Lab ↔ shader audit

The target worktree's `color_lab.html` links the Portal JavaScript modules but
does not contain them. They were read as a read-only local reference from the
Spendee worktree; that reference is an audit input, not a production dependency.

| Source area | Previous shader difference | Resolution | Status |
| --- | --- | --- | --- |
| MindPortalEnergy value noise | Float sin-hash differed from the source's 32-bit integer lattice | Separate `energyHash` implements the source multiply/xor sequence | Corrected |
| Cellular field | Generated cells substituted source seed tuples | Fixed seven source seed tuples are selected in the fragment shader | Corrected |
| Balance charges | Generated charge positions substituted source seed tuples | Fixed eight source seed tuples are selected in the fragment shader | Corrected |
| Portal message material noise | Shared integer hash incorrectly changed the Portal's distinct source channel | Separate source-style `portalHash2`/`portalValueNoise` path | Corrected |
| Portal Gaussian | Shared Header Gaussian missed the Portal source's `.5` exponent factor | Dedicated `portalGaussian` used in island/cloud paths | Corrected |
| Browser CSS gloss/blur/saturation | Browser composite and Flutter retained shader/Canvas composite are different renderer APIs | Remains physical visual-parity acceptance item; no blur used to mask the difference | Requires device evidence |

### Non-negotiable constraints

- No SQL, Room, repository, bridge, SVG, prewarm, aggregation, semantic publication, CoreDashboard/rail/TimeRail/LogBox rebuild during phase paint.
- Do not modify CenteredCarousel or TimeRail physics.
- No alternate main, WebView, prototype route, second program, ticker, or animation controller.
- Physical source parity and runtime backend proof require the normal `lib/main.dart` APK diagnostic log; automated tests can protect the contract but cannot substitute for a device result.
