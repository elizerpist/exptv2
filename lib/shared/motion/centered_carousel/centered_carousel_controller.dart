// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'centered_carousel_data_source.dart';
import 'centered_carousel_spec.dart';

class CenteredCarouselController extends ChangeNotifier {
  CenteredCarouselController({required int initialIndex})
    : _selectedLogicalIndex = initialIndex,
      _logicalOrigin = initialIndex,
      _rawCenteredIndex = initialIndex.toDouble(),
      _scrollController = ScrollController() {
    _scrollController.addListener(_handleScroll);
  }

  static const int virtualItemCount = 200001;
  static const int virtualAnchorIndex = 100000;
  static const int rebaseThresholdItems = 5000;

  final ScrollController _scrollController;
  CenteredCarouselDataMode _dataMode = CenteredCarouselDataMode.bounded;
  int _finiteLength = 0;
  int _physicalItemCount = 0;
  double _itemExtent = 0;
  int _selectedPhysicalIndex = 0;
  int _selectedLogicalIndex;
  int _logicalOrigin;
  double _rawCenteredIndex;
  bool _configured = false;
  bool _enableHaptics = false;
  Duration _hapticThrottle = const Duration(milliseconds: 38);
  Duration _programmaticScrollDuration =
      CenteredCarouselSpec.defaultProgrammaticScrollDuration;
  Curve _programmaticScrollCurve =
      CenteredCarouselSpec.defaultProgrammaticScrollCurve;
  bool _isScrolling = false;
  bool _isRebasing = false;
  bool _suppressScrollEvents = false;
  ValueListenable<bool>? _scrollingNotifier;
  int? _lastHapticLogicalIndex;
  DateTime? _lastHapticAt;
  int _motionCommandId = 0;
  int _activeMotionCommandId = 0;
  int? _lastSettledCommandId;

  /// Kept for compatibility with the original controller API.
  ValueChanged<int>? onSelectedChanged;
  ValueChanged<int>? onPreviewChanged;
  ValueChanged<int>? onSelectionSettled;
  VoidCallback? onHapticTick;

  int get selectedIndex => _selectedLogicalIndex;
  int get selectedLogicalIndex => _selectedLogicalIndex;
  int get selectedPhysicalIndex => _selectedPhysicalIndex;
  double get rawCenteredIndex => _rawCenteredIndex;
  double get rawCenteredLogicalIndex =>
      _logicalOrigin + _rawCenteredIndex - virtualAnchorIndex;
  int get logicalOrigin => _logicalOrigin;
  int get physicalItemCount => _physicalItemCount;
  CenteredCarouselDataMode get dataMode => _dataMode;
  bool get isInfinite => _dataMode != CenteredCarouselDataMode.bounded;
  bool get isRebasing => _isRebasing;
  bool get isScrolling => _isScrolling;
  // ScrollPosition.activity distinguishes ballistic/spring activity from a
  // user drag; both must be interruptible by an immediate retarget tap.
  bool get hasActiveScrollActivity =>
      _scrollController.hasClients &&
      _scrollController.position.activity is! IdleScrollActivity;
  ScrollController get scrollController => _scrollController;

  /// Starts a new user-owned motion command.
  ///
  /// This is intentionally independent from the scroll physics. It only
  /// invalidates callbacks belonging to a previous drag/fling/animation.
  int beginMotionCommand() {
    final commandId = ++_motionCommandId;
    _activeMotionCommandId = commandId;
    return commandId;
  }

  bool isCurrentMotionCommand(int commandId) => commandId == _motionCommandId;

  void updateConfiguration({
    required int itemCount,
    required double itemExtent,
    CenteredCarouselDataMode dataMode = CenteredCarouselDataMode.bounded,
    int? finiteLength,
    bool enableHaptics = false,
    Duration? hapticThrottle,
    Duration? programmaticScrollDuration,
    Curve? programmaticScrollCurve,
  }) {
    final nextFiniteLength = (finiteLength ?? itemCount).clamp(0, 1 << 30);
    final configurationChanged =
        !_configured ||
        _dataMode != dataMode ||
        _finiteLength != nextFiniteLength ||
        _itemExtent != itemExtent;

    _dataMode = dataMode;
    _finiteLength = nextFiniteLength;
    _itemExtent = itemExtent;
    _physicalItemCount = switch (dataMode) {
      CenteredCarouselDataMode.bounded => _finiteLength,
      CenteredCarouselDataMode.cyclic =>
        _finiteLength == 0 ? 0 : virtualItemCount,
      CenteredCarouselDataMode.generated => virtualItemCount,
    };
    _enableHaptics = enableHaptics;
    _hapticThrottle = hapticThrottle ?? _hapticThrottle;
    _programmaticScrollDuration =
        programmaticScrollDuration ?? _programmaticScrollDuration;
    _programmaticScrollCurve =
        programmaticScrollCurve ?? _programmaticScrollCurve;

    if (configurationChanged) {
      if (dataMode == CenteredCarouselDataMode.bounded) {
        _selectedLogicalIndex = _clampBounded(_selectedLogicalIndex);
        _logicalOrigin = 0;
        _selectedPhysicalIndex = _selectedLogicalIndex;
      } else {
        _logicalOrigin = _selectedLogicalIndex;
        _selectedPhysicalIndex = _physicalForLogical(_selectedLogicalIndex);
      }
      _rawCenteredIndex = _selectedPhysicalIndex.toDouble();
      _lastHapticLogicalIndex = _selectedLogicalIndex;
    }
    _configured = true;
    _attachScrollingNotifier();
    if (configurationChanged) {
      recenterSelected();
    }
    notifyListeners();
  }

  int logicalIndexForPhysical(int physicalIndex) {
    if (!isInfinite) return _clampBounded(physicalIndex);
    return _logicalOrigin + physicalIndex - virtualAnchorIndex;
  }

  int physicalIndexForLogical(int logicalIndex) {
    if (!isInfinite) return _clampBounded(logicalIndex);
    return (virtualAnchorIndex + logicalIndex - _logicalOrigin).clamp(
      0,
      virtualItemCount - 1,
    );
  }

  Future<void> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    final logicalIndex = isInfinite ? index : _clampBounded(index);
    final physicalIndex = physicalIndexForLogical(logicalIndex);
    await _animateToPhysicalIndex(
      physicalIndex,
      logicalIndex: logicalIndex,
      duration: duration,
      curve: curve,
    );
  }

  /// Retargets directly to the physical slot that was tapped.
  ///
  /// This matters for infinite and cyclic carousels where the same domain
  /// value can be represented by more than one physical slot.
  Future<void> tapToPhysicalIndex(
    int physicalIndex, {
    Duration? duration,
    Curve? curve,
  }) async {
    if (_physicalItemCount <= 0) return;

    final targetPhysicalIndex = physicalIndex.clamp(0, _physicalItemCount - 1);
    final logicalIndex = logicalIndexForPhysical(targetPhysicalIndex);
    await _animateToPhysicalIndex(
      targetPhysicalIndex,
      logicalIndex: logicalIndex,
      duration: duration,
      curve: curve,
    );
  }

  Future<void> _animateToPhysicalIndex(
    int physicalIndex, {
    required int logicalIndex,
    Duration? duration,
    Curve? curve,
  }) async {
    final commandId = beginMotionCommand();
    if (!_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      _setSelection(logicalIndex, physicalIndex);
      _emitSettledForCommand(commandId);
      return;
    }

    await _scrollController.animateTo(
      _pixelsForPhysicalIndex(physicalIndex),
      duration: duration ?? _programmaticScrollDuration,
      curve: curve ?? _programmaticScrollCurve,
    );

    if (!isCurrentMotionCommand(commandId)) return;
    _emitSettledForCommand(commandId);
  }

  void jumpToIndex(int index) {
    final logicalIndex = isInfinite ? index : _clampBounded(index);
    _setSelection(logicalIndex, physicalIndexForLogical(logicalIndex));
    recenterSelected();
  }

  void recenterSelected() {
    if (!_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      return;
    }
    _attachScrollingNotifier();
    _suppressScrollEvents = true;
    _scrollController.jumpTo(_pixelsForPhysicalIndex(_selectedPhysicalIndex));
    _suppressScrollEvents = false;
    _rawCenteredIndex = _selectedPhysicalIndex.toDouble();
  }

  /// Returns true when the physical belt was moved back to its anchor.
  bool rebaseIfNeeded() {
    if (!isInfinite ||
        _isScrolling ||
        _isRebasing ||
        !_scrollController.hasClients ||
        _itemExtent <= 0) {
      return false;
    }

    final physicalIndex = _rawCenteredIndex.round();
    final delta = physicalIndex - virtualAnchorIndex;
    if (delta.abs() < rebaseThresholdItems) return false;

    _isRebasing = true;
    _logicalOrigin += delta;
    _selectedPhysicalIndex = virtualAnchorIndex;
    _rawCenteredIndex = virtualAnchorIndex.toDouble();
    _suppressScrollEvents = true;
    _scrollController.jumpTo(_pixelsForPhysicalIndex(virtualAnchorIndex));
    _suppressScrollEvents = false;
    _isRebasing = false;
    notifyListeners();
    return true;
  }

  void setOnSelectedChanged(ValueChanged<int>? callback) {
    onSelectedChanged = callback;
  }

  void setCallbacks({
    ValueChanged<int>? onPreviewChanged,
    ValueChanged<int>? onSelectionSettled,
  }) {
    this.onPreviewChanged = onPreviewChanged;
    this.onSelectionSettled = onSelectionSettled;
  }

  void _attachScrollingNotifier() {
    if (!_scrollController.hasClients) return;
    final nextNotifier = _scrollController.position.isScrollingNotifier;
    if (_scrollingNotifier == nextNotifier) return;
    _scrollingNotifier?.removeListener(_handleScrollingChanged);
    _scrollingNotifier = nextNotifier;
    _scrollingNotifier!.addListener(_handleScrollingChanged);
  }

  void _handleScrollingChanged() {
    final isScrolling = _scrollingNotifier?.value ?? false;
    if (isScrolling) {
      _isScrolling = true;
      return;
    }
    if (!_isScrolling) return;
    _isScrolling = false;
    final commandId = _activeMotionCommandId;
    if (!isCurrentMotionCommand(commandId)) return;
    rebaseIfNeeded();
    _emitSettledForCommand(commandId);
  }

  /// Invalidates an in-flight programmatic motion when a new drag starts.
  void beginUserMotionCommand() {
    beginMotionCommand();
  }

  void _handleScroll() {
    if (_suppressScrollEvents ||
        !_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      return;
    }
    _attachScrollingNotifier();
    final position = _scrollController.position;
    _rawCenteredIndex =
        (_scrollController.offset - position.minScrollExtent) / _itemExtent;
    final nextPhysicalIndex = _rawCenteredIndex.round().clamp(
      0,
      _physicalItemCount - 1,
    );
    final nextLogicalIndex = logicalIndexForPhysical(nextPhysicalIndex);
    if (nextLogicalIndex != _selectedLogicalIndex) {
      _selectedPhysicalIndex = nextPhysicalIndex;
      _setSelection(nextLogicalIndex, nextPhysicalIndex);
    } else {
      _selectedPhysicalIndex = nextPhysicalIndex;
    }
    notifyListeners();
  }

  void _setSelection(int logicalIndex, int physicalIndex) {
    final changed = logicalIndex != _selectedLogicalIndex;
    _selectedLogicalIndex = logicalIndex;
    _selectedPhysicalIndex = physicalIndex;
    if (changed) _emitPreview(logicalIndex);
  }

  void _emitPreview(int logicalIndex) {
    _emitHapticIfNeeded(logicalIndex);
    onPreviewChanged?.call(logicalIndex);
    if (onSelectedChanged != null && onSelectedChanged != onPreviewChanged) {
      onSelectedChanged!.call(logicalIndex);
    }
  }

  void _emitHapticIfNeeded(int logicalIndex) {
    if (!_enableHaptics ||
        _isRebasing ||
        logicalIndex == _lastHapticLogicalIndex) {
      return;
    }
    final now = DateTime.now();
    if (_lastHapticAt != null &&
        now.difference(_lastHapticAt!) < _hapticThrottle) {
      return;
    }
    _lastHapticLogicalIndex = logicalIndex;
    _lastHapticAt = now;
    onHapticTick?.call();
    if (!kIsWeb) {
      HapticFeedback.selectionClick();
    }
  }

  void _emitSettledForCommand(int commandId) {
    if (!isCurrentMotionCommand(commandId) ||
        _lastSettledCommandId == commandId) {
      return;
    }
    _lastSettledCommandId = commandId;
    onSelectionSettled?.call(_selectedLogicalIndex);
  }

  int _physicalForLogical(int logicalIndex) =>
      physicalIndexForLogical(logicalIndex);

  int _clampBounded(int index) {
    if (_finiteLength <= 0) return 0;
    return index.clamp(0, _finiteLength - 1);
  }

  double _pixelsForPhysicalIndex(int physicalIndex) {
    final minScrollExtent = _scrollController.hasClients
        ? _scrollController.position.minScrollExtent
        : 0.0;
    return minScrollExtent + physicalIndex * _itemExtent;
  }

  @override
  void dispose() {
    _scrollingNotifier?.removeListener(_handleScrollingChanged);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
