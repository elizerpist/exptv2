import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/backheader_style_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('center backheader design persists through theme settings map', () {
    final settings = AppThemeSettings.defaults().copyWith(
      backheaderStyle: BackheaderStyle.centerBadgeBudget,
      centerBackheaderDesign: BackheaderCenterDesign.colored,
    );

    final roundTrip = AppThemeSettings.fromMap(settings.toMap());

    expect(roundTrip.backheaderStyle, BackheaderStyle.centerBadgeBudget);
    expect(roundTrip.centerBackheaderDesign, BackheaderCenterDesign.colored);
    expect(
      AppThemeSettings.fromMap(
        const <dynamic, dynamic>{},
      ).centerBackheaderDesign,
      BackheaderCenterDesign.neutral,
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerPartitionRingEnabled': true,
      }).toMap()['centerPartitionRingEnabled'],
      isTrue,
    );
    expect(
      AppThemeSettings.fromMap(
        const <dynamic, dynamic>{},
      ).toMap()['centerPartitionRingEnabled'],
      isFalse,
    );
  });

  test('legacy token backheader styles fall back to classic', () {
    expect(BackheaderStyle.fromAny('heroToken'), BackheaderStyle.classic);
    expect(BackheaderStyle.fromAny('orbitBudget'), BackheaderStyle.classic);
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'backheaderStyle': 'heroToken',
      }).backheaderStyle,
      BackheaderStyle.classic,
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'backheaderStyle': 'orbitBudget',
      }).backheaderStyle,
      BackheaderStyle.classic,
    );
  });

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
    expect(find.text('C - Hero Token'), findsNothing);
    expect(find.text('D - Orbit Budget'), findsNothing);
    expect(find.text('E - Center Badge Budget'), findsOneWidget);
    expect(find.text('A - Color Field Partition'), findsNothing);
    expect(find.text('B - Partition Dashboard'), findsNothing);
    expect(find.text('E - Mosaic Budget'), findsNothing);
    expect(find.text('F - Ledger Strip'), findsNothing);
    expect(
      find.byKey(const ValueKey('backheader-style-preview-classic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-style-preview-heroToken')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('backheader-style-preview-orbitBudget')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('backheader-style-preview-centerBadgeBudget')),
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

    await tester.tap(find.text('E - Center Badge Budget'));
    await tester.pump();

    expect(updated?.backheaderStyle, BackheaderStyle.centerBadgeBudget);
  });

  testWidgets('backheader style panel updates center design mode', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.defaults().copyWith(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
            ),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    expect(find.text('Jelenlegi háttér (jelenlegi)'), findsOneWidget);
    expect(find.text('Színes háttér'), findsOneWidget);

    await tester.tap(find.text('Színes háttér'));
    await tester.pump();

    expect(updated?.centerBackheaderDesign, BackheaderCenterDesign.colored);
  });

  testWidgets('backheader style panel toggles center partition ring', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.fromMap(const <dynamic, dynamic>{
              'backheaderStyle': 'centerBadgeBudget',
              'centerPartitionRingEnabled': false,
            }),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    expect(find.text('Külső partition kör'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('center-partition-ring-toggle')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-partition-ring-toggle')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('center-partition-ring-toggle')),
    );
    await tester.pump();

    expect(updated?.toMap()['centerPartitionRingEnabled'], isTrue);
  });
}
