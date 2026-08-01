import 'package:flutter/foundation.dart';

@immutable
class CenteredCarouselItemMetrics {
  const CenteredCarouselItemMetrics({
    required this.index,
    required this.selectedIndex,
    required this.rawCenteredIndex,
    required this.signedDistanceItems,
    required this.absoluteDistanceItems,
    required this.proximity,
    required this.scale,
    required this.opacity,
    required this.isSelected,
  });

  final int index;
  final int selectedIndex;
  final double rawCenteredIndex;
  final double signedDistanceItems;
  final double absoluteDistanceItems;
  final double proximity;
  final double scale;
  final double opacity;
  final bool isSelected;
}
