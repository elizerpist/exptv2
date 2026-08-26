import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/domain/fluvi_category.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_category_distribution_controller.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import '../../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../../runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/year_month.dart';
import 'budget_clay_donut_scene.dart';
import 'budget_partner_distribution_visual_bank.dart';

/// Retained Category geometry for one exact direction/time scene. The target
/// handle maps to a paint-time selection index; it does not select a resource.
@immutable
final class DashboardBudgetCategoryDistributionVisualFrame {
  DashboardBudgetCategoryDistributionVisualFrame({
    required this.semanticFrame,
    required this.scene,
    required List<int> sliceIndexByTargetHandle,
  }) : sliceIndexByTargetHandle = List<int>.unmodifiable(
         sliceIndexByTargetHandle,
       );

  final DashboardBudgetCategoryDistributionDirectionFrame semanticFrame;
  final BudgetClayDonutScene scene;
  final List<int> sliceIndexByTargetHandle;

  int sliceIndexForTargetHandle(int targetHandle) =>
      targetHandle < 0 || targetHandle >= sliceIndexByTargetHandle.length
      ? -1
      : sliceIndexByTargetHandle[targetHandle];
}

/// One immutable Category scene bank for both directions. Direction is not a
/// key because one exact prepared revision already owns both target domains.
@immutable
final class DashboardBudgetCategoryDistributionVisualBank {
  const DashboardBudgetCategoryDistributionVisualBank({
    required this.semanticBundle,
    required this.income,
    required this.expense,
  });

  final DashboardBudgetCategoryDistributionBundle semanticBundle;
  final DashboardBudgetCategoryDistributionVisualFrame income;
  final DashboardBudgetCategoryDistributionVisualFrame expense;

  int get sceneCount => 2;
  int get totalSliceCount =>
      income.scene.slices.length + expense.scene.slices.length;
  int get estimatedRetainedBytes => totalSliceCount * 384;

  DashboardBudgetCategoryDistributionVisualFrame frameFor(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => income,
    LedgerDirection.expense => expense,
  };

  factory DashboardBudgetCategoryDistributionVisualBank.prepare({
    required DashboardBudgetCategoryDistributionBundle semanticBundle,
  }) {
    DashboardBudgetCategoryDistributionVisualFrame buildFrame(
      DashboardBudgetCategoryDistributionDirectionFrame frame,
    ) {
      final scene = BudgetClayDonutScene.fromSlices(<BudgetClayDonutSliceInput>[
        for (final entry in frame.entries)
          BudgetClayDonutSliceInput(
            stableId: entry.categoryId,
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      final byHandle = List<int>.filled(frame.targetCount, -1);
      for (var index = 0; index < frame.entries.length; index += 1) {
        byHandle[frame.entries[index].targetHandle] = index;
      }
      return DashboardBudgetCategoryDistributionVisualFrame(
        semanticFrame: frame,
        scene: scene,
        sliceIndexByTargetHandle: byHandle,
      );
    }

    return DashboardBudgetCategoryDistributionVisualBank(
      semanticBundle: semanticBundle,
      income: buildFrame(semanticBundle.income),
      expense: buildFrame(semanticBundle.expense),
    );
  }
}

/// One coherent immutable Card2 analysis identity. It has no SVG or decoded
/// picture ownership: retained Canvas paths are synchronous paint resources.
@immutable
final class DashboardBudgetDistributionDrawableFrame {
  DashboardBudgetDistributionDrawableFrame({
    required this.semanticBundle,
    required this.visualBank,
    this.partnerSemanticBundle,
    this.partnerVisualBank,
  }) : assert(identical(semanticBundle, visualBank.semanticBundle)),
       assert(
         (partnerSemanticBundle == null) == (partnerVisualBank == null),
         'Partner semantic and scene banks must publish together.',
       ),
       assert(
         partnerSemanticBundle == null ||
             identical(
               partnerSemanticBundle,
               partnerVisualBank!.semanticBundle,
             ),
       );

  final DashboardBudgetCategoryDistributionBundle semanticBundle;
  final DashboardBudgetCategoryDistributionVisualBank visualBank;
  final DashboardBudgetPartnerDistributionBundle? partnerSemanticBundle;
  final DashboardBudgetPartnerDistributionVisualBank? partnerVisualBank;

  bool get hasPartnerDrawable =>
      partnerSemanticBundle != null && partnerVisualBank != null;

  int get sceneCount =>
      visualBank.sceneCount + (partnerVisualBank?.sceneCount ?? 0);
  int get totalSliceCount =>
      visualBank.totalSliceCount + (partnerVisualBank?.totalSliceCount ?? 0);
  int get estimatedRetainedBytes =>
      visualBank.estimatedRetainedBytes +
      (partnerVisualBank?.estimatedRetainedBytes ?? 0);
}

enum _BudgetDistributionPreparationPriority { foreground, maintenance }

/// Bounded exact analysis-scene owner for Budget Card2. It projects prepared
/// RAM values into Canvas paths only; no renderer decode or SVG resource is
/// involved in either preparation or selection.
final class DashboardBudgetDistributionDrawableController
    extends ValueNotifier<DashboardBudgetDistributionDrawableFrame?> {
  DashboardBudgetDistributionDrawableController({
    required ValueListenable<List<FluviCategory>> categories,
    PreparedBudgetLimitSnapshot? snapshot,
    PreparedBudgetLimitSnapshot? Function()? snapshotForCurrentFrame,
    PreparedBudgetPartnerDistributionSnapshot? Function()?
    partnerSnapshotForCurrentFrame,
    Iterable<LedgerTimeScope> Function(DashboardNavigationState state)?
    directChildScopesFor,
    bool Function()? isForegroundInputActive,
    this.maximumFrames = 40,
  }) : assert(snapshot != null || snapshotForCurrentFrame != null),
       assert(maximumFrames > 0),
       _categories = categories,
       _snapshotForCurrentFrame = snapshotForCurrentFrame ?? (() => snapshot),
       _partnerSnapshotForCurrentFrame = partnerSnapshotForCurrentFrame,
       _directChildScopesFor = directChildScopesFor,
       _isForegroundInputActive = isForegroundInputActive,
       super(null) {
    _categories.addListener(_invalidateForCategoryMetadata);
  }

  final ValueListenable<List<FluviCategory>> _categories;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final PreparedBudgetPartnerDistributionSnapshot? Function()?
  _partnerSnapshotForCurrentFrame;
  final Iterable<LedgerTimeScope> Function(DashboardNavigationState state)?
  _directChildScopesFor;
  final bool Function()? _isForegroundInputActive;
  final int maximumFrames;
  final DashboardBudgetCategoryDistributionBundleCache _categoryCache =
      DashboardBudgetCategoryDistributionBundleCache(maximumBundles: 40);
  final DashboardBudgetPartnerDistributionBundleCache _partnerCache =
      DashboardBudgetPartnerDistributionBundleCache(maximumBundles: 40);
  final LinkedHashMap<
    DashboardBudgetCategoryDistributionKey,
    DashboardBudgetDistributionDrawableFrame
  >
  _frames =
      LinkedHashMap<
        DashboardBudgetCategoryDistributionKey,
        DashboardBudgetDistributionDrawableFrame
      >();
  int _prepareGeneration = 0;
  int sceneBuildCount = 0;
  int sourceGenerationCount = 0;
  int rendererPrewarmCount = 0;
  int pictureDecodeCount = 0;
  int evictionCount = 0;

  int get retainedFrameCount => _frames.length;
  int get retainedSceneCount =>
      _frames.values.fold<int>(0, (count, frame) => count + frame.sceneCount);
  int get retainedPictureCount => 0;
  int get totalRetainedSliceCount => _frames.values.fold<int>(
    0,
    (count, frame) => count + frame.totalSliceCount,
  );
  int get estimatedRetainedBytes => _frames.values.fold<int>(
    0,
    (count, frame) => count + frame.estimatedRetainedBytes,
  );

  Future<bool> prepareForTimeScope(LedgerTimeScope scope) async {
    try {
      await prepareForScope(scope);
      return true;
    } on Object catch (error) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_DRAWABLE_FALLBACK_RETAINED',
          coreRevision: _snapshotForCurrentFrame()?.coreRevision,
          scope: 'analysisScope=${scope.canonicalKey} reason=$error',
        ),
      );
      return false;
    }
  }

  /// Compatibility seam for persisted-period callers. New chart callers must
  /// use [prepareForScope] so a Day never becomes a Month scene.
  Future<DashboardBudgetDistributionDrawableFrame> prepare(
    BudgetLimitPeriod period,
  ) => prepareForScope(_scopeForPeriod(period));

  Future<DashboardBudgetDistributionDrawableFrame> prepareForScope(
    LedgerTimeScope scope,
  ) => _prepareForScope(
    scope,
    priority: _BudgetDistributionPreparationPriority.foreground,
  );

  Future<DashboardBudgetDistributionDrawableFrame> _prepareForScope(
    LedgerTimeScope scope, {
    required _BudgetDistributionPreparationPriority priority,
  }) async {
    final snapshot = _snapshotForCurrentFrame();
    if (snapshot == null) {
      throw StateError('No exact prepared Budget snapshot is available.');
    }
    final key = DashboardBudgetCategoryDistributionKey.fromScope(
      coreRevision: snapshot.coreRevision,
      scope: scope,
    );
    final cached = _frames.remove(key);
    if (cached != null) {
      _frames[key] = cached;
      return cached;
    }
    final generation = ++_prepareGeneration;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_PREPARE_STARTED',
        coreRevision: key.coreRevision,
        scope: 'analysisScope=${key.diagnosticLabel} priority=${priority.name}',
      ),
    );
    final watch = Stopwatch()..start();
    final categoryBundle = _categoryCache.resolveForScope(
      snapshot: snapshot,
      categories: _categories.value,
      scope: scope,
    );
    final categoryBank = DashboardBudgetCategoryDistributionVisualBank.prepare(
      semanticBundle: categoryBundle,
    );
    final partnerSnapshot = _partnerSnapshotForCurrentFrame?.call();
    if (partnerSnapshot != null &&
        partnerSnapshot.coreRevision != key.coreRevision) {
      throw StateError(
        'Inexact prepared Budget partner distribution snapshot.',
      );
    }
    if (partnerSnapshot != null &&
        (!listEquals(
              partnerSnapshot.incomeBank.orderedCategoryIds,
              snapshot.incomeBank.orderedCategoryIds,
            ) ||
            !listEquals(
              partnerSnapshot.expenseBank.orderedCategoryIds,
              snapshot.expenseBank.orderedCategoryIds,
            ))) {
      throw StateError(
        'Budget partner contribution target domain does not match Budget targets.',
      );
    }
    final partnerBundle = partnerSnapshot == null
        ? null
        : _partnerCache.resolveForScope(
            snapshot: partnerSnapshot,
            categories: _categories.value,
            scope: scope,
          );
    final partnerBank = partnerBundle == null
        ? null
        : DashboardBudgetPartnerDistributionVisualBank.prepare(
            semanticBundle: partnerBundle,
          );
    if (generation != _prepareGeneration) {
      throw StateError('Stale Budget distribution scene preparation.');
    }
    final latest = _snapshotForCurrentFrame();
    if (latest == null || latest.coreRevision != key.coreRevision) {
      throw StateError('Inexact Budget distribution scene preparation.');
    }
    final frame = DashboardBudgetDistributionDrawableFrame(
      semanticBundle: categoryBundle,
      visualBank: categoryBank,
      partnerSemanticBundle: partnerBundle,
      partnerVisualBank: partnerBank,
    );
    _frames[key] = frame;
    _trimCache(pinned: key);
    sceneBuildCount += frame.sceneCount;
    watch.stop();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_SCENE_HOTSET_READY',
        coreRevision: key.coreRevision,
        durationMs: watch.elapsedMilliseconds,
        scope:
            'analysisScope=${key.diagnosticLabel} categorySceneCount=${categoryBank.sceneCount} '
            'partnerSceneCount=${partnerBank?.sceneCount ?? 0} '
            'totalSliceCount=${frame.totalSliceCount} '
            'estimatedBytes=${frame.estimatedRetainedBytes} '
            'retainedBytes=$estimatedRetainedBytes '
            'uiIsolateMicros=${watch.elapsedMicroseconds} '
            'largestContiguousUiSliceMicros=${watch.elapsedMicroseconds} '
            'yieldCount=0 pauseCount=0 resumeCount=0 supersededCount=0',
      ),
    );
    return frame;
  }

  Future<void> warmHotsetFor(DashboardNavigationState state) async {
    // This cache is an idle-only visual convenience. It has no authority over
    // direct Summary or BudgetAvatar input and it must re-check after yielding
    // because each projection can synchronously build Canvas paths.
    await Future<void>.delayed(Duration.zero);
    if (_isForegroundInputActive?.call() ?? false) return;
    final scopes = <String, LedgerTimeScope>{};
    void add(LedgerTimeScope scope) => scopes[scope.canonicalKey] = scope;
    add(state.parentScope);
    final direct = _directChildScopesFor?.call(state);
    if (direct == null) {
      add(state.retainedChildScope);
    } else {
      for (final scope in direct) {
        add(scope);
      }
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_SCENE_HOTSET_PLANNED',
        coreRevision: _snapshotForCurrentFrame()?.coreRevision,
        scope:
            'parentScope=${state.parentScope.canonicalKey} '
            'childScopeCount=${scopes.length - 1} '
            'retainedBytes=$estimatedRetainedBytes '
            'requiredScopes=${scopes.keys.join(',')}',
      ),
    );
    for (final scope in scopes.values) {
      if (_isForegroundInputActive?.call() ?? false) return;
      try {
        await _prepareForScope(
          scope,
          priority: _BudgetDistributionPreparationPriority.maintenance,
        );
      } on Object {
        return;
      }
    }
  }

  bool publishIfReadyForTimeScope(
    LedgerTimeScope scope, {
    LedgerDirection? direction,
    int? targetHandle,
    String? partnerId,
  }) {
    final snapshot = _snapshotForCurrentFrame();
    if (snapshot == null) return false;
    final key = DashboardBudgetCategoryDistributionKey.fromScope(
      coreRevision: snapshot.coreRevision,
      scope: scope,
    );
    final frame = _frames.remove(key);
    if (frame == null) return false;
    _frames[key] = frame;
    publish(
      frame,
      source: 'railPreview',
      direction: direction,
      targetHandle: targetHandle,
      partnerId: partnerId,
    );
    return true;
  }

  bool publishIfReady(BudgetLimitPeriod period) =>
      publishIfReadyForTimeScope(_scopeForPeriod(period));

  Future<void> publishWhenPreparedForTimeScope(
    LedgerTimeScope scope, {
    LedgerDirection? direction,
    int? targetHandle,
    String? partnerId,
  }) async {
    try {
      // Keep cache-miss Canvas projection out of the visible-frame listener
      // that is invoked by a physical Summary/Avatar crossing. A cache hit is
      // already handled synchronously by [publishIfReadyForTimeScope].
      await Future<void>.delayed(Duration.zero);
      if (_isForegroundInputActive?.call() ?? false) return;
      final frame = await prepareForScope(scope);
      final snapshot = _snapshotForCurrentFrame();
      if (snapshot != null &&
          snapshot.coreRevision == frame.semanticBundle.key.coreRevision) {
        publish(
          frame,
          source: 'committed',
          direction: direction,
          targetHandle: targetHandle,
          partnerId: partnerId,
        );
      }
    } on Object {
      // The previous full identity is retained only as an abnormal fallback.
    }
  }

  Future<void> publishWhenPrepared(BudgetLimitPeriod period) =>
      publishWhenPreparedForTimeScope(_scopeForPeriod(period));

  void publish(
    DashboardBudgetDistributionDrawableFrame frame, {
    String source = 'committed',
    LedgerDirection? direction,
    int? targetHandle,
    String? partnerId,
  }) {
    final old = value;
    _frames.remove(frame.semanticBundle.key);
    _frames[frame.semanticBundle.key] = frame;
    if (!identical(old, frame)) {
      value = frame;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_SCOPE_BOUND',
          coreRevision: frame.semanticBundle.key.coreRevision,
          scope:
              'source=$source analysisScope=${frame.semanticBundle.analysisScope.canonicalKey} '
              'direction=${direction?.name ?? '-'} '
              'targetHandle=${targetHandle ?? '-'} '
              'partnerId=${partnerId ?? '-'} '
              'categorySceneHit=true partnerSceneHit=${frame.hasPartnerDrawable}',
        ),
      );
    }
    _trimCache(pinned: frame.semanticBundle.key);
  }

  void _trimCache({DashboardBudgetCategoryDistributionKey? pinned}) {
    while (_frames.length > maximumFrames) {
      final visibleKey = value?.semanticBundle.key;
      final removable = _frames.keys.firstWhere(
        (key) => key != pinned && key != visibleKey,
        orElse: () => _frames.keys.first,
      );
      if (removable == pinned || removable == visibleKey) return;
      _frames.remove(removable);
      evictionCount += 1;
    }
  }

  void _invalidateForCategoryMetadata() {
    _prepareGeneration += 1;
    _categoryCache.clear();
    _partnerCache.clear();
    _frames.clear();
    if (value != null) value = null;
  }

  @override
  void dispose() {
    _prepareGeneration += 1;
    _categories.removeListener(_invalidateForCategoryMetadata);
    _frames.clear();
    if (value != null) value = null;
    super.dispose();
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
