/// Pure formatters used while prepared frames are materialized off the UI
/// interaction path.
abstract final class DashboardPreparedFormatter {
  static String amountMinor(int totalMinor) {
    final wholeForints = totalMinor ~/ 100;
    if (wholeForints == 0) return '0 Ft';
    return '$wholeForints Ft';
  }

  /// Compact Hungarian HUF copy for space-constrained prepared presentation.
  /// The input stays in the project's exact minor-unit representation; only
  /// this display formatter abbreviates its whole-forint projection.
  static String compactAmountMinor(int totalMinor) =>
      compactForints(totalMinor ~/ 100);

  /// Shared compact whole-HUF formatter. Mind's annual labels and Balance
  /// carousel previews intentionally use the same `k Ft` / `M Ft` grammar.
  /// Dense repeated metadata can omit only the repeated currency suffix while
  /// retaining the exact same compact magnitude and locale convention.
  static String compactForints(
    int forints, {
    bool includeCurrencySuffix = true,
  }) {
    final absolute = forints.abs();
    final sign = forints < 0 ? '-' : '';
    final suffix = includeCurrencySuffix ? ' Ft' : '';
    if (absolute >= 1000000) {
      final millions = (absolute / 1000000)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      return '$sign$millions M$suffix';
    }
    if (absolute >= 1000) return '$sign${(absolute / 1000).round()} k$suffix';
    return '$forints$suffix';
  }

  /// Presentation copy for the DAY Budget Header. Domain pace values remain
  /// scaled money; only this formatter owns the Hungarian unit suffix.
  static String amountMinorPerDay(int totalMinor) =>
      '${amountMinor(totalMinor)}/nap';

  static String entryCount(int value) => value.toString();
}
