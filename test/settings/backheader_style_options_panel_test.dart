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
    expect(BackheaderStyle.fromAny('ambulanceSkin'), BackheaderStyle.classic);
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
    expect(find.text('Mentők skin'), findsNothing);
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
    expect(
      find.byKey(const ValueKey('backheader-style-preview-ambulanceSkin')),
      findsNothing,
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

    expect(find.text('Fehér korong'), findsWidgets);
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
    for (var distance = 0; distance < 5; distance += 1) {
      expect(
        find.byKey(ValueKey('center-badge-pair-size-$distance-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('center-badge-pair-size-$distance-input')),
        findsOneWidget,
      );
      if (distance > 0) {
        expect(
          find.byKey(ValueKey('center-badge-distance-offset-$distance-slider')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('center-badge-distance-offset-$distance-input')),
          findsOneWidget,
        );
      }
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
      find.byKey(const ValueKey('center-badge-pair-size-0-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-pair-size-0-input')),
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
      find.byKey(const ValueKey('center-badge-distance-offset-1-input')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('center-badge-distance-offset-1-input')),
      '6',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(updated?.centerBadgeSlotXOffsets, [0, 0, 0, -6, 0, 6, 0, 0, 0]);
  });

  testWidgets(
    'center badge tuner groups controls by distance pairs and resets',
    (tester) async {
      AppThemeSettings? updated;
      final settings = AppThemeSettings.defaults().copyWith(
        backheaderStyle: BackheaderStyle.centerBadgeBudget,
        centerBadgeWhiteIconOpacities: const [90, 70, 50, 30, 10],
        centerBadgeColoredFillOpacities: const [80, 60, 40, 20, 5],
        centerBadgeSlotSizePercents: const [88, 89, 90, 91, 92, 93, 94, 95, 96],
        centerBadgeSlotXOffsets: const [-16, -12, -8, -4, 0, 4, 8, 12, 16],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackheaderStyleOptionsPanel(
              settings: settings,
              onChanged: (next) => updated = next,
            ),
          ),
        ),
      );

      for (var distance = 0; distance < 5; distance += 1) {
        expect(
          find.byKey(ValueKey('center-badge-tuning-section-$distance')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('center-badge-slot-x-offset-5-input')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('center-badge-pair-size-1-input')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('center-badge-pair-size-1-input')),
        '122',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(updated?.centerBadgeSlotSizePercents, [
        88,
        89,
        90,
        122,
        92,
        122,
        94,
        95,
        96,
      ]);

      await tester.ensureVisible(
        find.byKey(const ValueKey('center-badge-distance-offset-2-input')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('center-badge-distance-offset-2-input')),
        '9',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(updated?.centerBadgeSlotXOffsets, [
        -16,
        -12,
        -9,
        -4,
        0,
        4,
        9,
        12,
        16,
      ]);

      await tester.ensureVisible(
        find.byKey(const ValueKey('center-badge-tuning-reset-button')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('center-badge-tuning-reset-button')),
      );
      await tester.pump();

      expect(updated?.backheaderStyle, BackheaderStyle.centerBadgeBudget);
      expect(
        updated?.centerBadgeWhiteIconOpacities,
        kCenterBadgeWhiteIconOpacityDefaults,
      );
      expect(
        updated?.centerBadgeColoredFillOpacities,
        kCenterBadgeColoredFillOpacityDefaults,
      );
      expect(
        updated?.centerBadgeSlotSizePercents,
        kCenterBadgeSlotSizePercentDefaults,
      );
      expect(updated?.centerBadgeSlotXOffsets, kCenterBadgeSlotXOffsetDefaults);
    },
  );

  testWidgets('center badge tuner slider updates numeric pill live', (
    tester,
  ) async {
    var settings = AppThemeSettings.defaults().copyWith(
      backheaderStyle: BackheaderStyle.centerBadgeBudget,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return BackheaderStyleOptionsPanel(
                settings: settings,
                onChanged: (next) => setState(() => settings = next),
              );
            },
          ),
        ),
      ),
    );

    final sliderFinder = find.byKey(
      const ValueKey('center-badge-colored-opacity-icon-2-slider'),
    );
    await tester.ensureVisible(sliderFinder);
    await tester.pump();
    tester.widget<Slider>(sliderFinder).onChanged!(34);
    await tester.pump();

    final inputFinder = find.byKey(
      const ValueKey('center-badge-colored-opacity-icon-2-input'),
    );
    final editable = tester.widget<EditableText>(
      find.descendant(of: inputFinder, matching: find.byType(EditableText)),
    );
    expect(editable.controller.text, '34');
  });

  testWidgets(
    'center badge relative section separates size badge and disc opacity',
    (tester) async {
      var settings = AppThemeSettings.defaults().copyWith(
        backheaderStyle: BackheaderStyle.centerBadgeBudget,
        centerBadgeWhiteDiscOpacities: const [10, 20, 30, 40, 50],
        centerBadgeWhiteIconOpacities: const [100, 80, 60, 40, 20],
        centerBadgeWhiteProgressOpacities: const [90, 70, 50, 30, 10],
        centerBadgeColoredFillOpacities: const [15, 25, 35, 45, 55],
        centerBadgeColoredIconOpacities: const [20, 40, 60, 80, 100],
        centerBadgeColoredProgressOpacities: const [12, 24, 36, 48, 60],
        centerBadgeSlotSizePercents: const [
          80,
          90,
          100,
          110,
          120,
          110,
          100,
          90,
          80,
        ],
        centerBadgeSlotXOffsets: const [-8, -6, -4, -2, 0, 2, 4, 6, 8],
        centerBadgeColoredBackgroundOpacity: 64,
      );
      const baselineWhiteDisc = [10, 20, 30, 40, 50];
      const baselineWhiteIcon = [100, 80, 60, 40, 20];
      const baselineWhiteProgress = [90, 70, 50, 30, 10];
      const baselineColoredFill = [15, 25, 35, 45, 55];
      const baselineColoredIcon = [20, 40, 60, 80, 100];
      const baselineColoredProgress = [12, 24, 36, 48, 60];
      const baselineSizes = [80, 90, 100, 110, 120, 110, 100, 90, 80];
      const baselineOffsets = [-8, -6, -4, -2, 0, 2, 4, 6, 8];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BackheaderStyleOptionsPanel(
                  settings: settings,
                  onChanged: (next) => setState(() => settings = next),
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('center-badge-relative-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('center-badge-relative-all-slider')),
        findsNothing,
      );
      expect(find.text('Relatív méret'), findsOneWidget);
      expect(find.text('Relatív badge opacity'), findsOneWidget);
      expect(find.text('Relatív korong opacity'), findsOneWidget);

      final sizeSliderFinder = find.byKey(
        const ValueKey('center-badge-relative-size-slider'),
      );
      await tester.ensureVisible(sizeSliderFinder);
      await tester.pump();
      expect(tester.widget<Slider>(sizeSliderFinder).value, 100);
      tester.widget<Slider>(sizeSliderFinder).onChanged!(125);
      await tester.pump();

      expect(settings.centerBadgeSlotSizePercents, [
        100,
        113,
        125,
        138,
        150,
        138,
        125,
        113,
        100,
      ]);
      expect(settings.centerBadgeSlotXOffsets, baselineOffsets);
      expect(settings.centerBadgeWhiteDiscOpacities, baselineWhiteDisc);
      expect(settings.centerBadgeColoredIconOpacities, baselineColoredIcon);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);

      tester.widget<Slider>(sizeSliderFinder).onChanged!(100);
      await tester.pump();
      expect(settings.centerBadgeSlotSizePercents, baselineSizes);

      tester.widget<Slider>(sizeSliderFinder).onChanged!(75);
      await tester.pump();
      expect(settings.centerBadgeSlotSizePercents, [
        60,
        68,
        75,
        83,
        90,
        83,
        75,
        68,
        60,
      ]);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);

      tester.widget<Slider>(sizeSliderFinder).onChanged!(100);
      await tester.pump();

      final opacitySliderFinder = find.byKey(
        const ValueKey('center-badge-relative-opacity-slider'),
      );
      await tester.ensureVisible(opacitySliderFinder);
      await tester.pump();
      expect(tester.widget<Slider>(opacitySliderFinder).value, 100);
      tester.widget<Slider>(opacitySliderFinder).onChanged!(125);
      await tester.pump();

      expect(settings.centerBadgeWhiteDiscOpacities, baselineWhiteDisc);
      expect(settings.centerBadgeWhiteIconOpacities, [100, 100, 75, 50, 25]);
      expect(settings.centerBadgeWhiteProgressOpacities, [100, 88, 63, 38, 13]);
      expect(settings.centerBadgeColoredFillOpacities, baselineColoredFill);
      expect(settings.centerBadgeColoredIconOpacities, [25, 50, 75, 100, 100]);
      expect(settings.centerBadgeColoredProgressOpacities, [
        15,
        30,
        45,
        60,
        75,
      ]);
      expect(settings.centerBadgeSlotSizePercents, baselineSizes);
      expect(settings.centerBadgeSlotXOffsets, baselineOffsets);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);

      tester.widget<Slider>(opacitySliderFinder).onChanged!(100);
      await tester.pump();
      expect(settings.centerBadgeWhiteDiscOpacities, baselineWhiteDisc);
      expect(settings.centerBadgeWhiteIconOpacities, baselineWhiteIcon);
      expect(settings.centerBadgeWhiteProgressOpacities, baselineWhiteProgress);
      expect(settings.centerBadgeColoredFillOpacities, baselineColoredFill);
      expect(settings.centerBadgeColoredIconOpacities, baselineColoredIcon);
      expect(
        settings.centerBadgeColoredProgressOpacities,
        baselineColoredProgress,
      );

      tester.widget<Slider>(opacitySliderFinder).onChanged!(50);
      await tester.pump();
      expect(settings.centerBadgeWhiteDiscOpacities, baselineWhiteDisc);
      expect(settings.centerBadgeColoredIconOpacities, [10, 20, 30, 40, 50]);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);

      tester.widget<Slider>(opacitySliderFinder).onChanged!(100);
      await tester.pump();

      final discOpacitySliderFinder = find.byKey(
        const ValueKey('center-badge-relative-disc-opacity-slider'),
      );
      await tester.ensureVisible(discOpacitySliderFinder);
      await tester.pump();
      expect(tester.widget<Slider>(discOpacitySliderFinder).value, 100);
      tester.widget<Slider>(discOpacitySliderFinder).onChanged!(125);
      await tester.pump();

      expect(settings.centerBadgeWhiteDiscOpacities, [13, 25, 38, 50, 63]);
      expect(settings.centerBadgeColoredFillOpacities, [19, 31, 44, 56, 69]);
      expect(settings.centerBadgeWhiteIconOpacities, baselineWhiteIcon);
      expect(settings.centerBadgeWhiteProgressOpacities, baselineWhiteProgress);
      expect(settings.centerBadgeColoredIconOpacities, baselineColoredIcon);
      expect(
        settings.centerBadgeColoredProgressOpacities,
        baselineColoredProgress,
      );
      expect(settings.centerBadgeSlotSizePercents, baselineSizes);
      expect(settings.centerBadgeSlotXOffsets, baselineOffsets);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);

      tester.widget<Slider>(discOpacitySliderFinder).onChanged!(100);
      await tester.pump();
      expect(settings.centerBadgeWhiteDiscOpacities, baselineWhiteDisc);
      expect(settings.centerBadgeColoredFillOpacities, baselineColoredFill);

      tester.widget<Slider>(discOpacitySliderFinder).onChanged!(50);
      await tester.pump();
      expect(settings.centerBadgeWhiteDiscOpacities, [5, 10, 15, 20, 25]);
      expect(settings.centerBadgeColoredFillOpacities, [8, 13, 18, 23, 28]);
      expect(settings.centerBadgeWhiteIconOpacities, baselineWhiteIcon);
      expect(settings.centerBadgeColoredIconOpacities, baselineColoredIcon);
      expect(settings.centerBadgeColoredBackgroundOpacity, 64);
    },
  );

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
