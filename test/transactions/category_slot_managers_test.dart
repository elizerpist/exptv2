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

  test('category color manager exposes the expt0926 slot colors', () {
    expect(CategoryColorManager.hexes, {
      0: '#ef4444',
      1: '#f97316',
      2: '#eab308',
      3: '#84cc16',
      4: '#22c55e',
      5: '#10b981',
      6: '#06b6d4',
      7: '#0ea5e9',
      8: '#3b82f6',
      9: '#6366f1',
      10: '#8b5cf6',
      11: '#a855f7',
      12: '#d946ef',
      13: '#ec4899',
      14: '#f43f5e',
      15: '#6b7280',
      16: '#374151',
      17: '#1f2937',
      18: '#064e3b',
      19: '#7c2d12',
      20: '#4c1d95',
    });
    expect(CategoryColorManager.color(6).toARGB32(), 0xff06b6d4);
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
    expect(category.slotColor.toARGB32(), 0xff6366f1);
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
      0xff6366f1,
    );
    expect(CategoryColorResolver.findById([category], 6), same(category));
  });
}
