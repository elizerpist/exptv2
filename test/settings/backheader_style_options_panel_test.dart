import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/backheader_style_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('center backheader design persists through theme settings map', () {
    final settings = AppThemeSettings.defaults().copyWith(
      backheaderStyle: BackheaderStyle.centerBadgeBudget,
      centerBackheaderDesign: BackheaderCenterDesign.colored,
      centerBadgeDiscEnabled: false,
      centerBadgeBorderMode: CenterBadgeBorderMode.always,
    );

    final roundTrip = AppThemeSettings.fromMap(settings.toMap());

    expect(roundTrip.backheaderStyle, BackheaderStyle.centerBadgeBudget);
    expect(roundTrip.centerBackheaderDesign, BackheaderCenterDesign.colored);
    expect(roundTrip.centerBadgeDiscEnabled, isFalse);
    expect(roundTrip.centerBadgeBorderMode, CenterBadgeBorderMode.always);
    expect(roundTrip.centerBadgeOverlapMaskEnabled, isFalse);
    expect(roundTrip.centerBadgeWhiteDiscOpacities, [18, 13, 10, 9, 8]);
    expect(roundTrip.centerBadgeWhiteIconOpacities, [100, 72, 58, 48, 42]);
    expect(roundTrip.centerBadgeWhiteProgressOpacities, [100, 72, 58, 48, 42]);
    expect(roundTrip.centerBadgeColoredFillOpacities, [100, 72, 58, 48, 42]);
    expect(roundTrip.centerBadgeColoredIconOpacities, [100, 72, 58, 48, 42]);
    expect(roundTrip.centerBadgeColoredProgressOpacities, [
      100,
      72,
      58,
      48,
      42,
    ]);
    expect(roundTrip.centerBadgeSlotSizePercents, [
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
    ]);
    expect(roundTrip.centerBadgeSlotXOffsets, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
    expect(roundTrip.centerBadgeColoredBackgroundOpacity, 72);
    expect(
      AppThemeSettings.fromMap(
        const <dynamic, dynamic>{},
      ).centerBackheaderDesign,
      BackheaderCenterDesign.neutral,
    );
    expect(
      AppThemeSettings.fromMap(
        const <dynamic, dynamic>{},
      ).centerBadgeDiscEnabled,
      isTrue,
    );
    expect(
      AppThemeSettings.fromMap(
        const <dynamic, dynamic>{},
      ).centerBadgeBorderMode,
      CenterBadgeBorderMode.limitOnly,
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerPartitionRingEnabled': true,
        'centerBadgeDiscEnabled': false,
        'centerBadgeBorderMode': 'always',
      }).toMap()['centerPartitionRingEnabled'],
      isTrue,
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeDiscEnabled': false,
        'centerBadgeBorderMode': 'always',
      }).toMap(),
      containsPair('centerBadgeDiscEnabled', false),
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeDiscEnabled': false,
        'centerBadgeBorderMode': 'always',
        'centerBadgeOverlapMaskEnabled': true,
      }).toMap(),
      containsPair('centerBadgeBorderMode', 'always'),
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeOverlapMaskEnabled': true,
      }).centerBadgeOverlapMaskEnabled,
      isTrue,
    );
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeWhiteDiscOpacities': [20, 30, 40, 50, 60],
        'centerBadgeWhiteIconOpacities': [100, 90, 80, 70, 60],
        'centerBadgeWhiteProgressOpacities': [55, 45, 35, 25, 15],
        'centerBadgeColoredFillOpacities': [99, 88, 77, 66, 55],
        'centerBadgeColoredIconOpacities': [91, 82, 73, 64, 55],
        'centerBadgeColoredProgressOpacities': [81, 72, 63, 54, 45],
        'centerBadgeSlotSizePercents': [90, 91, 92, 93, 94, 95, 96, 97, 98],
        'centerBadgeSlotXOffsets': [-8, -6, -4, -2, 0, 2, 4, 6, 8],
        'centerBadgeColoredBackgroundOpacity': 64,
      }).toMap(),
      containsPair('centerBadgeWhiteDiscOpacities', [20, 30, 40, 50, 60]),
    );
    final customMap = AppThemeSettings.fromMap(const <dynamic, dynamic>{
      'centerBadgeColoredFillOpacities': [99, 88, 77, 66, 55],
      'centerBadgeColoredIconOpacities': [91, 82, 73, 64, 55],
      'centerBadgeColoredProgressOpacities': [81, 72, 63, 54, 45],
      'centerBadgeSlotSizePercents': [90, 91, 92, 93, 94, 95, 96, 97, 98],
      'centerBadgeSlotXOffsets': [-8, -6, -4, -2, 0, 2, 4, 6, 8],
    }).toMap();
    expect(customMap['centerBadgeColoredFillOpacities'], [99, 88, 77, 66, 55]);
    expect(customMap['centerBadgeColoredIconOpacities'], [91, 82, 73, 64, 55]);
    expect(customMap['centerBadgeColoredProgressOpacities'], [
      81,
      72,
      63,
      54,
      45,
    ]);
    expect(customMap['centerBadgeSlotSizePercents'], [
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      98,
    ]);
    expect(customMap['centerBadgeSlotXOffsets'], [
      -8,
      -6,
      -4,
      -2,
      0,
      2,
      4,
      6,
      8,
    ]);
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeWhiteDiscOpacities': [120, -5, '42', 99.6, null],
        'centerBadgeColoredFillOpacities': [120, -5, '42', 99.6, null],
        'centerBadgeSlotSizePercents': [10, 55, '88', 220, null],
        'centerBadgeSlotXOffsets': [-90, -48, '12', 90, null],
        'centerBadgeColoredBackgroundOpacity': 140,
      }).centerBadgeWhiteDiscOpacities,
      [100, 0, 42, 100, 8],
    );
    final clamped = AppThemeSettings.fromMap(const <dynamic, dynamic>{
      'centerBadgeColoredFillOpacities': [120, -5, '42', 99.6, null],
      'centerBadgeSlotSizePercents': [10, 55, '88', 220, null],
      'centerBadgeSlotXOffsets': [-90, -48, '12', 90, null],
    });
    expect(clamped.centerBadgeColoredFillOpacities, [100, 0, 42, 100, 42]);
    expect(clamped.centerBadgeSlotSizePercents.take(5), [50, 55, 88, 180, 100]);
    expect(clamped.centerBadgeSlotXOffsets.take(5), [-64, -48, 12, 64, 0]);
    expect(
      AppThemeSettings.fromMap(const <dynamic, dynamic>{
        'centerBadgeColoredBackgroundOpacity': -12,
      }).centerBadgeColoredBackgroundOpacity,
      0,
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

  testWidgets('backheader style panel toggles colored badge disc', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.fromMap(const <dynamic, dynamic>{
              'backheaderStyle': 'centerBadgeBudget',
              'centerBackheaderDesign': 'colored',
              'centerBadgeDiscEnabled': true,
            }),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    expect(find.text('Fehér korong'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('center-badge-disc-toggle')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-disc-toggle')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('center-badge-disc-toggle')));
    await tester.pump();

    expect(updated?.centerBadgeDiscEnabled, isFalse);
  });

  testWidgets('backheader style panel updates center badge border mode', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.fromMap(const <dynamic, dynamic>{
              'backheaderStyle': 'centerBadgeBudget',
              'centerBadgeBorderMode': 'limitOnly',
            }),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    expect(find.text('Badge border'), findsOneWidget);
    expect(find.text('Csak limites badgeken (jelenlegi)'), findsOneWidget);
    expect(find.text('Mindig látszik'), findsOneWidget);

    await tester.ensureVisible(find.text('Mindig látszik'));
    await tester.pump();
    await tester.tap(find.text('Mindig látszik'));
    await tester.pump();

    expect(updated?.centerBadgeBorderMode, CenterBadgeBorderMode.always);
  });

  testWidgets('backheader style panel exposes center badge opacity controls', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.defaults().copyWith(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              centerBackheaderDesign: BackheaderCenterDesign.colored,
            ),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    expect(find.text('Fehér opacity finomhangolás'), findsOneWidget);
    for (final layer in ['disc', 'icon', 'progress']) {
      for (var index = 0; index < 5; index += 1) {
        expect(
          find.byKey(ValueKey('center-badge-opacity-$layer-$index-slider')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('center-badge-opacity-$layer-$index-input')),
          findsOneWidget,
        );
      }
    }
    expect(
      find.byKey(const ValueKey('center-badge-opacity-background-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('center-badge-opacity-background-input')),
      findsOneWidget,
    );
    expect(find.text('Színes badge opacity'), findsOneWidget);
    for (final layer in ['fill', 'icon', 'progress']) {
      for (var index = 0; index < 5; index += 1) {
        expect(
          find.byKey(
            ValueKey('center-badge-colored-opacity-$layer-$index-slider'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            ValueKey('center-badge-colored-opacity-$layer-$index-input'),
          ),
          findsOneWidget,
        );
      }
    }
    expect(find.text('Badge méret és pozíció'), findsOneWidget);
    for (var index = 0; index < 9; index += 1) {
      expect(
        find.byKey(ValueKey('center-badge-slot-size-$index-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('center-badge-slot-size-$index-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('center-badge-slot-x-offset-$index-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('center-badge-slot-x-offset-$index-input')),
        findsOneWidget,
      );
    }

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-opacity-icon-1-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-opacity-icon-1-input')),
      '37',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeWhiteIconOpacities, [100, 37, 58, 48, 42]);

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-opacity-background-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-opacity-background-input')),
      '64',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeColoredBackgroundOpacity, 64);

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-colored-opacity-icon-2-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-colored-opacity-icon-2-input')),
      '33',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeColoredIconOpacities, [100, 72, 33, 48, 42]);

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-slot-size-4-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-slot-size-4-input')),
      '115',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeSlotSizePercents, [
      100,
      100,
      100,
      100,
      115,
      100,
      100,
      100,
      100,
    ]);

    await tester.ensureVisible(
      find.byKey(const ValueKey('center-badge-slot-x-offset-5-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-slot-x-offset-5-input')),
      '-6',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeSlotXOffsets, [0, 0, 0, 0, 0, -6, 0, 0, 0]);
  });

  testWidgets('backheader style panel toggles overlap masking', (tester) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackheaderStyleOptionsPanel(
            settings: AppThemeSettings.defaults().copyWith(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              centerBackheaderDesign: BackheaderCenterDesign.colored,
            ),
            onChanged: (next) => updated = next,
          ),
        ),
      ),
    );

    final toggle = find.byKey(
      const ValueKey('center-badge-overlap-mask-toggle'),
    );
    expect(toggle, findsOneWidget);

    await tester.ensureVisible(toggle);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pump();

    expect(updated?.centerBadgeOverlapMaskEnabled, isTrue);
  });
}
