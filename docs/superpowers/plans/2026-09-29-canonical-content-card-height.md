# Canonical Dashboard Content Card Height Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current Balance SUM Mother Card the single settled outer-height authority for Mind, every Balance scope, and every Budget composition; default Budget to the shared Mother Card and remove its dots.

**Architecture:** Add one geometry-level height policy and publish its result in `DashboardLayoutFrame`. The shared Mother Card bounds primitive consumes that result rather than a mode's incidental envelope position or optional body expansion. Balance Havi/Éves retain their HTML-derived inner grammar but use the fixed outer body, with only flexible plots receiving the reduced available height. Budget retains its controllers and its selectable composition, but neither can alter the global outer height.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing golden tests, Ubuntu proot test/analyze environment, GitHub Actions human APK job.

## Global Constraints

- Work only in `/data/data/com.termux/files/home/fluvi-balance-carousel-recovery` on `feature/balance-wave-defaults`; do not create, delete, or merge worktrees.
- Do not delete or modify the pre-existing `test/features/dashboard/presentation/failures/` directory.
- The current Balance SUM expanded Mother Card is the sole outer-height source of truth.
- The Havi/Éves HTML prototype at `html-prototypes/balance-extended-sheet-baseline/index.html` remains authoritative for inner typography, padding, card grammar, and direct rendering.
- The reference viewport must not use a card-wide `FittedBox`; only flexible plot/drawing regions may yield vertical space.
- Flutter tests and analysis run through Ubuntu proot. Do not create an APK locally on Termux.
- Before the final production handoff, push the app-code commit, monitor the exact GitHub Actions human APK job, download the normal APK to `/storage/emulated/0/Download/fluvi`, and report its SHA-256.

---

### Task 1: Lock the canonical geometry contract with red tests

**Files:**
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes: `DashboardGeometryResolver.resolve`, `DashboardHeaderContentMotherCardBounds.resolve`, and the existing mode presentation test harnesses.
- Produces: failing `CCH-*` tests that name the policy contract and reject the existing Havi/Éves and Budget outer-height exceptions.

- [ ] **Step 1: Add the failing geometry matrix test.**

  Add a test that resolves fully expanded Mind, Balance, and Budget frames with the same `DashboardLayoutMetrics.reference`, physical-rail state, and global content stretch. It must call the shared Mother Card resolver for every frame and assert the exact same `top`, `height`, and `bottom` as Balance SUM:

  ```dart
  expect(mindMother.height, closeTo(balanceSumMother.height, .01));
  expect(monthMother.bottom, closeTo(balanceSumMother.bottom, .01));
  expect(yearMother.bottom, closeTo(balanceSumMother.bottom, .01));
  expect(budgetMother.bottom, closeTo(balanceSumMother.bottom, .01));
  ```

- [ ] **Step 2: Add the failing UI and boundary assertions.**

  Update the Balance Havi/Éves test to resolve without a scope-specific
  `principalModeContentExtraHeight` and assert its unified surface rectangle
  equals the SUM rectangle. Replace the existing boundary assertion that
  requires `_balanceAlternativeExtendedSheetPrincipalContentExtraHeightFor`
  with assertions for a single policy owner and the absence of that method,
  `extendedSheetPrincipalModeContentExtraHeight`, and the Budget
  chart-first outer-height request.

- [ ] **Step 3: Run the tests red in Ubuntu proot.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/core/design/dashboard_geometry_resolver_test.dart test/boundary/balance_alternative_extended_sheet_boundary_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart'
  ```

  Expected: failure because the mode-specific extra-height paths and Mind's
  distinct outer-bounds calculation still exist.

### Task 2: Centralize the settled Mother Card height

**Files:**
- Create: `lib/core/design/dashboard_content_card_height_policy.dart`
- Modify: `lib/core/design/dashboard_geometry_resolver.dart`
- Modify: `lib/core/design/dashboard_layout_frame.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`

**Interfaces:**
- Consumes: `DashboardLayoutMetrics`, `hasPhysicalRail`, and the shell-wide flat-bottom-navigation content stretch.
- Produces: `DashboardLayoutFrame.canonicalMotherCardContentHeight`, a mode-independent geometry value consumed by all Mother Card renderers.

- [ ] **Step 1: Create the neutral policy.**

  Define `DashboardContentCardHeightPolicy` as a pure design-layer owner. Its
  `resolveSettledContentHeight` must derive the Balance SUM body from existing
  shared metrics only: the normal Balance SUM header-to-content gap, subheader
  height, standard gap, Zone2 height, reclaimed rail footprint, and a
  shell-wide content stretch when that stretch applies to every mode. It must
  not accept `DashboardModeSpec`, a Balance scope, Budget order, or a widget.

  ```dart
  static double resolveSettledContentHeight({
    required DashboardLayoutMetrics metrics,
    required bool hasPhysicalRail,
    required double sharedContentStretch,
  }) {
    final reclaimedRailFootprint = hasPhysicalRail
        ? 0.0
        : metrics.railHeight + metrics.railToCollapseHandleGap;
    return metrics.standardGap +
        metrics.subheaderOneHeight +
        metrics.standardGap +
        metrics.zone2CardHeight +
        reclaimedRailFootprint +
        sharedContentStretch;
  }
  ```

- [ ] **Step 2: Publish the policy result from the geometry resolver.**

  Extend `DashboardLayoutFrame` with the immutable policy result. In
  `DashboardGeometryResolver.resolve`, compute it once from the active metrics
  and shared shell stretch. Keep `modeContentBounds` available for the legacy
  cascade, but do not let `modeContentExtraHeight` or
  `principalModeContentExtraHeight` from a particular mode modify the new
  canonical value.

- [ ] **Step 3: Make the shared Mother Card primitive consume only the policy.**

  Replace the `subheaderEnvelopeBounds`-derived height in
  `DashboardHeaderContentMotherCardBounds.resolve` with the frame's canonical
  content height. Keep `bodyReveal` only as a multiplicative transition value;
  all three settled renderers must pass the same full endpoint value.

  ```dart
  height: header.height + geometry.canonicalMotherCardContentHeight * reveal,
  ```

- [ ] **Step 4: Remove the two mode-specific outer-height write paths.**

  Delete `_balanceAlternativeExtendedSheetPrincipalContentExtraHeightFor` and
  its `BalanceAlternativeHtmlTokens` helper. Remove the Budget
  `chartThenAvatarsExtraModeContentHeight` routing from `_modeContentExtraHeightFor`.
  Preserve the existing flat-bottom-navigation stretch only when it is a
  shell-wide setting, so it affects the canonical SUM source and every other
  mode equally.

- [ ] **Step 5: Run the Task 1 suites green.**

  Run the Task 1 command again. Expected: all geometry and boundary assertions
  pass; no Balance scope or Budget order can make a different settled Mother
  Card height.

- [ ] **Step 6: Commit the central policy.**

  ```sh
  git add lib/core/design/dashboard_content_card_height_policy.dart lib/core/design/dashboard_geometry_resolver.dart lib/core/design/dashboard_layout_frame.dart lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart lib/features/dashboard/presentation/core_dashboard.dart lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart test/core/design/dashboard_geometry_resolver_test.dart test/boundary/balance_alternative_extended_sheet_boundary_test.dart
  git commit -m "fix: centralize dashboard content card height"
  ```

### Task 3: Keep Havi and Éves direct-rendered inside the fixed SUM envelope

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
- Modify: `test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `test/goldens/balance_alternative_havi2_surface.png`
- Modify: `test/goldens/balance_alternative_eves_surface.png`

**Interfaces:**
- Consumes: the fixed bounds emitted by Task 2 and existing
  `BalanceExtendedSheetLayout` card rectangles.
- Produces: direct Havi/Éves card rendering at the reference viewport with
  HTML-derived fixed chrome and flex-only chart height.

- [ ] **Step 1: Add red direct-rendering and containment tests.**

  Change `_expectHtmlCardSurfaceSizes` so it checks the fixed SUM-envelope
  card rectangles rather than the obsolete 1187px outer-card minimums. For
  Havi and Éves, assert each card surface lies inside the unified Mother Card,
  no whole-card `FittedBox(fit: BoxFit.contain)` exists, and both plot keys
  have a positive, nonzero height.

- [ ] **Step 2: Run the Balance sheet test red.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  ```

  Expected: existing outer-card minimum dimensions select the card-wide
  fallback or assert the obsolete extended geometry.

- [ ] **Step 3: Rebase card-wide fallback thresholds on fixed chrome, not the obsolete Mother Card.**

  Keep source-derived typography, padding, radii, headers, insights, legends,
  and bar-strip dimensions intact. Replace the extended-sheet full-card
  fallback threshold with a direct-content threshold that reserves only
  non-flexible chrome. The `Expanded` `CustomPaint` plot regions receive the
  remaining height. Do not change `BalanceExtendedSheetLayout.resolve` ratios
  or insert a second scale/height owner in a card widget.

- [ ] **Step 4: Regenerate and inspect the two changed goldens.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test --update-goldens test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  ```

  Confirm visually that titles and padding remain at direct scale while only
  plotting space shortens to the SUM-height outer card.

- [ ] **Step 5: Run the Balance sheet suites green and commit.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  git add lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/goldens/balance_alternative_havi2_surface.png test/goldens/balance_alternative_eves_surface.png
  git commit -m "fix: fit balance sheets in canonical card"
  ```

### Task 4: Make unified Budget the default and remove its dots

**Files:**
- Modify: `lib/features/dashboard/presentation/budget_content_card_style.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/budget_section_order.dart`
- Modify: `test/features/dashboard/presentation/budget_content_layout_test.dart`
- Modify: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

**Interfaces:**
- Consumes: existing `BudgetContentCardStyleController`, section-order
  controller, and content renderers.
- Produces: one unified initial Budget surface and a Budget stack with no dots
  renderer or indicator-lane layout ownership.

- [ ] **Step 1: Write failing Budget default and no-dots tests.**

  Update the content-layout test to require:

  ```dart
  expect(controller.value, BudgetContentLayout.unifiedCard);
  ```

  In the surface matrix, create both section orders and both content-layout
  selections. Assert that no finder matches
  `dashboard-core-mode-budget-dots`, `BudgetDistributionPageDots`, or
  `DashboardPlaceholderDots`; assert every unified Mother Card rect equals the
  canonical Balance SUM rect.

- [ ] **Step 2: Run the Budget suites red.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/budget_content_layout_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart'
  ```

  Expected: the controller starts split and the current Budget dots subtree is
  found.

- [ ] **Step 3: Change the existing default owner and remove the dots topology.**

  Set `BudgetContentCardStyleController` and the surface's no-controller
  fallback to `BudgetContentLayout.unifiedCard`. Remove the dots
  `ValueListenableBuilder`, `_dotsContent`, `_unifiedIndicatorBounds`, and
  `indicatorBounds` from `_BudgetSectionLayout` and
  `BudgetAvatarContentRelationship`. Remove the chart-first extra-height
  constant once no downstream indicator tail needs it. Leave Budget avatar,
  pager, selection, and transition controllers unchanged.

- [ ] **Step 4: Run Budget suites green and commit.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/budget_content_layout_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart'
  git add lib/features/dashboard/presentation/budget_content_card_style.dart lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart lib/features/dashboard/presentation/budget_section_order.dart test/features/dashboard/presentation/budget_content_layout_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart
  git commit -m "fix: default budget to unified card"
  ```

### Task 5: Verify the accepted visual matrix and deliver the APK

**Files:**
- Modify: `docs/superpowers/checklists/2026-09-29-canonical-content-card-height.md`

**Interfaces:**
- Consumes: completed Tasks 1–4 and the production GitHub workflow.
- Produces: verified production APK for the exact pushed SHA and an honestly
  completed acceptance checklist.

- [ ] **Step 1: Run the focused architectural and visual regression suites.**

  Run the Task 1, 3, and 4 suites together, then:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter analyze'
  ```

  Expected: all tests and analysis pass with no test updated merely to accept a
  mismatch.

- [ ] **Step 2: Capture the accepted device states.**

  Install only the GitHub-produced normal human APK. Capture the fully
  expanded Balance SUM, Havi, Éves, Mind, and default Budget states at the
  same viewport. Compare their Mother Card top and lower edge to SUM; all
  must be equal within one physical pixel. Inspect Havi/Éves for direct-size
  text and padding, and Budget for absence of dots.

- [ ] **Step 3: Re-read and update the acceptance checklist.**

  Mark CCH-01 through CCH-09 `DONE` only after their stated test and screenshot
  evidence exists. Keep any unmet item as `PARTIAL` or `NOT DONE`; do not use
  a successful compilation as substitute evidence.

- [ ] **Step 4: Push the complete application-code commits.**

  ```sh
  git status --short
  git push origin feature/balance-wave-defaults
  ```

  Record the resulting commit SHA before locating its Actions run.

- [ ] **Step 5: Deliver the exact human APK.**

  Monitor the GitHub Actions human diagnostic APK job for the pushed SHA. If
  it fails, inspect and fix the in-scope failure before retrying. On success,
  download the normal `lib/main.dart` APK to `/storage/emulated/0/Download/fluvi`,
  verify it exists, and run:

  ```sh
  sha256sum /storage/emulated/0/Download/fluvi/*.apk
  ```

  Update CCH-10 to `DONE` with the exact SHA-256 and report the APK path.
