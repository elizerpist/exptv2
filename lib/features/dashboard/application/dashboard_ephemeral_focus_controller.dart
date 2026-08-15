import 'package:flutter/foundation.dart';

import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';

/// UI-neutral metadata already carried by a prepared visible row. It lets a
/// focus chip present the selected semantic entity without another lookup.
@immutable
final class DashboardFocusFacet {
  const DashboardFocusFacet({
    required this.id,
    required this.displayName,
    this.colorId,
    this.iconId,
  });

  final String id;
  final String displayName;
  final String? colorId;
  final String? iconId;
}

/// Identity of a temporary focus relative to one committed directional base.
///
/// The focus is deliberately not a Query draft or an applied Query mutation:
/// it can only be used while this exact base identity/revision remains valid.
@immutable
final class DashboardEphemeralFocusAnchor {
  const DashboardEphemeralFocusAnchor({
    required this.direction,
    required this.baseQueryKey,
    required this.coreRevision,
  });

  final LedgerDirection direction;
  final LedgerQueryKey baseQueryKey;
  final int coreRevision;

  bool matches({
    required CurrentLedgerQueryScope baseScope,
    required int revision,
  }) =>
      direction == baseScope.direction &&
      baseQueryKey == baseScope.key &&
      coreRevision == revision;
}

@immutable
final class DashboardEphemeralFocusState {
  const DashboardEphemeralFocusState({
    required this.anchor,
    this.category,
    this.partner,
  }) : assert(category != null || partner != null);

  final DashboardEphemeralFocusAnchor anchor;
  final DashboardFocusFacet? category;
  final DashboardFocusFacet? partner;

  bool get isEmpty => category == null && partner == null;

  DashboardEphemeralFocusState copyWith({
    DashboardFocusFacet? category,
    DashboardFocusFacet? partner,
    bool clearCategory = false,
    bool clearPartner = false,
  }) => DashboardEphemeralFocusState(
    anchor: anchor,
    category: clearCategory ? null : category ?? this.category,
    partner: clearPartner ? null : partner ?? this.partner,
  );
}

/// The single authoritative owner of temporary Category/Partner focus.
///
/// It contains only the focus overlay. The committed base query remains owned
/// by [CurrentQueryController], while the dashboard composition root turns an
/// effective scope into an atomically published prepared presentation.
final class DashboardEphemeralFocusController extends ChangeNotifier {
  DashboardEphemeralFocusState? _state;

  DashboardEphemeralFocusState? get state => _state;

  /// Atomically publishes the complete two-dimensional overlay after its
  /// matching immutable presentation has become authoritative. UI never sees
  /// a focus chip for rows that still belong to the base presentation.
  void replace({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    required DashboardFocusFacet? category,
    required DashboardFocusFacet? partner,
  }) {
    final next = category == null && partner == null
        ? null
        : DashboardEphemeralFocusState(
            anchor: DashboardEphemeralFocusAnchor(
              direction: baseScope.direction,
              baseQueryKey: baseScope.key,
              coreRevision: coreRevision,
            ),
            category: category,
            partner: partner,
          );
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void focusCategory({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    required DashboardFocusFacet facet,
  }) {
    _replaceDimension(
      baseScope: baseScope,
      coreRevision: coreRevision,
      category: facet,
    );
  }

  void focusPartner({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    required DashboardFocusFacet facet,
  }) {
    _replaceDimension(
      baseScope: baseScope,
      coreRevision: coreRevision,
      partner: facet,
    );
  }

  void _replaceDimension({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    DashboardFocusFacet? category,
    DashboardFocusFacet? partner,
  }) {
    final anchor = DashboardEphemeralFocusAnchor(
      direction: baseScope.direction,
      baseQueryKey: baseScope.key,
      coreRevision: coreRevision,
    );
    final prior = _state;
    final next =
        prior != null &&
            prior.anchor.matches(baseScope: baseScope, revision: coreRevision)
        ? prior.copyWith(category: category, partner: partner)
        : DashboardEphemeralFocusState(
            anchor: anchor,
            category: category,
            partner: partner,
          );
    _state = next;
    notifyListeners();
  }

  void clearCategory() => _clearDimension(category: true);

  void clearPartner() => _clearDimension(partner: true);

  void clearAll() {
    if (_state == null) return;
    _state = null;
    notifyListeners();
  }

  void _clearDimension({bool category = false, bool partner = false}) {
    final current = _state;
    if (current == null) return;
    final nextCategory = category ? null : current.category;
    final nextPartner = partner ? null : current.partner;
    _state = nextCategory == null && nextPartner == null
        ? null
        : DashboardEphemeralFocusState(
            anchor: current.anchor,
            category: nextCategory,
            partner: nextPartner,
          );
    notifyListeners();
  }

  /// Returns true only when a structurally newer committed base made the old
  /// temporary overlay unsafe to reuse. Focus is never implicitly rebased.
  bool invalidateIfBaseChanged({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
  }) {
    final current = _state;
    if (current == null ||
        current.anchor.matches(baseScope: baseScope, revision: coreRevision)) {
      return false;
    }
    _state = null;
    notifyListeners();
    return true;
  }

  /// Applies the currently valid overlay as a new immutable scope. Empty or
  /// stale focus falls through to the exact base object, avoiding accidental
  /// query-key churn in callers that only need the base presentation.
  CurrentLedgerQueryScope effectiveScopeFor(
    CurrentLedgerQueryScope baseScope, {
    int? coreRevision,
  }) {
    final current = _state;
    if (current == null ||
        (coreRevision != null &&
            !current.anchor.matches(
              baseScope: baseScope,
              revision: coreRevision,
            )) ||
        (coreRevision == null &&
            (current.anchor.direction != baseScope.direction ||
                current.anchor.baseQueryKey != baseScope.key))) {
      return baseScope;
    }
    return baseScope.copyWith(
      categoryIds: current.category == null
          ? baseScope.categoryIds
          : <String>{current.category!.id},
      partnerIds: current.partner == null
          ? baseScope.partnerIds
          : <String>{current.partner!.id},
    );
  }
}
