/// Owns the hand-off rules for the Budget V2 avatar belt.
///
/// The rail has two distinct callers: direct pointer manipulation and an
/// explicit external chart/tap request. A normal parent rebuild is neither.
/// Keeping that distinction out of the widget rendering code prevents a
/// just-published dashboard selection from stealing a new drag.
enum SpendeeBudgetV2AvatarRailOwner { idle, direct, external }

class SpendeeBudgetV2AvatarRailCoordinator {
  SpendeeBudgetV2AvatarRailCoordinator({required int externalSelectionEpoch})
    : _seenExternalSelectionEpoch = externalSelectionEpoch;

  var _serial = 0;
  var _settledSerial = -1;
  var _seenExternalSelectionEpoch = 0;
  var _owner = SpendeeBudgetV2AvatarRailOwner.idle;
  int? _externalTargetIndex;

  int get activeSerial => _serial;
  bool get ownsExternalMotion =>
      _owner == SpendeeBudgetV2AvatarRailOwner.external;
  bool get ownsDirectMotion => _owner == SpendeeBudgetV2AvatarRailOwner.direct;
  int? get externalTargetIndex => _externalTargetIndex;

  /// A selected-index prop is only a real command when its explicit epoch is
  /// newer. This deliberately ignores local-settlement acknowledgements.
  bool consumeExternalSelectionEpoch(int epoch) {
    if (epoch == _seenExternalSelectionEpoch) return false;
    _seenExternalSelectionEpoch = epoch;
    return true;
  }

  int beginDirectMotion() {
    _owner = SpendeeBudgetV2AvatarRailOwner.direct;
    _externalTargetIndex = null;
    return ++_serial;
  }

  int beginExternalMotion({required int targetIndex}) {
    _owner = SpendeeBudgetV2AvatarRailOwner.external;
    _externalTargetIndex = targetIndex;
    return ++_serial;
  }

  bool isCurrent(int serial) => serial == _serial;

  bool settle(int serial) {
    if (!isCurrent(serial) || _settledSerial == serial) return false;
    _settledSerial = serial;
    _owner = SpendeeBudgetV2AvatarRailOwner.idle;
    _externalTargetIndex = null;
    return true;
  }

  void finishWithoutSettlement(int serial) {
    if (isCurrent(serial)) {
      _owner = SpendeeBudgetV2AvatarRailOwner.idle;
      _externalTargetIndex = null;
    }
  }

  /// Invalidates an in-flight direct release before a newer raw pointer can
  /// become a drag. The newer drag receives its own serial and cannot inherit
  /// the old release's settlement callback.
  void interruptDirectMotion() {
    if (!ownsDirectMotion) return;
    _serial += 1;
    _owner = SpendeeBudgetV2AvatarRailOwner.idle;
    _externalTargetIndex = null;
  }

  void reset({required int externalSelectionEpoch}) {
    _serial += 1;
    _settledSerial = -1;
    _seenExternalSelectionEpoch = externalSelectionEpoch;
    _owner = SpendeeBudgetV2AvatarRailOwner.idle;
    _externalTargetIndex = null;
  }
}
