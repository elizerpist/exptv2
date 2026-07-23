import 'package:exptv2/exptv2_app.dart';
import 'package:exptv2/features/transactions/slots/category_icon_manager.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup cache includes the Spendee context icon stroke', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    CategoryIconManager.resetForTests();
    resetCategorySlotIconCacheForTests();

    await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      await bootstrapCategoryIconsForStartup(preferences: preferences);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: CategorySlotIcon(
          slot: 0,
          color: Colors.white,
          size: 28,
          strokeWidth: 1.4,
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
