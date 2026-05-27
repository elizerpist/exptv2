# Exptv2 Interval Category Limits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build interval-specific category/overview limit storage and the expt0926-style Stage1 category budget bars in Flutter.

**Architecture:** Kotlin Room owns persistence in a new `category_limits` table with one row per target/type/window/period. Flutter loads limits through the existing MethodChannel bridge, derives bar data through a centralized `LimitManager`, and renders Stage1 bars behind the copied Stage0 header.

**Tech Stack:** Flutter/Dart, Kotlin, Room, MethodChannel, Flutter unit/widget tests, GitHub Actions Android APK build.

---

## Task 1: Backend Category Limit Bridge

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/CategoryLimitEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/CategoryLimitDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`
- Test: `test/transactions/category_limit_bridge_test.dart`

- [ ] Write failing NativeBridge tests for `expenseListCategoryLimits` and `expenseUpsertCategoryLimit`.
- [ ] Run the focused bridge test and verify it fails because methods/models are missing.
- [ ] Add Room entity and DAO for `category_limits` with unique target/type/window/period identity.
- [ ] Bump Room database to version 2 and add a migration that creates `category_limits`.
- [ ] Add repository list/upsert methods with validation for target, type, window, period, and non-negative amount.
- [ ] Expose MethodChannel methods.
- [ ] Add NativeBridge wrappers.
- [ ] Run focused bridge tests and commit.

## Task 2: Dart Limit Models And LimitManager

**Files:**
- Create: `lib/features/transactions/models/category_limit.dart`
- Create: `lib/features/transactions/models/category_budget_bar_data.dart`
- Create: `lib/features/transactions/data/limit_manager.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/limit_manager_test.dart`
- Test: `test/transactions/transaction_store_test.dart`

- [ ] Write failing tests for monthly/yearly/all-time period keys, record filtering, limit matching, and progress color thresholds.
- [ ] Add `CategoryLimit`, `LimitTargetType`, and `LimitWindow` models.
- [ ] Add `CategoryBudgetBarData` for UI-ready bar state.
- [ ] Implement `LimitManager` calculations from categories, records, limits, active type, summary window, and reference date.
- [ ] Extend repository/store to load limits and save current-window limits.
- [ ] Run focused model/store tests and commit.

## Task 3: Stage1 Category Bars UI

**Files:**
- Create: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Create: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Create: `lib/features/transactions/widgets/header_card/category_progress_bar.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] Write failing widget tests for Stage1 visibility, overview/category bar rendering, swipe navigation, and progress color.
- [ ] Implement the Stage1 background behind the header when expanded.
- [ ] Implement the 70 px expt0926-style bar with slot color/icon, title, amount, optional progress, and swipe behavior.
- [ ] Wire Stage1 bars to `TransactionStore.categoryBudgetBars`.
- [ ] Run focused widget tests and commit.

## Task 4: Limit Editor Menu

**Files:**
- Create: `lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/category_limit_editor_test.dart`

- [ ] Write failing widget tests for opening the editor, editing limit amount, clearing limit, toggling alert, and saving.
- [ ] Implement the expt0926 BudgetPicker-style menu with preview bar, remaining/over bar, numeric input, reset button, cancel, and save.
- [ ] Wire save to `TransactionStore.saveCategoryLimitForBar`.
- [ ] Run focused widget tests and commit.

## Task 5: Full Verification And Online Build

**Files:**
- Any formatting or analyzer fixes.

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Commit verification fixes if any.
- [ ] Push `main` to GitHub.
- [ ] Watch the GitHub Actions APK build until completed.
- [ ] Report APK artifact name and run URL.
