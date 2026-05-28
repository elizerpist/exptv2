# Recurring Alarm Calendar Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace recurring transaction polling with a Maethclock-style exact alarm path, add a debug date tool, move calendar to bottom navigation, and apply the requested header, category, summary, search, logbox, magnet, and notification-card corrections.

**Architecture:** Kotlin/Room remains the durable data engine for recurring transactions, ghost rows, real transactions, category limits, and notification cards. Flutter owns UI state and calls Kotlin through focused MethodChannel wrappers. Recurring activation uses `AlarmManager` exact alarms plus app-open/resume processing as a safety net; it does not use a foreground service or continuous polling.

**Tech Stack:** Flutter/Dart, Material widgets, CustomPainter, MethodChannel, Android Kotlin, Room, AlarmManager, BroadcastReceiver, JUnit, Flutter widget tests, GitHub Actions APK build.

---

## Scope Check

This plan covers one coordinated batch because the features share the same Room database, transaction store, shell navigation, and notification-card surface. The tasks are split into small commits so native alarm behavior, debug tooling, calendar navigation, UI corrections, and notification triggers can be verified independently.

## File Structure

Create:

- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmDebugLogger.kt`: persistent native debug log for recurring alarm events.
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringDebugClockStore.kt`: persistent debug date override.
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmScheduler.kt`: exact alarm scheduling.
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmReceiver.kt`: due-ghost processing on alarm fire.
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringBootReceiver.kt`: reschedule after boot/package replacement.
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmMethodChannel.kt`: Flutter bridge for alarm sync/debug date.
- `android/app/src/main/kotlin/com/exptv2/app/expense/BudgetNotificationCardFactory.kt`: budget and spending-limit cards.
- `lib/features/transactions/services/recurring_alarm_scheduler_service.dart`: Dart bridge for `exptv2/recurring_alarm`.
- `lib/features/transactions/widgets/debug_date/debug_date_floating_button.dart`: floating date override UI.
- `lib/features/calendar/calendar_page.dart`: bottom-nav calendar tab.
- `lib/features/calendar/calendar_year_view.dart`: annual canvas and year swipe.
- `lib/features/calendar/calendar_month_detail_view.dart`: enlarged month view and month swipe.
- `lib/features/calendar/calendar_month_stats.dart`: pure month statistics.

Modify:

- `android/app/src/main/AndroidManifest.xml`: exact alarm and boot receiver declarations.
- `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`: register recurring alarm channel and remove WorkManager startup schedule.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`: `00:01` trigger.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt`: original card type.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: effective app clock, notification dedupe, budget alerts.
- `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt`: duplicate lookups.
- `lib/features/shell/app_tab.dart`: replace Groceries with Calendar.
- `lib/features/shell/expt_shell.dart`: calendar page, debug date button, lifecycle sync.
- `lib/features/shell/widgets/expt_bottom_nav.dart`: calendar nav item.
- `lib/features/transactions/transaction_home_page.dart`: remove header calendar overlay, spring header pullback, category overlay state.
- `lib/features/transactions/state/transaction_store.dart`: refresh after native recurring processing.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: remove calendar button, keep shadow.
- `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`: magnet height `105`.
- `lib/features/transactions/widgets/header_card/magnet_strip.dart`: full-width square edges and taller magnetcard mode.
- `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`: inline modal ending at bottom-nav top.
- `lib/features/transactions/widgets/summary_pill.dart`: instant content replacement.
- `lib/features/transactions/widgets/search_pill.dart`: two capsules without inner outline.
- `lib/features/transactions/widgets/transaction_log_box.dart`: pinned delete swipe and full-height border.
- `lib/features/transactions/widgets/transaction_log_list.dart`: pass async delete result.

---

### Task 1: Native `00:01` Trigger And Recurring Card Type

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactoryTest.kt`

- [ ] **Step 1: Write failing planner tests**

Add tests proving the due date does not activate at `00:00` and does activate at `00:01`:

```kotlin
@Test
fun doesNotActivateBeforeOneMinuteAfterMidnightOnDueDate() {
    val plan = RecurringGhostPlanner.plan(
        targetMillis = millis(2026, Calendar.MAY, 15, 0, 0),
        dayOfMonth = 15,
        lastProcessedPeriodKey = "2026-04",
        timeZone = utc,
    )

    assertFalse(plan.shouldActivate)
    assertTrue(plan.shouldShowGhost)
}

@Test
fun activatesAtOneMinuteAfterMidnightOnDueDate() {
    val plan = RecurringGhostPlanner.plan(
        targetMillis = millis(2026, Calendar.MAY, 15, 0, 1),
        dayOfMonth = 15,
        lastProcessedPeriodKey = "2026-04",
        timeZone = utc,
    )

    assertTrue(plan.shouldActivate)
    assertEquals(millis(2026, Calendar.MAY, 15, 0, 1), plan.triggerMillis)
}

private fun millis(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
    return Calendar.getInstance(utc).apply {
        clear()
        set(year, month, day, hour, minute, 0)
    }.timeInMillis
}
```

Change existing `millis(year, month, day)` test calls to `millis(year, month, day, 9, 0)`.

- [ ] **Step 2: Write failing notification-card type test**

In `RecurringNotificationCardFactoryTest`, expect:

```kotlin
assertEquals("recurring_transaction_alert", card.type)
```

- [ ] **Step 3: Run native tests and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && ./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.RecurringGhostPlannerTest" --tests "com.exptv2.app.expense.RecurringNotificationCardFactoryTest"'
```

Expected: tests fail on current `00:00` and `recurring_activation` behavior.

- [ ] **Step 4: Implement planner and card type**

Replace the trigger and activation in `RecurringGhostPlanner.plan`:

```kotlin
val trigger = Calendar.getInstance(timeZone).apply {
    clear()
    set(year, month, effectiveDay, 0, 1, 0)
    set(Calendar.MILLISECOND, 0)
}
return RecurringGhostPlan(
    periodKey = periodKey,
    date = date,
    effectiveDayOfMonth = effectiveDay,
    triggerMillis = trigger.timeInMillis,
    shouldShowGhost = !processedThisPeriod,
    shouldActivate = !processedThisPeriod && targetMillis >= trigger.timeInMillis,
)
```

In `RecurringNotificationCardFactory.activationCard`, set:

```kotlin
type = "recurring_transaction_alert",
```

- [ ] **Step 5: Run tests and commit**

Run the command from Step 3 again. Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt android/app/src/test/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactoryTest.kt
git commit -m "fix: activate recurring ghosts at 0001"
```

---

### Task 2: Maethclock-Style Exact Alarm Scheduler

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmDebugLogger.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringDebugClockStore.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmScheduler.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmReceiver.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringBootReceiver.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/RecurringAlarmMethodChannel.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Create native debug clock and logger**

Create `RecurringDebugClockStore` with these public methods:

```kotlin
fun effectiveNow(realNow: Long = System.currentTimeMillis()): Long
fun setOverride(targetMillis: Long): Long
fun clearOverride()
fun state(realNow: Long = System.currentTimeMillis()): Map<String, Any?>
```

`setOverride` normalizes the chosen day to local `00:01`. `state` returns `overrideMillis`, `effectiveMillis`, and `usingOverride`.

Create `RecurringAlarmDebugLogger` with:

```kotlin
fun log(message: String)
fun entries(): List<String>
fun clear()
```

The logger stores the newest 300 entries in `SharedPreferences` and writes messages like `[RecurringAlarm] scheduled next=1778803260000 mode=setAlarmClock`.

- [ ] **Step 2: Create exact scheduler**

Create `RecurringAlarmScheduler` using this decision order:

```kotlin
val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
val mode = when {
    canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP -> {
        alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerMillis, showIntent), intent)
        "setAlarmClock"
    }
    canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
        "setExactAndAllowWhileIdle"
    }
    canExact -> {
        alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
        "setExact"
    }
    else -> {
        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
        "set"
    }
}
```

The `sync()` method calls `ExpenseRepository(appContext).nextRecurringTriggerMillis()` and schedules the returned timestamp. If no timestamp exists, it cancels the pending intent and logs `active=0`.

- [ ] **Step 3: Add receiver and boot receiver**

`RecurringAlarmReceiver` uses `goAsync()`, loads `RecurringDebugClockStore.effectiveNow()`, calls `ExpenseRepository.processDueRecurringTransactions(target)`, logs processed count, and calls `RecurringAlarmScheduler.sync()`.

`RecurringBootReceiver` listens for `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED`, logs the action, and calls `RecurringAlarmScheduler.sync()`.

- [ ] **Step 4: Add MethodChannel**

Create `RecurringAlarmMethodChannel` on channel `exptv2/recurring_alarm` with methods:

```kotlin
syncRecurringAlarms -> Boolean
processRecurringNow -> Map("processedCount" to Int, "processed" to List<Map<String, Any?>>)
setDebugDateOverride -> Map("state" to clock.state(), "processedCount" to Int)
clearDebugDateOverride -> clock.state()
loadRecurringAlarmDebugState -> clock.state() + mapOf("logs" to logger.entries())
clearRecurringAlarmDebugLog -> Boolean
```

Use `Dispatchers.IO` for repository calls and return `RECURRING_ALARM_ERROR` for exceptions.

- [ ] **Step 5: Wire repository, activity, and manifest**

Add to `ExpenseRepository`:

```kotlin
suspend fun nextRecurringTriggerMillis(targetMillis: Long = System.currentTimeMillis()): Long? {
    seedIfEmpty()
    ensureRecurringGhostsForActivePeriod(targetMillis)
    return recurringGhosts.pending()
        .filter { !it.isActivated }
        .map { it.triggerMillis }
        .filter { it >= targetMillis }
        .minOrNull()
}
```

In `MainActivity`, remove `RecurringTransactionScheduler.schedule(this)` and attach:

```kotlin
RecurringAlarmMethodChannel(this, scope).attach(
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exptv2/recurring_alarm"),
)
RecurringAlarmScheduler(this).sync()
```

In `AndroidManifest.xml`, add:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

and receiver declarations for `.expense.recurring.RecurringAlarmReceiver` and `.expense.recurring.RecurringBootReceiver`.

- [ ] **Step 6: Run native tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && ./gradlew :app:testDebugUnitTest'
```

Expected: `BUILD SUCCESSFUL`.

Commit:

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt android/app/src/main/kotlin/com/exptv2/app/expense android/app/src/test/kotlin/com/exptv2/app/expense
git commit -m "feat: schedule recurring ghosts with exact alarms"
```

---

### Task 3: Dart Alarm Service And Floating Debug Date

**Files:**
- Create: `lib/features/transactions/services/recurring_alarm_scheduler_service.dart`
- Create: `lib/features/transactions/widgets/debug_date/debug_date_floating_button.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/recurring_alarm_scheduler_service_test.dart`
- Test: `test/transactions/debug_date_floating_button_test.dart`

- [ ] **Step 1: Write MethodChannel tests**

Create tests that mock `MethodChannel('test/recurring_alarm')` and assert:

```dart
final service = RecurringAlarmSchedulerService(channel: channel);
final state = await service.loadDebugState();
expect(state.usingOverride, isFalse);
expect(state.logs.single, contains('sync start'));

final result = await service.setDebugDateOverride(DateTime(2026, 6, 1));
expect(result.processedCount, 2);
```

- [ ] **Step 2: Implement service wrapper**

Create `RecurringAlarmDebugState`, `RecurringAlarmProcessResult`, and `RecurringAlarmSchedulerService`:

```dart
class RecurringAlarmSchedulerService {
  RecurringAlarmSchedulerService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('exptv2/recurring_alarm');

  final MethodChannel _channel;

  Future<void> syncRecurringAlarms() async => _channel.invokeMethod<void>('syncRecurringAlarms');

  Future<RecurringAlarmProcessResult> processRecurringNow({DateTime? targetDate}) async {
    final map = await _channel.invokeMapMethod<dynamic, dynamic>(
      'processRecurringNow',
      {if (targetDate != null) 'targetMillis': targetDate.millisecondsSinceEpoch},
    );
    return RecurringAlarmProcessResult.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmProcessResult> setDebugDateOverride(DateTime date) async {
    final map = await _channel.invokeMapMethod<dynamic, dynamic>(
      'setDebugDateOverride',
      {'targetMillis': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch},
    );
    return RecurringAlarmProcessResult.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmDebugState> clearDebugDateOverride() async {
    final map = await _channel.invokeMapMethod<dynamic, dynamic>('clearDebugDateOverride');
    return RecurringAlarmDebugState.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmDebugState> loadDebugState() async {
    final map = await _channel.invokeMapMethod<dynamic, dynamic>('loadRecurringAlarmDebugState');
    return RecurringAlarmDebugState.fromMap(map ?? <dynamic, dynamic>{});
  }
}
```

- [ ] **Step 3: Implement floating date button**

Create `DebugDateFloatingButton` with keys:

```dart
const ValueKey('debug-date-floating-button')
const ValueKey('debug-date-panel')
const ValueKey('debug-date-prev-day')
const ValueKey('debug-date-next-day')
const ValueKey('debug-date-reset')
```

The widget loads state in `initState`, toggles a compact panel, calls `setDebugDateOverride` for previous/next day, calls `clearDebugDateOverride` for reset, logs processed count to `DebugConsole`, and calls `onRecurringChanged` after every native processing call.

- [ ] **Step 4: Integrate shell lifecycle**

Add to `TransactionStore`:

```dart
Future<void> refreshAfterRecurringProcessing() async {
  await _reload();
  DebugConsole.log('[RecurringAlarm] store refreshed after processing');
}
```

Keep pending ghosts hidden in `SummaryWindow.allTime`, visible in monthly/yearly windows, and excluded from `activeSummary`, which continues to use `visibleTransactions` only.

Make `_ExptShellState` a `WidgetsBindingObserver`, register and remove the observer, create `RecurringAlarmSchedulerService`, call `syncRecurringAlarms()` in `initState`, and process on resume:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state != AppLifecycleState.resumed) return;
  _recurringAlarmScheduler.processRecurringNow().then((_) {
    if (mounted) _transactionStore.refreshAfterRecurringProcessing();
  });
}
```

Render `DebugDateFloatingButton` above the existing `DebugFloatingButton`.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/recurring_alarm_scheduler_service_test.dart test/transactions/debug_date_floating_button_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/services lib/features/transactions/widgets/debug_date lib/features/shell/expt_shell.dart lib/features/transactions/state/transaction_store.dart test/transactions/recurring_alarm_scheduler_service_test.dart test/transactions/debug_date_floating_button_test.dart
git commit -m "feat: add recurring debug date control"
```

---

### Task 4: Calendar Bottom Tab And Month Detail

**Files:**
- Create: `lib/features/calendar/calendar_page.dart`
- Create: `lib/features/calendar/calendar_year_view.dart`
- Create: `lib/features/calendar/calendar_month_detail_view.dart`
- Create: `lib/features/calendar/calendar_month_stats.dart`
- Modify: `lib/features/shell/app_tab.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/shell/widgets/expt_bottom_nav.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart`
- Test: `test/transactions/calendar_tab_test.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing tests**

Add `calendar_tab_test.dart` for `CalendarMonthStats.fromTransactions`, update `widget_test.dart` to expect `Naptar` and not `Groceries`, and update `calendar_menu_widgets_test.dart` to assert `header-calendar-button` is gone.

- [ ] **Step 2: Implement `CalendarMonthStats`**

Create:

```dart
class CalendarMonthStats {
  const CalendarMonthStats({required this.income, required this.expense, required this.balance, required this.transactionCount});

  final double income;
  final double expense;
  final double balance;
  final int transactionCount;

  factory CalendarMonthStats.fromTransactions({required int year, required int month, required List<TransactionRecord> transactions}) {
    var income = 0.0;
    var expense = 0.0;
    var count = 0;
    final prefix = '${year.toString().padLeft(4, '0')}.${month.toString().padLeft(2, '0')}.';
    for (final record in transactions) {
      if (!record.normalizedDate.startsWith(prefix)) continue;
      count += 1;
      if (record.amount >= 0) income += record.amount.abs();
      if (record.amount < 0) expense += record.amount.abs();
    }
    return CalendarMonthStats(income: income, expense: expense, balance: income - expense, transactionCount: count);
  }
}
```

- [ ] **Step 3: Implement calendar page views**

`CalendarPage` owns `_year` and `_selectedMonth`. Annual view renders `CalendarYearView`; selected-month view renders `CalendarMonthDetailView`.

`CalendarYearView` uses existing `CalendarRenderBuilder.buildYear`, `CalendarModeSelector`, and `CalendarCanvas`. Horizontal swipe velocity `< -200` increments year; `> 200` decrements year.

`CalendarMonthDetailView` shows a back arrow with key `calendar-month-detail-back`, a single enlarged month canvas, and stat rows for income, expense, balance, and transaction count. Horizontal swipe changes adjacent month. The calendar page starts at the screen top and its scrollable content leaves bottom padding for the bottom nav height.

- [ ] **Step 4: Replace Groceries with Calendar**

In `AppTab`, replace `groceries` with `calendar`, id `calendar`, label `Naptar`, icon `Icons.calendar_month_outlined`.

In `ExptShell`, replace blank Groceries page with:

```dart
ListenableBuilder(
  listenable: _transactionStore,
  builder: (context, _) => CalendarPage(
    transactions: _transactionStore.transactions,
    categories: _transactionStore.categories,
  ),
),
```

Remove `_calendarOpen`, `_openCalendarMenu`, `_closeCalendarMenu`, the header calendar callback, and `CalendarMenuOverlay` from `TransactionHomePage`.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_tab_test.dart test/transactions/calendar_menu_widgets_test.dart test/widget_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/calendar lib/features/shell lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/calendar_menu test/transactions/calendar_tab_test.dart test/transactions/calendar_menu_widgets_test.dart test/widget_test.dart
git commit -m "feat: move calendar to bottom tab"
```

---

### Task 5: Header, Magnet Strip, And Category Inline Modal

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Test: `test/transactions/header_card_test.dart`
- Test: `test/transactions/magnet_strip_test.dart`
- Test: `test/transactions/category_menu_test.dart`

- [ ] **Step 1: Write failing tests**

Update `header_card_test.dart` to remove the calendar callback and expect no `header-calendar-button`. Change magnet strip expected height to `105`. Add a category test that opens the header category button and verifies `category-menu-overlay` exists while `slide-up-menu-card` does not.

- [ ] **Step 2: Update header and magnet**

Remove `onCalendarPressed` from `TransactionHeaderCard`. Delete the calendar icon block. Keep shadow alpha at `0.15` even when fast info is visible.

Set:

```dart
static const magnetHeight = 105.0;
static const defaultHeight = 105.0;
```

In `MagnetStripPainter`, draw full-width base and value sections with `drawRect` so the strip reaches the screen edges without pill ends. In magnetcard mode, use:

```dart
final halfHeight = math.max(8.0, size.height * 0.22);
```

- [ ] **Step 3: Add spring snapback**

Make `_TransactionHomePageState` use `SingleTickerProviderStateMixin`, add an unbounded `AnimationController`, and replace drag end with:

```dart
_headerPullController.value = _fastInfoExtent;
_headerPullController.animateWith(
  SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 150, damping: 10),
    _fastInfoExtent,
    0,
    details.primaryVelocity ?? 0,
  ),
);
```

- [ ] **Step 4: Convert category picker to inline modal**

Replace the `SlideUpMenuCard` in `CategoryMenuOverlay` with a `Positioned` `Material`:

```dart
return Positioned(
  key: const ValueKey('category-menu-overlay'),
  top: TransactionMenuMetrics.overlayTop,
  left: 0,
  right: 0,
  bottom: AppDimensions.bottomNavHeight,
  child: Material(
    color: AppColors.white,
    elevation: 12,
    child: CategoryMenuPanel(
      key: const ValueKey('category-picker-panel'),
      activeType: store.activeType,
      categories: store.activeCategories,
      categoryTransactionCounts: store.categoryTransactionCounts,
      activeCategory: store.activeCategory,
      onSelect: onSelect,
      onModify: onModify,
      onDelete: onDelete,
      onAdd: onAdd,
      onClose: onClose,
    ),
  ),
);
```

In `TransactionHomePage`, set blocking overlay state from category editor only:

```dart
_notifyBlockingOverlay(_categoryEditorOpen);
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/header_card_test.dart test/transactions/magnet_strip_test.dart test/transactions/category_menu_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/header_card lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/category_menu/category_menu_overlay.dart test/transactions/header_card_test.dart test/transactions/magnet_strip_test.dart test/transactions/category_menu_test.dart
git commit -m "fix: align header magnet and category menu"
```

---

### Task 6: Summary, Search, And Logbox Swipe

**Files:**
- Modify: `lib/features/transactions/widgets/summary_pill.dart`
- Modify: `lib/features/transactions/widgets/search_pill.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that assert `SummaryPill` has no `AnimatedSwitcher`, two search capsules do not overlap the `TextField`, swipe borders fill the logbox card height, right-swipe delete stays translated while the async delete callback is unresolved, and the existing transaction name edit/reset controls still work.

- [ ] **Step 2: Make summary content instant**

Replace the `AnimatedSwitcher` in `SummaryPill` with a direct `Row`. Keep the outer `AnimatedContainer` for drag movement.

- [ ] **Step 3: Make delete callback awaitable**

Change:

```dart
typedef TransactionDeleteRequest = FutureOr<bool> Function(TransactionRecord record);
```

Use this type in `TransactionLogBox`, `TransactionLogList`, `TransactionHomePage`, and `ExptShell`.

Make `_confirmDeleteTransaction` return `Future<bool>`: `false` on cancel, `false` on failed delete, `true` after successful delete. Keep the existing merchant-name editor and reset button connected to `renameTransactionsByMerchant` and `resetTransactionNamesByMerchant`.

- [ ] **Step 4: Pin delete swipe and fill border**

In `_TransactionLogBoxState`, add `_deletePending`. When `_dragDx > 80`, set `_visualDx = 36`, await `onDeleteRequested`, and only reset on `false`.

Replace `_SwipeBorder` with `Positioned.fill`:

```dart
return Positioned.fill(
  child: IgnorePointer(
    child: Opacity(
      key: borderKey,
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color, width: 3),
        ),
      ),
    ),
  ),
);
```

- [ ] **Step 5: Keep search capsules visible**

Keep every `TextField` border set to `InputBorder.none`. Set capsule area to `Flexible(flex: 5)` and text input to `Expanded(flex: 3)` so merchant and category capsules remain visible.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_widgets_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/summary_pill.dart lib/features/transactions/widgets/search_pill.dart lib/features/transactions/widgets/transaction_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/transaction_home_page.dart lib/features/shell/expt_shell.dart test/transactions/transaction_widgets_test.dart
git commit -m "fix: refine summary search and logbox gestures"
```

---

### Task 7: Notification Card Triggers And Budget Alerts

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/BudgetNotificationCardFactory.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/BudgetNotificationCardFactoryTest.kt`
- Test: `test/notifications/expense_notification_card_test.dart`
- Test: `test/notifications/notification_store_test.dart`

- [ ] **Step 1: Write budget factory test**

Create a JUnit test that builds a monthly expense category `CategoryLimitEntity`, calls `BudgetNotificationCardFactory.limitCrossed`, and asserts:

```kotlin
assertEquals("spending_limit", card.type)
assertEquals("Food", card.categoryName)
assertEquals(12500.0, card.amount!!, 0.0)
assertEquals("2026-05", card.triggerDate)
assertFalse(card.isRead)
assertTrue(card.isActive)
```

- [ ] **Step 2: Implement budget factory**

Create `BudgetNotificationCardFactory.limitCrossed` returning a `NotificationCardEntity` with type `spending_limit` for category targets and `monthly_budget_alert` for overview targets.

- [ ] **Step 3: Add duplicate lookup queries**

Add to `NotificationCardDao`:

```kotlin
@Query("SELECT COUNT(*) FROM notification_cards WHERE isActive = 1 AND type = :type AND categoryId IS :categoryId AND triggerDate = :periodKey")
suspend fun activeCountForBudget(type: String, categoryId: Int?, periodKey: String): Int

@Query("SELECT COUNT(*) FROM notification_cards WHERE isActive = 1 AND type = 'recurring_transaction_alert' AND recurringTransactionId = :recurringId AND triggerDate = :triggerDate")
suspend fun activeCountForRecurring(recurringId: Int, triggerDate: String): Int
```

Use `activeCountForRecurring` before inserting recurring activation cards.

- [ ] **Step 4: Evaluate limits after mutations**

In `ExpenseRepository`, add `evaluateBudgetNotifications()` that loads active alert limits, filters real expense transactions by `monthly`, `yearly`, or `sum`, calculates spent amount, skips limits below threshold, checks `activeCountForBudget`, and inserts a card from `BudgetNotificationCardFactory.limitCrossed`.

Call this method after add/update/delete transaction and after `upsertCategoryLimit`.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && ./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.BudgetNotificationCardFactoryTest" && /home/flutteruser/flutter/bin/flutter test test/notifications/expense_notification_card_test.dart test/notifications/notification_store_test.dart'
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/BudgetNotificationCardFactory.kt android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/test/kotlin/com/exptv2/app/expense/BudgetNotificationCardFactoryTest.kt test/notifications
git commit -m "feat: create notification cards for budget alerts"
```

---

### Task 8: Full Verification, Push, And Online Build

**Files:**
- Modify: only files changed by Tasks 1-7.

- [ ] **Step 1: Run native tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && ./gradlew :app:testDebugUnitTest'
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 2: Run Flutter tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart test/transactions test/notifications test/settings'
```

Expected: all tests pass.

- [ ] **Step 3: Build APK locally once**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter build apk --debug'
```

Expected: APK written under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Push and watch online build**

Run:

```bash
git status --short
git push origin main
gh run list --repo elizerpist/exptv2 --limit 5
```

Expected: clean worktree before push, push succeeds, newest GitHub Actions run belongs to the pushed commit.

If the run is active, run:

```bash
gh run watch --repo elizerpist/exptv2
```

Expected: workflow completes successfully and APK artifact is available from the workflow page.
