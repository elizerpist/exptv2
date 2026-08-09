import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/demo_data/demo_seed_report.dart';

import '../../integration_test/support/dashboard_profile_seed_fixture_contract.dart';

void main() {
  test('defines the authoritative 2025 plus 2026 profile seed contract', () {
    expect(
      DashboardProfileSeedFixtureContract.expectedSeededTransactionCount,
      4304,
    );
    expect(
      DashboardProfileSeedFixtureContract.expectedMonthsByYear,
      const <int, int>{2025: 12, 2026: 7},
    );
    expect(DashboardProfileSeedFixtureContract.expectedTotalMonthCount, 19);

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
}

DemoSeedReport _currentSeedReport({List<DemoMonthReport>? months}) =>
    DemoSeedReport(
      seedVersion: 2,
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
          ],
      earliestEntryAtUtcMs: 1735686000000,
      latestEntryAtUtcMs: 1782777600000,
      alreadySeeded: false,
      durationMs: 0,
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
