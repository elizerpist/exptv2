# Main Branch Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Subagent-driven development is not recommended here because the merge tasks share one mutable git index and the statistics/theme/parser branches overlap in the same Flutter files.

**Goal:** Merge the 2026-06-08 feature branches into `main`, then implement the event-driven NotificationListenerService parser toggle behavior on top of the unified app.

**Architecture:** First integrate branch tips in dependency order so predecessor branches are included through their newest descendant. Then add the global push parser toggle and early listener eligibility checks in Kotlin/Flutter using the existing parser profile and debug-console paths. Verification happens through focused Flutter tests, Android unit tests, analyze, and GitHub Actions after pushing `main`.

**Tech Stack:** Flutter/Dart, Android Kotlin, Room/SQLite, Gradle unit tests, GitHub Actions APK build.

---

## Branch Scope

Branches with 2026-06-08 tip commits:

- `feature/push-notification-log-training` at `4c9e2bb`
- `feature/push-log-app-filter-ui` at `646229e`
- `feature/push-log-parser-training-fixes` at `8dddb20`
- `feature/statistics-visual-rework` at `7a68c99`
- `feature/neumorphism-night-theme` at `3090f69`
- `feature/neumorphism-night-theme-clean` at `8aa5f5e`

Integration rules:

- `feature/push-log-parser-training-fixes` contains `feature/push-log-app-filter-ui` and `feature/push-notification-log-training`, so merge only the newest parser stack branch.
- `feature/neumorphism-night-theme-clean` contains the current clean theme work.
- `feature/neumorphism-night-theme` has one unique patch-equivalent commit left after comparing to the clean branch: `3090f69 fix: anchor stats sliders to bottom overlay`; merge it after the clean theme branch.
- Keep the already pushed `main` spec commit `50ec8b6`.

## Files and Responsibilities

- `.github/workflows/android-build.yml`: keep Android unit tests and online APK build coverage from parser branch.
- `android/app/src/main/kotlin/com/exptv2/app/PushNotificationListenerService.kt`: event-driven notification entry point; add global toggle/profile early-skip behavior.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`: parser profile storage; add and read the global automatic push parser toggle.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationCaptureEligibility.kt`: app/profile matching; preserve enabled-profile-only eligibility.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`: captured push message insert and parser dispatch; ensure disabled/global-off notifications do not insert rows.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: push-created transaction insertion and merchant category inheritance.
- `lib/features/settings/settings_page.dart`: unified Settings UI; include parser settings, global push parser toggle, statistics/theme settings without dropping existing menus.
- `lib/features/settings/models/notification_parser_rule.dart`: keep profile enablement independent.
- `lib/features/settings/widgets/notification_parser_rule_editor.dart`: keep per-profile enable/disable behavior.
- `lib/features/settings/widgets/push_log/*`: captured push message list and training UI.
- `lib/services/native_bridge.dart`: bridge methods for parser profiles, push logs, and global push parser toggle.
- `lib/features/stats/stats_page.dart` and `lib/features/transactions/widgets/calendar_menu/*`: statistics visual rework.
- `lib/features/settings/theme/*`, `lib/features/shell/*`, and themed transaction widgets: neumorphism theme work.
- Android tests under `android/app/src/test/kotlin/com/exptv2/app/**`: parser, eligibility, settings, and repository behavior.
- Flutter tests under `test/settings/**`, `test/transactions/**`, `test/shell/**`: merged UI behavior.

### Task 1: Verify Clean Main and Remote State

**Files:** none

- [ ] **Step 1: Confirm `main` is clean and pushed**

Run:

```bash
git status --short --branch
git log --oneline --decorate -3
```

Expected:

```text
## main...origin/main
50ec8b6 docs: design notification listener parser
```

- [ ] **Step 2: Refresh remote branches**

Run:

```bash
git fetch --all --prune
```

Expected: command exits successfully.

### Task 2: Merge 2026-06-08 Branch Tips Into Main

**Files:** branch-dependent merge changes across Android, Flutter, docs, and tests

- [ ] **Step 1: Merge parser stack**

Run:

```bash
git merge --no-ff feature/push-log-parser-training-fixes -m "merge: push parser settings and training"
```

Expected: merge completes or reports conflicts. If conflicts appear, resolve by keeping the parser branch behavior while preserving `docs/superpowers/specs/2026-06-08-main-notification-listener-parser-design.md` from `main`.

- [ ] **Step 2: Merge statistics visual rework**

Run:

```bash
git merge --no-ff feature/statistics-visual-rework -m "merge: statistics visual rework"
```

Expected: merge completes or reports conflicts. If conflicts appear in shared Settings/calendar files, keep both parser Settings menus and statistics visual behavior.

- [ ] **Step 3: Merge clean neumorphism theme**

Run:

```bash
git merge --no-ff feature/neumorphism-night-theme-clean -m "merge: neumorphism theme surfaces"
```

Expected: merge completes or reports conflicts. If conflicts appear, keep statistics visual behavior and apply the clean theme surfaces around it.

- [ ] **Step 4: Merge remaining unique neumorphism fix**

Run:

```bash
git merge --no-ff feature/neumorphism-night-theme -m "merge: neumorphism slider anchor fix"
```

Expected: merge completes or reports conflicts. Since this branch has only one unique patch relative to the clean branch, preserve the slider anchor fix without reintroducing removed night theme mode.

- [ ] **Step 5: Confirm predecessor branches are included**

Run:

```bash
git merge-base --is-ancestor feature/push-notification-log-training main
git merge-base --is-ancestor feature/push-log-app-filter-ui main
git merge-base --is-ancestor feature/push-log-parser-training-fixes main
git merge-base --is-ancestor feature/statistics-visual-rework main
git merge-base --is-ancestor feature/neumorphism-night-theme-clean main
git merge-base --is-ancestor feature/neumorphism-night-theme main
```

Expected: every command exits with code `0`.

### Task 3: Add Red Tests for Global and Profile-Level Parser Enablement

**Files:**

- Modify: `android/app/src/test/kotlin/com/exptv2/app/NotificationParserRuleStoreTest.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/NotificationCaptureEligibilityTest.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt`
- Modify: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Add failing tests for global toggle off**

Add Android and bridge tests that assert a disabled global automatic push parser toggle causes listener/repository processing to skip capture, parse, and transaction insert.

- [ ] **Step 2: Add failing tests for disabled matching profile**

Add tests where an Erste notification matches a disabled Erste profile and asserts no captured event and no transaction.

- [ ] **Step 3: Add failing tests for independent profiles**

Add tests where Erste is disabled and Revolut is enabled. Assert Erste is skipped and Revolut is captured/parsed.

- [ ] **Step 4: Run focused tests and confirm red**

Run:

```bash
./gradlew testDebugUnitTest
flutter test test/settings/settings_bridge_test.dart
```

Expected: the newly added tests fail because the global toggle/early skip behavior has not been implemented yet.

### Task 4: Implement Global Toggle and Early Listener Skip

**Files:**

- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/PushNotificationListenerService.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/settings/settings_page.dart`

- [ ] **Step 1: Add native storage for the global toggle**

Store a boolean automatic push parser setting. Default should be `true` so existing configured parsing continues unless the user turns it off.

- [ ] **Step 2: Expose native bridge methods**

Add methods to read and write the global toggle from Flutter Settings.

- [ ] **Step 3: Add Settings control**

Add a toggle in the parser/settings area. It controls global automatic push parser processing, not Android notification listener permission.

- [ ] **Step 4: Add listener/repository early skip**

Check global toggle first. Then evaluate enabled matching profiles. Skip disabled-only matches before inserting a captured message.

- [ ] **Step 5: Add debug logs**

Log `global_disabled`, `profile_disabled`, `no_enabled_profile_match`, enabled profile match, capture insert, parse success/failure, transaction insert/link, duplicate skip, and elapsed timing.
