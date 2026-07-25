import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_transaction_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    '600-row production Balance log stays lazy, cached, and singly paged '
    'through 10 collapse cycles',
    (tester) async {
      tester.view
        ..physicalSize = const Size(412, 892)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _PerformanceRepository(recordCount: 600);
      final store = _CountingTransactionStore(
        repository,
        clock: () => DateTime(2026, 7, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();

      expect(store.transactions, hasLength(600));
      final initialStoreSnapshot = store.balanceVisibleDisplayLogEntries;
      expect(initialStoreSnapshot, hasLength(97));
      expect(
        initialStoreSnapshot.where((entry) => !entry.isHeader),
        hasLength(TransactionStore.visibleDisplayLogPageSize),
      );
      expect(store.balanceVisibleDisplayLogEntryTotalCount, 601);
      expect(store.hasMoreBalanceVisibleDisplayLogEntries, isTrue);

      var inputBuilds = 0;
      var logBuilderCalls = 0;
      var logProbeBuilds = 0;
      var loadMoreCalls = 0;
      BalanceRenderFrame? latestFrame;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 892),
              disableAnimations: true,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  inputBuilds += 1;
                  return SpendeeBalanceDashboard(
                    input: BalanceFrameInput.fromStore(store),
                    brand: const SizedBox(
                      key: ValueKey('balance-performance-brand'),
                      width: 300,
                      height: 60,
                    ),
                    transactionLogBuilder: (context, frame) {
                      logBuilderCalls += 1;
                      latestFrame = frame;
                      return _BuildProbe(
                        onBuild: () => logProbeBuilds += 1,
                        child: SpendeeBalanceTransactionLog(
                          groups: frame.logGroups,
                          categoriesById: store.categoriesById,
                          queryKey:
                              '${frame.query.activeType.name}:'
                              '${frame.visibleLogRowCount}',
                          hasMore: frame.hasMoreLogEntries,
                          onLoadMore: () {
                            loadMoreCalls += 1;
                            store.loadMoreBalanceVisibleDisplayLogEntries();
                          },
                          onFastFilter: (_, _) {},
                          onRecordTap: (_) {},
                          onDeleteRequested: (_) => false,
                          onCategoryFilter: (_) {},
                          onEditTransaction: (_) {},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(inputBuilds, 1);
      expect(logBuilderCalls, 1);
      expect(logProbeBuilds, 1);
      expect(latestFrame?.visibleLogRowCount, 96);
      expect(latestFrame?.totalLogEntryCount, 601);
      expect(latestFrame?.hasMoreLogEntries, isTrue);

      final viewport = find.byKey(
        const ValueKey('spendee-balance-transaction-viewport'),
      );
      final scrollView = tester.widget<CustomScrollView>(
        find.descendant(of: viewport, matching: find.byType(CustomScrollView)),
      );
      expect(scrollView.cacheExtent, SpendeeBalanceTransactionLog.cacheExtent);
      expect(_mountedProductionRows(), inInclusiveRange(1, 18));
      expect(
        _mountedProductionRows(),
        lessThan(TransactionStore.visibleDisplayLogPageSize),
        reason: 'The production sliver must not eagerly mount the first page.',
      );

      final initialLogGroups = latestFrame!.logGroups;
      final snapshotReadsBeforeCollapse = store.balanceSnapshotReads;
      final collapseHandle = find.byKey(
        const ValueKey('spendee-balance-collapse-handle'),
      );
      for (var cycle = 0; cycle < 10; cycle += 1) {
        await tester.tap(collapseHandle);
        await tester.pump();
        await tester.tap(collapseHandle);
        await tester.pump();
      }

      expect(inputBuilds, 1);
      expect(store.balanceSnapshotReads, snapshotReadsBeforeCollapse);
      expect(logBuilderCalls, 1);
      expect(logProbeBuilds, 1);
      expect(identical(latestFrame!.logGroups, initialLogGroups), isTrue);
      expect(
        identical(store.balanceVisibleDisplayLogEntries, initialStoreSnapshot),
        isTrue,
      );
      expect(_mountedProductionRows(), inInclusiveRange(1, 18));

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: viewport, matching: find.byType(Scrollable)),
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      ScrollEndNotification(
        metrics: scrollable.position,
        context: scrollable.context,
      ).dispatch(scrollable.context);
      await tester.pump();
      await tester.pump();

      expect(loadMoreCalls, 1);
      expect(inputBuilds, 2);
      expect(logBuilderCalls, 2);
      expect(logProbeBuilds, 2);
      expect(latestFrame?.visibleLogRowCount, 192);
      expect(latestFrame?.totalLogEntryCount, 601);
      expect(latestFrame?.hasMoreLogEntries, isTrue);
      expect(
        store.balanceVisibleDisplayLogEntries.where((entry) => !entry.isHeader),
        hasLength(192),
      );
      expect(_mountedProductionRows(), inInclusiveRange(1, 18));

      ScrollEndNotification(
        metrics: scrollable.position,
        context: scrollable.context,
      ).dispatch(scrollable.context);
      await tester.pump();
      await tester.pump();
      expect(
        loadMoreCalls,
        1,
        reason: 'One near-end generation may request only one additional page.',
      );
    },
  );

  testWidgets('unchanged parent rebuild reuses the resolved Balance frame', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 892)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = TransactionStore(
      _PerformanceRepository(recordCount: 24),
      clock: () => DateTime(2026, 7, 25, 12),
    );
    final hostRebuild = ValueNotifier<int>(0);
    addTearDown(store.dispose);
    addTearDown(hostRebuild.dispose);
    await store.start();
    var logBuilderCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: hostRebuild,
          builder: (context, _) {
            return Scaffold(
              body: Stack(
                children: [
                  SpendeeBalanceDashboard(
                    input: BalanceFrameInput.fromStore(store),
                    brand: const SizedBox(),
                    transactionLogRevision: const ValueKey(
                      'stable-log-dependencies',
                    ),
                    transactionLogBuilder: (context, frame) {
                      logBuilderCalls += 1;
                      return const SizedBox();
                    },
                  ),
                  Offstage(child: Text('${hostRebuild.value}')),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(logBuilderCalls, 1);

    hostRebuild.value += 1;
    await tester.pump();

    expect(
      logBuilderCalls,
      1,
      reason: 'An unchanged store revision must reuse the typed frame.',
    );
  });
}

int _mountedProductionRows() {
  return find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'spendee-balance-transaction-row-record-',
            ),
      )
      .evaluate()
      .length;
}

class _BuildProbe extends StatelessWidget {
  const _BuildProbe({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

class _CountingTransactionStore extends TransactionStore {
  _CountingTransactionStore(super.repository, {required super.clock});

  int balanceSnapshotReads = 0;

  @override
  List<TransactionLogEntry> get balanceVisibleDisplayLogEntries {
    balanceSnapshotReads += 1;
    return super.balanceVisibleDisplayLogEntries;
  }
}

class _PerformanceRepository implements TransactionRepositoryContract {
  _PerformanceRepository({required int recordCount})
    : _transactions = List<TransactionRecord>.generate(
        recordCount,
        (index) => TransactionRecord(
          id: index + 1,
          date: '2026.07.25.',
          time:
              '${(index % 24).toString().padLeft(2, '0')}:'
              '${(index % 60).toString().padLeft(2, '0')}',
          latitude: null,
          longitude: null,
          address: null,
          merchant: 'Valós kereskedő ${index % 12}',
          amount: -(100 + index).toDouble(),
          userAssignedName: null,
          transactionCategoryID: 7,
        ),
        growable: false,
      );

  static final _category = TransactionCategory.fromMap({
    'transactionCategoryID': 7,
    'name': 'Élelmiszer',
    'type': 'kiadás',
    'colorSlot': 3,
    'iconSlot': 1,
    'backgroundColor': '#ff4b78',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': false,
  });

  final List<TransactionRecord> _transactions;

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    return TransactionBootstrap(
      categories: [_category],
      transactions: _transactions,
      limits: const [],
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'Unexpected repository call: ${invocation.memberName}',
    );
  }
}
