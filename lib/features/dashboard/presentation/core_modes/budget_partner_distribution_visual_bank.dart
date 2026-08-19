import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_distribution_svg_resources.dart';

/// One immutable partner donut per direction. Partner is deliberately
/// read-only in Card2, so there is exactly one aggregate/unselected SVG
/// variant rather than one lifted source per partner.
@immutable
final class DashboardBudgetPartnerDistributionVisualFrame {
  const DashboardBudgetPartnerDistributionVisualFrame({
    required this.semanticFrame,
    required this.svg,
  });

  final DashboardBudgetPartnerDistributionDirectionFrame semanticFrame;
  final String svg;
}

/// Both direction-local partner donut sources for one exact period. This uses
/// the same Fluvi clay-donut source generator as Category; only selection
/// semantics differ.
@immutable
final class DashboardBudgetPartnerDistributionVisualBank {
  const DashboardBudgetPartnerDistributionVisualBank({
    required this.semanticBundle,
    required this.income,
    required this.expense,
    required this.sourceBytes,
  });

  final DashboardBudgetPartnerDistributionBundle semanticBundle;
  final DashboardBudgetPartnerDistributionVisualFrame income;
  final DashboardBudgetPartnerDistributionVisualFrame expense;
  final int sourceBytes;

  int get variantCount => 2;
  int get estimatedRetainedBytes => sourceBytes;

  DashboardBudgetPartnerDistributionVisualFrame frameFor(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => income,
    LedgerDirection.expense => expense,
  };

  Iterable<String> get allSources sync* {
    yield income.svg;
    yield expense.svg;
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

    final income = buildFrame(semanticBundle.income);
    final expense = buildFrame(semanticBundle.expense);
    return DashboardBudgetPartnerDistributionVisualBank(
      semanticBundle: semanticBundle,
      income: income,
      expense: expense,
      sourceBytes:
          utf8.encode(income.svg).length + utf8.encode(expense.svg).length,
    );
  }
}
