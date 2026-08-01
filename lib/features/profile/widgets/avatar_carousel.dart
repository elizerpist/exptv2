import 'package:flutter/widgets.dart';

import '../../../shared/motion/centered_carousel/centered_carousel.dart';

/// Domain adapter proving that avatars use the same centered motion engine.
class AvatarCarousel<T> extends StatelessWidget {
  const AvatarCarousel({
    super.key,
    required this.avatars,
    required this.controller,
    required this.itemBuilder,
    this.itemExtent = 88,
    this.height,
    this.onSelectedChanged,
    this.semanticsLabelBuilder,
  });

  final List<T> avatars;
  final CenteredCarouselController controller;
  final Widget Function(
    BuildContext context,
    T avatar,
    CenteredCarouselItemMetrics metrics,
  )
  itemBuilder;
  final double itemExtent;
  final double? height;
  final ValueChanged<int>? onSelectedChanged;
  final String Function(T avatar)? semanticsLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return CenteredCarousel<T>(
      items: avatars,
      controller: controller,
      spec: CenteredCarouselPresets.avatars(itemExtent: itemExtent),
      height: height,
      onSelectedChanged: onSelectedChanged,
      semanticsLabelBuilder: semanticsLabelBuilder,
      itemBuilder: itemBuilder,
    );
  }
}
