import 'package:flutter/foundation.dart';

/// Headless owner of the time rail's visibility only.
class DashboardRailController extends ChangeNotifier {
  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;

  void toggle() => setExpanded(!_isExpanded);

  void setExpanded(bool value) {
    if (value == _isExpanded) return;
    _isExpanded = value;
    notifyListeners();
  }
}
