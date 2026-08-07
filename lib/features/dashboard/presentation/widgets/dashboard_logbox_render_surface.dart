import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_text_layout_cache.dart';

typedef DashboardLogBoxWarmupTaskCallback = void Function(int viewportId);
typedef DashboardLogBoxWarmupErrorCallback =
    void Function(Object error, StackTrace stackTrace);
typedef DashboardLogBoxTextLayoutPreparedCallback =
    void Function({
      required int preparedRowCount,
      required int preparedDayHeaderCount,
      required int estimatedBytes,
    });

/// The LogBox's one bounded, stable render surface.
///
/// A payload swap updates one [RenderCustomPaint]. It never creates one Widget,
/// RenderObject, repaint layer or Material subtree per transaction row.
final class DashboardLogBoxRenderSurface extends StatefulWidget {
  const DashboardLogBoxRenderSurface({
    super.key,
    required this.visibleFrames,
    required this.scrollController,
    required this.minimumHeight,
    required this.preparedRasters,
    this.renderCriticalPayloads,
    this.onEntryTap,
    this.onWarmupSurfaceAttached,
    this.onWarmupSurfaceLaidOut,
    this.onWarmupTextLayoutsPrepared,
    this.onWarmupError,
    this.onTextLayoutsPrepared,
    this.performanceCounters,
    this.renderDiagnostics,
    this.renderDiagnosticContextProvider,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController scrollController;
  final double minimumHeight;
  final PreparedLogBoxRasterSet preparedRasters;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onWarmupError;
  final DashboardLogBoxTextLayoutPreparedCallback? onTextLayoutsPrepared;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  final DashboardRenderDiagnosticContextProvider?
  renderDiagnosticContextProvider;

  @override
  State<DashboardLogBoxRenderSurface> createState() =>
      _DashboardLogBoxRenderSurfaceState();
}

final class _DashboardLogBoxRenderSurfaceState
    extends State<DashboardLogBoxRenderSurface> {
  late final _DashboardLogBoxPaintResources _paintResources;
  late final DashboardLogBoxTextLayoutCache _textLayoutCache;
  _DashboardLogBoxSurfacePainter? _latestPainter;
  int? _lastViewportId;
  int? _scheduledViewportId;
  bool _firstFrameReported = false;
  bool _surfaceWarmupReported = false;
  bool _layoutWarmupReported = false;

  @override
  void initState() {
    super.initState();
    _paintResources = _DashboardLogBoxPaintResources();
    _textLayoutCache = DashboardLogBoxTextLayoutCache();
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logRenderSurfaceCreate,
    );
  }

  @override
  void dispose() {
    _textLayoutCache.dispose();
    _paintResources.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<DashboardVisibleFrame?>(
    valueListenable: widget.visibleFrames.logBoxLane,
    builder: (context, frame, _) {
      final measure = widget.performanceCounters?.measuresDurations ?? false;
      final buildStarted = measure ? developer.Timeline.now : 0;
      widget.performanceCounters?.increment(
        DashboardPerformanceMetric.logBoxBuild,
      );
      final payload = frame?.logBox;
      final viewportId = payload?.viewportId ?? 0;
      final previousViewportId = _lastViewportId;
      if (previousViewportId != null && previousViewportId != viewportId) {
        widget.performanceCounters?.increment(
          DashboardPerformanceMetric.logRenderSurfaceUpdate,
        );
      }
      _lastViewportId = viewportId;

      final contentHeight = _contentHeight(payload, widget.minimumHeight);
      final painter = _DashboardLogBoxSurfacePainter(
        payload: payload,
        resources: _paintResources,
        textLayouts: _textLayoutCache,
        textLayoutGeneration: _textLayoutCache.generation,
        rasters: widget.preparedRasters,
        scrollController: widget.scrollController,
        onEntryTap: widget.onEntryTap,
        performanceCounters: widget.performanceCounters,
        renderDiagnostics: widget.renderDiagnostics,
      );
      _latestPainter = painter;

      final buildMicros = measure ? developer.Timeline.now - buildStarted : 0;
      if (measure) {
        widget.performanceCounters!.increment(
          DashboardPerformanceMetric.logViewportBindMicros,
          by: buildMicros,
        );
      }
      if (payload != null && previousViewportId != viewportId) {
        _announceSurfaceAttached(frame!, payload);
        final diagnosticContext =
            widget.renderDiagnosticContextProvider?.call() ??
            DashboardRenderDiagnosticContext(
              gestureId: 0,
              displayFrameId: frame.frameGeneration,
            );
        _recordPresentationStarted(frame, payload, diagnosticContext);
        _schedulePresented(
          frame: frame,
          payload: payload,
          buildMicros: buildMicros,
          diagnosticContext: diagnosticContext,
        );
      }

      return SizedBox(
        height: contentHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (payload != null) {
              _announceSurfaceLaidOut(
                frame: frame!,
                payload: payload,
                surfaceWidth: constraints.maxWidth,
              );
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final entryId = _latestPainter?.entryAt(details.localPosition);
                if (entryId != null) widget.onEntryTap?.call(entryId);
              },
              child: CustomPaint(
                key: const ValueKey('dashboard-logbox-stable-render-surface'),
                painter: painter,
                isComplex: true,
                willChange: true,
              ),
            );
          },
        ),
      );
    },
  );

  void _announceSurfaceAttached(
    DashboardVisibleFrame frame,
    DashboardLogViewportState payload,
  ) {
    if (_surfaceWarmupReported) return;
    _surfaceWarmupReported = true;
    final timer = Stopwatch()..start();
    widget.renderDiagnostics?.recordFirstUseStarted(
      subsystem: DashboardRenderSubsystem.logBoxRenderSurface,
      queryKey: frame.queryKey.value,
      entryCount: payload.entryCount,
      railCritical: false,
    );
    widget.onWarmupSurfaceAttached?.call(payload.viewportId);
    timer.stop();
    widget.renderDiagnostics?.recordFirstUseCompleted(
      subsystem: DashboardRenderSubsystem.logBoxRenderSurface,
      queryKey: frame.queryKey.value,
      entryCount: payload.entryCount,
      durationMicros: timer.elapsedMicroseconds,
    );
  }

  void _announceSurfaceLaidOut({
    required DashboardVisibleFrame frame,
    required DashboardLogViewportState payload,
    required double surfaceWidth,
  }) {
    if (_layoutWarmupReported) return;
    _layoutWarmupReported = true;
    widget.onWarmupSurfaceLaidOut?.call(payload.viewportId);
    unawaited(
      _runCriticalTextWarmup(
        frame: frame,
        payload: payload,
        surfaceWidth: surfaceWidth,
      ),
    );
  }

  void _recordPresentationStarted(
    DashboardVisibleFrame frame,
    DashboardLogViewportState payload,
    DashboardRenderDiagnosticContext diagnosticContext,
  ) {
    widget.renderDiagnostics?.recordLogBoxPresentationStarted(
      gestureId: diagnosticContext.gestureId,
      displayFrameId: diagnosticContext.displayFrameId,
      queryKey: frame.queryKey.value,
      entryCount: payload.entryCount,
      groupCount: payload.groups.length,
      previewRowCount: payload.flatItems.length,
    );
  }

  void _schedulePresented({
    required DashboardVisibleFrame frame,
    required DashboardLogViewportState payload,
    required int buildMicros,
    required DashboardRenderDiagnosticContext diagnosticContext,
  }) {
    if (_scheduledViewportId == payload.viewportId) return;
    _scheduledViewportId = payload.viewportId;
    final counters = widget.performanceCounters;
    final layoutStart = counters?.value(
      DashboardPerformanceMetric.logLayoutMicros,
    );
    final paintStart = counters?.value(
      DashboardPerformanceMetric.logSurfacePaintMicros,
    );
    final slotStart = counters?.value(
      DashboardPerformanceMetric.logVisibleSlotPaint,
    );
    final semanticsStart = counters?.value(
      DashboardPerformanceMetric.logSemanticsNodeUpdate,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledViewportId = null;
      final samePayload =
          widget.visibleFrames.logBoxLane.value?.logBox.viewportId ==
          payload.viewportId;
      if (!samePayload) return;
      final layoutMicros = layoutStart == null
          ? 0
          : counters!.value(DashboardPerformanceMetric.logLayoutMicros) -
                layoutStart;
      final paintMicros = paintStart == null
          ? 0
          : counters!.value(DashboardPerformanceMetric.logSurfacePaintMicros) -
                paintStart;
      final rowSlotsPainted = slotStart == null
          ? 0
          : counters!.value(DashboardPerformanceMetric.logVisibleSlotPaint) -
                slotStart;
      final semanticsNodes = semanticsStart == null
          ? 0
          : counters!.value(DashboardPerformanceMetric.logSemanticsNodeUpdate) -
                semanticsStart;
      widget.renderDiagnostics?.recordLogBoxPresented(
        gestureId: diagnosticContext.gestureId,
        displayFrameId: diagnosticContext.displayFrameId,
        queryKey: frame.queryKey.value,
        entryCount: payload.entryCount,
        groupCount: payload.groups.length,
        previewRowCount: payload.flatItems.length,
        buildMicros: buildMicros,
        layoutMicros: layoutMicros,
        paintMicros: paintMicros,
        rowSlotsPainted: rowSlotsPainted,
        semanticsNodes: semanticsNodes,
        renderObjectsCreated: _firstFrameReported ? 0 : 1,
        renderObjectsUpdated: _firstFrameReported ? 1 : 0,
        layersCreated: _firstFrameReported ? 0 : 1,
        frameMissedBudget: buildMicros + layoutMicros + paintMicros > 16667,
      );
      if (_firstFrameReported) return;
      _firstFrameReported = true;
    });
  }

  Future<void> _runCriticalTextWarmup({
    required DashboardVisibleFrame frame,
    required DashboardLogViewportState payload,
    required double surfaceWidth,
  }) async {
    final started = developer.Timeline.now;
    widget.renderDiagnostics?.recordFirstUseStarted(
      subsystem: DashboardRenderSubsystem.textLayoutSlots,
      queryKey: frame.queryKey.value,
      entryCount: payload.entryCount,
      railCritical: false,
    );
    try {
      await _prepareCriticalTextLayouts(
        frame: frame,
        payload: payload,
        surfaceWidth: surfaceWidth,
        started: started,
      );
    } on Object catch (error, stackTrace) {
      widget.renderDiagnostics?.recordFirstUseFailed(
        subsystem: DashboardRenderSubsystem.textLayoutSlots,
        queryKey: frame.queryKey.value,
        entryCount: payload.entryCount,
        durationMicros: developer.Timeline.now - started,
        error: error,
      );
      if (!mounted) return;
      widget.onWarmupError?.call(error, stackTrace);
    }
  }

  Future<void> _prepareCriticalTextLayouts({
    required DashboardVisibleFrame frame,
    required DashboardLogViewportState payload,
    required double surfaceWidth,
    required int started,
  }) async {
    final provided = widget.renderCriticalPayloads?.call();
    final payloads = provided == null || provided.isEmpty
        ? <DashboardLogViewportState>[payload]
        : provided;
    await _textLayoutCache.preparePinned(
      payloads: payloads,
      surfaceWidth: surfaceWidth,
      // Standalone/component mounts do not own the app-readiness barrier and
      // must not leave a scheduled chunk behind when a test or route disposes
      // them immediately. The production readiness owner supplies the exact
      // presented callback and receives bounded scheduler chunks.
      yieldEveryRows: widget.onWarmupTextLayoutsPrepared == null
          ? _textLayoutCache.maximumPinnedRows + 1
          : 64,
    );
    if (!mounted) return;
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutPreparedRow,
      by: _textLayoutCache.preparedRowCount,
    );
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutPreparedDayHeader,
      by: _textLayoutCache.preparedDayHeaderCount,
    );
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutRetainedBytes,
      by: _textLayoutCache.estimatedBytes,
    );
    widget.onTextLayoutsPrepared?.call(
      preparedRowCount: _textLayoutCache.preparedRowCount,
      preparedDayHeaderCount: _textLayoutCache.preparedDayHeaderCount,
      estimatedBytes: _textLayoutCache.estimatedBytes,
    );
    setState(() {});
    widget.renderDiagnostics?.recordFirstUseCompleted(
      subsystem: DashboardRenderSubsystem.textLayoutSlots,
      queryKey: frame.queryKey.value,
      entryCount: _textLayoutCache.preparedRowCount,
      durationMicros: developer.Timeline.now - started,
    );
    widget.onWarmupTextLayoutsPrepared?.call(payload.viewportId);
  }

  static double _contentHeight(
    DashboardLogViewportState? payload,
    double minimumHeight,
  ) {
    if (payload == null || payload.flatItems.isEmpty) return minimumHeight;
    final groupDecorationHeight =
        payload.groups.length * DashboardLogBoxTokens.dayHeaderHeight +
        math.max(0, payload.groups.length - 1) *
            DashboardLogBoxTokens.dayGroupGap;
    final rowHeight =
        payload.flatItems.length * DashboardLogBoxTokens.rowHeight;
    return math.max(minimumHeight, groupDecorationHeight + rowHeight);
  }
}

final class _DashboardLogBoxPaintResources {
  _DashboardLogBoxPaintResources()
    : image = Paint()..filterQuality = FilterQuality.medium,
      divider = Paint()..color = FluviVisualTokens.border;

  final Paint image;
  final Paint divider;

  void dispose() {}
}

final class _DashboardLogBoxSurfacePainter extends CustomPainter {
  _DashboardLogBoxSurfacePainter({
    required this.payload,
    required this.resources,
    required this.textLayouts,
    required this.textLayoutGeneration,
    required this.rasters,
    required this.scrollController,
    required this.onEntryTap,
    required this.performanceCounters,
    required this.renderDiagnostics,
  });

  static const _paintOverscan = 90.0;

  final DashboardLogViewportState? payload;
  final _DashboardLogBoxPaintResources resources;
  final DashboardLogBoxTextLayoutCache textLayouts;
  final int textLayoutGeneration;
  final PreparedLogBoxRasterSet rasters;
  final ScrollController scrollController;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;

  @override
  void paint(Canvas canvas, Size size) {
    final measure = performanceCounters?.measuresDurations ?? false;
    final started = measure ? developer.Timeline.now : 0;
    final state = payload;
    if (state == null || state.flatItems.isEmpty) {
      _paintEmpty(canvas, size);
      _recordPaintDuration(started, measure);
      return;
    }

    final scrollOffset = scrollController.hasClients
        ? math.max(
            0.0,
            scrollController.offset - DashboardLogBoxTokens.summaryHeaderHeight,
          )
        : 0.0;
    final viewportHeight = scrollController.hasClients
        ? scrollController.position.viewportDimension
        : size.height;
    final visibleTop = math.max(0.0, scrollOffset - _paintOverscan);
    final visibleBottom = math.min(
      size.height,
      scrollOffset + viewportHeight + _paintOverscan,
    );
    _paintGroupBackgrounds(
      canvas,
      size,
      state,
      visibleTop: visibleTop,
      visibleBottom: visibleBottom,
    );
    final first = _firstPossiblyVisibleItem(state.flatItems, visibleTop);
    var resourceCursor = 0;
    for (var index = first; index < state.flatItems.length; index += 1) {
      final item = state.flatItems[index];
      final rowTop = _rowTop(item);
      if (rowTop > visibleBottom) break;
      if (rowTop + DashboardLogBoxTokens.rowHeight < visibleTop) continue;
      _paintItem(canvas, size.width, item, rowTop);
      resourceCursor += 1;
    }
    performanceCounters?.increment(
      DashboardPerformanceMetric.logVisibleSlotPaint,
      by: resourceCursor,
    );
    _recordPaintDuration(started, measure);
  }

  void _recordPaintDuration(int started, bool measure) {
    if (!measure) return;
    performanceCounters!.increment(
      DashboardPerformanceMetric.logSurfacePaintMicros,
      by: developer.Timeline.now - started,
    );
  }

  void _paintEmpty(Canvas canvas, Size size) {
    final painter = textLayouts.empty;
    if (painter == null) {
      _recordTextLayoutMiss();
      return;
    }
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        math.max(0, (size.height - painter.height) / 2),
      ),
    );
  }

  void _paintGroupBackgrounds(
    Canvas canvas,
    Size size,
    DashboardLogViewportState state, {
    required double visibleTop,
    required double visibleBottom,
  }) {
    final first = _firstPossiblyVisibleGroup(state.groupLayouts, visibleTop);
    for (var index = first; index < state.groupLayouts.length; index += 1) {
      final group = state.groupLayouts[index];
      if (group.rowCount == 0) continue;
      final top = _groupRowTop(group);
      final height = group.rowCount * DashboardLogBoxTokens.rowHeight;
      if (top > visibleBottom) break;
      if (top + height < visibleTop) continue;
      final rect = Rect.fromLTWH(
        DashboardLogBoxTokens.horizontalGutter,
        top,
        size.width - DashboardLogBoxTokens.horizontalGutter * 2,
        height,
      );
      canvas.drawImageNine(
        rasters.groupSurface,
        rasters.groupSurfaceCenterSlice,
        rect.inflate(rasters.groupSurfaceOutset),
        resources.image,
      );
    }
  }

  void _paintItem(
    Canvas canvas,
    double width,
    DashboardLogViewportItemViewModel item,
    double rowTop,
  ) {
    final dayLabel = item.dayLabel;
    if (dayLabel != null) {
      final header = textLayouts.dayHeaderFor(dayLabel);
      if (header == null) {
        _recordTextLayoutMiss(item.row);
      } else {
        header.paint(
          canvas,
          Offset(
            DashboardLogBoxTokens.horizontalGutter,
            _groupHeaderTop(item.groupIndex, item.flatRowIndex) +
                DashboardLogBoxTokens.dayHeaderTopInset,
          ),
        );
      }
    }

    if (item.showSeparator) {
      canvas.drawRect(
        Rect.fromLTWH(
          DashboardLogBoxTokens.rowHorizontalInset +
              DashboardLogBoxTokens.avatarSize +
              DashboardLogBoxTokens.rowGap,
          rowTop,
          math.max(
            0,
            width -
                (DashboardLogBoxTokens.rowHorizontalInset * 2) -
                DashboardLogBoxTokens.avatarSize -
                DashboardLogBoxTokens.rowGap,
          ),
          DashboardLogBoxTokens.dividerHeight,
        ),
        resources.divider,
      );
    }

    final row = item.row;
    final badgeTop =
        rowTop +
        (DashboardLogBoxTokens.rowHeight - DashboardLogBoxTokens.avatarSize) /
            2;
    final badgeRect = Rect.fromLTWH(
      DashboardLogBoxTokens.rowHorizontalInset,
      badgeTop,
      DashboardLogBoxTokens.avatarSize,
      DashboardLogBoxTokens.avatarSize,
    );
    _drawPreparedImage(
      canvas,
      rasters.badge(row.categoryColorHandle),
      badgeRect,
    );
    final iconRect = Rect.fromCenter(
      center: badgeRect.center,
      width: DashboardLogBoxTokens.avatarIconSize,
      height: DashboardLogBoxTokens.avatarIconSize,
    );
    _drawPreparedImage(canvas, rasters.icon(row.categoryIconHandle), iconRect);

    final preparedText = textLayouts.rowFor(row);
    if (preparedText != null) {
      preparedText.paint(canvas, rowTop);
      return;
    }
    _recordTextLayoutMiss(row);
  }

  void _recordTextLayoutMiss([DashboardLogRowViewModel? row]) {
    if (!textLayouts.isPrepared) return;
    performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutFallback,
    );
    renderDiagnostics?.recordRailCriticalCacheMiss(
      subsystem: DashboardRenderSubsystem.textLayoutSlots,
      queryKey: payload?.queryKey.value ?? row?.entryId ?? 'unbound',
    );
  }

  void _drawPreparedImage(
    Canvas canvas,
    PreparedLogBoxRasterSprite sprite,
    Rect target,
  ) {
    canvas.drawImageRect(
      sprite.image,
      sprite.sourceRect,
      target,
      resources.image,
    );
  }

  String? entryAt(Offset position) {
    final state = payload;
    if (state == null) return null;
    final index = _firstPossiblyVisibleItem(state.flatItems, position.dy);
    if (index >= state.flatItems.length) return null;
    final item = state.flatItems[index];
    final top = _rowTop(item);
    if (position.dy < top ||
        position.dy > top + DashboardLogBoxTokens.rowHeight) {
      return null;
    }
    return item.row.entryId;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final state = payload;
    if (state == null || state.flatItems.isEmpty) {
      return <CustomPainterSemantics>[
        CustomPainterSemantics(
          rect: Offset.zero & size,
          properties: SemanticsProperties(
            label: 'Nincs tranzakció ebben az időszakban.',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    }
    final viewportTop = scrollController.hasClients
        ? math.max(
            0.0,
            scrollController.offset - DashboardLogBoxTokens.summaryHeaderHeight,
          )
        : 0.0;
    final viewportHeight = scrollController.hasClients
        ? scrollController.position.viewportDimension
        : size.height;
    final viewportBottom = viewportTop + viewportHeight + _paintOverscan;
    final first = _firstPossiblyVisibleItem(state.flatItems, viewportTop);
    final result = <CustomPainterSemantics>[];
    for (
      var index = first;
      index < state.flatItems.length && result.length < 24;
      index += 1
    ) {
      final item = state.flatItems[index];
      final top = _rowTop(item);
      if (top > viewportBottom) break;
      result.add(
        CustomPainterSemantics(
          rect: Rect.fromLTWH(
            0,
            top,
            size.width,
            DashboardLogBoxTokens.rowHeight,
          ),
          properties: SemanticsProperties(
            label: item.row.semanticLabel,
            textDirection: TextDirection.ltr,
            button: true,
            onTap: onEntryTap == null
                ? null
                : () => onEntryTap!(item.row.entryId),
          ),
        ),
      );
    }
    performanceCounters?.increment(
      DashboardPerformanceMetric.logSemanticsNodeUpdate,
      by: result.length,
    );
    return result;
  };

  @override
  bool shouldRepaint(_DashboardLogBoxSurfacePainter oldDelegate) =>
      payload?.viewportId != oldDelegate.payload?.viewportId ||
      textLayoutGeneration != oldDelegate.textLayoutGeneration ||
      !identical(rasters, oldDelegate.rasters);

  @override
  bool shouldRebuildSemantics(_DashboardLogBoxSurfacePainter oldDelegate) =>
      payload?.viewportId != oldDelegate.payload?.viewportId ||
      onEntryTap != oldDelegate.onEntryTap;

  static int _firstPossiblyVisibleItem(
    List<DashboardLogViewportItemViewModel> items,
    double minimumBottom,
  ) {
    var low = 0;
    var high = items.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final item = items[middle];
      final bottom = _rowTop(item) + DashboardLogBoxTokens.rowHeight;
      if (bottom < minimumBottom) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static int _firstPossiblyVisibleGroup(
    List<DashboardLogGroupLayoutViewModel> groups,
    double minimumBottom,
  ) {
    var low = 0;
    var high = groups.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final group = groups[middle];
      final bottom =
          _groupRowTop(group) +
          group.rowCount * DashboardLogBoxTokens.rowHeight;
      if (bottom < minimumBottom) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static double _groupHeaderTop(int groupIndex, int precedingRowCount) =>
      groupIndex * DashboardLogBoxTokens.dayHeaderHeight +
      groupIndex * DashboardLogBoxTokens.dayGroupGap +
      precedingRowCount * DashboardLogBoxTokens.rowHeight;

  static double _rowTop(DashboardLogViewportItemViewModel item) =>
      _groupHeaderTop(item.groupIndex, item.flatRowIndex) +
      DashboardLogBoxTokens.dayHeaderHeight;

  static double _groupRowTop(DashboardLogGroupLayoutViewModel group) =>
      _groupHeaderTop(group.groupIndex, group.precedingRowCount) +
      DashboardLogBoxTokens.dayHeaderHeight;
}
