import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/year_month.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_period.dart';

/// Exact period identity for a query-independent Partner distribution. Both
/// directions deliberately share one key because a prepared snapshot owns
/// their immutable banks together.
@immutable
final class DashboardBudgetPartnerDistributionKey {
  const DashboardBudgetPartnerDistributionKey._({
    required this.coreRevision,
    required this.analysisScope,
  });

  factory DashboardBudgetPartnerDistributionKey.fromScope({
    required int coreRevision,
    required LedgerTimeScope scope,
  }) => DashboardBudgetPartnerDistributionKey._(
    coreRevision: coreRevision,
    analysisScope: scope,
  );

  factory DashboardBudgetPartnerDistributionKey.fromPeriod({
    required int coreRevision,
    required BudgetLimitPeriod period,
  }) => switch (period) {
    BudgetLimitSumPeriod() => DashboardBudgetPartnerDistributionKey._(
      coreRevision: coreRevision,
      analysisScope: const AllTimeScope(),
    ),
    BudgetLimitYearPeriod(:final year) =>
      DashboardBudgetPartnerDistributionKey._(
        coreRevision: coreRevision,
        analysisScope: YearScope(year),
      ),
    BudgetLimitMonthPeriod(:final year, :final month) =>
      DashboardBudgetPartnerDistributionKey._(
        coreRevision: coreRevision,
        analysisScope: MonthScope(YearMonth(year: year, month: month)),
      ),
  };

  final int coreRevision;
  final LedgerTimeScope analysisScope;

  String get diagnosticLabel => analysisScope.canonicalKey;

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetPartnerDistributionKey &&
      other.coreRevision == coreRevision &&
      other.analysisScope == analysisScope;

  @override
  int get hashCode => Object.hash(coreRevision, analysisScope);
}

@immutable
final class DashboardBudgetPartnerDistributionEntry {
  const DashboardBudgetPartnerDistributionEntry({
    required this.partnerHandle,
    required this.partnerId,
    required this.title,
    required this.colorId,
    required this.actualScaled100,
    required this.roundedPercent,
  });

  final int partnerHandle;
  final String partnerId;
  final String title;
  final String colorId;
  final int actualScaled100;
  final int roundedPercent;
}

@immutable
final class DashboardBudgetPartnerDistributionDirectionFrame {
  DashboardBudgetPartnerDistributionDirectionFrame({
    required this.direction,
    required this.targetHandle,
    required this.partnerCount,
    required List<DashboardBudgetPartnerDistributionEntry> entries,
    required this.totalPartnerActualScaled100,
    required List<int> positiveValues,
  }) : entries = List<DashboardBudgetPartnerDistributionEntry>.unmodifiable(
         entries,
       ),
       positiveValues = List<int>.unmodifiable(positiveValues);

  final LedgerDirection direction;

  /// Aggregate is handle zero; category handles use the exact matching Budget
  /// direction-local domain and never a global category index.
  final int targetHandle;
  final int partnerCount;
  final List<DashboardBudgetPartnerDistributionEntry> entries;
  final int totalPartnerActualScaled100;
  final List<int> positiveValues;
}

@immutable
final class DashboardBudgetPartnerDistributionBundle {
  DashboardBudgetPartnerDistributionBundle({
    required this.key,
    required this.analysisScope,
    required this.persistedLimitPeriod,
    required this.income,
    required this.expense,
    List<DashboardBudgetPartnerDistributionDirectionFrame>? incomeTargetFrames,
    List<DashboardBudgetPartnerDistributionDirectionFrame>? expenseTargetFrames,
    this.projectionMicros = 0,
  }) : incomeTargetFrames =
           List<DashboardBudgetPartnerDistributionDirectionFrame>.unmodifiable(
             incomeTargetFrames ??
                 <DashboardBudgetPartnerDistributionDirectionFrame>[income],
           ),
       expenseTargetFrames =
           List<DashboardBudgetPartnerDistributionDirectionFrame>.unmodifiable(
             expenseTargetFrames ??
                 <DashboardBudgetPartnerDistributionDirectionFrame>[expense],
           );

  final DashboardBudgetPartnerDistributionKey key;
  final LedgerTimeScope analysisScope;
  final BudgetLimitPeriod persistedLimitPeriod;

  @Deprecated('Use analysisScope or persistedLimitPeriod explicitly.')
  BudgetLimitPeriod get period => persistedLimitPeriod;
  final DashboardBudgetPartnerDistributionDirectionFrame income;
  final DashboardBudgetPartnerDistributionDirectionFrame expense;
  final List<DashboardBudgetPartnerDistributionDirectionFrame>
  incomeTargetFrames;
  final List<DashboardBudgetPartnerDistributionDirectionFrame>
  expenseTargetFrames;
  final int projectionMicros;

  DashboardBudgetPartnerDistributionBundle withProjectionMicros(int value) =>
      DashboardBudgetPartnerDistributionBundle(
        key: key,
        analysisScope: analysisScope,
        persistedLimitPeriod: persistedLimitPeriod,
        income: income,
        expense: expense,
        incomeTargetFrames: incomeTargetFrames,
        expenseTargetFrames: expenseTargetFrames,
        projectionMicros: value,
      );

  DashboardBudgetPartnerDistributionDirectionFrame frameFor(
    LedgerDirection direction, {
    int targetHandle = 0,
  }) {
    final frames = switch (direction) {
      LedgerDirection.income => incomeTargetFrames,
      LedgerDirection.expense => expenseTargetFrames,
    };
    if (targetHandle < 0 || targetHandle >= frames.length) {
      throw RangeError.range(
        targetHandle,
        0,
        frames.length - 1,
        'targetHandle',
      );
    }
    return frames[targetHandle];
  }
}

/// Pure RAM projection. No Query, repository, bridge or transaction rows are
/// reachable from this API. The native snapshot supplies dominant category
/// identity, so partner colour remains deterministic for exact data.
abstract final class DashboardBudgetPartnerDistributionProjector {
  static DashboardBudgetPartnerDistributionBundle project({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required List<FluviCategory> categories,
    required BudgetLimitPeriod period,
  }) => projectForScope(
    snapshot: snapshot,
    categories: categories,
    scope: _scopeForPeriod(period),
  );

  static DashboardBudgetPartnerDistributionBundle projectForScope({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required List<FluviCategory> categories,
    required LedgerTimeScope scope,
  }) {
    final categoryById = <String, FluviCategory>{
      for (final category in categories) category.id: category,
    };
    final incomeFrames = _framesForDirection(
      snapshot: snapshot,
      categoryById: categoryById,
      scope: scope,
      direction: LedgerDirection.income,
    );
    final expenseFrames = _framesForDirection(
      snapshot: snapshot,
      categoryById: categoryById,
      scope: scope,
      direction: LedgerDirection.expense,
    );
    return DashboardBudgetPartnerDistributionBundle(
      key: DashboardBudgetPartnerDistributionKey.fromScope(
        coreRevision: snapshot.coreRevision,
        scope: scope,
      ),
      analysisScope: scope,
      persistedLimitPeriod: DashboardBudgetPeriodResolver.fromTimeScope(scope),
      income: incomeFrames.first,
      expense: expenseFrames.first,
      incomeTargetFrames: incomeFrames,
      expenseTargetFrames: expenseFrames,
    );
  }

  static List<DashboardBudgetPartnerDistributionDirectionFrame>
  _framesForDirection({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required Map<String, FluviCategory> categoryById,
    required LedgerTimeScope scope,
    required LedgerDirection direction,
  }) {
    final bank = snapshot.directionBank(direction);
    return List<DashboardBudgetPartnerDistributionDirectionFrame>.unmodifiable([
      for (
        var targetHandle = 0;
        targetHandle < bank.categoryTargetCount;
        targetHandle += 1
      )
        _frame(
          snapshot: snapshot,
          categoryById: categoryById,
          scope: scope,
          direction: direction,
          targetHandle: targetHandle,
        ),
    ]);
  }

  static DashboardBudgetPartnerDistributionDirectionFrame _frame({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required Map<String, FluviCategory> categoryById,
    required LedgerTimeScope scope,
    required LedgerDirection direction,
    required int targetHandle,
  }) {
    final bank = snapshot.directionBank(direction);
    final raw = <_RawPartnerDistributionEntry>[];
    final amounts = _amountsFor(
      snapshot: snapshot,
      direction: direction,
      scope: scope,
      targetHandle: targetHandle,
    );
    for (final amount in amounts) {
      if (amount.actualScaled100 <= 0) continue;
      final handle = amount.partnerHandle;
      final category = categoryById[amount.dominantCategoryId];
      if (category == null) {
        throw StateError(
          'Prepared partner distribution colour category '
          '${amount.dominantCategoryId} is unavailable.',
        );
      }
      raw.add(
        _RawPartnerDistributionEntry(
          partnerHandle: handle,
          partnerId: bank.orderedPartnerIds[handle],
          title: bank.orderedPartnerTitles[handle],
          colorId: category.colorId,
          actualScaled100: amount.actualScaled100,
        ),
      );
    }
    raw.sort((left, right) {
      final byActual = right.actualScaled100.compareTo(left.actualScaled100);
      return byActual != 0
          ? byActual
          : left.partnerHandle.compareTo(right.partnerHandle);
    });
    final total = raw.fold<int>(0, (sum, entry) => sum + entry.actualScaled100);
    final entries = <DashboardBudgetPartnerDistributionEntry>[
      for (final entry in raw)
        DashboardBudgetPartnerDistributionEntry(
          partnerHandle: entry.partnerHandle,
          partnerId: entry.partnerId,
          title: entry.title,
          colorId: entry.colorId,
          actualScaled100: entry.actualScaled100,
          roundedPercent: total == 0
              ? 0
              : (entry.actualScaled100 * 100 + total ~/ 2) ~/ total,
        ),
    ];
    return DashboardBudgetPartnerDistributionDirectionFrame(
      direction: direction,
      targetHandle: targetHandle,
      partnerCount: bank.partnerCount,
      entries: entries,
      totalPartnerActualScaled100: total,
      positiveValues: <int>[for (final entry in raw) entry.actualScaled100],
    );
  }

  static List<_PartnerAmount> _amountsFor({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required LedgerDirection direction,
    required LedgerTimeScope scope,
    required int targetHandle,
  }) {
    final bank = snapshot.directionBank(direction);
    if (scope case DayScope(:final date)) {
      final epochDay = date.epochDay;
      if (targetHandle == 0) {
        return List<_PartnerAmount>.unmodifiable([
          for (final cell in bank.dayAggregateFor(epochDay))
            _PartnerAmount(
              partnerHandle: cell.partnerHandle,
              actualScaled100: cell.actualScaled100,
              dominantCategoryId: cell.dominantCategoryId,
            ),
        ]);
      }
      return List<_PartnerAmount>.unmodifiable([
        for (final contribution in bank.dayContributionsFor(
          epochDay: epochDay,
          targetHandle: targetHandle,
        ))
          _PartnerAmount(
            partnerHandle: contribution.partnerHandle,
            actualScaled100: contribution.actualScaled100,
            dominantCategoryId:
                bank.dayDominantCategoryIdFor(
                  epochDay: epochDay,
                  partnerHandle: contribution.partnerHandle,
                ) ??
                '',
          ),
      ]);
    }
    final period = DashboardBudgetPeriodResolver.fromTimeScope(scope);
    return List<_PartnerAmount>.unmodifiable([
      if (targetHandle == 0)
        for (var handle = 0; handle < bank.partnerCount; handle += 1)
          if (snapshot
                  .cellAt(
                    direction: direction,
                    period: period,
                    partnerHandle: handle,
                  )
                  .actualScaled100 >
              0)
            _PartnerAmount(
              partnerHandle: handle,
              actualScaled100: snapshot
                  .cellAt(
                    direction: direction,
                    period: period,
                    partnerHandle: handle,
                  )
                  .actualScaled100,
              dominantCategoryId: snapshot
                  .cellAt(
                    direction: direction,
                    period: period,
                    partnerHandle: handle,
                  )
                  .dominantCategoryId,
            ),
      if (targetHandle != 0)
        for (final contribution in snapshot.contributionsFor(
          direction: direction,
          period: period,
          targetHandle: targetHandle,
        ))
          _PartnerAmount(
            partnerHandle: contribution.partnerHandle,
            actualScaled100: contribution.actualScaled100,
            dominantCategoryId: snapshot
                .cellAt(
                  direction: direction,
                  period: period,
                  partnerHandle: contribution.partnerHandle,
                )
                .dominantCategoryId,
          ),
    ]);
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

final class _PartnerAmount {
  const _PartnerAmount({
    required this.partnerHandle,
    required this.actualScaled100,
    required this.dominantCategoryId,
  });

  final int partnerHandle;
  final int actualScaled100;
  final String dominantCategoryId;
}

final class _RawPartnerDistributionEntry {
  const _RawPartnerDistributionEntry({
    required this.partnerHandle,
    required this.partnerId,
    required this.title,
    required this.colorId,
    required this.actualScaled100,
  });

  final int partnerHandle;
  final String partnerId;
  final String title;
  final String colorId;
  final int actualScaled100;
}

/// Bounded RAM LRU. It caches both directions per period and therefore has no
/// direction-switch projection path.
final class DashboardBudgetPartnerDistributionBundleCache {
  DashboardBudgetPartnerDistributionBundleCache({this.maximumBundles = 3})
    : assert(maximumBundles > 0);

  final int maximumBundles;
  final LinkedHashMap<
    DashboardBudgetPartnerDistributionKey,
    DashboardBudgetPartnerDistributionBundle
  >
  _bundles =
      LinkedHashMap<
        DashboardBudgetPartnerDistributionKey,
        DashboardBudgetPartnerDistributionBundle
      >();
  int projectionCount = 0;
  int evictionCount = 0;

  DashboardBudgetPartnerDistributionBundle? peek(
    DashboardBudgetPartnerDistributionKey key,
  ) => _bundles[key];

  DashboardBudgetPartnerDistributionBundle resolve({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required List<FluviCategory> categories,
    required BudgetLimitPeriod period,
  }) {
    final key = DashboardBudgetPartnerDistributionKey.fromPeriod(
      coreRevision: snapshot.coreRevision,
      period: period,
    );
    final retained = _bundles.remove(key);
    if (retained != null) {
      _bundles[key] = retained;
      return retained;
    }
    final stopwatch = Stopwatch()..start();
    final projected = DashboardBudgetPartnerDistributionProjector.project(
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

  DashboardBudgetPartnerDistributionBundle resolveForScope({
    required PreparedBudgetPartnerDistributionSnapshot snapshot,
    required List<FluviCategory> categories,
    required LedgerTimeScope scope,
  }) {
    final key = DashboardBudgetPartnerDistributionKey.fromScope(
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
        DashboardBudgetPartnerDistributionProjector.projectForScope(
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

/// Headless CoreDashboard-lifetime owner for partner semantic frames. Query
/// and centered Budget target are deliberately absent from its input domain.
final class DashboardBudgetPartnerDistributionController
    extends ValueNotifier<DashboardBudgetPartnerDistributionBundle?> {
  DashboardBudgetPartnerDistributionController({
    required ValueListenable<List<FluviCategory>> categoryCollection,
    required ValueListenable<DashboardVisibleFrame?> visibleFrame,
    required PreparedBudgetPartnerDistributionSnapshot? Function()
    snapshotForCurrentFrame,
    DashboardBudgetPartnerDistributionBundleCache? cache,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _cache = cache ?? DashboardBudgetPartnerDistributionBundleCache(),
       super(null) {
    _categoryCollection.addListener(_invalidateForCategoryMetadata);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _refreshForVisibleFrame();
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final PreparedBudgetPartnerDistributionSnapshot? Function()
  _snapshotForCurrentFrame;
  final DashboardBudgetPartnerDistributionBundleCache _cache;

  int get projectionCount => _cache.projectionCount;

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
    final key = DashboardBudgetPartnerDistributionKey.fromScope(
      coreRevision: snapshot.coreRevision,
      scope: scope,
    );
    final cacheHit = _cache.peek(key) != null;
    final bundle = _cache.resolveForScope(
      snapshot: snapshot,
      categories: _categoryCollection.value,
      scope: scope,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: cacheHit
            ? 'BUDGET_PARTNER_DISTRIBUTION_REUSED'
            : 'BUDGET_PARTNER_DISTRIBUTION_READY',
        coreRevision: bundle.key.coreRevision,
        entryCount:
            bundle.income.entries.length + bundle.expense.entries.length,
        scope:
            '${bundle.key.diagnosticLabel} '
            'incomePositivePartners=${bundle.income.entries.length} '
            'expensePositivePartners=${bundle.expense.entries.length} '
            'cacheHit=$cacheHit',
      ),
    );
    if (!identical(value, bundle)) value = bundle;
  }

  @override
  void dispose() {
    _categoryCollection.removeListener(_invalidateForCategoryMetadata);
    _visibleFrame.removeListener(_refreshForVisibleFrame);
    super.dispose();
  }
}
