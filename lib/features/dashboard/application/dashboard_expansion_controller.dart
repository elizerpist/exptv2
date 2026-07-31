import 'package:flutter/foundation.dart';

enum DashboardExpansionTarget { expanded, collapsed }

/// Headless owner of the dashboard's two-endpoint collapse interaction.
class DashboardExpansionController extends ChangeNotifier {
  static const collapseTravel = 180.0;
  static const snapThreshold = 90.0;

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

  static double _progressFor(DashboardExpansionTarget target) {
    return switch (target) {
      DashboardExpansionTarget.expanded => 0,
      DashboardExpansionTarget.collapsed => collapseTravel,
    };
  }
}
