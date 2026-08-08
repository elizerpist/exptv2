import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_header.dart';
import 'dashboard_logbox_render_surface.dart';
import 'dashboard_logbox_prepared_scene_cache.dart';
import 'dashboard_logbox_text_layout_cache.dart';

/// Stable LogBox viewport. Its State, ScrollController, sliver hierarchy and
/// render surface survive every frame; only one immutable bounded payload
/// reference changes.
final class DashboardLogBoxViewport extends StatefulWidget {
  const DashboardLogBoxViewport({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    required this.onLoadNextPage,
    this.onLoadPreviousPage,
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
    this.performanceCounters,
    this.renderDiagnostics,
    this.renderDiagnosticContextProvider,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final VoidCallback onLoadNextPage;
  final VoidCallback? onLoadPreviousPage;
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
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  final DashboardRenderDiagnosticContextProvider?
  renderDiagnosticContextProvider;

  @override
  State<DashboardLogBoxViewport> createState() =>
      _DashboardLogBoxViewportState();
}

final class _DashboardLogBoxViewportState
    extends State<DashboardLogBoxViewport> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logViewportBuild,
    );
    final height = (MediaQuery.sizeOf(context).height - widget.bounds.top)
        .clamp(DashboardLogBoxTokens.summaryHeaderHeight, double.infinity);
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-lane-repaint-boundary'),
      child: SizedBox(
        width: widget.bounds.width,
        height: height,
        child: Stack(
          key: const ValueKey('dashboard-logbox-viewport'),
          clipBehavior: Clip.hardEdge,
          children: [
            _DashboardLogScrollArea(
              visibleFrames: widget.visibleFrames,
              controller: _scrollController,
              viewportHeight: height,
              preparedRasters: widget.preparedRasters,
              committedViewport: widget.committedViewport,
              onLoadNextPage: widget.onLoadNextPage,
              onLoadPreviousPage: widget.onLoadPreviousPage,
              renderCriticalPayloads: widget.renderCriticalPayloads,
              sceneWindowProvider: widget.sceneWindowProvider,
              preparedSceneCache: widget.preparedSceneCache,
              onEntryTap: widget.onEntryTap,
              onWarmupSurfaceAttached: widget.onWarmupSurfaceAttached,
              onWarmupSurfaceLaidOut: widget.onWarmupSurfaceLaidOut,
              onWarmupTextLayoutsPrepared: widget.onWarmupTextLayoutsPrepared,
              onWarmupError: widget.onWarmupError,
              onTextLayoutsPrepared: widget.onTextLayoutsPrepared,
              performanceCounters: widget.performanceCounters,
              renderDiagnostics: widget.renderDiagnostics,
              renderDiagnosticContextProvider:
                  widget.renderDiagnosticContextProvider,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: DashboardLogBoxTokens.summaryHeaderHeight,
              child: DashboardLogBoxHeader(
                bounds: DashboardBounds(
                  left: 0,
                  top: 0,
                  width: widget.bounds.width,
                  height: DashboardLogBoxTokens.summaryHeaderHeight,
                ),
                visibleFrames: widget.visibleFrames,
                performanceCounters: widget.performanceCounters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DashboardLogScrollArea extends StatelessWidget {
  const _DashboardLogScrollArea({
    required this.visibleFrames,
    required this.controller,
    required this.viewportHeight,
    required this.preparedRasters,
    required this.committedViewport,
    required this.onLoadNextPage,
    required this.onLoadPreviousPage,
    required this.renderCriticalPayloads,
    required this.sceneWindowProvider,
    required this.preparedSceneCache,
    required this.onEntryTap,
    required this.onWarmupSurfaceAttached,
    required this.onWarmupSurfaceLaidOut,
    required this.onWarmupTextLayoutsPrepared,
    required this.onWarmupError,
    required this.onTextLayoutsPrepared,
    required this.performanceCounters,
    required this.renderDiagnostics,
    required this.renderDiagnosticContextProvider,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final double viewportHeight;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final VoidCallback onLoadNextPage;
  final VoidCallback? onLoadPreviousPage;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
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
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification is ScrollEndNotification) {
        final committed = committedViewport;
        final visible = visibleFrames.value;
        if (visible?.mode == DashboardVisibleMode.committed &&
            committed != null &&
            committed.hasExactCommittedScope) {
          committed.recordScrollSummary(
            scrollOffset:
                (notification.metrics.pixels -
                        DashboardLogBoxTokens.summaryHeaderHeight)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
          );
        }
        return false;
      }
      if (notification is! ScrollUpdateNotification) return false;
      final visible = visibleFrames.value;
      final committed = committedViewport;
      if (visible?.mode == DashboardVisibleMode.committed &&
          committed != null &&
          committed.hasExactCommittedScope) {
        final contentOffset =
            (notification.metrics.pixels -
                    DashboardLogBoxTokens.summaryHeaderHeight)
                .clamp(0.0, double.infinity);
        final firstPage = committed.pageOrdinalForOffset(
          contentOffset.toDouble(),
        );
        final lastPage = committed.pageOrdinalForOffset(
          contentOffset.toDouble() + notification.metrics.viewportDimension,
        );
        committed.updateVisibleRowWindow(
          start: firstPage * committed.pageSize,
          end: (lastPage + 1) * committed.pageSize,
        );
        if (firstPage <= committed.lowestRetainedOrdinal &&
            committed.lowestRetainedOrdinal > 0) {
          onLoadPreviousPage?.call();
        }
        if (committed.hasMorePages &&
            lastPage >= committed.highestCommittedOrdinal - 1) {
          onLoadNextPage();
        }
      } else if (visible?.mode == DashboardVisibleMode.committed &&
          visible?.logBox.nextCursor != null &&
          notification.metrics.extentAfter < 360) {
        onLoadNextPage();
      }
      return false;
    },
    child: CustomScrollView(
      key: const ValueKey('dashboard-logbox-scroll-view'),
      controller: controller,
      cacheExtent: DashboardLogBoxTokens.cacheExtent,
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: DashboardLogBoxTokens.summaryHeaderHeight),
        ),
        SliverToBoxAdapter(
          child: DashboardLogBoxRenderSurface(
            visibleFrames: visibleFrames,
            scrollController: controller,
            minimumHeight:
                (viewportHeight - DashboardLogBoxTokens.summaryHeaderHeight)
                    .clamp(0, double.infinity),
            preparedRasters: preparedRasters,
            committedViewport: committedViewport,
            renderCriticalPayloads: renderCriticalPayloads,
            sceneWindowProvider: sceneWindowProvider,
            preparedSceneCache: preparedSceneCache,
            onEntryTap: onEntryTap,
            onWarmupSurfaceAttached: onWarmupSurfaceAttached,
            onWarmupSurfaceLaidOut: onWarmupSurfaceLaidOut,
            onWarmupTextLayoutsPrepared: onWarmupTextLayoutsPrepared,
            onWarmupError: onWarmupError,
            onTextLayoutsPrepared: onTextLayoutsPrepared,
            performanceCounters: performanceCounters,
            renderDiagnostics: renderDiagnostics,
            renderDiagnosticContextProvider: renderDiagnosticContextProvider,
          ),
        ),
      ],
    ),
  );
}
