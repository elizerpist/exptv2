import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(412, 892)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 378, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('expanded hero renders exact B3M-A3 content and geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SpendeeBalanceHeader(
          balanceText: '-372 047 472 Ft',
          reservePercent: 42,
          incomeRatio: 32,
          expenseRatio: 68,
          collapseProgress: 0,
        ),
      ),
    );

    final hero = find.byKey(const ValueKey('spendee-balance-hero'));
    expect(hero, findsOneWidget);
    expect(tester.getSize(hero), const Size(378, 126));
    expect(find.text('Egyenleg'), findsOneWidget);
    expect(find.text('-372 047 472 Ft'), findsOneWidget);
    expect(find.text('TARTALÉK'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('BALANCE ARÁNY'), findsOneWidget);
    expect(find.text('32%'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('BEVÉTEL'), findsOneWidget);
    expect(find.text('KIADÁS'), findsOneWidget);

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('spendee-balance-hero-decoration')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(24));
    expect(decoration.border, isNotNull);
    expect(decoration.gradient, isNotNull);
    expect(decoration.boxShadow, hasLength(3));
    expect(decoration.boxShadow!.last.blurStyle, BlurStyle.inner);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('spendee-balance-reserve-meter')),
      ),
      const Size(96, 5),
    );
    final meter =
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('spendee-balance-reserve-meter')),
                )
                .decoration
            as BoxDecoration;
    expect(meter.boxShadow, hasLength(1));
    expect(meter.boxShadow!.single.blurStyle, BlurStyle.inner);
  });

  testWidgets('hero stat tracks match the frozen 1.08fr 1px .92fr grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SpendeeBalanceHeader(
          balanceText: '-372 047 472 Ft',
          reservePercent: 42,
          incomeRatio: 32,
          expenseRatio: 68,
          collapseProgress: 0,
        ),
      ),
    );

    final heroRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-hero')),
    );
    final gridRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-hero-stat-grid')),
    );
    final reserveRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-reserve-stat-track')),
    );
    final dividerRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-hero-divider-track')),
    );
    final dividerMarginRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-hero-divider-margin-box')),
    );
    final dividerLineRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-hero-divider')),
    );
    final ratioRect = tester.getRect(
      find.byKey(const ValueKey('spendee-balance-ratio-stat-track')),
    );

    expect(gridRect.left, heroRect.left + 20);
    expect(gridRect.right, heroRect.right - 20);
    expect(gridRect.width, 338);

    const dividerWidth = 1.0;
    final fractionWidth = gridRect.width - dividerWidth;
    final expectedReserveWidth = fractionWidth * 1.08 / (1.08 + .92);
    final expectedRatioWidth = fractionWidth * .92 / (1.08 + .92);

    expect(reserveRect.left, gridRect.left);
    expect(reserveRect.width, closeTo(expectedReserveWidth, .001));
    expect(dividerRect.left, closeTo(reserveRect.right, .001));
    expect(dividerRect.width, dividerWidth);
    expect(dividerMarginRect.left, closeTo(dividerRect.left - 14, .001));
    expect(dividerMarginRect.right, closeTo(dividerRect.right + 14, .001));
    expect(dividerMarginRect.width, 29);
    expect(dividerLineRect, dividerRect);
    expect(ratioRect.left, closeTo(dividerRect.right, .001));
    expect(ratioRect.width, closeTo(expectedRatioWidth, .001));
    expect(ratioRect.right, gridRect.right);
  });

  testWidgets('collapsed hero follows the exact 126 to 104 tween', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SpendeeBalanceHeader(
          balanceText: '-372 047 472 Ft',
          reservePercent: 42,
          incomeRatio: 32,
          expenseRatio: 68,
          collapseProgress: 1,
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('spendee-balance-hero'))),
      const Size(378, 104),
    );
    final statOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('spendee-balance-hero-stats-opacity')),
    );
    expect(statOpacity.opacity, 0);
  });

  testWidgets('surface wrapper cannot change measured hero geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceHeader(
          balanceText: '-1 000 Ft',
          reservePercent: 20,
          incomeRatio: 40,
          expenseRatio: 60,
          collapseProgress: .5,
          surfaceBuilder: (context, radius, child) {
            return ClipRRect(
              key: const ValueKey('test-header-surface'),
              borderRadius: radius,
              child: ColoredBox(color: Colors.white24, child: child),
            );
          },
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('spendee-balance-hero'))),
      const Size(378, 115),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('test-header-surface'))),
      const Size(378, 115),
    );
  });
}
