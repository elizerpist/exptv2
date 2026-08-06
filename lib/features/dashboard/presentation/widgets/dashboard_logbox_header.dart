import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';

/// Stable LogBox header shell with a localized prepared-count leaf.
final class DashboardLogBoxHeader extends StatelessWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;

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
        child: _DashboardCountSlot(
          visibleFrames: visibleFrames,
          performanceCounters: performanceCounters,
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
