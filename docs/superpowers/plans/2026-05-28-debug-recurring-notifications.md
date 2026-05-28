# Debug Recurring Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global on-screen debug console, monthly recurring ghost projection, transaction name bulk rename/reset, doubled magnet strip height, and persistent notification cards.

**Architecture:** Flutter owns all visible UI and debug overlay state; Kotlin/Room owns persistent expense data, recurring activation, notification cards, and bulk transaction mutation. MethodChannel remains the API boundary, with small Dart repositories/stores translating native rows into widgets.

**Tech Stack:** Flutter/Dart, Material widgets, MethodChannel, Kotlin, Room, WorkManager, JUnit, Flutter widget tests.

---

## Scope Check

The approved spec spans several related subsystems. Keep this as one coordinated plan because notification cards, recurring activation, debug logs, and transaction reloads all pass through the same Room database and `NativeBridge`. Each task below still produces a narrow, testable commit.

## File Structure

Create these Dart files:

- `lib/core/debug/debug_console.dart`: singleton in-memory log buffer and debug dialog.
- `lib/core/debug/debug_floating_button.dart`: global floating button that opens the dialog.
- `lib/features/notifications/models/expense_notification_card.dart`: persisted notification card model.
- `lib/features/notifications/data/notification_repository.dart`: Dart wrapper around notification MethodChannel APIs.
- `lib/features/notifications/state/notification_store.dart`: month selection, load/read/delete/clear state.
- `lib/features/notifications/notifications_page.dart`: notifications tab screen.
- `lib/features/notifications/widgets/notification_month_header.dart`: swipeable month header and clear action.
- `lib/features/notifications/widgets/notification_log_box.dart`: expt0926-style notification card.

Modify these Dart files:

- `lib/features/shell/expt_shell.dart`: render `NotificationsPage` and the global debug button.
- `lib/services/native_bridge.dart`: add notification, rename/reset, and recurring ghost period APIs.
- `lib/features/transactions/data/transaction_repository.dart`: expose ensure ghost and rename/reset calls.
- `lib/features/transactions/state/transaction_store.dart`: trigger monthly ghost projection, hide ghosts outside monthly mode, bulk rename/reset, debug logging.
- `lib/features/transactions/widgets/transaction_log_box.dart`: add name tap/edit/reset affordance and color rules.
- `lib/features/transactions/widgets/transaction_log_list.dart`: pass name callbacks into logboxes.
- `lib/features/transactions/transaction_home_page.dart`: connect name edit/reset callbacks.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: double magnet strip height.
- `lib/features/settings/widgets/options/theme_options_panel.dart`: double magnet preview height.

Create these Kotlin files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardEntity.kt`: Room row plus `toMap()`.
- `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt`: list, insert, read, delete, clear queries.

Modify these Kotlin files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`: add `NotificationCardEntity`, DAO accessor, version 5, migration 4->5.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`: add bulk `userAssignedName` update/reset counts.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionDao.kt`: add period-specific pending queries.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`: add deterministic planning for an arbitrary viewed month.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: notification APIs, rename/reset APIs, period ghost ensure, notification creation on activation.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`: expose new MethodChannel methods.

Create or modify these tests:

- `test/core/debug_console_test.dart`
- `test/core/debug_floating_button_test.dart`
- `test/notifications/expense_notification_card_test.dart`
- `test/notifications/notification_store_test.dart`
- `test/notifications/notification_widgets_test.dart`
- `test/transactions/native_bridge_expense_test.dart`
- `test/transactions/recurring_ghost_log_test.dart`
- `test/transactions/transaction_store_test.dart`
- `test/transactions/transaction_widgets_test.dart`
- `test/transactions/magnet_strip_test.dart`
- `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt`
- `android/app/src/test/kotlin/com/exptv2/app/expense/NotificationCardEntityTest.kt`

## Task 1: Debug Console And Global Floating Button

**Files:**
- Create: `lib/core/debug/debug_console.dart`
- Create: `lib/core/debug/debug_floating_button.dart`
- Create: `test/core/debug_console_test.dart`
- Create: `test/core/debug_floating_button_test.dart`
- Modify: `lib/features/shell/expt_shell.dart`

- [ ] **Step 1: Write the failing debug console tests**

Create `test/core/debug_console_test.dart`:

```dart
import 'package:exptv2/core/debug/debug_console.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DebugConsole.clear);

  test('records timestamped entries and notifies listeners', () {
    var notifications = 0;
    void listener() => notifications += 1;
    DebugConsole.notifier.addListener(listener);
    addTearDown(() => DebugConsole.notifier.removeListener(listener));

    DebugConsole.log('recurring ghost created');

    expect(DebugConsole.entries, hasLength(1));
    expect(DebugConsole.entries.single, contains('recurring ghost created'));
    expect(DebugConsole.entries.single, matches(r'^\[\d{2}:\d{2}:\d{2}\.\d{2}\] '));
    expect(notifications, 1);
  });

  test('clear removes entries and increments notifier', () {
    DebugConsole.log('one');
    DebugConsole.clear();

    expect(DebugConsole.entries, isEmpty);
    expect(DebugConsole.allText, '');
  });

  test('keeps only the newest max entries', () {
    for (var i = 0; i < 520; i += 1) {
      DebugConsole.log('row $i');
    }

    expect(DebugConsole.entries, hasLength(500));
    expect(DebugConsole.entries.first, contains('row 20'));
    expect(DebugConsole.entries.last, contains('row 519'));
  });
}
```

Create `test/core/debug_floating_button_test.dart`:

```dart
import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/debug/debug_floating_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DebugConsole.clear);

  testWidgets('floating button opens debug console dialog', (tester) async {
    DebugConsole.log('bootstrap finished');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(find.text('Debug Console'), findsOneWidget);
    expect(find.textContaining('bootstrap finished'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/core/debug_console_test.dart test/core/debug_floating_button_test.dart'
```

Expected: compile failure because `lib/core/debug/debug_console.dart` and `DebugFloatingButton` do not exist.

- [ ] **Step 3: Implement `DebugConsole` and `DebugConsoleDialog`**

Create `lib/core/debug/debug_console.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugConsole {
  DebugConsole._();

  static const _maxEntries = 500;
  static final List<String> _entries = <String>[];
  static final ValueNotifier<int> _version = ValueNotifier<int>(0);

  static void log(String message) {
    final now = DateTime.now();
    final stamp = '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond ~/ 10).toString().padLeft(2, '0')}]';
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add('$stamp $message');
    _version.value += 1;
  }

  static void clear() {
    _entries.clear();
    _version.value += 1;
  }

  static List<String> get entries => List.unmodifiable(_entries);
  static String get allText => _entries.join('\n');
  static ValueNotifier<int> get notifier => _version;
}

class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({super.key});

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller.text = DebugConsole.allText;
    DebugConsole.notifier.addListener(_refresh);
  }

  @override
  void dispose() {
    DebugConsole.notifier.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final text = DebugConsole.allText;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  Future<void> _copyAll() async {
    if (_controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final count = DebugConsole.entries.length;
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.terminal, size: 16, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 8),
                  const Text('Debug Console', style: TextStyle(color: Color(0xFFCDD6F4), fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('($count)', style: const TextStyle(color: Color(0xFF6C7086), fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('debug-console-copy'),
                    onPressed: count == 0 ? null : _copyAll,
                    icon: Icon(_copied ? Icons.check : Icons.copy_outlined, size: 16),
                    color: _copied ? const Color(0xFF22C55E) : const Color(0xFF89B4FA),
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-clear'),
                    onPressed: count == 0 ? null : DebugConsole.clear,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: const Color(0xFFEF4444),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF313244)),
            Flexible(
              child: count == 0
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Még nincs log.', style: TextStyle(color: Color(0xFF94A3B8))),
                    )
                  : TextField(
                      controller: _controller,
                      readOnly: true,
                      maxLines: null,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.45, color: Color(0xFFCDD6F4)),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `DebugFloatingButton`**

Create `lib/core/debug/debug_floating_button.dart`:

```dart
import 'package:flutter/material.dart';

import 'debug_console.dart';

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;
    return Positioned(
      key: const ValueKey('debug-floating-button-position'),
      top: top,
      right: 14,
      child: SafeArea(
        child: Material(
          color: const Color(0xFF1E293B),
          shape: const CircleBorder(),
          elevation: 8,
          child: IconButton(
            key: const ValueKey('debug-floating-button'),
            tooltip: 'Debug log',
            icon: const Icon(Icons.terminal, size: 18, color: Color(0xFF06B6D4)),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const DebugConsoleDialog(),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Add the global button to `ExptShell`**

Modify `lib/features/shell/expt_shell.dart`:

```dart
import '../../core/debug/debug_console.dart';
import '../../core/debug/debug_floating_button.dart';
```

In `_ExptShellState.initState()` add:

```dart
DebugConsole.log('[Shell] start');
```

At the end of the `Stack(children: [...])`, after `AddTransactionSheet`, add:

```dart
const DebugFloatingButton(),
```

- [ ] **Step 6: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/core/debug_console_test.dart test/core/debug_floating_button_test.dart'
```

Expected: all tests pass.

Commit:

```bash
git add lib/core/debug lib/features/shell/expt_shell.dart test/core/debug_console_test.dart test/core/debug_floating_button_test.dart
git commit -m "feat: add global debug console"
```

## Task 2: Persistent Notification Card Backend And Bridge

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt`
- Create: `android/app/src/test/kotlin/com/exptv2/app/expense/NotificationCardEntityTest.kt`
- Create: `lib/features/notifications/models/expense_notification_card.dart`
- Create: `test/notifications/expense_notification_card_test.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `test/transactions/native_bridge_expense_test.dart`

- [ ] **Step 1: Write failing Dart notification model and bridge tests**

Create `test/notifications/expense_notification_card_test.dart`:

```dart
import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses recurring notification card from native map', () {
    final card = ExpenseNotificationCard.fromMap({
      'id': 7,
      'type': 'recurring_transaction_alert',
      'title': 'Ismétlődő tranzakció',
      'message': 'Rent automatikusan hozzáadva',
      'timestamp': 1778803200000,
      'isRead': false,
      'isActive': true,
      'priority': 'medium',
      'categoryId': 6,
      'categoryName': 'Lakhatás',
      'categoryColor': '#dc2626',
      'categoryIconSlot': 2,
      'recurringTransactionId': 9,
      'transactionId': 26051501,
      'amount': 120000,
      'triggerDate': '2026-05-15T00:00:00.000',
      'nextDueDate': '2026-06-15T00:00:00.000',
      'createdAt': 1778803200000,
      'updatedAt': 1778803200000,
    });

    expect(card.type, ExpenseNotificationType.recurringTransactionAlert);
    expect(card.monthKey, '2026-05');
    expect(card.categoryName, 'Lakhatás');
    expect(card.amount, 120000);
  });
}
```

Append to `test/transactions/native_bridge_expense_test.dart`:

```dart
test('loads, reads, and deletes notification cards through native bridge', () async {
  final invoked = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        invoked.add(call.method);
        if (call.method == 'expenseListNotificationCards') {
          return [
            {
              'id': 1,
              'type': 'recurring_transaction_alert',
              'title': 'Ismétlődő tranzakció',
              'message': 'Rent automatikusan hozzáadva',
              'timestamp': 1778803200000,
              'isRead': false,
              'isActive': true,
              'priority': 'medium',
              'categoryId': 6,
              'categoryName': 'Q',
              'categoryColor': '#dc2626',
              'categoryIconSlot': 2,
              'recurringTransactionId': 9,
              'transactionId': 26051501,
              'amount': 500,
              'triggerDate': '2026-05-15T00:00:00.000',
              'nextDueDate': '2026-06-15T00:00:00.000',
              'createdAt': 1778803200000,
              'updatedAt': 1778803200000,
            },
          ];
        }
        return true;
      });

  final cards = await bridge.expenseListNotificationCards();
  final read = await bridge.expenseMarkNotificationCardRead(1);
  final deleted = await bridge.expenseDeleteNotificationCard(1);

  expect(cards.single.title, 'Ismétlődő tranzakció');
  expect(read, isTrue);
  expect(deleted, isTrue);
  expect(invoked, [
    'expenseListNotificationCards',
    'expenseMarkNotificationCardRead',
    'expenseDeleteNotificationCard',
  ]);
});
```

- [ ] **Step 2: Run failing Dart tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/expense_notification_card_test.dart test/transactions/native_bridge_expense_test.dart'
```

Expected: compile failures for missing `ExpenseNotificationCard` and missing `NativeBridge` notification methods.

- [ ] **Step 3: Add Dart notification model and bridge methods**

Create `lib/features/notifications/models/expense_notification_card.dart`:

```dart
enum ExpenseNotificationType {
  recurringTransactionAlert('recurring_transaction_alert'),
  budgetAlert('budget_alert'),
  spendingLimit('spending_limit'),
  monthlyBudgetAlert('monthly_budget_alert'),
  system('system');

  const ExpenseNotificationType(this.nativeValue);
  final String nativeValue;

  static ExpenseNotificationType fromNative(String value) {
    return ExpenseNotificationType.values.firstWhere(
      (type) => type.nativeValue == value,
      orElse: () => ExpenseNotificationType.system,
    );
  }
}

class ExpenseNotificationCard {
  const ExpenseNotificationCard({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.isActive,
    required this.priority,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIconSlot,
    this.recurringTransactionId,
    this.transactionId,
    this.amount,
    this.triggerDate,
    this.nextDueDate,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final ExpenseNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isActive;
  final String priority;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final int? categoryIconSlot;
  final int? recurringTransactionId;
  final int? transactionId;
  final double? amount;
  final String? triggerDate;
  final String? nextDueDate;
  final int? createdAt;
  final int? updatedAt;

  String get monthKey => '${timestamp.year.toString().padLeft(4, '0')}-${timestamp.month.toString().padLeft(2, '0')}';

  factory ExpenseNotificationCard.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseNotificationCard(
      id: _int(map['id']),
      type: ExpenseNotificationType.fromNative(map['type']?.toString() ?? 'system'),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(_int(map['timestamp'])),
      isRead: map['isRead'] == true,
      isActive: map['isActive'] != false,
      priority: map['priority']?.toString() ?? 'normal',
      categoryId: _nullableInt(map['categoryId']),
      categoryName: map['categoryName']?.toString(),
      categoryColor: map['categoryColor']?.toString(),
      categoryIconSlot: _nullableInt(map['categoryIconSlot']),
      recurringTransactionId: _nullableInt(map['recurringTransactionId']),
      transactionId: _nullableInt(map['transactionId']),
      amount: _nullableDouble(map['amount']),
      triggerDate: map['triggerDate']?.toString(),
      nextDueDate: map['nextDueDate']?.toString(),
      createdAt: _nullableInt(map['createdAt']),
      updatedAt: _nullableInt(map['updatedAt']),
    );
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _int(value);
double? _nullableDouble(Object? value) => value == null ? null : (value is num ? value.toDouble() : double.parse(value.toString()));
```

Modify `lib/services/native_bridge.dart` imports:

```dart
import '../features/notifications/models/expense_notification_card.dart';
```

Add methods to `NativeBridge`:

```dart
Future<List<ExpenseNotificationCard>> expenseListNotificationCards() async {
  final rows = await _methodChannel.invokeListMethod<dynamic>('expenseListNotificationCards');
  return (rows ?? <dynamic>[])
      .cast<Map<dynamic, dynamic>>()
      .map(ExpenseNotificationCard.fromMap)
      .toList();
}

Future<bool> expenseMarkNotificationCardRead(int id) async {
  final updated = await _methodChannel.invokeMethod<bool>(
    'expenseMarkNotificationCardRead',
    {'id': id},
  );
  return updated ?? false;
}

Future<bool> expenseDeleteNotificationCard(int id) async {
  final deleted = await _methodChannel.invokeMethod<bool>(
    'expenseDeleteNotificationCard',
    {'id': id},
  );
  return deleted ?? false;
}

Future<int> expenseClearNotificationCards({String? monthKey}) async {
  final count = await _methodChannel.invokeMethod<int>(
    'expenseClearNotificationCards',
    {'monthKey': monthKey},
  );
  return count ?? 0;
}
```

- [ ] **Step 4: Add Kotlin entity, DAO, migration, repository, and channel**

Create `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "notification_cards",
    indices = [
        Index("timestamp"),
        Index("type"),
        Index("isRead"),
        Index("isActive"),
    ],
)
data class NotificationCardEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val type: String,
    val title: String,
    val message: String,
    val timestamp: Long,
    val isRead: Boolean,
    val isActive: Boolean,
    val priority: String,
    val categoryId: Int?,
    val categoryName: String?,
    val categoryColor: String?,
    val categoryIconSlot: Int?,
    val recurringTransactionId: Int?,
    val transactionId: Int?,
    val amount: Double?,
    val triggerDate: String?,
    val nextDueDate: String?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "type" to type,
        "title" to title,
        "message" to message,
        "timestamp" to timestamp,
        "isRead" to isRead,
        "isActive" to isActive,
        "priority" to priority,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "recurringTransactionId" to recurringTransactionId,
        "transactionId" to transactionId,
        "amount" to amount,
        "triggerDate" to triggerDate,
        "nextDueDate" to nextDueDate,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
```

Create `android/app/src/main/kotlin/com/exptv2/app/expense/NotificationCardDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface NotificationCardDao {
    @Query("SELECT * FROM notification_cards WHERE isActive = 1 ORDER BY timestamp DESC, id DESC")
    suspend fun active(): List<NotificationCardEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: NotificationCardEntity): Long

    @Query("UPDATE notification_cards SET isRead = 1, updatedAt = :updatedAt WHERE id = :id AND isActive = 1")
    suspend fun markRead(id: Int, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt WHERE id = :id")
    suspend fun delete(id: Int, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt WHERE strftime('%Y-%m', timestamp / 1000, 'unixepoch') = :monthKey")
    suspend fun clearMonth(monthKey: String, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt")
    suspend fun clearAll(updatedAt: Long): Int
}
```

Modify `ExpenseTrackerDatabase.kt`:

```kotlin
@Database(
    entities = [
        TransactionCategoryEntity::class,
        ExpenseTransactionEntity::class,
        CategoryLimitEntity::class,
        RecurringTransactionEntity::class,
        RecurringGhostTransactionEntity::class,
        NotificationCardEntity::class,
    ],
    version = 5,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {
    abstract fun notificationCards(): NotificationCardDao
```

Add migration:

```kotlin
private val MIGRATION_4_5 = object : Migration(4, 5) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS notification_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                type TEXT NOT NULL,
                title TEXT NOT NULL,
                message TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                isRead INTEGER NOT NULL,
                isActive INTEGER NOT NULL,
                priority TEXT NOT NULL,
                categoryId INTEGER,
                categoryName TEXT,
                categoryColor TEXT,
                categoryIconSlot INTEGER,
                recurringTransactionId INTEGER,
                transactionId INTEGER,
                amount REAL,
                triggerDate TEXT,
                nextDueDate TEXT,
                createdAt INTEGER NOT NULL,
                updatedAt INTEGER NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_timestamp ON notification_cards(timestamp)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_type ON notification_cards(type)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_isRead ON notification_cards(isRead)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_isActive ON notification_cards(isActive)")
    }
}
```

Include it in `.addMigrations(...)`:

```kotlin
.addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5)
```

Modify `ExpenseRepository.kt` fields:

```kotlin
private val notificationCards = db.notificationCards()
```

Add methods:

```kotlin
suspend fun listNotificationCards(): List<Map<String, Any?>> {
    seedIfEmpty()
    return notificationCards.active().map { it.toMap() }
}

suspend fun markNotificationCardRead(id: Int): Boolean {
    seedIfEmpty()
    return notificationCards.markRead(id, System.currentTimeMillis()) > 0
}

suspend fun deleteNotificationCard(id: Int): Boolean {
    seedIfEmpty()
    return notificationCards.delete(id, System.currentTimeMillis()) > 0
}

suspend fun clearNotificationCards(args: Map<*, *>): Int {
    seedIfEmpty()
    val now = System.currentTimeMillis()
    val monthKey = args["monthKey"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
    return if (monthKey == null) notificationCards.clearAll(now) else notificationCards.clearMonth(monthKey, now)
}
```

Modify `ExpenseMethodChannel.kt` with cases:

```kotlin
"expenseListNotificationCards" -> scope.launchResult(result) { repository.listNotificationCards() }
"expenseMarkNotificationCardRead" -> scope.launchResult(result) {
    val id = (call.argumentsMap()["id"] as? Number)?.toInt()
        ?: throw ExpenseValidationException("INVALID_NOTIFICATION_ID", "Notification id is required")
    repository.markNotificationCardRead(id)
}
"expenseDeleteNotificationCard" -> scope.launchResult(result) {
    val id = (call.argumentsMap()["id"] as? Number)?.toInt()
        ?: throw ExpenseValidationException("INVALID_NOTIFICATION_ID", "Notification id is required")
    repository.deleteNotificationCard(id)
}
"expenseClearNotificationCards" -> scope.launchResult(result) {
    repository.clearNotificationCards(call.argumentsMap())
}
```

- [ ] **Step 5: Add Kotlin entity test**

Create `android/app/src/test/kotlin/com/exptv2/app/expense/NotificationCardEntityTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class NotificationCardEntityTest {
    @Test
    fun mapsRecurringNotificationCardToFlutterPayload() {
        val row = NotificationCardEntity(
            id = 3,
            type = "recurring_transaction_alert",
            title = "Ismétlődő tranzakció",
            message = "Rent automatikusan hozzáadva",
            timestamp = 1778803200000,
            isRead = false,
            isActive = true,
            priority = "medium",
            categoryId = 6,
            categoryName = "Lakhatás",
            categoryColor = "#dc2626",
            categoryIconSlot = 2,
            recurringTransactionId = 9,
            transactionId = 26051501,
            amount = 120000.0,
            triggerDate = "2026-05-15T00:00:00.000",
            nextDueDate = "2026-06-15T00:00:00.000",
            createdAt = 1778803200000,
            updatedAt = 1778803200000,
        )

        val map = row.toMap()

        assertEquals("recurring_transaction_alert", map["type"])
        assertEquals("Lakhatás", map["categoryName"])
        assertEquals(120000.0, map["amount"])
        assertFalse(map["isRead"] as Boolean)
    }
}
```

- [ ] **Step 6: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/expense_notification_card_test.dart test/transactions/native_bridge_expense_test.dart'
```

Run Kotlin unit test in GitHub or a normal Android environment:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.NotificationCardEntityTest'
```

Expected: Dart tests pass. Kotlin entity test passes in a normal Android Gradle environment; Termux/proot can fail before test execution at AAPT2, which is a known local environment issue.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense android/app/src/test/kotlin/com/exptv2/app/expense/NotificationCardEntityTest.kt lib/features/notifications/models lib/services/native_bridge.dart test/notifications/expense_notification_card_test.dart test/transactions/native_bridge_expense_test.dart
git commit -m "feat: add notification card persistence bridge"
```

## Task 3: Notifications Tab UI

**Files:**
- Create: `lib/features/notifications/data/notification_repository.dart`
- Create: `lib/features/notifications/state/notification_store.dart`
- Create: `lib/features/notifications/notifications_page.dart`
- Create: `lib/features/notifications/widgets/notification_month_header.dart`
- Create: `lib/features/notifications/widgets/notification_log_box.dart`
- Create: `test/notifications/notification_store_test.dart`
- Create: `test/notifications/notification_widgets_test.dart`
- Modify: `lib/features/shell/expt_shell.dart`

- [ ] **Step 1: Write failing notification store and widget tests**

Create `test/notifications/notification_store_test.dart`:

```dart
import 'package:exptv2/features/notifications/data/notification_repository.dart';
import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:exptv2/features/notifications/state/notification_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store filters active cards by selected month and groups by date', () async {
    final store = NotificationStore(
      FakeNotificationRepository(),
      clock: () => DateTime(2026, 5, 15),
    );

    await store.start();

    expect(store.selectedMonthKey, '2026-05');
    expect(store.visibleCards, hasLength(2));
    expect(store.groupedCards.keys, ['2026.05.15', '2026.05.10']);
  });

  test('mark read and delete reload card state', () async {
    final repository = FakeNotificationRepository();
    final store = NotificationStore(repository);
    await store.start();

    await store.markRead(1);
    await store.deleteCard(2);

    expect(repository.readIds, [1]);
    expect(repository.deletedIds, [2]);
  });
}

class FakeNotificationRepository implements NotificationRepositoryContract {
  final readIds = <int>[];
  final deletedIds = <int>[];

  @override
  Future<List<ExpenseNotificationCard>> listCards() async => [
    card(1, 15),
    card(2, 10),
    card(3, 1, month: 4),
  ];

  @override
  Future<bool> markRead(int id) async {
    readIds.add(id);
    return true;
  }

  @override
  Future<bool> deleteCard(int id) async {
    deletedIds.add(id);
    return true;
  }

  @override
  Future<int> clearCards({String? monthKey}) async => 2;
}

ExpenseNotificationCard card(int id, int day, {int month = 5}) => ExpenseNotificationCard.fromMap({
  'id': id,
  'type': 'recurring_transaction_alert',
  'title': 'Ismétlődő tranzakció',
  'message': 'Rent',
  'timestamp': DateTime(2026, month, day, 8).millisecondsSinceEpoch,
  'isRead': false,
  'isActive': true,
  'priority': 'medium',
});
```

Create `test/notifications/notification_widgets_test.dart`:

```dart
import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:exptv2/features/notifications/widgets/notification_log_box.dart';
import 'package:exptv2/features/notifications/widgets/notification_month_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month header swipes between months', (tester) async {
    final shifts = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: NotificationMonthHeader(
        selectedMonth: DateTime(2026, 5),
        hasCards: true,
        onMonthShift: shifts.add,
        onClear: () {},
      ),
    ));

    await tester.drag(find.byKey(const ValueKey('notification-month-header')), const Offset(-90, 0));
    await tester.pumpAndSettle();

    expect(find.text('2026. Május'), findsOneWidget);
    expect(shifts, [1]);
  });

  testWidgets('notification logbox renders recurring card and swipe actions', (tester) async {
    int? readId;
    int? deleteId;
    await tester.pumpWidget(MaterialApp(
      home: NotificationLogBox(
        card: card(),
        onMarkRead: (id) => readId = id,
        onDelete: (id) => deleteId = id,
      ),
    ));

    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('notification-logbox-1')), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('notification-logbox-1')), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(readId, 1);
    expect(deleteId, 1);
  });
}

ExpenseNotificationCard card() => ExpenseNotificationCard.fromMap({
  'id': 1,
  'type': 'recurring_transaction_alert',
  'title': 'Ismétlődő tranzakció',
  'message': 'Rent',
  'timestamp': DateTime(2026, 5, 15, 8).millisecondsSinceEpoch,
  'isRead': false,
  'isActive': true,
  'priority': 'medium',
  'categoryName': 'Lakhatás',
  'categoryColor': '#dc2626',
  'amount': 120000,
});
```

- [ ] **Step 2: Run failing tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/notification_store_test.dart test/notifications/notification_widgets_test.dart'
```

Expected: compile failures for missing notification repository, store, and widgets.

- [ ] **Step 3: Implement notification repository and store**

Create `lib/features/notifications/data/notification_repository.dart`:

```dart
import '../../../services/native_bridge.dart';
import '../models/expense_notification_card.dart';

abstract class NotificationRepositoryContract {
  Future<List<ExpenseNotificationCard>> listCards();
  Future<bool> markRead(int id);
  Future<bool> deleteCard(int id);
  Future<int> clearCards({String? monthKey});
}

class NotificationRepository implements NotificationRepositoryContract {
  const NotificationRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<List<ExpenseNotificationCard>> listCards() => _bridge.expenseListNotificationCards();

  @override
  Future<bool> markRead(int id) => _bridge.expenseMarkNotificationCardRead(id);

  @override
  Future<bool> deleteCard(int id) => _bridge.expenseDeleteNotificationCard(id);

  @override
  Future<int> clearCards({String? monthKey}) => _bridge.expenseClearNotificationCards(monthKey: monthKey);
}
```

Create `lib/features/notifications/state/notification_store.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/notification_repository.dart';
import '../models/expense_notification_card.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _selectedMonth = DateTime(now.year, now.month);
  }

  final NotificationRepositoryContract _repository;
  final DateTime Function() _clock;
  late DateTime _selectedMonth;
  var _loading = false;
  String? _error;
  List<ExpenseNotificationCard> _cards = [];

  bool get loading => _loading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  String get selectedMonthKey => '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  List<ExpenseNotificationCard> get cards => List.unmodifiable(_cards);

  List<ExpenseNotificationCard> get visibleCards => _cards.where((card) => card.isActive && card.monthKey == selectedMonthKey).toList();

  Map<String, List<ExpenseNotificationCard>> get groupedCards {
    final groups = <String, List<ExpenseNotificationCard>>{};
    for (final card in visibleCards) {
      final key = '${card.timestamp.year.toString().padLeft(4, '0')}.${card.timestamp.month.toString().padLeft(2, '0')}.${card.timestamp.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => <ExpenseNotificationCard>[]).add(card);
    }
    return groups;
  }

  Future<void> start() async => _reload();

  void shiftMonth(int direction) {
    if (direction == 0) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + direction);
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    await _repository.markRead(id);
    await _reload();
  }

  Future<void> deleteCard(int id) async {
    await _repository.deleteCard(id);
    await _reload();
  }

  Future<void> clearVisibleMonth() async {
    await _repository.clearCards(monthKey: selectedMonthKey);
    await _reload();
  }

  Future<void> _reload() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _repository.listCards();
      rows.sort((left, right) {
        final byTime = right.timestamp.compareTo(left.timestamp);
        return byTime != 0 ? byTime : right.id.compareTo(left.id);
      });
      _cards = rows;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 4: Implement widgets and page**

Create `lib/features/notifications/widgets/notification_month_header.dart` with a swipeable header:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NotificationMonthHeader extends StatelessWidget {
  const NotificationMonthHeader({
    super.key,
    required this.selectedMonth,
    required this.hasCards,
    required this.onMonthShift,
    required this.onClear,
  });

  final DateTime selectedMonth;
  final bool hasCards;
  final ValueChanged<int> onMonthShift;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('notification-month-header'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -120) onMonthShift(1);
        if (velocity > 120) onMonthShift(-1);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          children: [
            const SizedBox(width: 36),
            Expanded(
              child: Text(
                '${selectedMonth.year}. ${_monthName(selectedMonth.month)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray500),
              ),
            ),
            IconButton(
              key: const ValueKey('notification-clear-month'),
              onPressed: hasCards ? onClear : null,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const names = <int, String>{
    1: 'Január', 2: 'Február', 3: 'Március', 4: 'Április', 5: 'Május', 6: 'Június',
    7: 'Július', 8: 'Augusztus', 9: 'Szeptember', 10: 'Október', 11: 'November', 12: 'December',
  };
  return names[month] ?? month.toString();
}
```

Create `lib/features/notifications/widgets/notification_log_box.dart` using the same gesture thresholds as `TransactionLogBox`: key `notification-logbox-$id`, min height 140, border radius 25, avatar circle 46, left swipe mark read, right swipe delete.

Use this core build structure:

```dart
class NotificationLogBox extends StatefulWidget {
  const NotificationLogBox({super.key, required this.card, required this.onMarkRead, required this.onDelete});

  final ExpenseNotificationCard card;
  final ValueChanged<int> onMarkRead;
  final ValueChanged<int> onDelete;

  @override
  State<NotificationLogBox> createState() => _NotificationLogBoxState();
}
```

In `_handleDragUpdate`, call `widget.onMarkRead(widget.card.id)` when `_dragDx < -80` and `widget.onDelete(widget.card.id)` when `_dragDx > 80`.

Create `lib/features/notifications/notifications_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/native_bridge.dart';
import 'data/notification_repository.dart';
import 'state/notification_store.dart';
import 'widgets/notification_log_box.dart';
import 'widgets/notification_month_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.nativeBridge});

  final NativeBridge nativeBridge;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationStore _store;

  @override
  void initState() {
    super.initState();
    _store = NotificationStore(NotificationRepository(widget.nativeBridge));
    _store.start();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        if (_store.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        if (_store.error != null) return Center(child: Text(_store.error!, style: const TextStyle(color: AppColors.expense)));
        final groups = _store.groupedCards;
        return Column(
          children: [
            const SizedBox(height: 36),
            NotificationMonthHeader(
              selectedMonth: _store.selectedMonth,
              hasCards: _store.visibleCards.isNotEmpty,
              onMonthShift: _store.shiftMonth,
              onClear: _store.clearVisibleMonth,
            ),
            Expanded(
              child: groups.isEmpty
                  ? const Center(child: Text('Nincsenek értesítések', style: TextStyle(color: AppColors.gray500)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                            child: Text(entry.key, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.gray500)),
                          ),
                          for (final card in entry.value)
                            NotificationLogBox(card: card, onMarkRead: _store.markRead, onDelete: _store.deleteCard),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
```

Modify `ExptShell` imports and tab content:

```dart
import '../notifications/notifications_page.dart';
```

Replace the notifications blank page:

```dart
NotificationsPage(nativeBridge: widget.nativeBridge),
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/notification_store_test.dart test/notifications/notification_widgets_test.dart'
```

Expected: all tests pass.

Commit:

```bash
git add lib/features/notifications lib/features/shell/expt_shell.dart test/notifications/notification_store_test.dart test/notifications/notification_widgets_test.dart
git commit -m "feat: add notification cards tab"
```

## Task 4: Bulk Transaction Name Rename And Reset

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `test/transactions/native_bridge_expense_test.dart`
- Modify: `test/transactions/transaction_widgets_test.dart`
- Modify: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing tests**

Append to `test/transactions/native_bridge_expense_test.dart`:

```dart
test('renames and resets all transactions by original merchant', () async {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return 3;
      });

  final renamed = await bridge.expenseRenameTransactionsByMerchant('Tesco', 'Tesco Market');
  final reset = await bridge.expenseResetTransactionNamesByMerchant('Tesco');

  expect(renamed, 3);
  expect(reset, 3);
  expect(calls[0].method, 'expenseRenameTransactionsByMerchant');
  expect((calls[0].arguments as Map)['originalMerchant'], 'Tesco');
  expect((calls[0].arguments as Map)['userAssignedName'], 'Tesco Market');
  expect(calls[1].method, 'expenseResetTransactionNamesByMerchant');
});
```

Append to `test/transactions/transaction_widgets_test.dart`:

```dart
testWidgets('logbox name tap opens name editor without opening transaction editor', (tester) async {
  var editOpened = false;
  String? renamedMerchant;
  await tester.pumpWidget(MaterialApp(
    home: TransactionLogBox(
      record: sampleExpenseRecord(),
      category: sampleExpenseCategory(),
      onTap: (_) => editOpened = true,
      onRenameMerchant: (record, value) async {
        renamedMerchant = '${record.merchant}:$value';
      },
      onResetMerchantName: (_) {},
    ),
  ));

  await tester.tap(find.byKey(const ValueKey('transaction-logbox-name-250909')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('transaction-name-editor-field')), 'Test Market Custom');
  await tester.tap(find.byKey(const ValueKey('transaction-name-editor-save')));
  await tester.pumpAndSettle();

  expect(editOpened, isFalse);
  expect(renamedMerchant, 'Test Store:Test Market Custom');
});

testWidgets('custom transaction name shows reset button and darker style', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: TransactionLogBox(
      record: sampleRecord(),
      category: sampleCategory(),
      onResetMerchantName: (_) {},
    ),
  ));

  expect(find.byKey(const ValueKey('transaction-name-reset-250905')), findsOneWidget);
  final text = tester.widget<Text>(find.byKey(const ValueKey('transaction-logbox-name-text-250905')));
  expect(text.style?.color, AppColors.gray800);
});
```

Append a store-level test to `test/transactions/transaction_store_test.dart` using a fake repository that records calls:

```dart
test('store bulk renames and resets by original merchant then reloads', () async {
  final repository = RenameRepository();
  final store = TransactionStore(repository);
  await store.start();

  await store.renameTransactionsByMerchant(repository.record, 'Tesco Market');
  await store.resetTransactionNamesByMerchant(repository.record);

  expect(repository.renameArgs, ['Tesco', 'Tesco Market']);
  expect(repository.resetMerchant, 'Tesco');
  expect(repository.reloads, 3);
});
```

- [ ] **Step 2: Run failing tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart'
```

Expected: compile failures for missing callbacks and bridge/store methods.

- [ ] **Step 3: Add Kotlin bulk rename/reset**

Modify `ExpenseTransactionDao.kt`:

```kotlin
@Query("UPDATE transactions SET userAssignedName = :userAssignedName WHERE merchant = :originalMerchant")
suspend fun renameByMerchant(originalMerchant: String, userAssignedName: String): Int

@Query("UPDATE transactions SET userAssignedName = NULL WHERE merchant = :originalMerchant")
suspend fun resetNamesByMerchant(originalMerchant: String): Int
```

Modify `ExpenseRepository.kt`:

```kotlin
suspend fun renameTransactionsByMerchant(args: Map<*, *>): Int {
    seedIfEmpty()
    val original = args["originalMerchant"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw ExpenseValidationException("INVALID_MERCHANT", "Original merchant is required")
    val custom = args["userAssignedName"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw ExpenseValidationException("INVALID_MERCHANT_NAME", "Custom merchant name is required")
    return transactions.renameByMerchant(original, custom)
}

suspend fun resetTransactionNamesByMerchant(args: Map<*, *>): Int {
    seedIfEmpty()
    val original = args["originalMerchant"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw ExpenseValidationException("INVALID_MERCHANT", "Original merchant is required")
    return transactions.resetNamesByMerchant(original)
}
```

Modify `ExpenseMethodChannel.kt`:

```kotlin
"expenseRenameTransactionsByMerchant" -> scope.launchResult(result) {
    repository.renameTransactionsByMerchant(call.argumentsMap())
}
"expenseResetTransactionNamesByMerchant" -> scope.launchResult(result) {
    repository.resetTransactionNamesByMerchant(call.argumentsMap())
}
```

- [ ] **Step 4: Add Dart bridge/repository/store methods**

Modify `NativeBridge`:

```dart
Future<int> expenseRenameTransactionsByMerchant(String originalMerchant, String userAssignedName) async {
  final count = await _methodChannel.invokeMethod<int>(
    'expenseRenameTransactionsByMerchant',
    {'originalMerchant': originalMerchant, 'userAssignedName': userAssignedName},
  );
  return count ?? 0;
}

Future<int> expenseResetTransactionNamesByMerchant(String originalMerchant) async {
  final count = await _methodChannel.invokeMethod<int>(
    'expenseResetTransactionNamesByMerchant',
    {'originalMerchant': originalMerchant},
  );
  return count ?? 0;
}
```

Modify `TransactionRepositoryContract` and `TransactionRepository`:

```dart
Future<int> renameTransactionsByMerchant(String originalMerchant, String userAssignedName);
Future<int> resetTransactionNamesByMerchant(String originalMerchant);
```

Implementation:

```dart
@override
Future<int> renameTransactionsByMerchant(String originalMerchant, String userAssignedName) {
  return _bridge.expenseRenameTransactionsByMerchant(originalMerchant, userAssignedName);
}

@override
Future<int> resetTransactionNamesByMerchant(String originalMerchant) {
  return _bridge.expenseResetTransactionNamesByMerchant(originalMerchant);
}
```

Modify `TransactionStore`:

```dart
Future<int> renameTransactionsByMerchant(TransactionRecord record, String userAssignedName) async {
  DebugConsole.log('[Rename] ${record.merchant} -> $userAssignedName');
  final count = await _repository.renameTransactionsByMerchant(record.merchant, userAssignedName);
  await _reload();
  DebugConsole.log('[Rename] updated $count rows for ${record.merchant}');
  return count;
}

Future<int> resetTransactionNamesByMerchant(TransactionRecord record) async {
  DebugConsole.log('[Rename] reset ${record.merchant}');
  final count = await _repository.resetTransactionNamesByMerchant(record.merchant);
  await _reload();
  DebugConsole.log('[Rename] reset $count rows for ${record.merchant}');
  return count;
}
```

Import:

```dart
import '../../../core/debug/debug_console.dart';
```

- [ ] **Step 5: Add logbox name editor UI**

Modify `TransactionLogContextCallback` area in `transaction_log_box.dart`:

```dart
import 'dart:async';

typedef TransactionRenameCallback = FutureOr<void> Function(TransactionRecord record, String userAssignedName);
typedef TransactionRecordAction = FutureOr<void> Function(TransactionRecord record);
```

Add constructor fields:

```dart
final TransactionRenameCallback? onRenameMerchant;
final TransactionRecordAction? onResetMerchantName;
```

Wrap the name `Text` with a `GestureDetector` key:

```dart
GestureDetector(
  key: ValueKey('transaction-logbox-name-${widget.record.id}'),
  behavior: HitTestBehavior.opaque,
  onTap: widget.onRenameMerchant == null ? null : _openNameEditor,
  child: Row(
    children: [
      Expanded(
        child: Text(
          widget.record.displayMerchant,
          key: ValueKey('transaction-logbox-name-text-${widget.record.id}'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.record.userAssignedName?.trim().isNotEmpty == true ? AppColors.gray800 : AppColors.gray500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (widget.record.userAssignedName?.trim().isNotEmpty == true && widget.onResetMerchantName != null)
        IconButton(
          key: ValueKey('transaction-name-reset-${widget.record.id}'),
          onPressed: () => widget.onResetMerchantName!(widget.record),
          icon: const Icon(Icons.restart_alt, size: 16),
          color: AppColors.gray500,
          tooltip: 'Eredeti név',
        ),
    ],
  ),
)
```

Add `_openNameEditor()` to `_TransactionLogBoxState`:

```dart
Future<void> _openNameEditor() async {
  final controller = TextEditingController(text: widget.record.displayMerchant);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tranzakció neve'),
      content: TextField(
        key: const ValueKey('transaction-name-editor-field'),
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary))),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Mégse')),
        FilledButton(
          key: const ValueKey('transaction-name-editor-save'),
          onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Mentés'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value == null || value.isEmpty) return;
  await widget.onRenameMerchant?.call(widget.record, value);
}
```

The name `GestureDetector` key above is the only tap target for name editing. Keep the existing outer card `GestureDetector` for transaction editing; Flutter's child gesture recognizer wins for taps on `transaction-logbox-name-*`, which keeps the full edit callback from firing.

- [ ] **Step 6: Wire callbacks through list and home page**

Modify `TransactionLogList` constructor:

```dart
required this.onRenameMerchant,
required this.onResetMerchantName,
```

Add fields:

```dart
final TransactionRenameCallback onRenameMerchant;
final TransactionRecordAction onResetMerchantName;
```

Pass into `TransactionLogBox`:

```dart
onRenameMerchant: onRenameMerchant,
onResetMerchantName: onResetMerchantName,
```

Modify `TransactionHomePage` `TransactionLogList` call:

```dart
onRenameMerchant: (record, value) async {
  await widget.store.renameTransactionsByMerchant(record, value);
},
onResetMerchantName: (record) async {
  await widget.store.resetTransactionNamesByMerchant(record);
},
```

- [ ] **Step 7: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart'
```

Expected: all selected Dart tests pass.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt lib/services/native_bridge.dart lib/features/transactions/data/transaction_repository.dart lib/features/transactions/state/transaction_store.dart lib/features/transactions/widgets/transaction_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/transaction_home_page.dart test/transactions/native_bridge_expense_test.dart test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart
git commit -m "feat: bulk edit transaction display names"
```

## Task 5: Monthly Recurring Ghost Projection, Activation Logs, And Trigger Notifications

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `test/transactions/recurring_ghost_log_test.dart`

- [ ] **Step 1: Write failing tests for monthly-only ghost visibility**

Modify `test/transactions/recurring_ghost_log_test.dart` first test:

```dart
test('store shows ghosts only in monthly mode and excludes them from summary', () async {
  final repository = GhostRepository();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 10));
  await store.start();

  expect(store.summaryWindow, SummaryWindow.allTime);
  expect(store.visibleGhostTransactions, isEmpty);

  store.cycleSummaryWindow();
  await repository.waitForEnsure();

  expect(store.summaryWindow, SummaryWindow.monthly);
  expect(store.visibleTransactions.single.displayMerchant, 'Real Shop');
  expect(store.visibleGhostTransactions.single.name, 'Rent');
  expect(store.visibleLogEntries.length, 2);
  expect(store.activeSummary.formattedFor(TransactionType.expense), '-100 Ft');
});
```

Update `GhostRepository` in the same file to implement the new contract method:

```dart
final ensured = <DateTime>[];
Completer<void>? _ensureCompleter;

Future<void> waitForEnsure() async {
  final completer = _ensureCompleter;
  if (completer != null && !completer.isCompleted) await completer.future;
}

@override
Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({DateTime? targetDate}) async {
  ensured.add(targetDate!);
  _ensureCompleter?.complete();
  return [ghostFixture()];
}
```

- [ ] **Step 2: Write failing Kotlin planner test for arbitrary viewed period**

Append to `RecurringGhostPlannerTest.kt`:

```kotlin
@Test
fun plansGhostForViewedMonthInsteadOfCurrentClockMonth() {
    val plan = RecurringGhostPlanner.planForPeriod(
        year = 2026,
        monthOneBased = 3,
        dayOfMonth = 31,
        lastProcessedPeriodKey = "2026-02",
        timeZone = utc,
    )

    assertEquals("2026-03", plan.periodKey)
    assertEquals("2026.03.31", plan.date)
    assertTrue(plan.shouldShowGhost)
}
```

- [ ] **Step 3: Run failing tests**

Run Dart:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/recurring_ghost_log_test.dart'
```

Expected: failure because ghosts still show in all-time and repository contract lacks ensure method.

Run Kotlin in a normal Android Gradle environment:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.RecurringGhostPlannerTest'
```

Expected: failure because `planForPeriod` does not exist.

- [ ] **Step 4: Add period planner and DAO query**

Modify `RecurringGhostPlanner.kt`:

```kotlin
fun planForPeriod(
    year: Int,
    monthOneBased: Int,
    dayOfMonth: Int,
    lastProcessedPeriodKey: String?,
    timeZone: TimeZone = TimeZone.getDefault(),
): RecurringGhostPlan {
    val monthZeroBased = (monthOneBased - 1).coerceIn(0, 11)
    val calendar = Calendar.getInstance(timeZone).apply {
        clear()
        set(year, monthZeroBased, 1, 0, 0, 0)
    }
    val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
    val effectiveDay = dayOfMonth.coerceIn(1, maxDay)
    val periodKey = "%04d-%02d".format(year, monthZeroBased + 1)
    val date = "%04d.%02d.%02d".format(year, monthZeroBased + 1, effectiveDay)
    val processedThisPeriod = lastProcessedPeriodKey == periodKey
    val trigger = Calendar.getInstance(timeZone).apply {
        clear()
        set(year, monthZeroBased, effectiveDay, 0, 0, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return RecurringGhostPlan(
        periodKey = periodKey,
        date = date,
        effectiveDayOfMonth = effectiveDay,
        triggerMillis = trigger.timeInMillis,
        shouldShowGhost = !processedThisPeriod,
        shouldActivate = false,
    )
}
```

Modify `RecurringGhostTransactionDao.kt`:

```kotlin
@Query("SELECT * FROM recurring_ghost_transactions WHERE isActivated = 0 AND periodKey = :periodKey ORDER BY date DESC, time DESC, id DESC")
suspend fun pendingForPeriod(periodKey: String): List<RecurringGhostTransactionEntity>
```

- [ ] **Step 5: Add Kotlin period ensure and trigger notification creation**

Modify `ExpenseRepository.kt` `ensureRecurringGhostTransactions` to compute period from `targetMillis` and return pending rows for that period:

```kotlin
suspend fun ensureRecurringGhostTransactions(targetMillis: Long = System.currentTimeMillis()): List<Map<String, Any?>> {
    seedIfEmpty()
    val calendar = Calendar.getInstance().apply { timeInMillis = targetMillis }
    val periodKey = "%04d-%02d".format(calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1)
    for (recurring in recurringTransactions.active()) {
        ensureRecurringGhostForPeriod(recurring, calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1)
    }
    activateDueRecurringGhosts(System.currentTimeMillis())
    return recurringGhosts.pendingForPeriod(periodKey).map { it.toMap() }
}
```

Add helper:

```kotlin
private suspend fun ensureRecurringGhostForPeriod(recurring: RecurringTransactionEntity, year: Int, monthOneBased: Int) {
    if (!recurring.isActive) return
    val plan = RecurringGhostPlanner.planForPeriod(
        year = year,
        monthOneBased = monthOneBased,
        dayOfMonth = recurring.dayOfMonth,
        lastProcessedPeriodKey = recurring.lastProcessedPeriodKey,
    )
    if (!plan.shouldShowGhost) return
    if (recurringGhosts.pendingByRecurringAndPeriod(recurring.id, plan.periodKey) != null) return
    val now = System.currentTimeMillis()
    recurringGhosts.insert(
        RecurringGhostTransactionEntity(
            recurringTransactionId = recurring.id,
            periodKey = plan.periodKey,
            name = recurring.name,
            amount = recurring.amount,
            transactionType = recurring.transactionType,
            date = plan.date,
            time = "00:00",
            categoryId = recurring.categoryId,
            categoryName = recurring.categoryName,
            categoryColor = recurring.categoryColor,
            categoryIconSlot = recurring.categoryIconSlot,
            triggerMillis = plan.triggerMillis,
            isActivated = false,
            activatedTransactionId = null,
            createdAt = now,
            updatedAt = now,
        ),
    )
}
```

In `activateDueRecurringGhosts`, after `transactions.insert(transaction)` and before `processed.add(updated)`, insert a notification card:

```kotlin
notificationCards.insert(
    NotificationCardEntity(
        type = "recurring_transaction_alert",
        title = "Ismétlődő tranzakció",
        message = "${ghost.name} automatikusan hozzáadva - ${ghost.categoryName}",
        timestamp = now,
        isRead = false,
        isActive = true,
        priority = "medium",
        categoryId = ghost.categoryId,
        categoryName = ghost.categoryName,
        categoryColor = ghost.categoryColor,
        categoryIconSlot = ghost.categoryIconSlot,
        recurringTransactionId = recurring.id,
        transactionId = transaction.id,
        amount = kotlin.math.abs(ghost.amount),
        triggerDate = ghost.date,
        nextDueDate = nextRecurringDateString(ghost.date, recurring.dayOfMonth),
        createdAt = now,
        updatedAt = now,
    ),
)
```

Add `nextRecurringDateString` helper:

```kotlin
private fun nextRecurringDateString(date: String, dayOfMonth: Int): String {
    val parts = date.replace('.', '-').split('-')
    val year = parts.getOrNull(0)?.toIntOrNull() ?: return date
    val month = parts.getOrNull(1)?.toIntOrNull() ?: return date
    val next = Calendar.getInstance().apply {
        clear()
        set(year, month, 1, 0, 0, 0)
    }
    val maxDay = next.getActualMaximum(Calendar.DAY_OF_MONTH)
    val day = dayOfMonth.coerceIn(1, maxDay)
    return "%04d.%02d.%02d".format(next.get(Calendar.YEAR), next.get(Calendar.MONTH) + 1, day)
}
```

- [ ] **Step 6: Add Dart ensure API and monthly store behavior**

Modify `TransactionRepositoryContract`:

```dart
Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({DateTime? targetDate});
```

Modify `TransactionRepository`:

```dart
@override
Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({DateTime? targetDate}) {
  return _bridge.expenseEnsureRecurringGhostTransactions(targetDate: targetDate);
}
```

Modify `TransactionStore`:

```dart
void cycleSummaryWindow() {
  _summaryWindow = switch (_summaryWindow) {
    SummaryWindow.monthly => SummaryWindow.yearly,
    SummaryWindow.yearly => SummaryWindow.allTime,
    SummaryWindow.allTime => SummaryWindow.monthly,
  };
  notifyListeners();
  _ensureGhostsForCurrentWindow();
}

void shiftSummaryPeriod(int direction) {
  if (direction == 0 || _summaryWindow == SummaryWindow.allTime) return;
  _periodReferenceDate = switch (_summaryWindow) {
    SummaryWindow.monthly => DateTime(_periodReferenceDate.year, _periodReferenceDate.month + direction),
    SummaryWindow.yearly => DateTime(_periodReferenceDate.year + direction),
    SummaryWindow.allTime => _periodReferenceDate,
  };
  notifyListeners();
  _ensureGhostsForCurrentWindow();
}

Future<void> _ensureGhostsForCurrentWindow() async {
  if (_summaryWindow != SummaryWindow.monthly) return;
  DebugConsole.log('[Recurring] ensure ghosts ${_periodReferenceDate.year}-${_periodReferenceDate.month.toString().padLeft(2, '0')}');
  try {
    final ghosts = await _repository.ensureRecurringGhostTransactions(targetDate: _periodReferenceDate);
    _recurringGhostTransactions = _sortGhosts(ghosts);
    DebugConsole.log('[Recurring] visible pending ghosts ${ghosts.length}');
    notifyListeners();
  } catch (error) {
    _error = error.toString();
    DebugConsole.log('[Recurring] ensure failed $error');
    notifyListeners();
  }
}
```

Change `_ghostInActiveWindow`:

```dart
bool _ghostInActiveWindow(RecurringGhostRecord ghost) {
  return switch (_summaryWindow) {
    SummaryWindow.allTime => false,
    SummaryWindow.yearly => false,
    SummaryWindow.monthly => ghost.yearMonthKey == '${_periodReferenceDate.year.toString().padLeft(4, '0')}-${_periodReferenceDate.month.toString().padLeft(2, '0')}',
  };
}
```

Log bootstrap in `start()` after payload assignment:

```dart
DebugConsole.log('[TransactionStore] bootstrap transactions=${_transactions.length} ghosts=${_recurringGhostTransactions.length}');
```

- [ ] **Step 7: Run tests and commit**

Run Dart:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/recurring_ghost_log_test.dart'
```

Run Kotlin in a normal Android Gradle environment:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.RecurringGhostPlannerTest'
```

Expected: Dart tests pass. Kotlin planner tests pass in a normal Android Gradle environment.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionDao.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt lib/services/native_bridge.dart lib/features/transactions/data/transaction_repository.dart lib/features/transactions/state/transaction_store.dart test/transactions/recurring_ghost_log_test.dart
git commit -m "feat: project recurring ghosts by month"
```

## Task 6: Magnet Strip Height

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Modify: `test/transactions/magnet_strip_test.dart`

- [ ] **Step 1: Write failing height tests**

Append to `test/transactions/magnet_strip_test.dart`:

```dart
testWidgets('header magnet strip uses doubled height', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TransactionHeaderCard(
        balanceText: '0 Ft',
        expanded: false,
        totalIncome: 100,
        totalExpense: 50,
        onCategoryPressed: () {},
        onCalendarPressed: () {},
        onExpandPressed: () {},
      ),
    ),
  ));

  final strip = tester.widget<MagnetStrip>(find.byType(MagnetStrip));
  expect(strip.height, 70);
});
```

Add import:

```dart
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_card.dart';
```

- [ ] **Step 2: Run failing test**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/magnet_strip_test.dart'
```

Expected: test fails because header passes `height: 35`.

- [ ] **Step 3: Double header and preview heights**

Modify `transaction_header_card.dart` magnet block:

```dart
child: SizedBox(
  height: 70,
  child: MagnetStrip(
    type: magnetType,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    accent: accent,
    height: 70,
  ),
),
```

Modify `theme_options_panel.dart` `_MagnetPreview`:

```dart
return SizedBox(
  width: 62,
  height: 48,
  child: MagnetStrip(
    type: type,
    totalIncome: 60,
    totalExpense: 40,
    height: 48,
  ),
);
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/magnet_strip_test.dart'
```

Expected: all magnet tests pass.

Commit:

```bash
git add lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/settings/widgets/options/theme_options_panel.dart test/transactions/magnet_strip_test.dart
git commit -m "fix: double magnet strip height"
```

## Task 7: Integration Verification And Push

**Files:**
- Modify only files needed to fix failures discovered by the commands below.

- [ ] **Step 1: Run Flutter analyzer**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 2: Run all Flutter tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all Flutter tests pass.

- [ ] **Step 3: Run Android unit tests where environment permits**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew testDebugUnitTest'
```

Expected in a normal Android Gradle environment: unit tests pass. In this Termux/proot workspace, record the known AAPT2 daemon failure if it occurs before Kotlin tests execute.

- [ ] **Step 4: Push commits**

Run:

```bash
git status --short
git push origin main
```

Expected: working tree clean before push, and `main -> main` pushed to GitHub.

- [ ] **Step 5: Verify GitHub online build**

Run:

```bash
gh run list --repo elizerpist/exptv2 --limit 3
gh run watch --repo elizerpist/exptv2 --exit-status
```

Expected: the newest GitHub Actions run succeeds and uploads the APK artifact. If `gh` is not authenticated in the environment, open the Actions URL from the pushed commit and report the run id.

- [ ] **Step 6: Final commit for verification notes if needed**

If no files changed during verification, do not create a commit. If a small fix was needed, commit it with:

```bash
git add <changed-files>
git commit -m "fix: stabilize debug recurring notifications"
git push origin main
```

## Self-Review

Spec coverage:

- Debug console and global floating button: Task 1.
- Recurring transaction debug logs and monthly ghost behavior: Task 5.
- Ghost activation into real transaction and notification card creation: Task 5 plus Task 2 backend.
- Magnet strip doubled height: Task 6.
- Transaction name edit, original merchant preservation, bulk rename/reset, reset button and colors: Task 4.
- Notification card system from expt0926: Tasks 2 and 3.
- Kotlin/Room backend and Dart UI bridge: Tasks 2, 4, and 5.
- Build, push, and online artifact verification: Task 7.

Plan quality scan:

- No unfinished-marker tokens or empty filler steps remain.
- Each code-changing task has a failing test step, implementation step, passing test step, and commit step.

Type consistency:

- Dart notification type is `ExpenseNotificationType` and card model is `ExpenseNotificationCard` across model, repository, store, and widgets.
- Rename API names are consistent: `expenseRenameTransactionsByMerchant` and `expenseResetTransactionNamesByMerchant`.
- Recurring projection API name is consistent: `ensureRecurringGhostTransactions` on repository and `expenseEnsureRecurringGhostTransactions` on bridge.
