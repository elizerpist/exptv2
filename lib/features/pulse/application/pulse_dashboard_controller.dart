import 'package:flutter/foundation.dart';

import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

final class PulseDashboardController extends ChangeNotifier {
  PulseDashboardController({required PulseRepository repository, DateTime? initialDate})
    : _repository = repository,
      _scope = initialDate ?? DateTime.now();

  final PulseRepository _repository;
  DateTime _scope;
  PulseGroup _group = PulseGroup.spending;
  PulseDashboardSnapshot? _snapshot;
  Object? _error;
  bool _loading = false;
  int _request = 0;

  DateTime get scope => _scope;
  PulseGroup get group => _group;
  PulseDashboardSnapshot? get snapshot => _snapshot;
  Object? get error => _error;
  bool get loading => _loading;

  Future<void> load() async {
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.dashboard(
        year: _scope.year,
        month: _scope.month,
      );
      if (request != _request) return;
      _snapshot = snapshot;
    } catch (error) {
      if (request != _request) return;
      _error = error;
    } finally {
      if (request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> shiftMonth(int delta) {
    _scope = DateTime(_scope.year, _scope.month + delta, 1);
    return load();
  }

  void selectGroup(PulseGroup group) {
    if (_group == group) return;
    _group = group;
    notifyListeners();
  }
}
