# Space Fabric single-speed timebase repair checklist

## Architecture card

### Scope and sources

- User requirement: repair the proven secondary Space Fabric speed scaling
  without changing the compensated metric-warp geometry.
- Current reference: `b9ebed315d7bb5f5d1a36dfba8383d41d3754769`.
- Existing owners: `DashboardHeaderVisualController` owns the one Header
  phase/ticker; `spaceFabricSourceUv` consumes that phase in the runtime
  shader.

### Single source and write path

| State | Owner | Write path | Lifetime |
|---|---|---|---|
| Effect phase rate | `DashboardHeaderVisualController._advance` | shared ticker → `_phase += delta * speed` | Header lifetime |
| Space Fabric local time | `spaceFabricSourceUv` | derived only from `uPhase` and fixed variant frequencies | one fragment evaluation |
| Temporal diagnostics | `DashboardHeaderVisualDiagnostics` | explicit/manual probe only | diagnostic call |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
|---|---|---|---|
| Animation speed | `DashboardHeaderVisualController` | Reuse; no shader-local speed multiplier | source contract + controller test |
| Header clock | controller ticker | Reuse; no ticker/timer/controller added | lifecycle tests/source audit |
| Metric geometry | `spaceFabricSourceUv` kernel | Preserve; alter time input only | shader diff + raster tests |

| ID | Source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| TIME-01 | Root-cause audit | controller/shader | Controller remains the sole speed owner; shader has no secondary speed scaling. | Source-contract RED/GREEN test. | DONE |
| TIME-02 | RED-02–05 | temporal raster test | Every default Space Fabric variant differs materially at 1/3/8 seconds. | Runtime-shader raster diffs. | DONE |
| TIME-03 | RED-06–08 | temporal raster/controller test | Speed zero freezes; higher speed advances phase faster without changing initial geometry. | Controller and raster tests. | DONE |
| TIME-04 | Diagnostics | visual engine | Bound diagnostic records single-speed timebase ownership; temporal probe is explicit only. | Diagnostic test/source audit. | DONE |
| TIME-05 | Protected architecture | shader/controller | Full Field, static, Cool/P/W, ABI v3, Portal/touch and IDs remain unchanged. | Focused regression tests and protected diff. | PARTIAL — full regression/CI pending |
| TIME-06 | Delivery | CI/APK | Exact remote match, required CI success, normal profile APK downloaded and hashed. | GitHub Actions/release SHA. | NOT DONE |
| TIME-07 | Physical acceptance | Android | Four default variants visibly evolve; speed progression verified by a human. | Fresh device/log evidence. | NOT DONE |
