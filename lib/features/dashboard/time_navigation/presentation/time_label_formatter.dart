import '../domain/year_month.dart';

abstract final class DashboardTimeLabelFormatter {
  static String monthName(int month) => const <String>[
    '',
    'január',
    'február',
    'március',
    'április',
    'május',
    'június',
    'július',
    'augusztus',
    'szeptember',
    'október',
    'november',
    'december',
  ][month];

  static String yearMonth(YearMonth value) {
    return '${value.year}. ${monthName(value.month)}';
  }

  static String date(YearMonth month, int day) {
    return '${yearMonth(month)} ${month.clampDay(day).day}.';
  }
}
