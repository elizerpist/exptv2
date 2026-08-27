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
import '../../application/dashboard_budget_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../budget_content_card_style.dart';
import '../budget_section_order.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_budget_header_presentation.dart';
import 'budget_category_avatar_rail.dart';
import 'budget_allocation_partition_lane.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
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
    this.onAvatarMotionActiveChanged,
    this.headerVisualController,
    this.headerVisualFrame,
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
  final ValueListenable<DashboardBudgetRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;
  final ValueChanged<bool>? onAvatarMotionActiveChanged;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

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
              _BudgetUnifiedContentCard(
                geometry: geometry,
                contentLayout: contentCardStyle,
              ),
              DashboardCoreModeCascadeCard(
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
                content:
                    presentationController == null ||
                        distributionDrawables == null ||
                        avatarRailController == null ||
                        distributionPageController == null
                    ? const SizedBox.shrink()
                    : BudgetDistributionPager(
                        controller: distributionPageController!,
                        presentation: presentationController!,
                        drawableFrames: distributionDrawables!,
                        avatarRailController: avatarRailController!,
                        expandCategoryDonutToFit: !geometry.hasPhysicalRail,
                        contentCardStyle: contentCardStyle,
                        rhythm: rhythm,
                        drilldown: drilldown,
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
                  content: presentationController == null
                      ? const SizedBox(
                          key: ValueKey<String>('budget-target-avatar-rail'),
                        )
                      : BudgetTargetAvatarRail(
                          presentation: presentationController!,
                          limitEditController: limitEditController,
                          navigationController: avatarRailController,
                          onTargetPreview: drilldown == null
                              ? null
                              : (state) => unawaited(
                                  drilldown!.previewBudgetTarget(state: state),
                                ),
                          onTargetSettled: drilldown == null
                              ? null
                              : (state) => unawaited(
                                  drilldown!.commitBudgetTarget(
                                    state: state,
                                    source: 'avatarSettled',
                                  ),
                                ),
                          onMotionActiveChanged: onAvatarMotionActiveChanged,
                        ),
                ),
              ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable: contentCardStyle ?? _alwaysSplitBudgetContent,
                builder: (context, layout, _) {
                  // The source dot gap is 4px. Only Unified Avatar→Chart
                  // uses it as an extra inner-bottom clearance; Split and
                  // Chart→Avatar retain their authored indicator geometry.
                  final bottomClearance =
                      layout == BudgetContentLayout.unifiedCard &&
                          order == BudgetSectionOrder.avatarsThenChart
                      ? DashboardLayoutMetrics.reference.dotGap
                      : 0.0;
                  final bounds = DashboardBounds(
                    left: section.indicatorBounds.left,
                    top: section.indicatorBounds.top - bottomClearance,
                    width: section.indicatorBounds.width,
                    height: section.indicatorBounds.height,
                  );
                  return DashboardCoreModeOpacityPosition(
                    bounds: bounds,
                    opacity: geometry.zone2Opacity,
                    offset: Offset(0, geometry.zone2Shift),
                    child: distributionPageController == null
                        ? DashboardPlaceholderDots(
                            bounds: bounds,
                            semanticKey: const ValueKey(
                              'dashboard-core-mode-budget-dots',
                            ),
                          )
                        : SizedBox(
                            key: const ValueKey(
                              'dashboard-core-mode-budget-dots',
                            ),
                            width: bounds.width,
                            height: bounds.height,
                            child: BudgetDistributionPageDots(
                              controller: distributionPageController!,
                            ),
                          ),
                  );
                },
              ),
              DashboardCoreModeHeaderScaffold(
                bounds: geometry.headerBounds,
                surfaceColor: presentation.palette.upcomingHeaderTone,
                headerKey: const ValueKey('dashboard-core-mode-budget-header'),
                labelKey: const ValueKey('dashboard-core-mode-label-budget'),
                label: 'budget',
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
                          final amount = header.isAvailable
                              ? '${DashboardPreparedFormatter.amountMinor(header.actualScaled100!)} / '
                                    '${header.hasLimit ? DashboardPreparedFormatter.amountMinor(header.limitScaled100!) : '—'}'
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
                                        Text(
                                          header.title,
                                          key: const ValueKey(
                                            'budget-header-target-title',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: headerProfile.foreground,
                                            fontSize: 10,
                                            height: 1,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            amount,
                                            key: const ValueKey(
                                              'budget-header-actual-limit',
                                            ),
                                            style: TextStyle(
                                              color: headerProfile.foreground,
                                              fontSize: 19,
                                              height: .96,
                                              letterSpacing: -.76,
                                              fontWeight: FontWeight.w900,
                                            ),
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
}

/// One purely presentational common shell over the central mode-content
/// envelope. The avatar rail, pager and dots stay mounted in their existing
/// cascade slots above it, preserving their controller and gesture ownership.
final class _BudgetUnifiedContentCard extends StatelessWidget {
  const _BudgetUnifiedContentCard({
    required this.geometry,
    required this.contentLayout,
  });

  final DashboardLayoutFrame geometry;
  final ValueListenable<BudgetContentLayout>? contentLayout;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetContentLayout>(
        valueListenable: contentLayout ?? _alwaysSplitBudgetContent,
        builder: (context, layout, _) {
          if (layout != BudgetContentLayout.unifiedCard) {
            return const SizedBox.shrink();
          }
          final bounds = geometry.modeContentBounds;
          final depth = DashboardShadowStyleScope.profileOf(
            context,
          ).depthFor(DashboardCornerSurfaceFamily.budgetDistributionCard);
          return DashboardCoreModeOpacityPosition(
            bounds: bounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            scale: geometry.zone2Scale,
            child: LayoutBuilder(
              builder: (context, constraints) => FluviRoundedBox(
                key: const ValueKey<String>(
                  'budget-unified-content-card-surface',
                ),
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
          );
        },
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            _allocationLabel(partition),
            key: const ValueKey('budget-header-allocation-percent'),
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _remainingStatusLabel(partition),
            key: const ValueKey('budget-header-remaining-status'),
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
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
