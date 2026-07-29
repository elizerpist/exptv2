import 'dart:io';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/slots/category_color_resolver.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/budget_v2_frame_data.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_ticking_carousel.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  test('BudgetV2 source contract locks the final B3M-B literals', () {
    final source = File('balance_latest_layout.html').readAsStringSync();
    final implementation = File(
      'lib/features/transactions/widgets/experimental/balance/'
      'spendee_budget_v2_components.dart',
    ).readAsStringSync();

    for (final literal in const <String>[
      'linear-gradient(112deg, #bdf5ff 0%, #06b6d4 50%, #0057d9 100%)',
      'height: 80px;',
      'min-height: 59.4px;',
      'transform: translate(-50%, 0) scale(.9);',
      'height: 210px;',
      'grid-template-rows: 23px minmax(0,1fr);',
      'border-radius: 26px;',
      'width: 70px;',
      'height: 70px;',
      'viewBox',
      '102 102 308 308',
      '46 60 564 226',
      '94 78 324 342',
      '44 44 424 424',
    ]) {
      expect(source, contains(literal));
    }
    for (final literal in const <String>[
      'budget-fluvi-circle-progress',
      'budget-fluvi-weekly-rhythm',
      'budget-fluvi-avatar-disc',
      'budget-fluvi-clay-donut',
      'SoftBlur',
      'budgetFluviWeeklyBlur6',
      'progress-highlight',
      'stroke-dashoffset',
      'CategoryColorResolver.color',
      'CategorySlotIcon',
      'coreOnly = false',
      'data-budget-avatar-disc-core',
      'selectedAvatarTrackRadiusScale',
      'trackRadiusScale',
      'fontSize: 7.4',
      'fontSize: 6.1',
      'fontSize: 9.5',
      'Color(0xFF25365C)',
      'Color(0xFF51617F)',
      'Color(0xFFE84CAE)',
      'width: 378',
      'height: 210',
      'spendee-budget-v2-mother-card-dot-',
    ]) {
      expect(implementation, contains(literal));
    }
  });

  test(
    'BudgetV2 selected avatar core uses a square, concentric source face',
    () {
      const color = Color(0xFF24C889);
      final regular = BudgetV2FluviSvg.avatarDisc(color, 41);
      final core = BudgetV2FluviSvg.avatarDisc(color, 41, coreOnly: true);

      expect(regular, contains('viewBox="94 78 324 342"'));
      expect(regular, contains('<ellipse cx="256" cy="382"'));
      expect(core, contains('viewBox="94 78 324 324"'));
      expect(core, contains('data-budget-avatar-disc-core="true"'));
      expect(core, isNot(contains('<ellipse cx="256" cy="382"')));
      expect(
        core,
        isNot(contains('filter="url(#budgetAvatarDisc41Shadow)"')),
        reason:
            'The selected orb owns its outer shadow; an inner lower SVG shadow '
            'would make the true circular avatar appear off-centre.',
      );
    },
  );

  test('BudgetV2 header preserves the real over-budget ratio', () {
    final summary = BudgetV2BudgetSummary.fromBars(<CategoryBudgetBarData>[
      _bar(_food, spent: 1500, limit: 1000),
    ]);

    expect(summary.percent, 150);
    expect(summary.remaining, -500);
  });

  test('BudgetV2 avatar bands keep the shared size controls independent', () {
    const base = BudgetV2AvatarAppearance();
    const largerCenter = BudgetV2AvatarAppearance(centerSize: .8);
    const largerInner = BudgetV2AvatarAppearance(innerSize: .8);
    const largerOuter = BudgetV2AvatarAppearance(outerSize: .8);

    expect(
      largerCenter.scaleForVisualLogicalOffset(0),
      greaterThan(base.scaleForVisualLogicalOffset(0)),
    );
    expect(
      largerCenter.scaleForVisualLogicalOffset(1),
      base.scaleForVisualLogicalOffset(1),
    );
    expect(
      largerCenter.scaleForVisualLogicalOffset(2),
      base.scaleForVisualLogicalOffset(2),
    );

    expect(
      largerInner.scaleForVisualLogicalOffset(0),
      base.scaleForVisualLogicalOffset(0),
    );
    expect(
      largerInner.scaleForVisualLogicalOffset(1),
      greaterThan(base.scaleForVisualLogicalOffset(1)),
    );
    expect(
      largerInner.scaleForVisualLogicalOffset(2),
      base.scaleForVisualLogicalOffset(2),
    );

    expect(
      largerOuter.scaleForVisualLogicalOffset(0),
      base.scaleForVisualLogicalOffset(0),
    );
    expect(
      largerOuter.scaleForVisualLogicalOffset(1),
      base.scaleForVisualLogicalOffset(1),
    );
    expect(
      largerOuter.scaleForVisualLogicalOffset(2),
      greaterThan(base.scaleForVisualLogicalOffset(2)),
    );
  });

  test('BudgetV2 inactive donut slices keep their full resolver colour', () {
    const source = Color(0xFF2BC4F3);

    expect(BudgetV2DonutSliceVisuals.colorFor(source, active: true), source);
    expect(BudgetV2DonutSliceVisuals.colorFor(source, active: false), source);
  });

  test(
    'BudgetV2 overview keeps the standard Budget total when a category is filtered',
    () {
      final input = BalanceFrameInput(
        now: DateTime(2026, 7, 25),
        activeType: TransactionType.expense,
        summaryWindow: SummaryWindow.monthly,
        summaryReferenceDate: DateTime(2026, 7),
        categoryIds: <int>{_food.transactionCategoryID},
        transactions: _inputWithVendorDistribution().transactions,
        recurringGhosts: const [],
        categories: _inputWithVendorDistribution().categories,
        limits: const [],
      );

      final overview = BudgetV2FrameData.fromInput(input).bars.first;

      expect(overview.targetType, LimitTargetType.overview);
      // The ordinary Budget carousel calculates its overview before a
      // category-avatar filter. Food is 850 Ft, but the active July expense
      // budget is 2,000 Ft including MOL and BKK.
      expect(overview.spent, 2000);
    },
  );

  test('BudgetV2 Fluvi SVGs map live category data to the B3M-B geometry', () {
    final donut = BudgetV2FluviSvg.clayDonut(
      slices: const <BudgetV2FluviDonutSlice>[
        BudgetV2FluviDonutSlice(
          label: 'Élelmiszer',
          value: 60,
          color: Color(0xFF22C55E),
        ),
        BudgetV2FluviDonutSlice(
          label: 'Lakás',
          value: 30,
          color: Color(0xFF60A5FA),
        ),
        BudgetV2FluviDonutSlice(
          label: 'Rezsi',
          value: 10,
          color: Color(0xFFA855F7),
        ),
      ],
      selectedIndex: 1,
      highlightedIndexes: const <int>{0, 1},
    );

    expect(donut, contains('data-budget-fluvi-donut-count="3"'));
    expect(donut, contains('data-fluvi-donut-slice="0"'));
    expect(donut, contains('data-label="Élelmiszer"'));
    expect(donut, contains('data-value="60"'));
    expect(donut, contains('data-label="Lakás"'));
    expect(donut, contains('data-value="30"'));
    expect(donut, contains('data-fluvi-donut-selected="true"'));
    expect(donut, contains('30%'));
    // The 60% arc is a large arc. Equal-count thirds would never use the
    // large-arc flag for any segment.
    expect(donut, contains('A 160.38 160.38 0 1 1'));
    expect(donut, contains('font-weight="750"'));
    final flutterDonut = BudgetV2FluviSvg.flutterRenderable(donut);
    expect(flutterDonut, isNot(contains('<filter')));
    expect(flutterDonut, isNot(contains('font-weight="750"')));
    expect(flutterDonut, contains('font-weight="700"'));
    expect(flutterDonut, contains('data-fluvi-donut-slice="0"'));
    expect(flutterDonut, contains('data-value="60"'));

    final progress = BudgetV2FluviSvg.circleProgress(51);
    expect(progress, contains('stroke-dashoffset="295.561037"'));
    expect(progress, contains('stroke-dasharray="307.624753 295.561037"'));
    expect(progress, contains('>51%</text>'));
    expect(progress, isNot(contains('>limit állása</text>')));

    final rhythm = BudgetV2FluviSvg.weeklyRhythm(const <int>[
      0,
      20,
      0,
      40,
      0,
      60,
      80,
    ]);
    expect(rhythm, contains('data-weekly-rhythm-day="0" data-value="0"></g>'));
    expect(rhythm, contains('data-weekly-rhythm-day="6" data-value="80"'));
    expect(rhythm, contains('y="73"'));
    expect(rhythm, contains('átlag: 29%'));

    expect(
      BudgetV2WeeklyRhythmValues.resolve(
        bar: _bars.first,
        records: _input().transactions,
        endDate: DateTime(2026, 7, 25),
      ),
      const <int>[0, 0, 0, 0, 0, 0, 51],
    );

    final avatar = BudgetV2FluviSvg.avatarDisc(const Color(0xFF22C55E), 2);
    expect(avatar, contains('stop-color="#cef2dc"'));
    expect(avatar, contains('stop-color="#4acf7b"'));
    expect(avatar, contains('stop-color="#238b54"'));
    expect(avatar, contains('flood-color="#22a558"'));
    expect(avatar, contains('M181 315 C233 357 307 355 350 311'));
  });

  test('BudgetV2 full limit ring uses Flutter-resolvable circle lengths', () {
    final rendered = BudgetV2FluviSvg.flutterRenderable(
      BudgetV2FluviSvg.circleProgress(100),
    );

    expect(rendered, isNot(contains('pathLength=')));
    expect(rendered, contains('stroke-dasharray="603.185789 0"'));
    expect(rendered, contains('stroke-dashoffset="0"'));
  });

  testWidgets(
    'BudgetV2 limit circle is painted by Flutter without a runtime SVG parser',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              budgetV2Bars: _bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final limitCircle = find.byKey(
        const ValueKey('spendee-budget-v2-limit-circle'),
      );
      expect(limitCircle, findsOneWidget);
      expect(
        find.descendant(of: limitCircle, matching: find.byType(SvgPicture)),
        findsNothing,
      );
      expect(
        find.descendant(of: limitCircle, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: limitCircle, matching: find.byType(CustomPaint)),
      );
      final painter = paint.painter! as BudgetV2LimitProgressPainter;
      // The reference setValue() rounds its live SVG arc to a whole percent.
      expect(painter.progress, .51);
      expect(painter.percent, 51);
      // The live arc starts at the exact central-resolver avatar colour and
      // ends in the same deterministic pink-to-lilac relationship that the
      // frozen source uses. It must not fall back to one global pink ring.
      final expectedStart = CategoryColorResolver.color(category: _food);
      expect(painter.startColor, expectedStart);
      expect(painter.endColor, _budgetV2CompanionColor(expectedStart));
      expect(painter.gradientStops, const <double>[0, .45, 1]);
      // Removing the inner caption lets the compact percentage sit with
      // physical breathing room inside the 96px source-radius track.
      expect(painter.percentFontSize, 48);
      expect(painter.percentBaseline, 172);
      expect(painter.centerCaption, isNull);
      expect(BudgetV2LimitProgressPainter.sourceViewport, const Size(308, 308));
      expect(BudgetV2LimitProgressPainter.sourceFaceRadius, 122);
      expect(BudgetV2LimitProgressPainter.sourceTrackRadius, 96);

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 70,
            height: 70,
            child: BudgetV2LimitProgressRing(
              key: ValueKey('budget-v2-full-limit-ring-test'),
              rawProgress: 1,
            ),
          ),
        ),
      );
      final fullPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-v2-full-limit-ring-test')),
          matching: find.byType(CustomPaint),
        ),
      );
      final fullPainter = fullPaint.painter! as BudgetV2LimitProgressPainter;
      expect(fullPainter.progress, 1);
      expect(fullPainter.percent, 100);

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 70,
            height: 70,
            child: BudgetV2LimitProgressRing(
              key: ValueKey('budget-v2-minimum-limit-ring-test'),
              rawProgress: 0,
            ),
          ),
        ),
      );
      final minimumPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-v2-minimum-limit-ring-test')),
          matching: find.byType(CustomPaint),
        ),
      );
      final minimumPainter =
          minimumPaint.painter! as BudgetV2LimitProgressPainter;
      // The frozen HTML clamps zero to a visible 1% arc rather than showing
      // a number without any live stroke.
      expect(minimumPainter.progress, .01);
      expect(minimumPainter.percent, 1);
    },
  );

  test('APK workflow does not run the unrelated Balance V3 gate', () {
    final workflow = File(
      '.github/workflows/android-build.yml',
    ).readAsStringSync();

    expect(workflow, isNot(contains('check_balance_v3_gate.sh')));
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter test'));
    expect(workflow, contains('flutter build apk --debug'));
  });

  testWidgets(
    'BudgetV2 distribution SVG parses without a Flutter renderer error',
    (tester) async {
      Object? renderError;
      final donut = BudgetV2FluviSvg.flutterRenderable(
        BudgetV2FluviSvg.clayDonut(
          slices: const <BudgetV2FluviDonutSlice>[
            BudgetV2FluviDonutSlice(
              label: 'Élelmiszer',
              value: 60,
              color: Color(0xFF22C55E),
            ),
            BudgetV2FluviDonutSlice(
              label: 'Lakás',
              value: 30,
              color: Color(0xFF60A5FA),
            ),
            BudgetV2FluviDonutSlice(
              label: 'Rezsi',
              value: 10,
              color: Color(0xFFA855F7),
            ),
          ],
          selectedIndex: 0,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 90,
            height: 90,
            child: SvgPicture.string(
              donut,
              errorBuilder: (_, error, _) {
                renderError = error;
                return const Text('distribution-render-error');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(renderError, isNull);
      expect(find.text('distribution-render-error'), findsNothing);
    },
  );

  testWidgets('BudgetV2 keeps the Balance shell and mounts B3M-B islands', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 892)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendeeBalanceDashboard(
            presentation: SpendeeBalancePresentation.budgetV2,
            input: _input(),
            budgetV2Bars: _bars,
            brand: const SizedBox(width: 300, height: 60),
            transactionLogBuilder: (_, _) => const SizedBox(
              width: 378,
              height: 300,
              key: ValueKey('budget-v2-test-log'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(SpendeeDashboardMode.budgetV2.usesBalanceShell, isTrue);
    expect(
      tester.getRect(find.byKey(const ValueKey('spendee-balance-hero'))),
      const Rect.fromLTWH(17, 104, 378, 126),
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-belt')),
      ),
      const Rect.fromLTWH(17, 241, 378, 80),
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey('spendee-budget-v2-mother-card')),
      ),
      const Rect.fromLTWH(17, 332, 378, 210),
    );
    expect(find.text('Limit állása'), findsOneWidget);
    expect(find.text('Heti ritmus'), findsOneWidget);
    expect(find.text('Kategóriák eloszlása'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-limit-edit')),
      findsOneWidget,
    );
    expect(find.byType(CategorySlotIcon), findsWidgets);
    for (final key in const <ValueKey<String>>[
      ValueKey<String>('spendee-budget-v2-avatar-svg-budget-v2-1'),
      ValueKey<String>('spendee-budget-v2-avatar-svg-budget-v2-2'),
      ValueKey<String>('spendee-budget-v2-avatar-svg-budget-v2-3'),
      ValueKey<String>('spendee-budget-v2-avatar-svg-budget-v2-4'),
      ValueKey<String>('spendee-budget-v2-avatar-svg-budget-v2-5'),
      ValueKey<String>('spendee-budget-v2-limit-circle'),
      ValueKey<String>('spendee-budget-v2-weekly-rhythm'),
      ValueKey<String>('spendee-budget-v2-clay-donut'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }

    final avatarBelt = find.byKey(
      const ValueKey('spendee-budget-v2-avatar-belt'),
    );
    final coloredAncestors = <Color>[];
    tester.element(avatarBelt).visitAncestorElements((element) {
      final widget = element.widget;
      if (widget case ColoredBox(:final color)) coloredAncestors.add(color);
      if (widget case DecoratedBox(decoration: BoxDecoration(:final color))) {
        if (color != null) coloredAncestors.add(color);
      }
      return true;
    });
    expect(
      coloredAncestors.where(
        (color) => color.a > 0 && color != const Color(0xFFF1F5F9),
      ),
      isEmpty,
    );

    await tester.drag(avatarBelt, const Offset(-180, 0));
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-avatar-belt')),
      findsOneWidget,
    );
  });

  testWidgets(
    'BudgetV2 enlarges only the selected category-distribution slice',
    (tester) async {
      final selectedTravelFirst = <CategoryBudgetBarData>[
        _bars[1],
        _bars[0],
        ..._bars.skip(2),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              // The selected avatar starts as Közlekedés, while Élelmiszer
              // has the largest proportional slice. This makes an accidental
              // "also highlight index zero" implementation observable.
              budgetV2Bars: selectedTravelFirst,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final picture = tester.widget<SvgPicture>(
        find.byKey(const ValueKey('spendee-budget-v2-clay-donut')),
      );
      final svg = (picture.bytesLoader as SvgStringLoader).provideSvg(null);

      expect(svg, contains('>Közlekedés</text>'));
      expect(
        RegExp('data-fluvi-donut-highlighted="true"').allMatches(svg).length,
        2,
      );
      expect(
        RegExp('data-fluvi-donut-selected="true"').allMatches(svg).length,
        2,
      );
    },
  );

  test('BudgetV2 uses the further-reduced active donut-slice radius', () {
    final donut = BudgetV2FluviSvg.clayDonut(
      slices: const <BudgetV2FluviDonutSlice>[
        BudgetV2FluviDonutSlice(
          label: 'Élelmiszer',
          value: 60,
          color: Color(0xFF22C55E),
        ),
        BudgetV2FluviDonutSlice(
          label: 'Közlekedés',
          value: 40,
          color: Color(0xFF4B92FF),
        ),
      ],
      selectedIndex: 1,
    );

    expect(donut, contains('A 160.38 160.38'));
    expect(donut, isNot(contains('A 178.2 178.2')));
    expect(
      RegExp('data-fluvi-donut-selected="true"').allMatches(donut).length,
      2,
    );
  });

  testWidgets(
    'BudgetV2 mother-card swipes through readable pages, reserves dot space and keeps its page on category selection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              budgetV2Bars: _bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      final limitCircle = find.byKey(
        const ValueKey('spendee-budget-v2-limit-circle'),
      );
      expect(motherCard, findsOneWidget);
      expect(limitCircle, findsOneWidget);
      expect(tester.getSize(motherCard).height, 210);
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('spendee-budget-v2-mother-card-surface'),
              ),
            )
            .height,
        200,
      );
      for (var index = 0; index < 4; index += 1) {
        expect(
          find.byKey(ValueKey('spendee-budget-v2-mother-card-dot-$index')),
          findsOneWidget,
        );
      }

      // The edit control belongs to the heading, not to the mother-card
      // background. It may enter its own editing state but must never open
      // the distribution alternative.
      final edit = find.byKey(const ValueKey('spendee-budget-v2-limit-edit'));
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-limit-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-distribution-overview')),
        findsNothing,
      );
      await tester.tap(edit);
      await tester.pumpAndSettle();

      // An inner island keeps its own tap target; it must never open the
      // alternative card through the surrounding mother-card background.
      await tester.tap(limitCircle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-distribution-overview')),
        findsNothing,
      );

      // Page changes are a single swipe-tick-slide carousel. Card controls
      // therefore remain free for their own taps.
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();

      final overview = find.byKey(
        const ValueKey('spendee-budget-v2-distribution-overview'),
      );
      final overviewDonut = find.byKey(
        const ValueKey('spendee-budget-v2-overview-clay-donut'),
      );
      expect(overview, findsOneWidget);
      expect(overviewDonut, findsOneWidget);
      // The 23px shared compact heading is now the source size for both
      // readable cards. Its room comes from the chart, never by increasing
      // the fixed 200px page or shifting downstream Balance content.
      expect(tester.getSize(overviewDonut).height, 150);
      final distributionTitle = find.text('Kategóriák eloszlása');
      expect(distributionTitle, findsOneWidget);
      expect(
        tester.getTopLeft(distributionTitle).dx,
        lessThan(tester.getCenter(motherCard).dx),
      );
      final overviewLegendTitle = tester.widget<Text>(
        find.descendant(
          of: find.byKey(
            const ValueKey('spendee-budget-v2-overview-legend-budget-v2-1'),
          ),
          matching: find.text('Élelmiszer'),
        ),
      );
      expect(overviewLegendTitle.style?.fontSize, 9);
      for (final bar in _bars) {
        expect(
          find.byKey(
            ValueKey<String>('spendee-budget-v2-overview-legend-${bar.key}'),
          ),
          findsOneWidget,
        );
      }

      final picture = tester.widget<SvgPicture>(overviewDonut);
      final svg = (picture.bytesLoader as SvgStringLoader).provideSvg(null);
      expect(svg, contains('data-value="63240"'));
      expect(svg, contains('data-value="31700"'));
      expect(svg, contains('>Élelmiszer</text>'));

      // The selected-avatar change must feed the same readable page; it may
      // update its data but must not recreate the mother card at page zero.
      await tester.tap(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-budget-v2-2')),
      );
      await tester.pumpAndSettle();
      expect(overview, findsOneWidget);
      final switchedPicture = tester.widget<SvgPicture>(overviewDonut);
      final switchedSvg = (switchedPicture.bytesLoader as SvgStringLoader)
          .provideSvg(null);
      expect(switchedSvg, contains('>Közlekedés</text>'));

      // Page three retains the mother-card geometry but gives the active
      // category's live native ring, current limit/editing control and rhythm
      // their own readable allocation.
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      final details = find.byKey(
        const ValueKey('spendee-budget-v2-limit-details-page'),
      );
      expect(details, findsOneWidget);
      final detailsRing = find.descendant(
        of: details,
        matching: find.byKey(const ValueKey('spendee-budget-v2-limit-circle')),
      );
      expect(detailsRing, findsOneWidget);
      expect(tester.getSize(detailsRing).width, greaterThanOrEqualTo(100));
      expect(
        find.descendant(
          of: details,
          matching: find.byKey(const ValueKey('spendee-budget-v2-limit-edit')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: details,
          matching: find.byKey(
            const ValueKey('spendee-budget-v2-weekly-rhythm'),
          ),
        ),
        findsOneWidget,
      );
      final nestedLimitDetailPanels = find.descendant(
        of: details,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! DecoratedBox) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == const Color(0xBDFFFFFF);
        }),
      );
      expect(nestedLimitDetailPanels, findsNothing);
    },
  );

  testWidgets(
    'BudgetV2 fourth mother-card page renders the filtered vendor distribution from real records',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _inputWithVendorDistribution(),
              budgetV2Bars: _bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      // compact → category distribution → limit details → vendor
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }

      expect(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-distribution-overview'),
        ),
        findsOneWidget,
      );
      expect(find.text('Vendorok eloszlása'), findsOneWidget);
      final donut = tester.widget<SvgPicture>(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-clay-donut'),
        ),
      );
      final svg = (donut.bytesLoader as SvgStringLoader).provideSvg(null);
      expect(svg, contains('data-label="Lidl"'));
      expect(svg, contains('data-value="850"'));
      expect(svg, isNot(contains('data-label="MOL"')));
      expect(svg, isNot(contains('data-label="BKK"')));
    },
  );

  testWidgets(
    'BudgetV2 overview avatar keeps the unfiltered vendor distribution',
    (tester) async {
      final input = _inputWithVendorDistribution();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: input,
              budgetV2Bars: BudgetV2FrameData.fromInput(input).bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }
      final donut = tester.widget<SvgPicture>(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-clay-donut'),
        ),
      );
      final svg = (donut.bytesLoader as SvgStringLoader).provideSvg(null);
      expect(svg, contains('data-label="MOL"'));
      expect(svg, contains('data-label="Lidl"'));
      expect(svg, contains('data-label="BKK"'));
    },
  );

  testWidgets(
    'BudgetV2 retains every category in a dot-free fixed-height expanded avatar rail',
    (tester) async {
      final bars = <CategoryBudgetBarData>[
        ..._bars,
        _unlimitedBar(_clothing, spent: 6400),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              budgetV2Bars: bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('spendee-budget-v2-avatar-dot-5')),
        findsNothing,
      );
      final belt = tester.widget<SizedBox>(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-belt')),
      );
      expect(belt.height, 80);
      final ticker = tester.widget<SpendeeBalanceTickingViewport>(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-ticker')),
      );
      expect(ticker.height, 72);
      expect(ticker.itemSizeBuilder(0, true), const Size(72, 72));
    },
  );

  testWidgets('BudgetV2 selected limit orb waits for the controller tick', (
    tester,
  ) async {
    final settled = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendeeBudgetV2AvatarBelt(
            bars: <CategoryBudgetBarData>[
              ..._bars,
              _bar(_food, key: 'budget-v2-6', spent: 7200, limit: 24000),
            ],
            selectedIndex: 0,
            onSettled: settled.add,
          ),
        ),
      ),
    );
    await tester.pump();

    final ticker = find.byKey(
      const ValueKey('spendee-budget-v2-avatar-ticker'),
    );
    final gesture = await tester.startGesture(tester.getCenter(ticker));
    DebugConsole.clear();
    // The first movement is consumed while Flutter resolves the horizontal
    // gesture arena. The remaining two moves are the actual 35px preview
    // and the boundary-crossing 28px travel.
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-35, 0));
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('spendee-budget-v2-avatar-limit-orb-budget-v2-2'),
      ),
      findsNothing,
      reason:
          'The orb must not switch merely because the incoming avatar is '
          'nearest; it switches on the same boundary as the tick.',
    );
    expect(
      DebugConsole.entries.where(
        (entry) => entry.contains('[BudgetV2Carousel] phase=preview'),
      ),
      isEmpty,
    );
    await gesture.moveBy(const Offset(-28, 0));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('spendee-budget-v2-avatar-limit-orb-budget-v2-2'),
      ),
      findsOneWidget,
    );
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (entry) =>
              entry.contains('[BudgetV2Carousel] phase=preview') &&
              entry.contains('key=budget-v2-2'),
        ),
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(settled, isNotEmpty);
  });

  testWidgets(
    'BudgetV2 avatar rail keeps direct tick previews local without chart delivery',
    (tester) async {
      final settled = <CategoryBudgetBarData>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              budgetV2Bars: _bars,
              onBudgetV2AvatarSettled: settled.add,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      DebugConsole.clear();
      await tester.timedDrag(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-ticker')),
        const Offset(-142, 0),
        const Duration(milliseconds: 260),
      );
      await tester.pumpAndSettle();

      final previews = DebugConsole.entries
          .where(
            (entry) =>
                entry.contains('[BudgetV2Carousel] phase=preview_local') &&
                entry.contains('commit=deferred'),
          )
          .toList(growable: false);
      expect(previews.length, greaterThanOrEqualTo(2));
      expect(
        DebugConsole.entries,
        isNot(
          contains(
            predicate<String>(
              (entry) =>
                  entry.contains('[BudgetV2Carousel] phase=chart_preview'),
            ),
          ),
        ),
        reason:
            'A physical avatar swipe must not rebuild the category/vendor '
            'SVGs per crossed slot. Remote chart requests keep their '
            'separate stepped preview path.',
      );
      expect(
        DebugConsole.entries.where(
          (entry) => entry.contains('[BudgetV2Chart] distribution '),
        ),
        hasLength(1),
        reason:
            'The category pie may refresh once for the final selection, not '
            'once for every physical slot tick.',
      );
      expect(
        DebugConsole.entries.where(
          (entry) => entry.contains('[BudgetV2Chart] vendor_distribution '),
        ),
        hasLength(1),
        reason:
            'The vendor pie may refresh once for the final selection, not '
            'once for every physical slot tick.',
      );
      expect(settled, hasLength(1));
      expect(
        DebugConsole.entries.where(
          (entry) => entry.contains('[BudgetV2Carousel] phase=settle'),
        ),
        hasLength(1),
      );
      expect(
        DebugConsole.entries.where(
          (entry) => entry.contains('[BudgetV2Carousel] phase=commit '),
        ),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'BudgetV2 category chart controls step the avatar and centre returns to overview',
    (tester) async {
      final settled = <CategoryBudgetBarData>[];
      final bars = <CategoryBudgetBarData>[
        BudgetV2FrameData.fromInput(_input()).bars.first,
        ..._bars,
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _input(),
              budgetV2Bars: bars,
              onBudgetV2AvatarSettled: settled.add,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();

      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();

      final donutInteraction = find.byKey(
        const ValueKey('spendee-budget-v2-overview-donut-interaction'),
      );
      await tester.tapAt(
        tester.getCenter(donutInteraction) + const Offset(0, -58),
      );
      await tester.pumpAndSettle();
      expect(settled.last.key, 'budget-v2-1');

      DebugConsole.clear();
      await tester.tap(
        find.byKey(
          const ValueKey('spendee-budget-v2-overview-legend-budget-v2-4'),
        ),
      );
      await tester.pumpAndSettle();
      final categoryPreviewSteps = DebugConsole.entries
          .where((entry) => entry.contains('[BudgetV2Chart] distribution '))
          .toList(growable: false);
      expect(
        categoryPreviewSteps,
        containsAllInOrder(<Matcher>[
          contains('selected=budget-v2-2'),
          contains('selected=budget-v2-3'),
          contains('selected=budget-v2-4'),
        ]),
        reason: DebugConsole.entries.join('\n'),
      );
      expect(settled.last.key, 'budget-v2-4');

      await tester.tap(donutInteraction, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(settled.last.targetType, LimitTargetType.overview);
    },
  );

  testWidgets(
    'BudgetV2 vendor chart highlights and publishes only its tertiary merchant',
    (tester) async {
      final vendors = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _inputWithVendorDistribution(),
              budgetV2Bars: _bars,
              onBudgetV2VendorSelected: vendors.add,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();
      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }
      final donutInteraction = find.byKey(
        const ValueKey('spendee-budget-v2-vendor-overview-donut-interaction'),
      );
      await tester.tapAt(
        tester.getCenter(donutInteraction) + const Offset(0, -58),
      );
      await tester.pump();
      expect(vendors, <String>['Lidl']);
      await tester.tap(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-legend-lidl'),
        ),
      );
      await tester.pump();
      expect(vendors, <String>['Lidl', 'Lidl']);
      expect(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-legend-lidl'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BudgetV2 vendor pie previews every avatar tick before the final avatar settlement',
    (tester) async {
      final settled = <CategoryBudgetBarData>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _inputWithVendorDistribution(),
              budgetV2Bars: _bars,
              onBudgetV2AvatarSettled: settled.add,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();
      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }

      DebugConsole.clear();
      await tester.tap(
        find.byKey(const ValueKey('spendee-budget-v2-avatar-budget-v2-3')),
      );
      await tester.pumpAndSettle();

      final vendorPreviewSteps = DebugConsole.entries
          .where(
            (entry) => entry.contains('[BudgetV2Chart] vendor_distribution '),
          )
          .toList(growable: false);
      expect(
        vendorPreviewSteps,
        containsAllInOrder(<Matcher>[
          contains('selected=budget-v2-2'),
          contains('selected=budget-v2-3'),
        ]),
        reason: DebugConsole.entries.join('\n'),
      );
      expect(settled, hasLength(1));
      expect(settled.single.key, 'budget-v2-3');
    },
  );

  test('BudgetV2 donut retains full colour for every category slice', () {
    final svg = BudgetV2FluviSvg.clayDonut(
      slices: <BudgetV2FluviDonutSlice>[
        BudgetV2FluviDonutSlice(
          label: _food.name,
          value: 70,
          color: _food.slotColor,
        ),
        BudgetV2FluviDonutSlice(
          label: _travel.name,
          value: 30,
          color: _travel.slotColor,
        ),
      ],
      selectedIndex: 0,
    );

    expect(svg, contains('fill="${_hexColor(_food.slotColor)}"'));
    expect(svg, contains('fill="${_hexColor(_travel.slotColor)}"'));
    expect(svg, isNot(contains('fill="#808080"')));
  });

  testWidgets(
    'BudgetV2 distribution titles share the compact card category marker',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _inputWithVendorDistribution(),
              budgetV2Bars: _bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();
      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );

      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('spendee-budget-v2-distribution-heading-marker'),
        ),
        findsOneWidget,
      );
      expect(find.text('Kategóriák eloszlása'), findsOneWidget);

      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-vendor-heading-marker')),
        findsOneWidget,
      );
      expect(find.text('Vendorok eloszlása'), findsOneWidget);
    },
  );

  testWidgets(
    'BudgetV2 vendor legend travels one entry at a time before filtering',
    (tester) async {
      final published = <String>[];
      final input = _inputWithVendorDistribution();
      final bars = BudgetV2FrameData.fromInput(input).bars;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: input,
              budgetV2Bars: bars,
              onBudgetV2VendorSelected: published.add,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();
      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }

      await tester.tap(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-legend-bkk'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-vendor-tick-lidl')),
        findsOneWidget,
      );
      expect(published, isEmpty);

      await tester.pumpAndSettle();
      expect(published, <String>['BKK']);
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-vendor-tick-bkk')),
        findsOneWidget,
      );
    },
  );

  testWidgets('BudgetV2 mounts through the real production home route', (
    tester,
  ) async {
    final store = createBalanceProductionStore(
      categories: <TransactionCategory>[_food, _travel],
      limits: <CategoryLimit>[
        _categoryLimit(1, 125000),
        _categoryLimit(2, 90000),
      ],
    );
    await pumpBalanceProductionHost(
      tester,
      store: store,
      dashboardMode: SpendeeDashboardMode.budgetV2,
      settle: false,
      recoverKnownDetailCardOverflows: true,
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.byKey(const ValueKey('spendee-budget-v2-header-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-avatar-belt')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-mother-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-search-row')),
      findsOneWidget,
    );
  });

  testWidgets(
    'BudgetV2 production expense belt includes the overview Budget avatar',
    (tester) async {
      await pumpBalanceProductionHost(
        tester,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-overview-expense_budget-all_time-all',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-svg-overview-expense_budget-all_time-all',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BudgetV2 avatar applies the primary category log query and vendor applies only the tertiary merchant query',
    (tester) async {
      final source = _inputWithVendorDistribution();
      final store = createBalanceProductionStore(
        transactions: source.transactions,
        categories: source.categories,
      );
      await pumpBalanceProductionHost(
        tester,
        store: store,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 30));

      // Budget avatar discs intentionally become interactive only after the
      // shared Balance header is expanded; this is the production gesture
      // path rather than calling the callback directly.
      await tester.drag(
        find.byKey(const ValueKey('spendee-balance-collapse-handle')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-category-1-expense-all_time-all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.activeCategoryIds, <int>{_food.transactionCategoryID});
      expect(store.activeMerchantFilters, isEmpty);
      expect(
        store.visibleTransactions
            .map((record) => record.transactionCategoryID)
            .toSet(),
        <int>{_food.transactionCategoryID},
      );

      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );
      for (var index = 0; index < 3; index += 1) {
        await _swipeBudgetV2MotherCard(tester, motherCard);
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(
          const ValueKey('spendee-budget-v2-vendor-overview-legend-lidl'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(store.activeCategoryIds, <int>{_food.transactionCategoryID});
      expect(store.activeMerchantFilters, <String>{'Lidl'});
      expect(
        store.visibleTransactions.map((record) => record.displayMerchant),
        everyElement('Lidl'),
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-category-2-expense-all_time-all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.activeCategoryIds, <int>{_travel.transactionCategoryID});
      expect(
        store.activeMerchantFilters,
        isEmpty,
        reason: 'a new avatar supersedes the prior tertiary vendor filter',
      );
      expect(
        store.visibleTransactions
            .map((record) => record.transactionCategoryID)
            .toSet(),
        <int>{_travel.transactionCategoryID},
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-overview-expense_budget-all_time-all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.activeCategoryIds, isEmpty);
      expect(store.activeMerchantFilters, isEmpty);
    },
  );

  testWidgets(
    'BudgetV2 production income resolves its own overview, category belt and mother card',
    (tester) async {
      final store = createBalanceProductionStore(
        categories: <TransactionCategory>[_incomeSalary, _incomeBonus],
        transactions: <TransactionRecord>[
          _recordForBudgetV2(
            id: 91,
            categoryId: _incomeSalary.transactionCategoryID,
            amount: 480000,
            merchant: 'Munkahely',
          ),
          _recordForBudgetV2(
            id: 92,
            categoryId: _incomeBonus.transactionCategoryID,
            amount: 75000,
            merchant: 'Projekt bónusz',
          ),
        ],
        limits: <CategoryLimit>[
          _limitForBudgetV2(
            id: 90,
            targetType: LimitTargetType.overview,
            targetId: 0,
            transactionType: TransactionType.income,
            amount: 600000,
          ),
          _limitForBudgetV2(
            id: 91,
            targetType: LimitTargetType.category,
            targetId: _incomeSalary.transactionCategoryID,
            transactionType: TransactionType.income,
            amount: 500000,
          ),
        ],
      );
      await store.start();
      store.setActiveType(TransactionType.income);

      await pumpBalanceProductionHost(
        tester,
        store: store,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-overview-income_goal-all_time-all',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-category-90-income-all_time-all',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-mother-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-limit-circle')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BudgetV2 selected avatar uses the coloured 3D limit orb and shared long-press editor',
    (tester) async {
      final store = createBalanceProductionStore(
        categories: <TransactionCategory>[_food, _travel],
        limits: <CategoryLimit>[
          _categoryLimit(_food.transactionCategoryID, 125000),
        ],
      );
      await pumpBalanceProductionHost(
        tester,
        store: store,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.drag(
        find.byKey(const ValueKey('spendee-balance-collapse-handle')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();

      final avatar = find.byKey(
        const ValueKey(
          'spendee-budget-v2-avatar-category-1-expense-all_time-all',
        ),
      );
      // Select the limited category first. Budget V2 must then replace the
      // old white outer halo with the source-aligned white 3D limit orb; its
      // live progress arc starts at the selected avatar's resolver colour.
      DebugConsole.clear();
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      // A normal tap travels through the belt's lightweight local preview
      // first; it must not accidentally close a non-existent limit session
      // and rebuild the full host before the one final settlement.
      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (entry) =>
                entry.contains('[BudgetV2Carousel] phase=preview') &&
                entry.contains('commit=deferred'),
          ),
        ),
      );
      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (entry) => entry.contains('[BudgetV2Carousel] phase=settle'),
          ),
        ),
      );
      expect(
        DebugConsole.entries,
        isNot(
          contains(
            predicate<String>(
              (entry) =>
                  entry.contains('[BudgetV2Limit] phase=cancel key=none'),
            ),
          ),
        ),
      );
      final orb = find.byKey(
        const ValueKey(
          'spendee-budget-v2-avatar-limit-orb-category-1-expense-all_time-all',
        ),
      );
      expect(orb, findsOneWidget);
      final orbScale = tester.widget<Transform>(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-limit-orb-scale-category-1-expense-all_time-all',
          ),
        ),
      );
      expect(orbScale.transform.storage[0], 1.25);
      expect(orbScale.transform.storage[5], 1.25);
      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-limit-halo-category-1-expense-all_time-all',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-limit-orb-core-category-1-expense-all_time-all',
          ),
        ),
        findsOneWidget,
      );
      final coreCenter = tester.widget<Transform>(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-limit-orb-core-center-category-1-expense-all_time-all',
          ),
        ),
      );
      expect(coreCenter.transform.storage[12], 0);
      expect(coreCenter.transform.storage[13], 0);
      final core = find.byKey(
        const ValueKey(
          'spendee-budget-v2-avatar-limit-orb-core-category-1-expense-all_time-all',
        ),
      );
      expect(tester.getSize(core), const Size(40, 40));
      final orbPaint = tester.widget<CustomPaint>(
        find.descendant(of: orb, matching: find.byType(CustomPaint)),
      );
      final orbPainter = orbPaint.painter! as BudgetV2LimitProgressPainter;
      expect(tester.getSize(orb), const Size(72, 72));
      expect(
        orbPainter.trackRadiusScale,
        BudgetV2LimitProgressPainter.selectedAvatarTrackRadiusScale,
      );
      expect(
        (orbPainter.trackRadius -
                BudgetV2LimitProgressPainter.sourceTrackRadius) *
            72 /
            BudgetV2LimitProgressPainter.sourceViewport.width *
            1.25,
        closeTo(3.37, .03),
        reason:
            'The selected avatar track needs a few extra physical pixels of '
            'clearance without modifying the normal mother-card ring.',
      );
      expect(
        orbPainter.startColor,
        CategoryColorResolver.color(category: _food),
      );

      final before = store.categoryBudgetBars
          .firstWhere((bar) => bar.targetId == _food.transactionCategoryID)
          .limitAmount;
      DebugConsole.clear();
      final gesture = await tester.startGesture(tester.getCenter(avatar));
      // Match the established production Budget gesture timing exactly: this
      // also leaves enough margin before the shared very-long-press clear.
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveBy(const Offset(0, -22));
      await tester.pump(const Duration(milliseconds: 90));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (entry) => entry.contains('[Perf] SpendeeTest budget_limit_tick'),
          ),
        ),
      );

      final after = store.categoryBudgetBars
          .firstWhere((bar) => bar.targetId == _food.transactionCategoryID)
          .limitAmount;
      expect(
        after,
        greaterThan(before),
        reason: DebugConsole.entries.join('\n'),
      );
    },
  );

  testWidgets(
    'BudgetV2 header tap opens the existing Budget avatar layout menu',
    (tester) async {
      await pumpBalanceProductionHost(
        tester,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));

      await tester.tap(
        find.byKey(const ValueKey('spendee-budget-v2-header-surface')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-avatar-layout-menu')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BudgetV2 readable distribution headings retain the compact marker scale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendeeBalanceDashboard(
              presentation: SpendeeBalancePresentation.budgetV2,
              input: _inputWithVendorDistribution(),
              budgetV2Bars: _bars,
              brand: const SizedBox(width: 300, height: 60),
              transactionLogBuilder: (_, _) =>
                  const SizedBox(width: 378, height: 300),
            ),
          ),
        ),
      );
      await tester.pump();
      final motherCard = find.byKey(
        const ValueKey('spendee-budget-v2-mother-card'),
      );

      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      final categoryMarker = tester.widget<BudgetV2CategoryMarker>(
        find.byKey(
          const ValueKey('spendee-budget-v2-distribution-heading-marker'),
        ),
      );
      expect(categoryMarker.size, 23);
      expect(categoryMarker.iconSize, 13);

      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
      final vendorMarker = tester.widget<BudgetV2CategoryMarker>(
        find.byKey(const ValueKey('spendee-budget-v2-vendor-heading-marker')),
      );
      expect(vendorMarker.size, 23);
      expect(vendorMarker.iconSize, 13);
    },
  );

  testWidgets('BudgetV2 vendor donut publishes its highlighted active slice', (
    tester,
  ) async {
    final input = _inputWithVendorDistribution();
    final bars = BudgetV2FrameData.fromInput(input).bars;
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendeeBalanceDashboard(
            presentation: SpendeeBalancePresentation.budgetV2,
            input: input,
            budgetV2Bars: bars,
            brand: const SizedBox(width: 300, height: 60),
            transactionLogBuilder: (_, _) =>
                const SizedBox(width: 378, height: 300),
          ),
        ),
      ),
    );
    await tester.pump();
    final motherCard = find.byKey(
      const ValueKey('spendee-budget-v2-mother-card'),
    );
    for (var index = 0; index < 3; index += 1) {
      await _swipeBudgetV2MotherCard(tester, motherCard);
      await tester.pumpAndSettle();
    }
    DebugConsole.clear();

    await tester.tap(
      find.byKey(
        const ValueKey('spendee-budget-v2-vendor-overview-legend-bkk'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (entry) =>
              entry.contains('[BudgetV2Chart] vendor_distribution') &&
              entry.contains('active_vendor=bkk') &&
              entry.contains('active_slice=true'),
        ),
      ),
    );
  });

  testWidgets(
    'BudgetV2 long-press lifecycle logs every boundary and releases input',
    (tester) async {
      final store = createBalanceProductionStore(
        categories: <TransactionCategory>[_food, _travel],
        limits: <CategoryLimit>[
          _categoryLimit(_food.transactionCategoryID, 125000),
        ],
      );
      await pumpBalanceProductionHost(
        tester,
        store: store,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.drag(
        find.byKey(const ValueKey('spendee-balance-collapse-handle')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();
      final avatar = find.byKey(
        const ValueKey(
          'spendee-budget-v2-avatar-category-1-expense-all_time-all',
        ),
      );
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      DebugConsole.clear();

      final gesture = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(const Duration(milliseconds: 650));
      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (entry) => entry.contains('[BudgetV2Limit] phase=start'),
          ),
        ),
      );
      DebugConsole.clear();
      await gesture.moveBy(const Offset(0, -22));
      await tester.pump(const Duration(milliseconds: 90));
      final entriesWhileHeld = List<String>.of(DebugConsole.entries);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        entriesWhileHeld,
        contains(
          predicate<String>(
            (entry) =>
                entry.contains('[BudgetV2Limit] phase=tick') &&
                entry.contains('persistence=release_only'),
          ),
        ),
        reason: entriesWhileHeld.join('\n'),
      );
      expect(
        entriesWhileHeld,
        isNot(
          contains(
            predicate<String>(
              (entry) => entry.contains('operation=balance-entry'),
            ),
          ),
        ),
        reason:
            'A held V2 limit tick must update only its local preview, never '
            'start a full Balance frame resolve.',
      );
      for (final phase in const <String>['move', 'end', 'release']) {
        expect(
          DebugConsole.entries,
          contains(
            predicate<String>(
              (entry) => entry.contains('[BudgetV2Limit] phase=$phase'),
            ),
          ),
          reason: DebugConsole.entries.join('\n'),
        );
      }
      // The editor must always release its recognizer after a completed
      // adjustment; a following ordinary avatar tap remains interactive.
      await tester.tap(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-category-2-expense-all_time-all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-limit-orb-category-2-expense-all_time-all',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BudgetV2 header avatar menu changes the selected V2 limit orb configuration',
    (tester) async {
      final store = createBalanceProductionStore(
        categories: <TransactionCategory>[_food, _travel],
        limits: <CategoryLimit>[
          _categoryLimit(_food.transactionCategoryID, 125000),
        ],
      );
      await pumpBalanceProductionHost(
        tester,
        store: store,
        dashboardMode: SpendeeDashboardMode.budgetV2,
        settle: false,
        recoverKnownDetailCardOverflows: true,
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.drag(
        find.byKey(const ValueKey('spendee-balance-collapse-handle')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'spendee-budget-v2-avatar-category-1-expense-all_time-all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('spendee-budget-v2-header-surface')),
      );
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(
        find.byKey(
          const ValueKey(
            'spendee-test-avatar-layout-progress-thickness-slider',
          ),
        ),
      );
      slider.onChanged!(.85);
      await tester.pumpAndSettle();

      DebugConsole.clear();
      tester
          .widget<Slider>(
            find.byKey(
              const ValueKey('spendee-test-avatar-layout-inner-size-slider'),
            ),
          )
          .onChanged!(.7);
      await tester.pump();
      tester
          .widget<Slider>(
            find.byKey(
              const ValueKey('spendee-test-avatar-layout-outer-size-slider'),
            ),
          )
          .onChanged!(-.6);
      await tester.pump();
      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (entry) =>
                entry.contains('[BudgetV2AvatarLayout] phase=menu_update') &&
                entry.contains('inner_size=0.70') &&
                entry.contains('outer_size=-0.60'),
          ),
        ),
        reason: DebugConsole.entries.join('\n'),
      );

      final orb = find.byKey(
        const ValueKey(
          'spendee-budget-v2-avatar-limit-orb-category-1-expense-all_time-all',
        ),
      );
      expect(orb, findsOneWidget);
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: orb, matching: find.byType(CustomPaint)),
      );
      final painter = paint.painter! as BudgetV2LimitProgressPainter;
      expect(
        painter.trackWidth,
        BudgetV2LimitProgressPainter.sourceTrackWidth *
            BudgetV2LimitProgressPainter.trackWidthScaleFor(.85),
      );
    },
  );

  testWidgets('header dropdown selects BudgetV2 on the production dashboard', (
    tester,
  ) async {
    final store = createBalanceProductionStore(
      categories: <TransactionCategory>[_food, _travel],
      limits: <CategoryLimit>[
        _categoryLimit(1, 125000),
        _categoryLimit(2, 90000),
      ],
    );
    await pumpBalanceProductionHost(
      tester,
      store: store,
      settle: false,
      recoverKnownDetailCardOverflows: true,
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    final budgetV2Item = find.byKey(
      const ValueKey('spendee-test-header-background-budget-v2'),
    );
    expect(budgetV2Item, findsOneWidget);
    await tester.tap(budgetV2Item);
    await tester.pump(const Duration(milliseconds: 40));

    expect(
      find.byKey(const ValueKey('spendee-budget-v2-header-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-mother-card')),
      findsOneWidget,
    );
  });
}

Future<void> _swipeBudgetV2MotherCard(
  WidgetTester tester,
  Finder motherCard,
) async {
  await tester.drag(motherCard, const Offset(-420, 0));
  await tester.pump(const Duration(milliseconds: 380));
}

final _food = TransactionCategory.fromMap(const <String, Object?>{
  'transactionCategoryID': 1,
  'name': 'Élelmiszer',
  'type': 'expense',
  'colorSlot': 7,
  'iconSlot': 3,
  'backgroundColor': '#ff4b78',
  'hasLimit': true,
  'limitAmount': 125000,
  'alertActive': true,
  'isCustomIcon': false,
});

final _travel = TransactionCategory.fromMap(const <String, Object?>{
  'transactionCategoryID': 2,
  'name': 'Közlekedés',
  'type': 'expense',
  'colorSlot': 3,
  'iconSlot': 5,
  'backgroundColor': '#4b92ff',
  'hasLimit': true,
  'limitAmount': 90000,
  'alertActive': true,
  'isCustomIcon': false,
});

final _clothing = TransactionCategory.fromMap(const <String, Object?>{
  'transactionCategoryID': 3,
  'name': 'Ruházat',
  'type': 'expense',
  'colorSlot': 5,
  'iconSlot': 8,
  'backgroundColor': '#f97316',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': false,
});

final _incomeSalary = TransactionCategory.fromMap(const <String, Object?>{
  'transactionCategoryID': 90,
  'name': 'Fizetés',
  'type': 'income',
  'colorSlot': 10,
  'iconSlot': 16,
  'backgroundColor': '#1bb7d2',
  'hasLimit': true,
  'limitAmount': 500000,
  'alertActive': true,
  'isCustomIcon': false,
});

final _incomeBonus = TransactionCategory.fromMap(const <String, Object?>{
  'transactionCategoryID': 91,
  'name': 'Bónusz',
  'type': 'income',
  'colorSlot': 16,
  'iconSlot': 18,
  'backgroundColor': '#8b45ed',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': false,
});

final List<CategoryBudgetBarData> _bars = <CategoryBudgetBarData>[
  _bar(_food, spent: 63240, limit: 125000),
  _bar(_travel, spent: 31700, limit: 90000),
  _bar(_food, key: 'budget-v2-3', spent: 18300, limit: 65000),
  _bar(_travel, key: 'budget-v2-4', spent: 11200, limit: 48000),
  _bar(_food, key: 'budget-v2-5', spent: 9600, limit: 32000),
];

CategoryBudgetBarData _bar(
  TransactionCategory category, {
  String? key,
  required double spent,
  required double limit,
}) => CategoryBudgetBarData(
  key: key ?? 'budget-v2-${category.transactionCategoryID}',
  targetType: LimitTargetType.category,
  targetId: category.transactionCategoryID,
  transactionType: TransactionType.expense,
  window: LimitWindow.monthly,
  periodKey: '2026-07',
  title: category.name,
  spent: spent,
  hasLimit: true,
  limitAmount: limit,
  alertActive: true,
  color: category.slotColor,
  iconSlot: category.iconSlot,
  category: category,
  sourceLimit: null,
);

CategoryBudgetBarData _unlimitedBar(
  TransactionCategory category, {
  required double spent,
}) => CategoryBudgetBarData(
  key: 'budget-v2-${category.transactionCategoryID}',
  targetType: LimitTargetType.category,
  targetId: category.transactionCategoryID,
  transactionType: TransactionType.expense,
  window: LimitWindow.monthly,
  periodKey: '2026-07',
  title: category.name,
  spent: spent,
  hasLimit: false,
  limitAmount: 0,
  alertActive: false,
  color: category.slotColor,
  iconSlot: category.iconSlot,
  category: category,
  sourceLimit: null,
);

BalanceFrameInput _input() => BalanceFrameInput(
  now: DateTime(2026, 7, 25),
  activeType: TransactionType.expense,
  summaryWindow: SummaryWindow.monthly,
  summaryReferenceDate: DateTime(2026, 7),
  transactions: const <TransactionRecord>[
    TransactionRecord(
      id: 1,
      date: '2026-07-25',
      time: '11:42',
      latitude: null,
      longitude: null,
      address: null,
      merchant: 'Lidl',
      amount: -63240,
      userAssignedName: null,
      transactionCategoryID: 1,
    ),
  ],
  recurringGhosts: const [],
  categories: <TransactionCategory>[_food, _travel],
  limits: const [],
);

BalanceFrameInput _inputWithVendorDistribution() => BalanceFrameInput(
  now: DateTime(2026, 7, 25),
  activeType: TransactionType.expense,
  summaryWindow: SummaryWindow.monthly,
  summaryReferenceDate: DateTime(2026, 7),
  transactions: <TransactionRecord>[
    _recordForBudgetV2(
      id: 601,
      categoryId: _food.transactionCategoryID,
      amount: -600,
      merchant: 'Lidl',
    ),
    _recordForBudgetV2(
      id: 602,
      categoryId: _food.transactionCategoryID,
      amount: -250,
      merchant: 'Lidl',
    ),
    _recordForBudgetV2(
      id: 603,
      categoryId: _travel.transactionCategoryID,
      amount: -1000,
      merchant: 'MOL',
    ),
    _recordForBudgetV2(
      id: 604,
      categoryId: _travel.transactionCategoryID,
      amount: -150,
      merchant: 'BKK',
    ),
    _recordForBudgetV2(
      id: 605,
      categoryId: _incomeSalary.transactionCategoryID,
      amount: 900,
      merchant: 'Kifizető',
    ),
  ],
  recurringGhosts: const [],
  categories: <TransactionCategory>[_food, _travel, _incomeSalary],
  limits: const [],
);

TransactionRecord _recordForBudgetV2({
  required int id,
  required int categoryId,
  required double amount,
  required String merchant,
}) => TransactionRecord(
  id: id,
  date: '2026-07-25',
  time: '11:42',
  latitude: null,
  longitude: null,
  address: null,
  merchant: merchant,
  amount: amount,
  userAssignedName: null,
  transactionCategoryID: categoryId,
);

CategoryLimit _limitForBudgetV2({
  required int id,
  required LimitTargetType targetType,
  required int targetId,
  required TransactionType transactionType,
  required double amount,
}) => CategoryLimit(
  id: id,
  targetType: targetType,
  targetId: targetId,
  transactionType: transactionType.nativeValue,
  window: LimitWindow.allTime,
  periodKey: 'all',
  hasLimit: true,
  limitAmount: amount,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

CategoryLimit _categoryLimit(int categoryId, double amount) => CategoryLimit(
  id: categoryId,
  targetType: LimitTargetType.category,
  targetId: categoryId,
  transactionType: 'expense',
  window: LimitWindow.monthly,
  periodKey: '2026-07',
  hasLimit: true,
  limitAmount: amount,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

Color _budgetV2CompanionColor(Color source) {
  final hsl = HSLColor.fromColor(source);
  return hsl
      .withHue((hsl.hue - 46 + 360) % 360)
      .withSaturation((hsl.saturation * .9).clamp(0, 1).toDouble())
      .withLightness((hsl.lightness * .92).clamp(0, 1).toDouble())
      .toColor();
}

String _hexColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
