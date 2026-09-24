# Balance palette remix and Header mode-icon size

| ID | Requirement source | Code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| PAL-01 | User prompt 1 | `dashboard_header_balance_color_scale.dart` | The existing four families and all twelve existing exact scales are byte-value unchanged. | DONE — exact legacy-array regression |
| PAL-02 | User prompt 1 | palette enum/catalog/labels | Add exactly `balanceDiverging`, `limitColorLabNoWhite`, `softRainbowNoYellowLeft`, and `softRainbowReordered`, with the supplied immutable original/saturated/vivid arrays. | DONE — exact-array regression |
| PAL-03 | User prompt 1 | catalog tests | Eight families × three variants = 24 combinations; specified anchor counts, diverging centre, exclusion and ordering contracts pass. | DONE — engine/catalog regression |
| PAL-04 | User prompt 1 | tuner / visual engine | Existing family/variant selectors remain the sole controls and preserve window, opacity, foreground, animation and ticker ownership. | DONE — tuner/policy regression |
| PAL-05 | User prompt 1 | palette tests | Every newly authored anchor is proven to occur in the pre-change four-family anchor union; no runtime synthesis is added. | DONE — test-only provenance union |
| ICO-01 | User prompt 2 | Header visual tuning / engine | One session-scoped `0..100` icon-size setting defaults to 0 and maps the existing glyph size to exactly 1×..2×. | DONE — frame/controller regression |
| ICO-02 | User prompt 2 | Header tuner | A clearly labelled slider exposes the setting without resetting mode-specific icon/veil choices or adding a controller/ticker. | DONE — tuner regression |
| ICO-03 | User prompt 2 | Header mode host / primitive | Mode-icon taps remain the sole mode-cycle action but do not start a Header tap-wave; a non-icon Header tap still starts it. | DONE — no-ink/no-wave widget regression |
| ICO-04 | User prompt 2 | widget tests | Base and 100% bounds are bounded, hit-testable and semantic; no carousel/header gesture ownership changes. | DONE — bounds, semantic and hit-test regression |
| REG-01 | User / milestone | affected focused and protected tests | No Query, financial, palette interpolation, carousel, Header shader, mode-selection or motion-owner regression. | DONE — focused and fast suites |
| DELIVERY-01 | Global workflow | app branch / Actions | Atomic application commit is pushed; exact-source human diagnostic APK is downloaded, signed/integrity/embedded-SHA verified. | NOT DONE |
| DELIVERY-02 | Graph provenance | tooling branch | Separate SCIP commit has `manifest.source_head` equal to final application SHA. | NOT DONE |
| PHYSICAL-01 | User | device | User visual/install acceptance. | BLOCKED — USER ONLY |
