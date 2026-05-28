# Recurring Stats Colors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an observable recurring background alarm test, keep recurring ghosts future-only in UI, unify slot-based category colors, and move the calendar into the Stats bottom tab.

**Architecture:** Extend the existing native recurring alarm method channel and Dart `RecurringAlarmService` instead of adding a new background system. Reuse `CalendarMenuOverlay` internals as a full-screen `StatsPage`, and resolve UI colors from current `TransactionCategory` data whenever available.

**Tech Stack:** Flutter/Dart widgets and widget tests, Android Kotlin `AlarmManager`/`BroadcastReceiver`, GitHub Actions for Flutter analyze/test/APK build.

---

### Task 1: Background Alarm Test Hook

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmScheduler.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmMethodChannel.kt`
- Modify: `lib/services/recurring_alarm_service.dart`
- Modify: `lib/core/debug/debug_console.dart`
- Test: `test/services/recurring_alarm_service_test.dart`
- Test: `test/core/debug_floating_button_test.dart`

- [ ] Add `scheduleDebugTestAlarm(delayMillis: Long)` in `RecurringAlarmScheduler` using a separate request code and the same `ACTION_PROCESS` receiver action.
- [ ] Add method channel call `scheduleRecurringDebugTestAlarm` that accepts `delayMillis`, schedules the test alarm, and returns `debugState()`.
- [ ] Add Dart method `scheduleDebugTestAlarm({Duration delay = const Duration(minutes: 2)})` to `RecurringAlarmService`.
- [ ] Add a debug console icon button keyed `recurring-debug-test-alarm` that calls the service method and logs the scheduled delay.
- [ ] Add service test asserting the method name and `delayMillis` payload.
- [ ] Add widget test tapping the button and asserting the channel call is made.

### Task 2: Future-Only Ghost Display

**Files:**
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/recurring_ghost_log_test.dart`

- [ ] Add a date comparison helper for `RecurringGhostRecord.normalizedDate` against `_clock()` month start.
- [ ] Filter `visibleGhostTransactions` so pending ghosts before the current month are hidden.
- [ ] Keep `_projectRecurringGhostsForActiveWindow()` able to ask native for any active window, but do not show ghosts from past months.
- [ ] Add tests for past-month hidden, current/future month visible, and activated ghost hidden.

### Task 3: Slot-Based Category Color Resolution

**Files:**
- Create: `lib/features/transactions/slots/category_color_resolver.dart`
- Modify: `lib/features/settings/widgets/options/recurring_options_panel.dart`
- Modify: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Modify: `lib/features/notifications/widgets/notification_log_box.dart` if category data is available at the caller; otherwise keep snapshot fallback.
- Modify: `lib/core/theme/app_colors.dart`
- Test: `test/transactions/category_slot_managers_test.dart`
- Test: `test/settings/settings_page_test.dart` or focused recurring options widget test if an existing fixture fits.

- [ ] Create resolver helpers that return current category color when a `TransactionCategory` exists and fallback to snapshot hex only when live category data is unavailable.
- [ ] Make recurring settings cards resolve their category by `transaction.categoryId` from `SettingsStore.expenseCategories` and render the live slot color.
- [ ] Keep notification cards safe by preserving snapshot color fallback where no live category list is passed.
- [ ] Remove duplicate slot color maps from `AppColors` or delegate them to `CategoryColorManager` to keep one slot palette in Dart.
- [ ] Add tests proving changing a category slot changes the recurring card color without changing the recurring transaction snapshot.

### Task 4: Stats Bottom Tab

**Files:**
- Modify: `lib/features/shell/app_tab.dart`
- Modify: `lib/features/shell/widgets/expt_bottom_nav.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Create: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Test: `test/widget_test.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] Rename `AppTab.groceries` to `AppTab.stats`, label it `Stats`, and use a stats icon.
- [ ] Add `StatsPage` that receives `TransactionStore` and renders the calendar menu full-screen above the bottom nav.
- [ ] Add a full-screen mode to calendar UI with square/full-screen material styling and no transparent dismiss layer.
- [ ] Remove home `_calendarOpen` state and the `header-calendar-button` entry point.
- [ ] Replace the second tab child in `ExptShell` with `StatsPage(store: _transactionStore)`.
- [ ] Update tests to expect Stats instead of Groceries and no home calendar overlay.

### Task 5: Debug Floating Button Placement

**Files:**
- Modify: `lib/core/debug/debug_floating_button.dart`
- Test: `test/core/debug_floating_button_test.dart`

- [ ] Position the debug console button at bottom-right above the bottom nav using `AppDimensions.bottomNavHeight` and safe-area padding.
- [ ] Keep it visible over all tabs but above shell navigation.
- [ ] Add/update widget test asserting the positioned widget is right-aligned and above the nav area.

### Task 6: Verification and Delivery

**Files:**
- All modified files above.

- [ ] Run `git diff --check` locally and expect no output.
- [ ] Run a read-only NUL byte scan over modified Dart/Kotlin/test files and expect no findings.
- [ ] Attempt local Flutter command and document the known TLS alignment blocker if it still fails.
- [ ] Commit implementation changes with a concise message.
- [ ] Push `main` to `origin`.
- [ ] Watch the latest GitHub Actions `Exptv2 Android APK Build` run until completion and report analyze/test/APK build status.
