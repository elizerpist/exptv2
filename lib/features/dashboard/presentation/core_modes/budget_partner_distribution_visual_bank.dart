import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_distribution_svg_resources.dart';

/// One immutable unselected partner donut for one exact Budget target. Partner
/// remains read-only: category target changes filter data but never lift a
/// partner slice or create partner selection state.
@immutable
final class DashboardBudgetPartnerDistributionVisualFrame {
  const DashboardBudgetPartnerDistributionVisualFrame({
    required this.semanticFrame,
    required this.svg,
  });

  final DashboardBudgetPartnerDistributionDirectionFrame semanticFrame;
  final String svg;
}

/// Both direction-local dense target banks for one exact period. Every category
/// target source is built/prewarmed with the drawable period so an avatar tick
/// becomes only a target-handle list lookup.
@immutable
final class DashboardBudgetPartnerDistributionVisualBank {
  DashboardBudgetPartnerDistributionVisualBank({
    required this.semanticBundle,
    required List<DashboardBudgetPartnerDistributionVisualFrame> incomeFrames,
    required List<DashboardBudgetPartnerDistributionVisualFrame> expenseFrames,
    required this.sourceBytes,
  }) : incomeFrames =
           List<DashboardBudgetPartnerDistributionVisualFrame>.unmodifiable(
             incomeFrames,
           ),
       expenseFrames =
           List<DashboardBudgetPartnerDistributionVisualFrame>.unmodifiable(
             expenseFrames,
           );

  final DashboardBudgetPartnerDistributionBundle semanticBundle;
  final List<DashboardBudgetPartnerDistributionVisualFrame> incomeFrames;
  final List<DashboardBudgetPartnerDistributionVisualFrame> expenseFrames;
  final int sourceBytes;

  int get variantCount => incomeFrames.length + expenseFrames.length;
  int get estimatedRetainedBytes => sourceBytes;

  DashboardBudgetPartnerDistributionVisualFrame frameFor(
    LedgerDirection direction, {
    int targetHandle = 0,
  }) {
    final frames = switch (direction) {
      LedgerDirection.income => incomeFrames,
      LedgerDirection.expense => expenseFrames,
    };
    if (targetHandle < 0 || targetHandle >= frames.length) {
      throw RangeError.range(
        targetHandle,
        0,
        frames.length - 1,
        'targetHandle',
      );
    }
    return frames[targetHandle];
  }

  Iterable<String> get allSources sync* {
    for (final frame in incomeFrames) {
      yield frame.svg;
    }
    for (final frame in expenseFrames) {
      yield frame.svg;
    }
  }

  factory DashboardBudgetPartnerDistributionVisualBank.prepare({
    required DashboardBudgetPartnerDistributionBundle semanticBundle,
    required BudgetDistributionSvgSourceGenerator sourceGenerator,
  }) {
    DashboardBudgetPartnerDistributionVisualFrame buildFrame(
      DashboardBudgetPartnerDistributionDirectionFrame frame,
    ) {
      final slices = List<BudgetCategoryDistributionSvgSlice>.unmodifiable([
        for (final entry in frame.entries)
          BudgetCategoryDistributionSvgSlice(
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      return DashboardBudgetPartnerDistributionVisualFrame(
        semanticFrame: frame,
        svg: sourceGenerator.generate(slices: slices, selectedIndex: null),
      );
    }

    final incomeFrames = <DashboardBudgetPartnerDistributionVisualFrame>[
      for (final frame in semanticBundle.incomeTargetFrames) buildFrame(frame),
    ];
    final expenseFrames = <DashboardBudgetPartnerDistributionVisualFrame>[
      for (final frame in semanticBundle.expenseTargetFrames) buildFrame(frame),
    ];
    return DashboardBudgetPartnerDistributionVisualBank(
      semanticBundle: semanticBundle,
      incomeFrames: incomeFrames,
      expenseFrames: expenseFrames,
      sourceBytes:
          incomeFrames.fold<int>(
            0,
            (total, frame) => total + utf8.encode(frame.svg).length,
          ) +
          expenseFrames.fold<int>(
            0,
            (total, frame) => total + utf8.encode(frame.svg).length,
          ),
    );
  }
}
