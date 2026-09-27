# Balance Wave Physical Visibility Acceptance Checklist

| ID | Source | Owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| WV-01 | Physical logs + §0–5 | `balance_carousel_wave_motion.dart` | The final, card-sized painted boundary has materially visible movement, not only changing normalized controls. | Pure pixel-boundary test and bounded runtime sample. | DONE |
| WV-02 | §2 | `balance_carousel_wave_diagnostics.dart` | `VISIBLE_MOTION_SAMPLE` reports actual local phase, card-pixel boundary range/delta, alpha and clip data without frame flooding. | Diagnostic unit test. | DONE |
| WV-03 | §3–5 | wave resolver/painter | Center selected wave reaches an authored 4–8 px full-cycle visible travel; profiles remain deterministic and local phase differs by card. | Pure motion/painter tests. | DONE |
| WV-04 | §6–10 | Balance settings/controller/tuner/runtime | One `0.25×–3.00×` speed setting defaults to `1.00×`, changes rate live without controller/profile/phase reset, and emits `SPEED_CHANGED`. | Settings, runtime and widget tests. | DONE |
| WV-05 | §9–10 | debug console/logger | Existing Balance Wave filter contains new prefix events and sampled status exposes speed, local phase and visible motion. | Debug-console test. | DONE |
| MI-01 | §11–16 | `balance_category_movers_card.dart` | Both Pages use 21 px lowercase `i`, retain a 44 px hit target and preserve overlays/chart metrics. | Widget geometry/interaction test. | DONE |
| REG-01 | §17–26 | focused dashboard suite | No carousel physics, defaults, count-row, or Movers chart-compaction regression. | Focused tests, format, diff check, analyze. | DONE |
| USER-01 | §24–26 | physical APK | User validates visible motion at 0.25×, 1× and 3×. | User only. | PENDING — USER ONLY |

## Architecture card

- **Clock owner:** existing `_BalanceUpperCarouselState`; no new ticker/controller.
- **Settings owner:** existing `BalancePresentationSettings` and `BalancePresentationController`; speed is a presentation-only value.
- **Geometry owner:** existing `BalanceCarouselWaveMotion`; it will own local phase, actual card-pixel visible-boundary measurement and the authored visible amplitude.
- **Diagnostics owner:** existing `BalanceCarouselWaveRuntimeDiagnostics` and the existing `FluviDiagnosticLogger` ring.
- **UI:** only renders settings/intent; it does not own a second clock or repository/data workflow.
