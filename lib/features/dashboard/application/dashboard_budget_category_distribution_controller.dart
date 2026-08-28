import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../runtime/domain/prepared_spending_rhythm_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/year_month.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_period.dart';

/// Exact identity of one RAM-only Budget distribution. Direction deliberately
/// is not part of the key: one prepared snapshot already contains both banks.
@immutable
final class DashboardBudgetCategoryDistributionKey {
  const DashboardBudgetCategoryDistributionKey._({
    required this.coreRevision,
    required this.analysisScope,
  });

  factory DashboardBudgetCategoryDistributionKey.fromScope({
    required int coreRevision,
    required LedgerTimeScope scope,
  }) => DashboardBudgetCategoryDistributionKey._(
    coreRevision: coreRevision,
    analysisScope: scope,
  );

  factory DashboardBudgetCategoryDistributionKey.fromPeriod({
    required int coreRevision,
    required BudgetLimitPeriod period,
  }) => switch (period) {
    BudgetLimitSumPeriod() => DashboardBudgetCategoryDistributionKey._(
      coreRevision: coreRevision,
      analysisScope: const AllTimeScope(),
    ),
    BudgetLimitYearPeriod(:final year) =>
      DashboardBudgetCategoryDistributionKey._(
        coreRevision: coreRevision,
        analysisScope: YearScope(year),
      ),
    BudgetLimitMonthPeriod(:final year, :final month) =>
      DashboardBudgetCategoryDistributionKey._(
        coreRevision: coreRevision,
        analysisScope: MonthScope(YearMonth(year: year, month: month)),
      ),
  };

  final int coreRevision;
  final LedgerTimeScope analysisScope;

  String get diagnosticLabel => analysisScope.canonicalKey;

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetCategoryDistributionKey &&
      other.coreRevision == coreRevision &&
      other.analysisScope == analysisScope;

  @override
  int get hashCode => Object.hash(coreRevision, analysisScope);
}

/// A category sector/list row. Monetary input stays exact integer scaled-100.
@immutable
final class DashboardBudgetCategoryDistributionEntry {
  const DashboardBudgetCategoryDistributionEntry({
    required this.targetHandle,
    required this.categoryId,
    required this.title,
    required this.colorId,
    required this.iconId,
    required this.actualScaled100,
    required this.roundedPercent,
  });

  final int targetHandle;
  final String categoryId;
  final String title;
  final String colorId;
  final String iconId;
  final int actualScaled100;
  final int roundedPercent;
}

/// One direction-local, sorted chart/list domain. Handle zero is intentionally
/// absent from [entries] and maps to -1 in [targetHandleToSliceIndex].
@immutable
final class DashboardBudgetCategoryDistributionDirectionFrame {
  DashboardBudgetCategoryDistributionDirectionFrame({
    required this.direction,
    required List<DashboardBudgetCategoryDistributionEntry> entries,
    required this.totalCategoryActualScaled100,
    required this.targetCount,
    required List<int> targetHandleToSliceIndex,
    required List<int> positiveValues,
  }) : entries = List<DashboardBudgetCategoryDistributionEntry>.unmodifiable(
         entries,
       ),
       targetHandleToSliceIndex = List<int>.unmodifiable(
         targetHandleToSliceIndex,
       ),
       positiveValues = List<int>.unmodifiable(positiveValues);

  final LedgerDirection direction;
  final List<DashboardBudgetCategoryDistributionEntry> entries;
  final int totalCategoryActualScaled100;
  final int targetCount;
  final List<int> targetHandleToSliceIndex;
  final List<int> positiveValues;

  int sliceIndexForTargetHandle(int targetHandle) =>
      targetHandle < 0 || targetHandle >= targetHandleToSliceIndex.length
      ? -1
      : targetHandleToSliceIndex[targetHandle];
}

/// Both direction frames for one exact revision + period. This immutable
/// semantic bundle has no selected target, Query, renderer or motion state.
@immutable
final class DashboardBudgetCategoryDistributionBundle {
  const DashboardBudgetCategoryDistributionBundle({
    required this.key,
    required this.analysisScope,
    required this.persistedLimitPeriod,
    required this.income,
    required this.expense,
    this.projectionMicros = 0,
  });

  final DashboardBudgetCategoryDistributionKey key;
  final LedgerTimeScope analysisScope;

  /// Kept explicit so a Day analysis frame can retain the containing-month
  /// persisted limit denominator without making that Month its chart key.
  final BudgetLimitPeriod persistedLimitPeriod;

  @Deprecated('Use analysisScope or persistedLimitPeriod explicitly.')
  BudgetLimitPeriod get period => persistedLimitPeriod;
  final DashboardBudgetCategoryDistributionDirectionFrame income;
  final DashboardBudgetCategoryDistributionDirectionFrame expense;
  final int projectionMicros;

  /// A direct projector call always creates both direction frames together.
  /// This test-visible value guards against a direction-switch re-projection.
  int get projectionCount => 1;

  DashboardBudgetCategoryDistributionBundle withProjectionMicros(int value) =>
      DashboardBudgetCategoryDistributionBundle(
        key: key,
        analysisScope: analysisScope,
        persistedLimitPeriod: persistedLimitPeriod,
        income: income,
        expense: expense,
        projectionMicros: value,
      );

  DashboardBudgetCategoryDistributionDirectionFrame frameFor(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => income,
    LedgerDirection.expense => expense,
  };
}

/// Pure projection of the already-prepared exact cells. It never has access
/// to repositories, Query state or transaction rows.
abstract final class DashboardBudgetCategoryDistributionProjector {
  static DashboardBudgetCategoryDistributionBundle project({
    required PreparedBudgetLimitSnapshot snapshot,
    required List<FluviCategory> categories,
    required BudgetLimitPeriod period,
  }) => projectForScope(
    snapshot: snapshot,
    categories: categories,
    scope: _scopeForPeriod(period),
  );

  /// Projects the exact visible analysis scope. Financial-limit persistence
  /// is deliberately resolved separately so Day charts never collapse into a
  /// containing Month frame.
  static DashboardBudgetCategoryDistributionBundle projectForScope({
    required PreparedBudgetLimitSnapshot snapshot,
    required List<FluviCategory> categories,
    required LedgerTimeScope scope,
  }) {
    final categoryById = <String, FluviCategory>{
      for (final category in categories) category.id: category,
    };
    final persistedLimitPeriod = DashboardBudgetPeriodResolver.fromTimeScope(
      scope,
    );
    return DashboardBudgetCategoryDistributionBundle(
      key: DashboardBudgetCategoryDistributionKey.fromScope(
        coreRevision: snapshot.coreRevision,
        scope: scope,
      ),
      analysisScope: scope,
      persistedLimitPeriod: persistedLimitPeriod,
      income: _frame(
        snapshot: snapshot,
        categoryById: categoryById,
        scope: scope,
        direction: LedgerDirection.income,
      ),
      expense: _frame(
        snapshot: snapshot,
        categoryById: categoryById,
        scope: scope,
        direction: LedgerDirection.expense,
      ),
    );
  }

  static DashboardBudgetCategoryDistributionDirectionFrame _frame({
    required PreparedBudgetLimitSnapshot snapshot,
    required Map<String, FluviCategory> categoryById,
    required LedgerTimeScope scope,
    required LedgerDirection direction,
  }) {
    final bank = snapshot.directionBank(direction);
    final raw = <_RawDistributionEntry>[];
    for (
      var categoryIndex = 0;
      categoryIndex < bank.orderedCategoryIds.length;
      categoryIndex += 1
    ) {
      final categoryId = bank.orderedCategoryIds[categoryIndex];
      final category = categoryById[categoryId];
      if (category == null) {
        throw StateError(
          'Budget distribution category $categoryId is missing from the '
          'authoritative category collection.',
        );
      }
      final targetHandle = categoryIndex + 1;
      final actual = _actualFor(
        snapshot: snapshot,
        direction: direction,
        scope: scope,
        targetHandle: targetHandle,
      );
      if (actual <= 0) continue;
      raw.add(
        _RawDistributionEntry(
          targetHandle: targetHandle,
          category: category,
          actualScaled100: actual,
        ),
      );
    }
    raw.sort((left, right) {
      final byActual = right.actualScaled100.compareTo(left.actualScaled100);
      return byActual != 0
          ? byActual
          : left.targetHandle.compareTo(right.targetHandle);
    });
    final total = raw.fold<int>(0, (sum, entry) => sum + entry.actualScaled100);
    final sliceByHandle = List<int>.filled(bank.targetCount, -1);
    final entries = <DashboardBudgetCategoryDistributionEntry>[];
    for (var index = 0; index < raw.length; index += 1) {
      final entry = raw[index];
      sliceByHandle[entry.targetHandle] = index;
      entries.add(
        DashboardBudgetCategoryDistributionEntry(
          targetHandle: entry.targetHandle,
          categoryId: entry.category.id,
          title: entry.category.name,
          colorId: entry.category.colorId,
          iconId: entry.category.iconId,
          actualScaled100: entry.actualScaled100,
          roundedPercent: total == 0
              ? 0
              : (entry.actualScaled100 * 100 + total ~/ 2) ~/ total,
        ),
      );
    }
    return DashboardBudgetCategoryDistributionDirectionFrame(
      direction: direction,
      entries: entries,
      totalCategoryActualScaled100: total,
      targetCount: bank.targetCount,
      targetHandleToSliceIndex: sliceByHandle,
      positiveValues: <int>[for (final entry in raw) entry.actualScaled100],
    );
  }

  static int _actualFor({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required LedgerTimeScope scope,
    required int targetHandle,
  }) => switch (scope) {
    DayScope(:final date) => _rhythmFor(
      snapshot,
      direction,
    ).targetView(targetHandle).actualAtEpochDay(date.epochDay),
    _ =>
      snapshot
          .cellAt(
            direction: direction,
            period: DashboardBudgetPeriodResolver.fromTimeScope(scope),
            targetHandle: targetHandle,
          )
          .actualScaled100,
  };

  static PreparedSpendingRhythmDirectionBank _rhythmFor(
    PreparedBudgetLimitSnapshot snapshot,
    LedgerDirection direction,
  ) {
    final rhythm = snapshot.spendingRhythmSnapshot;
    if (rhythm == null || rhythm.coreRevision != snapshot.coreRevision) {
      throw StateError('Exact prepared Budget daily rhythm is unavailable.');
    }
    return rhythm.directionBank(direction);
  }

  static LedgerTimeScope _scopeForPeriod(BudgetLimitPeriod period) =>
      switch (period) {
        BudgetLimitSumPeriod() => const AllTimeScope(),
        BudgetLimitYearPeriod(:final year) => YearScope(year),
        BudgetLimitMonthPeriod(:final year, :final month) => MonthScope(
          YearMonth(year: year, month: month),
        ),
      };
}

final class _RawDistributionEntry {
  const _RawDistributionEntry({
    required this.targetHandle,
    required this.category,
    required this.actualScaled100,
  });

  final int targetHandle;
  final FluviCategory category;
  final int actualScaled100;
}

/// Small LRU for prepared RAM bundles. It intentionally caches only semantic
/// period bundles; renderer banks retain their own matching bounded entries.
final class DashboardBudgetCategoryDistributionBundleCache {
  DashboardBudgetCategoryDistributionBundleCache({this.maximumBundles = 3})
    : assert(maximumBundles > 0);

  final int maximumBundles;
  final LinkedHashMap<
    DashboardBudgetCategoryDistributionKey,
    DashboardBudgetCategoryDistributionBundle
  >
  _bundles =
      LinkedHashMap<
        DashboardBudgetCategoryDistributionKey,
        DashboardBudgetCategoryDistributionBundle
      >();
  int projectionCount = 0;
  int evictionCount = 0;

  int get retainedBundleCount => _bundles.length;

  DashboardBudgetCategoryDistributionBundle? peek(
    DashboardBudgetCategoryDistributionKey key,
  ) => _bundles[key];

  DashboardBudgetCategoryDistributionBundle resolve({
    required PreparedBudgetLimitSnapshot snapshot,
    required List<FluviCategory> categories,
    required BudgetLimitPeriod period,
  }) {
    final key = DashboardBudgetCategoryDistributionKey.fromPeriod(
      coreRevision: snapshot.coreRevision,
      period: period,
    );
    final retained = _bundles.remove(key);
    if (retained != null) {
      _bundles[key] = retained;
      return retained;
    }
    final stopwatch = Stopwatch()..start();
    final projected = DashboardBudgetCategoryDistributionProjector.project(
      snapshot: snapshot,
      categories: categories,
      period: period,
    );
    stopwatch.stop();
    final next = projected.withProjectionMicros(stopwatch.elapsedMicroseconds);
    projectionCount += 1;
    _bundles[key] = next;
    while (_bundles.length > maximumBundles) {
      _bundles.remove(_bundles.keys.first);
      evictionCount += 1;
    }
    return next;
  }

  DashboardBudgetCategoryDistributionBundle resolveForScope({
    required PreparedBudgetLimitSnapshot snapshot,
    required List<FluviCategory> categories,
    required LedgerTimeScope scope,
  }) {
    final key = DashboardBudgetCategoryDistributionKey.fromScope(
      coreRevision: snapshot.coreRevision,
      scope: scope,
    );
    final retained = _bundles.remove(key);
    if (retained != null) {
      _bundles[key] = retained;
      return retained;
    }
    final stopwatch = Stopwatch()..start();
    final projected =
        DashboardBudgetCategoryDistributionProjector.projectForScope(
          snapshot: snapshot,
          categories: categories,
          scope: scope,
        );
    stopwatch.stop();
    final next = projected.withProjectionMicros(stopwatch.elapsedMicroseconds);
    projectionCount += 1;
    _bundles[key] = next;
    while (_bundles.length > maximumBundles) {
      _bundles.remove(_bundles.keys.first);
      evictionCount += 1;
    }
    return next;
  }

  void clear() => _bundles.clear();
}

/// CoreDashboard-lifetime headless owner of prepared category distribution
/// bundles. Its only inputs are exact visible-time/snapshot/category metadata.
/// Query state and selected target intentionally do not appear in this API.
final class DashboardBudgetCategoryDistributionController
    extends ValueNotifier<DashboardBudgetCategoryDistributionBundle?> {
  DashboardBudgetCategoryDistributionController({
    required ValueListenable<List<FluviCategory>> categoryCollection,
    required ValueListenable<DashboardVisibleFrame?> visibleFrame,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
    DashboardBudgetCategoryDistributionBundleCache? cache,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _cache = cache ?? DashboardBudgetCategoryDistributionBundleCache(),
       super(null) {
    _categoryCollection.addListener(_invalidateForCategoryMetadata);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _refreshForVisibleFrame();
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final DashboardBudgetCategoryDistributionBundleCache _cache;

  int get projectionCount => _cache.projectionCount;
  int get retainedBundleCount => _cache.retainedBundleCount;
  int get evictionCount => _cache.evictionCount;

  void _invalidateForCategoryMetadata() {
    _cache.clear();
    _refreshForVisibleFrame();
  }

  void _refreshForVisibleFrame() {
    final frame = _visibleFrame.value;
    final snapshot = _snapshotForCurrentFrame();
    if (frame == null ||
        snapshot == null ||
        frame.coreRevision != snapshot.coreRevision) {
      if (value != null) value = null;
      return;
    }
    final scope = frame.scope.timeScope;
    final key = DashboardBudgetCategoryDistributionKey.fromScope(
      coreRevision: snapshot.coreRevision,
      scope: scope,
    );
    final cacheHit = _cache.peek(key) != null;
    if (!cacheHit) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_PREPARE_STARTED',
          coreRevision: snapshot.coreRevision,
          scope: key.diagnosticLabel,
        ),
      );
    }
    try {
      final bundle = _cache.resolveForScope(
        snapshot: snapshot,
        categories: _categoryCollection.value,
        scope: scope,
      );
      if (cacheHit) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'BUDGET_DISTRIBUTION_REUSED',
            coreRevision: bundle.key.coreRevision,
            scope: '${bundle.key.diagnosticLabel} cacheHit=true',
          ),
        );
      }
      if (!identical(value, bundle)) value = bundle;
    } on Object catch (error) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_INVARIANT_FAILED',
          coreRevision: snapshot.coreRevision,
          scope: key.diagnosticLabel,
          error: '$error',
        ),
      );
      if (value != null) value = null;
    }
  }

  @override
  void dispose() {
    _categoryCollection.removeListener(_invalidateForCategoryMetadata);
    _visibleFrame.removeListener(_refreshForVisibleFrame);
    super.dispose();
  }
}
