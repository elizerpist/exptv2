# Center Badge Live Tuning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add temporary live Center Badge tuning controls for colored badge opacity, masking, per-slot size, and per-slot horizontal offsets.

**Architecture:** Extend the existing `AppThemeSettings` value object with persisted tuning arrays, wire those arrays through `CategoryBudgetStage` into `_CenterBadgeWheel`, and reuse the existing Backheader settings panel as a no-veil `SlideUpMenuCard` opened from Center Badge backheader background taps. The render path keeps current defaults unchanged and applies custom values only when provided.

**Tech Stack:** Flutter/Dart widgets and tests, existing Android Kotlin `ExpenseSettingsStore`, GitHub Actions for APK builds.

## Global Constraints

- Run Flutter tests and `flutter analyze` inside Ubuntu proot, not Termux-host Flutter.
- Do not run local APK builds on Android/Termux; APK builds run through GitHub Actions.
- Keep one final implementation commit only after checklist items are verified.
- Use TDD: write failing tests before production code.
- Preserve current default visuals when all new settings are at defaults.
- Keep verification scoped to the changed surfaces with the targeted Flutter suite; Android unit tests are covered by GitHub Actions because local Ubuntu proot lacks Android SDK configuration in this environment.

---

### Task 1: Settings Model And Persistence

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `test/settings/backheader_style_options_panel_test.dart`
- Modify: `test/settings/settings_bridge_test.dart`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

**Steps:**
- [x] Add RED tests proving defaults, clamping, `toMap` round-trip, Flutter bridge payload, and Android store persistence for:
  - `centerBadgeColoredFillOpacities`: 5 ints, default `[100, 72, 58, 48, 42]`
  - `centerBadgeColoredIconOpacities`: 5 ints, default `[100, 72, 58, 48, 42]`
  - `centerBadgeColoredProgressOpacities`: 5 ints, default `[100, 72, 58, 48, 42]`
  - `centerBadgeSlotSizePercents`: 9 ints, default `[100,100,100,100,100,100,100,100,100]`
  - `centerBadgeSlotXOffsets`: 9 ints, default `[0,0,0,0,0,0,0,0,0]`
- [x] Run targeted tests and confirm failure from missing fields.
- [x] Add settings fields, constants, `fromMap`, `toMap`, `copyWith`, and Kotlin persistence.
- [x] Run targeted tests and confirm pass.

### Task 2: Settings Panel Controls

**Files:**
- Modify: `lib/features/settings/widgets/options/backheader_style_options_panel.dart`
- Modify: `test/settings/backheader_style_options_panel_test.dart`

**Steps:**
- [x] Add RED widget tests for new colored opacity groups and 18 per-slot size/offset slider+input rows.
- [x] Run panel tests and confirm failure.
- [x] Add controls using the existing slider + numeric pill pattern.
- [x] Run panel tests and confirm pass.

### Task 3: Center Badge Render Controls

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `test/transactions/category_budget_stage_test.dart`

**Steps:**
- [x] Add RED render tests proving colored badge fill/icon/progress opacities affect neutral/color badge mode, mask applies there too, slot size percent changes rendered size, and slot X offset changes rendered center.
- [x] Run targeted render tests and confirm failure.
- [x] Wire settings through constructors and apply them in `_CenterBadgeWheel`.
- [x] Run targeted render tests and confirm pass.

### Task 4: Temporary Live Backheader Tuning Sheet

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `test/transactions/transaction_home_limits_test.dart`

**Steps:**
- [x] Add RED widget test proving Center Badge background tap opens a `SlideUpMenuCard` with no veil and live Backheader settings controls.
- [x] Run targeted test and confirm failure.
- [x] Add a background tap callback from Center Badge surface to `TransactionHomePage`; render `BackheaderStyleOptionsPanel` inside `SlideUpMenuCard(showFocusVeil: false)`.
- [x] Run targeted test and confirm pass.

### Task 5: Verification And Delivery

**Files:**
- Modify: checklist status only after verification.

**Steps:**
- [x] Run targeted Flutter tests in Ubuntu proot.
- [x] Run `flutter analyze` in Ubuntu proot.
- [x] Confirm local Android unit-test limitation and rely on GitHub Actions for Android Gradle verification.
- [x] Update checklist statuses for CBB-63 through CBB-67.
- [ ] Commit once, push branch, run GitHub Actions, download APK to `/storage/emulated/0/Download/exptv2`.
