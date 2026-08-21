# Header runtime proof and Deep Drift acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HD-01 | User / current physical log | diagnostics + fragment backend | Normal Header emits backend-bound, ready/fallback, and fidelity configuration events exactly once per semantic surface/configuration | Logger/contract test; normal APK diagnostic log | PARTIAL — automated contract is green; fresh normal-APK log is still required |
| HD-02 | User | fragment render plan | All normal render-scale values use retained per-fragment shader; mesh only follows genuine shader failure | Unit test at .35/.60/.95/1.00 | DONE |
| HD-03 | User | effect catalog/backend input | Common effects use explicit stable shader IDs; enum order cannot change GPU ABI | Unit test/source inspection | DONE |
| HD-04 | Color Lab / user | GLSL and source audit | Source-proven math/composite discrepancies are classified and corrected, not blurred or hidden | deterministic source checkpoints + reference inspection | PARTIAL — source hash/seeds and Portal Gaussian are corrected; physical CSS-composite parity still needs device review |
| HD-05 | User | shared effect catalog/tuner | `Mélységi áramlás` has exact supplied live controls in existing effect UI | catalog + widget tests | DONE |
| HD-06 | User | fragment input/shader | Deep Drift has three layers × five bounded anisotropic cubic blobs, CPU skeleton and analytic lighting | pure math/identity tests and shader inspection | DONE |
| HD-07 | User | shader composition | A/B depth roles, front-to-back Near→Middle→Far composition and touch UV displacement are preserved | deterministic projection tests | DONE — automated; physical visual review remains HD-10 |
| HD-08 | Protected milestones | motion/repaint boundaries | One shared clock/program; no carousel physics or semantic hot-path work | isolation tests, physics diff, CI | PARTIAL — focused isolation tests and physics diff are green; full CI is pending |
| HD-09 | User | delivery | CI green; human normal APK downloaded from GitHub | Actions + hash | NOT DONE |
| HD-10 | User physical acceptance | normal APK | Device log proves shader backend and human checks existing effects/Deep Drift/tuner/rail/TimeRail/tap/Portal | User device test | NOT DONE |

## Verification record before delivery

- Focused Header/Deep Drift/diagnostics suite: **PASS** (50 tests).
- `flutter analyze`: **PASS**.
- Runtime shader asset bundle compilation: **PASS**.
- Full local `flutter test`: **FAIL**, with five failures outside the changed
  Header files: four `dashboard_rail_density_trace_test.dart` cases and one
  `dashboard_scroll_milestone_test.dart` case. They remain release/CI items;
  none is hidden or reclassified as a Header success.
- `git diff -- lib/shared/motion/centered_carousel/centered_carousel_physics.dart`:
  **empty**.
