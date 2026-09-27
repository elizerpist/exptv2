# Category Movers Compaction and Balance Wave Forensics Acceptance Checklist

| ID | Source | Code owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CM-01 | §1–5 | `balance_category_movers_card.dart` | Page 1 shows title, `?`, compact selector and all bounded rows without permanent explanation/footer or normal-card scrolling. | Real 412×892 lower-card test with five movers, bounds assertions and overflow capture. | DONE |
| CM-02 | §3 | `balance_category_movers_card.dart` | Page-1 `?` opens/closes one grey in-card explanation overlay; it does not change outer-card bounds. | Widget tap/bounds test. | DONE |
| CM-03 | §4 | `balance_category_movers_card.dart` | Direction segments are 30–32 logical px high, 100–112 logical px wide, separated by 7–8 logical px, with retained semantics. | Widget geometry/semantics test. | DONE |
| CM-04 | §6–11 | `balance_category_movers_card.dart` | Page 2 has no normal-flow KPI row or permanent explanatory/footer copy; cumulative chart is immediately visible and uses the reclaimed space. | Widget chart/bounds plus refreshed inspected goldens. | DONE |
| CM-05 | §7–10 | `balance_category_movers_card.dart` | Page-2 `?` and chart tap select mutually-exclusive grey overlays; metrics has exactly current, percentage and delta. | Widget gesture/overlay test. | DONE |
| CM-06 | §12–13 | `dashboard_shell_presentation.dart`, core dashboard wiring | Shell defaults to eligible `modeContent` stretch while retaining straight/contained-flat, count-safe clamp, reset and user overrides. | Shell/default geometry tests. | DONE |
| WAVE-01 | §14–16 | carousel runtime + diagnostic logger | Forensics distinguishes source-proven behavior from runtime-unproven behavior and final implementation emits bounded `BALANCE_WAVE|` events only. | Runtime telemetry test. | DONE — source cause proven; device observation remains USER-01. |
| WAVE-02 | §20–21 | `balance_dashboard_core_surface.dart`, wave motion resolver | One stable shared clock repaints only waves; enabled phase changes geometry, static/reduced motion freezes it, profiles remain identity-stable and loop continuously. | Widget/pure motion tests. | DONE — automated only; physical acceptance remains USER-01. |
| WAVE-03 | §15 | wave runtime telemetry | Bound, profile, clock, geometry, loop, frame-summary and settings events include required factual fields without per-frame ring flooding. | Simulated 32-second cycle proves 4-summary/16-settings caps. | DONE |
| DEBUG-01 | §17–19 | `debug_console.dart`, carousel runtime | Balance Wave dropdown filters only `BALANCE_WAVE|`, shows an already-sampled status pull, and bug marker includes latest wave context with no second history. | Debug console/logger and carousel marker tests. | DONE |
| REG-01 | §10–13, §22–26 | dashboard/card test suites | No query/data/selection/carousel/collapse/count regression; on-demand hit regions do not steal outer gestures. | Final 121-test focused dashboard/presentation suite. | DONE |
| DELIVERY-01 | §26–28 | repository / GitHub Actions | Formatting, diff check, analyze, tests, code review, production commit/push and human APK delivery are complete. | `867b67d4`, Actions run `36311698137` human-APK job, downloaded artifact SHA-256. | DONE |
| USER-01 | §28 | physical device | Physical acceptance of wave and compact composition remains user-only. | User | PENDING — USER ONLY |

## Architecture card

- **Source of truth:** immutable `DashboardBalanceCategoryMoversPresentation` remains the only financial/window data input. Local overlay and page state belongs to `BalanceCategoryMoversCard`.
- **Wave state:** one `_BalanceUpperCarouselState` controller is the only ticker owner. A dedicated bounded runtime observer records controller/painter facts and exposes the latest sample solely to the existing logger/marker provider.
- **Shared mechanisms:** the existing immutable profile/geometry resolver remains the one wave identity and periodic-motion source. The existing logger ring remains the only diagnostic history and the existing Debug Console remains its only view.
- **UI boundary:** widgets collect overlay/chart/info intent and render prepared values; no overlay, painter, diagnostics or gesture path reads repositories or recomputes financial data.
