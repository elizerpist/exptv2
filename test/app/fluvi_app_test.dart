import 'dart:async';

import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/app/shell/fluvi_bottom_navigation.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/shared/presentation/fluvi_slide_up_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the fixed Fluvi dashboard shell', (tester) async {
    await tester.pumpWidget(
      const FluviApp(
        dashboardRepository: EmptyDashboardDataRuntimeRepository(),
      ),
    );
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsOneWidget,
    );
    expect(find.text('—'), findsNothing);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.byType(Bnb03BottomNavigation), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fluvi-fullscreen-button')),
      findsOneWidget,
    );
  });

  testWidgets('cold bootstrap reaches an interactive dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FluviApp(
        dashboardRepository: EmptyDashboardDataRuntimeRepository(),
      ),
    );

    for (var frame = 0; frame < 40; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find
          .byKey(const ValueKey('dashboard-bootstrap-surface'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsNothing,
    );
    final gate = tester.widget<AbsorbPointer>(
      find.byKey(const ValueKey('dashboard-interaction-readiness-gate')),
    );
    expect(gate.absorbing, isFalse);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
  });

  testWidgets('normal app stays idle without an automated scenario runner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FluviApp(
        dashboardRepository: EmptyDashboardDataRuntimeRepository(),
      ),
    );

    for (var frame = 0; frame < 40; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find
          .byKey(const ValueKey('dashboard-bootstrap-surface'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }
    final beforeIdle = tester.getCenter(
      find.byKey(const ValueKey('core-dashboard')),
    );
    await tester.pump(const Duration(seconds: 10));

    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('core-dashboard'))),
      beforeIdle,
    );
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsNothing,
    );
  });

  testWidgets('bootstrap failure replaces the spinner and retry can recover', (
    tester,
  ) async {
    final repository = _FailOnceDashboardRepository();
    await tester.pumpWidget(FluviApp(dashboardRepository: repository));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-failure-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-bootstrap-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(repository.prepareCount, 2);
  });

  testWidgets(
    'Query opens with the visible expense direction and closes after Apply',
    (tester) async {
      const queryChannel = MethodChannel('com.fluvi/query_menu');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Map<Object?, Object?>? facetArguments;
      messenger.setMockMethodCallHandler(queryChannel, (call) async {
        if (call.method == 'readQueryMenuFacets') {
          facetArguments = call.arguments! as Map<Object?, Object?>;
          return _queryMenuFacetsResponse();
        }
        if (call.method == 'listSavedQueries') return const <Object?>[];
        throw PlatformException(code: 'unexpected', message: call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(queryChannel, null));

      await tester.pumpWidget(
        const FluviApp(
          dashboardRepository: EmptyDashboardDataRuntimeRepository(),
          initialDirection: LedgerDirection.expense,
        ),
      );
      await _pumpInteractiveDashboard(tester);

      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsOneWidget);
      expect(facetArguments?['direction'], 'expense');
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const ValueKey('query-menu-apply')));
      await _pumpUntilSheetClosed(tester);

      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsNothing);
    },
  );

  testWidgets(
    'a failed Query Apply leaves the sheet open and a retry can publish',
    (tester) async {
      const queryChannel = MethodChannel('com.fluvi/query_menu');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(queryChannel, (call) async {
        if (call.method == 'readQueryMenuFacets') {
          return _queryMenuFacetsResponse();
        }
        if (call.method == 'listSavedQueries') {
          return const <Object?>[];
        }
        throw PlatformException(code: 'unexpected', message: call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(queryChannel, null));
      final repository = _FailFirstQueryDashboardRepository();

      await tester.pumpWidget(FluviApp(dashboardRepository: repository));
      await _pumpInteractiveDashboard(tester);
      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.tap(find.text('Aktuális hónap'));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const ValueKey('query-menu-apply')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(repository.queryPrepareCount, 1);
      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const ValueKey('query-menu-apply')));
      await _pumpUntilSheetClosed(tester);

      expect(repository.queryPrepareCount, 2);
      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsNothing);
    },
  );

  testWidgets(
    'closing and reopening the Query sheet does not inherit an old applying state',
    (tester) async {
      const queryChannel = MethodChannel('com.fluvi/query_menu');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(queryChannel, (call) async {
        if (call.method == 'readQueryMenuFacets') {
          return _queryMenuFacetsResponse();
        }
        if (call.method == 'listSavedQueries') return const <Object?>[];
        throw PlatformException(code: 'unexpected', message: call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(queryChannel, null));
      final repository = _BlockingQueryDashboardRepository();
      await tester.pumpWidget(FluviApp(dashboardRepository: repository));
      await _pumpInteractiveDashboard(tester);

      await tester.tap(find.text('Search'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Aktuális hónap'));
      await tester.tap(find.byKey(const ValueKey('query-menu-apply')));
      await tester.pump();
      expect(repository.queryPrepareCount, 1);

      await tester.tap(find.byKey(const ValueKey('query-menu-close')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Search'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
            .onPressed,
        isNotNull,
      );
      repository.completeQueryPreparation();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        tester.widget<FluviSlideUpSheet>(find.byType(FluviSlideUpSheet)).isOpen,
        isTrue,
      );
    },
  );

  testWidgets('BNB keeps the purple outer ring separate from the FAB core', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Bnb03BottomNavigation(
          selected: Bnb03Item.home,
          onChanged: (_) {},
        ),
      ),
    );

    final ring = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
    );

    expect(ring.painter, isA<CustomPainter>());
    expect(ring.child, isA<Padding>());

    final fabCore = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bnb03-fab-core')),
    );

    expect(fabCore.painter, isA<CustomPainter>());
    expect(fabCore.child, isA<Center>());
  });

  testWidgets('paints the bottom system inset white behind the navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 800),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: const FluviApp(
          dashboardRepository: EmptyDashboardDataRuntimeRepository(),
        ),
      ),
    );

    final background = find.byKey(
      const ValueKey('fluvi-bottom-safe-area-background'),
    );

    expect(background, findsOneWidget);
    expect(tester.widget<ColoredBox>(background).color, Colors.white);
    expect(tester.getRect(background).height, closeTo(48, 0.001));
  });

  testWidgets('keeps the raised center action inside the reserved nav area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 412,
            height: FluviVisualTokens.navigationHeight,
            child: FluviBottomNavigation(onDashboardTap: () {}),
          ),
        ),
      ),
    );

    final navigation = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
    );
    final centerAction = tester.getRect(
      find.byKey(const ValueKey('fluvi-center-fab')),
    );

    expect(navigation.height, greaterThanOrEqualTo(110));
    expect(navigation.height, lessThanOrEqualTo(144));
    expect(centerAction.width, closeTo(64, 0.001));
    expect(centerAction.height, closeTo(64, 0.001));
    expect(centerAction.top - navigation.top, closeTo(10, 2));
    expect(centerAction.left, greaterThanOrEqualTo(navigation.left));
    expect(centerAction.right, lessThanOrEqualTo(navigation.right));
    expect(centerAction.top, greaterThanOrEqualTo(navigation.top));
    expect(centerAction.bottom, lessThanOrEqualTo(navigation.bottom));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is FluviConvexCenterBottomNavigationPainter,
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpInteractiveDashboard(WidgetTester tester) async {
  for (var frame = 0; frame < 40; frame += 1) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find
        .byKey(const ValueKey('dashboard-bootstrap-surface'))
        .evaluate()
        .isEmpty) {
      return;
    }
  }
  fail('Dashboard did not become interactive.');
}

Future<void> _pumpUntilSheetClosed(WidgetTester tester) async {
  // Query publication intentionally waits for the replacement complete scene
  // bank. Empty widget-test data still has the full bounded rail catalog, so
  // its cooperative scene preparation spans more than a short animation.
  for (var frame = 0; frame < 420; frame += 1) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byKey(FluviSlideUpSheet.sheetKey).evaluate().isEmpty) return;
  }
  final shell = find.byType(FluviSlideUpSheet).evaluate().isEmpty
      ? null
      : tester.widget<FluviSlideUpSheet>(find.byType(FluviSlideUpSheet));
  final diagnostics = FluviDiagnosticLogger.entries
      .map((event) => event.toLine())
      .join('\n');
  fail(
    'Query sheet did not close after a successful Apply publication. '
    'sheetIsOpen=${shell?.isOpen}; diagnostics:\n$diagnostics',
  );
}

Map<String, Object?> _queryMenuFacetsResponse() => <String, Object?>{
  'result': <String, Object?>{'entryCount': 26, 'amountScaled100': 123000},
  'amountDomain': <String, Object?>{
    'minimumAmountScaled100': 0,
    'maximumAmountScaled100': 123000,
  },
  'availableMonths': const <Object?>[
    <String, Object?>{'year': 2025, 'month': 7},
  ],
  'categories': const <Object?>[],
  'partners': const <Object?>[],
};

final class _FailOnceDashboardRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  int prepareCount = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    prepareCount += 1;
    if (prepareCount == 1) {
      return Future<PreparedDashboardIndex>.error(
        StateError('synthetic bootstrap failure'),
      );
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _FailFirstQueryDashboardRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPrepareCount = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryPrepareCount += 1;
      if (queryPrepareCount == 1) {
        return Future<PreparedDashboardIndex>.error(
          StateError('synthetic query preparation failure'),
        );
      }
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _BlockingQueryDashboardRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final Completer<void> _releaseQuery = Completer<void>();
  var queryPrepareCount = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    final index = await _empty.prepareIndex(request, token);
    if (request.reason == DataAcquisitionReason.query) {
      queryPrepareCount += 1;
      await _releaseQuery.future;
    }
    return index;
  }

  void completeQueryPreparation() {
    if (!_releaseQuery.isCompleted) _releaseQuery.complete();
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}
