import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/dashboard_placeholder_card.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Balance owns its header and two future data-card presentation slots.
class BalanceDashboardCoreSurface extends StatelessWidget {
  const BalanceDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.headerVisualController,
    this.headerVisualFrame,
  });

  final DashboardCoreModePresentation presentation;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-balance'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashboardCoreModeCascadeCard(
            bounds: geometry.zone2Bounds,
            motion: geometry.lowerCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-2'),
          ),
          DashboardCoreModeCascadeCard(
            bounds: geometry.subheaderOneBounds,
            motion: geometry.upperCardMotion!,
            semanticKey: const ValueKey('dashboard-core-mode-balance-card-1'),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: DashboardPlaceholderDots(
              bounds: geometry.zone2IndicatorBounds,
              semanticKey: const ValueKey('dashboard-core-mode-balance-dots'),
            ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-balance-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-balance'),
            label: 'balance',
            visualController: headerVisualController,
            visualFrameListenable: headerVisualFrame,
          ),
        ],
      ),
    );
  }
}
