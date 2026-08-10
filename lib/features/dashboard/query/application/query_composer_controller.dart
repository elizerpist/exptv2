import 'package:flutter/foundation.dart';

import 'current_query_controller.dart';
import '../domain/current_ledger_query_scope.dart';

/// Presentation/application state for one open Query sheet.
///
/// It intentionally owns only a discardable draft. Persistent saved queries
/// and the dashboard's applied scope remain in their respective owners.
final class QueryComposerController extends ChangeNotifier {
  QueryComposerController({required CurrentQueryController appliedQuery})
    : _appliedQuery = appliedQuery,
      _draft = appliedQuery.scope;

  final CurrentQueryController _appliedQuery;
  CurrentLedgerQueryScope _draft;
  bool _isOpen = false;

  CurrentLedgerQueryScope get draft => _draft;
  bool get isOpen => _isOpen;
  bool get isDirty => _draft != _appliedQuery.scope;

  void open() {
    _draft = _appliedQuery.scope;
    _isOpen = true;
    notifyListeners();
  }

  void updateDraft({required CurrentLedgerQueryScope scope}) {
    if (!_isOpen || scope == _draft) return;
    _draft = scope;
    notifyListeners();
  }

  void closeWithoutApply() {
    if (!_isOpen) return;
    _draft = _appliedQuery.scope;
    _isOpen = false;
    notifyListeners();
  }

  /// Ends an edit session after the dashboard composition root has atomically
  /// published this draft as its new applied scope.
  ///
  /// The composer deliberately has no API that writes [_appliedQuery]. Query
  /// execution also swaps the prepared index and temporal availability, so a
  /// direct write here would create a second applied-query commit path.
  void completeApplied() {
    if (!_isOpen) return;
    _draft = _appliedQuery.scope;
    _isOpen = false;
    notifyListeners();
  }
}
