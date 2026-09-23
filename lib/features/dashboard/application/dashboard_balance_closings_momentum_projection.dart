import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import 'dashboard_balance_primary_projection.dart';

/// One discrete Balance closing period. It is deliberately a period result,
/// never a cumulative account-balance sample.
@immutable
final class DashboardBalanceClosingBucket {
  const DashboardBalanceClosingBucket({
    required this.id,
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String id;
  final String label;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

/// Immutable Core-owned read model shared by the compact and detailed
/// Closings renderers.
@immutable
final class DashboardBalanceClosingsPresentation {
  DashboardBalanceClosingsPresentation({
    required this.identity,
    required this.timeScope,
    required List<DashboardBalanceClosingBucket> buckets,
  }) : buckets = List<DashboardBalanceClosingBucket>.unmodifiable(buckets),
       presentationId = Object.hashAll(<Object?>[
         identity,
         timeScope.canonicalKey,
         for (final bucket in buckets)
           '${bucket.id}:${bucket.incomeMinor}:${bucket.expenseMinor}',
       ]);

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final List<DashboardBalanceClosingBucket> buckets;
  final int presentationId;

  int get positiveBucketCount =>
      buckets.where((bucket) => bucket.netMinor > 0).length;
}

/// Balance-local taxonomy. Budget's eight-part rhythm enum is intentionally
/// neither imported nor changed by this six-part Closings presentation.
enum DashboardBalanceClosingDaypart {
  night('Éjjel', 0, 359),
  morning('Reggel', 360, 539),
  lateMorning('Délelőtt', 540, 719),
  afternoon('Délután', 720, 1079),
  evening('Este', 1080, 1259),
  lateEvening('Késő este', 1260, 1439);

  const DashboardBalanceClosingDaypart(
    this.label,
    this.startInclusiveMinute,
    this.endInclusiveMinute,
  );

  final String label;
  final int startInclusiveMinute;
  final int endInclusiveMinute;

  bool contains(int minute) =>
      minute >= startInclusiveMinute && minute <= endInclusiveMinute;
}

/// Pure dual-direction projection for discrete Balance closing results.
abstract final class DashboardBalanceClosingsProjection {
  static DashboardBalanceClosingsPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final income = List<DashboardLedgerEntry>.unmodifiable(incomeEntries);
    final expense = List<DashboardLedgerEntry>.unmodifiable(expenseEntries);
    final buckets = switch (timeScope) {
      AllTimeScope() => _annualBuckets(income, expense),
      YearScope(:final year) => _monthlyBuckets(year, income, expense),
      MonthScope(:final value) => _dailyBuckets(value, income, expense),
      DayScope(:final date) => _daypartBuckets(date, income, expense),
    };
    return DashboardBalanceClosingsPresentation(
      identity: identity,
      timeScope: timeScope,
      buckets: buckets,
    );
  }

  static List<DashboardBalanceClosingBucket> _annualBuckets(
    List<DashboardLedgerEntry> income,
    List<DashboardLedgerEntry> expense,
  ) {
    final years = <int>{
      for (final entry in income) _date(entry.bookedLocalEpochDay).year,
      for (final entry in expense) _date(entry.bookedLocalEpochDay).year,
    }.toList()..sort();
    return List<DashboardBalanceClosingBucket>.unmodifiable(
      <DashboardBalanceClosingBucket>[
        for (final year in years)
          _bucket(
            id: 'year:$year',
            label: '$year',
            income: income,
            expense: expense,
            includes: (entry) => _date(entry.bookedLocalEpochDay).year == year,
          ),
      ],
    );
  }

  static List<DashboardBalanceClosingBucket> _monthlyBuckets(
    int year,
    List<DashboardLedgerEntry> income,
    List<DashboardLedgerEntry> expense,
  ) => List<DashboardBalanceClosingBucket>.unmodifiable(
    <DashboardBalanceClosingBucket>[
      for (var month = 1; month <= 12; month += 1)
        _bucket(
          id: 'month:$year-$month',
          label: _monthLabel(month),
          income: income,
          expense: expense,
          includes: (entry) {
            final date = _date(entry.bookedLocalEpochDay);
            return date.year == year && date.month == month;
          },
        ),
    ],
  );

  static List<DashboardBalanceClosingBucket> _dailyBuckets(
    YearMonth month,
    List<DashboardLedgerEntry> income,
    List<DashboardLedgerEntry> expense,
  ) {
    final days = month.daysInMonth;
    return List<DashboardBalanceClosingBucket>.unmodifiable(
      <DashboardBalanceClosingBucket>[
        for (var day = 1; day <= days; day += 1)
          _bucket(
            id: 'day:${month.isoString}-$day',
            label: '$day',
            income: income,
            expense: expense,
            includes: (entry) {
              final date = _date(entry.bookedLocalEpochDay);
              return date.year == month.year &&
                  date.month == month.month &&
                  date.day == day;
            },
          ),
      ],
    );
  }

  static List<DashboardBalanceClosingBucket> _daypartBuckets(
    LocalDate date,
    List<DashboardLedgerEntry> income,
    List<DashboardLedgerEntry> expense,
  ) => List<DashboardBalanceClosingBucket>.unmodifiable(
    <DashboardBalanceClosingBucket>[
      for (final daypart in DashboardBalanceClosingDaypart.values)
        _bucket(
          id: 'daypart:${daypart.name}',
          label: daypart.label,
          income: income,
          expense: expense,
          includes: (entry) =>
              entry.bookedLocalEpochDay == date.epochDay &&
              daypart.contains(entry.bookedLocalTimeMinutes),
        ),
    ],
  );

  static DashboardBalanceClosingBucket _bucket({
    required String id,
    required String label,
    required List<DashboardLedgerEntry> income,
    required List<DashboardLedgerEntry> expense,
    required bool Function(DashboardLedgerEntry entry) includes,
  }) => DashboardBalanceClosingBucket(
    id: id,
    label: label,
    incomeMinor: _total(income, includes),
    expenseMinor: _total(expense, includes),
  );

  static int _total(
    Iterable<DashboardLedgerEntry> entries,
    bool Function(DashboardLedgerEntry entry) includes,
  ) => entries
      .where(includes)
      .fold<int>(0, (total, entry) => total + entry.amountMinor.abs());

  static String _monthLabel(int month) => const <String>[
    'JAN',
    'FEB',
    'MÁR',
    'ÁPR',
    'MÁJ',
    'JÚN',
    'JÚL',
    'AUG',
    'SZE',
    'OKT',
    'NOV',
    'DEC',
  ][month - 1];
}

/// Inclusive calendar window displayed with a Momentum comparison.
@immutable
final class DashboardBalanceComparisonWindow {
  const DashboardBalanceComparisonWindow({
    required this.startInclusive,
    required this.endInclusive,
  });

  final LocalDate startInclusive;
  final LocalDate endInclusive;

  bool containsEpochDay(int epochDay) =>
      epochDay >= startInclusive.epochDay && epochDay <= endInclusive.epochDay;

  @override
  bool operator ==(Object other) =>
      other is DashboardBalanceComparisonWindow &&
      other.startInclusive == startInclusive &&
      other.endInclusive == endInclusive;

  @override
  int get hashCode => Object.hash(startInclusive, endInclusive);
}

enum DashboardBalanceMomentumUnit { perDay, perHour }

/// Explicit semantic states for the four Momentum quadrants and their axes.
enum DashboardBalanceMomentumState {
  recovery,
  strengtheningSurplus,
  deepeningDeficit,
  weakeningSurplus,
  stableSurplus,
  stableDeficit,
  improvingBreakEven,
  worseningBreakEven,
  stableBreakEven,
  unavailable;

  static DashboardBalanceMomentumState resolve({
    required num currentNetPace,
    required num momentum,
  }) {
    if (currentNetPace > 0) {
      if (momentum > 0) return strengtheningSurplus;
      if (momentum < 0) return weakeningSurplus;
      return stableSurplus;
    }
    if (currentNetPace < 0) {
      if (momentum > 0) return recovery;
      if (momentum < 0) return deepeningDeficit;
      return stableDeficit;
    }
    if (momentum > 0) return improvingBreakEven;
    if (momentum < 0) return worseningBreakEven;
    return stableBreakEven;
  }
}

/// Immutable, pre-normalized Momentum input shared by both Balance cards.
@immutable
final class DashboardBalanceMomentumPresentation {
  const DashboardBalanceMomentumPresentation._({
    required this.identity,
    required this.timeScope,
    required this.logicalAsOfDate,
    required this.logicalAsOfLocalTimeMinutes,
    required this.currentWindow,
    required this.previousWindow,
    required this.unit,
    required this.currentNetMinor,
    required this.previousNetMinor,
    required this.currentDuration,
    required this.previousDuration,
    required this.currentNetPace,
    required this.previousNetPace,
    required this.momentum,
    required this.state,
    required this.isAvailable,
  });

  factory DashboardBalanceMomentumPresentation.unavailable({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
  }) => DashboardBalanceMomentumPresentation._(
    identity: identity,
    timeScope: timeScope,
    logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 1),
    logicalAsOfLocalTimeMinutes: 0,
    currentWindow: null,
    previousWindow: null,
    unit: DashboardBalanceMomentumUnit.perDay,
    currentNetMinor: 0,
    previousNetMinor: 0,
    currentDuration: 0,
    previousDuration: 0,
    currentNetPace: 0,
    previousNetPace: 0,
    momentum: 0,
    state: DashboardBalanceMomentumState.unavailable,
    isAvailable: false,
  );

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final LocalDate logicalAsOfDate;
  final int logicalAsOfLocalTimeMinutes;
  final DashboardBalanceComparisonWindow? currentWindow;
  final DashboardBalanceComparisonWindow? previousWindow;
  final DashboardBalanceMomentumUnit unit;
  final int currentNetMinor;
  final int previousNetMinor;
  final int currentDuration;
  final int previousDuration;
  final double currentNetPace;
  final double previousNetPace;
  final double momentum;
  final DashboardBalanceMomentumState state;
  final bool isAvailable;

  int get presentationId => Object.hashAll(<Object?>[
    identity,
    timeScope.canonicalKey,
    logicalAsOfDate,
    logicalAsOfLocalTimeMinutes,
    currentWindow,
    previousWindow,
    currentNetMinor,
    previousNetMinor,
    currentDuration,
    previousDuration,
    state,
    isAvailable,
  ]);
}

/// Pure comparable-window Balance pace calculation over admitted histories.
abstract final class DashboardBalanceMomentumProjection {
  static DashboardBalanceMomentumPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LocalDate logicalAsOfDate,
    required int logicalAsOfLocalTimeMinutes,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final income = List<DashboardLedgerEntry>.unmodifiable(incomeEntries);
    final expense = List<DashboardLedgerEntry>.unmodifiable(expenseEntries);
    final windows = _windowsFor(
      timeScope,
      logicalAsOfDate,
      logicalAsOfLocalTimeMinutes,
    );
    if (windows == null ||
        !_hasHistoryBefore(windows.previous, income, expense)) {
      return _unavailable(
        identity: identity,
        timeScope: timeScope,
        asOf: logicalAsOfDate,
        asOfMinute: logicalAsOfLocalTimeMinutes,
        unit: windows?.unit ?? DashboardBalanceMomentumUnit.perDay,
        current: windows?.current.window,
        previous: windows?.previous.window,
      );
    }
    final currentNet = _netFor(
      windows.current,
      income: income,
      expense: expense,
    );
    final previousNet = _netFor(
      windows.previous,
      income: income,
      expense: expense,
    );
    final currentPace = _pace(
      currentNet,
      windows.current.duration,
      windows.unit,
    );
    final previousPace = _pace(
      previousNet,
      windows.previous.duration,
      windows.unit,
    );
    final value = currentPace - previousPace;
    return DashboardBalanceMomentumPresentation._(
      identity: identity,
      timeScope: timeScope,
      logicalAsOfDate: logicalAsOfDate,
      logicalAsOfLocalTimeMinutes: logicalAsOfLocalTimeMinutes,
      currentWindow: windows.current.window,
      previousWindow: windows.previous.window,
      unit: windows.unit,
      currentNetMinor: currentNet,
      previousNetMinor: previousNet,
      currentDuration: windows.current.duration,
      previousDuration: windows.previous.duration,
      currentNetPace: currentPace,
      previousNetPace: previousPace,
      momentum: value,
      state: DashboardBalanceMomentumState.resolve(
        currentNetPace: currentPace,
        momentum: value,
      ),
      isAvailable: true,
    );
  }

  static _MomentumWindows? _windowsFor(
    LedgerTimeScope scope,
    LocalDate asOf,
    int asOfMinute,
  ) {
    if (asOfMinute < 0 || asOfMinute > 1439) return null;
    return switch (scope) {
      AllTimeScope() => _yearToDate(asOf),
      YearScope(:final year) => _year(scopeYear: year, asOf: asOf),
      MonthScope(:final value) => _month(value, asOf),
      DayScope(:final date) => _day(date, asOf, asOfMinute),
    };
  }

  static _MomentumWindows _yearToDate(LocalDate asOf) {
    final previousEnd = _clampDate(asOf.year - 1, asOf.month, asOf.day);
    return _MomentumWindows(
      unit: DashboardBalanceMomentumUnit.perDay,
      current: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: LocalDate(year: asOf.year, month: 1, day: 1),
          endInclusive: asOf,
        ),
      ),
      previous: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: LocalDate(year: asOf.year - 1, month: 1, day: 1),
          endInclusive: previousEnd,
        ),
      ),
    );
  }

  static _MomentumWindows? _year({
    required int scopeYear,
    required LocalDate asOf,
  }) {
    if (scopeYear > asOf.year) return null;
    if (scopeYear < asOf.year) {
      return _monthPair(
        currentYear: scopeYear,
        currentMonth: 12,
        currentEndDay: 31,
        previousYear: scopeYear,
        previousMonth: 11,
        previousEndDay: 30,
      );
    }
    final previous = YearMonth(year: scopeYear, month: asOf.month).previous();
    return _monthPair(
      currentYear: scopeYear,
      currentMonth: asOf.month,
      currentEndDay: asOf.day,
      previousYear: previous.year,
      previousMonth: previous.month,
      previousEndDay: _daysInMonth(
        previous.year,
        previous.month,
      ).clamp(1, asOf.day).toInt(),
    );
  }

  static _MomentumWindows? _month(YearMonth scope, LocalDate asOf) {
    final scopeStart = LocalDate(year: scope.year, month: scope.month, day: 1);
    if (scopeStart.epochDay > asOf.epochDay) return null;
    final anchor = scope.year == asOf.year && scope.month == asOf.month
        ? asOf
        : LocalDate(
            year: scope.year,
            month: scope.month,
            day: scope.daysInMonth,
          );
    final currentStart = _dateForEpochDay(anchor.epochDay - 6);
    return _MomentumWindows(
      unit: DashboardBalanceMomentumUnit.perDay,
      current: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: currentStart,
          endInclusive: anchor,
        ),
      ),
      previous: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: _dateForEpochDay(currentStart.epochDay - 7),
          endInclusive: _dateForEpochDay(currentStart.epochDay - 1),
        ),
      ),
    );
  }

  static _MomentumWindows? _day(
    LocalDate scope,
    LocalDate asOf,
    int asOfMinute,
  ) {
    if (scope.epochDay > asOf.epochDay) return null;
    final isCurrent = scope == asOf;
    final endMinute = isCurrent ? asOfMinute : 1439;
    if (endMinute == 0) return null;
    final previous = _dateForEpochDay(scope.epochDay - 1);
    return _MomentumWindows(
      unit: DashboardBalanceMomentumUnit.perHour,
      current: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: scope,
          endInclusive: scope,
        ),
        endInclusiveMinute: endMinute,
        durationMinutes: isCurrent ? null : 24 * 60,
      ),
      previous: _TimedWindow(
        DashboardBalanceComparisonWindow(
          startInclusive: previous,
          endInclusive: previous,
        ),
        endInclusiveMinute: endMinute,
        durationMinutes: isCurrent ? null : 24 * 60,
      ),
    );
  }

  static _MomentumWindows _monthPair({
    required int currentYear,
    required int currentMonth,
    required int currentEndDay,
    required int previousYear,
    required int previousMonth,
    required int previousEndDay,
  }) => _MomentumWindows(
    unit: DashboardBalanceMomentumUnit.perDay,
    current: _TimedWindow(
      DashboardBalanceComparisonWindow(
        startInclusive: LocalDate(
          year: currentYear,
          month: currentMonth,
          day: 1,
        ),
        endInclusive: _clampDate(currentYear, currentMonth, currentEndDay),
      ),
    ),
    previous: _TimedWindow(
      DashboardBalanceComparisonWindow(
        startInclusive: LocalDate(
          year: previousYear,
          month: previousMonth,
          day: 1,
        ),
        endInclusive: _clampDate(previousYear, previousMonth, previousEndDay),
      ),
    ),
  );

  static bool _hasHistoryBefore(
    _TimedWindow previous,
    Iterable<DashboardLedgerEntry> income,
    Iterable<DashboardLedgerEntry> expense,
  ) {
    final earliest =
        <int>[
          for (final entry in income) entry.bookedLocalEpochDay,
          for (final entry in expense) entry.bookedLocalEpochDay,
        ].fold<int?>(
          null,
          (value, epochDay) =>
              value == null || epochDay < value ? epochDay : value,
        );
    return earliest != null &&
        earliest <= previous.window.startInclusive.epochDay;
  }

  static int _netFor(
    _TimedWindow window, {
    required Iterable<DashboardLedgerEntry> income,
    required Iterable<DashboardLedgerEntry> expense,
  }) => _totalFor(income, window) - _totalFor(expense, window);

  static int _totalFor(
    Iterable<DashboardLedgerEntry> entries,
    _TimedWindow window,
  ) => entries
      .where((entry) {
        if (!window.window.containsEpochDay(entry.bookedLocalEpochDay)) {
          return false;
        }
        final endMinute = window.endInclusiveMinute;
        return endMinute == null ||
            entry.bookedLocalEpochDay != window.window.endInclusive.epochDay ||
            entry.bookedLocalTimeMinutes <= endMinute;
      })
      .fold<int>(0, (total, entry) => total + entry.amountMinor.abs());

  static double _pace(
    int netMinor,
    int duration,
    DashboardBalanceMomentumUnit unit,
  ) => duration == 0
      ? 0
      : unit == DashboardBalanceMomentumUnit.perHour
      ? netMinor * 60 / duration
      : netMinor / duration;

  static DashboardBalanceMomentumPresentation _unavailable({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LocalDate asOf,
    required int asOfMinute,
    required DashboardBalanceMomentumUnit unit,
    DashboardBalanceComparisonWindow? current,
    DashboardBalanceComparisonWindow? previous,
  }) => DashboardBalanceMomentumPresentation._(
    identity: identity,
    timeScope: timeScope,
    logicalAsOfDate: asOf,
    logicalAsOfLocalTimeMinutes: asOfMinute,
    currentWindow: current,
    previousWindow: previous,
    unit: unit,
    currentNetMinor: 0,
    previousNetMinor: 0,
    currentDuration: 0,
    previousDuration: 0,
    currentNetPace: 0,
    previousNetPace: 0,
    momentum: 0,
    state: DashboardBalanceMomentumState.unavailable,
    isAvailable: false,
  );
}

final class _TimedWindow {
  _TimedWindow(this.window, {this.endInclusiveMinute, int? durationMinutes})
    : duration =
          durationMinutes ??
          endInclusiveMinute ??
          (window.endInclusive.epochDay - window.startInclusive.epochDay + 1);

  final DashboardBalanceComparisonWindow window;
  final int? endInclusiveMinute;
  final int duration;
}

final class _MomentumWindows {
  const _MomentumWindows({
    required this.unit,
    required this.current,
    required this.previous,
  });

  final DashboardBalanceMomentumUnit unit;
  final _TimedWindow current;
  final _TimedWindow previous;
}

int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

LocalDate _clampDate(int year, int month, int day) => LocalDate(
  year: year,
  month: month,
  day: _daysInMonth(year, month).clamp(1, day).toInt(),
);

LocalDate _dateForEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return LocalDate(year: date.year, month: date.month, day: date.day);
}

DateTime _date(int epochDay) =>
    DateTime.utc(1970).add(Duration(days: epochDay));
