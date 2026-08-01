import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'centered_carousel_spec.dart';

class CenteredCarouselController extends ChangeNotifier {
  CenteredCarouselController({required int initialIndex})
    : _selectedIndex = initialIndex < 0 ? 0 : initialIndex,
      _rawCenteredIndex = (initialIndex < 0 ? 0 : initialIndex).toDouble(),
      _scrollController = ScrollController() {
    _scrollController.addListener(_handleScroll);
  }

  final ScrollController _scrollController;
  int _itemCount = 0;
  double _itemExtent = 0;
  int _selectedIndex;
  double _rawCenteredIndex;
  bool _enableHaptics = false;
  Duration _programmaticScrollDuration =
      CenteredCarouselSpec.defaultProgrammaticScrollDuration;
  Curve _programmaticScrollCurve =
      CenteredCarouselSpec.defaultProgrammaticScrollCurve;
  ValueChanged<int>? onSelectedChanged;

  int get selectedIndex => _selectedIndex;
  double get rawCenteredIndex => _rawCenteredIndex;
  ScrollController get scrollController => _scrollController;

  void updateConfiguration({
    required int itemCount,
    required double itemExtent,
    bool enableHaptics = false,
    Duration? programmaticScrollDuration,
    Curve? programmaticScrollCurve,
  }) {
    _itemCount = itemCount < 0 ? 0 : itemCount;
    _itemExtent = itemExtent;
    _enableHaptics = enableHaptics;
    _programmaticScrollDuration =
        programmaticScrollDuration ?? _programmaticScrollDuration;
    _programmaticScrollCurve =
        programmaticScrollCurve ?? _programmaticScrollCurve;

    final nextIndex = _clampIndex(_selectedIndex);
    final changed = nextIndex != _selectedIndex;
    _selectedIndex = nextIndex;
    _rawCenteredIndex = nextIndex.toDouble();

    if (_scrollController.hasClients && _itemCount > 0 && _itemExtent > 0) {
      final target = _pixelsForIndex(nextIndex);
      if ((_scrollController.offset - target).abs() > .01) {
        _scrollController.jumpTo(target);
      }
    }

    if (changed) {
      _emitSelection(nextIndex);
    }
    notifyListeners();
  }

  Future<void> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    final nextIndex = _clampIndex(index);
    if (!_scrollController.hasClients || _itemExtent <= 0 || _itemCount <= 0) {
      jumpToIndex(nextIndex);
      return;
    }

    await _scrollController.animateTo(
      _pixelsForIndex(nextIndex),
      duration: duration ?? _programmaticScrollDuration,
      curve: curve ?? _programmaticScrollCurve,
    );
  }

  void jumpToIndex(int index) {
    final nextIndex = _clampIndex(index);
    final changed = nextIndex != _selectedIndex;
    _selectedIndex = nextIndex;
    _rawCenteredIndex = nextIndex.toDouble();

    if (_scrollController.hasClients && _itemCount > 0 && _itemExtent > 0) {
      _scrollController.jumpTo(_pixelsForIndex(nextIndex));
    }

    if (changed) {
      _emitSelection(nextIndex);
    }
    notifyListeners();
  }

  void setOnSelectedChanged(ValueChanged<int>? callback) {
    onSelectedChanged = callback;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _itemExtent <= 0 || _itemCount <= 0) {
      return;
    }

    final position = _scrollController.position;
    _rawCenteredIndex =
        (_scrollController.offset - position.minScrollExtent) / _itemExtent;
    final nextSelectedIndex = _clampIndex(_rawCenteredIndex.round());

    if (nextSelectedIndex != _selectedIndex) {
      _selectedIndex = nextSelectedIndex;
      _emitSelection(nextSelectedIndex);
    }
    notifyListeners();
  }

  int _clampIndex(int index) {
    if (_itemCount <= 0) return 0;
    return index.clamp(0, _itemCount - 1);
  }

  double _pixelsForIndex(int index) {
    final minScrollExtent = _scrollController.hasClients
        ? _scrollController.position.minScrollExtent
        : 0.0;
    return minScrollExtent + index * _itemExtent;
  }

  void _emitSelection(int index) {
    if (_enableHaptics) {
      HapticFeedback.selectionClick();
    }
    onSelectedChanged?.call(index);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
