# Header palette orientation and space-fabric acceptance checklist

## Architecture card

### Scope and sources

- User requirement: additive palette-axis drift above the established Full
  Field Flow lane, plus an independent local metric-warp family.
- Accepted reference: `b2ec151714584bd77be1e2d13aecbddc75222c0c`.
- Existing owners: `DashboardHeaderVisualController`,
  `DashboardHeaderVisualTuning`, `DashboardHeaderEffectCatalog`,
  `_DashboardHeaderFragmentUniformCache`, and
  `shaders/dashboard_header_field.frag`.

### Single source and write path

| State | Owner | Lifetime | Write path |
|---|---|---|---|
| Palette orientation tuning | `DashboardHeaderVisualTuning` | Dashboard Header | Tuner intent → `DashboardHeaderVisualController` |
| Active animation family/effect | `DashboardHeaderVisualTuning` | Dashboard Header | `selectAnimationFamily` / `selectEffect` |
| Packed shader scalars | `_DashboardHeaderFragmentUniformCache` | Renderer | Derived from immutable tuning only on configuration changes |
| Source UV | Runtime fragment shader | Fragment | Full Field inverse advection or Space Fabric metric warp |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
|---|---|---|---|
| Animation clock | `DashboardHeaderVisualController` | Reuse; neither feature gets a ticker | Controller lifecycle tests |
| Palette sampling/Cool P/W | canonical shader sampler + Cool source | Reuse; no second palette path | Palette regression tests/source audit |
| Boundary treatment | material/full-field envelope helpers | Reuse only as a soft metric-warp taper | Jacobian/edge tests |
| Local metric kernel | new shader helper | One reusable compensated core, with variant parameters | Source contract + deterministic probes |

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| ORI-01 | User Part A | Tuning/controller | Family-owned immutable orientation state has enabled/base/sweep/speed/phase; default is OFF. | New controller/widget tests. | NOT DONE |
| ORI-02 | User A01/A04 | Shader coordinate helper | OFF uses the audited fixed 112° path exactly; dynamic 112° helper has coordinate parity. | Frozen/source coordinate tests. | NOT DONE |
| ORI-03 | User A07–A11 | Shader | Oscillatory angle reverses smoothly; it changes palette projection only, never Full Field `sourceUv`. | Deterministic angle/source-map tests. | NOT DONE |
| ORI-04 | User A12–A14 | Flow tests | Enabled orientation increases two-axis light/dark mass mobility without becoming rigid image rotation. | Deterministic raster/grid tests. | NOT DONE |
| ORI-05 | User A15–A18 | Portal/backend | Portal uses the active angle; touch remains before source sampling; 36–39 are only family-reserved slots. | Source/ABI/backend tests. | NOT DONE |
| FAB-01 | User B01/B02 | Catalog/tuner | Explicit `spaceFabricWarp` family and stable IDs 14–17, with one active effect selector. | Catalog/widget tests. | NOT DONE |
| FAB-02 | User B03/B17/B18 | Shader | Strength-zero parity; P/W and midpoint only alter palette lookup, not warp geometry. | Palette/source-map tests. | NOT DONE |
| FAB-03 | User B04–B16 | Shader | Four effects use one analytical, anisotropic, compensated local metric source-UV core; no visible-object/RGB authority. | Shader contract/raster tests. | NOT DONE |
| FAB-04 | User B06–B14 | Metric tests | Default mappings have positive Jacobian, local magnification and neighboring compression, bounded global area change, no edge plateau/foldover. | Dense grid Jacobian probe. | NOT DONE |
| FAB-05 | User B09/B10/B19–B21 | Metric tests | Seeds deterministic; mode field moves and changes shape continuously; speed zero freezes temporal evolution only. | Deterministic phase tests. | NOT DONE |
| FAB-06 | User B27–B32 | Composition/lifecycle | Portal/touch compose over metric source UV; family switching retains the sole controller/clock/program owner. | Source/backend/widget tests. | NOT DONE |
| SAFE-01 | Protected architecture | Header/Dashboard | Cool P/W, static 112°, ABI v3, sampler specialization, existing Full Field equations/defaults, and Dashboard motion owners remain unchanged. | Regression suite, source audit, protected diff. | NOT DONE |
| SAFE-02 | User commit/build contract | Git/CI/APK | Three focused commits; push matches remote; CI succeeds; normal `lib/main.dart` profile APK is downloaded and hashed. | GitHub Actions and file SHA-256. | NOT DONE |
| SAFE-03 | User physical contract | Android | Human physical scenarios and fresh diagnostics are recorded only when actually observed. | User/device evidence. | NOT DONE |
