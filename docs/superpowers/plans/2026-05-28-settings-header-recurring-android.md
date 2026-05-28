# Settings, Header FastInfo, and Recurring Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the original RN settings menu, header pull-down FastInfo, fixed backheader button behavior, theme/magnet settings, and recurring transaction scheduling into the Flutter/Kotlin app with full Android persistence and background processing.

**Architecture:** Flutter owns UI and state; Kotlin owns Room persistence, recurring transaction processing, notification creation, and WorkManager scheduling. MethodChannel methods bridge settings, FastInfo config, recurring transaction CRUD, and manual recurring processing. The header uses Flutter gestures and animations while keeping the expand button outside the sliding card.

**Tech Stack:** Flutter/Dart widgets and tests, Android Kotlin, Room, WorkManager, NotificationManagerCompat, MethodChannel, GitHub Actions APK build.

---

## File Structure

- Modify `lib/services/native_bridge.dart`: settings, FastInfo, and recurring transaction bridge methods.
- Create `lib/features/settings/models/app_theme_settings.dart`: theme/magnet settings model.
- Create `lib/features/settings/models/fast_info_config.dart`: FastInfo slot/config model.
- Create `lib/features/settings/models/recurring_transaction.dart`: recurring transaction model.
- Create `lib/features/settings/data/settings_repository.dart`: Dart repository over `NativeBridge`.
- Create `lib/features/settings/state/settings_store.dart`: UI state and persistence calls.
- Replace `lib/features/settings/settings_page.dart`: original RN menu structure and submenu routing.
- Create focused widgets under `lib/features/settings/widgets/options/`: menu sections, submenu shell, theme menu, FastInfo menu, parsed-app menu, simple option menus, recurring menu.
- Modify `lib/features/shell/expt_shell.dart`: pass `NativeBridge` into `SettingsPage`.
- Modify `lib/features/transactions/transaction_home_page.dart`: header pull-down and FastInfo rendering.
- Modify `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: keep expand button fixed outside the sliding card and expose drag handlers.
- Create `lib/features/transactions/widgets/header_card/fast_info_panel.dart`: 3 pill + 3 box FastInfo panel.
- Modify `android/app/build.gradle.kts`: add `androidx.work:work-runtime-ktx`.
- Modify `android/app/src/main/AndroidManifest.xml`: worker-safe metadata/permissions if needed.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`: DB version migration and new entities/DAOs.
- Create `RecurringTransactionEntity.kt`, `RecurringTransactionDao.kt`, `ExpenseSettingsStore.kt`, `RecurringTransactionWorker.kt`, `RecurringTransactionScheduler.kt`, `RecurringNotificationHelper.kt`.
- Modify `ExpenseRepository.kt` and `ExpenseMethodChannel.kt`: recurring CRUD/process and settings bridge methods.
- Add/modify tests under `test/settings/`, `test/transactions/`, and `test/widget_test.dart`.

## Tasks

### Task 1: Dart Models and Bridge Tests

- [ ] Add failing tests in `test/settings/settings_bridge_test.dart` for `expenseLoadSettings`, `expenseUpdateThemeSettings`, FastInfo update, recurring list/add/update/delete/toggle, and `expenseProcessRecurringTransactions`.
- [ ] Run targeted Flutter test and confirm it fails because models and bridge methods do not exist.
- [ ] Implement `AppThemeSettings`, `FastInfoConfig`, `FastInfoSlot`, `RecurringTransaction`.
- [ ] Extend `NativeBridge` with settings and recurring methods.
- [ ] Re-run the targeted test and commit `test: cover settings and recurring bridge`.

### Task 2: Kotlin Persistence and Background Engine

- [ ] Add Room recurring entity/DAO with id, name, amount, transactionType, dayOfMonth, category fields, active state, last processed period, and timestamps.
- [ ] Add `MIGRATION_2_3` creating `recurring_transactions` and indexes.
- [ ] Add repository CRUD/toggle/list/process methods.
- [ ] Processing rule: active monthly items fire once per `yyyy-MM`; if configured day is beyond the month length, fire on the last day; generated transaction uses selected category and signed amount.
- [ ] Add `RecurringTransactionWorker`, unique daily WorkManager scheduling, and notification channel/helper.
- [ ] Extend `ExpenseMethodChannel` with recurring/settings methods.
- [ ] Commit `feat: add native recurring transaction engine`.

### Task 3: Settings Store and Menus

- [ ] Add failing widget tests for the RN settings sections, theme/magnet submenu, FastInfo submenu, and recurring submenu.
- [ ] Implement `SettingsRepository` and `SettingsStore`.
- [ ] Replace `SettingsPage` with a submenu shell matching the original RN layout: full gray page, 80px header, back button in submenus, white section cards, switch rows.
- [ ] Implement parsed app submenu using existing `AppFilterControl`.
- [ ] Implement theme menu with `fade`, `nofade`, `budget`, `magnetcard`, `adaptive` and color/card/background/box groups.
- [ ] Implement recurring menu with category pill, name/amount/day inputs, list cards, active/inactive toggle, edit, delete.
- [ ] Re-run targeted settings widget tests and commit `feat: port settings menus`.

### Task 4: FastInfo and Header Pull-Down

- [ ] Add failing tests for header pull-down reveal, fixed expand button position, and configured FastInfo slots.
- [ ] Implement `FastInfoPanel` with default RN slot values and dynamic transaction-derived values where available.
- [ ] Move expand button outside the sliding header content.
- [ ] Add vertical drag handling to reveal FastInfo and spring back on release.
- [ ] Keep category/calendar buttons behavior unchanged in collapsed state.
- [ ] Re-run header tests and commit `feat: add header fastinfo pull down`.

### Task 5: Integration Verification and Online Build

- [ ] Run full local verification: `flutter analyze` and `flutter test` in proot Ubuntu.
- [ ] Commit any remaining fixes.
- [ ] Push `main` to GitHub.
- [ ] Trigger/observe GitHub Actions APK build and report artifact name and run URL.

## Self-Review

- Spec coverage: settings menu, FastInfo, header downward swipe, fixed backheader button, magnet settings, recurring transaction scheduling, Android native background processing, notification creation, Kotlin persistence, Dart UI read/write are covered.
- Placeholder scan: no implementation step is intentionally deferred; WorkManager is the chosen native background implementation.
- Type consistency: Dart model names match bridge methods; Kotlin processing fields map directly to Dart `RecurringTransaction`.
