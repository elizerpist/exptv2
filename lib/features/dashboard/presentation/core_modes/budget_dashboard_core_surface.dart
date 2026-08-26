import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_budget_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
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
    this.rhythm,
    this.drilldown,
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
  final ValueListenable<bool>? contentCardStyle;
  final ValueListenable<DashboardBudgetRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-budget'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashboardCoreModeCascadeCard(
            bounds: geometry.zone2Bounds,
            motion: geometry.lowerCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-budget-card-2'),
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
          DashboardCoreModeCascadeCard(
            bounds: geometry.subheaderOneBounds,
            motion: geometry.upperCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-budget-card-1'),
            showPlaceholderSurface: false,
            contentVerticalInputOverflow:
                BudgetTargetAvatarRail.selectedInputVerticalOverflow,
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
                  ),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: distributionPageController == null
                ? DashboardPlaceholderDots(
                    bounds: geometry.zone2IndicatorBounds,
                    semanticKey: const ValueKey(
                      'dashboard-core-mode-budget-dots',
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('dashboard-core-mode-budget-dots'),
                    width: geometry.zone2IndicatorBounds.width,
                    height: geometry.zone2IndicatorBounds.height,
                    child: BudgetDistributionPageDots(
                      controller: distributionPageController!,
                    ),
                  ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-budget-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-budget'),
            label: 'budget',
            visualController: headerVisualController,
            visualFrameListenable: headerVisualFrame,
            detailTop: 4,
            detailRight: headerVisualController == null ? 16 : 60,
            detailBottom: 4,
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
                          const titleAndValueHeight = 34.0;
                          const partitionHeight = 20.0;
                          final roomReveal =
                              ((constraints.maxHeight - titleAndValueHeight) /
                                      partitionHeight)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                          final partitionReveal = expansion < roomReveal
                              ? expansion
                              : roomReveal;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      header.title,
                                      key: const ValueKey(
                                        'budget-header-target-title',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FluviVisualTokens.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    header.analysisScopeLabel,
                                    key: const ValueKey(
                                      'budget-header-analysis-scope',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FluviVisualTokens.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                amount,
                                key: const ValueKey(
                                  'budget-header-actual-limit',
                                ),
                                style: const TextStyle(
                                  color: FluviVisualTokens.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
  }
}

final class _BudgetHeaderAllocationDetail extends StatelessWidget {
  const _BudgetHeaderAllocationDetail({required this.partition});

  final DashboardBudgetPartitionPresentation partition;

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
        height: 7,
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
