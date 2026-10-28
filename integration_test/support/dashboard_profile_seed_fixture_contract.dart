import 'package:fluvi/core/demo_data/demo_seed_report.dart';

/// Authoritative profile-fixture contract shared by the automated harness and
/// its focused unit test. Keep the native generator's 2025 dense year, 2026
/// rail fixture, and exact 2027 Fastfood mirror explicit here instead of
/// scattering counts.
abstract final class DashboardProfileSeedFixtureContract {
  static const int expectedSeededTransactionCount = 5519;
  static const int expectedGhostOccurrenceCount = 96;
  static const int expectedGhostPendingOccurrenceCount = 48;
  static const int expectedGhostRealizedOccurrenceCount = 48;
  static const int expectedGhostLedgerEntryCount = 48;
  static const int _ghostStartYear = 2026;
  static const int _ghostEndYear = 2027;
  static const int _ghostDirectionCount = 2;
  static const Map<int, int> expectedMonthsByYear = <int, int>{
    2025: 12,
    2026: 8,
    2027: 12,
  };

  static int get expectedTotalMonthCount =>
      expectedMonthsByYear.values.fold(0, (total, count) => total + count);

  static void verify(DemoSeedReport report) {
    if (report.createdEntryCount != expectedSeededTransactionCount) {
      throw StateError(
        'Profile seed created ${report.createdEntryCount} transactions; '
        'expected $expectedSeededTransactionCount.',
      );
    }
    if (report.ghostOccurrenceCount != expectedGhostOccurrenceCount ||
        report.ghostPendingOccurrenceCount !=
            expectedGhostPendingOccurrenceCount ||
        report.ghostRealizedOccurrenceCount !=
            expectedGhostRealizedOccurrenceCount ||
        report.ghostLedgerEntryCount != expectedGhostLedgerEntryCount) {
      throw StateError(
        'Profile ghost fixture was ${report.ghostOccurrenceCount}/'
        '${report.ghostPendingOccurrenceCount}/'
        '${report.ghostRealizedOccurrenceCount}/'
        '${report.ghostLedgerEntryCount}; expected '
        '$expectedGhostOccurrenceCount/'
        '$expectedGhostPendingOccurrenceCount/'
        '$expectedGhostRealizedOccurrenceCount/'
        '$expectedGhostLedgerEntryCount.',
      );
    }
    if (report.monthlyReports.length != expectedTotalMonthCount) {
      throw StateError(
        'Profile seed returned ${report.monthlyReports.length} months; '
        'expected $expectedTotalMonthCount.',
      );
    }
    final actualMonthsByYear = <int, int>{};
    for (final month in report.monthlyReports) {
      actualMonthsByYear.update(
        month.year,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    if (!_sameCounts(actualMonthsByYear, expectedMonthsByYear)) {
      throw StateError(
        'Profile seed month coverage was $actualMonthsByYear; '
        'expected $expectedMonthsByYear.',
      );
    }
  }

  /// Derives every profile density assertion from the one native seed report.
  /// The profile must not carry a parallel, stale set of aggregate counts.
  static DashboardProfileSeedFixture verifiedFixtureFor(DemoSeedReport report) {
    verify(report);
    return DashboardProfileSeedFixture._(
      report.monthlyReports,
      ghostBookedRowsPerDirectionMonth:
          report.ghostRealizedOccurrenceCount ~/
          ((_ghostEndYear - _ghostStartYear + 1) * 12 * _ghostDirectionCount),
    );
  }

  static bool _sameCounts(Map<int, int> actual, Map<int, int> expected) {
    if (actual.length != expected.length) return false;
    for (final entry in expected.entries) {
      if (actual[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Immutable, report-derived aggregate counts for profile scenarios.
final class DashboardProfileSeedFixture {
  DashboardProfileSeedFixture._(
    List<DemoMonthReport> months, {
    required int ghostBookedRowsPerDirectionMonth,
  }) : _months = List<DemoMonthReport>.unmodifiable(months),
       _ghostBookedRowsPerDirectionMonth = ghostBookedRowsPerDirectionMonth;

  final List<DemoMonthReport> _months;
  final int _ghostBookedRowsPerDirectionMonth;

  int incomeEntryCount({int? year, int? month}) =>
      _entryCount(
        year: year,
        month: month,
        select: (report) => report.incomeCount,
      ) +
      _ghostBookedEntryCount(year: year, month: month);

  int expenseEntryCount({int? year, int? month}) =>
      _entryCount(
        year: year,
        month: month,
        select: (report) => report.expenseCount,
      ) +
      _ghostBookedEntryCount(year: year, month: month);

  int _ghostBookedEntryCount({required int? year, required int? month}) {
    if (year != null &&
        (year < DashboardProfileSeedFixtureContract._ghostStartYear ||
            year > DashboardProfileSeedFixtureContract._ghostEndYear)) {
      return 0;
    }
    final yearCount = year == null
        ? DashboardProfileSeedFixtureContract._ghostEndYear -
              DashboardProfileSeedFixtureContract._ghostStartYear +
              1
        : 1;
    final monthCount = month == null ? 12 : 1;
    return _ghostBookedRowsPerDirectionMonth * yearCount * monthCount;
  }

  int _entryCount({
    required int? year,
    required int? month,
    required int Function(DemoMonthReport report) select,
  }) => _months
      .where(
        (report) =>
            (year == null || report.year == year) &&
            (month == null || report.month == month),
      )
      .fold(0, (total, report) => total + select(report));
}
