# Budget card2 category distribution — acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCD-01 | User §5/§6A | Budget card2 surface | Existing zone2/card2 contains the category-distribution page, not another card. | Widget test + source inspection. | DONE |
| BCD-02 | User §5 semantic contract | Distribution application projection | Direction + prepared period project both dense direction banks; aggregate and zero actuals are omitted; selected target never changes values. | Pure projection tests. | DONE |
| BCD-03 | User §8B/D/E | Shared Budget period + controller | Period matches Budget header; Query is not an input; Query-only change reuses the exact bundle; selected-handle tick does no projection. | Unit identity/counter tests. | DONE |
| BCD-04 | User §8A/H | Immutable bundle cache | One revision+period bundle contains income and expense frames with deterministic sort/tie order and at most three retained bundles. | Unit LRU/direction tests. | DONE |
| BCD-05 | Spendee `spendee_budget_v2_components.dart` | Fluvi SVG/hit-test module | Exact clay-donut viewBox/radii/gaps/path/depth/lift/center text and matching mathematical hit test. | Non-golden SVG geometry tests. | DONE |
| BCD-06 | User §8F/G | Visual-bank/prewarmer | Dense target-to-variant mapping prepares bounded SVG variants and public `flutter_svg` cache prewarm before publish; no generation/prewarm on target tick. | Spy/counter tests. | DONE |
| BCD-07 | User §8K–N | Rail command seam | Distribution requests existing rail motion, with nearest cyclic target and preview-driven intermediate selection; no second controller or direct selection teleport. | Controller/widget tests. | DONE |
| BCD-08 | User §8P–R | Distribution card | Heading marker, donut, scrollable ordered legend, selected row, center/sector/row commands and local list scrolling follow the reference. | Widget/hit tests. | DONE |
| BCD-09 | User §10/§13 | Tests and boundaries | Required new focused RED/GREEN tests plus protected Budget/carousel/boundary regressions remain green; no Kotlin changes. | Flutter test/analyze/diff. | DONE |
| BCD-10 | User §15 | Delivery | Focused commits, pushed SHA, successful normal `lib/main.dart` APK workflow, downloaded artifact and SHA-256. | GitHub workflow + local hash. | DONE |

Reference reread before implementation: `spendeetest@144d78c30dc4cc5e9f230903fd6274c98e62e118`, `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart` (distribution data, overview, hit test, clay donut); companion carousel/coordinator files inspected read-only.
