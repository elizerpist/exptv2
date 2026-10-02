import 'dart:collection';
import 'dart:math' as math;

import '../domain/mind_temporal_heatmap_projection.dart';
import '../../time_navigation/domain/local_date.dart';

/// Presentation support derived once from the resident, slider-filtered SUM
/// frame. It has no financial membership or repository authority.
final class MindSumMicroDayRibbonModel {
  MindSumMicroDayRibbonModel._(this._years);

  final Map<int, MindSumMicroDayRibbonYear> _years;

  factory MindSumMicroDayRibbonModel.fromFrame(MindSumHeatmapFrame frame) {
    final totalsByEpochDay = <int, int>{};
    int? dailyMinimum;
    int? dailyMaximum;

    for (final year in frame.years) {
      for (final point in frame.dailyPointsForYear(year)) {
        totalsByEpochDay[point.date.epochDay] = point.total;
        dailyMinimum = dailyMinimum == null
            ? point.total
            : math.min(dailyMinimum, point.total);
        dailyMaximum = dailyMaximum == null
            ? point.total
            : math.max(dailyMaximum, point.total);
      }
    }

    final years = <int, MindSumMicroDayRibbonYear>{
      for (final year in frame.years)
        year: MindSumMicroDayRibbonYear._build(
          year: year,
          total: frame.yearTotal(year),
          totalsByEpochDay: totalsByEpochDay,
          dailyMinimum: dailyMinimum,
          dailyMaximum: dailyMaximum,
        ),
    };
    return MindSumMicroDayRibbonModel._(UnmodifiableMapView(years));
  }

  MindSumMicroDayRibbonYear year(int year) {
    final value = _years[year];
    if (value == null) {
      throw ArgumentError.value(year, 'year', 'Not represented by the frame.');
    }
    return value;
  }
}

/// A single compact annual field: twelve contiguous logical month groups,
/// each packed top-to-bottom into exactly five daily rows.
final class MindSumMicroDayRibbonYear {
  MindSumMicroDayRibbonYear._({
    required this.year,
    required this.total,
    required this.cells,
    required this.months,
    required this.totalMicroColumns,
  });

  static const int rows = 5;

  final int year;
  final int total;
  final List<MindSumMicroDayRibbonCell> cells;
  final List<MindSumMicroDayRibbonMonth> months;
  final int totalMicroColumns;

  int get rowCount => rows;

  factory MindSumMicroDayRibbonYear._build({
    required int year,
    required int total,
    required Map<int, int> totalsByEpochDay,
    required int? dailyMinimum,
    required int? dailyMaximum,
  }) {
    var startColumn = 0;
    final allCells = <MindSumMicroDayRibbonCell>[];
    final allMonths = <MindSumMicroDayRibbonMonth>[];

    for (var month = 1; month <= 12; month += 1) {
      final days = DateTime.utc(year, month + 1, 0).day;
      final microColumnCount = (days + rows - 1) ~/ rows;
      final monthCells = <MindSumMicroDayRibbonCell>[];
      for (var day = 1; day <= days; day += 1) {
        final date = LocalDate(year: year, month: month, day: day);
        final value = totalsByEpochDay[date.epochDay];
        monthCells.add(
          MindSumMicroDayRibbonCell(
            date: date,
            total: value,
            row: (day - 1) % rows,
            column: startColumn + ((day - 1) ~/ rows),
            intensity: _intensityFor(
              value,
              minimum: dailyMinimum,
              maximum: dailyMaximum,
            ),
          ),
        );
      }
      final immutableCells = List<MindSumMicroDayRibbonCell>.unmodifiable(
        monthCells,
      );
      allCells.addAll(immutableCells);
      allMonths.add(
        MindSumMicroDayRibbonMonth(
          month: month,
          startColumn: startColumn,
          microColumnCount: microColumnCount,
          cells: immutableCells,
        ),
      );
      startColumn += microColumnCount;
    }

    return MindSumMicroDayRibbonYear._(
      year: year,
      total: total,
      cells: List<MindSumMicroDayRibbonCell>.unmodifiable(allCells),
      months: List<MindSumMicroDayRibbonMonth>.unmodifiable(allMonths),
      totalMicroColumns: startColumn,
    );
  }

  MindSumMicroDayRibbonMonth month(int month) {
    if (month < 1 || month > months.length) {
      throw RangeError.range(month, 1, months.length, 'month');
    }
    return months[month - 1];
  }

  MindSumMicroDayRibbonCell cellFor({required int month, required int day}) {
    final monthData = this.month(month);
    if (day < 1 || day > monthData.cells.length) {
      throw RangeError.range(day, 1, monthData.cells.length, 'day');
    }
    return monthData.cells[day - 1];
  }

  static double _intensityFor(
    int? total, {
    required int? minimum,
    required int? maximum,
  }) {
    if (total == null || minimum == null || maximum == null) {
      return 0;
    }
    if (minimum == maximum) {
      return 1;
    }
    return ((total - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
  }
}

final class MindSumMicroDayRibbonMonth {
  const MindSumMicroDayRibbonMonth({
    required this.month,
    required this.startColumn,
    required this.microColumnCount,
    required this.cells,
  });

  final int month;
  final int startColumn;
  final int microColumnCount;
  final List<MindSumMicroDayRibbonCell> cells;
}

final class MindSumMicroDayRibbonCell {
  const MindSumMicroDayRibbonCell({
    required this.date,
    required this.total,
    required this.row,
    required this.column,
    required this.intensity,
  });

  final LocalDate date;
  final int? total;
  final int row;
  final int column;
  final double intensity;

  bool get isEmpty => total == null;
}

/// Width is solved from the actual annual ribbon width. Month transitions use
/// the exact same gap as adjacent micro-columns: there is no month padding.
final class MindSumMicroDayRibbonGeometry {
  const MindSumMicroDayRibbonGeometry._({
    required this.cellExtent,
    required this.microGap,
    required this.totalMicroColumns,
  });

  static const double _defaultMicroGap = 1;

  final double cellExtent;
  final double microGap;
  final int totalMicroColumns;

  factory MindSumMicroDayRibbonGeometry.resolve({
    required double availableWidth,
    required int totalMicroColumns,
  }) {
    if (totalMicroColumns < 1) {
      throw ArgumentError.value(
        totalMicroColumns,
        'totalMicroColumns',
        'Must be positive.',
      );
    }
    final gaps = _defaultMicroGap * (totalMicroColumns - 1);
    final cellExtent = math.max(
      0.0,
      (availableWidth - gaps) / totalMicroColumns,
    );
    return MindSumMicroDayRibbonGeometry._(
      cellExtent: cellExtent,
      microGap: _defaultMicroGap,
      totalMicroColumns: totalMicroColumns,
    );
  }

  double xForColumn(int column) => column * (cellExtent + microGap);

  double horizontalGapBetween({required int column, required int nextColumn}) =>
      xForColumn(nextColumn) - (xForColumn(column) + cellExtent);

  double get fieldHeight => rowCount * cellExtent + (rowCount - 1) * microGap;

  static const int rowCount = MindSumMicroDayRibbonYear.rows;
}
