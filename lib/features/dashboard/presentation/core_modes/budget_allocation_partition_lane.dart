import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';

/// One narrow paint lane for the prepared Budget category-allocation
/// partition. It traverses the retained canonical bank; the allocation total
/// itself is already a scalar in [DashboardBudgetPartitionPresentation].
final class BudgetAllocationPartitionLane extends StatelessWidget {
  const BudgetAllocationPartitionLane({required this.partition, super.key});

  final DashboardBudgetPartitionPresentation partition;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      key: const ValueKey('budget-header-allocation-partition'),
      painter: BudgetAllocationPartitionPainter(partition: partition),
      child: const SizedBox.expand(),
    ),
  );
}

/// Paint-only renderer for the ordered dense Budget bank. It never sorts,
/// searches, aggregates or projects category collections.
final class BudgetAllocationPartitionPainter extends CustomPainter {
  const BudgetAllocationPartitionPainter({required this.partition});

  final DashboardBudgetPartitionPresentation partition;

  static const _cornerRadius = Radius.circular(4);
  static const _allocatedRemainderOpacity = .38;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final track = Offset.zero & size;
    final clip = RRect.fromRectAndRadius(track, _cornerRadius);
    canvas
      ..save()
      ..clipRRect(clip)
      ..drawRect(
        track,
        Paint()..color = FluviVisualTokens.surface.withValues(alpha: .28),
      );

    if (!partition.hasPositiveAggregateLimit) {
      canvas.restore();
      return;
    }
    final bank = partition.bank;
    final catalog = partition.catalog;
    if (bank == null || catalog == null) {
      canvas.restore();
      return;
    }

    var covered = 0.0;
    for (var handle = 1; handle < bank.targetCount; handle += 1) {
      if (covered >= 1) break;
      final category = catalog.targetAtHandle(handle).category;
      if (category == null) continue;
      final segment = partition.segmentForCategoryHandle(handle);
      final color = CategoryColorCatalog.resolve(category.colorId).middleColor;
      covered = _paintPortion(
        canvas: canvas,
        track: track,
        covered: covered,
        ratio: segment.opaqueRatio,
        color: color,
      );
      covered = _paintPortion(
        canvas: canvas,
        track: track,
        covered: covered,
        ratio: segment.translucentRatio,
        color: color.withValues(alpha: _allocatedRemainderOpacity),
      );
    }
    canvas.restore();
  }

  double _paintPortion({
    required Canvas canvas,
    required Rect track,
    required double covered,
    required double ratio,
    required Color color,
  }) {
    if (ratio <= 0 || covered >= 1) return covered;
    final widthFraction = math.min(ratio, 1 - covered);
    if (widthFraction <= 0) return covered;
    canvas.drawRect(
      Rect.fromLTWH(
        track.left + track.width * covered,
        track.top,
        track.width * widthFraction,
        track.height,
      ),
      Paint()..color = color,
    );
    return covered + widthFraction;
  }

  @override
  bool shouldRepaint(covariant BudgetAllocationPartitionPainter oldDelegate) {
    final old = oldDelegate.partition;
    return old.coreRevision != partition.coreRevision ||
        old.periodSliceIndex != partition.periodSliceIndex ||
        old.effectiveAggregateLimitScaled100 !=
            partition.effectiveAggregateLimitScaled100 ||
        old.aggregateActualScaled100 != partition.aggregateActualScaled100 ||
        old.preparedAllocatedTotalScaled100 !=
            partition.preparedAllocatedTotalScaled100 ||
        old.optimisticAllocationDeltaScaled100 !=
            partition.optimisticAllocationDeltaScaled100 ||
        !identical(old.bank, partition.bank) ||
        !identical(old.catalog, partition.catalog) ||
        !mapEquals(
          old.effectiveLimitByTargetHandle,
          partition.effectiveLimitByTargetHandle,
        ) ||
        !identical(old.categoryOverlay, partition.categoryOverlay);
  }
}
