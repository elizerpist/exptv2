# Exptv2 Transaction Workflows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make transaction add/edit/delete, dual filtering, date-grouped logs, and filtered summaries behave as one coordinated database view.

**Architecture:** Dart owns UI state and visible-record filtering. Kotlin/Room owns durable database mutation for transaction update/delete. The add transaction card becomes a non-blocking stack overlay aligned to `TransactionMenuMetrics.overlayTop`, while category editor keeps its modal sheet route from the previous change.

**Tech Stack:** Flutter/Dart widgets and widget tests, MethodChannel bridge, Kotlin Room repository, GitHub Actions Flutter build.

---

## File Structure

- Modify `lib/features/shell/expt_shell.dart`: replace FAB modal bottom sheet with non-blocking transaction editor overlay state.
- Modify `lib/features/transactions/widgets/add_transaction_sheet.dart`: turn add-only sheet into add/edit transaction editor card with fixed overlay height support and optional close callback.
- Modify `lib/features/transactions/transaction_home_page.dart`: pass edit/delete/category-filter callbacks into the log list and close overlays when needed.
- Modify `lib/features/transactions/state/transaction_store.dart`: expose windowed/visible records, dual filters, summary from visible records, update/delete transaction methods, and filter capsule metadata.
- Modify `lib/features/transactions/data/transaction_filter.dart`: preserve independent merchant and category filters.
- Modify `lib/features/transactions/data/transaction_repository.dart`: add update/delete transaction contract methods.
- Modify `lib/services/native_bridge.dart`: add `expenseUpdateTransaction` wrapper and use existing `expenseDeleteTransaction`.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`: route `expenseUpdateTransaction`.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: implement update transaction validation and row replacement.
- Modify `lib/features/transactions/widgets/transaction_log_list.dart`: render date groups and forward interactions.
- Modify `lib/features/transactions/widgets/transaction_log_box.dart`: split tap, left swipe, right swipe, and avatar tap callbacks.
- Modify `lib/features/transactions/widgets/search_pill.dart`: support merchant/category capsules, capsule colors, and focused outer border styling.
- Modify `lib/features/transactions/widgets/summary_pill.dart`: accept and render interval/filter-aware title text from the store.
- Modify tests under `test/transactions/` and `test/widget_test.dart`: add regression tests for every behavior before implementation.

---

### Task 1: Store Filter Semantics And Summary Source

**Files:**
- Modify: `lib/features/transactions/data/transaction_filter.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing tests for dual filters and visible summary**

Add tests to `test/transactions/transaction_store_test.dart`:

```dart
test('store applies merchant and category filters together', () async {
  final store = TransactionStore(FakeTransactionRepository());
  await store.start();

  final category = store.categories.firstWhere((item) => item.name == 'Q');
  store.setMerchantFilter('Rrr');
  store.setCategoryFilter(category);

  expect(store.merchantFilter, 'Rrr');
  expect(store.activeCategory?.name, 'Q');
  expect(store.visibleTransactions.length, 2);
  expect(
    store.visibleTransactions.every((record) => record.displayMerchant == 'Rrr'),
    isTrue,
  );
});

test('active summary is calculated from visible filtered records', () async {
  final store = TransactionStore(FakeTransactionRepository());
  await store.start();

  store.setMerchantFilter('Rrr');

  expect(store.visibleTransactions.length, 2);
  expect(
    store.activeSummary.formattedFor(TransactionType.expense),
    '-13 135 Ft',
  );
});

test('summary title includes interval and active filters', () async {
  final store = TransactionStore(
    FakeTransactionRepository(),
    clock: () => DateTime(2026, 3, 15),
  );
  await store.start();

  expect(store.activeSummaryTitle, contains('Sum'));
  store.cycleSummaryWindow();
  expect(store.activeSummaryTitle, contains('Március 2026'));
  store.cycleSummaryWindow();
  expect(store.activeSummaryTitle, contains('2026'));
});
```

- [ ] **Step 2: Run RED verification online**

Run locally for documentation even though Termux fails:

```bash
/data/data/com.termux/files/home/flutter_user/flutter/bin/flutter test test/transactions/transaction_store_test.dart
```

Expected local result: Dart TLS alignment failure in Termux. Commit the failing tests and push to GitHub; expected GitHub result: tests fail because merchant/category filters replace each other or summary still uses all interval records.

- [ ] **Step 3: Implement filter state**

Change `TransactionFilter.copyWith` so `setCategoryFilter` does not clear merchant and `setMerchantFilter` does not clear category. Keep `setActiveType` clearing both filters.

Add to `TransactionStore`:

```dart
List<TransactionRecord> get windowedTransactions {
  return LimitManager.recordsForWindow(
    transactions: _transactions,
    activeType: _filter.type,
    summaryWindow: _summaryWindow,
    referenceDate: _clock(),
  );
}

List<TransactionRecord> get visibleTransactions {
  final query = _filter.searchQuery.trim().toLowerCase();
  final merchant = _filter.merchant?.trim();
  return windowedTransactions.where((record) {
    if (_filter.categoryId != null &&
        record.transactionCategoryID != _filter.categoryId) {
      return false;
    }
    if (merchant != null && record.displayMerchant != merchant) return false;
    if (query.isNotEmpty &&
        !record.displayMerchant.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();
}

TransactionSummary get activeSummary =>
    TransactionSummary.fromRecords(visibleTransactions);
```

Add `activeSummaryTitle` with Hungarian month labels:

```dart
String get activeSummaryTitle {
  final base = switch (_summaryWindow) {
    SummaryWindow.allTime => 'Sum',
    SummaryWindow.yearly => _clock().year.toString(),
    SummaryWindow.monthly => '${_hungarianMonth(_clock().month)} ${_clock().year}',
  };
  final parts = <String>[base];
  if (_filter.merchant != null) parts.add(_filter.merchant!);
  final category = activeCategory;
  if (category != null) parts.add(category.name);
  return parts.join(' · ');
}
```

- [ ] **Step 4: Run GREEN verification**

Push implementation and verify GitHub `flutter test` passes for `transaction_store_test.dart` and existing suite.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/data/transaction_filter.dart lib/features/transactions/state/transaction_store.dart test/transactions/transaction_store_test.dart
git commit -m "feat: summarize visible filtered transactions"
```

---

### Task 2: Transaction Update And Delete Backend Contract

**Files:**
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `test/transactions/native_bridge_expense_test.dart`
- Modify: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing Dart bridge/store tests**

Add to `test/transactions/native_bridge_expense_test.dart`:

```dart
test('updates and deletes transaction through native bridge', () async {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    calls.add(call);
    if (call.method == 'expenseUpdateTransaction') {
      final args = Map<dynamic, dynamic>.from(call.arguments as Map);
      return {
        'id': args['id'],
        'date': args['date'],
        'time': args['time'],
        'merchant': args['merchant'],
        'amount': -42.0,
        'userAssignedName': null,
        'transactionCategoryID': args['transactionCategoryID'],
      };
    }
    if (call.method == 'expenseDeleteTransaction') return true;
    return null;
  });

  final updated = await bridge.expenseUpdateTransaction(1, {
    'merchant': 'Edited',
    'amount': 42,
    'type': 'expense',
    'transactionCategoryID': 5,
    'date': '2026.03.01',
    'time': '12:00',
  });
  final deleted = await bridge.expenseDeleteTransaction(1);

  expect(updated.displayMerchant, 'Edited');
  expect(deleted, isTrue);
  expect(calls.map((call) => call.method), [
    'expenseUpdateTransaction',
    'expenseDeleteTransaction',
  ]);
});
```

Add to store fake repository and tests:

```dart
test('store updates and deletes transaction then reloads bootstrap', () async {
  final repository = FakeTransactionRepository();
  final store = TransactionStore(repository);
  await store.start();
  final record = store.visibleTransactions.first;

  await store.updateTransaction(
    record,
    merchant: 'Edited Store',
    amount: 100,
    type: TransactionType.expense,
    categoryId: 6,
    date: '2025-09-25',
    time: '12:30',
  );
  await store.deleteTransaction(record);

  expect(repository.updatedPayloads.single['merchant'], 'Edited Store');
  expect(repository.deletedTransactionIds.single, record.id);
});
```

- [ ] **Step 2: Run RED verification online**

Expected failure: missing `expenseUpdateTransaction`, repository contract methods, and store methods.

- [ ] **Step 3: Implement Dart bridge and repository contract**

Add to `NativeBridge`:

```dart
Future<TransactionRecord> expenseUpdateTransaction(
  int id,
  Map<String, Object?> payload,
) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseUpdateTransaction',
    {'id': id, ...payload},
  );
  return TransactionRecord.fromMap(row ?? <dynamic, dynamic>{});
}
```

Add `updateTransaction` and `deleteTransaction` to `TransactionRepositoryContract`, implement in `TransactionRepository`, and expose `TransactionStore.updateTransaction` / `TransactionStore.deleteTransaction` with `_reload()`.

- [ ] **Step 4: Implement Kotlin route**

In `ExpenseMethodChannel.handle`, add:

```kotlin
"expenseUpdateTransaction" -> scope.launchResult(result) {
    repository.updateTransaction(call.argumentsMap())
}
```

In `ExpenseRepository`, add:

```kotlin
suspend fun updateTransaction(args: Map<*, *>): Map<String, Any?> {
    seedIfEmpty()
    val id = optionalInt(args["id"])
        ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
    val existing = transactions.byId(id)
        ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction does not exist")
    val merchant = args["merchant"]?.toString()?.trim().orEmpty()
    if (merchant.isEmpty()) {
        throw ExpenseValidationException("INVALID_TRANSACTION_NAME", "Transaction name is required")
    }
    val rawAmount = (args["amount"] as? Number)?.toDouble()
        ?: args["amount"]?.toString()?.toDoubleOrNull()
        ?: throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be numeric")
    if (rawAmount <= 0.0) {
        throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be greater than zero")
    }
    val type = args["type"]?.toString() ?: typeFromAmount(existing.amount)
    if (type != "income" && type != "expense") {
        throw ExpenseValidationException("INVALID_TRANSACTION_TYPE", "Type must be income or expense")
    }
    val categoryId = optionalInt(args["transactionCategoryID"])
        ?: existing.transactionCategoryID
    categories.byId(categoryId)
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
    val signedAmount = if (type == "income") kotlin.math.abs(rawAmount) else -kotlin.math.abs(rawAmount)
    val row = existing.copy(
        date = formatDate(args["date"]?.toString() ?: existing.date),
        time = args["time"]?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: existing.time,
        merchant = merchant,
        amount = signedAmount,
        userAssignedName = args["userAssignedName"]?.toString() ?: existing.userAssignedName,
        transactionCategoryID = categoryId,
    )
    transactions.insert(row)
    return row.toMap()
}
```

- [ ] **Step 5: Run GREEN verification and commit**

```bash
git add lib/services/native_bridge.dart lib/features/transactions/data/transaction_repository.dart lib/features/transactions/state/transaction_store.dart android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt test/transactions/native_bridge_expense_test.dart test/transactions/transaction_store_test.dart
git commit -m "feat: update and delete transactions"
```

---

### Task 3: Search Pill Capsules And Focus Styling

**Files:**
- Modify: `lib/features/transactions/widgets/search_pill.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests:

```dart
testWidgets('search pill renders merchant and category capsules with colors', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SearchPill(
        query: '',
        onQueryChanged: (_) {},
        filteredCount: 2,
        merchantFilter: 'Rrr',
        merchantColor: const Color(0xFFDC2626),
        categoryFilterName: 'Food',
        categoryColor: const Color(0xFF0EA5E9),
        onClearMerchant: () {},
        onClearCategory: () {},
      ),
    ),
  ));

  expect(find.text('Rrr'), findsOneWidget);
  expect(find.text('Food'), findsOneWidget);
  expect(find.byKey(const ValueKey('merchant-filter-capsule')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-filter-capsule')), findsOneWidget);
});

testWidgets('search input uses blue outer border when focused', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SearchPill(
        query: '',
        onQueryChanged: (_) {},
        filteredCount: 3,
      ),
    ),
  ));

  await tester.tap(find.byKey(const ValueKey('transaction-search-input')));
  await tester.pumpAndSettle();

  final pill = tester.widget<Container>(find.byKey(const ValueKey('search-pill')));
  final decoration = pill.decoration! as BoxDecoration;
  expect(decoration.border!.top.color, AppColors.primary);
});
```

- [ ] **Step 2: Run RED verification online**

Expected failure: missing constructor parameters, missing keys, old TextField decoration.

- [ ] **Step 3: Implement SearchPill API and UI**

Add parameters:

```dart
final Color? merchantColor;
final String? categoryFilterName;
final Color? categoryColor;
final VoidCallback? onClearCategory;
```

Convert to `StatefulWidget` with `FocusNode`. Wrap root in `Container(key: ValueKey('search-pill'))`; set border color to `AppColors.primary` while focused. Use compact `_FilterCapsule` for both filters, with keys `merchant-filter-capsule` and `category-filter-capsule`.

- [ ] **Step 4: Wire store metadata**

In `TransactionStore`, expose:

```dart
Color? get merchantFilterColor;
String? get categoryFilterName => activeCategory?.name;
Color? get categoryFilterColor => activeCategory?.slotColor;
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/widgets/search_pill.dart lib/features/transactions/state/transaction_store.dart test/transactions/transaction_widgets_test.dart
git commit -m "feat: show dual filter capsules"
```

---

### Task 4: Date-Grouped Log List And Logbox Gestures

**Files:**
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Test: `test/transactions/category_menu_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests:

```dart
testWidgets('log list groups records by date', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 500,
        child: TransactionLogList(
          records: transactionFixtures,
          categories: categoryFixtures,
          onFastFilter: (_) {},
          onCategoryFilter: (_) {},
          onEdit: (_) {},
          onDeleteRequested: (_) {},
        ),
      ),
    ),
  ));

  expect(find.byKey(const ValueKey('transaction-date-header-2025-09-25')), findsOneWidget);
});

testWidgets('logbox tap edit right swipe delete and avatar tap category filter are distinct', (tester) async {
  TransactionRecord? edited;
  TransactionRecord? deleted;
  TransactionCategory? filteredCategory;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TransactionLogBox(
        record: transactionFixtures.first,
        category: categoryFixtures.last,
        onFastFilter: (_) {},
        onCategoryFilter: (category) => filteredCategory = category,
        onEdit: (record) => edited = record,
        onDeleteRequested: (record) => deleted = record,
      ),
    ),
  ));

  await tester.tap(find.byKey(const ValueKey('transaction-logbox-250909')));
  expect(edited?.id, 250909);

  await tester.tap(find.byKey(const ValueKey('transaction-log-avatar-250909')));
  expect(filteredCategory?.name, 'Q');

  await tester.drag(find.byKey(const ValueKey('transaction-logbox-250909')), const Offset(120, 0));
  await tester.pumpAndSettle();
  expect(deleted?.id, 250909);
});
```

- [ ] **Step 2: Run RED verification online**

Expected failure: missing callback parameters and date headers.

- [ ] **Step 3: Implement date grouping**

Build flattened entries in `TransactionLogList`:

```dart
sealed class _LogEntry {}
class _DateEntry extends _LogEntry { _DateEntry(this.date); final String date; }
class _RecordEntry extends _LogEntry { _RecordEntry(this.record); final TransactionRecord record; }
```

Render `_DateEntry` as a small uppercase/gray date header keyed by normalized date. Render `_RecordEntry` as `TransactionLogBox`.

- [ ] **Step 4: Implement gestures**

In `TransactionLogBox`, keep left swipe threshold for fast filter (`_dragDx < -80`) and add right swipe threshold (`_dragDx > 80`) for delete. Wrap only the avatar in a `GestureDetector` with key `transaction-log-avatar-${record.id}` and call `onCategoryFilter(category)`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/widgets/transaction_log_box.dart lib/features/transactions/transaction_home_page.dart test/transactions/transaction_widgets_test.dart test/transactions/category_menu_test.dart
git commit -m "feat: group logs and add log actions"
```

---

### Task 5: Non-Blocking Add/Edit Transaction Overlay

**Files:**
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/widget_test.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Write failing overlay tests**

Add to `test/widget_test.dart`:

```dart
testWidgets('FAB opens transaction editor without modal barrier and keeps type pills tappable', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  final summaryTop = tester.getRect(find.byKey(const ValueKey('summary-pill'))).top;
  await tester.tap(find.byKey(const ValueKey('expt-fab')));
  await tester.pumpAndSettle();

  expect(find.byType(ModalBarrier), findsNothing);
  expect(find.byKey(const ValueKey('transaction-editor-card')), findsOneWidget);
  expect(
    tester.getRect(find.byKey(const ValueKey('transaction-editor-card'))).top,
    moreOrLessEquals(summaryTop, epsilon: 0.1),
  );
  expect(find.text('Új kiadási tranzakció'), findsOneWidget);

  await tester.tap(find.text('Bevétel'));
  await tester.pumpAndSettle();
  expect(find.text('Új bevételi tranzakció'), findsOneWidget);
});
```

Add edit test:

```dart
testWidgets('tapping a logbox opens transaction editor in edit mode', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('transaction-logbox-250909')));
  await tester.pumpAndSettle();

  expect(find.text('Tranzakció módosítása'), findsOneWidget);
  expect(find.widgetWithText(TextField, 'Test Store'), findsOneWidget);
});
```

- [ ] **Step 2: Run RED verification online**

Expected failure: current FAB uses modal bottom sheet with barrier and card is not aligned to summary top.

- [ ] **Step 3: Implement shell overlay state**

In `_ExptShellState`, add:

```dart
bool _transactionEditorOpen = false;
TransactionRecord? _editingTransaction;
```

Replace `showModalBottomSheet` in `_handleFabPressed` with:

```dart
setState(() {
  _editingTransaction = null;
  _transactionEditorOpen = true;
});
```

Render after app body and before bottom nav/FAB:

```dart
if (_transactionEditorOpen)
  Positioned(
    left: 0,
    right: 0,
    top: TransactionMenuMetrics.overlayTop,
    bottom: AppDimensions.bottomNavHeight,
    child: AddTransactionSheet(
      key: const ValueKey('transaction-editor-card'),
      store: _transactionStore,
      initialRecord: _editingTransaction,
      onClose: () => setState(() => _transactionEditorOpen = false),
    ),
  ),
```

Pass `onEditTransaction` from `TransactionHomePage` back to shell. If keeping `TransactionHomePage` independent is simpler, add `ValueChanged<TransactionRecord>? onEditTransaction` to its constructor.

- [ ] **Step 4: Update AddTransactionSheet**

Add optional fields:

```dart
final TransactionRecord? initialRecord;
final VoidCallback? onClose;
```

In `initState`, prefill from `initialRecord`. Title is edit title when `initialRecord != null`. Save calls `store.updateTransaction` for edit, otherwise `store.addTransaction`. On success, call `onClose` instead of `Navigator.pop` when provided.

- [ ] **Step 5: Commit**

```bash
git add lib/features/shell/expt_shell.dart lib/features/transactions/widgets/add_transaction_sheet.dart lib/features/transactions/transaction_home_page.dart test/widget_test.dart test/transactions/header_layout_test.dart
git commit -m "feat: add nonblocking transaction editor"
```

---

### Task 6: Delete Confirmation Flow

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/shell/expt_shell.dart` if delete handling is lifted to shell
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing delete confirmation test**

```dart
testWidgets('right swipe on logbox confirms and deletes transaction', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  await tester.drag(find.byKey(const ValueKey('transaction-logbox-250909')), const Offset(140, 0));
  await tester.pumpAndSettle();

  expect(find.text('Tranzakció törlése?'), findsOneWidget);
  await tester.tap(find.text('Törlés'));
  await tester.pumpAndSettle();

  expect(deletedTransactions, contains(250909));
});
```

- [ ] **Step 2: Run RED verification online**

Expected failure: no delete dialog route wired.

- [ ] **Step 3: Implement confirmation dialog**

Use `showDialog<bool>` in `TransactionHomePage`:

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Tranzakció törlése?'),
    content: Text(record.displayMerchant),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Mégse')),
      FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Törlés')),
    ],
  ),
);
if (confirmed == true) await widget.store.deleteTransaction(record);
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/transaction_home_page.dart test/widget_test.dart
git commit -m "feat: confirm transaction deletion"
```

---

### Task 7: Final Integration And Online Build

**Files:**
- All files touched by previous tasks

- [ ] **Step 1: Run local non-Flutter checks**

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 2: Run local Flutter command and record environment failure**

```bash
/data/data/com.termux/files/home/flutter_user/flutter/bin/flutter test
```

Expected in Termux: Dart TLS alignment failure. Do not treat this as code failure.

- [ ] **Step 3: Push all commits**

```bash
git push origin main
```

- [ ] **Step 4: Watch GitHub Actions**

```bash
gh run list --branch main --limit 3
gh run watch <run-id> --exit-status
```

Expected: analyzer, Flutter tests, APK build, and artifact upload all succeed.

- [ ] **Step 5: Verify artifact and clean status**

```bash
gh run view <run-id> --json status,conclusion,url,headSha,jobs
gh api repos/elizerpist/exptv2/actions/runs/<run-id>/artifacts --jq '.artifacts[] | "\(.name) \(.size_in_bytes) \(.expired)"'
git status --short
```

Expected: `conclusion: success`, artifact `exptv2-debug-apk`, clean worktree.
