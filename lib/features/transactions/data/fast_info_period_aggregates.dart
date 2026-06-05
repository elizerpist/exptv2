import 'dart:math' as math;

import '../models/fast_info_metric.dart';
import '../models/fast_info_metric_snapshot.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class FastInfoDatedTransaction {
  const FastInfoDatedTransaction({required this.record, required this.date});

  final TransactionRecord record;
  final DateTime date;
}

class FastInfoDatedRecurringGhost {
  const FastInfoDatedRecurringGhost({required this.record, required this.date});

  final RecurringGhostRecord record;
  final DateTime date;
}

class FastInfoPeriodAggregates {
  FastInfoPeriodAggregates({required this.snapshot})
    : today = _dateOnly(snapshot.now) {
    categoriesById = Map.unmodifiable({
      for (final category in snapshot.categories)
        category.transactionCategoryID: category,
    });

    datedTransactions = List.unmodifiable(
      <FastInfoDatedTransaction>[
        for (final record in snapshot.transactions)
          if (_parseDate(record.date) case final date?)
            FastInfoDatedTransaction(record: record, date: date),
      ]..sort(_compareTransactions),
    );
    expenseRows = List.unmodifiable(
      datedTransactions.where((row) => row.record.amount < 0),
    );
    variableExpenseRows = List.unmodifiable(
      expenseRows.where((row) => !row.record.isRecurringGenerated),
    );
    incomeRows = List.unmodifiable(
      datedTransactions.where((row) => row.record.amount > 0),
    );
    datedRecurringGhosts = List.unmodifiable(
      <FastInfoDatedRecurringGhost>[
        for (final record in snapshot.recurringGhosts)
          if (_parseDate(record.date) case final date?)
            FastInfoDatedRecurringGhost(record: record, date: date),
      ]..sort(_compareRecurringGhosts),
    );

    _expenseByDay = _totalsByDay(expenseRows);
    _variableExpenseByDay = _totalsByDay(variableExpenseRows);
    _incomeByDay = _totalsByDay(incomeRows);
  }

  final FastInfoMetricSnapshot snapshot;
  final DateTime today;
  late final Map<int, TransactionCategory> categoriesById;
  late final List<FastInfoDatedTransaction> datedTransactions;
  late final List<FastInfoDatedTransaction> expenseRows;
  late final List<FastInfoDatedTransaction> variableExpenseRows;
  late final List<FastInfoDatedTransaction> incomeRows;
  late final List<FastInfoDatedRecurringGhost> datedRecurringGhosts;
  late final Map<DateTime, double> _expenseByDay;
  late final Map<DateTime, double> _variableExpenseByDay;
  late final Map<DateTime, double> _incomeByDay;

  DateTime get currentMonthStart => DateTime(today.year, today.month);
  DateTime get nextMonthStart => DateTime(today.year, today.month + 1);
  DateTime get previousMonthStart => DateTime(today.year, today.month - 1);
  DateTime get twoMonthsAgoStart => DateTime(today.year, today.month - 2);
  DateTime get weekStart => today.subtract(Duration(days: today.weekday - 1));
  DateTime get nextWeekStart => weekStart.add(const Duration(days: 7));
  DateTime get previousWeekStart => weekStart.subtract(const Duration(days: 7));
  DateTime get rolling30Start => today.subtract(const Duration(days: 29));
  DateTime get previousRolling30Start =>
      today.subtract(const Duration(days: 59));
  DateTime get tomorrow => today.add(const Duration(days: 1));

  int get daysInCurrentMonth => _daysInMonth(today.year, today.month);
  int get elapsedMonthDays => today.day;
  int get remainingMonthDaysIncludingToday =>
      daysInCurrentMonth - today.day + 1;

  double get todayExpense => expenseOn(today);
  double get todayVariableExpense => variableExpenseOn(today);
  double get currentMonthExpense => expenseBetween(currentMonthStart, tomorrow);
  double get currentMonthExpenseBeforeToday =>
      expenseBetween(currentMonthStart, today);
  double get previousMonthExpense =>
      expenseBetween(previousMonthStart, currentMonthStart);
  double get previousMonthSameDayExpense =>
      expenseBetween(previousMonthStart, _sameDayCutoff(previousMonthStart));
  double get rolling30Expense => expenseBetween(rolling30Start, tomorrow);
  double get previousRolling30Expense =>
      expenseBetween(previousRolling30Start, rolling30Start);
  double get currentWeekExpense => expenseBetween(weekStart, tomorrow);
  double get previousWeekSameDayExpense => expenseBetween(
    previousWeekStart,
    previousWeekStart.add(Duration(days: today.weekday)),
  );
  double get currentMonthIncome => incomeBetween(currentMonthStart, tomorrow);
  double get previousMonthSameDayIncome =>
      incomeBetween(previousMonthStart, _sameDayCutoff(previousMonthStart));
  double get rolling30Income => incomeBetween(rolling30Start, tomorrow);

  List<double> get currentMonthDailySeries => _dailyExpenseSeries(
    currentMonthStart,
    daysInCurrentMonth,
    ignoreAfterToday: true,
  );
  List<double> get previousMonthDailySeries => _dailyExpenseSeries(
    previousMonthStart,
    _daysInMonth(previousMonthStart.year, previousMonthStart.month),
  );
  List<double> get twoMonthsAgoDailySeries => _dailyExpenseSeries(
    twoMonthsAgoStart,
    _daysInMonth(twoMonthsAgoStart.year, twoMonthsAgoStart.month),
  );
  List<double> get rolling30DailySeries =>
      _dailyExpenseSeries(rolling30Start, 30);

  List<FastInfoWeeklyBar> get currentWeekBars => List.unmodifiable(
    List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final isFuture = date.isAfter(today);
      return FastInfoWeeklyBar(
        value: isFuture ? 0.0 : expenseOn(date),
        isFuture: isFuture,
        semantic: FastInfoSemantic.neutral,
      );
    }),
  );

  double expenseOn(DateTime date) => _expenseByDay[_dateOnly(date)] ?? 0.0;
  double variableExpenseOn(DateTime date) =>
      _variableExpenseByDay[_dateOnly(date)] ?? 0.0;
  double incomeOn(DateTime date) => _incomeByDay[_dateOnly(date)] ?? 0.0;

  double expenseBetween(DateTime start, DateTime end) =>
      _sumRows(expenseRowsBetween(start, end));

  double variableExpenseBetween(DateTime start, DateTime end) =>
      _sumRows(variableExpenseRowsBetween(start, end));

  double incomeBetween(DateTime start, DateTime end) =>
      _sumRows(incomeRowsBetween(start, end));

  List<FastInfoDatedTransaction> expenseRowsBetween(
    DateTime start,
    DateTime end,
  ) => _rowsBetween(expenseRows, start, end);

  List<FastInfoDatedTransaction> variableExpenseRowsBetween(
    DateTime start,
    DateTime end,
  ) => _rowsBetween(variableExpenseRows, start, end);

  List<FastInfoDatedTransaction> incomeRowsBetween(
    DateTime start,
    DateTime end,
  ) => _rowsBetween(incomeRows, start, end);

  List<FastInfoDatedRecurringGhost> recurringGhostsBetween(
    DateTime start,
    DateTime end, {
    bool expensesOnly = false,
    bool pendingOnly = false,
  }) {
    return List.unmodifiable(
      datedRecurringGhosts.where((row) {
        if (row.date.isBefore(start) || !row.date.isBefore(end)) return false;
        if (expensesOnly && row.record.type != TransactionType.expense) {
          return false;
        }
        if (pendingOnly && row.record.isActivated) return false;
        return true;
      }),
    );
  }

  Map<int, List<FastInfoDatedTransaction>> categoryExpenseGroups(
    Iterable<FastInfoDatedTransaction> rows,
  ) {
    final groups = <int, List<FastInfoDatedTransaction>>{};
    for (final row in rows) {
      groups
          .putIfAbsent(
            row.record.transactionCategoryID,
            () => <FastInfoDatedTransaction>[],
          )
          .add(row);
    }
    return Map<int, List<FastInfoDatedTransaction>>.unmodifiable({
      for (final entry in groups.entries)
        entry.key: List<FastInfoDatedTransaction>.unmodifiable(entry.value),
    });
  }

  Map<String, List<FastInfoDatedTransaction>> merchantExpenseGroups(
    Iterable<FastInfoDatedTransaction> rows,
  ) {
    final groups = <String, List<FastInfoDatedTransaction>>{};
    for (final row in rows) {
      final name = row.record.displayMerchant.trim();
      if (name.isEmpty) continue;
      groups.putIfAbsent(name, () => <FastInfoDatedTransaction>[]).add(row);
    }
    return Map<String, List<FastInfoDatedTransaction>>.unmodifiable({
      for (final entry in groups.entries)
        entry.key: List<FastInfoDatedTransaction>.unmodifiable(entry.value),
    });
  }

  DateTime _sameDayCutoff(DateTime monthStart) {
    final cutoffDay = math.min(
      today.day,
      _daysInMonth(monthStart.year, monthStart.month),
    );
    return DateTime(monthStart.year, monthStart.month, cutoffDay + 1);
  }

  List<double> _dailyExpenseSeries(
    DateTime start,
    int length, {
    bool ignoreAfterToday = false,
  }) {
    return List.unmodifiable(
      List.generate(length, (index) {
        final date = start.add(Duration(days: index));
        if (ignoreAfterToday && date.isAfter(today)) return 0.0;
        return expenseOn(date);
      }),
    );
  }
}

List<FastInfoDatedTransaction> _rowsBetween(
  List<FastInfoDatedTransaction> rows,
  DateTime start,
  DateTime end,
) {
  return List.unmodifiable(
    rows.where((row) => !row.date.isBefore(start) && row.date.isBefore(end)),
  );
}

Map<DateTime, double> _totalsByDay(List<FastInfoDatedTransaction> rows) {
  final totals = <DateTime, double>{};
  for (final row in rows) {
    totals.update(
      row.date,
      (value) => value + row.record.amount.abs(),
      ifAbsent: () => row.record.amount.abs(),
    );
  }
  return Map.unmodifiable(totals);
}

double _sumRows(Iterable<FastInfoDatedTransaction> rows) {
  return rows.fold<double>(0, (sum, row) => sum + row.record.amount.abs());
}

int _compareTransactions(
  FastInfoDatedTransaction left,
  FastInfoDatedTransaction right,
) {
  final byDate = right.date.compareTo(left.date);
  if (byDate != 0) return byDate;
  return right.record.time.compareTo(left.record.time);
}

int _compareRecurringGhosts(
  FastInfoDatedRecurringGhost left,
  FastInfoDatedRecurringGhost right,
) {
  final byDate = left.date.compareTo(right.date);
  if (byDate != 0) return byDate;
  return left.record.time.compareTo(right.record.time);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime? _parseDate(String raw) {
  final normalized = raw.trim().replaceAll('.', '-');
  final parts = normalized.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
