import 'dart:io';

import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production dashboard renders typed frame values without metric math',
    () {
      final source = File(
        'lib/features/transactions/widgets/experimental/balance/'
        'spendee_balance_dashboard.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('sourceMetric')));
      expect(source, isNot(contains('fastInfoMetrics[')));
      expect(source, isNot(contains('.visual.values')));
    },
  );

  void configureReferenceViewport(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(412, 892)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget host(
    BalanceFrameInput input, {
    ValueChanged<TransactionType>? onTypeChanged,
    ValueChanged<String>? onQueryChanged,
    ValueChanged<BalanceTimeScopeOption>? onScopeSelected,
    VoidCallback? onFilterPressed,
    VoidCallback? onSummaryTap,
    VoidCallback? onSummaryReset,
    ValueChanged<int>? onShiftPeriod,
    VoidCallback? onCycleSummary,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(412, 892)),
        child: Scaffold(
          body: SpendeeBalanceDashboard(
            input: input,
            brand: const SizedBox(
              key: ValueKey('balance-test-brand'),
              width: 300,
              height: 60,
            ),
            menuButton: const SizedBox(
              key: ValueKey('balance-test-menu'),
              width: 37,
              height: 37,
            ),
            onTypeChanged: onTypeChanged,
            onQueryChanged: onQueryChanged,
            onScopeSelected: onScopeSelected,
            onFilterPressed: onFilterPressed,
            onSummaryTap: onSummaryTap,
            onSummaryReset: onSummaryReset,
            onShiftPeriod: onShiftPeriod,
            onCycleSummary: onCycleSummary,
            transactionLogBuilder: (context, frame) => SizedBox(
              key: const ValueKey('balance-test-log'),
              width: 378,
              height: 407,
              child: Text('${frame.visibleLogRowCount} log rows'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('expanded screen freezes every B3M-A3 authored y coordinate', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    await tester.pumpWidget(host(_input()));
    await tester.pump();

    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-hero'))),
      const Rect.fromLTWH(17, 104, 378, 126),
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
      ),
      const Rect.fromLTWH(17, 241, 378, 104),
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey('spendee-balance-detail-stage')),
      ),
      const Rect.fromLTWH(17, 356, 378, 186),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-actions'))),
      const Rect.fromLTWH(17, 553, 378, 42),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-summary'))),
      const Rect.fromLTWH(17, 606, 378, 59),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-search-row'))),
      const Rect.fromLTWH(17, 676, 378, 39),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-time-rail'))),
      const Rect.fromLTWH(17, 726, 378, 79),
    );
    expect(find.text('Aktuális hónap'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-balance-focus-traversal')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-balance-summary')),
        matching: find.text('-350 000 Ft'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('balance-test-brand')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-test-menu')), findsOneWidget);
  });

  testWidgets('handle follows the 180px path and snaps to collapsed layout', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    await tester.pumpWidget(host(_input()));
    await tester.pump();

    final handle = find.byKey(
      const ValueKey('spendee-balance-collapse-handle'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('spendee-balance-hero'))).height,
      104,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('spendee-balance-actions')))
          .dy,
      closeTo(219, .01),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('spendee-balance-summary')))
          .dy,
      closeTo(272, .01),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('spendee-balance-search-row')))
          .dy,
      closeTo(342, .01),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('spendee-balance-time-rail')))
          .dy,
      closeTo(392, .01),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('balance-test-log'))).dy,
      closeTo(482, .01),
    );
    final insightOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('spendee-balance-insight-opacity')),
    );
    final detailOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('spendee-balance-detail-opacity')),
    );
    expect(insightOpacity.opacity, 0);
    expect(detailOpacity.opacity, 0);
    final hiddenInsightFocus = tester.widgetList<ExcludeFocus>(
      find.ancestor(
        of: find.byKey(
          const ValueKey('spendee-balance-fast-info-ghost-no-spend'),
        ),
        matching: find.byType(ExcludeFocus),
      ),
    );
    final hiddenDetailFocus = tester.widgetList<ExcludeFocus>(
      find.ancestor(
        of: find.byKey(
          const ValueKey('spendee-balance-detail-ghost-variable-budget'),
        ),
        matching: find.byType(ExcludeFocus),
      ),
    );
    expect(hiddenInsightFocus.any((widget) => widget.excluding), isTrue);
    expect(hiddenDetailFocus.map((widget) => widget.excluding), contains(true));
    expect(find.byKey(const ValueKey('balance-test-log')), findsOneWidget);
  });

  testWidgets('four-pixel handle drag snaps back instead of toggling', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    await tester.pumpWidget(host(_input()));
    await tester.pump();

    final handle = find.byKey(
      const ValueKey('spendee-balance-collapse-handle'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, -4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('spendee-balance-hero'))).height,
      126,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('spendee-balance-actions')))
          .dy,
      553,
    );
  });

  testWidgets(
    'vertical swipe on the action row collapses the content above rail',
    (tester) async {
      configureReferenceViewport(tester);
      await tester.pumpWidget(host(_input()));
      await tester.pump();

      final actionRegion = find.byKey(
        const ValueKey('spendee-balance-action-collapse-region'),
      );
      final gesture = await tester.startGesture(tester.getCenter(actionRegion));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(const ValueKey('spendee-balance-hero')))
            .height,
        104,
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('spendee-balance-actions')))
            .dy,
        closeTo(219, .01),
      );
    },
  );

  testWidgets('live budget adapter keeps every frozen dimension label', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    await tester.pumpWidget(host(_input()));
    await tester.pump();

    expect(find.text('30 napos napi átlag: 11 667 Ft'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-budget-dimension-week')),
    );
    await tester.pump();
    expect(find.text('A héten még elkölthető'), findsOneWidget);
    expect(find.text('Héten elköltve'), findsOneWidget);
    expect(find.text('Felhasználva: 0%'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-budget-dimension-month')),
    );
    await tester.pump();
    expect(find.text('Ebben a hónapban még elkölthető'), findsOneWidget);
    expect(find.text('Hónapban elköltve'), findsOneWidget);
    expect(find.text('Felhasználva: 0%'), findsOneWidget);
  });

  testWidgets('log cache invalidates explicit builder dependencies', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    var logBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: revision,
            builder: (context, _) => SpendeeBalanceDashboard(
              input: _input(),
              brand: const SizedBox(),
              transactionLogRevision: revision.value,
              transactionLogBuilder: (context, frame) {
                logBuilds += 1;
                return Text('log revision ${revision.value}');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(logBuilds, 1);
    expect(find.text('log revision 0'), findsOneWidget);

    revision.value = 1;
    await tester.pump();

    expect(logBuilds, 2);
    expect(find.text('log revision 1'), findsOneWidget);
    expect(find.text('log revision 0'), findsNothing);
  });

  testWidgets('in-flight empty month keeps the complete rail label', (
    tester,
  ) async {
    configureReferenceViewport(tester);
    await tester.pumpWidget(
      host(
        _input(
          summaryReferenceDate: DateTime(2026, 8),
          ghostProjectionInFlight: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HÓNAP FINOMÍTÁS'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-balance-time-rail')),
        matching: find.text('Augusztus 2026'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'production callbacks keep action query filter scope and summary',
    (tester) async {
      configureReferenceViewport(tester);
      TransactionType? type;
      var query = '';
      var filters = 0;
      BalanceTimeScopeOption? scope;
      var summaryTaps = 0;
      var summaryResets = 0;
      var cycles = 0;
      final shifts = <int>[];

      await tester.pumpWidget(
        host(
          _input(),
          onTypeChanged: (value) => type = value,
          onQueryChanged: (value) => query = value,
          onFilterPressed: () => filters += 1,
          onScopeSelected: (value) => scope = value,
          onSummaryTap: () => summaryTaps += 1,
          onSummaryReset: () => summaryResets += 1,
          onShiftPeriod: shifts.add,
          onCycleSummary: () => cycles += 1,
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-income-action')),
      );
      await tester.enterText(find.byType(TextField), 'lidl');
      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-filter-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-year-pill-2026-06')),
      );
      await tester.pumpAndSettle();

      expect(type, TransactionType.income);
      expect(query, 'lidl');
      expect(filters, 1);
      expect(scope?.key, '2026-06');

      final summary = find.byKey(const ValueKey('spendee-balance-summary'));
      await tester.tap(summary);
      await tester.pump(const Duration(milliseconds: 350));
      expect(summaryTaps, 1);

      await tester.tap(summary);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(summary);
      await tester.pumpAndSettle();
      expect(summaryResets, 1);
      expect(shifts, isEmpty);
      expect(cycles, 0);
    },
  );
}

BalanceFrameInput _input({
  DateTime? summaryReferenceDate,
  bool ghostProjectionInFlight = false,
}) {
  const expense = TransactionCategory(
    transactionCategoryID: 1,
    name: 'Élelmiszer',
    type: 'expense',
    colorSlot: 1,
    iconSlot: 1,
    backgroundColor: '#FF4B78',
    icon: null,
    notification: null,
    hasLimit: true,
    limitAmount: 500000,
    alertActive: true,
    isCustomIcon: false,
    originalIcon: null,
  );
  const income = TransactionCategory(
    transactionCategoryID: 2,
    name: 'Fizetés',
    type: 'income',
    colorSlot: 2,
    iconSlot: 16,
    backgroundColor: '#42CF82',
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
  return BalanceFrameInput(
    now: DateTime(2026, 7, 25),
    activeType: TransactionType.expense,
    summaryWindow: SummaryWindow.monthly,
    summaryReferenceDate: summaryReferenceDate ?? DateTime(2026, 7),
    transactions: const [
      TransactionRecord(
        id: 1,
        date: '2026-07-25',
        time: '11:42',
        latitude: null,
        longitude: null,
        address: null,
        merchant: 'Lidl',
        amount: -350000,
        userAssignedName: null,
        transactionCategoryID: 1,
      ),
      TransactionRecord(
        id: 2,
        date: '2026-06-25',
        time: '09:15',
        latitude: null,
        longitude: null,
        address: null,
        merchant: 'Auchan',
        amount: -150000,
        userAssignedName: null,
        transactionCategoryID: 1,
      ),
      TransactionRecord(
        id: 3,
        date: '2026-07-01',
        time: '08:00',
        latitude: null,
        longitude: null,
        address: null,
        merchant: 'Munkabér',
        amount: 1000000,
        userAssignedName: null,
        transactionCategoryID: 2,
      ),
    ],
    recurringGhosts: const [],
    categories: const [expense, income],
    limits: const [],
    ghostProjectionInFlight: ghostProjectionInFlight,
  );
}
