import 'package:flutter/material.dart';

import '../../assets/prepared_vector_asset_atlas.dart';
import '../catalog/category_icon_catalog.dart';
import 'category_icon_view.dart';

class CategoryVisualBadge extends StatelessWidget {
  const CategoryVisualBadge({
    required this.colorHandle,
    required this.iconHandle,
    this.size = 44,
    this.iconSize = 22,
    this.selected = false,
    super.key,
  });

  final int colorHandle;
  final int iconHandle;
  final double size;
  final double iconSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final atlas = PreparedVectorAssetAtlas.instance;
    final picture = atlas.categoryIcon(iconHandle);
    final gradient = atlas.categoryGradient(colorHandle);
    final semanticName = CategoryIconCatalog.tokenForHandle(
      iconHandle,
    ).semanticName;
    final radius = BorderRadius.circular(size * 0.28);
    return Semantics(
      label: semanticName,
      selected: selected,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
        alignment: Alignment.center,
        child: CategoryIconView(
          picture: picture,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
