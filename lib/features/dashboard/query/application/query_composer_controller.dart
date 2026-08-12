import 'package:flutter/foundation.dart';

import 'current_query_controller.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';

/// Exact authority for one discardable Query editing state.
///
/// The applied Query remains owned by the dashboard composition root. This
/// token only prevents an asynchronous Apply started for an older sheet/draft
/// from completing a newer editing session.
@immutable
final class QueryComposerApplyIdentity {
  const QueryComposerApplyIdentity({
    required this.sessionId,
    required this.direction,
    required this.draftKey,
  });

  final int sessionId;
  final LedgerDirection direction;
  final String draftKey;

  @override
  bool operator ==(Object other) =>
      other is QueryComposerApplyIdentity &&
      other.sessionId == sessionId &&
      other.direction == direction &&
      other.draftKey == draftKey;

  @override
  int get hashCode => Object.hash(sessionId, direction, draftKey);
}

enum QueryComposerStateChange {
  opened,
  draftChanged,
  closed,
  applyAccepted,
  applied,
  applyAborted,
}

/// Presentation/application state for one open Query sheet.
///
/// It intentionally owns only a discardable draft. Persistent saved queries
/// and the dashboard's applied scope remain in their respective owners.
final class QueryComposerController extends ChangeNotifier {
  QueryComposerController({required CurrentQueryController appliedQuery})
    : _appliedQuery = appliedQuery,
      _editingDirection = appliedQuery.scope.direction,
      _draft = appliedQuery.scope;

  final CurrentQueryController _appliedQuery;
  LedgerDirection _editingDirection;
  CurrentLedgerQueryScope _draft;
  bool _isOpen = false;
  int _sessionId = 0;
  QueryComposerApplyIdentity? _acceptedApplyIdentity;
  QueryComposerStateChange _lastStateChange = QueryComposerStateChange.closed;

  CurrentLedgerQueryScope get draft => _draft;
  LedgerDirection get editingDirection => _editingDirection;
  bool get isOpen => _isOpen;
  bool get isDirty => _draft != _appliedQuery.scopeFor(_editingDirection);
  QueryComposerStateChange get lastStateChange => _lastStateChange;
  bool get hasAcceptedApply => _acceptedApplyIdentity != null;
  QueryComposerApplyIdentity get applyIdentity => QueryComposerApplyIdentity(
    sessionId: _sessionId,
    direction: _editingDirection,
    draftKey: _draft.key.value,
  );

  bool isCurrentApplyIdentity(QueryComposerApplyIdentity identity) =>
      _acceptedApplyIdentity == identity ||
      (_isOpen && identity == applyIdentity);

  void open([LedgerDirection? direction]) {
    // A new visible edit session is newer intent than a visually dismissed,
    // still preparing Apply. Its immutable token becomes stale here; the core
    // observes this controller change and rejects the old publication.
    _acceptedApplyIdentity = null;
    _editingDirection = direction ?? _appliedQuery.scope.direction;
    _draft = _appliedQuery.scopeFor(_editingDirection);
    _isOpen = true;
    _sessionId += 1;
    _lastStateChange = QueryComposerStateChange.opened;
    notifyListeners();
  }

  void updateDraft({required CurrentLedgerQueryScope scope}) {
    if (!_isOpen || scope.direction != _editingDirection || scope == _draft) {
      return;
    }
    _draft = scope;
    _sessionId += 1;
    _lastStateChange = QueryComposerStateChange.draftChanged;
    notifyListeners();
  }

  void closeWithoutApply() {
    if (!_isOpen && _acceptedApplyIdentity == null) return;
    _acceptedApplyIdentity = null;
    _draft = _appliedQuery.scopeFor(_editingDirection);
    _isOpen = false;
    _sessionId += 1;
    _lastStateChange = QueryComposerStateChange.closed;
    notifyListeners();
  }

  /// Freezes the current draft as one accepted Apply intent, then ends only
  /// the editable/visible session. The applied dashboard scope is untouched
  /// until [completeApplied] is called by the composition root.
  bool acceptApply(QueryComposerApplyIdentity identity) {
    if (!_isOpen || identity != applyIdentity) return false;
    _acceptedApplyIdentity = identity;
    _isOpen = false;
    _lastStateChange = QueryComposerStateChange.applyAccepted;
    notifyListeners();
    return true;
  }

  /// Clears a failed accepted intent without mutating the applied scope.
  bool abortAcceptedApply({required QueryComposerApplyIdentity identity}) {
    if (_acceptedApplyIdentity != identity) return false;
    _acceptedApplyIdentity = null;
    _editingDirection = identity.direction;
    // The sheet did not dismiss, so a failed staged Apply remains an editable
    // draft rather than silently reverting to the old applied filters.
    _isOpen = true;
    _sessionId += 1;
    _lastStateChange = QueryComposerStateChange.applyAborted;
    notifyListeners();
    return true;
  }

  /// Ends an edit session after the dashboard composition root has atomically
  /// published this draft as its new applied scope.
  ///
  /// The composer deliberately has no API that writes [_appliedQuery]. Query
  /// execution also swaps the prepared index and temporal availability, so a
  /// direct write here would create a second applied-query commit path.
  bool completeApplied({QueryComposerApplyIdentity? expectedIdentity}) {
    if ((expectedIdentity != null &&
            !isCurrentApplyIdentity(expectedIdentity)) ||
        (!_isOpen && _acceptedApplyIdentity == null)) {
      return false;
    }
    _editingDirection = expectedIdentity?.direction ?? _editingDirection;
    _draft = _appliedQuery.scopeFor(_editingDirection);
    _isOpen = false;
    _acceptedApplyIdentity = null;
    _sessionId += 1;
    _lastStateChange = QueryComposerStateChange.applied;
    notifyListeners();
    return true;
  }
}
