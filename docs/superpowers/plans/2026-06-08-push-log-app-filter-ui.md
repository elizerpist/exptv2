# Push Log App Filter UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restrict captured push logs to observed parser apps, clean the app selector/profile UI, add app icons and debug diagnostics, and preserve the settings submenu when the app resumes.

**Architecture:** Keep transaction parsing behavior intact by leaving the existing recurring push matcher semantics in place. Add a capture-time eligibility layer that reads enabled parser profiles and only persists notification events from exact selected package names or, as fallback, matching app label regex. Add a cached app-list path in Flutter, with native installed-app filtering limited to user-installed apps plus Google Wallet/Pay allowlist.

**Tech Stack:** Flutter/Dart widgets and tests, Android Kotlin services/repositories, Room-backed push notification store, GitHub Actions for APK builds.

---

### Task 1: Native App List Filtering

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Test: add or extend a Kotlin/JVM-testable helper if existing Gradle test support allows it; otherwise add Flutter bridge tests around returned rows.

- [ ] Write a failing test or small helper test for installed-app eligibility:
  - User-installed app is included.
  - Generic Android system package is excluded.
  - `com.google.android.apps.walletnfcrel` and `com.google.android.apps.nbu.paisa.user` are included even if system.
- [ ] Implement a focused predicate in `MainActivity.kt`:
  - Include apps where `(flags and ApplicationInfo.FLAG_SYSTEM) == 0`.
  - Include allowlisted Google payment packages.
  - Keep label/icon mapping unchanged.
- [ ] Add Android `Log.d` lines for raw installed app count and filtered count.
- [ ] Commit with `fix: filter installed app picker list`.

### Task 2: Parser Profile App Eligibility

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/NotificationCaptureEligibility.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/PushNotificationListenerService.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/PushAccessibilityService.kt`

- [ ] Write failing unit-level tests for `NotificationCaptureEligibility`:
  - Exact `packageName` profile match accepts.
  - Different package with same-looking text rejects.
  - Blank package but matching `appFilterText`/label fallback accepts.
  - Disabled profile rejects.
- [ ] Implement `NotificationCaptureEligibility` as a pure Kotlin object returning an eligibility result with `allowed`, `reason`, and matched profile metadata.
- [ ] Add `NotificationParserRuleStore.activeProfilesForCapture()` that exposes id, name, enabled, packageName, appLabel, appFilterText.
- [ ] Call eligibility before `NotificationEventRepository.insertDraft`.
- [ ] If not eligible, do not insert or broadcast the event.
- [ ] Keep `ExpenseRepository.processNotificationEventForRecurring` unchanged except for debug logs around candidate decisions.
- [ ] Commit with `fix: only persist push events for enabled parser apps`.

### Task 3: Debug Console Bridge

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/EventBroadcaster.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/state/event_store.dart`
- Modify: `lib/core/debug/debug_console.dart` or caller-side logging.

- [ ] Write failing Dart test proving native debug payloads are appended to `DebugConsole`.
- [ ] Extend event channel payloads to distinguish `notification_event` from `debug_log`.
- [ ] Keep backward compatibility for existing raw event payload maps.
- [ ] Publish debug messages for:
  - Capture accepted/rejected with source, package, label, reason.
  - Parser profile count and selected matched profile.
  - App list cache/load timing on Flutter side.
- [ ] Commit with `feat: surface push parser debug logs`.

### Task 4: App List Cache and Picker Search

**Files:**
- Modify: `lib/state/event_store.dart`
- Modify: `lib/features/settings/widgets/installed_app_picker_sheet.dart`
- Modify: `lib/features/settings/widgets/app_filter_control.dart`
- Test: `test/event_store_test.dart`, `test/widget_test.dart` or settings-specific tests.

- [ ] Write failing test that first `listInstalledApps()` hits native bridge and second call returns cached rows.
- [ ] Write failing widget test for bottom fixed search field filtering the app list.
- [ ] Add `EventStore.preloadInstalledApps()` during `start()`.
- [ ] Add `EventStore.listInstalledApps({bool forceRefresh = false})` with cache hit/miss debug logs.
- [ ] Rebuild picker as white fixed-height sheet with scrollable list and non-scrolling bottom search field.
- [ ] Commit with `feat: cache and search installed app picker`.

### Task 5: Parser Profile UI and Delete

**Files:**
- Modify: `lib/state/event_store.dart`
- Modify: `lib/features/settings/models/notification_parser_rule.dart`
- Modify: `lib/features/settings/widgets/notification_parser_rule_editor.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/event_store_test.dart`, `test/settings/settings_page_test.dart`, `test/widget_test.dart`.

- [ ] Write failing test for deleting selected and non-selected parser profiles.
- [ ] Add `EventStore.deleteNotificationParserProfile(String id)`.
- [ ] Add delete button with confirmation to each profile tile.
- [ ] Add app icon to profile tiles using `InstalledAppIcon` when a cached app matches package.
- [ ] Remove the manual regex input row.
- [ ] Put the app selector button beside the profile name text input.
- [ ] Preserve `appFilterText` as generated data from selected app; no manual editing.
- [ ] Commit with `feat: redesign parser profile controls`.

### Task 6: Push Log Icons, Overflow, and Event Sheet

**Files:**
- Modify: `lib/features/settings/widgets/push_log/push_notification_log_page.dart`
- Modify: `lib/features/settings/widgets/push_log/push_notification_log_box.dart`
- Modify: `lib/features/settings/widgets/push_log/push_notification_event_sheet.dart`
- Test: `test/settings/push_notification_log_page_test.dart`.

- [ ] Write failing widget test proving logbox renders app icon for matching package.
- [ ] Write failing widget test proving long status/message content does not overflow.
- [ ] Write failing widget test proving the event sheet has fixed height, white background, handle drag close, and independently scrolling body.
- [ ] Pass cached installed apps from `EventStore` to push log page/logbox.
- [ ] Replace `NL` source avatar with app icon where available, vertically centered.
- [ ] Keep source text available as metadata in the row/sheet, not as the avatar.
- [ ] Rework event sheet to use the same fixed-height/handle/body-scroll pattern as the app selector.
- [ ] Commit with `feat: polish push log list and event sheet`.

### Task 7: Settings Submenu Persistence

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/settings/settings_page_test.dart` or `test/widget_test.dart`.

- [ ] Write failing widget test that opens `Elkapott push üzenetek`, simulates rebuild/resume, and expects the submenu to remain open.
- [ ] Persist active settings menu in restorable/page-storage-safe state owned above fragile rebuild points.
- [ ] Log menu restore decisions to `DebugConsole`.
- [ ] Commit with `fix: preserve settings submenu on resume`.

### Task 8: Verification and APK

**Files:**
- Workflow only, no source edits unless CI exposes real failures.

- [ ] Run `git diff --check`.
- [ ] Run focused tests where local Flutter environment allows it; if Termux TLS blocks Dart, use GitHub Actions as authoritative.
- [ ] Push branch `feature/push-log-app-filter-ui`.
- [ ] Trigger `android-build.yml` manually for this branch.
- [ ] Wait for `flutter analyze`, `flutter test`, APK build, and release upload.
- [ ] Provide the direct release APK URL.
