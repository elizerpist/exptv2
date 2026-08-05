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
            ValueListenableBuilder<DashboardVisibleFrame?>(
              valueListenable: widget.visibleFrames,
              builder: (context, frame, _) => _DashboardLogScrollArea(
                state: frame?.logBox,
                visibleFrames: widget.visibleFrames,
                controller: _scrollController,
                onLoadNextPage: widget.onLoadNextPage,
                onEntryTap: widget.onEntryTap,
                performanceCounters: widget.performanceCounters,
              ),
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
    required this.state,
    required this.visibleFrames,
    required this.controller,
    required this.onLoadNextPage,
    required this.onEntryTap,
    required this.performanceCounters,
  });

  final DashboardLogViewportState? state;
  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(DashboardPerformanceMetric.logBoxBuild);
    final current = state;
    final slivers = <Widget>[
      const SliverToBoxAdapter(
        child: SizedBox(height: DashboardLogBoxTokens.summaryHeaderHeight),
      ),
    ];
    if (current == null || current.groups.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'Nincs tranzakció ebben az időszakban.',
              key: const ValueKey('dashboard-logbox-empty'),
              textAlign: TextAlign.center,
              style: FluviVisualTokens.logBoxHeaderTextStyle,
            ),
          ),
        ),
      );
    } else {
      for (var index = 0; index < current.groups.length; index += 1) {
        slivers.add(
          DashboardDayLogGroupSliver(
            key: ValueKey('dashboard-log-day-${current.groups[index].dateKey}'),
            model: current.groups[index],
            showGroupGap: index < current.groups.length - 1,
            onEntryTap: onEntryTap,
            performanceCounters: performanceCounters,
          ),
        );
      }
    }
    return NotificationListener<ScrollUpdateNotification>(
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
        slivers: slivers,
      ),
    );
  }
}

final class DashboardDayLogGroupSliver extends StatelessWidget {
  const DashboardDayLogGroupSliver({
    required this.model,
    required this.showGroupGap,
    required this.onEntryTap,
    this.performanceCounters,
    super.key,
  });

  final DashboardDayLogGroupViewModel model;
  final bool showGroupGap;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
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
                  model.dayLabel,
                  style: FluviVisualTokens.logBoxDayHeaderTextStyle,
                ),
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardLogBoxTokens.horizontalGutter,
        ),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surface,
            borderRadius: FluviVisualTokens.logBoxGroupRadius,
            boxShadow: FluviVisualTokens.cardSurfaceShadows,
          ),
          sliver: SliverFixedExtentList.builder(
            itemExtent: DashboardLogBoxTokens.rowHeight,
            itemCount: model.rows.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            itemBuilder: (context, index) => DashboardLogRow(
              key: ValueKey(model.rows[index].entryId),
              model: model.rows[index],
              showSeparator: index != 0,
              onTap: () => onEntryTap?.call(model.rows[index].entryId),
              performanceCounters: performanceCounters,
            ),
          ),
        ),
      ),
      if (showGroupGap)
        const SliverToBoxAdapter(
          child: SizedBox(height: DashboardLogBoxTokens.dayGroupGap),
        ),
    ],
  );
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
                          colorId: model.categoryColorId,
                          iconId: model.categoryIconId,
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
