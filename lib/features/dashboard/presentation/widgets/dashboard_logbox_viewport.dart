import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../logbox/application/dashboard_log_presentation_adapter.dart';
import '../../logbox/application/dashboard_log_performance_diagnostics.dart';
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
    this.performanceDiagnostics,
    this.motionEpochProvider,
    this.performanceCounters,
    super.key,
  });

  final DashboardBounds bounds;
  final DashboardLogPresentationAdapter presentation;
  final Listenable metricsListenable;
  final SummaryMetricsPresentation Function() metricsPresentationBuilder;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogPerformanceDiagnostics? performanceDiagnostics;
  final int Function()? motionEpochProvider;
  final DashboardPerformanceCounters? performanceCounters;

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
                _DashboardLogPerformanceProbe(
                  diagnostics: widget.performanceDiagnostics,
                  state: state,
                  motionEpoch: widget.motionEpochProvider?.call() ?? 0,
                  child: _DashboardLogScrollArea(
                    state: state,
                    controller: _scrollController,
                    onLoadNextPage: widget.onLoadNextPage,
                    onEntryTap: widget.onEntryTap,
                    diagnostics: widget.performanceDiagnostics,
                    performanceCounters: widget.performanceCounters,
                    motionEpoch: widget.motionEpochProvider?.call() ?? 0,
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
    required this.diagnostics,
    required this.motionEpoch,
    required this.performanceCounters,
  });

  final DashboardLogViewportState? state;
  final ScrollController controller;
  final VoidCallback onLoadNextPage;
  final ValueChanged<String>? onEntryTap;
  final DashboardLogPerformanceDiagnostics? diagnostics;
  final int motionEpoch;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(DashboardPerformanceMetric.logBoxBuild);
    final stopwatch = Stopwatch()..start();
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
            performanceCounters: performanceCounters,
          ),
        );
      }
    }
    final result = NotificationListener<ScrollUpdateNotification>(
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
    stopwatch.stop();
    if (current != null) {
      diagnostics?.record(
        phase: DashboardLogPerformancePhase.logBoxWidgetBuild,
        queryKey: current.queryKey,
        entryCount: current.entryCount,
        rowCount: _rowCount(current),
        dataAttached: current.groups.isNotEmpty,
        durationMicros: stopwatch.elapsedMicroseconds,
        motionEpoch: motionEpoch,
      );
    }
    return result;
  }
}

class _DashboardLogPerformanceProbe extends SingleChildRenderObjectWidget {
  const _DashboardLogPerformanceProbe({
    required this.diagnostics,
    required this.state,
    required this.motionEpoch,
    required super.child,
  });

  final DashboardLogPerformanceDiagnostics? diagnostics;
  final DashboardLogViewportState? state;
  final int motionEpoch;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _DashboardLogPerformanceRenderObject(
        diagnostics: diagnostics,
        state: state,
        motionEpoch: motionEpoch,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _DashboardLogPerformanceRenderObject renderObject,
  ) {
    renderObject
      ..diagnostics = diagnostics
      ..state = state
      ..motionEpoch = motionEpoch;
  }
}

class _DashboardLogPerformanceRenderObject extends RenderProxyBox {
  _DashboardLogPerformanceRenderObject({
    required this.diagnostics,
    required this.state,
    required this.motionEpoch,
  });

  DashboardLogPerformanceDiagnostics? diagnostics;
  DashboardLogViewportState? state;
  int motionEpoch;

  @override
  void performLayout() {
    final stopwatch = Stopwatch()..start();
    super.performLayout();
    stopwatch.stop();
    _record(
      DashboardLogPerformancePhase.logBoxLayout,
      stopwatch.elapsedMicroseconds,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final stopwatch = Stopwatch()..start();
    super.paint(context, offset);
    stopwatch.stop();
    _record(
      DashboardLogPerformancePhase.logBoxPaint,
      stopwatch.elapsedMicroseconds,
    );
  }

  void _record(DashboardLogPerformancePhase phase, int durationMicros) {
    final current = state;
    if (current == null) return;
    diagnostics?.record(
      phase: phase,
      queryKey: current.queryKey,
      entryCount: current.entryCount,
      rowCount: _rowCount(current),
      dataAttached: current.groups.isNotEmpty,
      durationMicros: durationMicros,
      motionEpoch: motionEpoch,
    );
  }
}

int _rowCount(DashboardLogViewportState state) =>
    state.groups.fold<int>(0, (total, group) => total + group.rows.length);

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
    this.performanceCounters,
    super.key,
  });

  final DashboardDayLogGroupViewModel model;
  final bool showGroupGap;
  final ValueChanged<String>? onEntryTap;
  final DashboardPerformanceCounters? performanceCounters;

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

class DashboardLogRow extends StatelessWidget {
  const DashboardLogRow({
    required this.model,
    required this.onTap,
    required this.showSeparator,
    required this.isFirst,
    required this.isLast,
    this.performanceCounters,
    super.key,
  });

  final DashboardLogRowViewModel model;
  final VoidCallback onTap;
  final bool showSeparator;
  final bool isFirst;
  final bool isLast;
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
