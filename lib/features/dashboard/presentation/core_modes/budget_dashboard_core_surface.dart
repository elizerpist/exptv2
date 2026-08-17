import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
import 'budget_category_avatar_rail.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// Budget owns its header and two future data-card presentation slots.
class BudgetDashboardCoreSurface extends StatelessWidget {
  const BudgetDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.presentationController,
  });

  final DashboardCoreModePresentation presentation;
  final DashboardBudgetPresentationController? presentationController;

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
          ),
          DashboardCoreModeCascadeCard(
            bounds: geometry.subheaderOneBounds,
            motion: geometry.upperCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-budget-card-1'),
            showPlaceholderSurface: false,
            content: presentationController == null
                ? const SizedBox(key: ValueKey('budget-target-avatar-rail'))
                : BudgetTargetAvatarRail(presentation: presentationController!),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: DashboardPlaceholderDots(
              bounds: geometry.zone2IndicatorBounds,
              semanticKey: const ValueKey('dashboard-core-mode-budget-dots'),
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
                      return Text(
                        amount,
                        key: const ValueKey('budget-header-actual-limit'),
                        style: const TextStyle(
                          color: FluviVisualTokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
