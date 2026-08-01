import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/category_repository.dart';
import '../domain/fluvi_category.dart';

class MethodChannelCategoryRepository implements CategoryRepository {
  MethodChannelCategoryRepository({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.fluvi/category_repository');

  final MethodChannel _channel;
  final StreamController<List<FluviCategory>> _changes =
      StreamController<List<FluviCategory>>.broadcast();

  @override
  Stream<List<FluviCategory>> watchCategories() async* {
    yield await getCategories();
    yield* _changes.stream;
  }

  @override
  Future<List<FluviCategory>> getCategories() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getCategories');
    return _decodeList(raw);
  }

  @override
  Future<FluviCategory?> getCategoryById(String id) async {
    final raw = await _channel.invokeMethod<Object?>(
      'getCategoryById',
      <String, Object?>{'id': id},
    );
    if (raw == null) return null;
    return FluviCategory.fromMap(_asMap(raw));
  }

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) async {
    final raw = await _channel.invokeMethod<Object?>(
      'createCategory',
      <String, Object?>{'name': name, 'colorId': colorId, 'iconId': iconId},
    );
    return _publishSingle(raw);
  }

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) async {
    final raw = await _channel.invokeMethod<Object?>(
      'updateCategory',
      <String, Object?>{
        'id': id,
        'name': name,
        'colorId': colorId,
        'iconId': iconId,
      },
    );
    return _publishSingle(raw);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _channel.invokeMethod<void>('deleteCategory', <String, Object?>{
      'id': id,
    });
    _publish(await getCategories());
  }

  Future<FluviCategory> _publishSingle(Object? raw) async {
    final category = FluviCategory.fromMap(_asMap(raw));
    _publish(await getCategories());
    return category;
  }

  void _publish(List<FluviCategory> categories) {
    if (!_changes.isClosed) _changes.add(categories);
  }

  static List<FluviCategory> _decodeList(List<Object?>? raw) {
    if (raw == null) return const <FluviCategory>[];
    return raw
        .map((value) => FluviCategory.fromMap(_asMap(value)))
        .toList(growable: false);
  }

  static Map<Object?, Object?> _asMap(Object? raw) {
    if (raw is Map<Object?, Object?>) return raw;
    if (raw is Map) return Map<Object?, Object?>.from(raw);
    throw FormatException('Invalid category bridge payload.');
  }
}
