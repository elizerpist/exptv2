import 'package:flutter/foundation.dart';

import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';

/// Owns dashboard rail visibility and the rail's reusable carousel controller.
class DashboardRailController extends ChangeNotifier {
  DashboardRailController()
    : timeCarousel = CenteredCarouselController(initialIndex: 0);

  /// The time rail's generated year source is centered on its reference year;
  /// the shared controller owns the physical virtual belt and logical index.
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
