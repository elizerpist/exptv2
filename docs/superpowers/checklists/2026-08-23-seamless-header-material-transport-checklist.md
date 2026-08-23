# Seamless Header material transport — acceptance checklist

Source: user specification, 2026-08-23; current baseline `69d109c1e1f53ab4c0d2b66f5c576577de3e99c9`.

| ID | Source requirement | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SMT-01 | Current-source audit and physical screenshots | `shaders/`, Header tests, Android screenshots | All eight effects and both Portal channels are audited against the current remote source. | Pre-flight record, source inspection, screenshot review. | DONE |
| SMT-02 | Preserve static/Cool/ABI/sampler foundations | static renderer, fragment ABI v3, palette sampler | Static 112° pixels, Cool P/W semantics, ABI v3, no endpoint RGB authority, and direct 2/3-stop sampler remain unchanged. | Focused static/backend/palette tests and source checks. | NOT DONE |
| SMT-03 | One shared seam-decoupled transport contract | `dashboard_header_field.frag` | Shared boundary envelope, bounded source-UV transport, and bounded base→candidate-U interpolation are used before palette lookup. | Shader source contract and quantitative raster suite. | NOT DONE |
| SMT-04 | Common effects: Dual Tide, Magnetic Membrane, Breathing Lens, Cellular Field | shader common-effect flow helpers | Each effect deforms source UV with its own smooth material flow; no `mixture` target coordinate or generic seam light remains. | Per-effect distribution, seam-decoupling, constant-colour optics, real-Cool fixtures. | NOT DONE |
| SMT-05 | Balance material contract | shader balance flow helpers | Membrane, Counterflow, and Charges use one continuous spatial material rather than side/boundary palette ownership. | Per-effect distribution/seam and source-contract tests. | NOT DONE |
| SMT-06 | Deep Drift evidence gate | `deepDriftField` | Retain 3×5 geometry and change it only when metric evidence requires the shared bounded transport helper. | Deep-Drift and distribution tests. | NOT DONE |
| SMT-07 | Portal/touch contract | shader Portal/touch composition | Portal masks only cover/blend transported material; touch stays pre-lookup with independent magenta optics. | Portal/touch raster and source tests. | NOT DONE |
| SMT-08 | Distribution and continuity RED suite | new `dashboard_header_material_transport_distribution_test.dart` | Deterministic 412×188 neutral, real-Cool, narrow-window, strong, derivative/fold, temporal and zero-strength checks cover every effect. | New focused Flutter suite. | NOT DONE |
| SMT-09 | Optics cannot form a neon barrier | shader optics and tests | Constant-colour palette has no narrow persistent ridge; optics are broad, material-derived and effect-specific. | Optical-stripe oracle and source contract. | NOT DONE |
| SMT-10 | Diagnostics | visual engine | Transport diagnostic reports seamless material revision/flags and exposes explicit non-frame distribution and optical probes. | Visual-engine diagnostics tests. | NOT DONE |
| SMT-11 | Runtime/hot-path/identity protection | Header renderer and existing protected areas | One Header clock, retained program/shader identities, and zero protected data/render work on phase tick; Dashboard interaction boundaries unchanged. | Focused/protected suites, explicit `centered_carousel` diff. | NOT DONE |
| SMT-12 | Additive milestone and delivery | Git, `MILESTONE_COMMITS.md`, GitHub Actions, APK | Focused commits, behavioral milestone CI/APK then docs-only additive child; old milestone bytes identical. | Git diffs, exact SHA/remote match, CI and APK SHA-256. | NOT DONE |
| SMT-13 | Human Android acceptance | normal `lib/main.dart` profile APK | Required physical scenarios and fresh diagnostics are confirmed only by the user. | Fresh Android physical run/log. | NOT DONE |

## Material contract

`uv → effect sourceUv → canonicalGradientCoordinate(sourceUv) → distributionSafePaletteCoordinate(baseU, candidateU, strength) → sampleCanonicalPalette → effect-specific broad optics`.

The effect boundary may guide flow or shading, but never owns a palette coordinate. Static rendering is outside this animated path.
