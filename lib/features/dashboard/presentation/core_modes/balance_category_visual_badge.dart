import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';

/// Reuses the canonical category visual when the prepared vector atlas is
/// available, while retaining the same rounded-square identity during early
/// presentation tests and bootstrap.
class BalanceCategoryVisualBadge extends StatelessWidget {
  const BalanceCategoryVisualBadge({
    super.key,
    required this.semanticLabel,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.size,
    required this.iconSize,
    this.selected = false,
  });

  final String semanticLabel;
  final String categoryColorId;
  final String categoryIconId;
  final double size;
  final double iconSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final atlas = PreparedVectorAssetAtlas.instance;
    if (atlas.isReady) {
      return CategoryVisualBadge(
        colorHandle: CategoryColorCatalog.handleOf(categoryColorId),
        iconHandle: CategoryIconCatalog.handleOf(categoryIconId),
        size: size,
        iconSize: iconSize,
        selected: selected,
      );
    }
    final colorHandle = CategoryColorCatalog.handleOf(categoryColorId);
    return Semantics(
      label: semanticLabel,
      selected: selected,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: CategoryAvatarPaletteCatalog.gradientFor(
            CategoryAvatarColorProfileScope.profileOf(context),
            colorHandle,
          ),
          borderRadius: BorderRadius.circular(size * .28),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.category_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
