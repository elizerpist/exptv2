# Full-field Header flow acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| FF-01 | User: branch/pre-flight | Git worktree | `separated-core-modes` is clean, at the fetched remote SHA, with no unrelated changes absorbed. | Required Git pre-flight transcript. | DONE |
| FF-02 | User: preserve foundations | Header shader/backend/Cool source | Global Cool P/W, ABI v3, canonical 2/3-stop sampler, 112° static output and one clock stay intact. | Source contracts, static tests, backend tests. | DONE |
| FF-03 | User: two user-visible families | Effect catalog, controller, tuner | Explicit `classicReference` and `fullFieldFlow` metadata; one active family and effect selector. | Catalog + tuner widget tests. | DONE |
| FF-04 | User: classic comparison lane | Fragment shader | IDs 0–8 preserve their IDs and run isolated 69d109 effect mathematics on current palette/ABI infrastructure. | Historical source audit and deterministic parity fixture. | PARTIAL |
| FF-05 | User: no architecture revert | Shader/backend | No revert/reset, no endpoint RGB authority, no `uColorA/uColorB`; global Cool remains independent. | Source-contract tests and Git audit. | DONE |
| FF-06 | User: reusable full-domain engine | Fragment shader | One seeded analytic stream/flow core, soft boundaries and fixed (≤3) midpoint backtrace steps generate `sourceUv`. | Shader source contracts and flow-grid tests. | DONE |
| FF-07 | User: Free Flow | Catalog/shader/tuner | Stable ID 9, prescribed controls/defaults, broad non-rigid all-field transport. | Flow and tuner tests. | DONE |
| FF-08 | User: Chaotic Advection | Catalog/shader/tuner | Stable ID 10, prescribed controls/defaults, stronger but smooth non-rigid mixing. | Flow and tuner tests. | DONE |
| FF-09 | User: Elastic Space | Catalog/shader/tuner | Stable ID 11, prescribed controls/defaults, smooth strain without a crease/divider. | Flow and tuner tests. | DONE |
| FF-10 | User: Braided Current | Catalog/shader/tuner | Stable ID 12, prescribed controls/defaults, multiple flow corridors without colour ownership. | Flow and tuner tests. | DONE |
| FF-11 | User: Volumetric Current | Catalog/shader/tuner | Stable ID 13, prescribed controls/defaults, pseudo-depth affects source UV only, never RGB ownership. | Flow/midpoint-sensitivity tests and source audit. | DONE |
| FF-12 | User: full material contract | Shader/tests | Palette lookup is `sourceUv -> canonicalGradientCoordinate -> sampleCanonicalPalette -> optics`; no semantic centre, palette divider or mixture target. | Source-contract tests. | DONE |
| FF-13 | User: physical flow behavior | Flow tests | ≥80% participation, non-rigid residual, light/dark cross-domain mobility, five-band movement and simultaneous local compression/expansion. | Deterministic neutral-palette flow probes. | PARTIAL |
| FF-14 | User: continuity/distribution | Flow tests | Fixed seed is deterministic; frames are continuous; entropy/Wasserstein remain bounded; no wrapping or endpoint plateaus. | Raster/grid distribution tests. | DONE |
| FF-15 | User: compose infrastructure | Shader/tests | Portal and touch compose over the transported material; no source reset; shader lifecycle stays stable. | Existing portal/tap/backend regression tests plus source contract. | DONE |
| FF-16 | User: diagnostics/hot path | Visual engine | Family-aware low-frequency binding/probe diagnostics; no new ticker or phase-tick allocations/IO. | Engine tests and source inspection. | DONE |
| FF-17 | User: Dashboard protection | Protected files/tests | Dashboard motion, rails, query, LogBox and physics behavior are untouched. | Focused protected suites; empty CenteredCarousel diff. | PARTIAL |
| FF-18 | User: RED→GREEN→REFACTOR/commits | Git history | Focused test, classic refactor, feature, then docs-only additive commit in order. | Commit inspection. | NOT DONE |
| FF-19 | User: build delivery | GitHub Actions/APK | Behavioral SHA is pushed, required CI succeeds, normal `lib/main.dart` profile APK is downloaded to `/storage/emulated/0/Download/fluvi` and hashed. | GitHub run/artifact and SHA-256. | NOT DONE |
| FF-20 | User: milestone | `MILESTONE_COMMITS.md` | New additive 2026-08-23 flow milestone leaves all existing bytes/statuses/order untouched and remains human-acceptance candidate. | Byte comparison and docs commit review. | NOT DONE |
| FF-21 | User: physical acceptance | Physical Android | All requested visual and performance scenarios are inspected on a physical device; no automated result is presented as human acceptance. | Fresh final-SHA log and human observation. | NOT DONE |
