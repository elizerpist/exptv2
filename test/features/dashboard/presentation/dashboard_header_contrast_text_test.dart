import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_contrast_text.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_budget_header_presentation.dart';

void main() {
  testWidgets('outline adds one excluded paint copy and one semantic label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardHeaderContrastText(
            data: 'Napi tempó',
            style: TextStyle(fontSize: 12),
            foreground: Colors.white,
            contrastStyle: DashboardHeaderTextContrastStyle.oppositeOutline,
          ),
        ),
      ),
    );

    expect(find.text('Napi tempó'), findsNWidgets(2));
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Napi tempó'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('hard shadow keeps one text layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardHeaderContrastText(
            data: 'Havi állás',
            style: TextStyle(fontSize: 12),
            foreground: Colors.black,
            contrastStyle: DashboardHeaderTextContrastStyle.hardOppositeShadow,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Havi állás'));
    expect(
      text.style!.shadows!.single.color,
      Colors.white.withValues(alpha: .88),
    );
    expect(text.style!.shadows!.single.blurRadius, 0);
  });

  testWidgets('both foregrounds receive the exact hard opposite shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const <Widget>[
              DashboardHeaderContrastText(
                data: 'fehér',
                style: TextStyle(fontSize: 12),
                foreground: Colors.white,
                contrastStyle:
                    DashboardHeaderTextContrastStyle.hardOppositeShadow,
              ),
              DashboardHeaderContrastText(
                data: 'fekete',
                style: TextStyle(fontSize: 12),
                foreground: Colors.black,
                contrastStyle:
                    DashboardHeaderTextContrastStyle.hardOppositeShadow,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('fehér')).style!.shadows!.single.color,
      Colors.black.withValues(alpha: .88),
    );
    expect(
      tester.widget<Text>(find.text('fekete')).style!.shadows!.single.color,
      Colors.white.withValues(alpha: .88),
    );
  });

  testWidgets('contrast styles keep the semantic fill geometry unchanged', (
    tester,
  ) async {
    Widget host(DashboardHeaderTextContrastStyle contrast) => MaterialApp(
      home: Scaffold(
        body: DashboardHeaderContrastText(
          key: const ValueKey<String>('contrast-geometry'),
          data: '74 685 Ft / 102 784 Ft',
          style: const TextStyle(fontSize: 14, height: 1),
          foreground: Colors.white,
          contrastStyle: contrast,
        ),
      ),
    );

    await tester.pumpWidget(host(DashboardHeaderTextContrastStyle.none));
    final baseline = tester.getSize(
      find.byKey(const ValueKey<String>('contrast-geometry')),
    );
    await tester.pumpWidget(
      host(DashboardHeaderTextContrastStyle.hardOppositeShadow),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('contrast-geometry'))),
      baseline,
    );
    await tester.pumpWidget(
      host(DashboardHeaderTextContrastStyle.oppositeOutline),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('contrast-geometry'))),
      baseline,
    );
  });
}
