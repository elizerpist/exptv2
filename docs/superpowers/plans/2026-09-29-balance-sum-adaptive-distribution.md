# Balance SUM Adaptive Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the approved Balance SUM prototype from live closed-month data without changing its Mother Card geometry.

**Architecture:** `DashboardBalanceStabilityProjection` remains the sole owner of complete-month membership and robust median/MAD. A pure application distribution projection turns its immutable observations into adaptive histogram and positive-streak models. The scope adapter passes immutable models to dedicated SUM renderers, which reuse the existing extended-sheet allocation and card shell.

**Tech Stack:** Flutter/Dart, immutable presentation DTOs, CustomPainter, existing dashboard projections, Flutter widget/unit tests.

## Global Constraints

- The canonical reference is `html-prototypes/balance-extended-sheet-baseline/index.html`; inspect its SUM row before visual implementation.
- Preserve `DashboardHeaderContentMotherCardBounds` and `BalanceExtendedSheetLayout` exactly.
- Use standard neutral `BalanceAlternativeHtmlCardSurface` borders; never add the prototype-only purple child border.
- Binning is sample-derived and never a fixed HUF step.
- Original Soft rainbow anchors must come from the existing header palette catalog, not a copied palette.
- Run Flutter tests and analysis in Ubuntu proot; run the APK build online after push and download the normal human APK to `/storage/emulated/0/Download/fluvi`.

---

## File map

- Create `lib/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection.dart`: pure adaptive bins and positive-run calculation.
- Modify `lib/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart`: construct immutable SUM presentation from linked stability/retention data.
- Modify `lib/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart`: expose original Soft rainbow anchors through its existing catalog if required.
- Modify `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`: centralize SUM visual measurements and catalog-derived colors.
- Create `lib/features/dashboard/presentation/core_modes/balance_alternative_sum_cards.dart`: render-only SUM cards and painters.
- Modify `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`: route SUM through existing extended-sheet frame.
- Modify `test/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection_test.dart`: core calculations.
- Modify `test/features/dashboard/presentation/balance_alternative_scope_presentation_test.dart`: adapter mapping.
- Create `test/features/dashboard/presentation/balance_alternative_sum_cards_test.dart`: text, card shell and custom-paint visual contract.
- Modify `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`: dependency, one-owner and geometry boundaries.

### Task 1: Adaptive monthly-net model

**Files:**
- Create: `lib/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection.dart`
- Test: `test/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection_test.dart`

**Interfaces:**
- Consumes: `DashboardBalanceStabilityPresentation`.
- Produces: `DashboardBalanceMonthlyNetDistributionPresentation build({required DashboardBalanceStabilityPresentation stability})`, with histogram bins, overlay values and longest-positive-series values.

- [ ] **Step 1: Write failing tests** for complete assignment, equal regular widths, one identical bin, IQR-zero/MAD fallback, outlier bins, zero boundary, and a positive series of exactly six months.
- [ ] **Step 2: Run the focused test** in Ubuntu proot and confirm it fails because the distribution projection does not exist.
- [ ] **Step 3: Implement the immutable model**: calculate quantiles/median, FD width, MAD/min-max fallbacks, robust fences, bounded equal-width bins, zero alignment, interval counts, and the chronological positive run without Flutter imports.
- [ ] **Step 4: Run the focused test** and confirm all calculation cases pass.

### Task 2: SUM presentation path and central visual tokens

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_scope_presentation_test.dart`

**Interfaces:**
- Consumes: `DashboardBalanceLinkedPresentation.stability`, `.retention`, and Task 1 presentation.
- Produces: `BalanceAlternativeSumPresentation` with distribution, stability and savings values; central SUM dimensions and original palette colors.

- [ ] **Step 1: Write failing adapter/token tests** that assert linked SUM gets real stability/savings/distribution data and original color anchors come from the catalog.
- [ ] **Step 2: Run the focused adapter test** and confirm it fails for the missing SUM payload.
- [ ] **Step 3: Map the linked SUM data once** in `fromLinked`; preserve the legacy `fromPrimary` fallback with deterministic empty SUM data rather than querying again. Expose catalog colors and add only semantic SUM tokens.
- [ ] **Step 4: Run focused unit tests** and confirm they pass.

### Task 3: Render source-truth SUM cards

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_alternative_sum_cards.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_sum_cards_test.dart`

**Interfaces:**
- Consumes: immutable Task 1/Task 2 SUM presentation and `BalanceAlternativeHtmlCardSurface`.
- Produces: `BalanceAlternativeSumHistogramCard`, `BalanceAlternativePositiveStreakCard`, and `BalanceAlternativeCashflowStabilityBandCard`.

- [ ] **Step 1: Write failing widget tests** that pump each card with live-shaped DTO data and assert titles, sample chip, median callout, insight copy, legend copy, positive-run value and neutral child shell.
- [ ] **Step 2: Run the focused widget test** and confirm it fails because SUM widgets are missing.
- [ ] **Step 3: Implement render-only cards** using the prototype’s converted dimensions: histogram painter with typical overlay/zero/median, mini streak graph, and stability band with dots/rules/legend. Use catalog-derived original Soft rainbow colors and standard card shell.
- [ ] **Step 4: Run widget tests** and create/inspect a representative golden or screenshot evidence against the prototype references.

### Task 4: Route SUM through its existing geometry

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_sum_cards_test.dart`

**Interfaces:**
- Consumes: `BalanceAlternativeSumPresentation` and Task 3 cards.
- Produces: `_BalanceSumExtendedSheetScaffold` placed through `_BalanceExtendedSheetFrame` using `card3`, `card4`, `card5`, and `combined` slots.

- [ ] **Step 1: Extend the boundary test first**: it must reject a SUM `BalanceFiveSectionLayout`, a SUM-local Mother Card bounds policy, raw ledger imports in renderer, and a second Soft rainbow list.
- [ ] **Step 2: Run the boundary test** and confirm the old SUM route fails it.
- [ ] **Step 3: Replace only the SUM router branch** with `_BalanceSumExtendedSheetScaffold`; use `_BalanceExtendedSheetFrame` and standard section slots, preserving all Mother Card bounds.
- [ ] **Step 4: Run focused boundary and widget tests** and inspect the changed SUM visual state.

### Task 5: Verify, commit, push and deliver APK

**Files:**
- Modify: `docs/superpowers/specs/2026-09-29-balance-sum-adaptive-distribution.md` (mark every verified item honestly)

- [ ] **Step 1: Re-read the source prototype, screenshots, specification and plan**, then perform direct code/visual checklist review.
- [ ] **Step 2: Run focused tests, full relevant dashboard tests and `flutter analyze` in Ubuntu proot**; record real results.
- [ ] **Step 3: Mark checklist rows DONE only when evidence covers their acceptance conditions.**
- [ ] **Step 4: Commit production/prototype/spec/test changes** with a conventional SUM-distribution message and push `feature/balance-wave-defaults`.
- [ ] **Step 5: Monitor the GitHub Actions normal human APK job for that exact commit.** If it fails, inspect and repair in scope, then repeat verification/push.
- [ ] **Step 6: Download the exact normal `lib/main.dart` human APK to `/storage/emulated/0/Download/fluvi` and compute SHA-256.**

## Plan self-review

- Spec coverage: SUM-01 is Task 1; SUM-02 and SUM-05 are Task 3; SUM-03 is Tasks 1/3; SUM-04 is Task 2; SUM-06/07 are Tasks 3/4; SUM-08 is Tasks 1/2/4; SUM-09 is Task 5.
- Placeholder scan: no deferred implementation placeholders are present.
- Type consistency: the distribution projection is immutable, consumed by the SUM adapter and render-only cards; widgets never receive ledger entries.

## Execution note

The user explicitly approved execution after the spec and plan. This implementation proceeds inline because the domain model, adapter and rendering route are sequentially coupled and share the same presentation contracts.
