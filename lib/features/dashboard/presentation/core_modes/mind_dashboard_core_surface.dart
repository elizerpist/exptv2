import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../query/domain/query_amount_threshold.dart';
import '../../query/presentation/query_amount_threshold_slider.dart';
import '../widgets/dashboard_placeholder_card.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Mind owns one merged body surface spanning the central unified envelope.
class MindDashboardCoreSurface extends StatelessWidget {
  const MindDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.queryThresholdBounds,
    this.queryThresholdChanges,
    this.onQueryThresholdCommitted,
    this.headerVisualController,
    this.headerVisualFrame,
  });

  final DashboardCoreModePresentation presentation;
  final QueryAmountThresholdBounds Function()? queryThresholdBounds;
  final Listenable? queryThresholdChanges;
  final ValueChanged<int>? onQueryThresholdCommitted;
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
              borderSurface: DashboardBorderSurface.mindContent,
              child:
                  queryThresholdBounds == null ||
                      queryThresholdChanges == null ||
                      onQueryThresholdCommitted == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: AnimatedBuilder(
                          animation: queryThresholdChanges!,
                          builder: (context, child) =>
                              _MindQueryThresholdBinding(
                                boundsFor: queryThresholdBounds!,
                                onValueCommitted: onQueryThresholdCommitted!,
                              ),
                        ),
                      ),
                    ),
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

final class _MindQueryThresholdBinding extends StatelessWidget {
  const _MindQueryThresholdBinding({
    required this.boundsFor,
    required this.onValueCommitted,
  });

  final QueryAmountThresholdBounds Function() boundsFor;
  final ValueChanged<int> onValueCommitted;

  @override
  Widget build(BuildContext context) => QueryAmountThresholdSlider(
    key: const ValueKey('mind-query-threshold'),
    bounds: boundsFor(),
    onValueCommitted: onValueCommitted,
    semanticPrefix: 'Mind összegküszöb',
  );
}
