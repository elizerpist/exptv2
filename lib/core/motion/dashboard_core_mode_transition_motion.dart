import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../design/dashboard_mode_palette.dart';

/// One central policy for the bounded core-mode transition.
abstract final class DashboardCoreModeTransitionPolicy {
  static const commitProgress = .35;
  static const settleDuration = DashboardMotionTokens.collapseDuration;
  static const settleCurve = DashboardMotionTokens.transitionCurve;

  static bool commitsAt(double progress) => progress >= commitProgress;
}

/// Ticker-backed visual progress owned and disposed by [DashboardMotionHost].
///
/// The semantic mode controller intentionally does not know about this object.
final class DashboardCoreModeTransitionMotion extends ChangeNotifier
    implements ValueListenable<double> {
  DashboardCoreModeTransitionMotion({required TickerProvider vsync})
    : _controller = AnimationController.unbounded(vsync: vsync) {
    _controller.addListener(notifyListeners);
  }

  final AnimationController _controller;

  @override
  double get value => _controller.value.clamp(0.0, 1.0).toDouble();

  void setDragProgress(double progress) {
    _controller
      ..stop()
      ..value = progress.clamp(0.0, 1.0).toDouble();
  }

  Future<void> settleTo(double target) => _controller.animateTo(
    target.clamp(0.0, 1.0).toDouble(),
    duration: DashboardCoreModeTransitionPolicy.settleDuration,
    curve: DashboardCoreModeTransitionPolicy.settleCurve,
  );

  @override
  void dispose() {
    _controller
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
