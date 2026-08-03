import 'package:flutter/material.dart';

import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../logbox/application/dashboard_log_presentation_adapter.dart';
import '../../logbox/application/dashboard_log_view_models.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';
import 'dashboard_logbox_header.dart';

/// Stable LogBox shell. Snapshot changes rebuild only the lane's Listenable
/// child; this State keeps the vertical scroll controller alive.
class DashboardLogBoxViewport extends StatefulWidget {
  const DashboardLogBoxViewport({
    required this.bounds,
    required this.presentation,
    required this.metricsListenable,
    required this.metricsPresentationBuilder,
    required this.onLoadNextPage,
    this.onEntryTap,
    super.key,
  });

  final DashboardBounds bounds;
  final DashboardLogPresentationAdapter presentation;
  final Listenable metricsListenable;
  final SummaryMetricsPresentation Function() metricsPresentationBuilder;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;

  @override
  State<DashboardLogBoxViewport> createState() =>
      _DashboardLogBoxViewportState();
}

class _DashboardLogBoxViewportState extends State<DashboardLogBoxViewport> {
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
        child: ListenableBuilder(
          listenable: widget.presentation,
          builder: (context, _) {
            final state = widget.presentation.state;
            return Stack(
              key: const ValueKey('dashboard-logbox-viewport'),
              clipBehavior: Clip.hardEdge,
              children: [
                _DashboardLogScrollArea(
                  state: state,
                  controller: _scrollController,
                  onLoadNextPage: widget.onLoadNextPage,
                  onEntryTap: widget.onEntryTap,
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
                    metricsListenable: widget.metricsListenable,
                    metricsPresentationBuilder:
                        widget.metricsPresentationBuilder,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardLogScrollArea extends StatelessWidget {
  const _DashboardLogScrollArea({
    required this.state,
    required this.controller,
    required this.onLoadNextPage,
    required this.onEntryTap,
  });

  final DashboardLogViewportState? state;
  final ScrollController controller;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;

  @override
  Widget build(BuildContext context) {
    final current = state;
    final slivers = <Widget>[
      const SliverToBoxAdapter(
        child: SizedBox(height: DashboardLogBoxTokens.summaryHeaderHeight),
      ),
    ];
    if (current == null) {
      slivers.add(const _DashboardLogLoadingSliver());
    } else if (current.groups.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              current.entryCount == 0
                  ? 'Nincs tranzakció ebben az időszakban.'
                  : 'A tranzakciók betöltése folyamatban van.',
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
            model: current.groups[index],
            showGroupGap: index < current.groups.length - 1,
            onEntryTap: onEntryTap,
          ),
        );
      }
    }
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (current?.hasNextPage == true &&
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

class _DashboardLogLoadingSliver extends StatelessWidget {
  const _DashboardLogLoadingSliver();

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: 2,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.only(
        left: DashboardLogBoxTokens.horizontalGutter,
        right: DashboardLogBoxTokens.horizontalGutter,
        bottom: DashboardLogBoxTokens.dayGroupGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FluviVisualTokens.surfaceMuted,
          borderRadius: FluviVisualTokens.logBoxGroupRadius,
        ),
        child: const SizedBox(height: DashboardLogBoxTokens.rowHeight * 2),
      ),
    ),
  );
}

class DashboardDayLogGroupSliver extends StatelessWidget {
  const DashboardDayLogGroupSliver({
    required this.model,
    required this.showGroupGap,
    required this.onEntryTap,
    super.key,
  });

  final DashboardDayLogGroupViewModel model;
  final bool showGroupGap;
  final ValueChanged<String>? onEntryTap;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    key: ValueKey('dashboard-log-day-${model.dateKey}'),
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
              model: model.rows[index],
              showSeparator: index != 0,
              isFirst: index == 0,
              isLast: index == model.rows.length - 1,
              onTap: () => onEntryTap?.call(model.rows[index].entryId),
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

class DashboardLogRow extends StatelessWidget {
  const DashboardLogRow({
    required this.model,
    required this.onTap,
    required this.showSeparator,
    required this.isFirst,
    required this.isLast,
    super.key,
  });

  final DashboardLogRowViewModel model;
  final VoidCallback onTap;
  final bool showSeparator;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
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
