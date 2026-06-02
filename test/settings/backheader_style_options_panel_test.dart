import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/backheader_style_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backheader style panel lists classic and experimental styles', (
    tester,
  ) async {
    var settings = AppThemeSettings.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: settings,
            onChanged: (next) => settings = next,
          ),
        ),
      ),
    );

    expect(find.text('Jelenlegi bar rendszer (jelenlegi)'), findsOneWidget);
    expect(find.text('A - Color Field Partition'), findsOneWidget);
    expect(find.text('B - Partition Dashboard'), findsOneWidget);
    expect(find.text('C - Hero Token'), findsOneWidget);
    expect(find.text('D - Orbit Budget'), findsOneWidget);
    expect(find.text('E - Mosaic Budget'), findsOneWidget);
    expect(find.text('F - Ledger Strip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('backheader-style-preview-classic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-style-preview-ledgerStrip')),
      findsOneWidget,
    );
  });

  testWidgets('backheader style panel updates selected style', (tester) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.defaults(),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    await tester.tap(find.text('D - Orbit Budget'));
    await tester.pump();

    expect(updated?.backheaderStyle, BackheaderStyle.orbitBudget);
  });
}
