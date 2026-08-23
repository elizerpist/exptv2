# Header Continuous Palette Transport — Recovery Acceptance Checklist

Source instruction: recovered Codex session `01a01c31-6f06-71a1-b7c7-93f235789b2b`,
user request of 2026-08-23 to complete the interrupted work. Reference
implementation/state: `separated-core-modes` at `b81bacc2b46ca5c7b9c5565022591f44b79c588a`,
`MILESTONE_COMMITS.md`, and the original accepted static Cool implementation.

| ID | Requirement/source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CPT-01 | Root cause: animated effects collapsed `P(u)` to endpoint A/B RGB | Header shader/fragment ABI | Effects transport palette coordinates and do not choose RGB identities | Source audit plus midpoint-sensitivity tests | DONE |
| CPT-02 | Preserve accepted static Cool source and P/W semantics | `dashboard_header_budget_cool_source.dart`, static renderer | Exact 10 authored source stops; three sampled A/M/B probes; unchanged 112° static field | Focused Cool/static tests | DONE |
| CPT-03 | ABI v3 removes endpoint RGB authority | fragment ABI and shader | No `uColorA`, `uColorB`, or endpoint paint-input fields; canonical bank only | `dashboard_header_palette_transport_test.dart` | DONE |
| CPT-04 | One continuous canonical palette sampler | shader | Arbitrary coordinate samples canonical colors/stops continuously; static uses the same semantic sampler | Shader/source contract and shader-load test | DONE |
| CPT-05 | All standard, Balance, Deep Drift and Portal material lanes use `P(U)` | shader | Same endpoints plus changed midpoint materially changes every animated lane | Focused palette-transport widget suite | DONE |
| CPT-06 | Zero-strength parity and bounded palette support | shader/test | Animated zero-strength matches static; Dual Tide/Deep Drift retain broad support without endpoint plateaus | Focused palette-transport suite | DONE |
| CPT-07 | One shared Header clock; no data/UI hot-path regression | visual controller/backend | No new tickers, persistence, Query, LogBox, or rail work on phase ticks | Existing Header/motion suites and profile evidence | PARTIAL |
| CPT-08 | Deep Drift and Portal retain their required material/optical ownership | shader/portal/deep-drift owners | One palette material for Deep Drift; Portal samples palette coordinates; pink touch optic remains independent | Focused deep-drift, Portal, tap-wave and transport suites | DONE |
| CPT-09 | Required low-frequency palette diagnostics | visual engine | Palette-field and effect-transport diagnostics declare ABI v3 and no endpoint authority without frame logging | Direct code audit and profile log | DONE |
| CPT-10 | Keep protected dashboard interactions unchanged | Dashboard/CenteredCarousel/TimeRail owners | No physics, controller-identity, committed-viewport, Query, or LogBox regression | Protected test suites and explicit physics diff | DONE |
| CPT-11 | Production profile remains within CI watchdog | shader palette sampling | The common 2-/3-stop Cool fields avoid a generic 10-slot interval scan while preserving the same continuous output; 4–10 stops remain supported | RED/GREEN contract tests plus successful A–J profile | PARTIAL — local contract/compile tests pass; exact-SHA A–J CI profile is pending |
| CPT-12 | Full CI and normal human APK delivery | GitHub Actions and `/storage/emulated/0/Download/fluvi` | Exact final SHA has all required CI jobs successful and its normal `lib/main.dart` human APK is downloaded with SHA-256 | GitHub Actions, local file check, SHA-256 | PARTIAL — final SHA has not yet been pushed |
| CPT-13 | Human physical acceptance | normal APK/manual Android | All static, effects, Portal, touch, P/W, target-independence and performance observations are inspected on device | User/device evidence | NOT DONE |
