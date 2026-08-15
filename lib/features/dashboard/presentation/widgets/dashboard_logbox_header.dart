import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../query/application/current_query_controller.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_query_facet_chips.dart';

/// Stable LogBox header shell with a localized prepared-count leaf.
final class DashboardLogBoxHeader extends StatelessWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    this.performanceCounters,
    this.currentQuery,
    this.onRemoveCategory,
    this.onRemovePartner,
    this.onClear,
    this.focus,
    this.onClearFocusCategory,
    this.onClearFocusPartner,
    this.onClearFocus,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;
  final CurrentQueryController? currentQuery;
  final ValueChanged<String>? onRemoveCategory;
  final ValueChanged<String>? onRemovePartner;
  final VoidCallback? onClear;
  final DashboardEphemeralFocusController? focus;
  final VoidCallback? onClearFocusCategory;
  final VoidCallback? onClearFocusPartner;
  final VoidCallback? onClearFocus;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(
      DashboardPerformanceMetric.headerSubtreeBuild,
    );
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-header-repaint-boundary'),
      child: SizedBox(
        key: const ValueKey('dashboard-logbox-header'),
        width: bounds.width,
        height: bounds.height,
        child: Column(
          children: [
            SizedBox(
              height: DashboardLogBoxTokens.summaryHeaderHeight,
              child: _DashboardCountSlot(
                visibleFrames: visibleFrames,
                performanceCounters: performanceCounters,
              ),
            ),
            if (currentQuery != null &&
                onRemoveCategory != null &&
                onRemovePartner != null &&
                onClear != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DashboardQueryFacetChips(
                  currentQuery: currentQuery!,
                  visibleFrames: visibleFrames,
                  focus: focus,
                  onRemoveCategory: onRemoveCategory!,
                  onRemovePartner: onRemovePartner!,
                  onClear: onClear!,
                  onClearFocusCategory: onClearFocusCategory,
                  onClearFocusPartner: onClearFocusPartner,
                  onClearFocus: onClearFocus,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _DashboardCountSlot extends StatelessWidget {
  const _DashboardCountSlot({
    required this.visibleFrames,
    required this.performanceCounters,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardVisibleFrame?>(
      valueListenable: visibleFrames.countLane,
      builder: (context, frame, _) {
        final measure = performanceCounters?.measuresDurations ?? false;
        final started = measure ? developer.Timeline.now : 0;
        performanceCounters?.increment(DashboardPerformanceMetric.countBuild);
        final result = Center(
          child: Text(
            '${frame?.count.formattedEntryCount ?? '0'} tranzakció listázva',
            key: const ValueKey('dashboard-logbox-entry-count'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FluviVisualTokens.logBoxHeaderTextStyle,
          ),
        );
        if (measure) {
          performanceCounters!.increment(
            DashboardPerformanceMetric.countBindMicros,
            by: developer.Timeline.now - started,
          );
        }
        return result;
      },
    );
  }
}
