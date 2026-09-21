import 'package:flutter/foundation.dart';

import '../query/domain/ledger_direction.dart';

/// One already-prepared latest item for the Balance prototype card.
///
/// It is built by Dashboard Core from a bounded prepared LogBox preview. The
/// Balance renderer receives no repository, raw ledger collection, or scope
/// lookup capability.
@immutable
final class DashboardBalanceLatestTransactionPresentation {
  const DashboardBalanceLatestTransactionPresentation({
    required this.entryId,
    required this.title,
    required this.formattedAmount,
    required this.direction,
    required this.occurredOrder,
  });

  final String entryId;
  final String title;
  final String formattedAmount;
  final LedgerDirection direction;
  final int occurredOrder;
}

/// Immutable, current-scope Balance presentation supplied by Dashboard Core.
@immutable
final class DashboardBalancePresentation {
  const DashboardBalancePresentation({
    required this.scopeKey,
    required this.coreRevision,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required this.netTotalMinor,
    required this.formattedNetTotal,
    required this.presentationId,
    this.latestTransaction,
  });

  final String scopeKey;
  final int coreRevision;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  final int netTotalMinor;
  final String formattedNetTotal;
  final int presentationId;
  final DashboardBalanceLatestTransactionPresentation? latestTransaction;

  DashboardBalancePresentation copyWith({
    String? scopeKey,
    int? coreRevision,
    int? incomeTotalMinor,
    int? expenseTotalMinor,
    int? netTotalMinor,
    String? formattedNetTotal,
    int? presentationId,
    DashboardBalanceLatestTransactionPresentation? latestTransaction,
  }) => DashboardBalancePresentation(
    scopeKey: scopeKey ?? this.scopeKey,
    coreRevision: coreRevision ?? this.coreRevision,
    incomeTotalMinor: incomeTotalMinor ?? this.incomeTotalMinor,
    expenseTotalMinor: expenseTotalMinor ?? this.expenseTotalMinor,
    netTotalMinor: netTotalMinor ?? this.netTotalMinor,
    formattedNetTotal: formattedNetTotal ?? this.formattedNetTotal,
    presentationId: presentationId ?? this.presentationId,
    latestTransaction: latestTransaction ?? this.latestTransaction,
  );
}
