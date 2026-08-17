import '../domain/category_repository.dart';
import '../domain/fluvi_category.dart';

/// No-op category source for platforms without the native category bridge.
final class EmptyCategoryRepository implements CategoryRepository {
  const EmptyCategoryRepository();

  @override
  Stream<List<FluviCategory>> watchCategories() =>
      Stream<List<FluviCategory>>.value(const <FluviCategory>[]);

  @override
  Future<List<FluviCategory>> getCategories() async => const <FluviCategory>[];

  @override
  Future<FluviCategory?> getCategoryById(String id) async => null;

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) => Future<FluviCategory>.error(
    UnsupportedError('Categories are unavailable on this platform.'),
  );

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) => Future<FluviCategory>.error(
    UnsupportedError('Categories are unavailable on this platform.'),
  );

  @override
  Future<void> deleteCategory(String id) => Future<void>.error(
    UnsupportedError('Categories are unavailable on this platform.'),
  );
}
