import 'dart:async';

import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/fluvi_app_shell.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/app/shell/fluvi_bottom_navigation.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/categories/domain/category_repository.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/shared/presentation/fluvi_slide_up_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const categoryChannel = MethodChannel('com.fluvi/category_repository');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(categoryChannel, (call) async {
      if (call.method == 'getCategories') return const <Object?>[];
      throw PlatformException(code: 'unexpected', message: call.method);
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(categoryChannel, null));

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

  testWidgets(
    'RED: a healthy first cold bootstrap has one traced startup attempt and reaches READY without Retry',
    (tester) async {
      FluviDiagnosticLogger.clear();
      await tester.pumpWidget(
        const FluviApp(
          dashboardRepository: EmptyDashboardDataRuntimeRepository(),
        ),
      );
      await _pumpInteractiveDashboard(tester);

      final starts = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'DASHBOARD_STARTUP_ATTEMPT_STARTED')
          .toList(growable: false);
      final ready = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'DASHBOARD_STARTUP_READY')
          .toList(growable: false);
      final failed = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'DASHBOARD_STARTUP_STAGE_FAILED')
          .toList(growable: false);

      expect(starts, hasLength(1));
      expect(starts.single.scope, contains('attemptGeneration=1'));
      expect(ready, hasLength(1));
      expect(failed, isEmpty);
      expect(
        find.byKey(const ValueKey('dashboard-bootstrap-retry')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Budget shows the category inventory after cold bootstrap without Query Menu',
    (tester) async {
      messenger.setMockMethodCallHandler(categoryChannel, (call) async {
        if (call.method == 'getCategories') return _categoryInventoryResponse();
        throw PlatformException(code: 'unexpected', message: call.method);
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(categoryChannel, null),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: FluviAppShell(
            mode: DashboardModeSpec.budget,
            dashboardRepository: EmptyDashboardDataRuntimeRepository(),
          ),
        ),
      );
      await _pumpInteractiveDashboard(tester);
      // The centered-carousel's initial semantic anchor is scheduled from
      // its first layout; let that explicit post-layout hand-off run before
      // asserting the selected avatar rather than treating the pre-anchor
      // physical slot as the semantic centre.
      await tester.pump();

      expect(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-target-avatar-center')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'root category collection is ready before the Budget dashboard mounts',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final categories = _CountingCategoryRepository(_categoryInventory());
      addTearDown(categories.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: FluviAppShell(
            mode: DashboardModeSpec.budget,
            dashboardRepository: const EmptyDashboardDataRuntimeRepository(),
            categoryRepository: categories,
          ),
        ),
      );
      await _pumpInteractiveDashboard(tester);

      expect(categories.watchCalls, 1);
      expect(categories.getCalls, 0);
      expect(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        findsOneWidget,
      );
      final carousel = find.byKey(
        const ValueKey('budget-target-avatar-carousel'),
      );
      await tester.fling(
        find.descendant(of: carousel, matching: find.byType(ListView)),
        const Offset(-420, 0),
        2200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fluvi-expense-button')));
      await tester.pump();
      expect(carousel, findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
        const Offset(-260, 0),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-mind')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
        const Offset(260, 0),
      );
      await tester.pump();
      expect(carousel, findsOneWidget);

      expect(categories.watchCalls, 1);
      expect(categories.getCalls, 0);
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'CATEGORY_COLLECTION_READY')
            .entryCount,
        2,
      );
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere(
              (event) => event.stage == 'BUDGET_CATEGORY_RAIL_INPUT_UPDATED',
            )
            .entryCount,
        2,
      );
    },
  );

  testWidgets(
    'a category bootstrap error reaches the existing failure surface',
    (tester) async {
      FluviDiagnosticLogger.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: FluviAppShell(
            dashboardRepository: const EmptyDashboardDataRuntimeRepository(),
            categoryRepository: const _FailingCategoryRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('dashboard-bootstrap-failure-surface')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('core-dashboard')), findsNothing);
      final startupFailure = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'DASHBOARD_STARTUP_STAGE_FAILED',
      );
      expect(startupFailure.scope, contains('attemptGeneration=1'));
      expect(startupFailure.scope, contains('stage=categoryCollection'));
      expect(startupFailure.error, contains('StateError'));
      expect(startupFailure.error, contains('category bridge unavailable'));
    },
  );

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
    'a failed staged Query candidate keeps the sheet open and a new session can retry',
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
      expect(
        tester.widget<FluviSlideUpSheet>(find.byType(FluviSlideUpSheet)).isOpen,
        isTrue,
        reason:
            'A failed staged candidate must not dismiss onto the old dashboard.',
      );
      await tester.tap(find.byKey(const ValueKey('query-menu-close')));
      await _pumpUntilSheetClosed(tester);

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
      await _pumpUntilSheetClosed(tester);

      // The retry stages one new candidate. Its successful restrictive Query
      // may then begin the bounded clear-chip neighbour prewarm, so this is
      // intentionally not an exact total-work assertion.
      expect(repository.queryPrepareCount, greaterThanOrEqualTo(2));
      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsNothing);
    },
  );

  testWidgets(
    'an accepted Query Apply waits behind its staged candidate before dismissal',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(800, 1280));
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
      addTearDown(repository.completeQueryPreparation);

      await tester.pumpWidget(FluviApp(dashboardRepository: repository));
      await _pumpInteractiveDashboard(tester);
      await tester.tap(find.text('Search'));
      await tester.pump(const Duration(milliseconds: 300));
      tester
          .widget<TextButton>(
            find
                .ancestor(
                  of: find.text('Aktuális hónap'),
                  matching: find.byType(TextButton),
                )
                .first,
          )
          .onPressed!();
      await tester.pump();

      tester
          .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
          .onPressed!();
      await tester.pump();

      expect(repository.queryPrepareCount, 1);
      expect(
        tester.widget<FluviSlideUpSheet>(find.byType(FluviSlideUpSheet)).isOpen,
        isTrue,
        reason:
            'The sheet may only dismiss after the exact staged revision can '
            'atomically replace the old dashboard.',
      );
      repository.completeQueryPreparation();
      await _pumpUntilSheetClosed(tester);
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
      tester
          .widget<TextButton>(
            find
                .ancestor(
                  of: find.text('Aktuális hónap'),
                  matching: find.byType(TextButton),
                )
                .first,
          )
          .onPressed!();
      await tester.pump();
      tester
          .widget<TextButton>(find.byKey(const ValueKey('query-menu-apply')))
          .onPressed!();
      await tester.pump();
      expect(repository.queryPrepareCount, 1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('query-menu-close')));
      await _pumpUntilSheetClosed(tester);
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

List<Map<String, Object?>> _categoryInventoryResponse() =>
    <Map<String, Object?>>[
      <String, Object?>{
        'id': 'category-groceries',
        'name': 'Groceries',
        'colorId': 'color_08',
        'iconId': 'icon_08',
        'isSystemUncategorized': false,
        'createdAtUtcMs': 1,
        'updatedAtUtcMs': 1,
      },
      <String, Object?>{
        'id': 'category-travel',
        'name': 'Travel',
        'colorId': 'color_13',
        'iconId': 'icon_11',
        'isSystemUncategorized': false,
        'createdAtUtcMs': 2,
        'updatedAtUtcMs': 2,
      },
    ];

List<FluviCategory> _categoryInventory() => <FluviCategory>[
  const FluviCategory(
    id: 'category-groceries',
    name: 'Groceries',
    colorId: 'color_08',
    iconId: 'icon_08',
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  ),
  const FluviCategory(
    id: 'category-travel',
    name: 'Travel',
    colorId: 'color_13',
    iconId: 'icon_11',
    isSystemUncategorized: false,
    createdAtUtcMs: 2,
    updatedAtUtcMs: 2,
  ),
];

final class _CountingCategoryRepository implements CategoryRepository {
  _CountingCategoryRepository(this._categories);

  final List<FluviCategory> _categories;
  var watchCalls = 0;
  var getCalls = 0;

  @override
  Stream<List<FluviCategory>> watchCategories() {
    watchCalls += 1;
    return Stream<List<FluviCategory>>.value(_categories);
  }

  @override
  Future<List<FluviCategory>> getCategories() async {
    getCalls += 1;
    return _categories;
  }

  void dispose() {}

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<FluviCategory?> getCategoryById(String id) =>
      throw UnimplementedError();

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();
}

final class _FailingCategoryRepository implements CategoryRepository {
  const _FailingCategoryRepository();

  @override
  Stream<List<FluviCategory>> watchCategories() =>
      Stream<List<FluviCategory>>.error(
        StateError('category bridge unavailable'),
      );

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<FluviCategory?> getCategoryById(String id) =>
      throw UnimplementedError();

  @override
  Future<List<FluviCategory>> getCategories() => throw UnimplementedError();

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();
}

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
