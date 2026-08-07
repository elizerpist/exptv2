import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_header.dart';
import 'dashboard_logbox_render_surface.dart';
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
    this.renderCriticalPayloads,
    this.onEntryTap,
    this.onFirstFramePresented,
    this.onWarmupError,
    this.onTextLayoutsPrepared,
    this.performanceCounters,
    this.renderDiagnostics,
    this.renderDiagnosticContextProvider,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final VoidCallback onLoadNextPage;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogBoxFramePresentedCallback? onFirstFramePresented;
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
              onLoadNextPage: widget.onLoadNextPage,
              renderCriticalPayloads: widget.renderCriticalPayloads,
              onEntryTap: widget.onEntryTap,
              onFirstFramePresented: widget.onFirstFramePresented,
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
    required this.onLoadNextPage,
    required this.renderCriticalPayloads,
    required this.onEntryTap,
    required this.onFirstFramePresented,
    required this.onWarmupError,
    required this.onTextLayoutsPrepared,
    required this.performanceCounters,
    required this.renderDiagnostics,
    required this.renderDiagnosticContextProvider,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final double viewportHeight;
  final VoidCallback onLoadNextPage;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogBoxFramePresentedCallback? onFirstFramePresented;
  final DashboardLogBoxWarmupErrorCallback? onWarmupError;
  final DashboardLogBoxTextLayoutPreparedCallback? onTextLayoutsPrepared;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  final DashboardRenderDiagnosticContextProvider?
  renderDiagnosticContextProvider;

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollUpdateNotification>(
    onNotification: (notification) {
      final visible = visibleFrames.value;
      if (visible?.mode == DashboardVisibleMode.committed &&
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
            renderCriticalPayloads: renderCriticalPayloads,
            onEntryTap: onEntryTap,
            onFirstFramePresented: onFirstFramePresented,
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
