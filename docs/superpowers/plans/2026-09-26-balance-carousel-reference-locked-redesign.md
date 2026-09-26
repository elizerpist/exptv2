# Reference-locked Balance carousel mini-card redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the internal visual design of every Balance mini carousel card match `/storage/emulated/0/spendee/reference/carousel2.png` without changing the shared carousel or any external geometry.

**Architecture:** `_BalanceCarouselCard` remains the single visual owner. It receives the existing `CenteredCarouselItemMetrics.isSelected` as immutable render input and layers a category-palette-derived shell, passive wave painter, top-right icon tile, and positioned text grammar inside its unchanged `SizedBox`. No controller, data, physics, or selection path changes.

**Tech Stack:** Flutter/Dart, existing category visual palette/badge, `flutter_test`, golden images, Ubuntu-proot Flutter tooling, GitHub Actions human diagnostic APK.

## Global Constraints

- `/storage/emulated/0/spendee/reference/carousel2.png` is the visual source of truth.
- Do not change `CenteredCarousel`, its controller, physics, focus scaling, external item/card sizes, carousel row placement, surrounding dashboard surfaces, or data/Query/repository paths.
- Reuse `CategoryAvatarPaletteCatalog`, `CategoryColorCatalog`, `BalanceCategoryVisualBadge`, and existing Dashboard scopes; do not add raw feature-local palettes.
- Keep every visual metric in one reference-style specification; do not branch into topic-specific mini-card renderers.
- The full acceptance checklist is `docs/superpowers/checklists/2026-09-26-balance-carousel-reference-locked-redesign.md`.

### Task 1: Lock the reference structure in failing widget tests

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes: existing Balance surface fixture, card keys, and `CenteredCarouselController`.
- Produces: `RCR-RED-01` structural/geometry evidence and the unchanged-card-envelope assertion used by Task 2.

- [x] Add `RCR-RED-01`, rendering the existing Balance surface at `Size(412, 892)`, selecting each card, and requiring keyed accent shell, wave layer, and icon tile for every topic.
- [x] In the same test, compare rects: title begins in the top-left lane, icon tile is right of the card midpoint and above the primary line, and primary/secondary copy stays in the lower-left lane with increasing vertical positions.
- [x] Preserve/extend the existing fixed-carousel assertion so selected and neighbour sizes/engine scales do not change.
- [ ] Run:

  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart --plain-name "RCR-RED-01"'
  ```

  Expected: FAIL because the current renderer has no reference-shell, wave, or icon-tile keys and its visual is a leading-left badge.

### Task 2: Implement the one reference-styled renderer

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes: `BalanceCarouselCard`, existing `CenteredCarouselItemMetrics.isSelected`, category identity/visual palette, Dashboard corner/shadow scopes.
- Produces: `_BalanceCarouselReferenceVisualSpec`, `_BalanceCarouselReferenceAccent`, `_BalanceCarouselSoftWave`, `_BalanceCarouselIconTile`, and the unchanged public/interaction surface.

- [x] Change only the existing item-builder adapter to pass `metrics.isSelected` to `_BalanceCarouselCard`; retain all existing `CenteredCarouselSpec`, controller, offsets, transforms, callbacks, and hit bounds.
- [x] Resolve one accent from `CategoryAvatarPaletteCatalog.gradientFor(CategoryAvatarColorProfileScope.profileOf(context), CategoryColorCatalog.handleOf(card.categoryColorId))`; use `FluviVisualTokens.appHighlightGradient` only for cards lacking category identity.
- [x] Replace the current title-plus-leading-row composition with a clipped `Stack`: reference-tinted shell plus fine accent border, passive lower wave, top-left title, top-right  icon tile, and lower-left one-line primary/secondary copy.
- [x] Keep reference proportions in `_BalanceCarouselReferenceVisualSpec.resolve(Size)`: title, tile, primary/secondary font scale, side/top/bottom insets, lane reservation and wave curve constants have one source. Preserve ellipsis rather than reflowing text.
- [x] Keep `BalanceCategoryVisualBadge` as the category icon renderer inside the tile and use the existing semantic icon fallback for non-category cards.
- [ ] Run the Task 1 command again. Expected: PASS.

### Task 3: Reference screenshot evidence and regression verification

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `test/goldens/balance_carousel_canonical_layout.png`

**Interfaces:**
- Consumes: the Task 2 renderer and existing golden harness.
- Produces: inspected proof of the exact selected-card reference grammar.

- [x] Update `BCL-03` only with `--update-goldens` after Task 2 is green:

  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart --plain-name "BCL-03" --update-goldens'
  ```

- [x] Inspect `test/goldens/balance_carousel_canonical_layout.png` next to the direct source reference; verify outline, tint, lower wave, top-left title, top-right tile and lower-left hierarchy.
- [x] Run the complete focused surface suite and analyzer:

  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter analyze --no-pub --no-fatal-infos lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  ```

- [ ] Update the acceptance checklist truthfully, commit production code/tests/golden, append the required journal in a separate `[skip ci]` commit, push the production SHA, monitor its human diagnostic APK job, download it to `/storage/emulated/0/Download/fluvi`, and record SHA-256.
