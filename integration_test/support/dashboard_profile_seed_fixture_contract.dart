import 'package:fluvi/core/demo_data/demo_seed_report.dart';

/// Authoritative profile-fixture contract shared by the automated harness and
/// its focused unit test. Keep the native generator's 2025 dense year and the
/// original 2026 rail fixture explicit here instead of scattering counts.
abstract final class DashboardProfileSeedFixtureContract {
  static const int expectedSeededTransactionCount = 4304;
  static const Map<int, int> expectedMonthsByYear = <int, int>{
    2025: 12,
    2026: 7,
  };

  static int get expectedTotalMonthCount => expectedMonthsByYear.values.fold(
    0,
    (total, count) => total + count,
  );

  static void verify(DemoSeedReport report) {
    if (report.createdEntryCount != expectedSeededTransactionCount) {
      throw StateError(
        'Profile seed created ${report.createdEntryCount} transactions; '
        'expected $expectedSeededTransactionCount.',
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

  static bool _sameCounts(Map<int, int> actual, Map<int, int> expected) {
    if (actual.length != expected.length) return false;
    for (final entry in expected.entries) {
      if (actual[entry.key] != entry.value) return false;
    }
    return true;
  }
}
