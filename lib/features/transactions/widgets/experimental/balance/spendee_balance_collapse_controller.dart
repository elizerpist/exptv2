import 'package:flutter/foundation.dart';

enum SpendeeBalanceCollapseState { expanded, collapsing, collapsed }

enum SpendeeBalanceCollapseTarget { expanded, collapsed }

/// Headless controller for the frozen B3M-A3 two-endpoint collapse path.
///
/// Pointer movement follows the 180 logical-pixel HTML scroll path directly.
/// Animation is deliberately owned by the host widget so reduced-motion and
/// vsync lifetime stay presentation concerns.
class SpendeeBalanceCollapseController extends ChangeNotifier {
  static const maxOffset = 180.0;
  static const snapOffset = maxOffset / 2;

  double _offset = 0;
  var _dragging = false;

  double get offset => _offset;
  double get progress => _offset / maxOffset;
  bool get dragging => _dragging;

  SpendeeBalanceCollapseState get state {
    if (_offset <= 0) return SpendeeBalanceCollapseState.expanded;
    if (_offset >= maxOffset) return SpendeeBalanceCollapseState.collapsed;
    return SpendeeBalanceCollapseState.collapsing;
  }

  SpendeeBalanceCollapseTarget get toggleTarget => _offset < snapOffset
      ? SpendeeBalanceCollapseTarget.collapsed
      : SpendeeBalanceCollapseTarget.expanded;

  void beginDrag() {
    if (_dragging) return;
    _dragging = true;
    notifyListeners();
  }

  /// Positive pointer dy expands and negative pointer dy collapses.
  void dragBy(double dy) {
    final next = (_offset - dy).clamp(0.0, maxOffset).toDouble();
    if (next == _offset) return;
    _offset = next;
    notifyListeners();
  }

  SpendeeBalanceCollapseTarget release() {
    final target = _offset >= snapOffset
        ? SpendeeBalanceCollapseTarget.collapsed
        : SpendeeBalanceCollapseTarget.expanded;
    _dragging = false;
    jumpTo(target.offset);
    return target;
  }

  void cancelDrag() {
    _dragging = false;
    jumpTo(toggleTarget == SpendeeBalanceCollapseTarget.collapsed ? 0 : 180);
  }

  void jumpTo(double value) {
    final next = value.clamp(0.0, maxOffset).toDouble();
    if (next == _offset) {
      if (_dragging) {
        _dragging = false;
        notifyListeners();
      }
      return;
    }
    _offset = next;
    notifyListeners();
  }
}

extension on SpendeeBalanceCollapseTarget {
  double get offset => switch (this) {
    SpendeeBalanceCollapseTarget.expanded => 0,
    SpendeeBalanceCollapseTarget.collapsed =>
      SpendeeBalanceCollapseController.maxOffset,
  };
}

/// Final computed visual values from `attachTodayRedesignScrollInteraction`.
@immutable
class SpendeeBalanceCollapseVisuals {
  const SpendeeBalanceCollapseVisuals._({
    required this.progress,
    required this.heroHeight,
    required this.insightOpacity,
    required this.insightScale,
    required this.insightTranslateY,
    required this.detailOpacity,
    required this.detailScale,
    required this.detailTranslateY,
    required this.heroStatsOpacity,
    required this.heroStatsTranslateY,
    required this.scrollContentTranslateY,
    required this.postTranslateY,
    required this.insightsInteractive,
    required this.detailsInteractive,
  });

  factory SpendeeBalanceCollapseVisuals.forOffset(double offset) {
    return SpendeeBalanceCollapseVisuals.forProgress(
      offset / SpendeeBalanceCollapseController.maxOffset,
    );
  }

  factory SpendeeBalanceCollapseVisuals.forProgress(double value) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    final insightProgress = _unit((progress - .03) / .62);
    final detailProgress = _unit((progress - .16) / .62);
    final heroStatsOpacity = 1 - _unit((progress - .08) / .52);
    final scrollTop = progress * SpendeeBalanceCollapseController.maxOffset;

    // Exit-mode B3M-A3 has two pre-post stack gaps and no compact budget pill.
    // The HTML multiplies the changing disappearing-stack shift by the detail
    // progress rather than applying a simple linear endpoint tween.
    const insightHeight = 104.0;
    const detailHeight = 186.0;
    const stackGap = 11.0;
    const stackGapCount = 2;
    const heroGap = 11.0;
    const disappearingPillActionGap = heroGap;
    final postBudgetShift =
        -((insightHeight + stackGap * stackGapCount + detailHeight) -
            scrollTop +
            heroGap -
            disappearingPillActionGap);

    return SpendeeBalanceCollapseVisuals._(
      progress: progress,
      heroHeight: 126 - 22 * progress,
      insightOpacity: 1 - insightProgress,
      insightScale: 1 - .1 * insightProgress,
      insightTranslateY: -18 * insightProgress,
      detailOpacity: 1 - detailProgress,
      detailScale: 1 - .04 * detailProgress,
      detailTranslateY: -24 * detailProgress,
      heroStatsOpacity: heroStatsOpacity,
      heroStatsTranslateY: 10 * (1 - heroStatsOpacity),
      // The frozen DOM first scrolls the content viewport by 180px, while the
      // shrinking 126→104px hero moves the content flow another 22px upward.
      // Element-specific CSS transforms remain separate below.
      scrollContentTranslateY: -(scrollTop + 22 * progress),
      postTranslateY: postBudgetShift * detailProgress,
      insightsInteractive: insightProgress <= .96,
      detailsInteractive: detailProgress <= .96,
    );
  }

  final double progress;
  final double heroHeight;
  final double insightOpacity;
  final double insightScale;
  final double insightTranslateY;
  final double detailOpacity;
  final double detailScale;
  final double detailTranslateY;
  final double heroStatsOpacity;
  final double heroStatsTranslateY;
  final double scrollContentTranslateY;
  final double postTranslateY;
  final bool insightsInteractive;
  final bool detailsInteractive;

  static double _unit(double value) => value.clamp(0.0, 1.0).toDouble();
}
