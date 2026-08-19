import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/time/fluvi_clock.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../runtime/domain/prepared_budget_rhythm_snapshot.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/domain/time_plane.dart';
import 'dashboard_budget_presentation_controller.dart';
import 'dashboard_budget_target.dart';

@immutable
final class DashboardBudgetRhythmBar {
  const DashboardBudgetRhythmBar({
    required this.label,
    required this.actualScaled100,
    required this.visualFraction,
  });

  final String label;
  final int actualScaled100;
  final double visualFraction;
}

@immutable
final class DashboardBudgetRhythmProjection {
  const DashboardBudgetRhythmProjection({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.plane,
    required this.windowStart,
    required this.windowEnd,
    required this.title,
    required this.bars,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final TimePlane plane;

  /// UTC day-key representations of the local clock's rolling window. The
  /// UTC construction preserves local Y/M/D identity; it does not convert a
  /// local instant across a timezone boundary.
  final DateTime windowStart;
  final DateTime windowEnd;
  final String title;
  final List<DashboardBudgetRhythmBar> bars;
}

/// Immutable local paint input. The colour is resolved from the existing
/// selected Budget target authority, never from a rhythm-local palette.
@immutable
final class DashboardBudgetRhythmState {
  const DashboardBudgetRhythmState({
    required this.projection,
    required this.startColorArgb,
    required this.middleColorArgb,
    required this.endColorArgb,
  });

  final DashboardBudgetRhythmProjection projection;
  final int startColorArgb;
  final int middleColorArgb;
  final int endColorArgb;
}

typedef DashboardBudgetRhythmRolloverScheduler =
    VoidCallback Function(Duration delay, VoidCallback callback);

/// CoreDashboard-lifetime RAM-only binding. It observes the canonical Budget
/// semantic selection and navigation plane; local wall-clock time is the sole
/// rolling-window authority. It owns neither a selected target nor an
/// alternative navigation model.
final class DashboardBudgetRhythmController
    extends ValueNotifier<DashboardBudgetRhythmState?> {
  DashboardBudgetRhythmController({
    required DashboardBudgetPresentationController presentation,
    required DashboardNavigationController navigation,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
    FluviClock clock = const SystemFluviClock(),
    DashboardBudgetRhythmRolloverScheduler? scheduleRollover,
  }) : _presentation = presentation,
       _navigation = navigation,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _clock = clock,
       _scheduleRollover = scheduleRollover ?? _scheduleWithTimer,
       super(null) {
    _presentation.addListener(_refresh);
    _navigation.addListener(_refresh);
    _refresh();
    _armNextLocalDayRollover();
  }

  final DashboardBudgetPresentationController _presentation;
  final DashboardNavigationController _navigation;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final FluviClock _clock;
  final DashboardBudgetRhythmRolloverScheduler _scheduleRollover;
  VoidCallback? _cancelRollover;
  int? _lastDiagnosticSignature;

  void _refresh() {
    final snapshot = _snapshotForCurrentFrame();
    final selection = _presentation.value.liveSelection;
    final rhythm = snapshot?.rhythmSnapshot;
    if (snapshot == null ||
        rhythm == null ||
        !selection.isAvailable ||
        selection.coreRevision != snapshot.coreRevision ||
        rhythm.coreRevision != snapshot.coreRevision ||
        selection.target.handle >=
            rhythm.directionBank(selection.direction).targetCount) {
      if (value != null) value = null;
      return;
    }
    final state = _navigation.state;
    final projection = DashboardBudgetRhythmProjector.project(
      snapshot: rhythm,
      direction: selection.direction,
      targetHandle: selection.target.handle,
      plane: state.plane,
      localClockDate: _clock.now(),
    );
    final colors = _colorsFor(selection.target, selection.direction);
    final next = DashboardBudgetRhythmState(
      projection: projection,
      startColorArgb: colors.$1,
      middleColorArgb: colors.$2,
      endColorArgb: colors.$3,
    );
    value = next;
    final signature = Object.hash(
      projection.coreRevision,
      projection.direction,
      projection.targetHandle,
      projection.plane,
      projection.windowStart,
      projection.windowEnd,
    );
    if (_lastDiagnosticSignature != signature) {
      _lastDiagnosticSignature = signature;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_RHYTHM_BOUND',
          coreRevision: projection.coreRevision,
          direction: projection.direction.name,
          scope:
              'plane=${projection.plane.name} '
              'targetHandle=${projection.targetHandle} '
              'windowStart=${_dateLabel(projection.windowStart)} '
              'windowEnd=${_dateLabel(projection.windowEnd)} '
              'barCount=${projection.bars.length} '
              'nonZeroBarCount=${projection.bars.where((bar) => bar.actualScaled100 > 0).length} '
              'maxActualScaled100=${projection.bars.fold<int>(0, (max, bar) => bar.actualScaled100 > max ? bar.actualScaled100 : max)}',
        ),
      );
    }
  }

  void _armNextLocalDayRollover() {
    _cancelRollover?.call();
    final now = _clock.now();
    final nextLocalDay = DateTime(now.year, now.month, now.day + 1);
    final delay = nextLocalDay.difference(now);
    _cancelRollover = _scheduleRollover(
      delay.isNegative || delay == Duration.zero
          ? const Duration(milliseconds: 1)
          : delay,
      () {
        _refresh();
        _armNextLocalDayRollover();
      },
    );
  }

  static VoidCallback _scheduleWithTimer(
    Duration delay,
    VoidCallback callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }

  static String _dateLabel(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  (int, int, int) _colorsFor(
    DashboardBudgetTarget target,
    LedgerDirection direction,
  ) {
    if (target.isAggregate) {
      final visual = DashboardBudgetAggregateVisual.forDirection(direction);
      return (
        visual.startColorArgb,
        visual.middleColorArgb,
        visual.endColorArgb,
      );
    }
    final gradient = CategoryColorCatalog.resolve(target.category!.colorId);
    return (
      gradient.colorA.toARGB32(),
      gradient.middleColor.toARGB32(),
      gradient.colorB.toARGB32(),
    );
  }

  @override
  void dispose() {
    _presentation.removeListener(_refresh);
    _navigation.removeListener(_refresh);
    _cancelRollover?.call();
    super.dispose();
  }
}

/// Pure RAM-only rolling-window projection. Navigation supplies only the
/// bucket granularity; the device-local clock supplies the calendar window.
abstract final class DashboardBudgetRhythmProjector {
  static DashboardBudgetRhythmProjection project({
    required PreparedBudgetRhythmSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required TimePlane plane,
    required DateTime localClockDate,
  }) {
    final points = snapshot
        .directionBank(direction)
        .pointsForTargetHandle(targetHandle);
    final windowEnd = localCalendarDay(localClockDate);
    late final DateTime windowStart;
    late final List<_RawRhythmBar> raw;
    switch (plane) {
      case TimePlane.month:
        windowStart = windowEnd.subtract(const Duration(days: 6));
        raw = _days(points, windowEnd);
      case TimePlane.year:
        windowStart = DateTime.utc(windowEnd.year, windowEnd.month - 5);
        raw = _months(points, windowEnd);
      case TimePlane.sum:
        windowStart = DateTime.utc(windowEnd.year - 4);
        raw = _years(points, windowEnd);
    }
    final max = raw.fold<int>(
      0,
      (current, bar) =>
          bar.actualScaled100 > current ? bar.actualScaled100 : current,
    );
    return DashboardBudgetRhythmProjection(
      coreRevision: snapshot.coreRevision,
      direction: direction,
      targetHandle: targetHandle,
      plane: plane,
      windowStart: windowStart,
      windowEnd: windowEnd,
      title: switch (plane) {
        TimePlane.month => '7 napos ritmus',
        TimePlane.year => '6 havi ritmus',
        TimePlane.sum => '5 éves ritmus',
      },
      bars: List<DashboardBudgetRhythmBar>.unmodifiable(
        <DashboardBudgetRhythmBar>[
          for (final bar in raw)
            DashboardBudgetRhythmBar(
              label: bar.label,
              actualScaled100: bar.actualScaled100,
              visualFraction: max == 0 ? 0 : bar.actualScaled100 / max,
            ),
        ],
      ),
    );
  }

  /// Maps the local wall-clock Y/M/D directly onto the UTC epoch-day calendar
  /// identity used by prepared local ledger-day points. This deliberately does
  /// not call [DateTime.toUtc], which could shift the intended local date.
  static DateTime localCalendarDay(DateTime localClockDate) => DateTime.utc(
    localClockDate.year,
    localClockDate.month,
    localClockDate.day,
  );

  static List<_RawRhythmBar> _days(
    List<PreparedBudgetRhythmPoint> points,
    DateTime windowEnd,
  ) {
    return <_RawRhythmBar>[
      for (var offset = 6; offset >= 0; offset -= 1)
        () {
          final date = windowEnd.subtract(Duration(days: offset));
          return _RawRhythmBar(
            label: _weekdayLabels[date.weekday - 1],
            actualScaled100: _sumForEpochRange(
              points,
              _epochDay(date),
              _epochDay(date),
            ),
          );
        }(),
    ];
  }

  static List<_RawRhythmBar> _months(
    List<PreparedBudgetRhythmPoint> points,
    DateTime windowEnd,
  ) => <_RawRhythmBar>[
    for (var offset = 5; offset >= 0; offset -= 1)
      () {
        final month = DateTime.utc(windowEnd.year, windowEnd.month - offset);
        final next = DateTime.utc(month.year, month.month + 1);
        return _RawRhythmBar(
          label: _monthLabels[month.month - 1],
          actualScaled100: _sumForEpochRange(
            points,
            _epochDay(month),
            _epochDay(next) - 1,
          ),
        );
      }(),
  ];

  static List<_RawRhythmBar> _years(
    List<PreparedBudgetRhythmPoint> points,
    DateTime windowEnd,
  ) => <_RawRhythmBar>[
    for (var year = windowEnd.year - 4; year <= windowEnd.year; year += 1)
      () {
        final start = DateTime.utc(year);
        final end = DateTime.utc(year + 1);
        return _RawRhythmBar(
          label: '$year',
          actualScaled100: _sumForEpochRange(
            points,
            _epochDay(start),
            _epochDay(end) - 1,
          ),
        );
      }(),
  ];

  static int _sumForEpochRange(
    List<PreparedBudgetRhythmPoint> points,
    int startInclusive,
    int endInclusive,
  ) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (points[middle].epochDay < startInclusive) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    var total = 0;
    for (
      var index = low;
      index < points.length && points[index].epochDay <= endInclusive;
      index += 1
    ) {
      total += points[index].actualScaled100;
    }
    return total;
  }

  static int _epochDay(DateTime date) =>
      date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static const _weekdayLabels = <String>[
    'H',
    'K',
    'Sze',
    'Cs',
    'P',
    'Szo',
    'V',
  ];
  static const _monthLabels = <String>[
    'jan',
    'feb',
    'már',
    'ápr',
    'máj',
    'jún',
    'júl',
    'aug',
    'sze',
    'okt',
    'nov',
    'dec',
  ];
}

@immutable
final class _RawRhythmBar {
  const _RawRhythmBar({required this.label, required this.actualScaled100});

  final String label;
  final int actualScaled100;
}
