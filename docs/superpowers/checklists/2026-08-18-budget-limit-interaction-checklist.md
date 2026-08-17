# Budget limit interaction acceptance checklist

Reference mechanism: `spendeetest@144d78c30dc4cc5e9f230903fd6274c98e62e118`:

- `lib/features/transactions/widgets/header_card/budget_avatar_limit_halo.dart`
- `lib/features/transactions/widgets/experimental/modes/spendee_budget_mode_host.dart`
- `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`

The reference supplies interaction mechanics only. Production ownership remains
the current `separated-core-modes` Dashboard/FinancialLimit architecture.

| ID | Requirement/source | Intended code area | Acceptance and verification | Status |
| --- | --- | --- | --- | --- |
| BLR-01 | Live selected arc, reference raw/visual/source projection | avatar artwork + presentation state | `actual / effectiveLimit`, clamped visual percent with authored 1% minimum; focused unit/widget tests | DONE |
| BLR-02 | Selected target title and atomic title/amount/ring binding | Budget presentation controller + header | aggregate/category names and exact key travel with one header state; controller/widget tests | DONE |
| BLR-03 | Press feedback: raw down `.8`, 115 ms, easeOutQuad | Budget rail interaction shell | pointer widget test inspects scale contract and reset paths | DONE |
| BLR-04 | Long/very-long, drag mapping, auto-repeat and haptics from reference | input shell + limit-edit controller | deterministic controller and widget tests cover 720 ms, 5/12/14/18/50 px rules and one haptic per batch | DONE |
| BLR-05 | Optimistic, release-only persistence, delete and latest-wins | headless Dashboard limit-edit controller | fake repository tests: no pre-release I/O, one release write/delete, ordered reconciliation/failure handling | DONE |
| BLR-06 | No hot-path database/query/catalog/SVG/LogBox work | presentation + rail ownership | rebuild/isolation and counting-repository tests; direct code inspection | DONE |
| BLR-07 | Preserve shared centered-carousel physics and target catalog | rail + shared motion contracts | existing motion/tap/drag/fling tests unchanged; no physics edits | DONE |
| BLR-08 | Protected Dashboard/Query/LogBox baseline | regression suites | affected Flutter/Kotlin/boundary tests pass | PARTIAL — Flutter/boundary green; local Android unit-test resources are blocked by Termux ARM64 AAPT2 startup, pending GitHub validation |
| BLR-09 | Delivery for production Flutter change | GitHub Actions / normal APK | focused commit, pushed SHA, successful `lib/main.dart` APK downloaded to `/storage/emulated/0/Download/fluvi` and SHA-256 recorded | NOT DONE |
