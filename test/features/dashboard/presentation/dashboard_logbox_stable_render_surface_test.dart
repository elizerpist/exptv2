import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
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

  testWidgets(
    'RED: only a true tap on a prepared avatar emits its category focus row',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(_visible(groups: _groups(1), epoch: 1));
      DashboardLogRowViewModel? selected;

      await _pumpViewport(
        tester,
        store: store,
        counters: DashboardPerformanceCounters(),
        onAvatarTap: (row) => selected = row,
      );
      await tester.pump();

      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final origin = tester.getTopLeft(surface);
      await tester.tapAt(origin + const Offset(24, 40));
      await tester.pump();

      expect(selected?.entryId, 'row-0');
      expect(selected?.categoryId, 'category-row-0');
    },
  );

  testWidgets(
    'RED: vertical movement beginning on an avatar never becomes category focus',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(_visible(groups: _groups(24), epoch: 1, entryCount: 94));
      DashboardLogRowViewModel? selected;

      await _pumpViewport(
        tester,
        store: store,
        counters: DashboardPerformanceCounters(),
        onAvatarTap: (row) => selected = row,
      );
      await tester.pump();

      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final origin = tester.getTopLeft(surface);
      final gesture = await tester.startGesture(origin + const Offset(24, 40));
      await gesture.moveBy(const Offset(0, -72));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        selected,
        isNull,
        reason:
            'The avatar affordance is a true tap only; its recognizer must '
            'cede a dragged pointer to the stable vertical scroll path.',
      );
    },
  );

  testWidgets(
    'RED: two visible LogBox avatars cannot erase an earlier prepared row',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final counters = DashboardPerformanceCounters();
      final repaintBoundaryKey = GlobalKey();
      addTearDown(store.dispose);
      store.publish(
        _visible(
          groups: _groupsWithIconIds(<String>['icon_02', 'icon_03']),
          epoch: 1,
        ),
      );

      await _pumpViewport(
        tester,
        store: store,
        counters: counters,
        repaintBoundaryKey: repaintBoundaryKey,
      );
      for (var frame = 0; frame < 8; frame += 1) {
        await tester.pump();
      }

      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final boundary =
          repaintBoundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final surfaceBox = tester.renderObject<RenderBox>(surface);
      final surfaceOrigin = surfaceBox.localToGlobal(
        Offset.zero,
        ancestor: boundary,
      );
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      ))!;
      addTearDown(image.dispose);
      final pixels = (await tester.runAsync(
        () => _StableSurfacePixels.read(image),
      ))!;

      final firstRowText = Rect.fromLTWH(
        surfaceOrigin.dx + 60,
        surfaceOrigin.dy + 30,
        170,
        32,
      );
      final secondAvatar = Rect.fromLTWH(
        surfaceOrigin.dx + 12,
        surfaceOrigin.dy + 123,
        34,
        34,
      );
      expect(
        pixels.darkInkCount(firstRowText),
        greaterThan(8),
        reason:
            'The second avatar may not destroy the first row\'s already '
            'prepared text or card content.',
      );
      expect(
        pixels.nonWhiteCount(secondAvatar),
        greaterThan(8),
        reason: 'The second prepared avatar still has to paint its glyph.',
      );
      expect(
        counters.value(DashboardPerformanceMetric.logVisibleSlotPaint),
        greaterThanOrEqualTo(2),
      );
    },
  );

  testWidgets(
    'decorative edit placeholder is painted in the source trailing slot',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final repaintBoundaryKey = GlobalKey();
      String? tapped;
      addTearDown(store.dispose);
      store.publish(_visible(groups: _groups(1), epoch: 1));

      await _pumpViewport(
        tester,
        store: store,
        counters: DashboardPerformanceCounters(),
        repaintBoundaryKey: repaintBoundaryKey,
        onEntryTap: (entryId) => tapped = entryId,
      );
      for (var frame = 0; frame < 8; frame += 1) {
        await tester.pump();
      }

      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final boundary =
          repaintBoundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final surfaceBox = tester.renderObject<RenderBox>(surface);
      final surfaceOrigin = surfaceBox.localToGlobal(
        Offset.zero,
        ancestor: boundary,
      );
      final localBounds = DashboardLogBoxTokens.editPlaceholderBounds(
        surfaceWidth: surfaceBox.size.width,
        rowTop: DashboardLogBoxTokens.dayHeaderHeight,
        rowHeight: DashboardLogBoxTokens.rowHeight,
      );
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      ))!;
      addTearDown(image.dispose);
      final pixels = (await tester.runAsync(
        () => _StableSurfacePixels.read(image),
      ))!;
      expect(
        pixels.nonWhiteCount(localBounds.shift(surfaceOrigin)),
        greaterThan(80),
      );

      await tester.tapAt(surfaceBox.localToGlobal(localBounds.center));
      await tester.pump();
      expect(tapped, isNull);
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
    'an active matching committed cache cannot replace a preview rail scene',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      final preview = _visible(groups: _groups(1), epoch: 1);
      store.publish(preview);
      final verticalPayload = DashboardLogViewportState(
        queryKey: preview.queryKey,
        revision: preview.coreRevision,
        groups: _groups(1, idPrefix: 'vertical'),
        entryCount: 1,
        nextCursor: null,
        direction: preview.scope.direction,
      );
      cache.seed(
        CommittedLogPage(
          queryKey: preview.queryKey,
          coreRevision: preview.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: verticalPayload,
        ),
        generation: 1,
        geometryManifest: _manifestForPayload(
          queryKey: preview.queryKey,
          coreRevision: preview.coreRevision,
          payload: verticalPayload,
        ),
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      await _pumpViewport(
        tester,
        store: store,
        counters: counters,
        committedViewport: cache,
      );
      await tester.pump();

      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
        0,
      );
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(
        find.semantics.byLabel('Partner row-0, -1,00 Ft, kiadás, Category'),
        findsOne,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'committed virtual surface uses the exact manifest extent even for a short scope',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      final committed = _visible(groups: _groups(1), epoch: 1).asCommitted();
      store.publish(committed);
      cache.seed(
        CommittedLogPage(
          queryKey: committed.queryKey,
          coreRevision: committed.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: committed.logBox,
        ),
        generation: 1,
        geometryManifest: _manifestForPayload(
          queryKey: committed.queryKey,
          coreRevision: committed.coreRevision,
          payload: committed.logBox,
        ),
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      await _pumpViewport(
        tester,
        store: store,
        counters: counters,
        committedViewport: cache,
      );
      await tester.pump();

      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('dashboard-logbox-stable-render-surface'),
              ),
            )
            .height,
        cache.contentHeight,
      );
    },
  );

  testWidgets(
    'READY waits for every pinned rail payload text layout and crossing is cache-only',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final counters = DashboardPerformanceCounters();
      final diagnostics = DashboardRenderReadinessDiagnostics(enabled: true);
      final first = _visible(groups: _groups(4), epoch: 1);
      final second = _visible(
        groups: _groups(9, idPrefix: 'next'),
        epoch: 2,
        year: 2025,
      );
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
  CommittedLogViewportCache? committedViewport,
  DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads,
  DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached,
  DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut,
  DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared,
  ValueChanged<DashboardLogRowViewModel>? onAvatarTap,
  ValueChanged<String>? onEntryTap,
  GlobalKey? repaintBoundaryKey,
}) => tester.pumpWidget(
  MaterialApp(
    home: _maybeRepaintBoundary(
      key: repaintBoundaryKey,
      child: SizedBox(
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
          onLoadNextPage: (_) {},
          committedViewport: committedViewport,
          preparedRasters:
              preparedRasters ??
              PreparedVectorAssetAtlas.instance.logBoxRastersFor(3),
          renderCriticalPayloads: renderCriticalPayloads,
          onEntryTap: onEntryTap,
          onAvatarTap: onAvatarTap,
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
  ),
);

Widget _maybeRepaintBoundary({required Widget child, GlobalKey? key}) =>
    key == null ? child : RepaintBoundary(key: key, child: child);

DashboardVisibleFrame _visible({
  required List<DashboardDayLogGroupViewModel> groups,
  required int epoch,
  int year = 2026,
  int? entryCount,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: YearScope(year),
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
        categoryId: 'category-$idPrefix-$index',
        partnerId: 'partner-$idPrefix-$index',
        partnerDisplayName: 'Partner $idPrefix-$index',
        semanticLabel: 'Partner $idPrefix-$index, -1,00 Ft, kiadás, Category',
      ),
    ],
  ),
  growable: false,
);

List<DashboardDayLogGroupViewModel> _groupsWithIconIds(List<String> iconIds) =>
    List<DashboardDayLogGroupViewModel>.generate(
      iconIds.length,
      (index) => DashboardDayLogGroupViewModel(
        dateKey: '2026-07-${(index + 1).toString().padLeft(2, '0')}',
        dayLabel: '2026. július ${index + 1}.',
        rows: <DashboardLogRowViewModel>[
          DashboardLogRowViewModel(
            entryId: 'glyph-row-$index',
            displayName: 'Prepared glyph row $index',
            categoryDisplayName: 'Category',
            formattedAmount: '-1,00 Ft',
            displayTime: '12:00',
            amountStyle: LogAmountStyle.expense,
            categoryColorId: 'fallback',
            categoryIconId: iconIds[index],
            semanticLabel: 'Prepared glyph row $index',
          ),
        ],
      ),
      growable: false,
    );

final class _StableSurfacePixels {
  const _StableSurfacePixels(this._bytes, this.width, this.height);

  final ByteData _bytes;
  final int width;
  final int height;

  static Future<_StableSurfacePixels> read(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      throw StateError('Could not inspect the painted LogBox.');
    }
    return _StableSurfacePixels(bytes, image.width, image.height);
  }

  int darkInkCount(Rect rect) => _countWhere(
    rect,
    (red, green, blue, alpha) =>
        alpha > 200 && red < 120 && green < 120 && blue < 120,
  );

  int nonWhiteCount(Rect rect) => _countWhere(
    rect,
    (red, green, blue, alpha) =>
        alpha > 0 && (red < 245 || green < 245 || blue < 245),
  );

  int _countWhere(
    Rect rect,
    bool Function(int red, int green, int blue, int alpha) predicate,
  ) {
    var count = 0;
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y += 1) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x += 1) {
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        final offset = (y * width + x) * 4;
        if (predicate(
          _bytes.getUint8(offset),
          _bytes.getUint8(offset + 1),
          _bytes.getUint8(offset + 2),
          _bytes.getUint8(offset + 3),
        )) {
          count += 1;
        }
      }
    }
    return count;
  }
}

CommittedVerticalGeometryManifest _manifestForPayload({
  required LedgerQueryKey queryKey,
  required int coreRevision,
  required DashboardLogViewportState payload,
}) => CommittedVerticalGeometryManifest.compile(
  queryKey: queryKey,
  coreRevision: coreRevision,
  pageSize: 24,
  totalEntryCount: payload.entryCount,
  dayBuckets: <CommittedVerticalGeometryDayBucket>[
    for (var index = 0; index < payload.groups.length; index += 1)
      if (payload.groups[index].rows.isNotEmpty)
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 20_000 - index,
          entryCount: payload.groups[index].rows.length,
        ),
  ],
);
