import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/committed_vertical_geometry_manifest.dart';
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

/// Structural paint identity for the one stable LogBox [CustomPaint] surface.
///
/// The payload lane is deliberately allowed to retain an otherwise identical
/// preview while the presentation lane advances ownership. A new presentation
/// epoch must still paint its exact prepared rail scene without waiting for a
/// scroll notification or a render-domain transition.
@immutable
final class DashboardLogBoxPaintIdentity {
  const DashboardLogBoxPaintIdentity({
    required this.payloadViewportId,
    required this.presentationEpoch,
    required this.sceneGeneration,
    required this.committedGeneration,
    required this.renderDomain,
    required this.rasterIdentity,
  });

  final int? payloadViewportId;
  final int? presentationEpoch;
  final int sceneGeneration;
  final int committedGeneration;
  final DashboardLogBoxRenderDomain renderDomain;
  final Object rasterIdentity;

  bool requiresRepaintFrom(DashboardLogBoxPaintIdentity previous) =>
      payloadViewportId != previous.payloadViewportId ||
      presentationEpoch != previous.presentationEpoch ||
      sceneGeneration != previous.sceneGeneration ||
      committedGeneration != previous.committedGeneration ||
      renderDomain != previous.renderDomain ||
      !identical(rasterIdentity, previous.rasterIdentity);
}

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
  int? _lastNonemptyPresentationWithoutPaintSignature;
  bool _firstFrameReported = false;
  bool _surfaceWarmupReported = false;
  bool _layoutWarmupReported = false;
  bool _committedViewportRebuildScheduled = false;
  double _devicePixelRatio = 1;

  @override
  void initState() {
    super.initState();
    _paintResources = _DashboardLogBoxPaintResources();
    _ownsSceneCache = widget.preparedSceneCache == null;
    _sceneCache =
        widget.preparedSceneCache ?? DashboardLogBoxPreparedSceneCache();
    _ownsCommittedViewport = widget.committedViewport == null;
    _committedViewport =
        widget.committedViewport ?? CommittedLogViewportCache(pageSize: 24);
    _committedViewport.addListener(_onCommittedViewportChanged);
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logRenderSurfaceCreate,
    );
  }

  @override
  void dispose() {
    _committedViewport.removeListener(_onCommittedViewportChanged);
    if (_ownsSceneCache) _sceneCache.dispose();
    if (_ownsCommittedViewport) _committedViewport.dispose();
    _paintResources.dispose();
    super.dispose();
  }

  void _onCommittedViewportChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }
    if (_committedViewportRebuildScheduled) return;
    _committedViewportRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _committedViewportRebuildScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) => _captureDevicePixelRatio(
    context,
    ValueListenableBuilder<DashboardVisibleFrame?>(
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
                hasExactRailScene:
                    payload != null &&
                    _sceneCache.railCriticalSceneFor(payload) != null,
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
              final selectedScene = payload == null
                  ? null
                  : _sceneCache.railCriticalSceneFor(payload);
              assert(
                selectedScene == null || selectedScene.isCompletelyPrepared,
              );
              if (payload != null &&
                  _lastLoggedSceneViewportId != viewportId &&
                  selectedScene?.isCompletelyPrepared == true) {
                _lastLoggedSceneViewportId = viewportId;
                FluviDiagnosticLogger.log(
                  FluviDiagnosticEvent(
                    stage: 'LOGBOX_SCENE_SELECTED',
                    queryKey: payload.queryKey.value,
                    entryCount: payload.previewRowCount,
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
                    renderDomain ==
                        DashboardLogBoxRenderDomain.committedVertical
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
                presentationEpoch: binding.presentation?.presentationEpoch,
                resources: _paintResources,
                sceneCache: _sceneCache,
                sceneGeneration: _sceneCache.generation,
                rasters: widget.preparedRasters,
                committedViewport: _committedViewport,
                committedGeneration: _committedViewport.renderGeneration,
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
                      if (presentation?.mode ==
                              DashboardVisibleMode.committed &&
                          presentation?.queryKey == payload.queryKey &&
                          presentation?.coreRevision == payload.revision &&
                          presentation?.viewportId == payload.viewportId) {
                        _committedViewport.configureSurfaceWidth(
                          constraints.maxWidth,
                        );
                      }
                      _scheduleExtentPublication(binding, painter);
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
    ),
  );

  Widget _captureDevicePixelRatio(BuildContext context, Widget child) {
    _devicePixelRatio = View.of(context).devicePixelRatio;
    return child;
  }

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

  void _scheduleExtentPublication(
    _DashboardLogBoxRenderBinding binding,
    _DashboardLogBoxSurfacePainter painter,
  ) {
    final signature = Object.hash(
      binding.presentation,
      binding.payloadFrame?.mode,
      binding.payload?.viewportId,
      binding.renderDomain,
      binding.previewSurfaceHeight,
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
        binding.surfaceHeight - position.viewportDimension,
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
      final payloadRowCount = binding.payload?.previewRowCount ?? 0;
      final snapshot = DashboardLogBoxRenderExtentSnapshot(
        presentation: binding.presentation,
        payloadLaneMode: binding.payloadFrame?.mode,
        payloadViewportId: binding.payload?.viewportId,
        renderDomain: binding.renderDomain,
        renderedRowCount: rendersCommitted
            ? _committedViewport.totalEntryCount
            : payloadRowCount,
        payloadRowCount: payloadRowCount,
        drawableRowCount: rendersCommitted
            ? _committedViewport.totalEntryCount
            : painter.lastDrawableRowCount,
        paintedRowCount: painter.lastPaintedRowCount,
        renderedContentExtent: binding.surfaceHeight,
        previewPayloadRows: binding.payload?.previewRowCount ?? 0,
        previewSurfaceHeight: binding.previewSurfaceHeight,
        committedCacheQueryKey: _committedViewport.queryKey?.value,
        committedCacheGeneration: _committedViewport.generation,
        committedCacheReadyRows: _committedViewport.contiguousReadyRowCount,
        committedCacheDrawableExtent: _committedViewport.drawableExtent,
        committedCacheReadyFrontierOrdinal:
            _committedViewport.highestReadyPageOrdinal,
        renderSurfaceHeight: binding.surfaceHeight,
        sliverScrollExtent: binding.surfaceHeight,
        viewportDimension: position.viewportDimension,
        minScrollExtent: position.minScrollExtent,
        maxScrollExtent: position.maxScrollExtent,
        pixels: position.pixels,
        isMismatch: mismatch,
      );
      widget.onExtentPublished?.call(snapshot);
      _reportNonemptyPresentationWithoutPaint(
        binding: binding,
        sceneGeneration: painter.sceneGeneration,
        snapshot: snapshot,
      );
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
              'payloadRowCount=${snapshot.payloadRowCount} '
              'drawableRowCount=${snapshot.drawableRowCount} '
              'paintedRowCount=${snapshot.paintedRowCount} '
              'renderedContentExtent=${snapshot.renderedContentExtent.round()} '
              'previewPayloadRows=${snapshot.previewPayloadRows} '
              'previewSurfaceHeight=${snapshot.previewSurfaceHeight.round()} '
              'committedCacheQuery=${snapshot.committedCacheQueryKey ?? 'none'} '
              'committedCacheGeneration=${snapshot.committedCacheGeneration ?? -1} '
              'committedCacheReadyRows=${snapshot.committedCacheReadyRows} '
              'committedCacheDrawableExtent=${snapshot.committedCacheDrawableExtent.round()} '
              'readyFrontier=${snapshot.committedCacheReadyFrontierOrdinal} '
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

  void _reportNonemptyPresentationWithoutPaint({
    required _DashboardLogBoxRenderBinding binding,
    required int sceneGeneration,
    required DashboardLogBoxRenderExtentSnapshot snapshot,
  }) {
    if (binding.renderDomain != DashboardLogBoxRenderDomain.railPreview ||
        snapshot.payloadRowCount == 0 ||
        snapshot.drawableRowCount == 0 ||
        snapshot.paintedRowCount != 0) {
      return;
    }
    final presentation = binding.presentation;
    final signature = Object.hash(
      presentation?.queryKey,
      presentation?.coreRevision,
      presentation?.presentationEpoch,
      presentation?.viewportId,
      binding.renderDomain,
      sceneGeneration,
    );
    if (_lastNonemptyPresentationWithoutPaintSignature == signature) return;
    _lastNonemptyPresentationWithoutPaintSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'LOGBOX_NONEMPTY_PRESENTATION_WITHOUT_PAINT',
        queryKey:
            presentation?.queryKey.value ?? binding.payload?.queryKey.value,
        coreRevision: presentation?.coreRevision ?? binding.payload?.revision,
        entryCount: snapshot.payloadRowCount,
        error: 'A complete non-empty rail-preview scene did not paint.',
        message:
            'presentationEpoch=${presentation?.presentationEpoch ?? -1} '
            'viewportId=${presentation?.viewportId ?? binding.payload?.viewportId ?? -1} '
            'renderDomain=${binding.renderDomain.name} '
            'sceneGeneration=$sceneGeneration '
            'drawableRowCount=${snapshot.drawableRowCount} '
            'paintedRowCount=${snapshot.paintedRowCount} '
            'scrollPixels=${snapshot.pixels.round()}',
      ),
    );
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
      groupCount: payload.groupCount,
      previewRowCount: payload.previewRowCount,
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
        groupCount: payload.groupCount,
        previewRowCount: payload.previewRowCount,
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
      devicePixelRatio: _devicePixelRatio,
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
    final geometryManifest = _standaloneGeometryManifest(frame, payload);
    if (geometryManifest == null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_VIRTUAL_GEOMETRY_MISMATCH',
          queryKey: frame.queryKey.value,
          coreRevision: frame.coreRevision,
          entryCount: payload.entryCount,
          error: 'Standalone surface received only a bounded preview payload.',
        ),
      );
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
      geometryManifest: geometryManifest,
    );
  }

  CommittedVerticalGeometryManifest? _standaloneGeometryManifest(
    DashboardVisibleFrame frame,
    DashboardLogViewportState payload,
  ) {
    // The production path always receives the exact manifest from the
    // PreparedDashboardIndex through DashboardCoreController. This owned-cache
    // fallback is deliberately fail-closed: a bounded preview cannot invent a
    // full scroll world. It is only valid when this payload actually contains
    // every entry of the committed scope.
    if (payload.previewRowCount != payload.entryCount) return null;
    final buckets = <CommittedVerticalGeometryDayBucket>[];
    for (var index = 0; index < payload.groups.length; index += 1) {
      final group = payload.groups[index];
      if (group.rows.isEmpty) continue;
      buckets.add(
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: 1_000_000 - index,
          entryCount: group.rows.length,
        ),
      );
    }
    try {
      return CommittedVerticalGeometryManifest.compile(
        queryKey: frame.queryKey,
        coreRevision: frame.coreRevision,
        pageSize: _committedViewport.pageSize,
        totalEntryCount: payload.entryCount,
        dayBuckets: buckets,
      );
    } on ArgumentError {
      return null;
    }
  }

  static double _contentHeight(
    DashboardLogViewportState? payload,
    double minimumHeight, {
    required CommittedLogViewportCache committedViewport,
    required bool useCommittedViewport,
  }) {
    if (useCommittedViewport && committedViewport.hasVirtualGeometry) {
      // A committed nonempty scope has exactly one scroll world: the immutable
      // manifest. Adding visual minimum-height padding here would make a
      // second, non-manifest geometry source. Empty scopes retain their
      // non-scrollable presentation area because their exact extent is zero.
      return committedViewport.totalEntryCount == 0
          ? minimumHeight
          : committedViewport.contentHeight;
    }
    if (payload == null || payload.previewRowCount == 0) {
      return minimumHeight;
    }
    final groupDecorationHeight =
        payload.groupCount * DashboardLogBoxTokens.dayHeaderHeight +
        math.max(0, payload.groupCount - 1) * DashboardLogBoxTokens.dayGroupGap;
    final rowHeight = payload.previewRowCount * DashboardLogBoxTokens.rowHeight;
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

@immutable
final class _DashboardLogBoxVisibleWindow {
  const _DashboardLogBoxVisibleWindow({
    required this.contentOffset,
    required this.top,
    required this.bottom,
  });

  /// The current content-local scroll position. A rail preview deliberately
  /// has no committed scroll position, so its value is always zero.
  final double contentOffset;
  final double top;
  final double bottom;
}

final class _DashboardLogBoxSurfacePainter extends CustomPainter {
  _DashboardLogBoxSurfacePainter({
    required this.payload,
    required this.presentationEpoch,
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
  }) : super(
         repaint: Listenable.merge(<Listenable>[
           sceneCache,
           committedViewport.resourceChanges,
         ]),
       );

  static const _paintOverscan = 90.0;

  final DashboardLogViewportState? payload;
  final int? presentationEpoch;
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
  int _lastDrawableRowCount = 0;
  int _lastPaintedRowCount = 0;

  int get lastDrawableRowCount => _lastDrawableRowCount;
  int get lastPaintedRowCount => _lastPaintedRowCount;

  late final DashboardLogBoxPaintIdentity paintIdentity =
      DashboardLogBoxPaintIdentity(
        payloadViewportId: payload?.viewportId,
        presentationEpoch: presentationEpoch,
        sceneGeneration: sceneGeneration,
        committedGeneration: committedGeneration,
        renderDomain: renderDomain,
        rasterIdentity: rasters,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final measure = performanceCounters?.measuresDurations ?? false;
    final started = measure ? developer.Timeline.now : 0;
    final state = payload;
    if (state == null) {
      _lastDrawableRowCount = 0;
      _lastPaintedRowCount = 0;
      _recordPaintDuration(started, measure);
      return;
    }
    if (renderDomain == DashboardLogBoxRenderDomain.committedVertical) {
      _paintCommittedViewport(canvas, size, state);
      _recordPaintDuration(started, measure);
      return;
    }
    final scene = sceneCache.railCriticalSceneFor(state);
    if (scene == null) {
      _lastDrawableRowCount = 0;
      _lastPaintedRowCount = 0;
      if (state.previewRowCount > 0 &&
          sceneCache.railCriticalSceneBank.isComplete) {
        sceneCache.recordVisiblePayloadWithoutDrawable();
        sceneCache.recordVisiblePayloadWithoutPaint();
      }
      // Startup may mount behind its readiness surface before an active bank
      // exists. Once a bank exists, preparation activity cannot suppress a
      // visible rail correctness violation.
      if (sceneCache.activeWindowIdentity != null) {
        _recordTextLayoutMiss();
      }
      _recordPaintDuration(started, measure);
      return;
    }
    if (state.previewRowCount == 0) {
      _lastDrawableRowCount = 0;
      _lastPaintedRowCount = 0;
      _paintEmpty(canvas, size, scene);
      _recordPaintDuration(started, measure);
      return;
    }

    final visibleWindow = _visibleWindow(size);
    _paintGroupBackgrounds(
      canvas,
      size,
      state,
      visibleTop: visibleWindow.top,
      visibleBottom: visibleWindow.bottom,
    );
    final first = _firstPossiblyVisibleItem(state.flatItems, visibleWindow.top);
    _lastDrawableRowCount = state.flatItems.length;
    var resourceCursor = 0;
    for (var index = first; index < state.flatItems.length; index += 1) {
      final item = state.flatItems[index];
      final rowTop = _rowTop(item);
      if (rowTop > visibleWindow.bottom) break;
      if (rowTop + DashboardLogBoxTokens.rowHeight < visibleWindow.top) {
        continue;
      }
      if (_paintItem(canvas, size.width, item, rowTop, scene)) {
        resourceCursor += 1;
      }
    }
    _lastPaintedRowCount = resourceCursor;
    if (resourceCursor == 0) {
      sceneCache.recordVisiblePayloadWithoutPaint();
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
    final manifest = committedViewport.geometryManifest;
    _lastDrawableRowCount = manifest?.totalEntryCount ?? 0;
    _lastPaintedRowCount = 0;
    if (manifest == null) {
      _recordVerticalCacheMiss(state, -1);
      return;
    }
    if (committedViewport.totalEntryCount == 0) {
      final scene = sceneCache.railCriticalSceneFor(state);
      if (scene != null) _paintEmpty(canvas, size, scene);
      return;
    }
    final visibleWindow = _visibleWindow(size);
    final scrollOffset = visibleWindow.contentOffset;
    final visibleTop = visibleWindow.top;
    final visibleBottom = visibleWindow.bottom;
    final initialRailScene = sceneCache.railCriticalSceneFor(state);
    var ordinal = manifest.pageOrdinalForOffset(visibleTop);
    var resourceCursor = 0;
    // The immutable manifest maps this paint to a tiny virtual page range.
    // The bounded resource cache independently decides whether that exact
    // content is ready; a miss never shrinks the scrollable world.
    while (ordinal < manifest.totalPageCount) {
      final pageGeometry = manifest.pageForOrdinal(ordinal)!;
      final pageTop = pageGeometry.top;
      if (pageTop > visibleBottom) break;
      final page = committedViewport.pageForOrdinal(ordinal);
      final prepared = committedViewport.preparedPageForOrdinal(ordinal);
      final usesInitialRailPreview =
          ordinal == 0 &&
          page?.payload.viewportId == state.viewportId &&
          initialRailScene != null;
      if (page == null || (prepared == null && !usesInitialRailPreview)) {
        committedViewport.recordVirtualPageMiss(
          ordinal: ordinal,
          scrollOffset: scrollOffset,
          direction: 'paint',
        );
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
    _lastPaintedRowCount = resourceCursor;
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
    _drawPreparedVectorBadge(
      canvas,
      rasters.badge(row.categoryColorHandle),
      badgeRect,
    );
    final iconRect = Rect.fromCenter(
      center: badgeRect.center,
      width: DashboardLogBoxTokens.avatarIconSize,
      height: DashboardLogBoxTokens.avatarIconSize,
    );
    _drawPreparedVectorGlyph(
      canvas,
      rasters.glyph(row.categoryIconHandle),
      iconRect,
    );
    preparedText.paint(canvas, rowTop);
  }

  void _recordVerticalCacheMiss(DashboardLogViewportState state, int ordinal) {
    if (_reportedVerticalCacheMiss) return;
    _reportedVerticalCacheMiss = true;
    performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutFallback,
    );
    performanceCounters?.increment(
      DashboardPerformanceMetric.verticalCacheMiss,
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

  bool _paintItem(
    Canvas canvas,
    double width,
    DashboardLogViewportItemViewModel item,
    double rowTop,
    DashboardPreparedLogBoxScene scene,
  ) {
    final preparedText = scene.rowFor(item.row);
    if (preparedText == null) {
      _recordTextLayoutMiss(item.row);
      return false;
    }
    final dayLabel = item.dayLabel;
    if (dayLabel != null) {
      final header = scene.dayHeaderFor(dayLabel);
      if (header == null) {
        _recordTextLayoutMiss(item.row);
        return false;
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
    _drawPreparedVectorBadge(
      canvas,
      rasters.badge(row.categoryColorHandle),
      badgeRect,
    );
    final iconRect = Rect.fromCenter(
      center: badgeRect.center,
      width: DashboardLogBoxTokens.avatarIconSize,
      height: DashboardLogBoxTokens.avatarIconSize,
    );
    _drawPreparedVectorGlyph(
      canvas,
      rasters.glyph(row.categoryIconHandle),
      iconRect,
    );

    preparedText.paint(canvas, rowTop);
    return true;
  }

  void _recordTextLayoutMiss([DashboardLogRowViewModel? row]) {
    if (_reportedTextLayoutMiss) return;
    _reportedTextLayoutMiss = true;
    sceneCache.recordTextLayoutMiss();
    performanceCounters?.increment(
      DashboardPerformanceMetric.logTextLayoutFallback,
    );
    performanceCounters?.increment(DashboardPerformanceMetric.textLayoutMiss);
    final queryKey = payload?.queryKey.value ?? row?.entryId ?? 'unbound';
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'TEXT_LAYOUT_MISS',
        queryKey: queryKey,
        entryCount: payload?.entryCount,
        error: 'No complete active LogBox scene was available.',
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

  void _drawPreparedVectorBadge(
    Canvas canvas,
    PreparedLogBoxVectorBadge badge,
    Rect target,
  ) => _drawPreparedVectorResource(canvas, badge, target);

  void _drawPreparedVectorGlyph(
    Canvas canvas,
    PreparedLogBoxVectorGlyph glyph,
    Rect target,
  ) => _drawPreparedVectorResource(canvas, glyph, target);

  void _drawPreparedVectorResource(
    Canvas canvas,
    PreparedLogBoxVectorResource resource,
    Rect target,
  ) {
    final logicalSize = resource.logicalSize;
    if (logicalSize.isEmpty || target.isEmpty) return;
    canvas.save();
    canvas.translate(target.left, target.top);
    canvas.scale(
      target.width / logicalSize.width,
      target.height / logicalSize.height,
    );
    canvas.drawPicture(resource.picture);
    canvas.restore();
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
    final manifest = committedViewport.geometryManifest;
    if (manifest == null) return null;
    final ordinal = manifest.pageOrdinalForOffset(verticalOffset);
    final page = committedViewport.pageForOrdinal(ordinal);
    if (page == null) {
      committedViewport.recordVirtualPageMiss(
        ordinal: ordinal,
        scrollOffset: verticalOffset,
        direction: 'tap',
      );
      return null;
    }
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

  /// Rail preview is the top-anchored, exact prepared first page that is shown
  /// before a real vertical interaction takes ownership. It must not inherit a
  /// prior committed scope's pixels while that stable ScrollPosition is being
  /// reset for a new Query publication. Committed vertical rendering alone
  /// reads its content-local scroll position.
  _DashboardLogBoxVisibleWindow _visibleWindow(Size size) {
    final viewportHeight = scrollController.hasClients
        ? scrollController.position.viewportDimension
        : size.height;
    if (renderDomain == DashboardLogBoxRenderDomain.railPreview) {
      return _DashboardLogBoxVisibleWindow(
        contentOffset: 0,
        top: 0,
        bottom: math.min(size.height, viewportHeight + _paintOverscan),
      );
    }
    final contentOffset = scrollController.hasClients
        ? math.max(0.0, scrollController.offset)
        : 0.0;
    return _DashboardLogBoxVisibleWindow(
      contentOffset: contentOffset,
      top: math.max(0.0, contentOffset - _paintOverscan),
      bottom: math.min(
        size.height,
        contentOffset + viewportHeight + _paintOverscan,
      ),
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final state = payload;
    if (state == null || state.previewRowCount == 0) {
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
    final visibleWindow = _visibleWindow(size);
    final viewportTop = visibleWindow.top;
    final viewportBottom = visibleWindow.bottom;
    final result = <CustomPainterSemantics>[];
    if (renderDomain == DashboardLogBoxRenderDomain.committedVertical) {
      final manifest = committedViewport.geometryManifest;
      if (manifest == null) return result;
      var ordinal = manifest.pageOrdinalForOffset(viewportTop);
      while (ordinal < manifest.totalPageCount && result.length < 24) {
        final pageGeometry = manifest.pageForOrdinal(ordinal)!;
        if (pageGeometry.top > viewportBottom) break;
        final page = committedViewport.pageForOrdinal(ordinal);
        final prepared = committedViewport.preparedPageForOrdinal(ordinal);
        final usesInitialRailPreview =
            ordinal == 0 &&
            page?.payload.viewportId == state.viewportId &&
            sceneCache.railCriticalSceneFor(state) != null;
        if (page == null || (prepared == null && !usesInitialRailPreview)) {
          committedViewport.recordVirtualPageMiss(
            ordinal: ordinal,
            scrollOffset: viewportTop,
            direction: 'semantics',
          );
          ordinal += 1;
          continue;
        }
        final pageTop = pageGeometry.top;
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
      paintIdentity.requiresRepaintFrom(oldDelegate.paintIdentity);

  @override
  bool shouldRebuildSemantics(_DashboardLogBoxSurfacePainter oldDelegate) =>
      payload?.viewportId != oldDelegate.payload?.viewportId ||
      presentationEpoch != oldDelegate.presentationEpoch ||
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
