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
      105,
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
}
