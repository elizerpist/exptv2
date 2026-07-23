import 'dart:async';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/security/security_gate.dart';
import 'package:exptv2/features/shell/expt_shell.dart';
import 'package:exptv2/features/notifications/notifications_page.dart';
import 'package:exptv2/features/settings/settings_page.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/stats/data/stats_render_frame.dart';
import 'package:exptv2/features/stats/data/stats_render_frame_worker.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DebugConsole.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'high-volume Home type callback performs no eager visible-view reads',
    (tester) async {
      final store = _TrackingTransactionStore(
        _HighVolumeRepository(),
        clock: () => DateTime(2026, 7, 12),
      );
      await store.start();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: TransactionHomePage(store: store),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      store.resetVisibleReads();
      DebugConsole.clear();
      final incomePill = find.byKey(
        const ValueKey('transaction-type-pill-income-surface'),
      );
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: incomePill, matching: find.byType(InkWell)),
      );

      inkWell.onTap!();

      expect(store.visibleDisplayLogEntryReads, 0);
      expect(store.visibleTransactionReads, 0);
      expect(
        DebugConsole.allText,
        isNot(contains('[Perf] Store active view reason=type-switch')),
      );
      expect(store.activeType, TransactionType.income);
      await tester.pump();
      expect(store.visibleDisplayLogEntryReads, lessThanOrEqualTo(3));
      expect(store.visibleTransactions, hasLength(3000));
    },
  );

  testWidgets('cold start prewarms and mounts Stats before first navigation', (
    tester,
  ) async {
    const channel = MethodChannel('startup-prewarm-shell');
    const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _smallShellMethodHandler);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async => false);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, null);
    });
    final bridge = NativeBridge(methodChannel: channel);
    final worker = _ControlledStatsFrameWorker();
    final cache = StatsRenderFrameCache();

    await tester.pumpWidget(
      MaterialApp(
        home: ExptShell(
          store: EventStore(bridge, realtimeEnabled: false),
          nativeBridge: bridge,
          statsRenderFrameCache: cache,
          statsRenderFrameWorker: worker,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(worker.requests, hasLength(2));
    expect(
      worker.requests.map((request) => request.activeType),
      containsAll(<TransactionType>[
        TransactionType.expense,
        TransactionType.income,
      ]),
    );
    expect(
      find.byKey(const ValueKey('shell-cold-start-loading')),
      findsOneWidget,
    );
    expect(find.byType(StatsPage, skipOffstage: false), findsNothing);

    worker.complete(0);
    worker.complete(1);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('shell-cold-start-loading')),
      findsNothing,
    );
    expect(
      find.byType(TransactionHomePage, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(StatsPage, skipOffstage: false), findsOneWidget);
    final requestCountBeforeStatsTap = worker.requests.length;

    await tester.tap(find.byKey(const ValueKey('bottom-nav-stats')));
    await tester.pump();
    await tester.pump();

    expect(worker.requests, hasLength(requestCountBeforeStatsTap));
    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-frame-pending')), findsNothing);
  });

  testWidgets(
    'cold start retries Stats prewarm when resume merges a newer transaction',
    (tester) async {
      const channel = MethodChannel('startup-prewarm-revision-shell');
      const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
      var eventDelivered = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'loadEventsAfterId' && !eventDelivered) {
              eventDelivered = true;
              return <Map<String, Object?>>[
                <String, Object?>{
                  'id': 77,
                  'timestamp': DateTime(2026, 7, 12).millisecondsSinceEpoch,
                  'source': 'notification_listener',
                  'packageName': 'hu.bank',
                  'appLabel': 'Bank',
                  'title': 'Transaction',
                  'text': 'Expense',
                  'bigText': '',
                  'subText': '',
                  'category': '',
                  'notificationKey': 'event-77',
                  'accessibilityEventType': '',
                  'hash': 'event-77',
                  'isDuplicate': false,
                },
              ];
            }
            if (call.method == 'expenseTransactionsForNotificationEvents') {
              return <Map<String, Object?>>[
                <String, Object?>{
                  'id': 3,
                  'date': '2026.07.03',
                  'time': '11:00',
                  'merchant': 'Background expense',
                  'amount': -24000,
                  'userAssignedName': null,
                  'transactionCategoryID': 1,
                },
              ];
            }
            return _smallShellMethodHandler(call);
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, (call) async => false);
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nativeSheetChannel, null);
      });
      final bridge = NativeBridge(methodChannel: channel);
      final worker = _ControlledStatsFrameWorker();

      await tester.pumpWidget(
        MaterialApp(
          home: ExptShell(
            store: EventStore(bridge, realtimeEnabled: false),
            nativeBridge: bridge,
            statsRenderFrameWorker: worker,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(worker.requests, hasLength(2));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(eventDelivered, isTrue);

      worker.complete(0);
      worker.complete(1);
      await tester.pump();
      await tester.pump();

      expect(worker.requests, hasLength(4));
      expect(worker.requests[2].transactions, hasLength(3));
      expect(worker.requests[3].transactions, hasLength(3));
      expect(
        find.byKey(const ValueKey('shell-cold-start-loading')),
        findsOneWidget,
      );

      worker.complete(2);
      worker.complete(3);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('shell-cold-start-loading')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'background resume retains the active Stats tab without cold loading',
    (tester) async {
      const channel = MethodChannel('retained-resume-shell');
      const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
      var settingsLoadCount = 0;
      final resumeSettings = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'expenseLoadSettings') {
              settingsLoadCount += 1;
              if (settingsLoadCount > 2) return await resumeSettings.future;
            }
            if (call.method == 'loadEvents') return <Object?>[];
            return await _smallShellMethodHandler(call);
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, (call) async => false);
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nativeSheetChannel, null);
      });
      final bridge = NativeBridge(methodChannel: channel);
      final worker = _ControlledStatsFrameWorker();

      await tester.pumpWidget(
        MaterialApp(
          home: SecurityGate(
            nativeBridge: bridge,
            child: ExptShell(
              store: EventStore(bridge, realtimeEnabled: false),
              nativeBridge: bridge,
              statsRenderFrameWorker: worker,
            ),
          ),
        ),
      );
      for (var index = 0; index < 6 && worker.requests.length < 2; index += 1) {
        await tester.pump();
      }
      expect(worker.requests, hasLength(2));
      worker.complete(0);
      worker.complete(1);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('shell-cold-start-loading')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('bottom-nav-stats')));
      await tester.pump();
      await tester.pump();
      final statsElement = tester.element(find.byType(StatsPage));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(const ValueKey('shell-cold-start-loading')),
        findsNothing,
      );
      expect(tester.element(find.byType(StatsPage)), same(statsElement));

      resumeSettings.complete(<String, Object?>{});
      await tester.pump();
      await tester.pump();

      expect(find.byType(StatsPage), findsOneWidget);
      expect(tester.element(find.byType(StatsPage)), same(statsElement));
    },
  );

  testWidgets(
    'bottom-nav pointer work is deferred and visited tab elements are retained',
    (tester) async {
      const channel = MethodChannel('task-5a-shell');
      const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, _shellMethodHandler);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, (call) async => false);
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nativeSheetChannel, null);
      });
      final bridge = NativeBridge(methodChannel: channel);
      final store = _TrackingEventStore(bridge);
      await tester.pumpWidget(
        MaterialApp(
          home: ExptShell(
            store: store,
            nativeBridge: bridge,
            statsRenderFrameWorker: const _ImmediateStatsFrameWorker(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        find.byKey(const ValueKey('shell-cold-start-loading')),
        findsNothing,
      );
      final homeElement = tester.element(find.byType(TransactionHomePage));
      store.shellPersistenceWrites = 0;
      DebugConsole.clear();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('bottom-nav-stats'))),
      );

      expect(store.shellPersistenceWrites, 0);
      expect(DebugConsole.allText, isNot(contains('close sheets issued')));
      expect(DebugConsole.allText, isNot(contains('page jump tab=stats')));
      await gesture.up();

      expect(store.shellPersistenceWrites, 0);
      expect(DebugConsole.allText, isNot(contains('close sheets issued')));
      expect(DebugConsole.allText, isNot(contains('page jump tab=stats')));
      await tester.pump();
      expect(store.shellPersistenceWrites, 1);
      expect(
        RegExp(r'page jump tab=stats').allMatches(DebugConsole.allText).length,
        1,
      );
      await tester.pump();
      final statsElement = tester.element(find.byType(StatsPage));
      expect(find.byType(SettingsPage), findsNothing);

      final settingsGesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('bottom-nav-settings'))),
      );
      await settingsGesture.up();
      expect(find.byType(SettingsPage), findsNothing);
      await tester.pump();
      expect(find.byType(SettingsPage), findsNothing);
      await tester.pump();
      final settingsElement = tester.element(find.byType(SettingsPage));

      await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
      await tester.pump();
      await tester.pump();
      expect(
        tester.element(find.byType(TransactionHomePage)),
        same(homeElement),
      );
      DebugConsole.clear();
      final homeIncomePill = find.descendant(
        of: find.byType(TransactionHomePage),
        matching: find.byKey(
          const ValueKey('transaction-type-pill-income-surface'),
        ),
      );
      tester
          .widget<InkWell>(
            find.descendant(of: homeIncomePill, matching: find.byType(InkWell)),
          )
          .onTap!();
      expect(DebugConsole.allText, isNot(contains('Stats frame build')));
      await tester.pump();
      expect(DebugConsole.allText, isNot(contains('Stats frame build')));

      await tester.tap(
        find.descendant(
          of: find.byType(TransactionHomePage),
          matching: find.byKey(const ValueKey('header-notification-button')),
        ),
      );
      await tester.pump();
      await tester.pump();
      final notificationsElement = tester.element(
        find.byType(NotificationsPage),
      );
      await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
      await tester.pump();
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(TransactionHomePage),
          matching: find.byKey(const ValueKey('header-notification-button')),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.element(find.byType(NotificationsPage)),
        same(notificationsElement),
      );
      await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('bottom-nav-stats')));
      await tester.pump();
      await tester.pump();
      expect(tester.element(find.byType(StatsPage)), same(statsElement));

      await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
      await tester.pump();
      await tester.pump();
      expect(tester.element(find.byType(SettingsPage)), same(settingsElement));
    },
  );
}

class _TrackingTransactionStore extends TransactionStore {
  _TrackingTransactionStore(super.repository, {required super.clock});

  var visibleDisplayLogEntryReads = 0;
  var visibleTransactionReads = 0;

  void resetVisibleReads() {
    visibleDisplayLogEntryReads = 0;
    visibleTransactionReads = 0;
  }

  @override
  List<TransactionLogEntry> get visibleDisplayLogEntries {
    visibleDisplayLogEntryReads += 1;
    return super.visibleDisplayLogEntries;
  }

  @override
  List<TransactionRecord> get visibleTransactions {
    visibleTransactionReads += 1;
    return super.visibleTransactions;
  }
}

class _TrackingEventStore extends EventStore {
  _TrackingEventStore(super.bridge) : super(realtimeEnabled: false);

  var shellPersistenceWrites = 0;

  @override
  void setShellActiveTabKey(String key) {
    shellPersistenceWrites += 1;
    super.setShellActiveTabKey(key);
  }
}

class _ControlledStatsFrameWorker implements StatsRenderFrameWorker {
  final requests = <StatsRenderFrameRequest>[];
  final _completers = <Completer<StatsRenderFrame>>[];

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) {
    requests.add(request);
    final completer = Completer<StatsRenderFrame>();
    _completers.add(completer);
    return completer.future;
  }

  void complete(int index) {
    _completers[index].complete(requests[index].buildSynchronously());
  }
}

class _ImmediateStatsFrameWorker implements StatsRenderFrameWorker {
  const _ImmediateStatsFrameWorker();

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) async {
    return StatsRenderFrame.build(
      year: request.year,
      month: request.month,
      activeType: request.activeType,
      thresholdValue: request.thresholdValue,
      transactions: const <TransactionRecord>[],
      categories: request.categories,
      selectedCategoryIds: request.selectedCategoryIds,
      vendorFilters: request.vendorFilters,
      summaryScope: request.summaryScope,
      query: request.query,
      today: request.today,
    );
  }
}

class _HighVolumeRepository extends TransactionRepositoryContract {
  _HighVolumeRepository()
    : categories = [
        _categoryMap(1, 'Expense', TransactionType.expense),
        _categoryMap(2, 'Income', TransactionType.income),
      ].map(TransactionCategory.fromMap).toList(),
      transactions = _transactionMaps().map(TransactionRecord.fromMap).toList();

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: const [],
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async => TransactionPage(
    transactions: transactions,
    totalCount: transactions.length,
    limit: query.limit,
    offset: query.offset,
  );

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) =>
      throw UnimplementedError();

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteTransaction(int id) => throw UnimplementedError();

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) =>
      throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) => throw UnimplementedError();

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => const {1: 3000, 2: 3000};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => const [];

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) =>
      throw UnimplementedError();
}

Future<Object?> _shellMethodHandler(MethodCall call) async {
  return switch (call.method) {
    'expenseLoadBootstrap' => <String, Object?>{
      'categories': [
        _categoryMap(1, 'Expense', TransactionType.expense),
        _categoryMap(2, 'Income', TransactionType.income),
      ],
      'transactions': _transactionMaps(),
      'limits': <Object?>[],
      'recurringGhostTransactions': <Object?>[],
    },
    'expenseLoadSettings' => <String, Object?>{},
    'expenseListNotificationCards' ||
    'expenseListStatsSnapshots' ||
    'expenseListRecurringRules' ||
    'expenseListRecurringTransactions' => <Object?>[],
    'requestPostNotificationsOnFirstLaunch' => false,
    _ => null,
  };
}

Future<Object?> _smallShellMethodHandler(MethodCall call) async {
  return switch (call.method) {
    'expenseLoadBootstrap' => <String, Object?>{
      'categories': [
        _categoryMap(1, 'Expense', TransactionType.expense),
        _categoryMap(2, 'Income', TransactionType.income),
      ],
      'transactions': <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'date': '2026.07.01',
          'time': '10:00',
          'merchant': 'Expense merchant',
          'amount': -12000,
          'userAssignedName': null,
          'transactionCategoryID': 1,
        },
        <String, Object?>{
          'id': 2,
          'date': '2026.07.02',
          'time': '10:00',
          'merchant': 'Income merchant',
          'amount': 18000,
          'userAssignedName': null,
          'transactionCategoryID': 2,
        },
      ],
      'limits': <Object?>[],
      'recurringGhostTransactions': <Object?>[],
    },
    'expenseLoadSettings' => <String, Object?>{},
    'expenseListNotificationCards' ||
    'expenseListStatsSnapshots' ||
    'expenseListRecurringRules' ||
    'expenseListRecurringTransactions' => <Object?>[],
    'requestPostNotificationsOnFirstLaunch' => false,
    _ => null,
  };
}

Map<String, Object?> _categoryMap(int id, String name, TransactionType type) =>
    <String, Object?>{
      'transactionCategoryID': id,
      'name': name,
      'type': type.hungarianValue,
      'colorSlot': id,
      'iconSlot': 0,
      'backgroundColor': type == TransactionType.income ? '#16a34a' : '#dc2626',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    };

List<Map<String, Object?>> _transactionMaps() =>
    List<Map<String, Object?>>.generate(6000, (index) {
      final income = index.isEven;
      final day = (index % 28) + 1;
      return <String, Object?>{
        'id': 100000 + index,
        'date': '2026.07.${day.toString().padLeft(2, '0')}',
        'time': '10:00',
        'merchant': 'Merchant ${index % 40}',
        'amount': income ? 1000 + index : -(1000 + index),
        'userAssignedName': null,
        'transactionCategoryID': income ? 2 : 1,
      };
    });
