import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_layout_metrics.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_spending_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_render_diagnostic_probe.dart';
import '../budget_content_card_style.dart';
import '../budget_section_order.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import '../dashboard_budget_header_presentation.dart';
import 'budget_category_avatar_rail.dart';
import 'budget_allocation_partition_lane.dart';
import 'dashboard_header_contrast_text.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
import 'budget_distribution_page_surface.dart';
import 'budget_target_avatar_rail_controller.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Budget owns its header and two future data-card presentation slots.
class BudgetDashboardCoreSurface extends StatelessWidget {
  const BudgetDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.presentationController,
    this.limitEditController,
    this.distributionDrawables,
    this.avatarRailController,
    this.distributionPageController,
    this.contentCardStyle,
    this.sectionOrder,
    this.rhythm,
    this.drilldown,
    this.onAvatarDirectInputStarted,
    this.onAvatarMotionActiveChanged,
    this.headerVisualController,
    this.headerVisualFrame,
    this.upperVerticalGestures,
  });

  final DashboardCoreModePresentation presentation;
  final DashboardBudgetPresentationController? presentationController;
  final DashboardBudgetLimitEditController? limitEditController;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>?
  distributionDrawables;
  final BudgetTargetAvatarRailController? avatarRailController;
  final BudgetDistributionPageController? distributionPageController;
  final ValueListenable<BudgetContentLayout>? contentCardStyle;
  final ValueListenable<BudgetSectionOrder>? sectionOrder;
  final ValueListenable<DashboardSpendingRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;
  final VoidCallback? onAvatarDirectInputStarted;
  final ValueChanged<bool>? onAvatarMotionActiveChanged;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    final headerProfile = DashboardBudgetHeaderPresentationScope.profileOf(
      context,
    );
    return ValueListenableBuilder<BudgetSectionOrder>(
      valueListenable: sectionOrder ?? _alwaysAvatarsThenChart,
      builder: (context, order, _) {
        final section = _BudgetSectionLayout.resolve(geometry, order);
        return KeyedSubtree(
          key: const ValueKey('dashboard-core-mode-budget'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Preserve the original StackFill sizing contract. The optional
              // unified shell is a positioned dashboard surface when enabled and
              // a zero-size leaf when Split is selected; it must not become the
              // only non-positioned child and collapse the Budget stack.
              const SizedBox.expand(),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable: contentCardStyle ?? _alwaysSplitBudgetContent,
                builder: (context, layout, _) => _BudgetUnifiedContentCard(
                  geometry: geometry,
                  section: section,
                  contentLayout: layout,
                ),
              ),
              DashboardRenderDiagnosticProbe(
                candidate: 'budgetChartCascadeCard',
                material: 'contentOnly DashboardCoreModeCascadeCard',
                clip: 'none at cascade; child owns rounded viewport clip',
                zOrder: 'unifiedSurface<chartCascade<avatarCascade<dots',
                child: DashboardCoreModeCascadeCard(
                  bounds: section.chartBounds,
                  motion: section.motionFor(
                    geometry.lowerCardMotion!,
                    from: geometry.zone2Bounds,
                    to: section.chartBounds,
                  ),
                  semanticKey: const ValueKey(
                    'dashboard-core-mode-budget-card-2',
                  ),
                  showPlaceholderSurface: false,
                  content: ValueListenableBuilder<BudgetContentLayout>(
                    valueListenable:
                        contentCardStyle ?? _alwaysSplitBudgetContent,
                    builder: (context, layout, _) => _distributionContent(
                      surfaceOwner: layout == BudgetContentLayout.unifiedCard
                          ? BudgetDistributionSurfaceOwner.unifiedParent
                          : BudgetDistributionSurfaceOwner.splitCard2,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable: contentCardStyle ?? _alwaysSplitBudgetContent,
                builder: (context, layout, _) => DashboardCoreModeCascadeCard(
                  bounds: section.avatarBounds,
                  motion: section.motionFor(
                    geometry.upperCardMotion!,
                    from: geometry.subheaderOneBounds,
                    to: section.avatarBounds,
                  ),
                  semanticKey: const ValueKey(
                    'dashboard-core-mode-budget-card-1',
                  ),
                  showPlaceholderSurface: false,
                  contentVerticalInputOverflow:
                      BudgetTargetAvatarRail.selectedInputVerticalOverflow,
                  // The shared card starts at the authored mode-content top.
                  // Moving this full input parent down exactly one existing
                  // overflow clears the selected 112px chrome without changing
                  // Split's baseline rail position, hit bounds or carousel state.
                  contentVerticalOffset:
                      layout == BudgetContentLayout.unifiedCard ||
                          order == BudgetSectionOrder.chartThenAvatars
                      ? BudgetTargetAvatarRail.selectedInputVerticalOverflow
                      : 0,
                  content: _avatarContent(),
                ),
              ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable: contentCardStyle ?? _alwaysSplitBudgetContent,
                builder: (context, layout, _) {
                  final bounds = layout == BudgetContentLayout.unifiedCard
                      ? _unifiedIndicatorBounds(section, order)
                      : section.indicatorBounds;
                  return DashboardCoreModeOpacityPosition(
                    bounds: bounds,
                    opacity: geometry.zone2Opacity,
                    offset: Offset(0, geometry.zone2Shift),
                    child: _dotsContent(bounds),
                  );
                },
              ),
              DashboardCoreModeHeaderScaffold(
                bounds: geometry.headerBounds,
                surfaceColor: presentation.palette.upcomingHeaderTone,
                headerKey: const ValueKey('dashboard-core-mode-budget-header'),
                labelKey: const ValueKey('dashboard-core-mode-label-budget'),
                label: 'budget',
                labelContent: presentationController == null
                    ? null
                    : ValueListenableBuilder<DashboardBudgetPresentationState>(
                        valueListenable: presentationController!,
                        builder: (context, state, _) =>
                            DashboardHeaderContrastText(
                              data: state.header.metric.modeLabel,
                              key: const ValueKey(
                                'dashboard-core-mode-label-budget',
                              ),
                              style:
                                  Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle(),
                              foreground: headerProfile.foreground,
                              contrastStyle:
                                  headerProfile.settings.textContrastStyle,
                            ),
                      ),
                visualController: headerVisualController,
                visualFrameListenable: headerVisualFrame,
                // The source title starts at x=20/y=16. Text keeps the
                // existing tuner/menu clearance internally; the partition
                // lane itself now owns equal 16px physical insets.
                detailLeft: 16,
                detailTop: 16,
                detailRight: 16,
                detailBottom: headerProfile.partitionBottomInset,
                detail: presentationController == null
                    ? null
                    : ValueListenableBuilder<DashboardBudgetPresentationState>(
                        valueListenable: presentationController!,
                        builder: (context, state, child) {
                          final header = state.header;
                          final metric = header.metric;
                          final amount = header.isAvailable
                              ? '${metric.usesPerDayAmounts ? DashboardPreparedFormatter.amountMinorPerDay(header.displayNumeratorScaled100!) : DashboardPreparedFormatter.amountMinor(header.displayNumeratorScaled100!)} / '
                                    '${header.displayDenominatorScaled100 == null
                                        ? '—'
                                        : metric.usesPerDayAmounts
                                        ? DashboardPreparedFormatter.amountMinorPerDay(header.displayDenominatorScaled100!)
                                        : DashboardPreparedFormatter.amountMinor(header.displayDenominatorScaled100!)}'
                              : '— / —';
                          final partition = state.partition;
                          final expansion = geometry.headerExpansionProgress;
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              // The lower lane consumes only the room made by the
                              // existing header expansion. This preserves the
                              // title/value anchor at every intermediate height
                              // without a feature-local layout threshold or
                              // animation owner.
                              const titleAndValueHeight = 36.0;
                              final partitionHeight =
                                  13.0 + headerProfile.partitionThickness;
                              final roomReveal =
                                  ((constraints.maxHeight -
                                              titleAndValueHeight) /
                                          partitionHeight)
                                      .clamp(0.0, 1.0)
                                      .toDouble();
                              final partitionReveal = expansion < roomReveal
                                  ? expansion
                                  : roomReveal;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 44,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        DashboardHeaderContrastText(
                                          data: header.title,
                                          key: const ValueKey(
                                            'budget-header-target-title',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            height: 1,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          foreground: headerProfile.foreground,
                                          contrastStyle: headerProfile
                                              .settings
                                              .textContrastStyle,
                                        ),
                                        DashboardHeaderContrastText(
                                          data: metric.metricLabel,
                                          key: const ValueKey(
                                            'budget-header-metric-label',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            // The fixed Header already has a
                                            // seven-source-pixel interline
                                            // lane between target and amount.
                                            // The metric owns that existing
                                            // lane, retaining the accepted
                                            // Header/partition geometry even
                                            // at its collapsed height.
                                            fontSize: 7,
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          foreground: headerProfile.foreground
                                              .withValues(alpha: .72),
                                          contrastStyle: headerProfile
                                              .settings
                                              .textContrastStyle,
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: DashboardHeaderContrastText(
                                            data: amount,
                                            key: const ValueKey(
                                              'budget-header-actual-limit',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 19,
                                              height: .96,
                                              letterSpacing: -.76,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            foreground:
                                                headerProfile.foreground,
                                            contrastStyle: headerProfile
                                                .settings
                                                .textContrastStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  ClipRect(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      heightFactor: partitionReveal,
                                      child: Opacity(
                                        key: const ValueKey(
                                          'budget-header-partition-reveal',
                                        ),
                                        opacity: partitionReveal,
                                        child: _BudgetHeaderAllocationDetail(
                                          partition: partition,
                                          thickness:
                                              headerProfile.partitionThickness,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _distributionContent({
    required BudgetDistributionSurfaceOwner surfaceOwner,
  }) {
    if (presentationController == null ||
        distributionDrawables == null ||
        avatarRailController == null ||
        distributionPageController == null) {
      return switch (surfaceOwner) {
        BudgetDistributionSurfaceOwner.splitCard2 =>
          const BudgetDistributionCardShell(child: SizedBox.expand()),
        BudgetDistributionSurfaceOwner.unifiedParent =>
          const BudgetDistributionCardShell(
            surfaceOwner: BudgetDistributionSurfaceOwner.unifiedParent,
            child: SizedBox.expand(),
          ),
      };
    }
    return BudgetDistributionPager(
      controller: distributionPageController!,
      presentation: presentationController!,
      drawableFrames: distributionDrawables!,
      avatarRailController: avatarRailController!,
      expandCategoryDonutToFit: !presentation.geometry.hasPhysicalRail,
      rhythm: rhythm,
      drilldown: drilldown,
      upperVerticalGestures: upperVerticalGestures,
      surfaceOwner: surfaceOwner,
    );
  }

  Widget _avatarContent() => presentationController == null
      ? const SizedBox(key: ValueKey<String>('budget-target-avatar-rail'))
      : BudgetTargetAvatarRail(
          presentation: presentationController!,
          limitEditController: limitEditController,
          navigationController: avatarRailController,
          onTargetPreview: drilldown == null
              ? null
              : (targetHandle) => unawaited(
                  drilldown!.previewBudgetTarget(targetHandle: targetHandle),
                ),
          onTargetSettled: drilldown == null
              ? null
              : (targetHandle) => unawaited(
                  drilldown!.commitBudgetTargetHandle(
                    targetHandle: targetHandle,
                    source: 'avatarSettled',
                  ),
                ),
          onPreparedTargetHotsetRequested: drilldown?.primeBudgetTargetHotset,
          onMotionActiveChanged: onAvatarMotionActiveChanged,
          onDirectInputStarted: onAvatarDirectInputStarted,
        );

  Widget _dotsContent(DashboardBounds bounds) =>
      distributionPageController == null
      ? DashboardPlaceholderDots(
          bounds: bounds,
          semanticKey: const ValueKey('dashboard-core-mode-budget-dots'),
        )
      : SizedBox(
          key: const ValueKey('dashboard-core-mode-budget-dots'),
          width: bounds.width,
          height: bounds.height,
          child: BudgetDistributionPageDots(
            controller: distributionPageController!,
          ),
        );
}

/// Unified Budget's physical common surface follows the exact same
/// top-centred cascade as its persistent Card2 viewport. It therefore stays
/// behind the transparent Rhythm lane without becoming a second, differently
/// transformed raster owner, while Avatar and PageView elements retain their
/// existing tree positions and controllers.
final class _BudgetUnifiedContentCard extends StatelessWidget {
  const _BudgetUnifiedContentCard({
    required this.geometry,
    required this.section,
    required this.contentLayout,
  });

  final DashboardLayoutFrame geometry;
  final _BudgetSectionLayout section;
  final BudgetContentLayout contentLayout;

  @override
  Widget build(BuildContext context) {
    if (contentLayout != BudgetContentLayout.unifiedCard) {
      return const SizedBox.shrink();
    }
    final bounds = geometry.modeContentBounds;
    final motion = section.motionFor(
      geometry.lowerCardMotion!,
      from: geometry.zone2Bounds,
      to: bounds,
    );
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.budgetDistributionCard);
    return DashboardCoreModeOpacityPosition(
      bounds: bounds,
      opacity: motion.opacity,
      offset: Offset(0, motion.top - bounds.top),
      scale: motion.scale,
      child: LayoutBuilder(
        builder: (context, constraints) => DashboardRenderDiagnosticProbe(
          candidate: 'budgetUnifiedContentSurface',
          material:
              'surface=FluviRoundedBox color=${depth.surfaceColor ?? FluviVisualTokens.surface} '
              'shadowCount=${depth.shadows.length}',
          clip:
              'none; descendant BudgetDistributionCardShell owns viewport clip',
          zOrder: 'unifiedSurface<chartCascade<avatarCascade<dots',
          child: FluviRoundedBox(
            key: const ValueKey<String>('budget-unified-content-card-surface'),
            color: depth.surfaceColor ?? FluviVisualTokens.surface,
            border: DashboardBorderScope.profileOf(
              context,
            ).borderFor(DashboardBorderSurface.budgetContent),
            borderRadius: DashboardCornerRoundnessScope.profileOf(context)
                .borderRadiusFor(
                  DashboardCornerSurfaceFamily.budgetDistributionCard,
                  size: constraints.biggest,
                ),
            boxShadow: depth.shadows,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

DashboardBounds _unifiedIndicatorBounds(
  _BudgetSectionLayout section,
  BudgetSectionOrder order,
) {
  final bottomClearance = order == BudgetSectionOrder.avatarsThenChart
      ? DashboardLayoutMetrics.reference.dotGap
      : 0.0;
  return DashboardBounds(
    left: section.indicatorBounds.left,
    top: section.indicatorBounds.top - bottomClearance,
    width: section.indicatorBounds.width,
    height: section.indicatorBounds.height,
  );
}

final ValueListenable<BudgetContentLayout> _alwaysSplitBudgetContent =
    ValueNotifier<BudgetContentLayout>(BudgetContentLayout.split);
final ValueListenable<BudgetSectionOrder> _alwaysAvatarsThenChart =
    ValueNotifier<BudgetSectionOrder>(BudgetSectionOrder.avatarsThenChart);

@immutable
final class _BudgetSectionLayout {
  const _BudgetSectionLayout({
    required this.avatarBounds,
    required this.chartBounds,
    required this.indicatorBounds,
  });

  final DashboardBounds avatarBounds;
  final DashboardBounds chartBounds;
  final DashboardBounds indicatorBounds;

  static _BudgetSectionLayout resolve(
    DashboardLayoutFrame geometry,
    BudgetSectionOrder order,
  ) {
    if (order == BudgetSectionOrder.avatarsThenChart) {
      return _BudgetSectionLayout(
        avatarBounds: geometry.subheaderOneBounds,
        chartBounds: geometry.zone2Bounds,
        indicatorBounds: geometry.zone2IndicatorBounds,
      );
    }
    final gap = geometry.zone2Bounds.top - geometry.subheaderOneBounds.bottom;
    final chart = DashboardBounds(
      left: geometry.zone2Bounds.left,
      top: geometry.subheaderOneBounds.top,
      width: geometry.zone2Bounds.width,
      height: geometry.zone2Bounds.height,
    );
    final avatars = DashboardBounds(
      left: geometry.subheaderOneBounds.left,
      top: chart.bottom + gap,
      width: geometry.subheaderOneBounds.width,
      height: geometry.subheaderOneBounds.height,
    );
    final indicatorGap =
        geometry.zone2IndicatorBounds.top - geometry.zone2Bounds.bottom;
    final selectedShellFootprint =
        BudgetTargetAvatarRail.selectedInputVerticalOverflow;
    return _BudgetSectionLayout(
      avatarBounds: avatars,
      chartBounds: chart,
      indicatorBounds: DashboardBounds(
        left: geometry.zone2IndicatorBounds.left,
        // The selected input shell is deliberately 40px taller than this
        // structural rail. Chart-first puts it below the chart, so dots must
        // follow the whole physical shell rather than slice through its lower
        // ring/shadow. The central geometry reserves the same 40px tail.
        top: avatars.bottom + selectedShellFootprint * 2 + indicatorGap,
        width: geometry.zone2IndicatorBounds.width,
        height: geometry.zone2IndicatorBounds.height,
      ),
    );
  }

  CascadedCardMotion motionFor(
    CascadedCardMotion motion, {
    required DashboardBounds from,
    required DashboardBounds to,
  }) => CascadedCardMotion(
    top: motion.top + to.top - from.top,
    left: motion.left,
    right: motion.right,
    opacity: motion.opacity,
    scale: motion.scale,
    progress: motion.progress,
  );
}

final class _BudgetHeaderAllocationDetail extends StatelessWidget {
  const _BudgetHeaderAllocationDetail({
    required this.partition,
    required this.thickness,
  });

  final DashboardBudgetPartitionPresentation partition;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final profile = DashboardBudgetHeaderPresentationScope.profileOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DashboardHeaderContrastText(
              data: _allocationLabel(partition),
              key: const ValueKey('budget-header-allocation-percent'),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              foreground: profile.foreground.withValues(alpha: .78),
              contrastStyle: profile.settings.textContrastStyle,
            ),
            DashboardHeaderContrastText(
              data: _remainingStatusLabel(partition),
              key: const ValueKey('budget-header-remaining-status'),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              foreground: profile.foreground.withValues(alpha: .78),
              contrastStyle: profile.settings.textContrastStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: thickness,
          width: double.infinity,
          child: BudgetAllocationPartitionLane(partition: partition),
        ),
      ],
    );
  }

  static String _allocationLabel(DashboardBudgetPartitionPresentation value) {
    if (!value.hasPositiveAggregateLimit) return '—';
    final percentage = value.allocationRawRatio * 100;
    final decimal = percentage == percentage.roundToDouble()
        ? percentage.toStringAsFixed(0)
        : percentage.toStringAsFixed(1);
    return '$decimal% lefoglalva';
  }

  static String _remainingStatusLabel(
    DashboardBudgetPartitionPresentation value,
  ) {
    final limit = value.effectiveAggregateLimitScaled100;
    final actual = value.aggregateActualScaled100;
    if (limit == null || limit <= 0 || actual == null) return '—';
    final remaining = limit - actual;
    final amount = DashboardPreparedFormatter.amountMinor(remaining.abs());
    return remaining >= 0 ? '$amount maradt' : '$amount túlköltés';
  }
}
