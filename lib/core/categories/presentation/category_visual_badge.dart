import 'package:flutter/material.dart';

import '../catalog/category_visual_resolver.dart';
import 'category_icon_view.dart';

class CategoryVisualBadge extends StatelessWidget {
  const CategoryVisualBadge({
    required this.colorId,
    required this.iconId,
    this.size = 44,
    this.iconSize = 22,
    this.selected = false,
    super.key,
  });

  final String colorId;
  final String iconId;
  final double size;
  final double iconSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisualResolver.resolve(
      colorId: colorId,
      iconId: iconId,
    );
    final radius = BorderRadius.circular(size * 0.28);
    return Semantics(
      label: visual.icon.semanticName,
      selected: selected,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: visual.gradient.gradient,
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: CategoryIconView(
          iconId: visual.icon.id,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
