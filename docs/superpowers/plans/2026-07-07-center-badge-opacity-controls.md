# Center Badge Opacity Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add manual opacity tuning controls for colored Center Badge white layers and background while preserving the current default look.

**Architecture:** Store opacity values in `AppThemeSettings`, persist them through the native settings store, expose them in the Backheader settings panel, and pass them through the transaction header into the Center Badge renderer. The renderer applies these values only when `BackheaderCenterDesign.colored` is active.

**Tech Stack:** Flutter/Dart settings and widget tests, Android Kotlin settings store tests, Ubuntu proot for local Flutter test/analyze, GitHub Actions for APK build.

## Global Constraints

- Do not create partial commits or builds; commit and build only after all checklist items are complete.
- Run local Flutter tests/analyze through Ubuntu proot, not Termux Flutter directly.
- APK build must run on GitHub Actions and then be downloaded to `/storage/emulated/0/Download/exptv2`.
- Preserve the current visual defaults unless the user changes the new settings.

---

### Task 1: Settings Model And Persistence

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Test: `test/settings/backheader_style_options_panel_test.dart`
- Test: `test/settings/settings_bridge_test.dart`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

**Interfaces:**
- Produces: opacity fields for disc, icon, progress, and colored background.
- Consumes: current Center Badge settings map and native update/load flow.

- [x] Write failing serialization and native-store tests for defaults, clamp behavior, and round trip.
- [x] Implement minimal settings fields, parsing, clamping, `copyWith`, `toMap`, and native persistence.
- [x] Re-run targeted tests through Ubuntu proot for Flutter; leave Android unit verification to GitHub if local ARM tooling fails.

### Task 2: Settings Panel Controls

**Files:**
- Modify: `lib/features/settings/widgets/options/backheader_style_options_panel.dart`
- Test: `test/settings/backheader_style_options_panel_test.dart`

**Interfaces:**
- Consumes: opacity settings from Task 1.
- Produces: 16 slider plus numeric text-pill controls.

- [x] Write failing widget tests that find 15 layer controls plus 1 background control and verify slider/text input updates.
- [x] Add reusable opacity slider rows for distance labels: center, neighbor, next, far, edge.
- [x] Keep controls under the Center Badge settings section and only relevant to colored white-layer tuning.

### Task 3: Render Wiring

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

**Interfaces:**
- Consumes: opacity settings from Task 1.
- Produces: colored-mode layer opacity behavior and 2 px closer immediate neighbors.

- [x] Write failing render tests for custom disc, icon, progress, and background opacity.
- [x] Write failing geometry test for immediate neighbor badges being 2 px closer.
- [x] Apply opacity values only in colored Center Badge mode; keep neutral mode unchanged.
- [x] Re-run targeted Center Badge tests.

### Task 4: Final Verification And Delivery

**Files:**
- Modify: checklist statuses in `docs/superpowers/checklists/2026-07-06-center-badge-backheader-partition-checklist.md`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: final commit, pushed branch, GitHub Actions APK, downloaded artifact.

- [x] Run targeted Flutter tests in Ubuntu proot.
- [x] Run full Flutter test suite in Ubuntu proot.
- [x] Run `flutter analyze` in Ubuntu proot.
- [x] Re-read and update checklist statuses.
- [ ] Commit once, push, wait for GitHub Actions debug APK, download to `/storage/emulated/0/Download/exptv2`.
