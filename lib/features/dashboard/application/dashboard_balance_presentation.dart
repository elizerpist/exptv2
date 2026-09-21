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

/// One exact transaction-order cumulative Balance sample.
///
/// [epochMinute] is the real local transaction coordinate used by the Header
/// X domain. [epochDay] remains explicit so display labels need not recover a
/// date from a fabricated score scale.
@immutable
final class DashboardBalanceHistoryPoint {
  const DashboardBalanceHistoryPoint({
    required this.entryId,
    required this.epochDay,
    required this.epochMinute,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required this.balanceMinor,
  });

  final String entryId;
  final int epochDay;
  final int epochMinute;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  final int balanceMinor;
}

/// Immutable all-time Balance evolution prepared by Dashboard Core.
///
/// It deliberately has no Summary plane/cursor. Its temporal domain is the
/// actual earliest through latest admitted transaction coordinate.
@immutable
final class DashboardBalanceHistorySeries {
  DashboardBalanceHistorySeries({
    required this.startInclusiveEpochMinute,
    required this.endInclusiveEpochMinute,
    required List<DashboardBalanceHistoryPoint> points,
  }) : assert(startInclusiveEpochMinute <= endInclusiveEpochMinute),
       assert(points.isNotEmpty),
       points = List<DashboardBalanceHistoryPoint>.unmodifiable(points);

  final int startInclusiveEpochMinute;
  final int endInclusiveEpochMinute;
  final List<DashboardBalanceHistoryPoint> points;
}

/// Immutable all-time Balance presentation supplied by Dashboard Core.
///
/// The source partitions retain their canonical non-temporal Query/filter
/// identity, but Summary time navigation is deliberately absent: the Balance
/// Header and carousel are not a second Summary view.
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
    this.history,
  });

  final String scopeKey;
  final int coreRevision;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  final int netTotalMinor;
  final String formattedNetTotal;
  final int presentationId;
  final DashboardBalanceLatestTransactionPresentation? latestTransaction;
  final DashboardBalanceHistorySeries? history;

  DashboardBalancePresentation copyWith({
    String? scopeKey,
    int? coreRevision,
    int? incomeTotalMinor,
    int? expenseTotalMinor,
    int? netTotalMinor,
    String? formattedNetTotal,
    int? presentationId,
    DashboardBalanceLatestTransactionPresentation? latestTransaction,
    DashboardBalanceHistorySeries? history,
  }) => DashboardBalancePresentation(
    scopeKey: scopeKey ?? this.scopeKey,
    coreRevision: coreRevision ?? this.coreRevision,
    incomeTotalMinor: incomeTotalMinor ?? this.incomeTotalMinor,
    expenseTotalMinor: expenseTotalMinor ?? this.expenseTotalMinor,
    netTotalMinor: netTotalMinor ?? this.netTotalMinor,
    formattedNetTotal: formattedNetTotal ?? this.formattedNetTotal,
    presentationId: presentationId ?? this.presentationId,
    latestTransaction: latestTransaction ?? this.latestTransaction,
    history: history ?? this.history,
  );
}
