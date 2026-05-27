# Exptv2 Header And Category Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the expt0926-style header card and full category management UI/backend slice in exptv2.

**Architecture:** Kotlin Room remains persistence owner for category CRUD. Flutter owns header/category UI, slot managers, local filtering, editor forms, and MethodChannel calls through the existing `NativeBridge`.

**Tech Stack:** Flutter/Dart, Kotlin, Room, MethodChannel, Flutter widget tests, GitHub Actions Android APK build.

---

## Task 1: Category CRUD Bridge

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/TransactionCategoryDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/category_crud_bridge_test.dart`
- Test: `test/transactions/transaction_store_test.dart`

- [ ] Write failing Dart tests for bridge/store category add, update, delete, counts, and category filter.
- [ ] Run focused tests and verify missing methods fail.
- [ ] Add DAO insert/update/delete/count helpers.
- [ ] Add repository methods with validation and Hungarian type normalization.
- [ ] Expose MethodChannel methods.
- [ ] Add NativeBridge and TransactionRepository wrappers.
- [ ] Add TransactionStore category methods and reload behavior.
- [ ] Run focused tests and commit.

## Task 2: Slot Managers And Icon Assets

**Files:**
- Create: `lib/features/transactions/slots/category_color_manager.dart`
- Create: `lib/features/transactions/slots/category_icon_manager.dart`
- Create: `assets/category_icons/slot_00.png` through `assets/category_icons/slot_20.png`
- Modify: `pubspec.yaml`
- Modify: `lib/features/transactions/models/transaction_category.dart`
- Test: `test/transactions/category_slot_managers_test.dart`

- [ ] Write failing tests for 21 exact colors and 21 asset icon slots.
- [ ] Generate local PNG icon assets with simple distinct shapes/colors.
- [ ] Register assets in pubspec.
- [ ] Implement color and icon managers.
- [ ] Route `TransactionCategory.slotColor` through `CategoryColorManager`.
- [ ] Run focused tests and commit.

## Task 3: Header Card

**Files:**
- Create: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/header_card_test.dart`

- [ ] Write failing widget test for Stage0 header dimensions, labels, category button, balance, and expand arrow callback.
- [ ] Implement focused header widget with 204 px height and copied design constants.
- [ ] Compose it into `TransactionHomePage` and adjust body top spacing.
- [ ] Run focused tests and commit.

## Task 4: Category Picker Menu And Cards

**Files:**
- Create: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Create: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Create: `lib/features/transactions/widgets/category_menu/category_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/category_menu_test.dart`

- [ ] Write failing widget tests for category button opening menu, menu header controls, active-type filtering, card tap filtering, and delete disabled when count is non-zero.
- [ ] Implement overlay state and picker panel.
- [ ] Implement category card design and callbacks.
- [ ] Wire card tap to store category filter.
- [ ] Run focused tests and commit.

## Task 5: Add And Modify Category Menus

**Files:**
- Create: `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`
- Create: `lib/features/transactions/widgets/category_menu/category_slot_grid.dart`
- Create: `lib/features/transactions/widgets/category_menu/category_preview_pill.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Test: `test/transactions/category_editor_test.dart`

- [ ] Write failing widget tests for add menu, modify menu, color/icon swipe grid, preview pill, save add, save update, and delete category.
- [ ] Implement shared editor panel for add and modify.
- [ ] Implement swipeable color/icon grid using managers.
- [ ] Implement preview pill.
- [ ] Wire save/delete to store.
- [ ] Run focused tests and commit.

## Task 6: Full Verification And Online Build

**Files:**
- Any formatting updates.

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Commit any verification fixes.
- [ ] Push `main` to GitHub.
- [ ] Watch GitHub Actions run until completed.
- [ ] Report APK artifact name and run URL.
