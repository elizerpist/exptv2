# LogBox Vector Glyph Destination-Isolation Checklist

## Architecture card

### Scope and sources

- User requirement: repair the destructive reusable LogBox glyph composition
  at `2197658a` without regressing the physically approved `155f18b` scroll
  milestone or the `464ac7a` no-input Query first-paint contract.
- Physical references:
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260814-223305.png`
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260814-223258.png`
- Existing implementation:
  - `assets/category_catalog/category_catalog.json`
  - `tool/generate_category_catalog.py`
  - `tool/compile_vector_assets.sh`
  - `lib/core/categories/catalog/category_icon_catalog.dart`
  - `lib/core/assets/prepared_vector_asset_atlas.dart`
  - `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`

### Single source and write path

| State/resource | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Canonical category icon identity | category catalog manifest and generator | source/build time | generated token exposes both normal and LogBox-white compiled assets. |
| Monochrome LogBox vector source and `.vec` resource | existing catalog/vector compilation pipeline | build time | generated from the canonical SVG, never row-owned. |
| Decoded prepared glyph picture | `PreparedVectorAssetAtlas` | process lifetime | complete bounded catalog publishes atomically; atlas disposes pictures exactly once. |
| Row paint | `DashboardLogBoxRenderSurface` | visible paint | only transform plus `drawPicture`; never decodes, tints, composites, or owns assets. |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Category asset identity | category catalog generator | extend the generated token; no parallel registry | catalog/source/compiled-asset test. |
| Prepared glyph lifecycle | `PreparedVectorAssetAtlas` | retain one bounded atlas-owned vector picture per category | lifecycle and destination-isolation tests. |
| Row drawing | existing LogBox CustomPainter | keep the one surface and transform-plus-drawPicture call site | multi-row composition and structural hot-path test. |

### Layer flow

`canonical category SVG -> generated white SVG/.vec variant -> generated category token -> PreparedVectorAssetAtlas bootstrap decode -> PreparedLogBoxVectorGlyph -> LogBox CustomPainter`.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DI-01 | Physical trace and screenshot | atlas glyph resource | Painting a glyph cannot change pixels outside its avatar target or erase an earlier glyph/row. | RED/GREEN pixel-composition test. | DONE |
| DI-02 | User multi-row requirement | LogBox surface | Two visible rows retain card/text/avatar pixels after both glyphs paint. | Focused non-golden painter pixel test. | DONE |
| AS-01 | User canonical asset requirement | manifest/generator/compiler/catalog | The generated catalog exposes a dedicated white LogBox `.vec` resource derived from each canonical category SVG. | Generator/catalog/asset test. | DONE |
| AS-02 | User ownership requirement | `PreparedVectorAssetAtlas` | Glyph count is catalog-bounded, bootstrap-decoded once, and disposed exactly once. | Atlas lifecycle test. | DONE |
| HP-01 | User hot-path requirement | LogBox painter/atlas | No `srcIn`/destination blend, `drawColor`, `saveLayer`, `ColorFilter`, SVG decode, `toImage`, or `TextPainter` occurs in glyph row paint. | Focused structural test and source inspection. | DONE |
| FP-01 | `464ac7a` regression | Query preview paint test | A non-empty Query B paints in `railPreview` without input. | Existing no-input regression suite. | DONE |
| SM-01 | `155f18b` milestone | scroll regression suite | Vertical/horizontal controller, position, physics, virtual geometry, and bounded-resource contracts remain unchanged. | Existing approved milestone suite. | DONE |
| Q-01 | Query contract | Query/controller tests | Directional Query, Apply atomicity, and demo counts remain correct. | Focused Flutter and native/CI suites. | DONE |
| DEL-01 | Human delivery | GitHub Actions + Download/fluvi | Normal `lib/main.dart` APK for the final SHA is downloaded and SHA-256 verified. | Exact Actions human APK job and local digest. | PARTIAL — production commit is ready; delivery starts after push. |
