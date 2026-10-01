import 'package:flutter/foundation.dart';

/// Presentation-only list ordering for Budget Card2. It never changes the
/// monetary-share donut scene or prepares/acquires financial data.
enum BudgetDistributionRanking { share, transactionCount }

extension BudgetDistributionRankingLabel on BudgetDistributionRanking {
  String get label => switch (this) {
    BudgetDistributionRanking.share => 'Részesedés',
    BudgetDistributionRanking.transactionCount => 'Tranzakciószám',
  };
}

/// Dashboard-lifetime state for the independently rendered Card2 legend
/// lists. It owns no Query, repository, prepared snapshot or PageController.
final class BudgetDistributionRankingController {
  BudgetDistributionRankingController({
    BudgetDistributionRanking categoryInitial = BudgetDistributionRanking.share,
    BudgetDistributionRanking partnerInitial = BudgetDistributionRanking.share,
  }) : category = ValueNotifier<BudgetDistributionRanking>(categoryInitial),
       partner = ValueNotifier<BudgetDistributionRanking>(partnerInitial);

  final ValueNotifier<BudgetDistributionRanking> category;
  final ValueNotifier<BudgetDistributionRanking> partner;

  void setCategory(BudgetDistributionRanking next) {
    if (category.value != next) category.value = next;
  }

  void setPartner(BudgetDistributionRanking next) {
    if (partner.value != next) partner.value = next;
  }

  void dispose() {
    category.dispose();
    partner.dispose();
  }
}

/// Shared deterministic sorting contract. Stable identity is the final tie
/// break so the selected row and pie slice are never coupled to row index.
abstract final class BudgetDistributionRankingOrder {
  static int compare({
    required BudgetDistributionRanking ranking,
    required int leftTransactionCount,
    required int rightTransactionCount,
    required int leftActualScaled100,
    required int rightActualScaled100,
    required int leftStableHandle,
    required int rightStableHandle,
  }) {
    if (ranking == BudgetDistributionRanking.transactionCount) {
      final byCount = rightTransactionCount.compareTo(leftTransactionCount);
      if (byCount != 0) return byCount;
    }
    final byActual = rightActualScaled100.compareTo(leftActualScaled100);
    return byActual != 0
        ? byActual
        : leftStableHandle.compareTo(rightStableHandle);
  }
}
