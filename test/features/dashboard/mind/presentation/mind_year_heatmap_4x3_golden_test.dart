import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'VIS-4x3: direct Year field consumes its live vertical viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final frame = ValueNotifier(_frame());
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('mind-year-4x3-golden-boundary'),
              child: SizedBox(
                width: 430,
                height: 560,
                child: MindYearHeatmapViewport(frameListenable: frame),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-year-direct-month-12')),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(const ValueKey<String>('mind-year-4x3-golden-boundary')),
        matchesGoldenFile(
          '../../../../goldens/mind_year_heatmap_4x3_vertical_fill.png',
        ),
      );
    },
  );

  testWidgets(
    'VIS-4x3-SQUARE: the optional square field remains selector-free in its lower free region',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final frame = ValueNotifier(_frame());
      final settings = MindYearHeatmapPresentationController()
        ..setFourColumnCellStyle(MindYearFourColumnCellStyle.squareCells);
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>(
                'mind-year-4x3-square-golden-boundary',
              ),
              child: SizedBox(
                width: 430,
                height: 560,
                child: MindYearHeatmapViewport(
                  frameListenable: frame,
                  presentationSettings: settings,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('3×4'), findsNothing);
      expect(find.text('4×3'), findsNothing);
      expect(find.text('2×6'), findsNothing);
      await expectLater(
        find.byKey(
          const ValueKey<String>('mind-year-4x3-square-golden-boundary'),
        ),
        matchesGoldenFile(
          '../../../../goldens/mind_year_heatmap_4x3_square.png',
        ),
      );
    },
  );
}

MindYearHeatmapFrame _frame() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 100000,
    maximumScaled100: 1000000,
    lowerScaled100: 100000,
    upperScaled100: 1000000,
  );
  final aggregates = MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
    year: 2025,
    incomeEntries: <DashboardLedgerEntry>[
      _entry(
        'income-jan',
        480000,
        const LocalDate(year: 2025, month: 1, day: 2),
        'income',
      ),
      _entry(
        'income-mar',
        230000,
        const LocalDate(year: 2025, month: 3, day: 4),
        'income',
      ),
    ],
    expenseEntries: <DashboardLedgerEntry>[
      _entry(
        'expense-jan',
        120000,
        const LocalDate(year: 2025, month: 1, day: 3),
        'expense',
      ),
      _entry(
        'expense-feb',
        310000,
        const LocalDate(year: 2025, month: 2, day: 7),
        'expense',
      ),
      _entry(
        'expense-mar',
        230000,
        const LocalDate(year: 2025, month: 3, day: 9),
        'expense',
      ),
    ],
  );
  return MindYearHeatmapProjection.build(
    identity: const MindYearHeatmapIdentity(
      upstreamScopeKey: 'expense|year:2025',
      indexGeneration: 6,
      coreRevision: 6,
      year: 2025,
      navigationEpoch: 6,
    ),
    entries: <DashboardLedgerEntry>[
      _entry(
        'scope-jan',
        120000,
        const LocalDate(year: 2025, month: 1, day: 3),
        'expense',
      ),
      _entry(
        'scope-feb',
        310000,
        const LocalDate(year: 2025, month: 2, day: 7),
        'expense',
      ),
      _entry(
        'scope-mar',
        230000,
        const LocalDate(year: 2025, month: 3, day: 9),
        'expense',
      ),
    ],
    monthlyAggregates: aggregates,
  ).preview(range);
}

DashboardLedgerEntry _entry(
  String id,
  int amountMinor,
  LocalDate date,
  String direction,
) => DashboardLedgerEntry(
  id: id,
  partnerId: 'p',
  categoryId: 'c',
  direction: direction,
  amountMinor: amountMinor,
  bookedLocalEpochDay: date.epochDay,
  bookedLocalTimeMinutes: 0,
);
