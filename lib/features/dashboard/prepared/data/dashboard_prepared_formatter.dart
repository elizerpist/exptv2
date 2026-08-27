/// Pure formatters used while prepared frames are materialized off the UI
/// interaction path.
abstract final class DashboardPreparedFormatter {
  static String amountMinor(int totalMinor) {
    if (totalMinor == 0) return '0 Ft';
    final sign = totalMinor < 0 ? '-' : '';
    final absolute = totalMinor.abs();
    final major = absolute ~/ 100;
    final minor = (absolute % 100).toString().padLeft(2, '0');
    return '$sign$major,$minor Ft';
  }

  /// Presentation copy for the DAY Budget Header. Domain pace values remain
  /// scaled money; only this formatter owns the Hungarian unit suffix.
  static String amountMinorPerDay(int totalMinor) =>
      '${amountMinor(totalMinor)}/nap';

  static String entryCount(int value) => value.toString();
}
