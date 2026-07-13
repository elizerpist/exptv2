import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/slots/category_color_manager.dart';
import 'package:exptv2/features/transactions/slots/category_color_resolver.dart';
import 'package:exptv2/features/transactions/slots/category_icon_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoryIconManager.resetForTests();
  });

  tearDown(CategoryIconManager.resetForTests);

  test('category color manager exposes the spendee gradient slot colors', () {
    expect(CategoryColorManager.hexes, {
      0: '#ff5268',
      1: '#ff7043',
      2: '#ffa12b',
      3: '#ffc233',
      4: '#f7ea45',
      5: '#b7ea2a',
      6: '#5bd265',
      7: '#24c889',
      8: '#12b980',
      9: '#19c0aa',
      10: '#1bb7d2',
      11: '#2bc4f3',
      12: '#3b9df5',
      13: '#496deb',
      14: '#5a55df',
      15: '#7546dc',
      16: '#8b45ed',
      17: '#a94ee6',
      18: '#b84ce0',
      19: '#d932c9',
      20: '#f04ab6',
    });
    expect(CategoryColorManager.color(6).toARGB32(), 0xff5bd265);
    expect(CategoryColorManager.hex(99), '#64748b');
  });

  test(
    'category icon manager exposes local lucide bank and mutable slots',
    () async {
      final preferences = await SharedPreferences.getInstance();

      expect(
        CategoryIconManager.slots,
        List<int>.generate(21, (index) => index),
      );
      expect(CategoryIconManager.iconOptions, hasLength(60));
      expect(CategoryIconManager.iconOptions.first.name, 'shirt');
      expect(CategoryIconManager.assetPath(0), 'assets/icons/lucide/shirt.svg');
      expect(
        CategoryIconManager.assetPath(20),
        'assets/icons/lucide/drama.svg',
      );
      expect(
        CategoryIconManager.assetPath(99),
        CategoryIconManager.assetPath(0),
      );

      await CategoryIconManager.assignIconToSlot(
        4,
        'pizza',
        preferences: preferences,
      );
      expect(CategoryIconManager.iconNameForSlot(4), 'pizza');
      expect(CategoryIconManager.assetPath(4), 'assets/icons/lucide/pizza.svg');

      CategoryIconManager.resetForTests();
      await CategoryIconManager.load(preferences: preferences);
      expect(CategoryIconManager.iconNameForSlot(4), 'pizza');
    },
  );

  test('category icon manager logs preference load timing', () async {
    final preferences = await SharedPreferences.getInstance();
    await CategoryIconManager.assignIconToSlot(
      4,
      'pizza',
      preferences: preferences,
    );
    CategoryIconManager.resetForTests();
    DebugConsole.clear();

    await CategoryIconManager.load(preferences: preferences);

    expect(DebugConsole.allText, contains('[IconLoad] prefs load start'));
    expect(DebugConsole.allText, contains('[IconLoad] prefs load end'));
    expect(DebugConsole.allText, contains('assignments='));
    expect(DebugConsole.allText, contains('elapsed='));
  });

  test('transaction category reads slot colors through the manager', () {
    final category = TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 9,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });

    expect(category.slotColorHex, CategoryColorManager.hex(9));
    expect(
      category.slotColor.toARGB32(),
      CategoryColorManager.color(9).toARGB32(),
    );
  });
  test('category color resolver prefers live category slot over snapshots', () {
    final category = TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 9,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });

    expect(
      CategoryColorResolver.color(
        category: category,
        snapshotHex: '#dc2626',
      ).toARGB32(),
      CategoryColorManager.color(9).toARGB32(),
    );
    expect(CategoryColorResolver.findById([category], 6), same(category));
  });
}
