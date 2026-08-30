import 'package:flutter/foundation.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../runtime/domain/prepared_spending_rhythm_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import 'dashboard_budget_presentation_controller.dart';
import 'dashboard_budget_live_analysis_projection.dart';
import 'dashboard_budget_target.dart';

@immutable
final class SpendingRhythmBucket {
  const SpendingRhythmBucket({
    required this.label,
    required this.accessibilityLabel,
    required this.actualScaled100,
  }) : assert(actualScaled100 >= 0);

  final String label;
  final String accessibilityLabel;
  final int actualScaled100;

  bool sameAs(SpendingRhythmBucket other) =>
      label == other.label &&
      accessibilityLabel == other.accessibilityLabel &&
      actualScaled100 == other.actualScaled100;
}

/// Closed scope catalogue: rendering never infers bucket identity from a
/// rolling window or a device clock.
sealed class SpendingRhythmAnalysis {
  const SpendingRhythmAnalysis({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.scope,
    required this.buckets,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final LedgerTimeScope scope;
  final List<SpendingRhythmBucket> buckets;

  int get maxBucketActualScaled100 => buckets.fold<int>(
    0,
    (maximum, bucket) =>
        bucket.actualScaled100 > maximum ? bucket.actualScaled100 : maximum,
  );

  /// Keep the average fractional until presentation. Rounding it in the
  /// projection would make sparse rhythms mathematically wrong (for example
  /// 5k, 20k, 10k and 0 average to 8.75k, not 8k).
  double get averageActualScaled100 => buckets.isEmpty
      ? 0
      : buckets.fold<int>(
              0,
              (total, bucket) => total + bucket.actualScaled100,
            ) /
            buckets.length;

  bool sameProjectionAs(SpendingRhythmAnalysis other) =>
      runtimeType == other.runtimeType &&
      coreRevision == other.coreRevision &&
      direction == other.direction &&
      targetHandle == other.targetHandle &&
      scope.canonicalKey == other.scope.canonicalKey &&
      buckets.length == other.buckets.length &&
      Iterable<int>.generate(
        buckets.length,
      ).every((index) => buckets[index].sameAs(other.buckets[index]));
}

final class DaySpendingRhythm extends SpendingRhythmAnalysis {
  const DaySpendingRhythm({
    required super.coreRevision,
    required super.direction,
    required super.targetHandle,
    required super.scope,
    required super.buckets,
  }) : assert(buckets.length == SpendingRhythmDayPart.bucketCount);
}

final class MonthSpendingRhythm extends SpendingRhythmAnalysis {
  const MonthSpendingRhythm({
    required super.coreRevision,
    required super.direction,
    required super.targetHandle,
    required super.scope,
    required super.buckets,
  }) : assert(buckets.length >= 28 && buckets.length <= 31);
}

final class YearSpendingRhythm extends SpendingRhythmAnalysis {
  const YearSpendingRhythm({
    required super.coreRevision,
    required super.direction,
    required super.targetHandle,
    required super.scope,
    required super.buckets,
  }) : assert(buckets.length == 12);
}

final class SumSpendingRhythm extends SpendingRhythmAnalysis {
  const SumSpendingRhythm({
    required super.coreRevision,
    required super.direction,
    required super.targetHandle,
    required super.scope,
    required super.buckets,
  });
}

final class UnavailableSpendingRhythm extends SpendingRhythmAnalysis {
  const UnavailableSpendingRhythm({
    required super.coreRevision,
    required super.direction,
    required super.targetHandle,
    required super.scope,
  }) : super(buckets: const <SpendingRhythmBucket>[]);
}

@immutable
final class DashboardSpendingRhythmState {
  const DashboardSpendingRhythmState({
    required this.analysis,
    required this.startColorArgb,
    required this.middleColorArgb,
    required this.endColorArgb,
  });

  final SpendingRhythmAnalysis analysis;
  final int startColorArgb;
  final int middleColorArgb;
  final int endColorArgb;

  bool sameAs(DashboardSpendingRhythmState other) =>
      startColorArgb == other.startColorArgb &&
      middleColorArgb == other.middleColorArgb &&
      endColorArgb == other.endColorArgb &&
      analysis.sameProjectionAs(other.analysis);
}

/// Pure scope projection over already prepared local-day data. It has no
/// clock, scheduler, rolling endpoint or repository dependency.
abstract final class DashboardSpendingRhythmProjector {
  static SpendingRhythmAnalysis project({
    required PreparedSpendingRhythmSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LedgerTimeScope scope,
  }) {
    final bank = snapshot.directionBank(direction);
    if (targetHandle < 0 || targetHandle >= bank.targetCount) {
      return UnavailableSpendingRhythm(
        coreRevision: snapshot.coreRevision,
        direction: direction,
        targetHandle: targetHandle,
        scope: scope,
      );
    }
    final target = bank.targetView(targetHandle);
    return switch (scope) {
      DayScope(:final date) => _day(
        snapshot,
        direction,
        targetHandle,
        date,
        target,
      ),
      MonthScope(:final value) => _month(
        snapshot,
        direction,
        targetHandle,
        value,
        target,
      ),
      YearScope(:final year) => _year(
        snapshot,
        direction,
        targetHandle,
        year,
        target,
      ),
      AllTimeScope() => _sum(snapshot, direction, targetHandle, scope, target),
    };
  }

  static DaySpendingRhythm _day(
    PreparedSpendingRhythmSnapshot snapshot,
    LedgerDirection direction,
    int targetHandle,
    LocalDate date,
    PreparedSpendingRhythmTargetView target,
  ) => DaySpendingRhythm(
    coreRevision: snapshot.coreRevision,
    direction: direction,
    targetHandle: targetHandle,
    scope: DayScope(date),
    buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
      for (final part in SpendingRhythmDayPart.values)
        SpendingRhythmBucket(
          label: part.displayLabel,
          accessibilityLabel: part.label,
          actualScaled100: target.actualForDayPartAtEpochDay(
            epochDay: date.epochDay,
            part: part,
          ),
        ),
    ]),
  );

  static MonthSpendingRhythm _month(
    PreparedSpendingRhythmSnapshot snapshot,
    LedgerDirection direction,
    int targetHandle,
    YearMonth month,
    PreparedSpendingRhythmTargetView target,
  ) => MonthSpendingRhythm(
    coreRevision: snapshot.coreRevision,
    direction: direction,
    targetHandle: targetHandle,
    scope: MonthScope(month),
    buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
      for (var day = 1; day <= month.daysInMonth; day += 1)
        SpendingRhythmBucket(
          label: '$day',
          accessibilityLabel: '$day',
          actualScaled100: target.actualAtEpochDay(
            LocalDate(year: month.year, month: month.month, day: day).epochDay,
          ),
        ),
    ]),
  );

  static YearSpendingRhythm _year(
    PreparedSpendingRhythmSnapshot snapshot,
    LedgerDirection direction,
    int targetHandle,
    int year,
    PreparedSpendingRhythmTargetView target,
  ) => YearSpendingRhythm(
    coreRevision: snapshot.coreRevision,
    direction: direction,
    targetHandle: targetHandle,
    scope: YearScope(year),
    buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
      for (var month = 1; month <= 12; month += 1)
        SpendingRhythmBucket(
          label: _monthLabels[month - 1],
          accessibilityLabel: _monthLabels[month - 1],
          actualScaled100: target.actualForMonth(year: year, month: month),
        ),
    ]),
  );

  static SpendingRhythmAnalysis _sum(
    PreparedSpendingRhythmSnapshot snapshot,
    LedgerDirection direction,
    int targetHandle,
    LedgerTimeScope scope,
    PreparedSpendingRhythmTargetView target,
  ) {
    if (target.isEmpty) {
      return UnavailableSpendingRhythm(
        coreRevision: snapshot.coreRevision,
        direction: direction,
        targetHandle: targetHandle,
        scope: scope,
      );
    }
    final firstYear = target.firstYear!;
    final lastYear = target.lastYear!;
    return SumSpendingRhythm(
      coreRevision: snapshot.coreRevision,
      direction: direction,
      targetHandle: targetHandle,
      scope: scope,
      buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
        for (var year = firstYear; year <= lastYear; year += 1)
          SpendingRhythmBucket(
            label: '$year',
            accessibilityLabel: '$year',
            actualScaled100: target.actualForYear(year),
          ),
      ]),
    );
  }

  static const List<String> _monthLabels = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MÁJ',
    'JÚN',
    'JÚL',
    'AUG',
    'SZE',
    'OKT',
    'NOV',
    'DEC',
  ];
}

/// CoreDashboard-lifetime publication binding. The typed Budget live analysis
/// projection is the preview authority, so a retained LogBox scene is never a
/// prerequisite for a scope-aware Rhythm update.
final class DashboardSpendingRhythmController
    extends ValueNotifier<DashboardSpendingRhythmState?> {
  DashboardSpendingRhythmController({
    required DashboardBudgetPresentationController presentation,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
  }) : _presentation = presentation,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       super(null) {
    _presentation.addListener(_refresh);
    _refresh();
  }

  final DashboardBudgetPresentationController _presentation;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  int? _lastDiagnosticSignature;
  int? _lastStateDiagnosticSignature;

  void _refresh() {
    final snapshot = _snapshotForCurrentFrame();
    final presentation = _presentation.value;
    final selection = presentation.liveSelection;
    final liveAnalysis = presentation.liveAnalysis;
    final rhythm = snapshot?.spendingRhythmSnapshot;
    final unavailableReason = snapshot == null
        ? 'snapshotAbsent'
        : rhythm == null
        ? 'rhythmSnapshotAbsent'
        : !liveAnalysis.isAvailable
        ? 'liveAnalysisUnavailable'
        : !selection.isAvailable
        ? 'selectionUnavailable'
        : liveAnalysis.coreRevision != snapshot.coreRevision
        ? 'analysisRevisionMismatch'
        : liveAnalysis.direction != selection.direction
        ? 'directionMismatch'
        : liveAnalysis.targetHandle != selection.target.handle
        ? 'targetMismatch'
        : selection.coreRevision != snapshot.coreRevision
        ? 'selectionRevisionMismatch'
        : rhythm.coreRevision != snapshot.coreRevision
        ? 'rhythmRevisionMismatch'
        : selection.target.handle >=
              rhythm.directionBank(selection.direction).targetCount
        ? 'targetOutsideRhythmBank'
        : null;
    if (unavailableReason != null) {
      _recordState(
        availability: 'unavailable',
        reason: unavailableReason,
        snapshot: snapshot,
        liveAnalysis: liveAnalysis,
        selection: selection,
        rhythm: rhythm,
      );
      if (value != null) value = null;
      return;
    }
    final resolvedRhythm = rhythm!;
    final scope = liveAnalysis.scope!;
    final analysis = DashboardSpendingRhythmProjector.project(
      snapshot: resolvedRhythm,
      direction: selection.direction,
      targetHandle: selection.target.handle,
      scope: scope,
    );
    final colors = _colorsFor(selection.target, selection.direction);
    final next = DashboardSpendingRhythmState(
      analysis: analysis,
      startColorArgb: colors.$1,
      middleColorArgb: colors.$2,
      endColorArgb: colors.$3,
    );
    if (value == null || !value!.sameAs(next)) value = next;
    _recordState(
      availability: 'available',
      reason: 'bound',
      snapshot: snapshot,
      liveAnalysis: liveAnalysis,
      selection: selection,
      rhythm: resolvedRhythm,
    );
    final signature = Object.hash(
      liveAnalysis.interactionGeneration,
      analysis.coreRevision,
      analysis.direction,
      analysis.targetHandle,
      analysis.scope,
      analysis.buckets.length,
    );
    if (_lastDiagnosticSignature != signature) {
      _lastDiagnosticSignature = signature;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SPENDING_RHYTHM_BOUND',
          coreRevision: analysis.coreRevision,
          direction: analysis.direction.name,
          scope:
              '${analysis.scope.canonicalKey} '
              'generation=${liveAnalysis.interactionGeneration} '
              'targetHandle=${analysis.targetHandle} '
              'barCount=${analysis.buckets.length} '
              'nonZeroBarCount=${analysis.buckets.where((bucket) => bucket.actualScaled100 > 0).length}',
        ),
      );
    }
  }

  void _recordState({
    required String availability,
    required String reason,
    required PreparedBudgetLimitSnapshot? snapshot,
    required DashboardBudgetLiveAnalysisProjection liveAnalysis,
    required DashboardBudgetLiveSelectionState selection,
    required PreparedSpendingRhythmSnapshot? rhythm,
  }) {
    final signature = Object.hash(
      availability,
      reason,
      snapshot?.coreRevision,
      rhythm?.coreRevision,
      liveAnalysis.provenanceKey,
      selection.coreRevision,
      selection.target.handle,
      selection.direction,
    );
    if (_lastStateDiagnosticSignature == signature) return;
    _lastStateDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SPENDING_RHYTHM|STATE',
        coreRevision: liveAnalysis.coreRevision ?? snapshot?.coreRevision,
        direction: selection.direction.name,
        scope:
            'availability=$availability reason=$reason '
            'snapshotRevision=${snapshot?.coreRevision ?? '-'} '
            'rhythmRevision=${rhythm?.coreRevision ?? '-'} '
            'analysisAvailable=${liveAnalysis.isAvailable} '
            'analysisRevision=${liveAnalysis.coreRevision ?? '-'} '
            'analysisDirection=${liveAnalysis.direction.name} '
            'analysisTarget=${liveAnalysis.targetHandle} '
            'analysisScope=${liveAnalysis.scope?.canonicalKey ?? '-'} '
            'selectionAvailable=${selection.isAvailable} '
            'selectionRevision=${selection.coreRevision ?? '-'} '
            'selectionTarget=${selection.target.handle} '
            'rhythmTargetCount=${rhythm == null ? '-' : rhythm.directionBank(selection.direction).targetCount}',
      ),
    );
  }

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
    super.dispose();
  }
}
