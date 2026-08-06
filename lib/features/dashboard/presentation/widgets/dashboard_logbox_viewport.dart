import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_header.dart';

/// Stable LogBox viewport. Its State and ScrollController survive every frame;
/// only the immutable prepared viewport pointer and count leaf are replaced.
final class DashboardLogBoxViewport extends StatefulWidget {
  const DashboardLogBoxViewport({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    required this.onLoadNextPage,
    this.onEntryTap,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

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
              onLoadNextPage: widget.onLoadNextPage,
              onEntryTap: widget.onEntryTap,
              performanceCounters: widget.performanceCounters,
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
    required this.onLoadNextPage,
    required this.onEntryTap,
    required this.performanceCounters,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      key: const ValueKey('dashboard-logbox-scroll-view'),
      controller: controller,
      cacheExtent: DashboardLogBoxTokens.cacheExtent,
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: DashboardLogBoxTokens.summaryHeaderHeight),
        ),
        _DashboardLogContentSliver(
          visibleFrames: visibleFrames,
          onEntryTap: onEntryTap,
          performanceCounters: performanceCounters,
        ),
      ],
    );
    final result = NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        final visible = visibleFrames.value;
        if (visible?.mode == DashboardVisibleMode.committed &&
            visible?.logBox.nextCursor != null &&
            notification.metrics.extentAfter < 360) {
          onLoadNextPage();
        }
        return false;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DashboardLogGroupBackground(
            visibleFrames: visibleFrames,
            controller: controller,
          ),
          scrollView,
        ],
      ),
    );
    return result;
  }
}

final class _DashboardLogContentSliver extends StatelessWidget {
  const _DashboardLogContentSliver({
    required this.visibleFrames,
    required this.onEntryTap,
    required this.performanceCounters,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardVisibleFrame?>(
        valueListenable: visibleFrames.logBoxLane,
        builder: (context, frame, _) {
          final measure = performanceCounters?.measuresDurations ?? false;
          final started = measure ? developer.Timeline.now : 0;
          performanceCounters?.increment(
            DashboardPerformanceMetric.logBoxBuild,
          );
          final current = frame?.logBox;
          final result = current == null || current.flatItems.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Nincs tranzakció ebben az időszakban.',
                      key: const ValueKey('dashboard-logbox-empty'),
                      textAlign: TextAlign.center,
                      style: FluviVisualTokens.logBoxHeaderTextStyle,
                    ),
                  ),
                )
              : SliverList.builder(
                  key: const ValueKey('dashboard-logbox-flat-sliver-list'),
                  itemCount: current.flatItems.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  addSemanticIndexes: false,
                  itemBuilder: (context, index) =>
                      _buildFlatItem(current.flatItems[index]),
                );
          if (measure) {
            performanceCounters!.increment(
              DashboardPerformanceMetric.logViewportBindMicros,
              by: developer.Timeline.now - started,
            );
          }
          return result;
        },
      );

  Widget _buildFlatItem(DashboardLogViewportItemViewModel item) =>
      switch (item.kind) {
        DashboardLogViewportItemKind.dayHeader => Padding(
          key: ValueKey(item.stableId),
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardLogBoxTokens.horizontalGutter,
          ),
          child: Semantics(
            header: true,
            child: SizedBox(
              height: DashboardLogBoxTokens.dayHeaderHeight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: DashboardLogBoxTokens.dayHeaderTopInset,
                ),
                child: Text(
                  item.dayLabel!,
                  style: FluviVisualTokens.logBoxDayHeaderTextStyle,
                ),
              ),
            ),
          ),
        ),
        DashboardLogViewportItemKind.row => Padding(
          key: ValueKey(item.stableId),
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardLogBoxTokens.horizontalGutter,
          ),
          child: DashboardLogRow(
            key: ValueKey(item.row!.entryId),
            model: item.row!,
            showSeparator: item.showSeparator,
            onTap: () => onEntryTap?.call(item.row!.entryId),
            performanceCounters: performanceCounters,
          ),
        ),
        DashboardLogViewportItemKind.groupGap => SizedBox(
          key: ValueKey(item.stableId),
          height: DashboardLogBoxTokens.dayGroupGap,
        ),
      };
}

final class _DashboardLogGroupBackground extends StatelessWidget {
  const _DashboardLogGroupBackground({
    required this.visibleFrames,
    required this.controller,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardVisibleFrame?>(
        valueListenable: visibleFrames.logBoxLane,
        builder: (context, frame, _) {
          final state = frame?.logBox;
          if (state == null || state.flatItems.isEmpty) {
            return const SizedBox.shrink();
          }
          return IgnorePointer(
            child: CustomPaint(
              painter: _DashboardLogGroupBackgroundPainter(
                state: state,
                controller: controller,
              ),
            ),
          );
        },
      );
}

final class _DashboardLogGroupBackgroundPainter extends CustomPainter {
  _DashboardLogGroupBackgroundPainter({
    required this.state,
    required this.controller,
  }) : _boxPainter = const BoxDecoration(
         color: FluviVisualTokens.surface,
         borderRadius: FluviVisualTokens.logBoxGroupRadius,
         boxShadow: FluviVisualTokens.cardSurfaceShadows,
       ).createBoxPainter(),
       super(repaint: controller);

  final DashboardLogViewportState state;
  final ScrollController controller;
  final BoxPainter _boxPainter;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollOffset = controller.hasClients ? controller.offset : 0.0;
    for (final group in state.groupLayouts) {
      if (group.rowCount == 0) continue;
      final contentTop =
          DashboardLogBoxTokens.summaryHeaderHeight +
          (group.groupIndex + 1) * DashboardLogBoxTokens.dayHeaderHeight +
          group.precedingRowCount * DashboardLogBoxTokens.rowHeight +
          group.groupIndex * DashboardLogBoxTokens.dayGroupGap;
      final top = contentTop - scrollOffset;
      final height = group.rowCount * DashboardLogBoxTokens.rowHeight;
      if (top > size.height + 28 || top + height < -28) continue;
      final rect = Rect.fromLTWH(
        DashboardLogBoxTokens.horizontalGutter,
        top,
        size.width - DashboardLogBoxTokens.horizontalGutter * 2,
        height,
      );
      _boxPainter.paint(
        canvas,
        rect.topLeft,
        ImageConfiguration(size: rect.size),
      );
    }
  }

  @override
  bool shouldRepaint(_DashboardLogGroupBackgroundPainter oldDelegate) =>
      state.viewportId != oldDelegate.state.viewportId ||
      !identical(controller, oldDelegate.controller);
}

final class DashboardLogRow extends StatelessWidget {
  const DashboardLogRow({
    required this.model,
    required this.onTap,
    required this.showSeparator,
    this.performanceCounters,
    super.key,
  });

  final DashboardLogRowViewModel model;
  final VoidCallback onTap;
  final bool showSeparator;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(DashboardPerformanceMetric.logRowBuild);
    final amountColor = model.amountStyle == LogAmountStyle.expense
        ? FluviVisualTokens.logBoxExpenseAmount
        : FluviVisualTokens.logBoxIncomeAmount;
    return SizedBox(
      height: DashboardLogBoxTokens.rowHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showSeparator)
            const Positioned(
              top: 0,
              left:
                  DashboardLogBoxTokens.rowHorizontalInset +
                  DashboardLogBoxTokens.avatarSize +
                  DashboardLogBoxTokens.rowGap,
              right: DashboardLogBoxTokens.rowHorizontalInset,
              child: SizedBox(
                height: DashboardLogBoxTokens.dividerHeight,
                child: ColoredBox(color: FluviVisualTokens.border),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: Semantics(
              label: model.semanticLabel,
              button: true,
              child: InkWell(
                key: ValueKey('dashboard-log-row-${model.entryId}'),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashboardLogBoxTokens.rowHorizontalInset,
                    vertical: DashboardLogBoxTokens.rowVerticalInset,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: CategoryVisualBadge(
                          colorHandle: model.categoryColorHandle,
                          iconHandle: model.categoryIconHandle,
                          size: DashboardLogBoxTokens.avatarSize,
                          iconSize: DashboardLogBoxTokens.avatarIconSize,
                        ),
                      ),
                      const SizedBox(width: DashboardLogBoxTokens.rowGap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FluviVisualTokens.logBoxRowTitleTextStyle,
                            ),
                            Text(
                              model.categoryDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  FluviVisualTokens.logBoxRowSecondaryTextStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DashboardLogBoxTokens.rowGap),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            model.formattedAmount,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.right,
                            style: FluviVisualTokens.logBoxRowAmountTextStyle
                                .copyWith(color: amountColor),
                          ),
                          Text(
                            model.displayTime,
                            maxLines: 1,
                            style:
                                FluviVisualTokens.logBoxRowSecondaryTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
