import 'package:flutter/foundation.dart';

import '../../motion/dashboard_semantic_catalog.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_prepared_deck.dart';

@immutable
final class DashboardPreparedDeckRequest {
  const DashboardPreparedDeckRequest({
    required this.key,
    required this.parentScope,
    required this.semanticCatalog,
  });

  factory DashboardPreparedDeckRequest.fromDeck(DashboardPreparedDeck deck) =>
      DashboardPreparedDeckRequest(
        key: deck.key,
        parentScope: deck.parentScope,
        semanticCatalog: deck.semanticCatalog,
      );

  final DashboardPreparedDeckKey key;
  final CurrentLedgerQueryScope parentScope;
  final DashboardSemanticCatalog semanticCatalog;
}

/// Cooperative preparation cancellation and priority token.
final class DashboardPreparationToken {
  DashboardPreparationToken({required this.generation, required bool required})
    : _required = required;

  final int generation;
  bool _required;
  bool _cancelled = false;

  bool get isRequired => _required;
  bool get isCancelled => _cancelled;

  void promoteToRequired() {
    _required = true;
    _cancelled = false;
  }

  void cancel() => _cancelled = true;
}

abstract interface class DashboardPreparedDeckRepository {
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  );
}

/// Read-only cumulative measurements exposed to integration/profile harnesses.
/// Production presentation never listens to this object.
abstract interface class DashboardPreparedRepositoryMetrics {
  Map<String, Object?> performanceReport();
}

/// Capability marker used only for exact diagnostics counters. It lets the
/// application count native transport/SQL starts without importing a concrete
/// MethodChannel adapter into the controller layer.
abstract interface class DashboardNativePreparedRepository {}

@immutable
final class DashboardCommittedFrameRequest {
  const DashboardCommittedFrameRequest({
    required this.scope,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.presentationEpoch,
    required this.leaseGeneration,
    required this.pageSize,
  });

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final int presentationEpoch;
  final int leaseGeneration;
  final int pageSize;
}

/// Prepared live/page transport used only by the committed-query owner.
/// Implementations must decode and project frames outside the UI isolate.
abstract interface class DashboardPreparedLiveRepository {
  Stream<DashboardPreparedFrame> watchCommittedFrame(
    DashboardCommittedFrameRequest request,
  );

  Future<DashboardPreparedFrame> readCommittedNextPage(
    DashboardCommittedFrameRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  });
}

/// Stable source for the monotonic database revision used by the seed gate.
abstract interface class DashboardCoreRevisionRepository {
  Stream<int> watchCoreRevision();
}
