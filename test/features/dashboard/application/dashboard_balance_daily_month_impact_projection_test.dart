import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

const identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'month-impact-filter',
  indexGeneration: 3,
  coreRevision: 7,
);
const selected = LocalDate(year: 2026, month: 7, day: 16);
DashboardLedgerEntry entry(LocalDate date, int amount, {int minute = 720}) =>
    DashboardLedgerEntry(
      id: '${date.isoString}-$amount-$minute',
      partnerId: 'p',
      categoryId: 'c',
      direction: 'unused-by-directional-prepared-membership',
      amountMinor: amount,
      bookedLocalEpochDay: date.epochDay,
      bookedLocalTimeMinutes: minute,
    );
DashboardBalanceDailyInsightsPresentation build({
  LocalDate date = selected,
  LocalDate? now,
  int minute = 720,
  List<DashboardLedgerEntry> income = const [],
  List<DashboardLedgerEntry> expense = const [],
}) => DashboardBalanceDailyInsightsProjection.build(
  identity: identity,
  timeScope: DayScope(date),
  logicalAsOfDate: now ?? date,
  logicalAsOfLocalTimeMinutes: minute,
  incomeEntries: income,
  expenseEntries: expense,
);

void main() {
  for (final fixture in [
    (10000, 7000, 0, 400, 30.0, 26.0, -4.0),
    (10000, 11200, 5000, 2600, -12.0, 8.0, 20.0),
    (10000, 9500, 0, 800, 5.0, -3.0, -8.0),
    (10000, 12500, 10000, 10500, -25.0, -15.0, 10.0),
  ]) {
    test(
      'prepared monthly ratio ${fixture.$5} to ${fixture.$6} gives ${fixture.$7} percentage points',
      () {
        final result = build(
          income: [
            entry(const LocalDate(year: 2026, month: 7, day: 1), fixture.$1),
            entry(selected, fixture.$3),
          ],
          expense: [
            entry(const LocalDate(year: 2026, month: 7, day: 1), fixture.$2),
            entry(selected, fixture.$4),
          ],
        );
        final impact = result.monthImpact!;
        expect(
          result.momentum.available,
          isFalse,
          reason: 'New monthly metric has no 119-day coverage requirement',
        );
        expect(impact.selectedEpochDay, selected.epochDay);
        expect(impact.isAvailable, isTrue);
        expect(impact.incomeBeforeMinor, fixture.$1);
        expect(impact.expenseBeforeMinor, fixture.$2);
        expect(impact.incomeAfterMinor, fixture.$1 + fixture.$3);
        expect(impact.expenseAfterMinor, fixture.$2 + fixture.$4);
        expect(impact.ratioBeforePercent, closeTo(fixture.$5, 1e-10));
        expect(impact.ratioAfterPercent, closeTo(fixture.$6, 1e-10));
        expect(impact.dailyImpactPp, closeTo(fixture.$7, 1e-10));
      },
    );
  }
  test(
    'undefined zero-income states remain nullable and do not invent a baseline',
    () {
      final none = build().monthImpact!;
      expect(none.available, isFalse);
      expect(none.ratioBeforePercent, isNull);
      expect(none.ratioAfterPercent, isNull);
      expect(none.dailyImpactPp, isNull);
      final expenseOnly = build(expense: [entry(selected, 500)]).monthImpact!;
      expect(expenseOnly.expenseAfterMinor, 500);
      expect(expenseOnly.ratioAfterPercent, isNull);
      final firstIncome = build(income: [entry(selected, 1000)]).monthImpact!;
      expect(firstIncome.ratioBeforePercent, isNull);
      expect(firstIncome.ratioAfterPercent, 100);
      expect(firstIncome.dailyImpactPp, isNull);
      final zero = build(
        income: [entry(const LocalDate(year: 2026, month: 7, day: 1), 1000)],
        expense: [entry(const LocalDate(year: 2026, month: 7, day: 1), 1000)],
      ).monthImpact!;
      expect(zero.ratioBeforePercent, 0);
      expect(zero.ratioAfterPercent, 0);
      expect(zero.dailyImpactPp, 0);
      expect(zero.available, isTrue);
    },
  );
  test(
    'full precision is preserved and payload invalidates parent publication identity',
    () {
      final result = build(
        income: [
          entry(const LocalDate(year: 2026, month: 7, day: 1), 3),
          entry(selected, 4),
        ],
        expense: [
          entry(const LocalDate(year: 2026, month: 7, day: 1), 1),
          entry(selected, 2),
        ],
      );
      expect(result.monthImpact!.ratioBeforePercent, closeTo(200 / 3, 1e-12));
      expect(result.monthImpact!.ratioAfterPercent, closeTo(400 / 7, 1e-12));
      expect(
        result.monthImpact!.dailyImpactPp,
        closeTo(400 / 7 - 200 / 3, 1e-12),
      );
      final old = DashboardBalanceDailyInsightsPresentation(
        identity: result.identity,
        timeScope: result.timeScope,
        momentum: result.momentum,
        impact: result.impact,
      );
      expect(old.monthImpact, isNull);
      expect(old.presentationId, isNot(result.presentationId));
    },
  );
  test(
    'today applies cutoff only at selected day, not legacy matched D-30',
    () {
      const today = LocalDate(year: 2026, month: 7, day: 31);
      const first = LocalDate(year: 2026, month: 7, day: 1);
      final result = build(
        date: today,
        minute: 720,
        income: [
          entry(first, 1000, minute: 1200),
          entry(today, 500, minute: 720),
          entry(today, 700, minute: 721),
        ],
        expense: [
          entry(first, 200, minute: 1200),
          entry(today, 100, minute: 719),
          entry(today, 900, minute: 721),
        ],
      ).monthImpact!;
      expect(result.incomeBeforeMinor, 1000);
      expect(result.expenseBeforeMinor, 200);
      expect(result.incomeAfterMinor, 1500);
      expect(result.expenseAfterMinor, 300);
      expect(result.ratioBeforePercent, 80);
      expect(result.ratioAfterPercent, 80);
      expect(result.dailyImpactPp, 0);
    },
  );
  test(
    'past selected days use complete day even after the canonical minute',
    () {
      final result = build(
        now: const LocalDate(year: 2026, month: 7, day: 17),
        minute: 1,
        income: [
          entry(const LocalDate(year: 2026, month: 7, day: 1), 1000),
          entry(selected, 1000, minute: 1439),
        ],
        expense: [entry(selected, 500, minute: 1439)],
      ).monthImpact!;
      expect(result.incomeAfterMinor, 2000);
      expect(result.expenseAfterMinor, 500);
      expect(result.ratioAfterPercent, 75);
      expect(result.dailyImpactPp, -25);
    },
  );
  test(
    'future selected date is unavailable and future transactions never leak in',
    () {
      final future = build(
        now: const LocalDate(year: 2026, month: 7, day: 15),
        income: [entry(selected, 1000)],
      ).monthImpact!;
      expect(future.available, isFalse);
      expect(future.incomeAfterMinor, 0);
      expect(future.dailyImpactPp, isNull);
      final result = build(
        income: [
          entry(const LocalDate(year: 2026, month: 6, day: 30), 999999),
          entry(const LocalDate(year: 2026, month: 7, day: 1), 1000),
          entry(const LocalDate(year: 2026, month: 7, day: 17), 999999),
          entry(const LocalDate(year: 2026, month: 8, day: 1), 999999),
        ],
      ).monthImpact!;
      expect(result.incomeBeforeMinor, 1000);
      expect(result.incomeAfterMinor, 1000);
    },
  );
  for (final date in [
    const LocalDate(year: 2024, month: 2, day: 29),
    const LocalDate(year: 2026, month: 4, day: 30),
    const LocalDate(year: 2026, month: 12, day: 31),
    const LocalDate(year: 2027, month: 1, day: 1),
  ]) {
    test(
      'own-month boundaries at $date do not inherit other months or years',
      () {
        final start = LocalDate(year: date.year, month: date.month, day: 1);
        final previous = DateTime.utc(
          date.year,
          date.month,
          1,
        ).subtract(const Duration(days: 1));
        final result = build(
          date: date,
          income: [
            entry(
              LocalDate(
                year: previous.year,
                month: previous.month,
                day: previous.day,
              ),
              999999,
            ),
            entry(start, 1000),
          ],
          expense: [entry(date, 200)],
        ).monthImpact!;
        expect(result.incomeAfterMinor, 1000);
        expect(result.expenseAfterMinor, 200);
        expect(result.incomeBeforeMinor, date.day == 1 ? 0 : 1000);
        expect(result.ratioAfterPercent, 80);
        expect(result.dailyImpactPp, date.day == 1 ? isNull : -20);
      },
    );
  }
}
