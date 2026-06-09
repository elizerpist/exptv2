# Main Joystick Export Google Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one main-branch debug APK that includes the existing recurring/design work, the statistics joystick, working export surfaces, and a more robust Google Sheets sign-in flow.

**Architecture:** Work from the `main` worktree only. Port the joystick UI from `stats-joystick` as a focused UI component change, keep the already-merged export/recurring/design code on main, and fix CI/build compatibility in the main workflow.

**Tech Stack:** Flutter/Dart, `google_sign_in` 7.x, GitHub Actions Android debug APK build.

---

### Task 1: Main Scope Guard

**Files:**
- Inspect: git history and `lib/features/settings/widgets/options/export_options_panel.dart`
- Inspect: recurring and design files already present in main

- [ ] **Step 1: Verify branch and clean status**

Run: `git status --short --branch`
Expected: `## main...origin/main` with no modified files before implementation.

- [ ] **Step 2: Verify recurring/design commits are reachable from main**

Run: `git log --oneline --grep='recurring\\|ghost\\|surface\\|theme' -20`
Expected: entries for recurring trigger time controls and ghost/surface design work.

### Task 2: Joystick Visual Feedback

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests that long-press the joystick trigger and verify:
- `calendar-threshold-joystick-plus-indicator` appears above the trigger during upward drag.
- `calendar-threshold-joystick-minus-indicator` appears below the trigger during downward drag.
- `calendar-threshold-joystick-speed-fast` appears for far drags.
- `calendar-threshold-joystick-speed-slow` appears for near drags.

- [ ] **Step 2: Run focused tests and confirm failure**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: new indicator/speed key expectations fail before production code changes.

- [ ] **Step 3: Implement visual feedback and speed curve**

Add active-direction indicators around the existing floating trigger. Replace the current 1/3/5 coarse speed with a distance band where close movement is slower and far movement is faster.

- [ ] **Step 4: Run focused tests and confirm pass**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: all calendar menu widget tests pass.

### Task 3: Google Sign-In UX and Flow

**Files:**
- Modify: `lib/features/transactions/sync/google_sheets_auth_client.dart`
- Modify: `lib/features/settings/widgets/options/export_options_panel.dart`
- Modify: `test/transactions/google_sheets_sync_controller_test.dart`
- Add or modify focused export panel widget tests if needed.

- [ ] **Step 1: Write failing tests**

Add tests proving Google sign-in cancellation/configuration errors surface as Hungarian user-facing messages rather than raw `GoogleSignInException(...)`, and that scope authorization uses the documented `authorizeScopes`/`authorizationHeaders` flow.

- [ ] **Step 2: Run focused tests and confirm failure**

Run: `flutter test test/transactions/google_sheets_sync_controller_test.dart test/settings/settings_page_test.dart`
Expected: new behavior fails before production code changes.

- [ ] **Step 3: Implement auth-flow and messaging fixes**

Keep `authenticate(scopeHint: scopes)`, then request `authorizationForScopes`; if null, call `authorizeScopes(scopes)`, then read `authorizationHeaders(scopes)`. Map Google sign-in errors to stable Hungarian UI messages.

- [ ] **Step 4: Run focused tests and confirm pass**

Run: `flutter test test/transactions/google_sheets_sync_controller_test.dart test/settings/settings_page_test.dart`
Expected: focused tests pass.

### Task 4: Main Build Compatibility

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `.github/workflows/android-build.yml`
- Modify: `lib/features/settings/widgets/push_log/push_notification_log_page.dart` only if analyzer requires it on current Flutter.

- [ ] **Step 1: Apply proven main build fixes**

Set Android `minSdk = 24` and run Android unit tests as `:app:testDebugUnitTest` in CI.

- [ ] **Step 2: Run local verification**

Run: `flutter analyze` and `flutter test`.
Expected: analyzer has no issues and all Flutter tests pass.

- [ ] **Step 3: Commit, push, and online build**

Run: `git push origin main`, then watch the GitHub Actions APK workflow.
Expected: online build succeeds and updates `debug-latest` with a new `exptv2-debug.apk`.
