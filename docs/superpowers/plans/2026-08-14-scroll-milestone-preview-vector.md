# Dashboard Scroll Milestone, Preview Paint, and Vector Glyph Implementation Plan

> **For agentic workers:** Execute inline in this session. The user explicitly
> prohibits subagents; each task ends at a separately reviewable commit.

**Goal:** Protect the Android-approved virtual-geometry scrolling contract,
make a newly applied non-empty Query preview paint before any input, and retain
the LogBox category glyph as a prepared vector display list.

**Architecture:** Keep `CommittedLogViewportCache` as the only virtual
geometry/resource owner. Extend the existing scene-cache/render-surface
publication identity so a complete active rail scene has a guaranteed first
paint. Extend `PreparedVectorAssetAtlas` rather than creating a row-local
icon path: badges/group surfaces remain raster resources while category glyphs
become pre-recorded white `ui.Picture` resources.

**Tech Stack:** Flutter 3.41.4, Dart, `flutter_test`, `dart:ui`,
`vector_graphics`, GitHub Actions human APK.

## Global Constraints

- Preserve 155f18b's immutable virtual extent, five movable pages, 2 MiB
  bound, one controller/position, and unchanged production physics.
- Preserve `railPreview` until a real vertical gesture; never use
  `committedVertical` as a Query Apply workaround.
- Query Apply remains atomic and directional; no stale/partial scene or
  loading state is permitted.
- No golden tests, timing thresholds, timers, debounces, additional database
  reads, SVG parsing, TextPainter creation, or saveLayer tint work in row
  paint.
- Build normal human APKs through GitHub Actions only.

---

### Task 1: Lock the approved interaction milestone

**Files:**
- Modify: `MILESTONE_COMMITS.md`
- Modify: `docs/superpowers/forensics/2026-08-14-virtual-vertical-geometry-redesign.md`
- Create: `test/regression/dashboard_scroll_milestone_test.dart`

- [x] Write deterministic vertical, horizontal, and Query/scroll cross-contract tests using the existing virtual cache, rail motion kernel, visible-frame store, and Query candidate fixtures.
- [x] Run the new suite against 0e2b3d56; it must pass because it documents the physically approved contract without production behavior changes.
- [x] Record the supplied Android physical trace and milestone policy in the two requested documents.
- [x] Commit only documentation and regression tests as `test: lock smooth dashboard scroll milestone` (`84cb4f0`).

### Task 2: Repair non-input rail-preview first paint

**Files:**
- Modify: the closest existing LogBox surface/Query Apply widget test
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart` only if the single aggregate diagnostic belongs there

- [x] Write a Query A -> fully prepared Query B -> Apply -> normal pump test with no pointer/scroll event, asserting exact B scene, payload, and `paintedRowCount > 0` while the domain remains `railPreview`.
- [x] Run it and retain the concrete RED output identifying the missing first-paint invalidation.
- [x] Add the smallest surface-paint identity/notification correction, preserving cache ownership and no input workaround.
- [x] Run the focused surface/Query/milestone suites and commit as `fix: paint filtered logbox preview before first input` (`464ac7a`).

### Task 3: Replace category-icon raster sprites with prepared vector glyphs

**Files:**
- Modify: `lib/core/assets/prepared_vector_asset_atlas.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `test/core/assets/prepared_vector_asset_atlas_test.dart`
- Modify/create: closest LogBox painter structural test

- [x] Write RED structural tests requiring a `ui.Picture` glyph and no icon atlas/raster sprite dependency in the LogBox glyph path.
- [x] Run the RED tests.
- [x] Build one normalized white `ui.Picture` per catalog icon during atlas preparation, dispose it with the atlas, and draw it through transform plus `drawPicture` from both preview and committed row paint paths.
- [x] Run vector, painter, Query, and milestone suites; commit as `fix: keep logbox avatar glyphs vector sharp`.

### Task 4: Verify and deliver

- [x] Re-read `docs/superpowers/checklists/2026-08-14-scroll-milestone-preview-vector-checklist.md` and update each status truthfully.
- [x] Run focused tests, `./scripts/test-fluvi-fast.sh`, `./scripts/verify-fluvi-boundaries.sh`, and `flutter analyze` in Ubuntu proot.
- [ ] Push each production SHA as a normal fast-forward update to `origin/query`, monitor its exact GitHub Actions run, and download the normal `lib/main.dart` human APK to `/storage/emulated/0/Download/fluvi` with SHA-256 verification.
- [ ] Report the three commit SHAs, test evidence, and that only the user can physically accept the two new visual fixes.
