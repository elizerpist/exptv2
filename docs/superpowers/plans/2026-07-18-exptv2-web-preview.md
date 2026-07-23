# Exptv2 Web Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the complete production Exptv2 Flutter widget tree in a browser with deterministic in-memory data, session-scoped CRUD, safe web fallbacks for Android-only capabilities, and a repeatable `127.0.0.1:8766` UI-development workflow.

**Architecture:** Preserve `NativeBridge` as the domain serialization boundary and put a generic transport underneath it. Native builds keep the current MethodChannel/EventChannel transport; web selects a routed in-memory transport whose focused handlers share one seeded preview state. Conditional adapters keep Android-only keyboard, isolate, alarm, IME, Google sign-in, and socket APIs out of the web compilation unit.

**Tech Stack:** Flutter 3.41.4/Dart 3.11.1, Flutter web-server, MethodChannel/EventChannel, conditional Dart exports, `flutter_test`, SharedPreferences web implementation, fixed-viewport golden screenshots.

## Global Constraints

- `lib/main.dart` remains the canonical entry point and must build the same `Exptv2App`/`ExptShell` widget tree on Android and web.
- Browser data is deterministic, in memory, shared across screens during the session, and reset by full page refresh; do not add IndexedDB, local storage, or a server API.
- Every CRUD operation exposed by the preview UI must mutate shared preview state and return payloads accepted by the existing `NativeBridge` decoders.
- Notification listener, accessibility capture, Android permissions/settings, biometrics, native alarms, native IME, and native file sharing are unavailable/no-op on web and must not invoke missing platform channels.
- Google Sheets authentication and sync initialization are disabled in web preview.
- Android continues to use the existing channel-backed behavior; do not change Android method names or payload contracts.
- Primary UI verification viewport is `412x915`; also verify `360x800` and `1280x900` for overflow.
- Run Flutter tests and analysis only inside Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Do not run a local APK build. A local Flutter web build is allowed.
- Preserve the user's existing uncommitted Color Lab, query-time-picker, and `test/failures/` changes.
- Source specification: `docs/superpowers/specs/2026-07-18-exptv2-web-preview-design.md`.

## File Structure

### Transport and composition

- Create `lib/services/native_bridge_transport.dart`: generic bridge transport plus channel-backed native implementation.
- Modify `lib/services/native_bridge.dart`: delegate all method/list/map/event calls to the transport while preserving the existing constructor API.
- Create `lib/services/native_bridge_factory.dart`: conditional export for platform bridge creation.
- Create `lib/services/native_bridge_factory_native.dart`: native `NativeBridge()` factory.
- Create `lib/services/native_bridge_factory_web.dart`: web `NativeBridge` with preview transport.
- Modify `lib/main.dart`: call `createNativeBridge()` once and inject that instance into `EventStore` and `Exptv2App`.

### Preview backend

- Create `lib/services/preview/preview_fixture_data.dart`: deterministic fixture builder only.
- Create `lib/services/preview/preview_native_state.dart`: mutable session state, IDs, reset, clone helpers, and event controller.
- Create `lib/services/preview/preview_method_handler.dart`: focused handler interface.
- Create `lib/services/preview/preview_transaction_handler.dart`: transaction/category/limit/stats CRUD and queries.
- Create `lib/services/preview/preview_settings_handler.dart`: app settings, parser settings, security-disabled behavior, export, and installed-app responses.
- Create `lib/services/preview/preview_activity_handler.dart`: raw events, notification cards/logs, recurring records/rules, service status, and platform no-ops.
- Create `lib/services/preview/preview_native_bridge_transport.dart`: route table, duplicate-route validation, generic casts, event stream, and unknown-method failure.

### Web compatibility

- Create `lib/core/keyboard/app_keyboard_provider.dart`, `app_keyboard_provider_native.dart`, and `app_keyboard_provider_web.dart`: conditional provider wrapper.
- Modify `lib/exptv2_app.dart`: use `AppKeyboardProvider` and skip Google Sheets initialization on web.
- Modify `lib/features/transactions/widgets/slide_up_menu_card.dart`: remove its unused direct keyboard-controller import.
- Split `lib/features/stats/data/stats_render_frame_worker.dart` into a web-safe API plus `stats_render_frame_worker_native.dart` and `stats_render_frame_worker_web.dart` implementations.
- Create `lib/core/platform/network_failure.dart`, `network_failure_io.dart`, and `network_failure_web.dart`: conditional `isNetworkFailure(Object)` implementation.
- Modify `lib/features/transactions/sync/google_sheets_sync_controller.dart`: use `isNetworkFailure` without importing `dart:io`.
- Modify `lib/services/recurring_alarm_service.dart`: add a disabled constructor that returns stable no-op values.
- Modify `lib/services/native_ime_sheet_bridge.dart`: add a disabled constructor and guard every outbound method.
- Modify `lib/features/shell/expt_shell.dart`: select disabled alarm/IME services on web.
- Modify `lib/core/keyboard/native_keyboard_insets.dart`: do not subscribe to the native event channel on web.

### Web platform and verification

- Generate `web/index.html`, `web/manifest.json`, `web/favicon.png`, `web/icons/*`, and `.metadata` with Flutter's web scaffold command.
- Create preview backend tests under `test/services/preview/`.
- Create `test/web_preview/exptv2_web_preview_test.dart`: production-tree startup/navigation/CRUD smoke coverage.
- Create `test/web_preview/exptv2_web_preview_golden_test.dart`: fixed mobile/narrow/desktop screenshots.
- Create/update golden PNGs under `test/goldens/web_preview/`.
- Update the acceptance table in the design spec only after evidence exists.

## Requirement Coverage

- `WEB-RUN-001`: Tasks 7, 8, 9, and 10 isolate web-incompatible APIs, generate the web target, load the production tree, and verify the served URL.
- `WEB-UI-001`: Task 9 navigates every main screen and Flutter fallback sheet at mobile and desktop viewport sizes.
- `WEB-DATA-001`: Task 2 creates the complete deterministic fixture and shared session state.
- `WEB-CRUD-001`: Tasks 3, 4, 5, 6, and 9 implement protocol handlers, decoder contracts, and UI-driven mutation checks.
- `WEB-NATIVE-001`: Tasks 4, 5, and 7 disable security/platform capabilities and remove unconditional native API imports.
- `WEB-HOT-001`: Task 10 starts `flutter run -d web-server` in a foreground Termux session and verifies the live app.
- `WEB-ANDROID-001`: Tasks 1, 7, 8, and 9 preserve constructor/channel contracts and run the existing bridge, shell, and full test suites.

---

### Task 1: Introduce the bridge transport without changing native behavior

**Files:**
- Create: `lib/services/native_bridge_transport.dart`
- Modify: `lib/services/native_bridge.dart`
- Create: `test/services/native_bridge_transport_test.dart`

**Interfaces:**
- Produces: `NativeBridgeTransport`, `MethodChannelNativeBridgeTransport`, and `NativeBridge(transport: ...)`.
- Preserves: `NativeBridge(methodChannel: ..., eventChannel: ...)` for all existing tests and Android callers.

- [ ] **Step 1: Write the failing transport-injection test**

```dart
class RecordingTransport implements NativeBridgeTransport {
  final calls = <String>[];

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(method);
    if (method == 'getStatus') {
      return <String, Object?>{
            'captureMode': 'both',
            'notificationListenerEnabled': false,
            'accessibilityEnabled': false,
            'notificationListenerActive': false,
            'accessibilityActive': false,
            'totalEvents': 0,
          }
          as T;
    }
    return null;
  }

  @override
  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]) async {
    calls.add(method);
    return <T>[];
  }

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [Object? arguments]) async {
    final value = await invokeMethod<Object?>(method, arguments);
    return (value as Map?)?.cast<K, V>();
  }

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) => const Stream.empty();
}

test('NativeBridge delegates scalar, list, map, and event work to transport', () async {
  final transport = RecordingTransport();
  final bridge = NativeBridge(transport: transport);

  await bridge.loadEvents();
  await bridge.getStatus();
  await bridge.watchEvents().drain<void>();

  expect(transport.calls, containsAll(<String>['loadEvents', 'getStatus']));
});
```

- [ ] **Step 2: Run the test and confirm the missing-interface failure**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/services/native_bridge_transport_test.dart'
```

Expected: FAIL because `NativeBridgeTransport` and the `transport` constructor parameter do not exist.

- [ ] **Step 3: Add the transport interface and channel implementation**

```dart
import 'package:flutter/services.dart';

abstract interface class NativeBridgeTransport {
  Future<T?> invokeMethod<T>(String method, [Object? arguments]);
  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]);
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [Object? arguments]);
  Stream<Object?> receiveBroadcastStream([Object? arguments]);
}

class MethodChannelNativeBridgeTransport implements NativeBridgeTransport {
  MethodChannelNativeBridgeTransport({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel = methodChannel ?? const MethodChannel('pushparser/methods'),
      _eventChannel = eventChannel ?? const EventChannel('pushparser/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) =>
      _methodChannel.invokeMethod<T>(method, arguments);

  @override
  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]) =>
      _methodChannel.invokeListMethod<T>(method, arguments);

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [Object? arguments]) =>
      _methodChannel.invokeMapMethod<K, V>(method, arguments);

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) =>
      _eventChannel.receiveBroadcastStream(arguments);
}
```

Modify `NativeBridge` to own one `_transport`, preserve channel injection, and replace every `_methodChannel.invoke*` call plus `_eventChannel.receiveBroadcastStream()` with the matching transport call:

```dart
NativeBridge({
  MethodChannel? methodChannel,
  EventChannel? eventChannel,
  NativeBridgeTransport? transport,
}) : _transport = transport ?? MethodChannelNativeBridgeTransport(
       methodChannel: methodChannel,
       eventChannel: eventChannel,
     );

final NativeBridgeTransport _transport;
```

- [ ] **Step 4: Run transport and existing bridge contract tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/services/native_bridge_transport_test.dart test/transactions/native_bridge_expense_test.dart test/settings/settings_bridge_test.dart test/event_store_test.dart'
```

Expected: all tests PASS with unchanged MethodChannel method names and payloads.

- [ ] **Step 5: Commit the transport boundary**

```bash
git add lib/services/native_bridge.dart lib/services/native_bridge_transport.dart test/services/native_bridge_transport_test.dart
git commit -m "refactor: add native bridge transport boundary"
```

### Task 2: Add deterministic preview fixtures and shared session state

**Files:**
- Create: `lib/services/preview/preview_fixture_data.dart`
- Create: `lib/services/preview/preview_native_state.dart`
- Create: `lib/services/preview/preview_method_handler.dart`
- Create: `test/services/preview/preview_native_state_test.dart`

**Interfaces:**
- Produces: `PreviewFixtureData buildPreviewFixtureData(DateTime now)`, `PreviewNativeState.seeded({DateTime? now})`, `PreviewNativeState.reset()`, and `PreviewMethodHandler`.
- State representation: mutable `List<Map<String, Object?>>` collections and mutable settings maps; callers receive defensive deep copies.

- [ ] **Step 1: Write failing fixture/state tests**

```dart
test('seed covers current, adjacent, and prior-year UI states', () {
  final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));

  expect(state.categories.any((row) => row['type'] == 'kiadás'), isTrue);
  expect(state.categories.any((row) => row['type'] == 'bevétel'), isTrue);
  expect(state.transactions.any((row) => row['date'].toString().startsWith('2026.07')), isTrue);
  expect(state.transactions.any((row) => row['date'].toString().startsWith('2026.06')), isTrue);
  expect(state.transactions.any((row) => row['date'].toString().startsWith('2025.')), isTrue);
  expect(state.securitySettings['pinEnabled'], isFalse);
  expect(state.securitySettings['biometricAvailable'], isFalse);
});

test('reset restores fixtures and monotonic IDs', () {
  final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
  final first = state.takeTransactionId();
  state.transactions.clear();
  state.reset();
  final afterReset = state.takeTransactionId();

  expect(state.transactions, isNotEmpty);
  expect(afterReset, first);
});
```

- [ ] **Step 2: Run the fixture test and confirm missing classes**

Run the targeted test in Ubuntu proot. Expected: FAIL because preview state files do not exist.

- [ ] **Step 3: Implement fixture data with fixed semantic content and dates relative to `now`**

Define `PreviewFixtureData` with these exact fields:

```dart
class PreviewFixtureData {
  const PreviewFixtureData({
    required this.categories,
    required this.transactions,
    required this.limits,
    required this.recurringTransactions,
    required this.recurringRules,
    required this.recurringGhosts,
    required this.notificationCards,
    required this.notificationEvents,
    required this.pushLogEvents,
    required this.statsSnapshots,
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.pushRecurringSettings,
    required this.notificationSettings,
    required this.securitySettings,
    required this.notificationParserConfig,
  });

  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> transactions;
  final List<Map<String, Object?>> limits;
  final List<Map<String, Object?>> recurringTransactions;
  final List<Map<String, Object?>> recurringRules;
  final List<Map<String, Object?>> recurringGhosts;
  final List<Map<String, Object?>> notificationCards;
  final List<Map<String, Object?>> notificationEvents;
  final List<Map<String, Object?>> pushLogEvents;
  final List<Map<String, Object?>> statsSnapshots;
  final Map<String, Object?> themeSettings;
  final Map<String, Object?> fastInfoConfig;
  final Map<String, Object?> pushRecurringSettings;
  final Map<String, Object?> notificationSettings;
  final Map<String, Object?> securitySettings;
  final Map<String, Object?> notificationParserConfig;
}
```

Seed exactly six expense categories, two income categories, twelve current-month transactions, four adjacent-month transactions, and four prior-year transactions. Use the existing model keys exactly: `transactionCategoryID`, `date`, `time`, `merchant`, signed `amount`, `userAssignedName`, `transactionCategoryID`, `targetType`, `transactionType`, `window`, and `periodKey`. Use stable merchant names (`Tesco`, `Lidl`, `BKK`, `Netflix`, `Fizetés`) and relative date formatting `yyyy.MM.dd` so the current UI is populated whenever the preview starts.

- [ ] **Step 4: Implement mutable state, cloning, reset, and IDs**

```dart
class PreviewNativeState {
  PreviewNativeState.seeded({DateTime? now}) : _now = now ?? DateTime.now() {
    reset();
  }

  final DateTime _now;
  late List<Map<String, Object?>> categories;
  late List<Map<String, Object?>> transactions;
  late List<Map<String, Object?>> limits;
  late List<Map<String, Object?>> recurringTransactions;
  late List<Map<String, Object?>> recurringRules;
  late List<Map<String, Object?>> recurringGhosts;
  late List<Map<String, Object?>> notificationCards;
  late List<Map<String, Object?>> notificationEvents;
  late List<Map<String, Object?>> pushLogEvents;
  late List<Map<String, Object?>> statsSnapshots;
  late Map<String, Object?> themeSettings;
  late Map<String, Object?> fastInfoConfig;
  late Map<String, Object?> pushRecurringSettings;
  late Map<String, Object?> notificationSettings;
  late Map<String, Object?> securitySettings;
  late Map<String, Object?> notificationParserConfig;
  bool automaticPushParserEnabled = true;
  String? lastExportFileName;
  String? lastExportMimeType;
  String? lastExportContent;
  int _nextTransactionId = 1;
  int _nextCategoryId = 1;
  int _nextLimitId = 1;
  int _nextRecurringId = 1;
  int _nextRuleId = 1;

  final StreamController<Object?> eventController = StreamController<Object?>.broadcast();

  DateTime get now => _now;

  void reset() {
    final fixture = buildPreviewFixtureData(_now);
    categories = _copyRows(fixture.categories);
    transactions = _copyRows(fixture.transactions);
    limits = _copyRows(fixture.limits);
    recurringTransactions = _copyRows(fixture.recurringTransactions);
    recurringRules = _copyRows(fixture.recurringRules);
    recurringGhosts = _copyRows(fixture.recurringGhosts);
    notificationCards = _copyRows(fixture.notificationCards);
    notificationEvents = _copyRows(fixture.notificationEvents);
    pushLogEvents = _copyRows(fixture.pushLogEvents);
    statsSnapshots = _copyRows(fixture.statsSnapshots);
    themeSettings = Map<String, Object?>.from(fixture.themeSettings);
    fastInfoConfig = Map<String, Object?>.from(fixture.fastInfoConfig);
    pushRecurringSettings = Map<String, Object?>.from(fixture.pushRecurringSettings);
    notificationSettings = Map<String, Object?>.from(fixture.notificationSettings);
    securitySettings = Map<String, Object?>.from(fixture.securitySettings);
    notificationParserConfig = _deepCopyMap(fixture.notificationParserConfig);
    automaticPushParserEnabled = true;
    lastExportFileName = null;
    lastExportMimeType = null;
    lastExportContent = null;
    _nextTransactionId = _nextId(transactions, 'id');
    _nextCategoryId = _nextId(categories, 'transactionCategoryID');
    _nextLimitId = _nextId(limits, 'id');
    _nextRecurringId = _nextId(recurringTransactions, 'id');
    _nextRuleId = _nextId(recurringRules, 'id');
  }

  int takeTransactionId() => _nextTransactionId++;
  int takeCategoryId() => _nextCategoryId++;
  int takeLimitId() => _nextLimitId++;
  int takeRecurringId() => _nextRecurringId++;
  int takeRuleId() => _nextRuleId++;

  Future<void> dispose() => eventController.close();
}
```

Define `PreviewMethodHandler` as:

```dart
abstract interface class PreviewMethodHandler {
  Set<String> get supportedMethods;
  Future<Object?> invoke(String method, Object? arguments);
}
```

- [ ] **Step 5: Run state tests, format, and commit**

Run the targeted test, then `dart format` through the Flutter SDK's bundled Dart. Expected: PASS.

```bash
git add lib/services/preview/preview_fixture_data.dart lib/services/preview/preview_native_state.dart lib/services/preview/preview_method_handler.dart test/services/preview/preview_native_state_test.dart
git commit -m "feat: add seeded web preview state"
```

### Task 3: Implement transaction, category, limit, and stats preview CRUD

**Files:**
- Create: `lib/services/preview/preview_transaction_handler.dart`
- Create: `test/services/preview/preview_transaction_handler_test.dart`

**Interfaces:**
- Consumes: `PreviewNativeState`, `PreviewMethodHandler`.
- Produces: `PreviewTransactionHandler` supporting bootstrap, transaction/category/limit CRUD, transaction filtering/paging, merchant rename/reset, recurring ghost listing, and stats snapshots.

- [ ] **Step 1: Write failing tests for shared-state CRUD and filtering**

Tests must call the handler with protocol-level maps and assert:

```dart
final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
final handler = PreviewTransactionHandler(state);

final added = await handler.invoke('expenseAddTransaction', <String, Object?>{
  'date': '2026.07.18',
  'time': '12:30',
  'merchant': 'Design Coffee',
  'amount': 1890,
  'type': 'expense',
  'transactionCategoryID': 1,
}) as Map<String, Object?>;
expect(added['amount'], -1890.0);

final page = await handler.invoke('expenseListTransactionPage', <String, Object?>{
  'searchQuery': 'design',
  'limit': 20,
  'offset': 0,
}) as Map<String, Object?>;
expect(page['totalCount'], 1);

await handler.invoke('expenseUpdateTransaction', <String, Object?>{
  'id': added['id'],
  'merchant': 'Design Cafe',
  'amount': 2200,
  'type': 'expense',
});
expect(state.transactions.singleWhere((row) => row['id'] == added['id'])['merchant'], 'Design Cafe');

expect(await handler.invoke('expenseDeleteTransaction', <String, Object?>{'id': added['id']}), isTrue);
```

Add equivalent create/update/delete assertions for categories, category count protection, limit upsert/filter, stats snapshot upsert, merchant rename/reset, year/month selection, and bootstrap defensive copies.

- [ ] **Step 2: Run the handler test and confirm the missing-class failure**

Run the targeted test. Expected: FAIL because `PreviewTransactionHandler` does not exist.

- [ ] **Step 3: Implement the exact supported method set**

```dart
static const _methods = <String>{
  'expensePickYearMonth',
  'expenseLoadBootstrap',
  'expenseListStatsSnapshots',
  'expenseUpsertStatsSnapshot',
  'expenseListTransactions',
  'expenseListTransactionPage',
  'expenseGetTransaction',
  'expenseNotificationEventIdForTransaction',
  'expenseTransactionsForNotificationEvents',
  'expenseListCategories',
  'expenseAddTransaction',
  'expenseUpdateTransaction',
  'expenseAddCategory',
  'expenseUpdateCategory',
  'expenseDeleteCategory',
  'expenseCategoryCounts',
  'expenseListCategoryLimits',
  'expenseUpsertCategoryLimit',
  'expenseDeleteTransaction',
  'expenseRenameTransactionsByMerchant',
  'expenseResetTransactionNamesByMerchant',
  'expenseListRecurringGhostTransactions',
  'expenseEnsureRecurringGhostTransactions',
};
```

Normalize transaction payloads before storage:

```dart
Map<String, Object?> _transactionFromPayload(
  Map<String, Object?> payload, {
  required int id,
  Map<String, Object?>? existing,
}) {
  final merged = <String, Object?>{...?existing, ...payload};
  final rawAmount = (merged['amount'] as num?)?.toDouble() ?? 0;
  final income = merged['type'] == 'income' || rawAmount > 0 && merged['type'] == null;
  return <String, Object?>{
    'id': id,
    'date': merged['date']?.toString() ?? _formatDate(state.now),
    'time': merged['time']?.toString() ?? '12:00',
    'latitude': merged['latitude'],
    'longitude': merged['longitude'],
    'address': merged['address'],
    'merchant': merged['merchant']?.toString() ?? '',
    'amount': income ? rawAmount.abs() : -rawAmount.abs(),
    'userAssignedName': merged['userAssignedName'],
    'transactionCategoryID': merged['transactionCategoryID'],
    if (merged['sourceNotificationEventId'] != null)
      'sourceNotificationEventId': merged['sourceNotificationEventId'],
  };
}
```

Filtering order is: type, category ID, merchant exact match, case-insensitive search over merchant/user-assigned name, year-month, descending date/time/id, then offset/limit. Category deletion returns `false` when any transaction references the category. Limit upsert matches `(targetType, targetId, transactionType, window, periodKey)` and preserves its ID. Return defensive copies from every read.

- [ ] **Step 4: Run handler and real bridge decoder tests**

For this task run the handler tests and existing transaction repository tests. The real `NativeBridge` decoder contract is added in Task 6 after the routed transport exists. Expected: PASS.

- [ ] **Step 5: Commit transaction preview behavior**

```bash
git add lib/services/preview/preview_transaction_handler.dart test/services/preview/preview_transaction_handler_test.dart
git commit -m "feat: add preview transaction CRUD"
```

### Task 4: Implement settings, parser, security-disabled, and export behavior

**Files:**
- Create: `lib/services/preview/preview_settings_handler.dart`
- Create: `test/services/preview/preview_settings_handler_test.dart`

**Interfaces:**
- Consumes: shared preview state.
- Produces: settings and parser payloads that pass existing `NativeBridge` model decoders; all security capability responses remain disabled.

- [ ] **Step 1: Write failing settings tests**

Assert `expenseLoadSettings` returns all five nested maps, theme/fast-info/push-recurring/notification updates are stored and returned, parser profile add/update/delete payloads survive, installed-app discovery returns an empty list, export returns a `memory://` URI, share completes without a platform call, and every security method returns:

```dart
const disabledSecurity = <String, Object?>{
  'pinEnabled': false,
  'biometricEnabled': false,
  'biometricAvailable': false,
  'biometricLabel': 'Nem elerheto',
};
```

- [ ] **Step 2: Run tests and confirm missing handler**

Expected: FAIL because `PreviewSettingsHandler` does not exist.

- [ ] **Step 3: Implement the exact method set and state updates**

```dart
static const _methods = <String>{
  'listInstalledApps',
  'expenseLoadSettings',
  'expenseUpdateThemeSettings',
  'expenseUpdateFastInfoConfig',
  'expenseSaveTextFile',
  'expenseShareTextFile',
  'expenseUpdatePushRecurringSettings',
  'expenseUpdateNotificationSettings',
  'expenseSetSecurityPin',
  'expenseChangeSecurityPin',
  'expenseClearSecurityPin',
  'expenseVerifySecurityPin',
  'expenseSetBiometricEnabled',
  'expenseGetBiometricAvailability',
  'expenseAuthenticateBiometric',
  'loadNotificationParserProfiles',
  'saveNotificationParserProfiles',
  'loadNotificationParserRule',
  'saveNotificationParserRule',
  'loadAutomaticPushParserEnabled',
  'saveAutomaticPushParserEnabled',
};
```

`expenseLoadSettings` must return copies under `themeSettings`, `fastInfoConfig`, `pushRecurringSettings`, `notificationSettings`, and `securitySettings`. All security mutation methods ignore supplied PIN/biometric values and return disabled security; verification/authentication return `false`. `expenseSaveTextFile` stores the last file name, MIME type, and content in state and returns `memory://<encoded fileName>`; `expenseShareTextFile` stores the same three values and returns `null`.

- [ ] **Step 4: Run settings handler plus existing settings bridge tests**

Expected: all PASS.

- [ ] **Step 5: Commit settings preview behavior**

```bash
git add lib/services/preview/preview_settings_handler.dart test/services/preview/preview_settings_handler_test.dart
git commit -m "feat: add preview settings backend"
```

### Task 5: Implement events, notifications, recurring CRUD, status, and native no-ops

**Files:**
- Create: `lib/services/preview/preview_activity_handler.dart`
- Create: `test/services/preview/preview_activity_handler_test.dart`

**Interfaces:**
- Consumes: shared preview state.
- Produces: notification and recurring payloads, service status, reset behavior, and stable no-op platform responses.

- [ ] **Step 1: Write failing activity-domain tests**

Cover raw event paging, `markNotificationEventSystem`, notification card read/delete/clear, recurring transaction create/update/toggle/delete/process, recurring rule create/update/toggle/delete, stable service status, permission/settings no-ops, and `clearDatabase` restoring seed data rather than leaving the UI blank.

- [ ] **Step 2: Run tests and confirm missing handler**

Expected: FAIL because `PreviewActivityHandler` does not exist.

- [ ] **Step 3: Implement the exact method inventory**

```dart
static const _methods = <String>{
  'loadEvents',
  'loadEventsAfterId',
  'loadNotificationEventPage',
  'loadNotificationEvent',
  'markNotificationEventSystem',
  'getStatus',
  'expenseListRecurringTransactions',
  'expenseAddRecurringTransaction',
  'expenseUpdateRecurringTransaction',
  'expenseToggleRecurringTransaction',
  'expenseDeleteRecurringTransaction',
  'expenseProcessRecurringTransactions',
  'expenseListRecurringRules',
  'expenseAddRecurringRule',
  'expenseUpdateRecurringRule',
  'expenseToggleRecurringRule',
  'expenseDeleteRecurringRule',
  'expenseListNotificationCards',
  'expenseMarkNotificationCardRead',
  'expenseDeleteNotificationCard',
  'expenseClearNotificationCards',
  'setCaptureMode',
  'openNotificationAccessSettings',
  'openAccessibilitySettings',
  'openAppInfoSettings',
  'openAppNotificationSettings',
  'requestPostNotifications',
  'requestPostNotificationsOnFirstLaunch',
  'sendTestNotification',
  'clearDatabase',
};
```

Service status always reports all native capabilities false and `totalEvents` equal to the fixture event count. Platform open/request/send calls return `null` or `false` according to the existing `NativeBridge` return type. Recurring processing creates at most one transaction per active rule/current period and records `recurringRuleId`; repeated processing for the same period is idempotent.

- [ ] **Step 4: Run activity, notification repository, and recurring tests**

Expected: PASS with no pending timers or uncaught async channel errors.

- [ ] **Step 5: Commit activity preview behavior**

```bash
git add lib/services/preview/preview_activity_handler.dart test/services/preview/preview_activity_handler_test.dart
git commit -m "feat: add preview activity backend"
```

### Task 6: Route preview methods through a complete transport

**Files:**
- Create: `lib/services/preview/preview_native_bridge_transport.dart`
- Create: `test/services/preview/preview_native_bridge_transport_test.dart`

**Interfaces:**
- Consumes: all three preview handlers and shared state.
- Produces: `PreviewNativeBridgeTransport({PreviewNativeState? state})`, `state`, generic transport methods, route validation, and event stream.

- [ ] **Step 1: Write failing route/completeness tests**

```dart
test('routes real NativeBridge decoders through preview payloads', () async {
  final transport = PreviewNativeBridgeTransport(
    state: PreviewNativeState.seeded(now: DateTime(2026, 7, 18)),
  );
  final bridge = NativeBridge(transport: transport);

  final bootstrap = await bridge.expenseLoadBootstrap();
  final settings = await bridge.expenseLoadSettings();
  final cards = await bridge.expenseListNotificationCards();

  expect(bootstrap.transactions, isNotEmpty);
  expect(settings.securitySettings.authEnabled, isFalse);
  expect(cards, isNotEmpty);
});

test('unknown methods fail with the missing method name', () async {
  final transport = PreviewNativeBridgeTransport();
  await expectLater(
    transport.invokeMethod<Object?>('unmappedMethod'),
    throwsA(isA<UnsupportedError>().having((e) => e.message, 'message', contains('unmappedMethod'))),
  );
});
```

Add a duplicate route test by injecting two handlers with the same method name and expecting `StateError`.

- [ ] **Step 2: Run tests and confirm missing transport**

Expected: FAIL because the preview transport does not exist.

- [ ] **Step 3: Implement route registration and generic casts**

```dart
class PreviewNativeBridgeTransport implements NativeBridgeTransport {
  PreviewNativeBridgeTransport({PreviewNativeState? state, List<PreviewMethodHandler>? handlers})
    : state = state ?? PreviewNativeState.seeded() {
    final sources = handlers ?? <PreviewMethodHandler>[
      PreviewTransactionHandler(this.state),
      PreviewSettingsHandler(this.state),
      PreviewActivityHandler(this.state),
    ];
    for (final handler in sources) {
      for (final method in handler.supportedMethods) {
        if (_routes.containsKey(method)) {
          throw StateError('Duplicate preview method route: $method');
        }
        _routes[method] = handler;
      }
    }
  }

  final PreviewNativeState state;
  final Map<String, PreviewMethodHandler> _routes = <String, PreviewMethodHandler>{};

  Future<Object?> _dispatch(String method, Object? arguments) {
    final handler = _routes[method];
    if (handler == null) throw UnsupportedError('Unsupported preview bridge method: $method');
    return handler.invoke(method, arguments);
  }

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async =>
      await _dispatch(method, arguments) as T?;

  @override
  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]) async =>
      (await _dispatch(method, arguments) as List?)?.cast<T>();

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [Object? arguments]) async =>
      (await _dispatch(method, arguments) as Map?)?.cast<K, V>();

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) => state.eventController.stream;
}
```

- [ ] **Step 4: Run all preview backend and existing bridge tests**

Expected: PASS. Confirm every method invoked by the production startup has exactly one route.

- [ ] **Step 5: Commit routed preview transport**

```bash
git add lib/services/preview/preview_native_bridge_transport.dart test/services/preview/preview_native_bridge_transport_test.dart
git commit -m "feat: route preview bridge methods"
```

### Task 7: Isolate Android-only APIs behind web-safe adapters

**Files:**
- Create/modify all files listed under **Web compatibility** in the file structure.
- Create: `test/core/platform/web_preview_adapters_test.dart`

**Interfaces:**
- Produces: `AppKeyboardProvider`, conditionally selected `IsolateStatsRenderFrameWorker`, `isNetworkFailure(Object)`, `RecurringAlarmService.disabled()`, and `NativeImeSheetBridge.disabled()`.

- [ ] **Step 1: Write failing direct tests for web implementations**

Import the `_web.dart` adapter files directly and assert the keyboard wrapper builds its child, the web stats worker returns the canonical frame asynchronously via `Future<StatsRenderFrame>.value`, `isNetworkFailure` returns false without `dart:io`, disabled alarm methods return empty/default results, and disabled IME methods return `false`/empty/no-op.

- [ ] **Step 2: Run tests and confirm missing adapters**

Expected: FAIL on missing files/classes.

- [ ] **Step 3: Add conditional keyboard provider**

Aggregator:

```dart
export 'app_keyboard_provider_native.dart'
    if (dart.library.js_interop) 'app_keyboard_provider_web.dart';
```

Both implementations expose:

```dart
class AppKeyboardProvider extends StatelessWidget {
  const AppKeyboardProvider({super.key, required this.child});
  final Widget child;
}
```

Native `build` returns `KeyboardProvider(child: child)`; web `build` returns `child`. Replace `KeyboardProvider` in `Exptv2App` and remove the unused package import from `slide_up_menu_card.dart`.

- [ ] **Step 4: Split stats worker and socket classification conditionally**

Keep `StatsRenderFrameRequest` and `StatsRenderFrameWorker` in a web-safe base file. Native implementation imports `dart:isolate` and calls `Isolate.run`; web implementation returns `Future<StatsRenderFrame>.value(request.buildSynchronously())`. Export the class under the existing `IsolateStatsRenderFrameWorker` name so callers and tests remain unchanged.

`network_failure.dart` conditionally exports IO/web implementations. IO checks `error is SocketException`; web always returns false. Replace both `SocketException` checks in `google_sheets_sync_controller.dart` with `isNetworkFailure(error)`.

- [ ] **Step 5: Add disabled alarm/IME constructors and web selection**

Use a private `_enabled` field. Disabled methods return `false`, empty maps/lists, or a `RecurringAlarmDebugState` with `usingOverride: false` and no platform invocation. In `ExptShell.initState`, select with `kIsWeb`. In `NativeKeyboardInsets.ensureStarted`, return immediately when `kIsWeb`. In `Exptv2App.initState`, skip `_initGoogleSheetsSync()` when `kIsWeb`.

- [ ] **Step 6: Prove web-blocking imports are conditionally isolated**

Run:

```bash
rg -n "import 'dart:io'|import 'dart:isolate'|package:flutter_keyboard_controller" lib
```

Expected: matches only in native conditional implementation files; no unconditional app compilation unit imports them.

- [ ] **Step 7: Run adapter, keyboard, stats, shell, and Google sync tests**

Expected: PASS.

- [ ] **Step 8: Commit platform adapters**

```bash
git add lib/core/keyboard lib/core/platform lib/exptv2_app.dart lib/features/stats/data lib/features/transactions/sync/google_sheets_sync_controller.dart lib/features/transactions/widgets/slide_up_menu_card.dart lib/services/recurring_alarm_service.dart lib/services/native_ime_sheet_bridge.dart lib/features/shell/expt_shell.dart test/core/platform/web_preview_adapters_test.dart
git commit -m "feat: add web-safe platform adapters"
```

### Task 8: Add platform bridge factory and Flutter web target

**Files:**
- Create: `lib/services/native_bridge_factory.dart`
- Create: `lib/services/native_bridge_factory_native.dart`
- Create: `lib/services/native_bridge_factory_web.dart`
- Modify: `lib/main.dart`
- Generate: `.metadata`, `web/index.html`, `web/manifest.json`, `web/favicon.png`, `web/icons/*`
- Create: `test/services/native_bridge_factory_test.dart`

**Interfaces:**
- Produces: `NativeBridge createNativeBridge()` selected at compile time.

- [ ] **Step 1: Write failing factory tests**

Test the native file directly returns a `NativeBridge`; test the web file directly returns a bridge whose `expenseLoadBootstrap()` and `expenseLoadSettings()` decode seeded data without platform channels.

- [ ] **Step 2: Run tests and confirm missing factories**

Expected: FAIL because factory files do not exist.

- [ ] **Step 3: Implement conditional factory and wire `main.dart`**

```dart
export 'native_bridge_factory_native.dart'
    if (dart.library.js_interop) 'native_bridge_factory_web.dart';
```

Native:

```dart
NativeBridge createNativeBridge() => NativeBridge();
```

Web:

```dart
NativeBridge createNativeBridge() => NativeBridge(
  transport: PreviewNativeBridgeTransport(),
);
```

Main:

```dart
final bridge = createNativeBridge();
runApp(Exptv2App(store: EventStore(bridge), nativeBridge: bridge));
```

- [ ] **Step 4: Generate only the Flutter web platform scaffold**

Run inside Ubuntu proot:

```bash
/home/flutteruser/flutter/bin/flutter create --platforms=web --project-name=exptv2 .
```

Expected: creates `.metadata` and `web/`; inspect `git diff` and revert no user files. Do not accept Android, README, pubspec dependency, or unrelated formatting changes from the generator.

- [ ] **Step 5: Run factory tests and a debug web compilation**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/services/native_bridge_factory_test.dart && /home/flutteruser/flutter/bin/flutter build web --debug'
```

Expected: tests PASS and `build/web/index.html` exists with no unsupported library/plugin errors.

- [ ] **Step 6: Commit factory and web scaffold**

```bash
git add lib/main.dart lib/services/native_bridge_factory*.dart .metadata web test/services/native_bridge_factory_test.dart
git commit -m "feat: enable exptv2 web preview"
```

### Task 9: Verify the production widget tree, CRUD flows, and screenshots

**Files:**
- Create: `test/web_preview/exptv2_web_preview_test.dart`
- Create: `test/web_preview/exptv2_web_preview_golden_test.dart`
- Create/update: `test/goldens/web_preview/*.png`

**Interfaces:**
- Consumes: production `Exptv2App`, `EventStore`, preview bridge/transport.
- Produces: repeatable startup/navigation/CRUD and viewport screenshot evidence.

- [ ] **Step 1: Write failing production-tree startup/navigation test**

Build the app with `SharedPreferences.setMockInitialValues({})`, `PreviewNativeBridgeTransport`, and the immediate stats worker test override. At `412x915`, wait for `expt-bottom-nav`, then open Home, Stats (`bottom-nav-stats`), Settings (`bottom-nav-settings`), Notifications (`header-notification-button`), the FAB transaction editor, category editor, recurring manager, and Flutter fallback sheet. After every transition assert `tester.takeException()` is null.

- [ ] **Step 2: Add UI-driven CRUD checks**

Use existing stable keys to create and edit one transaction, add/edit/delete one category, save a limit, toggle/delete one recurring rule, mark/delete one notification card, and mutate theme/notification/parser settings. Assert the shared preview state changed after each save and the visible screen reflects the new value.

- [ ] **Step 3: Run the interaction test and fix only evidence-backed route/adapter gaps**

Expected first run: any missing preview method fails loudly with its exact method name. Add that method to the correct focused handler with a targeted unit test before rerunning the widget test. Stop and reassess if three unrelated missing architecture paths appear.

- [ ] **Step 4: Add fixed-viewport golden tests**

Capture the loaded production tree at `412x915`, `360x800`, and `1280x900` with deterministic fixture time and DPR 1. Store files as:

```text
test/goldens/web_preview/exptv2-mobile-412x915.png
test/goldens/web_preview/exptv2-narrow-360x800.png
test/goldens/web_preview/exptv2-desktop-1280x900.png
```

The test must check `tester.takeException()`, visible root pixels, missing asset exceptions, and absence of `RenderFlex overflowed` diagnostics before matching the golden.

- [ ] **Step 5: Generate and inspect screenshots**

Run `flutter test --update-goldens` only for the new golden test inside Ubuntu proot. Open every generated PNG with the local image viewer. Reject blank, clipped, overlapped, or desktop-stretched output; fix layout only when the issue also affects the production widget tree and record the relevant acceptance item.

- [ ] **Step 6: Run targeted and full verification**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/services/preview test/web_preview test/services/native_bridge_transport_test.dart test/services/native_bridge_factory_test.dart && /home/flutteruser/flutter/bin/flutter test && /home/flutteruser/flutter/bin/flutter analyze && /home/flutteruser/flutter/bin/flutter build web --debug'
```

Expected: all tests PASS, analyze reports no issues, and web build succeeds.

- [ ] **Step 7: Commit integration coverage and accepted goldens**

```bash
git add test/web_preview test/goldens/web_preview
git commit -m "test: verify exptv2 web preview"
```

### Task 10: Start the preview, verify HTTP, and close the acceptance checklist

**Files:**
- Modify: `docs/superpowers/specs/2026-07-18-exptv2-web-preview-design.md`

**Interfaces:**
- Produces: running browser URL and evidence-backed checklist statuses.

- [ ] **Step 1: Re-read the approved spec and checklist**

For every `WEB-*` row, link the exact test, screenshot, command result, or direct inspection that satisfies it. Leave any unsupported item `PARTIAL` or `NOT DONE`.

- [ ] **Step 2: Start Flutter web-server on loopback**

Run in a dedicated Termux session:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8766'
```

Expected: Flutter prints a serving URL containing `http://127.0.0.1:8766` and keeps the hot-reload terminal active.

- [ ] **Step 3: Verify the served app, not just the HTML shell**

Run `curl -I http://127.0.0.1:8766`, open the URL in the phone browser, wait for the Exptv2 shell, navigate Home/Stats/Settings/Notifications, and confirm the browser console/server output has no startup exceptions.

- [ ] **Step 4: Update acceptance statuses honestly**

Set a row to `DONE` only when its acceptance condition and verification method both have evidence. Do not mark the package complete solely because `flutter build web` succeeded.

- [ ] **Step 5: Commit checklist evidence**

```bash
git add docs/superpowers/specs/2026-07-18-exptv2-web-preview-design.md
git commit -m "docs: verify exptv2 web preview"
```

- [ ] **Step 6: Report the exact command and URL**

Report `http://127.0.0.1:8766`, the foreground Termux command, completed checklist IDs, any honest deferrals, and the fact that full browser refresh resets preview data.
