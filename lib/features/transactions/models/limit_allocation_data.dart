import 'package:flutter/material.dart';

enum LimitAllocationSegmentKind { used, remaining, unlimitedUsed, free }

class LimitAllocationSegment {
  const LimitAllocationSegment({
    required this.kind,
    required this.amount,
    required this.fraction,
    required this.color,
    this.targetId,
    this.label,
  });

  final LimitAllocationSegmentKind kind;
  final double amount;
  final double fraction;
  final Color color;
  final int? targetId;
  final String? label;
}

class LimitAllocationData {
  const LimitAllocationData({
    required this.overviewLimit,
    required this.allocatedAmount,
    required this.freeAmount,
    required this.segments,
  });

  final double overviewLimit;
  final double allocatedAmount;
  final double freeAmount;
  final List<LimitAllocationSegment> segments;

  bool get hasOverviewLimit => overviewLimit > 0;
  bool get hasFreeSpace => freeAmount > 0;
}
