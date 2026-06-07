import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default magnet strip height is doubled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MagnetStrip(
            type: MagnetType.fade,
            totalIncome: 70,
            totalExpense: 30,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('magnet-strip-fade'))).height,
      MagnetStrip.defaultHeight,
    );
  });

  testWidgets('magnetcard renders marker mode without gradient fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MagnetStrip(
            type: MagnetType.magnetcard,
            totalIncome: 70,
            totalExpense: 30,
            height: 35,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('magnet-strip-magnetcard')),
      findsOneWidget,
    );
  });

  testWidgets('adaptive magnet exposes dynamic pill width key', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: MagnetStrip(
              type: MagnetType.adaptive,
              totalIncome: 80,
              totalExpense: 20,
              height: 35,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('magnet-strip-adaptive')), findsOneWidget);
  });

  test('magnet strip uses app income expense ratio math', () {
    expect(MagnetStripPainter.incomeRatio(80, -20), 0.8);
    expect(MagnetStripPainter.incomeRatio(0, -20), 0.05);
    expect(MagnetStripPainter.incomeRatio(20, 0), 0.95);
  });

  test('magnet strip fade uses income and expense colors', () {
    expect(
      MagnetStripPainter.gradientColorsFor(MagnetType.fade),
      [AppColors.income, AppColors.expense],
    );
    expect(
      MagnetStripPainter.gradientColorsFor(MagnetType.nofade),
      [AppColors.income, AppColors.income, AppColors.expense, AppColors.expense],
    );
  });
}
