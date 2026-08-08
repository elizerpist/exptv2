import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_text_layout_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  test(
    'text-layout pin set fails closed instead of growing without bound',
    () async {
      final cache = DashboardLogBoxTextLayoutCache(maximumPinnedRows: 2);
      addTearDown(cache.dispose);
      final payload = _visible(groups: _groups(3), epoch: 1).logBox;

      await expectLater(
        cache.preparePinned(
          payloads: <DashboardLogViewportState>[payload],
          surfaceWidth: 378,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('prepared row text identity is constant-time content metadata', () {
    final first = _groups(1).single.rows.single;
    final sameContent = _groups(1).single.rows.single;
    final changedContent = DashboardLogRowViewModel(
      entryId: first.entryId,
      displayName: '${first.displayName} changed',
      categoryDisplayName: first.categoryDisplayName,
      formattedAmount: first.formattedAmount,
      displayTime: first.displayTime,
      amountStyle: first.amountStyle,
      categoryColorId: first.categoryColorId,
      categoryIconId: first.categoryIconId,
      semanticLabel: first.semanticLabel,
    );

    expect(sameContent.textLayoutId, first.textLayoutId);
    expect(changedContent.textLayoutId, isNot(first.textLayoutId));
  });

  testWidgets('empty and populated frames keep one render surface identity', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    final counters = _SurfaceTimingCounters();
    final diagnostics = DashboardRenderReadinessDiagnostics(enabled: true);
    addTearDown(store.dispose);
    store.publish(_visible(groups: const [], epoch: 1));

    await _pumpViewport(
      tester,
      store: store,
      counters: counters,
      diagnostics: diagnostics,
    );
    final surface = find.byKey(
      const ValueKey('dashboard-logbox-stable-render-surface'),
    );
    expect(surface, findsOneWidget);
    final renderObject = tester.renderObject<RenderBox>(surface);
    final scrollableState = tester.state(find.byType(Scrollable));

    store.publish(_visible(groups: _groups(24), epoch: 2));
    await tester.pump();

    expect(
      identical(tester.renderObject<RenderBox>(surface), renderObject),
      isTrue,
    );
    expect(
      identical(tester.state(find.byType(Scrollable)), scrollableState),
      isTrue,
    );
    expect(find.byType(SliverList), findsNothing);
    expect(find.byType(SliverFillRemaining), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'DashboardLogRow',
      ),
      findsNothing,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logRenderSurfaceCreate),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logRenderSurfaceUpdate),
      1,
    );
    final presented = diagnostics.snapshot().lastWhere(
      (event) =>
          event.type == DashboardRenderReadinessEventType.logBoxFramePresented,
    );
    expect(presented.gestureId, 41);
    expect(presented.displayFrameId, 73);
    expect(
      presented.paintMicros,
      _SurfaceTimingCounters.syntheticSurfacePaintMicros,
      reason:
          'LOGBOX_FRAME_PRESENTED must report the CustomPainter surface, not '
          'the outer repaint-boundary probe.',
    );
  });

  testWidgets(
    '94-entry month creates one bounded paint surface, not row widgets',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      store.publish(_visible(groups: _groups(24), epoch: 1, entryCount: 94));

      await _pumpViewport(tester, store: store, counters: counters);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('dashboard-logbox-stable-render-surface')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'DashboardLogRow',
        ),
        findsNothing,
      );
      expect(counters.value(DashboardPerformanceMetric.logRowBuild), 0);
      expect(
        counters.value(DashboardPerformanceMetric.logVisibleSlotPaint),
        inInclusiveRange(1, 24),
      );
      expect(
        counters.value(DashboardPerformanceMetric.logRenderSurfaceCreate),
        1,
      );
    },
  );

  testWidgets('stable surface preserves row semantics and tap intent', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    store.publish(_visible(groups: _groups(2), epoch: 1));
    String? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 700,
          child: DashboardLogBoxViewport(
            bounds: const DashboardBounds(
              left: 0,
              top: 28,
              width: 378,
              height: 28,
            ),
            visibleFrames: store,
            preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(
              3,
            ),
            onLoadNextPage: (_) {},
            onEntryTap: (entryId) => tapped = entryId,
          ),
        ),
      ),
    );
    await tester.pump();
    final semantics = tester.ensureSemantics();
    await tester.pump();

    final rowSemantics = find.semantics.byLabel(
      'Partner row-0, -1,00 Ft, kiadás, Category',
    );
    expect(rowSemantics, findsOne);
    expect(
      rowSemantics.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );
    final surface = find.byKey(
      const ValueKey('dashboard-logbox-stable-render-surface'),
    );
    await tester.tapAt(tester.getTopLeft(surface) + const Offset(100, 47.5));
    await tester.pump();
    expect(tapped, 'row-0');
    semantics.dispose();
  });

  testWidgets(
    'READY waits for every pinned rail payload text layout and crossing is cache-only',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final counters = DashboardPerformanceCounters();
      final diagnostics = DashboardRenderReadinessDiagnostics(enabled: true);
      final first = _visible(groups: _groups(4), epoch: 1);
      final second = _visible(groups: _groups(9, idPrefix: 'next'), epoch: 2);
      addTearDown(store.dispose);
      store.publish(first);
      var readyAcknowledgements = 0;

      await _pumpViewport(
        tester,
        store: store,
        counters: counters,
        diagnostics: diagnostics,
        renderCriticalPayloads: () => <DashboardLogViewportState>[
          first.logBox,
          second.logBox,
        ],
        onWarmupTextLayoutsPrepared: (_) {
          readyAcknowledgements += 1;
          diagnostics.markReady();
        },
      );
      for (
        var frame = 0;
        frame < 20 && readyAcknowledgements == 0;
        frame += 1
      ) {
        await tester.pump();
      }

      expect(readyAcknowledgements, 1);
      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutPreparedRow),
        13,
      );
      expect(
        counters.value(
          DashboardPerformanceMetric.logTextLayoutPreparedDayHeader,
        ),
        9,
      );
      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutRetainedBytes),
        greaterThan(0),
      );
      final fallbacksBefore = counters.value(
        DashboardPerformanceMetric.logTextLayoutFallback,
      );

      store.publish(second);
      await tester.pump();

      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
        fallbacksBefore,
        reason: 'A pinned child crossing must only paint prepared paragraphs.',
      );
      expect(diagnostics.railCriticalCacheMissCount, 0);
    },
  );

  testWidgets('surface consumes the exact raster set prepared by bootstrap', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    store.publish(_visible(groups: _groups(1), epoch: 1));
    final prepared = PreparedVectorAssetAtlas.instance.logBoxRastersFor(3);

    await _pumpViewport(
      tester,
      store: store,
      counters: DashboardPerformanceCounters(),
      preparedRasters: prepared,
    );
    await tester.pump();

    final surface = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('dashboard-logbox-stable-render-surface')),
    );
    expect((surface.painter! as dynamic).rasters, same(prepared));
  });

  testWidgets(
    'deterministic warmup completes attach layout and text tasks without paint acknowledgement',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(_visible(groups: _groups(1), epoch: 1));
      final tasks = <String>[];

      await _pumpViewport(
        tester,
        store: store,
        counters: DashboardPerformanceCounters(),
        onWarmupSurfaceAttached: (_) => tasks.add('surface'),
        onWarmupSurfaceLaidOut: (_) => tasks.add('layout'),
        onWarmupTextLayoutsPrepared: (_) => tasks.add('text'),
      );
      for (var frame = 0; frame < 10 && tasks.length < 3; frame += 1) {
        await tester.pump();
      }

      expect(tasks, <String>['surface', 'layout', 'text']);
    },
  );
}

final class _SurfaceTimingCounters extends DashboardPerformanceCounters {
  _SurfaceTimingCounters() : super(measuresDurations: true);

  static const syntheticSurfacePaintMicros = 700;

  @override
  void increment(DashboardPerformanceMetric metric, {int by = 1}) {
    super.increment(
      metric,
      by: metric == DashboardPerformanceMetric.logSurfacePaintMicros
          ? syntheticSurfacePaintMicros
          : by,
    );
  }
}

Future<void> _pumpViewport(
  WidgetTester tester, {
  required DashboardVisibleFrameStore store,
  required DashboardPerformanceCounters counters,
  PreparedLogBoxRasterSet? preparedRasters,
  DashboardRenderReadinessDiagnostics? diagnostics,
  DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads,
  DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached,
  DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut,
  DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared,
}) => tester.pumpWidget(
  MaterialApp(
    home: SizedBox(
      width: 378,
      height: 700,
      child: DashboardLogBoxViewport(
        bounds: const DashboardBounds(left: 0, top: 28, width: 378, height: 28),
        visibleFrames: store,
        onLoadNextPage: (_) {},
        preparedRasters:
            preparedRasters ??
            PreparedVectorAssetAtlas.instance.logBoxRastersFor(3),
        renderCriticalPayloads: renderCriticalPayloads,
        onWarmupSurfaceAttached: onWarmupSurfaceAttached,
        onWarmupSurfaceLaidOut: onWarmupSurfaceLaidOut,
        onWarmupTextLayoutsPrepared: onWarmupTextLayoutsPrepared,
        performanceCounters: counters,
        renderDiagnostics: diagnostics,
        renderDiagnosticContextProvider: () =>
            const DashboardRenderDiagnosticContext(
              gestureId: 41,
              displayFrameId: 73,
            ),
      ),
    ),
  ),
);

DashboardVisibleFrame _visible({
  required List<DashboardDayLogGroupViewModel> groups,
  required int epoch,
  int? entryCount,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const YearScope(2026),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: groups,
    entryCount: entryCount ?? groups.length,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: epoch * 100,
    formattedAmount: '$epoch,00 Ft',
    entryCount: entryCount ?? groups.length,
    formattedEntryCount: '${entryCount ?? groups.length}',
    logBox: logBox,
    presentationDigest: Object.hash(epoch, groups.length),
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.year,
    railOpen: true,
    semanticIndex: 0,
    childLabel: '2026',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: epoch,
    mode: DashboardVisibleMode.preview,
  );
}

List<DashboardDayLogGroupViewModel> _groups(
  int count, {
  String idPrefix = 'row',
}) => List<DashboardDayLogGroupViewModel>.generate(
  count,
  (index) => DashboardDayLogGroupViewModel(
    dateKey: '2026-07-${(index + 1).toString().padLeft(2, '0')}',
    dayLabel: '2026. július ${index + 1}.',
    rows: <DashboardLogRowViewModel>[
      DashboardLogRowViewModel(
        entryId: '$idPrefix-$index',
        displayName: 'Partner $idPrefix-$index',
        categoryDisplayName: 'Category',
        formattedAmount: '-1,00 Ft',
        displayTime: '12:00',
        amountStyle: LogAmountStyle.expense,
        categoryColorId: 'fallback',
        categoryIconId: 'fallback',
        semanticLabel: 'Partner $idPrefix-$index, -1,00 Ft, kiadás, Category',
      ),
    ],
  ),
  growable: false,
);
