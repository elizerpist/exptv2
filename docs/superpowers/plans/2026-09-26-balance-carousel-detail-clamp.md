# Balance carousel detail and flat-navigation clamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver one coherent Balance mini-card grammar, a denser category-detail page two, and count-safe flat-BottomNav stretch geometry.

**Architecture:** Extend the existing immutable Balance render model and one carousel renderer; retain category visuals through the existing resolver; place the BottomNav safety clamp in the existing pure shell geometry bridge. No data or motion owner changes.

**Tech Stack:** Flutter/Dart, existing `CenteredCarousel`, existing dashboard geometry resolver, Flutter widget and unit tests.

## Global Constraints

- Written user prompt overrides reference-image pixel interpretation.
- Preserve milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` interaction contracts.
- No local Android APK build; run Flutter checks in Ubuntu proot and final Human APK on GitHub Actions.
- Preserve untracked diagnostic files and `index.scip`.
- TDD: observe each new test fail before production implementation.

---

### Task 1: Red tests for Balance mini-card data and visual grammar

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`

**Interfaces:**
- Consumes: `balanceCarouselCardsFor(DashboardBalanceLinkedPresentation?)`.
- Produces: render-only primary/secondary/visual descriptors and stable card keys.

- [x] **Step 1: Write failing model and mounted-widget tests**

```dart
expect(card.primary, 'Lakhatás');
expect(card.secondary, '390 k Ft');
expect(find.byKey(ValueKey('balance-carousel-card-primary-${card.id}')), findsOneWidget);
```

- [x] **Step 2: Run the focused test in Ubuntu proot and observe missing API/key failure.**

- [x] **Step 3: Add the smallest immutable visual descriptor and one shared responsive renderer.**

```dart
final class BalanceCarouselCard {
  final String primary;
  final String secondary;
  final BalanceCarouselVisual visual;
}
```

- [x] **Step 4: Run the focused test and preserve CenteredCarousel identity tests.**

### Task 2: Red tests and implementation for category page-two continuity

**Files:**
- Modify: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart`

**Interfaces:**
- Consumes: immutable rank and insight DTOs plus `CategoryAvatarPaletteCatalog`.
- Produces: category-coloured median/pill and page-two rect keys.

- [x] **Step 1: Add failing page-rhythm, median-colour, chips and segment-height assertions.**
- [x] **Step 2: Run it and observe the old left/black/app-highlight layout fail.**
- [x] **Step 3: Extract the title rhythm token and render page two with the existing category palette authority.**
- [x] **Step 4: Run focused detail tests and inspect the updated large and production-height golden/reference states.**

### Task 3: Red tests and count-safe stretch clamp

**Files:**
- Modify: `test/features/dashboard/presentation/dynamic_mind_flat_bottomnav_test.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_shell_presentation.dart`
- Modify only if required: `lib/features/dashboard/presentation/core_dashboard.dart`

**Interfaces:**
- Consumes: resolved `logBoxHeaderBounds`, current shell settings and canonical BNB dimensions.
- Produces: `availableGain`, `desiredGain`, `delta == min(availableGain, desiredGain)`.

- [x] **Step 1: Add count-safe resolver coverage and a production-shell rendered-rectangle regression.**
- [x] **Step 2: Observe the missing production-height category-page and shell/nav evidence, then add failing assertions.**
- [x] **Step 3: Resolve the count-safe limit from canonical Ledger/BottomNav geometry without modifying BottomNav placement or Ledger tokens.**
- [x] **Step 4: Run reference/device-like/cross-mode and real-shell geometry tests.**

### Task 4: Integration verification and delivery

**Files:**
- Modify: this checklist and implementation plan statuses.
- Modify: `docs/FLUVI_ENGINEERING_JOURNAL.md` in a separate documentation-only commit after application delivery.

- [x] **Step 1: Format and run all affected focused tests, full fast suite and analyzer in proot.**
- [x] **Step 2: Reinspect both reference PNGs and the final diff; audit the no-go boundaries.**
- [ ] **Step 3: Commit production source, push, monitor the exact GitHub Actions Human APK job, download the exact normal APK and hash it.**
- [ ] **Step 4: Regenerate exact-source SCIP if project workflow supports it; then write and separately commit the factual journal entry.**
