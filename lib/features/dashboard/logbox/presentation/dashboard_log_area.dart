import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../performance/dashboard_performance_trace.dart';
import '../application/dashboard_log_area_state.dart';
import 'dashboard_day_log_group.dart';

/// The dashboard's only vertical transaction scroll host.
///
/// It receives a narrow presentation state/API: no DAO, platform channel,
/// query controller, Room entity or raw cursor is reachable from this layer.
/// Its fixed count label is composed by [DashboardLogBoxViewport], keeping this
/// widget focused on scrolling slivers only.
class DashboardLogArea extends StatelessWidget {
  const DashboardLogArea({
    required this.state,
    required this.onLoadNextPage,
    required this.onRetry,
    required this.onEntryTap,
    this.scrollController,
    super.key,
  });

  final DashboardLogAreaState state;
  final VoidCallback onLoadNextPage;
  final VoidCallback onRetry;
  final ValueChanged<String> onEntryTap;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-area-repaint-boundary'),
      child: switch (state) {
        DashboardLogInitialLoading() => _LogScrollHost(
          controller: scrollController,
          onLoadNextPage: onLoadNextPage,
          slivers: const [_LogHeaderClearanceSliver(), _LogLoadingSliver()],
        ),
        DashboardLogPreviewLoading() => _LogScrollHost(
          controller: scrollController,
          onLoadNextPage: null,
          slivers: const [_LogHeaderClearanceSliver(), _LogLoadingSliver()],
        ),
        DashboardLogData(
          :final viewGroups,
          :final hasNextPage,
          :final isPreview,
          :final isLoadingNextPage,
        ) =>
          _LogScrollHost(
            controller: scrollController,
            onLoadNextPage: !isPreview && hasNextPage ? onLoadNextPage : null,
            slivers: [
              const _LogHeaderClearanceSliver(),
              for (var index = 0; index < viewGroups.length; index += 1)
                DashboardDayLogGroupSliver(
                  model: viewGroups[index],
                  onEntryTap: onEntryTap,
                  showGroupGap: index < viewGroups.length - 1,
                ),
              if (isLoadingNextPage) const _LogNextPageLoadingSliver(),
            ],
          ),
        DashboardLogEmpty() => _LogScrollHost(
          controller: scrollController,
          onLoadNextPage: null,
          slivers: [const _LogHeaderClearanceSliver(), const _LogEmptySliver()],
        ),
        DashboardLogError(:final previousData) => _LogScrollHost(
          controller: scrollController,
          onLoadNextPage: previousData?.hasNextPage == true
              ? onLoadNextPage
              : null,
          slivers: [
            const _LogHeaderClearanceSliver(),
            _LogErrorSliver(onRetry: onRetry),
          ],
        ),
      },
    );
  }
}

/// Full LogBox presentation viewport shared by the dashboard and golden tests.
///
/// It overlays the opaque fixed header on the one lazy scroll host. Both
/// children receive the same immutable committed state; neither owns query or
/// interaction state.
class DashboardLogBoxViewport extends StatefulWidget {
  const DashboardLogBoxViewport({
    required this.state,
    required this.onLoadNextPage,
    required this.onRetry,
    required this.onEntryTap,
    super.key,
  });

  final DashboardLogAreaState state;
  final VoidCallback onLoadNextPage;
  final VoidCallback onRetry;
  final ValueChanged<String> onEntryTap;

  @override
  State<DashboardLogBoxViewport> createState() =>
      _DashboardLogBoxViewportState();
}

class _DashboardLogBoxViewportState extends State<DashboardLogBoxViewport> {
  DashboardLogAreaState? _lastTracedPreviewState;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _schedulePreviewFirstPaintTrace();
  }

  @override
  void didUpdateWidget(covariant DashboardLogBoxViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      _schedulePreviewFirstPaintTrace();
    }
  }

  void _schedulePreviewFirstPaintTrace() {
    final state = widget.state;
    if (!state.isPreview ||
        state is! DashboardLogData && state is! DashboardLogEmpty ||
        identical(_lastTracedPreviewState, state)) {
      return;
    }
    _lastTracedPreviewState = state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(widget.state, state)) return;
      final rowCount = switch (state) {
        DashboardLogData(:final groups) => groups.fold<int>(
          0,
          (count, group) => count + group.rows.length,
        ),
        DashboardLogEmpty() => 0,
        _ => 0,
      };
      DashboardPerformanceTrace.record(
        DashboardPerformanceTraceKind.logPreviewFirstPaint,
        valueA: rowCount,
        valueB: state.coreRevision ?? -1,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('dashboard-logbox-viewport'),
    clipBehavior: Clip.hardEdge,
    children: [
      DashboardLogArea(
        state: widget.state,
        onLoadNextPage: widget.onLoadNextPage,
        onRetry: widget.onRetry,
        onEntryTap: widget.onEntryTap,
        scrollController: _scrollController,
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: DashboardLogBoxTokens.summaryHeaderHeight,
        child: RepaintBoundary(
          child: DashboardLogBoxFloatingHeader(state: widget.state),
        ),
      ),
    ],
  );
}

/// Fixed visual sibling of [DashboardLogArea]'s scroll host.
///
/// The committed LogBox state is still its only data source. Its page-color
/// surface deliberately occludes day groups as they scroll below the count;
/// it owns neither gestures nor query state.
class DashboardLogBoxFloatingHeader extends StatelessWidget {
  const DashboardLogBoxFloatingHeader({required this.state, super.key});

  final DashboardLogAreaState state;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ColoredBox(
      key: const ValueKey('dashboard-logbox-floating-header'),
      color: FluviVisualTokens.pageBackground,
      child: Center(
        child: Text(
          '${_entryCount(state)} tranzakció listázva',
          key: const ValueKey('dashboard-logbox-entry-count'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FluviVisualTokens.logBoxHeaderTextStyle,
        ),
      ),
    ),
  );

  static String _entryCount(DashboardLogAreaState state) => switch (state) {
    DashboardLogInitialLoading() => '—',
    DashboardLogPreviewLoading(:final metrics) =>
      '${metrics.entryCount ?? '—'}',
    DashboardLogData(:final snapshot) =>
      '${snapshot.summaryMetrics.entryCount ?? 0}',
    DashboardLogEmpty(:final snapshot) =>
      '${snapshot.summaryMetrics.entryCount ?? 0}',
    DashboardLogError(:final previousData) =>
      '${previousData?.snapshot.summaryMetrics.entryCount ?? '—'}',
  };
}

class _LogScrollHost extends StatelessWidget {
  const _LogScrollHost({
    required this.slivers,
    required this.onLoadNextPage,
    this.controller,
  });

  final List<Widget> slivers;
  final VoidCallback? onLoadNextPage;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 360) onLoadNextPage?.call();
        return false;
      },
      child: CustomScrollView(
        key: const ValueKey('dashboard-logbox-scroll-view'),
        controller: controller,
        cacheExtent: DashboardLogBoxTokens.cacheExtent,
        slivers: slivers,
      ),
    );
  }
}

/// Preserves initial LogBox clearance under the fixed header. Once scrolled,
/// it leaves the viewport and day groups are clipped by that opaque sibling.
class _LogHeaderClearanceSliver extends StatelessWidget {
  const _LogHeaderClearanceSliver();

  @override
  Widget build(BuildContext context) => const SliverToBoxAdapter(
    child: SizedBox(
      key: ValueKey('dashboard-logbox-scroll-clearance'),
      height: DashboardLogBoxTokens.summaryHeaderHeight,
    ),
  );
}

class _LogLoadingSliver extends StatelessWidget {
  const _LogLoadingSliver();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(
      horizontal: DashboardLogBoxTokens.horizontalGutter,
    ),
    sliver: SliverList.builder(
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: DashboardLogBoxTokens.dayGroupGap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surfaceMuted,
            borderRadius: FluviVisualTokens.logBoxGroupRadius,
          ),
          child: SizedBox(height: DashboardLogBoxTokens.rowHeight * 2),
        ),
      ),
    ),
  );
}

class _LogNextPageLoadingSliver extends StatelessWidget {
  const _LogNextPageLoadingSliver();

  @override
  Widget build(BuildContext context) => const SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}

class _LogEmptySliver extends StatelessWidget {
  const _LogEmptySliver();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Text(
        'Nincs tranzakció ebben az időszakban.',
        key: ValueKey('dashboard-logbox-empty'),
        textAlign: TextAlign.center,
        style: FluviVisualTokens.logBoxHeaderTextStyle,
      ),
    ),
  );
}

class _LogErrorSliver extends StatelessWidget {
  const _LogErrorSliver({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: TextButton(
        key: const ValueKey('dashboard-logbox-retry'),
        onPressed: onRetry,
        child: const Text('A tranzakciók betöltése sikertelen. Újrapróbálás'),
      ),
    ),
  );
}
