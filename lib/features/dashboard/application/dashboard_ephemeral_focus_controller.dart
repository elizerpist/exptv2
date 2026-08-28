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

/// Compatibility identity of a direct-manipulation Ledger facet.
///
/// Category and Partner are orthogonal to temporal navigation, so this
/// identity intentionally has no temporal/base-query key. Direction and
/// immutable core revision are the only compatibility boundaries.
@immutable
final class DashboardEphemeralFocusAnchor {
  const DashboardEphemeralFocusAnchor({
    required this.direction,
    required this.coreRevision,
  });

  final LedgerDirection direction;
  final int coreRevision;

  bool matches({
    required CurrentLedgerQueryScope baseScope,
    required int revision,
  }) => direction == baseScope.direction && coreRevision == revision;
}

@immutable
final class DashboardEphemeralFocusState {
  const DashboardEphemeralFocusState({
    required this.anchor,
    this.category,
    this.partner,
    this.normalizedSearch,
  }) : assert(category != null || partner != null || normalizedSearch != null);

  final DashboardEphemeralFocusAnchor anchor;
  final DashboardFocusFacet? category;
  final DashboardFocusFacet? partner;
  final String? normalizedSearch;

  bool get isEmpty =>
      category == null && partner == null && normalizedSearch == null;
}

/// The single authoritative owner of composable interactive Ledger facets.
///
/// It contains only the focus overlay. The committed base query remains owned
/// by [CurrentQueryController], while the dashboard composition root turns an
/// effective scope into an atomically published prepared presentation.
final class DashboardEphemeralFocusController extends ChangeNotifier {
  DashboardEphemeralFocusState? _state;

  DashboardEphemeralFocusState? get state => _state;

  /// Atomically publishes the complete direct-manipulation overlay as soon as
  /// its prepared membership frame is accepted. Rich scenes and paging may
  /// decorate that frame later, but never own chip visibility, close controls
  /// or the next user input.
  void replace({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    required DashboardFocusFacet? category,
    required DashboardFocusFacet? partner,
    String? normalizedSearch,
  }) {
    final next = category == null && partner == null && normalizedSearch == null
        ? null
        : DashboardEphemeralFocusState(
            anchor: DashboardEphemeralFocusAnchor(
              direction: baseScope.direction,
              coreRevision: coreRevision,
            ),
            category: category,
            partner: partner,
            normalizedSearch: normalizedSearch,
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

  /// Writes the live, already-normalized Search dimension without coupling it
  /// to an exact temporal Query key. Search composes with existing Category
  /// and Partner facets and clearing it restores only this dimension.
  void setNormalizedSearch({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    required String? normalizedSearch,
  }) {
    final prior = _state;
    final compatible =
        prior != null &&
        prior.anchor.matches(baseScope: baseScope, revision: coreRevision);
    final category = compatible ? prior.category : null;
    final partner = compatible ? prior.partner : null;
    _state = _stateOrNull(
      anchor: DashboardEphemeralFocusAnchor(
        direction: baseScope.direction,
        coreRevision: coreRevision,
      ),
      category: category,
      partner: partner,
      normalizedSearch: normalizedSearch,
    );
    notifyListeners();
  }

  void clearSearch() {
    final current = _state;
    if (current == null || current.normalizedSearch == null) return;
    _state = _stateOrNull(
      anchor: current.anchor,
      category: current.category,
      partner: current.partner,
    );
    notifyListeners();
  }

  void _replaceDimension({
    required CurrentLedgerQueryScope baseScope,
    required int coreRevision,
    DashboardFocusFacet? category,
    DashboardFocusFacet? partner,
  }) {
    final anchor = DashboardEphemeralFocusAnchor(
      direction: baseScope.direction,
      coreRevision: coreRevision,
    );
    final prior = _state;
    final compatible =
        prior != null &&
        prior.anchor.matches(baseScope: baseScope, revision: coreRevision);
    _state = _stateOrNull(
      anchor: anchor,
      category: category ?? (compatible ? prior.category : null),
      partner: partner ?? (compatible ? prior.partner : null),
      normalizedSearch: compatible ? prior.normalizedSearch : null,
    );
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
    _state = _stateOrNull(
      anchor: current.anchor,
      category: nextCategory,
      partner: nextPartner,
      normalizedSearch: current.normalizedSearch,
    );
    notifyListeners();
  }

  /// Returns true only for direction/revision incompatibility. A temporal or
  /// base-query change is intentionally compositional and keeps the facet.
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

  /// Applies the currently valid overlay over any temporal/base scope. Empty
  /// or incompatible focus falls through to the exact base object.
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
            current.anchor.direction != baseScope.direction)) {
      return baseScope;
    }
    return baseScope.copyWith(
      categoryIds: current.category == null
          ? baseScope.categoryIds
          : <String>{current.category!.id},
      partnerIds: current.partner == null
          ? baseScope.partnerIds
          : <String>{current.partner!.id},
      normalizedSearch: current.normalizedSearch,
    );
  }

  static DashboardEphemeralFocusState? _stateOrNull({
    required DashboardEphemeralFocusAnchor anchor,
    DashboardFocusFacet? category,
    DashboardFocusFacet? partner,
    String? normalizedSearch,
  }) {
    if (category == null && partner == null && normalizedSearch == null) {
      return null;
    }
    return DashboardEphemeralFocusState(
      anchor: anchor,
      category: category,
      partner: partner,
      normalizedSearch: normalizedSearch,
    );
  }
}

/// Preferred architectural names. The legacy file/class names remain only to
/// avoid a broad unrelated rename while the dashboard migrates call sites.
typedef DashboardInteractiveFacetController = DashboardEphemeralFocusController;
typedef DashboardInteractiveFacetState = DashboardEphemeralFocusState;
