import 'category_color_catalog.dart';
import 'category_icon_catalog.dart';

class CategoryVisual {
  const CategoryVisual({required this.gradient, required this.icon});

  final CategoryGradientToken gradient;
  final CategoryIconToken icon;
}

abstract final class CategoryVisualResolver {
  static CategoryVisual resolve({
    required String colorId,
    required String iconId,
  }) {
    return CategoryVisual(
      gradient: CategoryColorCatalog.resolve(colorId),
      icon: CategoryIconCatalog.resolve(iconId),
    );
  }
}
