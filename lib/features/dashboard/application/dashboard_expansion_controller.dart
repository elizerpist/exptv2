import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';

enum DashboardExpansionTarget { expanded, collapsed }

/// Headless owner of the dashboard's two-endpoint collapse interaction.
class DashboardExpansionController extends ChangeNotifier {
  DashboardExpansionController({
    this.metrics = DashboardLayoutMetrics.reference,
  });

  /// The geometry source that defines this interaction's endpoints.
  final DashboardLayoutMetrics metrics;

  double get collapseTravel => metrics.collapseTravel;
  double get snapThreshold => collapseTravel / 2;

  double _progress = 0;
  bool _isDragging = false;

  double get progress => _progress;
  bool get isDragging => _isDragging;

  DashboardExpansionTarget get toggleTarget => _progress <= snapThreshold
      ? DashboardExpansionTarget.collapsed
      : DashboardExpansionTarget.expanded;

  void beginDrag() {
    if (_isDragging) return;
    _isDragging = true;
    notifyListeners();
  }

  /// Negative vertical movement collapses; positive movement expands.
  void dragBy(double verticalDelta) {
    setProgress(_progress - verticalDelta);
  }

  DashboardExpansionTarget endDrag() {
    final target = _progress > snapThreshold
        ? DashboardExpansionTarget.collapsed
        : DashboardExpansionTarget.expanded;
    _isDragging = false;
    _setProgress(_progressFor(target), notify: false);
    notifyListeners();
    return target;
  }

  void cancelDrag() {
    final target = _progress > snapThreshold
        ? DashboardExpansionTarget.collapsed
        : DashboardExpansionTarget.expanded;
    _isDragging = false;
    _setProgress(_progressFor(target), notify: false);
    notifyListeners();
  }

  void setProgress(double value) => _setProgress(value, notify: true);

  void toggle() => setProgress(_progressFor(toggleTarget));

  void _setProgress(double value, {required bool notify}) {
    final next = value.clamp(0.0, collapseTravel).toDouble();
    if (next == _progress) return;
    _progress = next;
    if (notify) notifyListeners();
  }

  double _progressFor(DashboardExpansionTarget target) {
    return switch (target) {
      DashboardExpansionTarget.expanded => 0,
      DashboardExpansionTarget.collapsed => collapseTravel,
    };
  }
}
