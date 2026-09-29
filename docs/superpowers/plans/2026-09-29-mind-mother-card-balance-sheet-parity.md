# Mind Mother Card and Balance Sheet Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Mind the one mother-card geometry authority for Mind, Balance and Budget, then render Balance Havi 2 and Éves at the approved HTML scale rather than shrinking their contents.

**Architecture:** Extract a neutral `DashboardHeaderContentMotherCardBounds` resolver beside the existing seamless-shape primitive. It consumes an immutable `DashboardLayoutFrame` and produces the exact Mind Header-plus-unified-body envelope. Keep extended-sheet visual metrics in `BalanceAlternativeHtmlTokens`; derive its fallback thresholds from the canonical 842×1187 HTML allocation so production reference cards use their direct layout path.

**Tech Stack:** Flutter/Dart, existing widget/boundary/golden tests, Ubuntu/proot Flutter tooling.

## Global Constraints

- `html-prototypes/balance-extended-sheet-baseline/index.html` is the visual source of truth; do not sample or crop screenshots into production widgets.
- The two expected and two defect Android screenshots listed in the approved design must be re-opened before delivery review.
- Do not change Balance projection, repositories, carousel physics, selection, time navigation, Mind body content, or Budget split/cascade behavior.
- Run Flutter test and analysis only in Ubuntu/proot; do not build an APK locally in Termux.

### Task 1: Centralize Mind-authoritative mother-card bounds

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Test: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`
- Test: `test/features/dashboard/presentation/selectable_header_direction_chrome_test.dart`
- Test: `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`

**Interfaces:**
- Produces `DashboardHeaderContentMotherCardBounds.resolve({required DashboardLayoutFrame geometry, required double bodyReveal}) -> DashboardBounds`.
- Consumes the existing `DashboardLayoutFrame.headerBounds`, `subheaderEnvelopeBounds`, and `headerExpansionProgress` only. (`unifiedSubheaderBounds` is a Mind-only alias.)

- [ ] **Step 1: Write failing Mind/Balance/Budget bound tests.** Assert the resolver returns `Rect.fromLTWH(header.left, header.top, header.width, header.height + unifiedBody.height * reveal)`. Mount Balance and settled unified Budget at 412×892 and assert their mother-surface rectangles equal that value; retain existing separate/transition assertions.
- [ ] **Step 2: Run the focused tests in Ubuntu/proot and verify RED.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/selectable_header_direction_chrome_test.dart'
  ```

  Expected: the existing Balance/Budget `modeContentBounds.bottom` implementation fails the new Mind-equivalence assertions.

- [ ] **Step 3: Implement the one neutral resolver and route all three seamless mother cards through it.** Keep Mind's existing `unifiedSubheaderBounds` and reveal behavior, use reveal `1` for settled Balance and Budget, and remove their duplicated `modeContentBounds.bottom - headerBounds.top` calculation. Do not alter child content bounds or transition routes.
- [ ] **Step 4: Add a boundary assertion.** Verify all three renderer files import/use the shared resolver and that neither Balance nor Budget retains its own `modeContentBounds.bottom - geometry.headerBounds.top` mother-card calculation.
- [ ] **Step 5: Run the focused tests to GREEN and format.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/selectable_header_direction_chrome_test.dart test/boundary/balance_alternative_extended_sheet_boundary_test.dart && dart format --output=none --set-exit-if-changed lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart'
  ```

### Task 2: Render Havi 2 and Éves at the canonical direct size

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart`
- Test: `test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Test: `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`
- Golden: `test/goldens/balance_alternative_havi2_cards.png`
- Golden: `test/goldens/balance_alternative_eves_cards.png`

**Interfaces:**
- Consumes `BalanceExtendedSheetLayout` allocation rectangles and `BalanceAlternativeHtmlTokens.sourcePixelsPerLogicalPixel`.
- Produces one CSS-derived fallback threshold per card family; the direct child path remains unchanged at the reference allocation.

- [ ] **Step 1: Write failing 412×892 Havi 2 and Éves tests.** Mount each scope with the existing live presentation fixture. Assert the headline `Text` styles equal the CSS-to-logical token sizes, plots have their direct allocated height, and each extended-sheet surface's `RenderFittedBox` reports unit scale at the reference allocation.
- [ ] **Step 2: Run the focused card tests and verify RED.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart'
  ```

  Expected: current `minimumContentSize` values select card-wide `FittedBox` scaling and the unit-scale assertions fail.

- [ ] **Step 3: Replace arbitrary fallback thresholds with canonical allocation-derived thresholds.** Define the source reference mother/header/inset/gutter metrics once in `BalanceAlternativeHtmlTokens`, calculate direct Havi/Éves card-family thresholds from the same 70/30–60/40 layout grammar, and feed those values to the existing surface. Preserve `FittedBox` solely for dimensions below the reference allocation.
- [ ] **Step 4: Prove the direct path and regenerate only the two focused goldens after GREEN.** Keep source text/padding/colour tokens unchanged; do not add renderer-local raw CSS colours or separate layout ratios.
- [ ] **Step 5: Run focused tests, goldens, boundary suite, format and diff check.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/boundary/balance_alternative_extended_sheet_boundary_test.dart && /home/flutteruser/flutter/bin/flutter test --update-goldens test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart && dart format --output=none --set-exit-if-changed lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart && git diff --check'
  ```

### Task 3: Delivery verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-09-29-mind-mother-card-balance-sheet-parity.md`

- [ ] **Step 1: Re-open all four Android screenshots and the canonical HTML before delivery review.** Confirm Havi 2 and Éves have direct-size typography, padding and plot space, and Mind/Balance/Budget mother-card lower bounds follow the same rule.
- [ ] **Step 2: Run required verification in Ubuntu/proot.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter analyze --no-pub --no-fatal-infos && /home/flutteruser/flutter/bin/flutter test test/boundary/balance_alternative_extended_sheet_boundary_test.dart test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart test/features/dashboard/presentation/selectable_header_direction_chrome_test.dart && git diff --check'
  ```

- [ ] **Step 3: Commit and push the production change.** Update every checklist status honestly before commit. Push the new commit on `feature/balance-wave-defaults`.
- [ ] **Step 4: Monitor the exact GitHub Actions human diagnostic APK, download the resulting normal APK to `/storage/emulated/0/Download/fluvi`, and record the SHA-256.**
