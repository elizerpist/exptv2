/// Pure formatters used while prepared frames are materialized off the UI
/// interaction path.
abstract final class DashboardPreparedFormatter {
  static String amountMinor(int totalMinor) {
    final wholeForints = totalMinor ~/ 100;
    if (wholeForints == 0) return '0 Ft';
    return '$wholeForints Ft';
  }

  /// Presentation copy for the DAY Budget Header. Domain pace values remain
  /// scaled money; only this formatter owns the Hungarian unit suffix.
  static String amountMinorPerDay(int totalMinor) =>
      '${amountMinor(totalMinor)}/nap';

  static String entryCount(int value) => value.toString();
}
