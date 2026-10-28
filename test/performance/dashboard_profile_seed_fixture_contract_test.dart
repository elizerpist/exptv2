import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/demo_data/demo_seed_report.dart';

import '../../integration_test/support/dashboard_profile_seed_fixture_contract.dart';

void main() {
  test('defines the authoritative 2025–2027 profile seed contract', () {
    expect(
      DashboardProfileSeedFixtureContract.expectedSeededTransactionCount,
      5519,
    );
    expect(
      DashboardProfileSeedFixtureContract.expectedMonthsByYear,
      const <int, int>{2025: 12, 2026: 8, 2027: 12},
    );
    expect(DashboardProfileSeedFixtureContract.expectedTotalMonthCount, 32);
    expect(
      DashboardProfileSeedFixtureContract.expectedGhostOccurrenceCount,
      96,
    );
    expect(
      DashboardProfileSeedFixtureContract.expectedGhostLedgerEntryCount,
      48,
    );

    expect(
      () => DashboardProfileSeedFixtureContract.verify(_currentSeedReport()),
      returnsNormally,
    );
  });

  test('rejects a profile seed that omits a required fixture month', () {
    final incomplete = _currentSeedReport(
      months: _monthsFor(year: 2025, count: 12)
        ..removeLast()
        ..addAll(_monthsFor(year: 2026, count: 7)),
    );

    expect(
      () => DashboardProfileSeedFixtureContract.verify(incomplete),
      throwsA(isA<StateError>()),
    );
  });

  test('derives scenario density from the verified native monthly report', () {
    final fixture = DashboardProfileSeedFixtureContract.verifiedFixtureFor(
      _currentSeedReport(),
    );

    expect(fixture.incomeEntryCount(), 43);
    expect(fixture.incomeEntryCount(year: 2025), 12);
    expect(fixture.incomeEntryCount(year: 2026, month: 7), 2);
    expect(fixture.expenseEntryCount(), 1239);
    expect(fixture.expenseEntryCount(year: 2027), 112);
  });
}

DemoSeedReport _currentSeedReport({
  List<DemoMonthReport>? months,
}) => DemoSeedReport(
  seedVersion: 8,
  prngSeed: 20260107,
  createdCategoryCount: 10,
  createdPartnerCount: 27,
  createdEntryCount:
      DashboardProfileSeedFixtureContract.expectedSeededTransactionCount,
  monthlyReports:
      months ??
      <DemoMonthReport>[
        ..._monthsFor(year: 2025, count: 12),
        ..._monthsFor(year: 2026, count: 7),
        _september2026(),
        ..._fastfoodMonthsFor2027(),
      ],
  earliestEntryAtUtcMs: 1735686000000,
  latestEntryAtUtcMs: 1782777600000,
  alreadySeeded: false,
  durationMs: 0,
  ghostOccurrenceCount:
      DashboardProfileSeedFixtureContract.expectedGhostOccurrenceCount,
  ghostPendingOccurrenceCount:
      DashboardProfileSeedFixtureContract.expectedGhostPendingOccurrenceCount,
  ghostRealizedOccurrenceCount:
      DashboardProfileSeedFixtureContract.expectedGhostRealizedOccurrenceCount,
  ghostLedgerEntryCount:
      DashboardProfileSeedFixtureContract.expectedGhostLedgerEntryCount,
);

List<DemoMonthReport> _monthsFor({required int year, required int count}) =>
    List<DemoMonthReport>.generate(
      count,
      (index) => DemoMonthReport(
        year: year,
        month: index + 1,
        entryCount: 1,
        incomeCount: 1,
        expenseCount: 0,
        incomeTargetMinor: 1,
        expenseTargetMinor: 0,
        incomeTotalMinor: 1,
        expenseTotalMinor: 0,
      ),
    );

DemoMonthReport _september2026() => const DemoMonthReport(
  year: 2026,
  month: 9,
  entryCount: 1115,
  incomeCount: 0,
  expenseCount: 1115,
  incomeTargetMinor: 76825800,
  expenseTargetMinor: 76825800,
  incomeTotalMinor: 0,
  expenseTotalMinor: 76825800,
);

List<DemoMonthReport> _fastfoodMonthsFor2027() =>
    List<DemoMonthReport>.generate(
      12,
      (index) => DemoMonthReport(
        year: 2027,
        month: index + 1,
        entryCount: const <int>[16, 15, 14, 12, 8, 7, 8, 6, 3, 4, 3, 4][index],
        incomeCount: 0,
        expenseCount: const <int>[
          16,
          15,
          14,
          12,
          8,
          7,
          8,
          6,
          3,
          4,
          3,
          4,
        ][index],
        incomeTargetMinor: 0,
        expenseTargetMinor: 0,
        incomeTotalMinor: 0,
        expenseTotalMinor: 0,
      ),
    );
