# Dashboard Scroll Milestone, Preview Paint, and Vector Glyph Checklist

## Architecture card

### Scope and sources

- User requirements: the 2026-08-14 dashboard milestone, Query Apply blank
  LogBox report, and pixelated category glyph report.
- Accepted physical evidence:
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260814-203630.png`
  - supplied interaction generation 85 trace for `155f18b`.
- Existing implementation:
  - `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
  - `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart`
  - `lib/core/assets/prepared_vector_asset_atlas.dart`

### Single source and write path

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Approved virtual extent and bounded page resources | `CommittedLogViewportCache` | Exact committed scope | Page readiness changes resources, never geometry. |
| Active exact rail-preview scene | `DashboardLogBoxPreparedSceneCache` | Presentation window | Complete candidate bank swaps atomically through `activateWindow`. |
| First visible paint of a non-empty preview | `DashboardLogBoxRenderSurface` | Current paint delegate | An exact presentation identity must invalidate paint without input. |
| Category glyph display list | `PreparedVectorAssetAtlas` | Process/DPR-independent bootstrap resource | Asset preparation builds it once; renderer only transforms and draws it. |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Scroll identity/physics | Existing virtual-geometry surface and rail motion kernel | Controller, position, physics remain stable | Preserve; add milestone regressions | New explicit vertical/horizontal/cross-contract tests. |
| Rail-preview paint invalidation | `DashboardLogBoxRenderSurface` / prepared scene cache | Complete scene must paint after atomic publication | Extend existing surface identity only | Query-B no-input RED test. |
| Category glyph resources | `PreparedVectorAssetAtlas` | Decode once; no per-row asset/tint work | Replace only icon-atlas raster sprite with prepared vector glyph | Atlas and renderer structural tests. |

### Layer flow

`Prepared query candidate -> DashboardCoreController atomic scene/index/query publication -> DashboardVisibleFrameStore -> DashboardLogBoxRenderSurface -> CustomPainter`.

`PreparedVectorAssetAtlas bootstrap decode -> prepared white vector glyph -> DashboardLogBoxRenderSurface visible-row paint`.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MS-01 | User physical acceptance | `MILESTONE_COMMITS.md`, virtual-geometry forensic doc | 155f18b is recorded as an Android-verified permanent vertical + horizontal interaction boundary without claiming 60 fps | Direct document inspection | DONE — recorded by 84cb4f0. |
| MS-02 | User milestone contract | New discoverable regression suite | A page resource commit during one ballistic interaction leaves virtual/max extent, geometry generation, controller/position/physics identities, retention and fail-closed counters valid | Deterministic widget/controller test | DONE — `APPROVED SCROLL MILESTONE` vertical test. |
| MS-03 | User milestone contract | New discoverable regression suite | Rail drag/settle/semantic crossing/Query publication keep rail identity and rail-preview ownership valid | Controller/widget regression test | DONE — `APPROVED SCROLL MILESTONE` horizontal test. |
| MS-04 | User cross-contract | New discoverable regression suite | Query Apply followed by rail then live vertical paging has no stale Query, identity replacement, or page-readiness geometry mutation | Focused integration-style widget/controller test | DONE — `APPROVED SCROLL MILESTONE` cross-contract test. |
| PV-01 | Screenshot and supplied Query trace | `dashboard_logbox_render_surface.dart` tests | Existing Query B rail-preview scenario fails before a gesture when exact data/scene exist but no rows paint | RED widget test | DONE — regression is expressed by the no-input Query-B first-paint test. |
| PV-02 | User no-workaround constraint | `dashboard_logbox_render_surface.dart` | Exact Query B scene paints on ordinary publication while render domain remains `railPreview` | GREEN widget test; render-domain assertion | DONE — `presentationEpoch` is structural painter identity; test keeps `railPreview`. |
| PV-03 | User diagnostics constraint | Render surface / scene cache | At most one aggregate non-empty-without-paint diagnostic per presentation; normal Apply is zero | Focused diagnostic test | DONE — the surface emits one `LOGBOX_NONEMPTY_PRESENTATION_WITHOUT_PAINT` event per presentation and the Query-B normal-paint test stays at zero scene violations. |
| VG-01 | User vector fidelity requirement | `prepared_vector_asset_atlas.dart` | Final category glyph is a prepared `ui.Picture`, never a `ui.Image`/raster sprite | Atlas structural test | DONE — atlas test asserts `PreparedLogBoxVectorGlyph` and no icon-atlas path. |
| VG-02 | User hot-path constraint | Atlas and LogBox painter | No asset decode, SVG parsing, saveLayer tint, TextPainter construction, or row widgets occur in row paint | Source/structural tests plus existing painter suite | DONE — source/painter structural test and existing single-surface painter suite. |
| VG-03 | User resource-lifecycle requirement | Atlas | Glyphs are prepared once, bounded by catalog count, and disposed deterministically | Atlas lifecycle test | DONE — DPR rebuild reuses glyphs; atlas disposal disposes them. |
| VG-04 | User no-scroll-regression constraint | Milestone suite | New glyph path preserves MS-02 through MS-04 | Milestone suite rerun after glyph commit | DONE — milestone suite passed after the glyph-path change. |
| Q-01 | User Query contract/counts | Query/controller suites | Directional applied Query, atomic Apply/Cancel, and existing demo-count coverage remain intact | Focused Query suites | DONE — focused Query suites and the fast suite passed; native demo-count source test is queued for online Android verification because the local proot has no Android SDK. |
| DEL-01 | User delivery requirement | GitHub Actions + `/storage/emulated/0/Download/fluvi` | Every production commit is pushed normally and its normal human APK is downloaded and SHA-256 checked | GitHub run/artifact check | PARTIAL — commit 2 was pushed but its Actions run stopped at analyzer warnings (already corrected here); this final production SHA still requires its normal online APK delivery. |
