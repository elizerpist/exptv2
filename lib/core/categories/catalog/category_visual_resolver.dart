import 'category_color_catalog.dart';
import 'category_icon_catalog.dart';
import '../presentation/category_avatar_palette_catalog.dart';
import '../../design/fluvi_global_appearance.dart';

class CategoryVisual {
  const CategoryVisual({required this.gradient, required this.icon});

  final CategoryGradientToken gradient;
  final CategoryIconToken icon;
}

abstract final class CategoryVisualResolver {
  static CategoryVisual resolve({
    required String colorId,
    required String iconId,
    CategoryAvatarColorProfile profile = CategoryAvatarColorProfile.original,
  }) {
    return CategoryVisual(
      gradient: CategoryAvatarPaletteCatalog.tokenFor(
        profile,
        CategoryColorCatalog.handleOf(colorId),
      ),
      icon: CategoryIconCatalog.resolve(iconId),
    );
  }
}
