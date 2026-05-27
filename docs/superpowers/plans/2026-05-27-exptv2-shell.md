# Exptv2 Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork the working PushParserV2 Flutter app into Exptv2, keep the push scraping engine integrated but hidden, and show a blank expense tracker shell with bottom navigation, a centered FAB, and a settings filter/app picker control.

**Architecture:** The Android notification/accessibility scraper remains in place as infrastructure. The Flutter UI is replaced with small focused shell components: centralized colors/theme, app tab state, bottom nav, floating action button, blank pages, and settings controls. Tests cover the expected shell behavior before implementation.

**Tech Stack:** Flutter, Material 3, Dart widget tests, Android Kotlin notification/accessibility services.

---

### Task 1: Preserve Fork Identity

**Files:**
- Modify: `pubspec.yaml`
- Modify: `README.md`
- Modify: `.github/workflows/android-build.yml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] Rename the Flutter package/app copy from `pushparserv2` to `exptv2`.
- [ ] Keep the native push parser channels and services intact.
- [ ] Update README and artifact names so GitHub output identifies this app as Exptv2.

### Task 2: Add Shell Widget Tests

**Files:**
- Modify: `test/widget_test.dart`

- [ ] Add a test that expects a blank Exptv2 shell with four bottom nav labels and one FAB.
- [ ] Add a test that taps bottom nav items and verifies the active blank page changes.
- [ ] Add a test that opens Settings and verifies the app regex input plus installed-app picker button are visible there.
- [ ] Run `flutter test test/widget_test.dart` and confirm these tests fail against the copied PushParserV2 UI.

### Task 3: Create Focused Shell Components

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/features/shell/app_tab.dart`
- Create: `lib/features/shell/expt_shell.dart`
- Create: `lib/features/shell/widgets/expt_bottom_nav.dart`
- Create: `lib/features/shell/widgets/expt_fab.dart`
- Create: `lib/features/shell/widgets/blank_tab_page.dart`
- Create: `lib/features/settings/settings_page.dart`
- Create: `lib/features/settings/widgets/app_filter_control.dart`
- Modify: `lib/main.dart`

- [ ] Centralize the old RN color values in `AppColors`.
- [ ] Keep bottom nav height `80`, FAB size `66`, FAB color `#06b6d4`, nav border `#e2e8f0`, inactive text `#64748b`.
- [ ] Render blank pages for every tab except Settings.
- [ ] Move the push parser filter text input and installed-app picker control into Settings.
- [ ] Keep scraper engine construction in `main.dart`, but do not render the old captured-event feed.

### Task 4: Keep Engine Tests Passing

**Files:**
- Modify package imports in `test/*.dart`

- [ ] Update test imports to `package:exptv2/...`.
- [ ] Keep existing model/store/native bridge tests unchanged in behavior.
- [ ] Run `flutter test`.

### Task 5: Build, Commit, Push, Trigger GitHub Build

**Files:**
- All changed files

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build apk --debug` if local Flutter/Java tooling supports it.
- [ ] Commit all changes.
- [ ] Set the GitHub remote to the Exptv2 repository when available.
- [ ] Push to GitHub.
- [ ] Trigger the `android-build.yml` workflow with `gh workflow run` if GitHub CLI/auth is available.
