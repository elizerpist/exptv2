import 'package:flutter/foundation.dart';

import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';

/// Owns dashboard rail visibility and the rail's reusable carousel controller.
class DashboardRailController extends ChangeNotifier {
  DashboardRailController()
    : timeCarousel = CenteredCarouselController(initialIndex: 23);

  /// The time rail is an effectively infinite repeated sequence. The shared
  /// engine remains finite and bounds-safe; the adapter supplies 41 values.
  final CenteredCarouselController timeCarousel;

  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;

  void toggle() => setExpanded(!_isExpanded);

  void setExpanded(bool value) {
    if (value == _isExpanded) return;
    _isExpanded = value;
    notifyListeners();
  }

  @override
  void dispose() {
    timeCarousel.dispose();
    super.dispose();
  }
}
