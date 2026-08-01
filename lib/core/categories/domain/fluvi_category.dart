import '../catalog/category_catalog.dart';

class FluviCategory {
  const FluviCategory({
    required this.id,
    required this.name,
    required this.colorId,
    required this.iconId,
    required this.isSystemUncategorized,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
  });

  final String id;
  final String name;
  final String colorId;
  final String iconId;
  final bool isSystemUncategorized;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;

  CategoryVisual get visual =>
      CategoryVisualResolver.resolve(colorId: colorId, iconId: iconId);

  factory FluviCategory.fromMap(Map<Object?, Object?> map) {
    return FluviCategory(
      id: _requiredString(map, 'id'),
      name: _requiredString(map, 'name'),
      colorId: _requiredString(map, 'colorId'),
      iconId: _requiredString(map, 'iconId'),
      isSystemUncategorized: map['isSystemUncategorized'] == true,
      createdAtUtcMs: _requiredInt(map, 'createdAtUtcMs'),
      updatedAtUtcMs: _requiredInt(map, 'updatedAtUtcMs'),
    );
  }
}

String _requiredString(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Category field "$key" is missing or invalid.');
}

int _requiredInt(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Category field "$key" is missing or invalid.');
}
