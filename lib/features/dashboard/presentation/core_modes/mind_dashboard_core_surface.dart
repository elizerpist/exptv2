import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/dashboard_placeholder_card.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Mind owns one merged body surface spanning the central unified envelope.
class MindDashboardCoreSurface extends StatelessWidget {
  const MindDashboardCoreSurface({
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
    final bodyBounds = geometry.unifiedSubheaderBounds!;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-mind'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashboardCoreModeOpacityPosition(
            bounds: bodyBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            scale: geometry.zone2Scale,
            child: DashboardPlaceholderCard(
              bounds: bodyBounds,
              fillParent: true,
              semanticKey: const ValueKey('dashboard-core-mode-mind-body'),
            ),
          ),
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: DashboardPlaceholderDots(
              bounds: geometry.zone2IndicatorBounds,
              semanticKey: const ValueKey('dashboard-core-mode-mind-dots'),
            ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-mind-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-mind'),
            label: 'mind',
            visualController: headerVisualController,
            visualFrameListenable: headerVisualFrame,
          ),
        ],
      ),
    );
  }
}
