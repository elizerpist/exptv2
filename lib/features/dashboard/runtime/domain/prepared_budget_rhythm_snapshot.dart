import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';

/// One non-zero target/day amount retained from the bounded native Budget
/// grouped-day acquisition. Money always stays integer scaled-100.
@immutable
final class PreparedBudgetRhythmPoint {
  const PreparedBudgetRhythmPoint({
    required this.epochDay,
    required this.actualScaled100,
  }) : assert(actualScaled100 > 0);

  final int epochDay;
  final int actualScaled100;
}

/// Sparse target-local daily series. Points are grouped by Budget target
/// handle, so a target rhythm never scans another category's prepared rows.
@immutable
final class PreparedBudgetRhythmDirectionBank {
  PreparedBudgetRhythmDirectionBank({
    required this.targetCount,
    required List<int> targetOffsets,
    required List<PreparedBudgetRhythmPoint> points,
  }) : targetOffsets = List<int>.unmodifiable(targetOffsets),
       points = List<PreparedBudgetRhythmPoint>.unmodifiable(points) {
    if (targetCount <= 0 ||
        this.targetOffsets.length != targetCount + 1 ||
        this.targetOffsets.first != 0 ||
        this.targetOffsets.last != this.points.length) {
      throw ArgumentError('Invalid prepared Budget rhythm offsets.');
    }
    for (var handle = 0; handle < targetCount; handle += 1) {
      final start = this.targetOffsets[handle];
      final end = this.targetOffsets[handle + 1];
      if (start > end || start < 0 || end > this.points.length) {
        throw ArgumentError('Invalid prepared Budget rhythm range.');
      }
      var previousEpochDay = -0x7fffffffffffffff;
      for (var index = start; index < end; index += 1) {
        final point = this.points[index];
        if (point.actualScaled100 <= 0 || point.epochDay <= previousEpochDay) {
          throw ArgumentError('Budget rhythm points must be positive/sorted.');
        }
        previousEpochDay = point.epochDay;
      }
    }
  }

  factory PreparedBudgetRhythmDirectionBank.empty({required int targetCount}) =>
      PreparedBudgetRhythmDirectionBank(
        targetCount: targetCount,
        targetOffsets: List<int>.filled(targetCount + 1, 0),
        points: const <PreparedBudgetRhythmPoint>[],
      );

  factory PreparedBudgetRhythmDirectionBank.fromTargetPoints({
    required List<List<PreparedBudgetRhythmPoint>> targetPoints,
  }) {
    final offsets = <int>[0];
    final flattened = <PreparedBudgetRhythmPoint>[];
    for (final rawPoints in targetPoints) {
      final ordered = List<PreparedBudgetRhythmPoint>.of(rawPoints)
        ..sort((left, right) => left.epochDay.compareTo(right.epochDay));
      flattened.addAll(ordered);
      offsets.add(flattened.length);
    }
    return PreparedBudgetRhythmDirectionBank(
      targetCount: targetPoints.length,
      targetOffsets: offsets,
      points: flattened,
    );
  }

  final int targetCount;
  final List<int> targetOffsets;
  final List<PreparedBudgetRhythmPoint> points;

  List<PreparedBudgetRhythmPoint> pointsForTargetHandle(int targetHandle) {
    if (targetHandle < 0 || targetHandle >= targetCount) {
      throw RangeError.range(targetHandle, 0, targetCount - 1, 'targetHandle');
    }
    return points.sublist(
      targetOffsets[targetHandle],
      targetOffsets[targetHandle + 1],
    );
  }

  /// Exact O(log n) day lookup for a direction-local Budget target. This is
  /// deliberately separate from rolling rhythm projection so a DayScope pie
  /// can reuse the prepared day bank without scanning another target.
  int actualAtEpochDay({required int targetHandle, required int epochDay}) {
    if (targetHandle < 0 || targetHandle >= targetCount) {
      throw RangeError.range(targetHandle, 0, targetCount - 1, 'targetHandle');
    }
    var low = targetOffsets[targetHandle];
    var high = targetOffsets[targetHandle + 1];
    while (low < high) {
      final middle = (low + high) ~/ 2;
      final point = points[middle];
      if (point.epochDay < epochDay) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final end = targetOffsets[targetHandle + 1];
    return low < end && points[low].epochDay == epochDay
        ? points[low].actualScaled100
        : 0;
  }
}

/// Query-independent exact-revision daily source for the compact rolling
/// Budget rhythm. Its target-handle domains match PreparedBudgetLimitSnapshot.
@immutable
final class PreparedBudgetRhythmSnapshot {
  const PreparedBudgetRhythmSnapshot({
    required this.coreRevision,
    required this.incomeBank,
    required this.expenseBank,
  }) : assert(coreRevision > 0);

  final int coreRevision;
  final PreparedBudgetRhythmDirectionBank incomeBank;
  final PreparedBudgetRhythmDirectionBank expenseBank;

  PreparedBudgetRhythmDirectionBank directionBank(LedgerDirection direction) =>
      switch (direction) {
        LedgerDirection.income => incomeBank,
        LedgerDirection.expense => expenseBank,
      };
}
