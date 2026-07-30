import 'package:flutter/foundation.dart';

enum BudgetV2SelectionPhase { physical, settled, committed }

class BudgetV2SelectionController extends ChangeNotifier {
  static const int maxRememberedGenerations = 32;

  BudgetV2SelectionController({required String initialAvatarKey})
    : _settledAvatarKey = initialAvatarKey,
      _committedAvatarKey = initialAvatarKey;

  var _generation = 0;
  var _phase = BudgetV2SelectionPhase.committed;
  var _physicalOffset = 0.0;
  String _settledAvatarKey;
  String _committedAvatarKey;
  final Map<int, int> _commitsByGeneration = <int, int>{};

  BudgetV2SelectionPhase get phase => _phase;
  double get physicalOffset => _physicalOffset;
  String get settledAvatarKey => _settledAvatarKey;
  String get committedAvatarKey => _committedAvatarKey;

  int beginPointerDown() {
    _generation += 1;
    _phase = BudgetV2SelectionPhase.physical;
    _physicalOffset = 0;
    _settledAvatarKey = _committedAvatarKey;
    notifyListeners();
    return _generation;
  }

  void adoptCommittedAvatar(String avatarKey) {
    if (_phase == BudgetV2SelectionPhase.committed &&
        _committedAvatarKey == avatarKey) {
      return;
    }
    _generation += 1;
    _phase = BudgetV2SelectionPhase.committed;
    _physicalOffset = 0;
    _settledAvatarKey = avatarKey;
    _committedAvatarKey = avatarKey;
    notifyListeners();
  }

  void updatePhysical({required double offset}) {
    if (_phase != BudgetV2SelectionPhase.physical) return;
    _physicalOffset = offset;
    notifyListeners();
  }

  bool settleAvatar(String avatarKey, {required int generation}) {
    if (generation != _generation ||
        _phase != BudgetV2SelectionPhase.physical) {
      return false;
    }
    _settledAvatarKey = avatarKey;
    _phase = BudgetV2SelectionPhase.settled;
    notifyListeners();
    return true;
  }

  bool commitIfCurrent(int generation) {
    if (generation != _generation ||
        _phase != BudgetV2SelectionPhase.settled ||
        commitsForGeneration(generation) != 0) {
      return false;
    }
    _committedAvatarKey = _settledAvatarKey;
    _phase = BudgetV2SelectionPhase.committed;
    _commitsByGeneration[generation] = 1;
    while (_commitsByGeneration.length > maxRememberedGenerations) {
      _commitsByGeneration.remove(_commitsByGeneration.keys.first);
    }
    notifyListeners();
    return true;
  }

  int commitsForGeneration(int generation) =>
      _commitsByGeneration[generation] ?? 0;
}
