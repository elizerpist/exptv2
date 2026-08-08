import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import '../../logbox/application/dashboard_logbox_render_domain.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_logbox_presentation_binding.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_prepared_scene_cache.dart';
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

// Stable identity: ValueKey('dashboard-logbox-stable-render-surface').
const _stableLogBoxRenderSurfaceKey = ValueKey(
  'dashboard-logbox-stable-render-surface',
);

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
    this.committedViewport,
    this.renderCriticalPayloads,
    this.sceneWindowProvider,
    this.preparedSceneCache,
    this.onEntryTap,
    this.onWarmupSurfaceAttached,
    this.onWarmupSurfaceLaidOut,
    this.onWarmupTextLayoutsPrepared,
    this.onWarmupError,
    this.onTextLayoutsPrepared,
    this.onExtentPublished,
    this.performanceCounters,
    this.renderDiagnostics,
    this.renderDiagnosticContextProvider,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController scrollController;
  final double minimumHeight;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onWarmupError;
  final DashboardLogBoxTextLayoutPreparedCallback? onTextLayoutsPrepared;
  final ValueChanged<DashboardLogBoxRenderExtentSnapshot>? onExtentPublished;
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
  late final DashboardLogBoxPreparedSceneCache _sceneCache;
  late final bool _ownsSceneCache;
  late final CommittedLogViewportCache _committedViewport;
  late final bool _ownsCommittedViewport;
  _DashboardLogBoxSurfacePainter? _latestPainter;
  int? _lastViewportId;
  int? _lastLoggedSceneViewportId;
  int? _scheduledViewportId;
  DashboardLogBoxRenderDomain? _lastRenderDomain;
  int? _lastExtentPublicationSignature;
  int? _lastMismatchSignature;
  bool _firstFrameReported = false;
  bool _surfaceWarmupReported = false;
  bool _layoutWarmupReported = false;

  @override
  void initState() {
    super.initState();
    _paintResources = _DashboardLogBoxPaintResources();
    _ownsSceneCache = widget.preparedSceneCache == null;
    _sceneCache =
        widget.preparedSceneCache ?? DashboardLogBoxPreparedSceneCache();
    _ownsCommittedViewport = widget.committedViewport == null;
    _committedViewport =
        widget.committedViewport ??
        CommittedLogViewportCache(pageSize: 24, maximumRetainedPages: 5);
    _sceneCache.addListener(_onSceneCacheChanged);
    _committedViewport.addListener(_onSceneCacheChanged);
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logRenderSurfaceCreate,
    );
  }

  @override
  void dispose() {
    _sceneCache.removeListener(_onSceneCacheChanged);
    _committedViewport.removeListener(_onSceneCacheChanged);
    if (_ownsSceneCache) _sceneCache.dispose();
    if (_ownsCommittedViewport) _committedViewport.dispose();
    _paintResources.dispose();
    super.dispose();
  }

  void _onSceneCacheChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<DashboardVisibleFrame?>(
    valueListenable: widget.visibleFrames.logBoxLane,
    builder: (context, frame, _) =>
        ValueListenableBuilder<DashboardLogBoxPresentationBinding?>(
          valueListenable: widget.visibleFrames.logBoxPresentationLane,
          builder: (context, presentation, _) {
            final measure =
                widget.performanceCounters?.measuresDurations ?? false;
            final buildStarted = measure ? developer.Timeline.now : 0;
            widget.performanceCounters?.increment(
              DashboardPerformanceMetric.logBoxBuild,
            );
            final payload = frame?.logBox;
            if (_ownsCommittedViewport &&
                frame != null &&
                presentation?.mode == DashboardVisibleMode.committed &&
                payload != null) {
              _seedStandaloneCommittedViewport(frame.asCommitted(), payload);
            }
            final renderDomain = resolveDashboardLogBoxRenderDomain(
              payload: payload,
              presentation: presentation,
              committedViewport: _committedViewport,
            );
            _recordRenderDomainTransition(frame, presentation, renderDomain);
            final viewportId = payload?.viewportId ?? 0;
            final previousViewportId = _lastViewportId;
            if (previousViewportId != null &&
                previousViewportId != viewportId) {
              widget.performanceCounters?.increment(
                DashboardPerformanceMetric.logRenderSurfaceUpdate,
              );
            }
            _lastViewportId = viewportId;

            // A scene selection is structural data, not a paint sample. Logging it
            // once per selected viewport keeps profile diagnostics useful without
            // introducing per-frame console traffic on a fling.
            if (payload != null &&
                _lastLoggedSceneViewportId != viewportId &&
                _sceneCache.sceneFor(payload) != null) {
              _lastLoggedSceneViewportId = viewportId;
              FluviDiagnosticLogger.log(
                FluviDiagnosticEvent(
                  stage: 'LOGBOX_SCENE_SELECTED',
                  queryKey: payload.queryKey.value,
                  entryCount: payload.flatItems.length,
                ),
              );
            }

            final previewSurfaceHeight = _contentHeight(
              payload,
              widget.minimumHeight,
              committedViewport: _committedViewport,
              useCommittedViewport: false,
            );
            final binding = _DashboardLogBoxRenderBinding(
              payloadFrame: frame,
              presentation: presentation,
              payload: payload,
              renderDomain: renderDomain,
              previewSurfaceHeight: previewSurfaceHeight,
              surfaceHeight:
                  renderDomain == DashboardLogBoxRenderDomain.committedVertical
                  ? _contentHeight(
                      payload,
                      widget.minimumHeight,
                      committedViewport: _committedViewport,
                      useCommittedViewport: true,
                    )
                  : previewSurfaceHeight,
            );
            final painter = _DashboardLogBoxSurfacePainter(
              payload: binding.payload,
              resources: _paintResources,
              sceneCache: _sceneCache,
              sceneGeneration: _sceneCache.generation,
              rasters: widget.preparedRasters,
              committedViewport: _committedViewport,
              committedGeneration: _committedViewport.presentationGeneration,
              renderDomain: binding.renderDomain,
              scrollController: widget.scrollController,
              onEntryTap: widget.onEntryTap,
              performanceCounters: widget.performanceCounters,
              renderDiagnostics: widget.renderDiagnostics,
            );
            _latestPainter = painter;

            final buildMicros = measure
                ? developer.Timeline.now - buildStarted
                : 0;
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
              height: binding.surfaceHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (payload != null) {
                    if (presentation?.mode == DashboardVisibleMode.committed &&
                        presentation?.queryKey == payload.queryKey &&
                        presentation?.coreRevision == payload.revision &&
                        presentation?.viewportId == payload.viewportId) {
                      _committedViewport.configureSurfaceWidth(
                        constraints.maxWidth,
                      );
                    }
                    _scheduleExtentPublication(binding);
                    _announceSurfaceLaidOut(
                      frame: frame!,
                      payload: payload,
                      surfaceWidth: constraints.maxWidth,
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final entryId = _latestPainter?.entryAt(
                        details.localPosition,
                      );
                      if (entryId != null) widget.onEntryTap?.call(entryId);
                    },
                    child: CustomPaint(
                      key: _stableLogBoxRenderSurfaceKey,
                      painter: painter,
                      isComplex: true,
                      willChange: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
  );

  void _recordRenderDomainTransition(
    DashboardVisibleFrame? payloadFrame,
    DashboardLogBoxPresentationBinding? presentation,
    DashboardLogBoxRenderDomain next,
  ) {
    final previous = _lastRenderDomain;
    if (previous == next) return;
    _lastRenderDomain = next;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'LOGBOX_RENDER_DOMAIN_CHANGED',
        queryKey: presentation?.queryKey.value ?? payloadFrame?.queryKey.value,
        coreRevision: presentation?.coreRevision ?? payloadFrame?.coreRevision,
        message:
            'fromDomain=${previous?.name ?? 'none'} toDomain=${next.name} '
            'frameMode=${presentation?.mode.name ?? 'none'} '
            'payloadLaneMode=${payloadFrame?.mode.name ?? 'none'} '
            'presentationEpoch=${presentation?.presentationEpoch ?? -1} '
            'committedVerticalQuery=${_committedViewport.queryKey?.value ?? 'none'} '
            'committedVerticalGeneration=${_committedViewport.generation ?? -1} '
            'verticalActive=${_committedViewport.isVerticalRenderingActive} '
            'rootPagePresent=${_committedViewport.rootPagePresent} '
            'scrollPixels=${widget.scrollController.hasClients ? widget.scrollController.offset.round() : 0}',
      ),
    );
  }

  void _scheduleExtentPublication(_DashboardLogBoxRenderBinding binding) {
    final signature = Object.hash(
      binding.presentation,
      binding.payloadFrame?.mode,
      binding.payload?.viewportId,
      binding.renderDomain,
      binding.previewSurfaceHeight,
      _committedViewport.contiguousReadyRowCount,
      _committedViewport.drawableExtent,
      binding.surfaceHeight,
    );
    if (_lastExtentPublicationSignature == signature) return;
    _lastExtentPublicationSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) return;
      final position = widget.scrollController.position;
      final expectedMax = math.max(
        0.0,
        DashboardLogBoxTokens.summaryHeaderHeight +
            binding.surfaceHeight -
            position.viewportDimension,
      );
      const tolerance = 1.0;
      final mismatch =
          binding.renderDomain ==
              DashboardLogBoxRenderDomain.committedVertical &&
          (_committedViewport.drawableExtent >
                  binding.surfaceHeight + tolerance ||
              position.maxScrollExtent + tolerance < expectedMax);
      final rendersCommitted =
          binding.renderDomain == DashboardLogBoxRenderDomain.committedVertical;
      final snapshot = DashboardLogBoxRenderExtentSnapshot(
        presentation: binding.presentation,
        payloadLaneMode: binding.payloadFrame?.mode,
        payloadViewportId: binding.payload?.viewportId,
        renderDomain: binding.renderDomain,
        renderedRowCount: rendersCommitted
            ? _committedViewport.contiguousReadyRowCount
            : binding.payload?.flatItems.length ?? 0,
        renderedContentExtent: binding.surfaceHeight,
        previewPayloadRows: binding.payload?.flatItems.length ?? 0,
        previewSurfaceHeight: binding.previewSurfaceHeight,
        committedCacheQueryKey: _committedViewport.queryKey?.value,
        committedCacheGeneration: _committedViewport.generation,
        committedCacheReadyRows: _committedViewport.contiguousReadyRowCount,
        committedCacheDrawableExtent: _committedViewport.drawableExtent,
        renderSurfaceHeight: binding.surfaceHeight,
        sliverScrollExtent: binding.surfaceHeight,
        viewportDimension: position.viewportDimension,
        minScrollExtent: position.minScrollExtent,
        maxScrollExtent: position.maxScrollExtent,
        pixels: position.pixels,
        isMismatch: mismatch,
      );
      widget.onExtentPublished?.call(snapshot);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_EXTENT_PUBLISHED',
          queryKey:
              binding.presentation?.queryKey.value ??
              binding.payload?.queryKey.value,
          coreRevision:
              binding.presentation?.coreRevision ?? binding.payload?.revision,
          entryCount: snapshot.renderedRowCount,
          message:
              'mode=${binding.presentation?.mode.name ?? 'unbound'} '
              'payloadLaneMode=${binding.payloadFrame?.mode.name ?? 'unbound'} '
              'renderDomain=${binding.renderDomain.name} '
              'payloadViewportId=${binding.payload?.viewportId ?? -1} '
              'authoritativeViewportId=${binding.presentation?.viewportId ?? -1} '
              'renderedRowCount=${snapshot.renderedRowCount} '
              'renderedContentExtent=${snapshot.renderedContentExtent.round()} '
              'previewPayloadRows=${snapshot.previewPayloadRows} '
              'previewSurfaceHeight=${snapshot.previewSurfaceHeight.round()} '
              'committedCacheQuery=${snapshot.committedCacheQueryKey ?? 'none'} '
              'committedCacheGeneration=${snapshot.committedCacheGeneration ?? -1} '
              'committedCacheReadyRows=${snapshot.committedCacheReadyRows} '
              'committedCacheDrawableExtent=${snapshot.committedCacheDrawableExtent.round()} '
              'renderSurfaceHeight=${snapshot.renderSurfaceHeight.round()} '
              'sliverScrollExtent=${snapshot.sliverScrollExtent.round()} '
              'viewportDimension=${snapshot.viewportDimension.round()} '
              'minScrollExtent=${snapshot.minScrollExtent.round()} '
              'maxScrollExtent=${snapshot.maxScrollExtent.round()} '
              'pixels=${snapshot.pixels.round()}',
        ),
      );
      if (mismatch && _lastMismatchSignature != signature) {
        _lastMismatchSignature = signature;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'VERTICAL_SCROLL_EXTENT_MISMATCH',
            queryKey:
                binding.presentation?.queryKey.value ??
                binding.payload?.queryKey.value,
            coreRevision:
                binding.presentation?.coreRevision ?? binding.payload?.revision,
            entryCount: snapshot.renderedRowCount,
            error: 'Committed cache extent was not exposed by Flutter layout.',
            message:
                'cacheExtent=${snapshot.committedCacheDrawableExtent.round()} '
                'surfaceHeight=${snapshot.renderSurfaceHeight.round()} '
                'sliverExtent=${snapshot.sliverScrollExtent.round()} '
                'maxScrollExtent=${snapshot.maxScrollExtent.round()} '
                'viewportDimension=${snapshot.viewportDimension.round()} '
                'pixels=${snapshot.pixels.round()}',
          ),
        );
      }
    });
  }

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
    final providedWindow = widget.sceneWindowProvider?.call();
    final providedPayloads = widget.renderCriticalPayloads?.call();
    final window =
        providedWindow ??
        DashboardLogBoxSceneWindow(
          identity: 'surface:${frame.queryKey.value}:${frame.frameGeneration}',
          payloads: providedPayloads == null || providedPayloads.isEmpty
              ? <DashboardLogViewportState>[payload]
              : providedPayloads,
        );
    await _sceneCache.prepareWindow(
      window: window,
      surfaceWidth: surfaceWidth,
      // Standalone/component mounts do not own the app-readiness barrier and
      // must not leave a scheduled chunk behind when a test or route disposes
      // them immediately. The production readiness owner supplies the exact
      // presented callback and receives bounded scheduler chunks.
      yieldEveryRows: widget.onWarmupTextLayoutsPrepared == null
          ? _sceneCache.maximumPinnedRows + 1
          : 64,
    );
    _sceneCache.activateWindow(window);
    if (!mounted) return;
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutPreparedRow,
      by: _sceneCache.preparedRowCount,
    );
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutPreparedDayHeader,
      by: _sceneCache.preparedDayHeaderCount,
    );
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutRetainedBytes,
      by: _sceneCache.estimatedBytes,
    );
    widget.onTextLayoutsPrepared?.call(
      preparedRowCount: _sceneCache.preparedRowCount,
      preparedDayHeaderCount: _sceneCache.preparedDayHeaderCount,
      estimatedBytes: _sceneCache.estimatedBytes,
    );
    setState(() {});
    widget.renderDiagnostics?.recordFirstUseCompleted(
      subsystem: DashboardRenderSubsystem.textLayoutSlots,
      queryKey: frame.queryKey.value,
      entryCount: _sceneCache.preparedRowCount,
      durationMicros: developer.Timeline.now - started,
    );
    widget.onWarmupTextLayoutsPrepared?.call(payload.viewportId);
  }

  void _seedStandaloneCommittedViewport(
    DashboardVisibleFrame frame,
    DashboardLogViewportState payload,
  ) {
    final existing = _committedViewport.pageForOrdinal(0);
    if (_committedViewport.queryKey == frame.queryKey &&
        _committedViewport.coreRevision == frame.coreRevision &&
        existing?.payload.viewportId == payload.viewportId) {
      return;
    }
    _committedViewport.seed(
      CommittedLogPage(
        queryKey: frame.queryKey,
        coreRevision: frame.coreRevision,
        generation: frame.presentationEpoch,
        ordinal: 0,
        startCursor: null,
        previousStartCursor: null,
        payload: payload,
      ),
      generation: frame.presentationEpoch,
    );
  }

  static double _contentHeight(
    DashboardLogViewportState? payload,
    double minimumHeight, {
    required CommittedLogViewportCache committedViewport,
    required bool useCommittedViewport,
  }) {
    if (useCommittedViewport && committedViewport.contentHeight > 0) {
      return math.max(minimumHeight, committedViewport.contentHeight);
    }
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

/// One immutable surface decision. The payload lane may intentionally retain
/// a preview frame after settle, while [presentation] carries the authoritative
/// committed mode that selects the vertical geometry.
@immutable
final class _DashboardLogBoxRenderBinding {
  const _DashboardLogBoxRenderBinding({
    required this.payloadFrame,
    required this.presentation,
    required this.payload,
    required this.renderDomain,
    required this.previewSurfaceHeight,
    required this.surfaceHeight,
  });

  final DashboardVisibleFrame? payloadFrame;
  final DashboardLogBoxPresentationBinding? presentation;
  final DashboardLogViewportState? payload;
  final DashboardLogBoxRenderDomain renderDomain;
  final double previewSurfaceHeight;
  final double surfaceHeight;
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
    required this.sceneCache,
    required this.sceneGeneration,
    required this.rasters,
    required this.committedViewport,
    required this.committedGeneration,
    required this.renderDomain,
    required this.scrollController,
    required this.onEntryTap,
    required this.performanceCounters,
    required this.renderDiagnostics,
  });

  static const _paintOverscan = 90.0;

  final DashboardLogViewportState? payload;
  final _DashboardLogBoxPaintResources resources;
  final DashboardLogBoxPreparedSceneCache sceneCache;
  final int sceneGeneration;
  final PreparedLogBoxRasterSet rasters;
  final CommittedLogViewportCache committedViewport;
  final int committedGeneration;
  final DashboardLogBoxRenderDomain renderDomain;
  final ScrollController scrollController;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  bool _reportedTextLayoutMiss = false;
  bool _reportedVerticalCacheMiss = false;

  @override
  void paint(Canvas canvas, Size size) {
    final measure = performanceCounters?.measuresDurations ?? false;
    final started = measure ? developer.Timeline.now : 0;
    final state = payload;
    if (state == null) {
      _recordPaintDuration(started, measure);
      return;
    }
    if (renderDomain == DashboardLogBoxRenderDomain.committedVertical) {
      _paintCommittedViewport(canvas, size, state);
      _recordPaintDuration(started, measure);
      return;
    }
    final scene = sceneCache.sceneFor(state);
    if (scene == null) {
      // Before READY the normal surface is intentionally mounted behind the
      // spinner while its deterministic scene bank is being assembled. That
      // transitional paint is neither interactive nor a rail-critical cache
      // lookup. Once an active bank exists and no rotation is in progress, a
      // miss is an invariant failure and is recorded exactly once below.
      if (sceneCache.activeWindowIdentity != null && !sceneCache.isPreparing) {
        _recordTextLayoutMiss();
      }
      _recordPaintDuration(started, measure);
      return;
    }
    if (state.flatItems.isEmpty) {
      _paintEmpty(canvas, size, scene);
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
      _paintItem(canvas, size.width, item, rowTop, scene);
      resourceCursor += 1;
    }
    performanceCounters?.increment(
      DashboardPerformanceMetric.logVisibleSlotPaint,
      by: resourceCursor,
    );
    _recordPaintDuration(started, measure);
  }

  void _paintCommittedViewport(
    Canvas canvas,
    Size size,
    DashboardLogViewportState state,
  ) {
    if (committedViewport.totalEntryCount == 0) {
      final scene = sceneCache.sceneFor(state);
      if (scene != null) _paintEmpty(canvas, size, scene);
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
    final initialRailScene = sceneCache.sceneFor(state);
    var ordinal = committedViewport.pageOrdinalForOffset(visibleTop);
    var resourceCursor = 0;
    // The geometry ends at the contiguous drawable frontier. Never probe a
    // future total-count page here: an unloaded page has neither a prepared
    // scene nor drawable content and must not be part of the paint contract.
    while (ordinal <= committedViewport.highestReadyPageOrdinal) {
      final pageTop = committedViewport.pageTopForOrdinal(ordinal);
      if (pageTop > visibleBottom) break;
      final page = committedViewport.pageForOrdinal(ordinal);
      final prepared = committedViewport.preparedPageForOrdinal(ordinal);
      final usesInitialRailPreview =
          ordinal == 0 &&
          page?.payload.viewportId == state.viewportId &&
          initialRailScene != null;
      if (page == null || (prepared == null && !usesInitialRailPreview)) {
        _recordVerticalCacheMiss(state, ordinal);
        ordinal += 1;
        continue;
      }
      _paintCommittedPageBackgrounds(
        canvas,
        size,
        page.payload,
        pageTop: pageTop,
        visibleTop: visibleTop,
        visibleBottom: visibleBottom,
      );
      for (final item in page.payload.flatItems) {
        final rowTop = pageTop + _rowTop(item);
        if (rowTop > visibleBottom) break;
        if (rowTop + DashboardLogBoxTokens.rowHeight < visibleTop) continue;
        if (prepared != null) {
          _paintCommittedItem(
            canvas,
            size.width,
            item,
            rowTop,
            pageTop,
            prepared,
          );
        } else {
          // Page zero is the immutable, already-complete rail preview. It is
          // intentionally borrowed for the first committed vertical frame so
          // scroll start never lays out a duplicate paragraph bank.
          _paintItem(canvas, size.width, item, rowTop, initialRailScene!);
        }
        resourceCursor += 1;
      }
      ordinal += 1;
    }
    performanceCounters?.increment(
      DashboardPerformanceMetric.logVisibleSlotPaint,
      by: resourceCursor,
    );
  }

  void _paintCommittedPageBackgrounds(
    Canvas canvas,
    Size size,
    DashboardLogViewportState state, {
    required double pageTop,
    required double visibleTop,
    required double visibleBottom,
  }) {
    final first = _firstPossiblyVisibleGroup(
      state.groupLayouts,
      math.max(0, visibleTop - pageTop),
    );
    for (var index = first; index < state.groupLayouts.length; index += 1) {
      final group = state.groupLayouts[index];
      if (group.rowCount == 0) continue;
      final top = pageTop + _groupRowTop(group);
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

  void _paintCommittedItem(
    Canvas canvas,
    double width,
    DashboardLogViewportItemViewModel item,
    double rowTop,
    double pageTop,
    CommittedPreparedLogPage page,
  ) {
    final preparedText = page.rowFor(item);
    final dayLabel = item.dayLabel;
    final header = dayLabel == null ? null : page.dayHeaderFor(dayLabel);
    if (preparedText == null || (dayLabel != null && header == null)) {
      _recordVerticalCacheMiss(payload ?? page.page.payload, page.page.ordinal);
      return;
    }
    if (header != null) {
      header.paint(
        canvas,
        Offset(
          DashboardLogBoxTokens.horizontalGutter,
          pageTop +
              _groupHeaderTop(item.groupIndex, item.flatRowIndex) +
              DashboardLogBoxTokens.dayHeaderTopInset,
        ),
      );
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
    preparedText.paint(canvas, rowTop);
  }

  void _recordVerticalCacheMiss(DashboardLogViewportState state, int ordinal) {
    if (_reportedVerticalCacheMiss) return;
    _reportedVerticalCacheMiss = true;
    performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutFallback,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_CACHE_MISS',
        queryKey: state.queryKey.value,
        entryCount: state.entryCount,
        error: 'Committed LogBox page $ordinal was not ready.',
      ),
    );
  }

  void _recordPaintDuration(int started, bool measure) {
    if (!measure) return;
    performanceCounters!.increment(
      DashboardPerformanceMetric.logSurfacePaintMicros,
      by: developer.Timeline.now - started,
    );
  }

  void _paintEmpty(
    Canvas canvas,
    Size size,
    DashboardPreparedLogBoxScene scene,
  ) {
    final painter = scene.empty;
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
    DashboardPreparedLogBoxScene scene,
  ) {
    final preparedText = scene.rowFor(item.row);
    if (preparedText == null) {
      _recordTextLayoutMiss(item.row);
      return;
    }
    final dayLabel = item.dayLabel;
    if (dayLabel != null) {
      final header = scene.dayHeaderFor(dayLabel);
      if (header == null) {
        _recordTextLayoutMiss(item.row);
        return;
      }
      header.paint(
        canvas,
        Offset(
          DashboardLogBoxTokens.horizontalGutter,
          _groupHeaderTop(item.groupIndex, item.flatRowIndex) +
              DashboardLogBoxTokens.dayHeaderTopInset,
        ),
      );
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

    preparedText.paint(canvas, rowTop);
  }

  void _recordTextLayoutMiss([DashboardLogRowViewModel? row]) {
    if (_reportedTextLayoutMiss) return;
    _reportedTextLayoutMiss = true;
    sceneCache.recordTextLayoutMiss();
    performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutFallback,
    );
    final queryKey = payload?.queryKey.value ?? row?.entryId ?? 'unbound';
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'TEXT_LAYOUT_MISS',
        queryKey: queryKey,
        entryCount: payload?.entryCount,
        error: 'A ready LogBox scene was incomplete.',
      ),
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'RAIL_CRITICAL_CACHE_MISS',
        queryKey: queryKey,
        entryCount: payload?.entryCount,
      ),
    );
    renderDiagnostics?.recordRailCriticalCacheMiss(
      subsystem: DashboardRenderSubsystem.textLayoutSlots,
      queryKey: queryKey,
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
    if (renderDomain == DashboardLogBoxRenderDomain.committedVertical) {
      return _committedItemAt(position.dy)?.row.entryId;
    }
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

  DashboardLogViewportItemViewModel? _committedItemAt(double verticalOffset) {
    final ordinal = committedViewport.pageOrdinalForOffset(verticalOffset);
    final page = committedViewport.pageForOrdinal(ordinal);
    if (page == null) return null;
    final localOffset =
        verticalOffset - committedViewport.pageTopForOrdinal(ordinal);
    final index = _firstPossiblyVisibleItem(
      page.payload.flatItems,
      localOffset,
    );
    if (index >= page.payload.flatItems.length) return null;
    final item = page.payload.flatItems[index];
    final top = _rowTop(item);
    return localOffset >= top &&
            localOffset <= top + DashboardLogBoxTokens.rowHeight
        ? item
        : null;
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
    final result = <CustomPainterSemantics>[];
    if (renderDomain == DashboardLogBoxRenderDomain.committedVertical) {
      var ordinal = committedViewport.pageOrdinalForOffset(viewportTop);
      while (ordinal <= committedViewport.highestReadyPageOrdinal &&
          result.length < 24) {
        final page = committedViewport.pageForOrdinal(ordinal);
        final prepared = committedViewport.preparedPageForOrdinal(ordinal);
        final usesInitialRailPreview =
            ordinal == 0 &&
            page?.payload.viewportId == state.viewportId &&
            sceneCache.sceneFor(state) != null;
        if (page == null || (prepared == null && !usesInitialRailPreview)) {
          ordinal += 1;
          continue;
        }
        final pageTop = committedViewport.pageTopForOrdinal(ordinal);
        final first = _firstPossiblyVisibleItem(
          page.payload.flatItems,
          math.max(0, viewportTop - pageTop),
        );
        for (
          var index = first;
          index < page.payload.flatItems.length && result.length < 24;
          index += 1
        ) {
          final item = page.payload.flatItems[index];
          final top = pageTop + _rowTop(item);
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
        ordinal += 1;
      }
      performanceCounters?.increment(
        DashboardPerformanceMetric.logSemanticsNodeUpdate,
        by: result.length,
      );
      return result;
    }
    final first = _firstPossiblyVisibleItem(state.flatItems, viewportTop);
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
      sceneGeneration != oldDelegate.sceneGeneration ||
      committedGeneration != oldDelegate.committedGeneration ||
      renderDomain != oldDelegate.renderDomain ||
      !identical(rasters, oldDelegate.rasters);

  @override
  bool shouldRebuildSemantics(_DashboardLogBoxSurfacePainter oldDelegate) =>
      payload?.viewportId != oldDelegate.payload?.viewportId ||
      committedGeneration != oldDelegate.committedGeneration ||
      renderDomain != oldDelegate.renderDomain ||
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
