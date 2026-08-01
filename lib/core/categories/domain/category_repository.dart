import 'fluvi_category.dart';

abstract interface class CategoryRepository {
  Stream<List<FluviCategory>> watchCategories();

  Future<List<FluviCategory>> getCategories();

  Future<FluviCategory?> getCategoryById(String id);

  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  });

  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  });

  Future<void> deleteCategory(String id);
}
