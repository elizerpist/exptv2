import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
import 'budget_category_avatar_rail.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
import 'budget_target_avatar_rail_controller.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';

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
  });

  final DashboardCoreModePresentation presentation;
  final DashboardBudgetPresentationController? presentationController;
  final DashboardBudgetLimitEditController? limitEditController;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>?
  distributionDrawables;
  final BudgetTargetAvatarRailController? avatarRailController;
  final BudgetDistributionPageController? distributionPageController;

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
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            header.title,
                            key: const ValueKey('budget-header-target-title'),
                            style: const TextStyle(
                              color: FluviVisualTokens.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            amount,
                            key: const ValueKey('budget-header-actual-limit'),
                            style: const TextStyle(
                              color: FluviVisualTokens.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
