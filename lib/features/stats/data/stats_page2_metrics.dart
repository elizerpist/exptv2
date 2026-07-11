import 'stats_year_data.dart';

class StatsPage2Metrics {
  const StatsPage2Metrics({
    required this.total,
    required this.monthCount,
    required this.dayCount,
    required this.recordCount,
    required this.activeDayCount,
    required this.monthlyAverage,
    required this.largestAmount,
    required this.topMonthAmount,
    required this.topMonthLabel,
    required this.dailyAverageTransactionCount,
    required this.dailyAverageAmount,
    required this.zeroActivityDays,
    required this.averageEventAmount,
  });

  final double total;
  final int monthCount;
  final int dayCount;
  final int recordCount;
  final int activeDayCount;
  final double monthlyAverage;
  final double largestAmount;
  final double topMonthAmount;
  final String topMonthLabel;
  final double dailyAverageTransactionCount;
  final double dailyAverageAmount;
  final int zeroActivityDays;
  final double averageEventAmount;

  static StatsPage2Metrics fromYearData(StatsYearData data) {
    final monthCount = data.metricMonthCount;
    final dayCount = data.metricDayCount;
    final recordCount = data.metricRecordCount;
    return StatsPage2Metrics(
      total: data.summaryTotal,
      monthCount: monthCount,
      dayCount: dayCount,
      recordCount: recordCount,
      activeDayCount: data.metricActiveDayCount,
      monthlyAverage: monthCount == 0 ? 0 : data.summaryTotal / monthCount,
      largestAmount: data.largestRecordAmount,
      topMonthAmount: data.topMonthAmount,
      topMonthLabel: data.topMonthLabel,
      dailyAverageTransactionCount: dayCount == 0 ? 0 : recordCount / dayCount,
      dailyAverageAmount: dayCount == 0 ? 0 : data.summaryTotal / dayCount,
      zeroActivityDays: (dayCount - data.metricActiveDayCount).clamp(
        0,
        dayCount,
      ),
      averageEventAmount: recordCount == 0
          ? 0
          : data.summaryTotal / recordCount,
    );
  }
}
