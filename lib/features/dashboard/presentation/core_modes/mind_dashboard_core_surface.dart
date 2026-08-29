import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../query/domain/query_amount_range.dart';
import '../../query/presentation/query_amount_range_control.dart';
import '../widgets/dashboard_placeholder_card.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Mind owns one merged body surface spanning the central unified envelope.
class MindDashboardCoreSurface extends StatelessWidget {
  const MindDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.queryAmountRange,
    this.queryAmountRangeChanges,
    this.onQueryAmountRangeCommitted,
    this.headerVisualController,
    this.headerVisualFrame,
  });

  final DashboardCoreModePresentation presentation;
  final QueryAmountRangeValues? Function()? queryAmountRange;
  final Listenable? queryAmountRangeChanges;
  final ValueChanged<QueryAmountRangeValues>? onQueryAmountRangeCommitted;
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
                  queryAmountRange == null ||
                      queryAmountRangeChanges == null ||
                      onQueryAmountRangeCommitted == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: AnimatedBuilder(
                          animation: queryAmountRangeChanges!,
                          builder: (context, child) =>
                              _MindQueryAmountRangeBinding(
                                valuesFor: queryAmountRange!,
                                onRangeCommitted: onQueryAmountRangeCommitted!,
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

final class _MindQueryAmountRangeBinding extends StatelessWidget {
  const _MindQueryAmountRangeBinding({
    required this.valuesFor,
    required this.onRangeCommitted,
  });

  final QueryAmountRangeValues? Function() valuesFor;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;

  @override
  Widget build(BuildContext context) {
    final values = valuesFor();
    if (values == null) {
      return const Text(
        'Az összeg tartomány betöltése folyamatban',
        key: ValueKey('mind-query-amount-range-unavailable'),
      );
    }
    return QueryAmountRangeControl(
      key: const ValueKey('mind-query-amount-range'),
      values: values,
      onRangeCommitted: onRangeCommitted,
    );
  }
}
