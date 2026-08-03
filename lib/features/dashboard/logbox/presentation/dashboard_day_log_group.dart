import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../shared/widgets/sliver_clip_r_rect.dart';
import '../application/dashboard_log_view_models.dart';
import 'dashboard_log_row.dart';

/// One complete local-day section built as lazy slivers.
///
/// The group paints a single joined outer surface, while its rows stay in a
/// [SliverFixedExtentList] so a busy day never materializes all row widgets
/// just because its date becomes visible.
class DashboardDayLogGroupSliver extends StatelessWidget {
  const DashboardDayLogGroupSliver({
    required this.model,
    required this.onEntryTap,
    required this.showGroupGap,
    super.key,
  });

  final DashboardDayLogGroupViewModel model;
  final ValueChanged<String> onEntryTap;
  final bool showGroupGap;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
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
          sliver: SliverClipRRect(
            borderRadius: FluviVisualTokens.logBoxGroupRadius,
            sliver: DecoratedSliver(
              decoration: const BoxDecoration(
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
                  onTap: () => onEntryTap(model.rows[index].entryId),
                ),
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
}
