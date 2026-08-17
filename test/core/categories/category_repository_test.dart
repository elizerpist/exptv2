import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/data/method_channel_category_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'method channel repository keeps the backend ID contract intact',
    () async {
      const channel = MethodChannel('test/category_repository');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'getCategories':
            return <Map<String, Object?>>[
              <String, Object?>{
                'id': '01TEST',
                'name': 'Uncategorized',
                'colorId': 'color_01',
                'iconId': 'icon_01',
                'isSystemUncategorized': true,
                'createdAtUtcMs': 1,
                'updatedAtUtcMs': 1,
              },
            ];
          default:
            throw UnimplementedError(call.method);
        }
      });

      final repository = MethodChannelCategoryRepository(channel: channel);
      final categories = await repository.getCategories();

      expect(categories, hasLength(1));
      expect(categories.single.colorId, 'color_01');
      expect(categories.single.iconId, 'icon_01');

      messenger.setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'watchCategories emits exactly one initial native inventory snapshot',
    () async {
      const channel = MethodChannel('test/category_repository/watch');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var getCategoriesCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'getCategories') {
          throw UnimplementedError(call.method);
        }
        getCategoriesCalls += 1;
        return <Map<String, Object?>>[
          <String, Object?>{
            'id': '01TEST',
            'name': 'Uncategorized',
            'colorId': 'color_01',
            'iconId': 'icon_01',
            'isSystemUncategorized': true,
            'createdAtUtcMs': 1,
            'updatedAtUtcMs': 1,
          },
        ];
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final repository = MethodChannelCategoryRepository(channel: channel);
      final categories = await repository.watchCategories().first;

      expect(getCategoriesCalls, 1);
      expect(categories.single.id, '01TEST');
    },
  );
}
