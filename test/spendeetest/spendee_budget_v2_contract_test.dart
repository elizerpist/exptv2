import 'dart:io';

import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
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
      'fontSize: 7.4',
      'fontSize: 6.1',
      'fontSize: 9.5',
      'Color(0xFF25365C)',
      'Color(0xFF51617F)',
      'Color(0xFFE84CAE)',
      'width: 378',
      'height: 210',
    ]) {
      expect(implementation, contains(literal));
    }
  });

  test('BudgetV2 header preserves the real over-budget ratio', () {
    final summary = BudgetV2BudgetSummary.fromBars(<CategoryBudgetBarData>[
      _bar(_food, spent: 1500, limit: 1000),
    ]);

    expect(summary.percent, 150);
    expect(summary.remaining, -500);
  });

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
    expect(donut, contains('A 198 198 0 1 1'));
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

  testWidgets('BudgetV2 retains every supplied category in the avatar ticker', (
    tester,
  ) async {
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
      findsOneWidget,
    );
  });

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
