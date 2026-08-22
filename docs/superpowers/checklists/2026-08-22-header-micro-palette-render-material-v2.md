# Header micro-palette, touch-render, and material-field acceptance checklist

## Evidence inventory

- Approved palette responsiveness reference: `docs/prototypes/color_lab.html:102-115` (`Cool`, 10 stops, 28% window).
- Approved touch reference: `docs/prototypes/color_lab.html:3318-3428, 22357-22375, 22444-22527`.
- Physical screenshot inspected: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260822-083733.png`.
- Current source baseline: `8a69acdd0d36df5db9211bc088b12144d3e8b862`.
- Current source evidence: `dashboard_header_budget_palette.dart` has canonical index 5 and one pale-to-canonical OKLab lead; `dashboard_header_field.frag:131-137` uses unsupported `uint`; `dashboard_header_tap_wave_painter.dart` uses a separate `saveLayer`/blur Canvas path; `deepDriftField` gives each depth layer a fixed A/B coordinate.

| ID | Source requirement | Owner/code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PAL-01 | User palette V2 slots 1–10 | `dashboard_header_budget_palette.dart` | Exactly 21×10 generated micro-palettes; exact canonical color at visible slot 7 | unit fixture + catalog test | DONE |
| PAL-02 | User local sister-hue corridor | palette generator + `CategoryColorCatalog` | Piecewise OKLCH corridor follows cyclic neighbors without second color authority | unit perceptual/family tests | DONE |
| PAL-03 | User 28/30% responsiveness | sampler + diagnostic snapshot | Every representative category/window remains perceptually informative, not merely RGB-distinct | all-category metric test | DONE |
| PAL-04 | User live tuner visualization | `dashboard_header_visual_tuner.dart` | Existing collapsible section shows numbered slots, slot-7 marker, active window and A/B edges | widget test + final physical screenshot | PARTIAL |
| PAL-05 | User freeze 210 values | palette test fixture | Generator deterministically reproduces reviewable 21×10 output fixture | fixture test | DONE |
| REN-01 | User physical backend proof | Header paint resources + diagnostic logger | Normal diagnostic stream receives backend, ready/fallback and fidelity events for an active Header | logger/paint-path test + next human APK log | PARTIAL |
| REN-02 | Flutter runtime-shader compatibility | `dashboard_header_field.frag` + backend test | No unsupported runtime-stage GLSL (`uint`/bool); shader compilation/load reaches ready rather than fallback | runtime-stage build check + test | DONE |
| REN-03 | User native pixel path | fragment paint layer | DPR-aware full-surface fragment route, no normal mesh selection or scaled low-res intermediate | plan test + source/paint inspection | PARTIAL |
| TOU-01 | User touch A/B isolation | tap wave state/painter/shader | Field-only, overlay-only and combined paths are independently inspectable in deterministic tests | focused tests/diagnostics | DONE |
| TOU-02 | User touch continuity | shader touch composition | Overlay and trail are native fragment-space analytical fields (or evidence-backed retained native pass), with no Canvas low-resolution blur path | source contract + render path diagnostic + screenshot | PARTIAL |
| DRI-01 | User continuous material color | deep drift math + fragment shader | A/B comes from total density + continuous weighted depth, not fixed depth-layer colors | math/cross-section tests | DONE |
| DRI-02 | User continuous Z migration | retained Deep Drift skeleton | Scale, opacity, parallax/light/color influence derive from one smooth apparent-depth value | deterministic skeleton tests | DONE |
| DRI-03 | User no light/dark sheets | shader + color math | Adjacent cross-section color/alpha/depth changes are bounded; rich A/B stays coherent | deterministic continuity tests + screenshot | PARTIAL |
| ARC-01 | Protected motion/data architecture | Header controller/painter only | One Header clock/program; zero data/repository/native work and zero semantic dashboard rebuilds on phase frame | existing boundary/hotpath tests | DONE |
| ARC-02 | No physics regression | shared centered carousel | No behavioral diff to physics | source diff + protected tests | DONE |
| DEL-01 | Normal app delivery | CI + artifact | Normal `lib/main.dart` human APK is built by GitHub Actions, downloaded to `/storage/emulated/0/Download/fluvi`, SHA-256 recorded | CI/artifact check | NOT DONE |

## Verification notes

- Focused Header, palette, touch, Deep Drift and diagnostic tests: PASS.
- `flutter analyze --no-fatal-infos`: PASS.
- `scripts/test-fluvi-fast.sh`: PASS (248 tests).
- Full `flutter test`: blocked by pre-existing
  `dashboard_rail_density_trace_test.dart` failures. Its own isolated rerun
  reproduces a 721px fling target outside the default 800×600 test surface,
  followed by missing trace events and a pending-plane expectation mismatch.
  None of its stack frames or sources overlap this change set.
- Physical APK/diagnostic capture, visual screenshot comparison, CI and normal
  human APK delivery remain outstanding; no physical fidelity claim is made.
