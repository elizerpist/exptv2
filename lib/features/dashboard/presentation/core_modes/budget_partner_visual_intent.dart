import 'package:flutter/foundation.dart';

import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

/// Immutable identity of one already-prepared Partner frame. It deliberately
/// contains no Query or focus state: it exists only to prevent direct visual
/// feedback from leaking into a different Budget target or time analysis.
@immutable
final class BudgetPartnerVisualIdentity {
  const BudgetPartnerVisualIdentity({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.analysisScope,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final LedgerTimeScope analysisScope;

  @override
  bool operator ==(Object other) =>
      other is BudgetPartnerVisualIdentity &&
      other.coreRevision == coreRevision &&
      other.direction == direction &&
      other.targetHandle == targetHandle &&
      other.analysisScope == analysisScope;

  @override
  int get hashCode =>
      Object.hash(coreRevision, direction, targetHandle, analysisScope);
}

/// One local direct-manipulation acknowledgement that awaits the authoritative
/// prepared ephemeral-focus publication. It must never become a second filter
/// or Query owner.
@immutable
final class BudgetPartnerVisualIntent {
  const BudgetPartnerVisualIntent({
    required this.partner,
    required this.identity,
    required this.generation,
  });

  final DashboardFocusFacet partner;
  final BudgetPartnerVisualIdentity identity;
  final int generation;
}

/// Presentation-only latest-intent latch for the Partner Card2 page.
///
/// Core remains the only authority for focus chips, LogBox rows and effective
/// Query scope. This controller only gives the already-prepared donut and row
/// an immediate tap-frame selected identity, then acknowledges or rolls it
/// back when Core's existing focus publication resolves.
final class BudgetPartnerVisualIntentController {
  BudgetPartnerVisualIntent? _pending;
  var _nextGeneration = 0;

  BudgetPartnerVisualIntent? get pending => _pending;

  BudgetPartnerVisualIntent begin({
    required DashboardFocusFacet partner,
    required BudgetPartnerVisualIdentity identity,
  }) {
    final next = BudgetPartnerVisualIntent(
      partner: partner,
      identity: identity,
      generation: ++_nextGeneration,
    );
    _pending = next;
    return next;
  }

  DashboardFocusFacet? effectivePartner({
    required BudgetPartnerVisualIdentity identity,
    required Set<String> availablePartnerIds,
    required DashboardFocusFacet? authoritativePartner,
  }) {
    final pending = _pending;
    if (pending == null ||
        pending.identity != identity ||
        !availablePartnerIds.contains(pending.partner.id)) {
      return authoritativePartner;
    }
    return pending.partner;
  }

  /// Returns true only when this call removed the current local latch.
  bool acknowledge({
    required BudgetPartnerVisualIdentity identity,
    required DashboardFocusFacet? authoritativePartner,
  }) {
    final pending = _pending;
    if (pending == null ||
        pending.identity != identity ||
        pending.partner.id != authoritativePartner?.id) {
      return false;
    }
    _pending = null;
    return true;
  }

  /// Completion belongs to its originating local generation. A stale Core
  /// Future cannot roll back a newer tap.
  bool complete({required int generation, required bool accepted}) {
    final pending = _pending;
    if (pending == null || pending.generation != generation) return false;
    if (accepted) return false;
    _pending = null;
    return true;
  }

  /// Clears a latch only when its prepared scene identity has become invalid
  /// or the selected Partner is absent from the new exact scene.
  bool invalidateIfIncompatible({
    required BudgetPartnerVisualIdentity identity,
    required Set<String> availablePartnerIds,
  }) {
    final pending = _pending;
    if (pending == null ||
        (pending.identity == identity &&
            availablePartnerIds.contains(pending.partner.id))) {
      return false;
    }
    _pending = null;
    return true;
  }

  bool clear() {
    if (_pending == null) return false;
    _pending = null;
    return true;
  }
}
