# Budget Header palette domain and continuous material design

## Scope and reference inputs

- User acceptance request, 2026-08-22: live Budget category colour scales,
  collapsible Header tuner sections, premium continuous Deep Drift material,
  and no new motion/data-path work.
- Approved visual reference: `docs/prototypes/color_lab.html` and the current
  Android screenshots in `/storage/emulated/0/Pictures/Screenshots`.
- Existing gradient/window contract:
  `docs/prototypes/color_lab_budget_gradient_window_acceptance.md`.
- Current implementation audit: `dashboard_header_visual_engine.dart` uses
  `BudgetHeaderColorScale._scaleSample`, which first samples a three-stop
  canonical gradient and then mixes it from white.  This is the proven live
  white-to-endpoint domain that must be replaced for positive limits.
- Current material audit: Deep Drift's retained skeleton drives a layer-wide
  rotation and the shader projects bounded individual blobs.  This accounts
  for the reported sticker-like/discrete visual grammar.  The normal renderer
  is already a retained per-fragment shader; no sparse mesh is part of the
  normal path.

## Architecture card

### State ownership and write paths

| State | Owner | Write path | Render consumer |
| --- | --- | --- | --- |
| Canonical category identity | `CategoryColorCatalog` | generated category catalog only | `BudgetHeaderPaletteCatalog` |
| Ten-slot category palette | `BudgetHeaderPaletteCatalog` | lazily cached deterministic derivation from a `CategoryGradientToken` | `BudgetHeaderColorWindowSampler`, tuner preview |
| Budget limit palette window | `DashboardBudgetHeaderColorPolicy` | retained `DashboardBudgetPresentationController` selection plus Header tuning | immutable `DashboardHeaderVisualFrame` |
| Palette diagnostics snapshot | `DashboardBudgetHeaderColorPolicy` | one semantic refresh after target/progress/window changes | existing FLOW/on-screen diagnostics |
| Header effect/tuner state | `DashboardHeaderVisualController` | existing live tuner intent methods | narrow Header paint configuration |
| Continuous Deep Drift transforms | existing retained `DashboardHeaderDeepDriftSkeleton` | shared Header elapsed time only | retained fragment shader uniforms |

There is one colour authority per semantic identity: `CategoryColorCatalog`
provides canonical gradients, and `BudgetHeaderPaletteCatalog` deterministically
derives the only ten-slot palette representation from them.  No widget,
renderer, or Budget accounting controller owns an ARGB table.  Aggregate Budget
continues to derive its palette from its existing aggregate gradient authority.

### Palette model

`BudgetHeaderPalette` contains exactly ten immutable colours.  Its canonical
middle colour is placed at slot 6 (zero-based index 5), surrounded by pale,
progressively chromatic lead-in slots and richer, subtly hue-shifted tail
slots.  Generation operates in local OKLab/OKLCH-style space so the result is
not a naïve gamma-RGB white interpolation.  Sampling is continuous between
slots in the same perceptual space.

`BudgetHeaderColorWindowSampler` clamps the finite window using the existing
Color Lab geometry: `rawProgress * 100` supplies the centre, the centre clamps
to `[halfWidth, 100 - halfWidth]`, and the two edge positions produce Header
A/B.  Positive limits always use this palette sampler.  No-positive-limit
targets preserve the existing complete canonical avatar/aggregate gradient.

### Tuner and diagnostics

The existing bounded slide-up card stays the only menu.  It becomes a
scrollable list of two independently collapsible top-level sections:

1. `Header animáció`: current effect, effect controls, colour-window controls,
   Portal, pulse, and tap-wave controls.
2. `Kategória színskálák`: all 21 canonical colour identities, each with its
   own canonical swatch and exactly ten generated palette slots.

Open/closed state belongs to `DashboardHeaderVisualController` and has a
single explicit toggle write path.  The card retains `DashboardHeaderVisualTunerPlacement`;
its top stays below the Header and internal `ListView` owns overflow.

The existing diagnostic logger receives bounded semantic events for palette
binding/window resolution/render target/effect mode/debug snapshot.  These
events do not fire during a phase tick, paint call, or pointer sample.

### Deep Drift correction

Deep Drift remains one shared effect using the existing shared Header clock,
single retained fragment program and stable fixed 3×5 skeleton.  It is changed
from rotation-led independent blobs to a field-led material:

- low-frequency directional layer drift and advection establish the primary
  motion;
- layer rotation is reduced to a subtle secondary shear;
- a smooth low-frequency carrier density joins nearby blobs before alpha and
  colour composition, preventing separated sticker silhouettes;
- density, tone, A/B mix, depth breathing, and lighting remain continuous at
  fragment resolution;
- analytic blob gradient remains the lighting source; weak modulation does not
  create hard tonal quantisation or own the geometry.

This preserves the documented bounded 3×5 cubic-blob contract and does not
add a ticker, controller, CPU pixel field, additional program, or domain work.

## Protected constraints

- No changes to `CenteredCarousel`, its ballistic physics, TimeRail physics,
  Dashboard expansion ownership, or committed query/motion owners.
- No SQL, Room, repository, bridge, SVG/prewarm, aggregation, or prepared
  snapshot reconstruction in Header phase, palette sampling, tuner drag, or
  avatar preview hot paths.
- The normal high-fidelity Header remains `FragmentProgram`/`FragmentShader`
  per-fragment.  Sparse vertices remain shader-failure fallback only.
- The normal app entry point is `lib/main.dart`; no alternate route or harness.
