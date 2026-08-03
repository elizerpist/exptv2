import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_committed_query_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/logbox/presentation/dashboard_log_area.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

const _goldenSize = Size(390, 600);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> expectLogBoxGolden(
    WidgetTester tester,
    String name,
    DashboardLogAreaState state,
  ) async {
    await tester.binding.setSurfaceSize(_goldenSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xfff7f7fb),
          body: DashboardLogBoxViewport(
            state: state,
            onLoadNextPage: () {},
            onRetry: () {},
            onEntryTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard-logbox/$name.png'),
    );
  }

  testWidgets('golden: one day, one transaction', (tester) async {
    await expectLogBoxGolden(
      tester,
      'one-day-one-row',
      _data(
        groups: [
          _group(13, [_entry('coffee', partner: 'Kávézó')]),
        ],
      ),
    );
  });

  testWidgets('golden: one joined day with multiple transactions', (
    tester,
  ) async {
    await expectLogBoxGolden(
      tester,
      'one-day-multiple-rows',
      _data(
        groups: [
          _group(13, [
            _entry('coffee', partner: 'Kávézó'),
            _entry('tram', note: 'Villamos', amountMinor: 501489),
            _entry('market', partner: 'Piac', amountMinor: 330000),
          ]),
        ],
      ),
    );
  });

  testWidgets('golden: multiple day groups', (tester) async {
    await expectLogBoxGolden(
      tester,
      'multiple-days',
      _data(
        groups: [
          _group(14, [_entry('latest', partner: 'Legfrissebb')]),
          _group(13, [_entry('older', partner: 'Korábbi')]),
          _group(12, [_entry('oldest', partner: 'Régebbi')]),
        ],
      ),
    );
  });

  testWidgets('golden: long partner name', (tester) async {
    await expectLogBoxGolden(
      tester,
      'long-partner-name',
      _data(
        groups: [
          _group(13, [
            _entry(
              'long-name',
              partner: 'Budapesti Közlekedési Központ ügyfélszolgálat',
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('golden: large amount', (tester) async {
    await expectLogBoxGolden(
      tester,
      'large-amount',
      _data(
        groups: [
          _group(13, [
            _entry('large', partner: 'Nagy összeg', amountMinor: 493800000),
          ]),
        ],
      ),
    );
  });

  testWidgets('golden: income and expense rows', (tester) async {
    await expectLogBoxGolden(
      tester,
      'income-and-expense',
      _data(
        groups: [
          _group(13, [
            _entry('income', partner: 'Fizetés', direction: 'income'),
            _entry('expense', partner: 'Ebéd', direction: 'expense'),
          ]),
        ],
      ),
    );
  });

  testWidgets('golden: uncategorized fallback avatar', (tester) async {
    await expectLogBoxGolden(
      tester,
      'fallback-avatar',
      _data(
        groups: [
          _group(13, [
            _entry(
              'fallback',
              categoryColorId: 'unknown-color',
              categoryIconId: 'unknown-icon',
              categoryDisplayName: null,
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('golden: loading state', (tester) async {
    await expectLogBoxGolden(
      tester,
      'loading',
      DashboardLogInitialLoading(queryKey: _scope.key.value),
    );
  });

  testWidgets('golden: empty state', (tester) async {
    await expectLogBoxGolden(
      tester,
      'empty',
      DashboardLogEmpty(snapshot: _snapshot(entryCount: 0), cacheHit: false),
    );
  });

  testWidgets('golden: next page loading footer', (tester) async {
    await expectLogBoxGolden(
      tester,
      'next-page-loading',
      _data(
        groups: [
          _group(13, [_entry('coffee', partner: 'Kávézó')]),
        ],
        isLoadingNextPage: true,
        nextCursor: const DashboardDayGroupPageCursor(
          beforeLocalDateExclusive: LocalDate(year: 2026, month: 3, day: 13),
        ),
      ),
    );
  });
}

final _scope = CurrentLedgerQueryScope(
  direction: LedgerDirection.expense,
  timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
);

DashboardLogData _data({
  required List<DashboardDayLogGroup> groups,
  DashboardDayGroupPageCursor? nextCursor,
  bool isLoadingNextPage = false,
}) => DashboardLogData(
  snapshot: _snapshot(
    entryCount: groups.fold(0, (sum, group) => sum + group.rows.length),
  ),
  groups: groups,
  nextCursor: nextCursor,
  isLoadingNextPage: isLoadingNextPage,
  isStale: false,
  cacheHit: true,
);

DashboardCommittedQuerySnapshot _snapshot({required int entryCount}) =>
    DashboardCommittedQuerySnapshot.fromResult(
      scope: _scope,
      result: DashboardLedgerResult(
        totalMinor: 901489,
        entryCount: entryCount,
        scopeKey: _scope.key.value,
        timeScopeKey: _scope.timeScope.canonicalKey,
        direction: _scope.direction.name,
        coreRevision: 12,
      ),
    );

DashboardDayLogGroup _group(int day, List<DashboardLedgerEntry> rows) =>
    DashboardDayLogGroup(
      localDate: LocalDate(year: 2026, month: 3, day: day),
      rows: rows,
    );

DashboardLedgerEntry _entry(
  String id, {
  String? partner,
  String? note,
  String? direction,
  int amountMinor = 400000,
  String? categoryColorId = 'color_01',
  String? categoryIconId = 'food',
  String? categoryDisplayName = 'Étkezés',
}) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  partnerDisplayName: partner,
  categoryId: 'category-$id',
  categoryDisplayName: categoryDisplayName,
  categoryColorId: categoryColorId,
  categoryIconId: categoryIconId,
  direction: direction ?? 'expense',
  amountMinor: amountMinor,
  bookedLocalEpochDay: 20525,
  bookedLocalTimeMinutes: 720,
  note: note,
);
