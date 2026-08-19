import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/domain/fluvi_category.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_category_distribution_controller.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../application/dashboard_budget_period.dart';
import '../../query/domain/ledger_direction.dart';
import '../../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../../runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_distribution_svg_resources.dart';
import 'budget_partner_distribution_visual_bank.dart';

export 'budget_distribution_svg_resources.dart';

@immutable
final class DashboardBudgetCategoryDistributionVisualFrame {
  DashboardBudgetCategoryDistributionVisualFrame({
    required this.semanticFrame,
    required List<String> svgVariants,
    required List<int> variantIndexByTargetHandle,
  }) : svgVariants = List<String>.unmodifiable(svgVariants),
       variantIndexByTargetHandle = List<int>.unmodifiable(
         variantIndexByTargetHandle,
       );

  final DashboardBudgetCategoryDistributionDirectionFrame semanticFrame;
  final List<String> svgVariants;
  final List<int> variantIndexByTargetHandle;

  String svgForTargetHandle(int targetHandle) {
    final variant =
        targetHandle >= 0 && targetHandle < variantIndexByTargetHandle.length
        ? variantIndexByTargetHandle[targetHandle]
        : 0;
    return svgVariants[variant];
  }

  int variantIndexForTargetHandle(int targetHandle) =>
      targetHandle >= 0 && targetHandle < variantIndexByTargetHandle.length
      ? variantIndexByTargetHandle[targetHandle]
      : 0;
}

@immutable
final class DashboardBudgetCategoryDistributionVisualBank {
  const DashboardBudgetCategoryDistributionVisualBank({
    required this.semanticBundle,
    required this.income,
    required this.expense,
    required this.sourceBytes,
  });

  final DashboardBudgetCategoryDistributionBundle semanticBundle;
  final DashboardBudgetCategoryDistributionVisualFrame income;
  final DashboardBudgetCategoryDistributionVisualFrame expense;
  final int sourceBytes;

  int get variantCount =>
      income.svgVariants.length + expense.svgVariants.length;
  int get estimatedRetainedBytes =>
      sourceBytes +
      (income.variantIndexByTargetHandle.length +
              expense.variantIndexByTargetHandle.length) *
          4;

  DashboardBudgetCategoryDistributionVisualFrame frameFor(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => income,
    LedgerDirection.expense => expense,
  };

  Iterable<String> get allSources sync* {
    yield* income.svgVariants;
    yield* expense.svgVariants;
  }

  factory DashboardBudgetCategoryDistributionVisualBank.prepare({
    required DashboardBudgetCategoryDistributionBundle semanticBundle,
    required BudgetCategoryDistributionSvgSourceGenerator sourceGenerator,
  }) {
    DashboardBudgetCategoryDistributionVisualFrame buildFrame(
      DashboardBudgetCategoryDistributionDirectionFrame frame,
    ) {
      final slices = List<BudgetCategoryDistributionSvgSlice>.unmodifiable([
        for (final entry in frame.entries)
          BudgetCategoryDistributionSvgSlice(
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      final variants = <String>[
        sourceGenerator.generate(slices: slices, selectedIndex: null),
        for (var index = 0; index < frame.entries.length; index += 1)
          sourceGenerator.generate(slices: slices, selectedIndex: index),
      ];
      final variantByHandle = List<int>.filled(frame.targetCount, 0);
      for (var slice = 0; slice < frame.entries.length; slice += 1) {
        variantByHandle[frame.entries[slice].targetHandle] = slice + 1;
      }
      return DashboardBudgetCategoryDistributionVisualFrame(
        semanticFrame: frame,
        svgVariants: variants,
        variantIndexByTargetHandle: variantByHandle,
      );
    }

    final income = buildFrame(semanticBundle.income);
    final expense = buildFrame(semanticBundle.expense);
    final bytes =
        income.svgVariants.fold<int>(
          0,
          (sum, source) => sum + utf8.encode(source).length,
        ) +
        expense.svgVariants.fold<int>(
          0,
          (sum, source) => sum + utf8.encode(source).length,
        );
    return DashboardBudgetCategoryDistributionVisualBank(
      semanticBundle: semanticBundle,
      income: income,
      expense: expense,
      sourceBytes: bytes,
    );
  }
}

/// Bounded renderer-resource owner. Selection is intentionally not an input:
/// all source variants are ready before this bank becomes visible.
final class DashboardBudgetCategoryDistributionVisualBankController
    extends ValueNotifier<DashboardBudgetCategoryDistributionVisualBank?> {
  DashboardBudgetCategoryDistributionVisualBankController({
    required ValueListenable<DashboardBudgetCategoryDistributionBundle?>
    bundles,
    BudgetCategoryDistributionSvgPrewarmer? prewarmer,
    BudgetCategoryDistributionSvgSourceGenerator? sourceGenerator,
    this.maximumBanks = 3,
  }) : _bundles = bundles,
       _prewarmer =
           prewarmer ?? const FlutterSvgBudgetCategoryDistributionPrewarmer(),
       _sourceGenerator =
           sourceGenerator ??
           const FluviBudgetCategoryDistributionSvgSourceGenerator(),
       assert(maximumBanks > 0),
       super(null) {
    _bundles.addListener(_prepareCurrentBundle);
    _prepareCurrentBundle();
  }

  final ValueListenable<DashboardBudgetCategoryDistributionBundle?> _bundles;
  final BudgetCategoryDistributionSvgPrewarmer _prewarmer;
  final BudgetCategoryDistributionSvgSourceGenerator _sourceGenerator;
  final int maximumBanks;
  final LinkedHashMap<
    DashboardBudgetCategoryDistributionKey,
    DashboardBudgetCategoryDistributionVisualBank
  >
  _banks =
      LinkedHashMap<
        DashboardBudgetCategoryDistributionKey,
        DashboardBudgetCategoryDistributionVisualBank
      >();
  int _prepareGeneration = 0;
  int sourceGenerationCount = 0;
  int rendererPrewarmCount = 0;
  int evictionCount = 0;

  int get retainedBankCount => _banks.length;

  Future<void> _prepareCurrentBundle() async {
    final bundle = _bundles.value;
    final generation = ++_prepareGeneration;
    if (bundle == null) {
      if (value != null) value = null;
      return;
    }
    final retained = _banks.remove(bundle.key);
    if (retained != null && identical(retained.semanticBundle, bundle)) {
      _banks[bundle.key] = retained;
      if (!identical(value, retained)) value = retained;
      return;
    }
    final watch = Stopwatch()..start();
    final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
      semanticBundle: bundle,
      sourceGenerator: _sourceGenerator,
    );
    sourceGenerationCount += bank.variantCount;
    final sourceGenerationMicros = watch.elapsedMicroseconds;
    await _prewarmer.prewarm(bank.allSources);
    if (generation != _prepareGeneration ||
        !identical(_bundles.value, bundle)) {
      return;
    }
    rendererPrewarmCount += bank.variantCount;
    _banks[bundle.key] = bank;
    while (_banks.length > maximumBanks) {
      _banks.remove(_banks.keys.first);
      evictionCount += 1;
    }
    watch.stop();
    // The semantic controller logs source-domain counts; renderer ownership
    // adds bounded visual-cache information once per prepared bundle.
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_READY',
        coreRevision: bank.semanticBundle.key.coreRevision,
        entryCount: bank.variantCount,
        durationMs: watch.elapsedMilliseconds,
        scope:
            '${bank.semanticBundle.key.diagnosticLabel} '
            'incomeCategoryCount=${bank.semanticBundle.income.targetCount - 1} '
            'expenseCategoryCount=${bank.semanticBundle.expense.targetCount - 1} '
            'incomePositiveSliceCount=${bank.semanticBundle.income.entries.length} '
            'expensePositiveSliceCount=${bank.semanticBundle.expense.entries.length} '
            'incomeTotalScaled100=${bank.semanticBundle.income.totalCategoryActualScaled100} '
            'expenseTotalScaled100=${bank.semanticBundle.expense.totalCategoryActualScaled100} '
            'projectionMicros=${bank.semanticBundle.projectionMicros} '
            'svgVariantCount=${bank.variantCount} '
            'svgSourceBytes=${bank.sourceBytes} '
            'svgGenerationMicros=$sourceGenerationMicros '
            'svgPrewarmMicros=${watch.elapsedMicroseconds} '
            'estimatedRetainedBytes=${bank.estimatedRetainedBytes}',
      ),
    );
    value = bank;
  }

  @override
  void dispose() {
    _prepareGeneration += 1;
    _bundles.removeListener(_prepareCurrentBundle);
    super.dispose();
  }
}

/// One coherent drawable Card2 identity. A frame is published only after the
/// exact semantic period and its renderer-warmed SVG bank are both available.
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
         'Partner semantic and visual banks must publish together.',
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
}

enum _BudgetDistributionPreparationPriority { foreground, maintenance }

final class _QueuedBudgetDistributionPreparation {
  _QueuedBudgetDistributionPreparation({
    required this.snapshot,
    required this.period,
    required this.key,
    required this.generation,
  });

  final PreparedBudgetLimitSnapshot snapshot;
  final BudgetLimitPeriod period;
  final DashboardBudgetCategoryDistributionKey key;
  final int generation;
  final Completer<DashboardBudgetDistributionDrawableFrame> completer =
      Completer<DashboardBudgetDistributionDrawableFrame>();
}

/// Presentation resource owner for Budget Card2. It intentionally keeps the
/// previous fully drawable frame visible while an unexpected cold target is
/// prepared; normal time navigation asks [prepareForTimeScope] before the
/// semantic commit, so the target is already an O(1) publication here.
final class DashboardBudgetDistributionDrawableController
    extends ValueNotifier<DashboardBudgetDistributionDrawableFrame?> {
  DashboardBudgetDistributionDrawableController({
    required ValueListenable<List<FluviCategory>> categories,
    PreparedBudgetLimitSnapshot? snapshot,
    PreparedBudgetLimitSnapshot? Function()? snapshotForCurrentFrame,
    PreparedBudgetPartnerDistributionSnapshot? Function()?
    partnerSnapshotForCurrentFrame,
    BudgetCategoryDistributionSvgPrewarmer? prewarmer,
    BudgetCategoryDistributionSvgSourceGenerator? sourceGenerator,
    this.maximumFrames = 3,
  }) : assert(snapshot != null || snapshotForCurrentFrame != null),
       assert(maximumFrames > 0),
       _categories = categories,
       _snapshotForCurrentFrame = snapshotForCurrentFrame ?? (() => snapshot),
       _partnerSnapshotForCurrentFrame = partnerSnapshotForCurrentFrame,
       _prewarmer =
           prewarmer ?? const FlutterSvgBudgetCategoryDistributionPrewarmer(),
       _sourceGenerator =
           sourceGenerator ??
           const FluviBudgetCategoryDistributionSvgSourceGenerator(),
       super(null) {
    _categories.addListener(_invalidateForCategoryMetadata);
  }

  final ValueListenable<List<FluviCategory>> _categories;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final PreparedBudgetPartnerDistributionSnapshot? Function()?
  _partnerSnapshotForCurrentFrame;
  final BudgetCategoryDistributionSvgPrewarmer _prewarmer;
  final BudgetCategoryDistributionSvgSourceGenerator _sourceGenerator;
  final int maximumFrames;
  final DashboardBudgetCategoryDistributionBundleCache _semanticCache =
      DashboardBudgetCategoryDistributionBundleCache();
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
  Future<DashboardBudgetDistributionDrawableFrame>? _inFlight;
  DashboardBudgetCategoryDistributionKey? _inFlightKey;
  _QueuedBudgetDistributionPreparation? _queuedForeground;
  int sourceGenerationCount = 0;
  int rendererPrewarmCount = 0;
  int evictionCount = 0;

  int get retainedFrameCount => _frames.length;

  Future<bool> prepareForTimeScope(LedgerTimeScope scope) async {
    final period = DashboardBudgetPeriodResolver.fromTimeScope(scope);
    final snapshot = _snapshotForCurrentFrame();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_TIME_HOTSET_PLANNED',
        coreRevision: snapshot?.coreRevision,
        scope:
            'currentPeriod=${_labelFor(period)} requiredPeriods=${_labelFor(period)}',
      ),
    );
    try {
      await prepare(period);
      return true;
    } on Object catch (error) {
      final snapshot = _snapshotForCurrentFrame();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_DRAWABLE_FALLBACK_RETAINED',
          coreRevision: snapshot?.coreRevision,
          scope: 'reason=$error',
        ),
      );
      return false;
    }
  }

  /// Uses the existing idle next-plane publication opportunity to retain the
  /// three immediately reachable semantic periods, never a calendar universe.
  Future<void> warmHotsetFor(DashboardNavigationState state) async {
    final anchor = state.temporalAnchor;
    final periods = <BudgetLimitPeriod>[
      const BudgetLimitPeriod.sum(),
      BudgetLimitPeriod.year(anchor.visibleYear),
      BudgetLimitPeriod.month(anchor.visibleYear, anchor.visibleMonth),
    ];
    final snapshot = _snapshotForCurrentFrame();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_TIME_HOTSET_PLANNED',
        coreRevision: snapshot?.coreRevision,
        scope:
            'currentPeriod=${_labelFor(DashboardBudgetPeriodResolver.fromTimeScope(state.parentScope))} '
            'requiredPeriods=${periods.map(_labelFor).join(',')}',
      ),
    );
    for (final period in periods) {
      try {
        await _prepare(
          period,
          priority: _BudgetDistributionPreparationPriority.maintenance,
        );
      } on Object {
        return;
      }
    }
  }

  bool publishIfReady(BudgetLimitPeriod period) {
    final snapshot = _snapshotForCurrentFrame();
    if (snapshot == null) return false;
    final key = DashboardBudgetCategoryDistributionKey.fromPeriod(
      coreRevision: snapshot.coreRevision,
      period: period,
    );
    final frame = _frames.remove(key);
    if (frame == null) return false;
    _frames[key] = frame;
    publish(frame);
    return true;
  }

  Future<void> publishWhenPrepared(BudgetLimitPeriod period) async {
    try {
      final frame = await prepare(period);
      final snapshot = _snapshotForCurrentFrame();
      if (snapshot == null ||
          snapshot.coreRevision != frame.semanticBundle.key.coreRevision) {
        return;
      }
      publish(frame);
    } on Object {
      // The retained frame remains the explicit fail-safe for an unexpected
      // render-resource failure. The bounded diagnostic is emitted by
      // [prepareForTimeScope] on navigation paths.
    }
  }

  Future<DashboardBudgetDistributionDrawableFrame> prepare(
    BudgetLimitPeriod period,
  ) => _prepare(
    period,
    priority: _BudgetDistributionPreparationPriority.foreground,
  );

  Future<DashboardBudgetDistributionDrawableFrame> _prepare(
    BudgetLimitPeriod period, {
    required _BudgetDistributionPreparationPriority priority,
  }) {
    final snapshot = _snapshotForCurrentFrame();
    if (snapshot == null) {
      return Future<DashboardBudgetDistributionDrawableFrame>.error(
        StateError('No exact prepared Budget snapshot is available.'),
      );
    }
    final key = DashboardBudgetCategoryDistributionKey.fromPeriod(
      coreRevision: snapshot.coreRevision,
      period: period,
    );
    final cached = _frames.remove(key);
    if (cached != null) {
      _frames[key] = cached;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_REUSED',
          coreRevision: key.coreRevision,
          scope: '${key.diagnosticLabel} cacheHit=true',
        ),
      );
      return Future<DashboardBudgetDistributionDrawableFrame>.value(cached);
    }
    if (_inFlightKey == key && _inFlight != null) return _inFlight!;
    if (_inFlight != null) {
      if (priority == _BudgetDistributionPreparationPriority.maintenance) {
        return Future<DashboardBudgetDistributionDrawableFrame>.error(
          StateError(
            'Budget distribution maintenance yielded to foreground readiness.',
          ),
        );
      }
      final superseded = _queuedForeground;
      if (superseded != null && !superseded.completer.isCompleted) {
        superseded.completer.completeError(
          StateError('Superseded Budget distribution drawable preparation.'),
        );
      }
      // A renderer prewarm cannot be interrupted through flutter_svg's public
      // API. It is therefore allowed to finish privately, but a later real
      // navigation intent invalidates it and is the only queued foreground
      // request that may run next.
      final queued = _QueuedBudgetDistributionPreparation(
        snapshot: snapshot,
        period: period,
        key: key,
        generation: ++_prepareGeneration,
      );
      _queuedForeground = queued;
      return queued.completer.future;
    }
    return _startPreparation(
      snapshot: snapshot,
      period: period,
      key: key,
      generation: ++_prepareGeneration,
    );
  }

  Future<DashboardBudgetDistributionDrawableFrame> _startPreparation({
    required PreparedBudgetLimitSnapshot snapshot,
    required BudgetLimitPeriod period,
    required DashboardBudgetCategoryDistributionKey key,
    required int generation,
  }) {
    final task = _prepareExact(
      snapshot: snapshot,
      period: period,
      key: key,
      generation: generation,
    );
    _inFlight = task;
    _inFlightKey = key;
    unawaited(
      task.then<void>(
        (_) => _clearInFlight(task),
        onError: (Object error, StackTrace stackTrace) => _clearInFlight(task),
      ),
    );
    return task;
  }

  void _clearInFlight(Future<DashboardBudgetDistributionDrawableFrame> task) {
    if (!identical(_inFlight, task)) return;
    _inFlight = null;
    _inFlightKey = null;
    final queued = _queuedForeground;
    if (queued == null) return;
    _queuedForeground = null;
    final next = _startPreparation(
      snapshot: queued.snapshot,
      period: queued.period,
      key: queued.key,
      generation: queued.generation,
    );
    unawaited(
      next.then<void>(
        queued.completer.complete,
        onError: (Object error, StackTrace stackTrace) =>
            queued.completer.completeError(error, stackTrace),
      ),
    );
  }

  Future<DashboardBudgetDistributionDrawableFrame> _prepareExact({
    required PreparedBudgetLimitSnapshot snapshot,
    required BudgetLimitPeriod period,
    required DashboardBudgetCategoryDistributionKey key,
    required int generation,
  }) async {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_PREPARE_STARTED',
        coreRevision: key.coreRevision,
        scope: key.diagnosticLabel,
      ),
    );
    final watch = Stopwatch()..start();
    final bundle = _semanticCache.resolve(
      snapshot: snapshot,
      categories: _categories.value,
      period: period,
    );
    final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
      semanticBundle: bundle,
      sourceGenerator: _sourceGenerator,
    );
    sourceGenerationCount += bank.variantCount;
    final partnerSnapshot = _partnerSnapshotForCurrentFrame?.call();
    if (partnerSnapshot != null &&
        (partnerSnapshot.incomeBank.orderedCategoryIds.isNotEmpty ||
            partnerSnapshot.expenseBank.orderedCategoryIds.isNotEmpty) &&
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
        : DashboardBudgetPartnerDistributionProjector.project(
            snapshot: partnerSnapshot,
            categories: _categories.value,
            period: period,
          );
    final partnerBank = partnerBundle == null
        ? null
        : DashboardBudgetPartnerDistributionVisualBank.prepare(
            semanticBundle: partnerBundle,
            sourceGenerator: _sourceGenerator,
          );
    if (partnerBank != null) {
      sourceGenerationCount += partnerBank.variantCount;
    }
    final sourceGenerationMicros = watch.elapsedMicroseconds;
    await _prewarmer.prewarm(<String>[
      ...bank.allSources,
      ...?partnerBank?.allSources,
    ]);
    if (generation != _prepareGeneration) {
      throw StateError('Stale Budget distribution drawable preparation.');
    }
    final latest = _snapshotForCurrentFrame();
    if (latest == null || latest.coreRevision != key.coreRevision) {
      throw StateError('Inexact Budget distribution drawable preparation.');
    }
    rendererPrewarmCount +=
        bank.variantCount + (partnerBank?.variantCount ?? 0);
    final frame = DashboardBudgetDistributionDrawableFrame(
      semanticBundle: bundle,
      visualBank: bank,
      partnerSemanticBundle: partnerBundle,
      partnerVisualBank: partnerBank,
    );
    _frames[key] = frame;
    _trimCache(pinned: value?.semanticBundle.key);
    watch.stop();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_TIME_HOTSET_READY',
        coreRevision: key.coreRevision,
        durationMs: watch.elapsedMilliseconds,
        scope:
            '${key.diagnosticLabel} categoryReady=true '
            'partnerReady=${partnerBank != null} cacheHit=false '
            'svgVariantCount=${bank.variantCount + (partnerBank?.variantCount ?? 0)} '
            'svgSourceBytes=${bank.sourceBytes + (partnerBank?.sourceBytes ?? 0)} '
            'svgGenerationMicros=$sourceGenerationMicros '
            'svgPrewarmMicros=${watch.elapsedMicroseconds} '
            'estimatedRetainedBytes=${bank.estimatedRetainedBytes + (partnerBank?.estimatedRetainedBytes ?? 0)}',
      ),
    );
    return frame;
  }

  void publish(DashboardBudgetDistributionDrawableFrame frame) {
    if (!identical(frame.semanticBundle, frame.visualBank.semanticBundle)) {
      throw StateError('Budget distribution drawable frame identity mismatch.');
    }
    final partnerBundle = frame.partnerSemanticBundle;
    final partnerBank = frame.partnerVisualBank;
    if ((partnerBundle == null) != (partnerBank == null) ||
        (partnerBundle != null &&
            !identical(partnerBundle, partnerBank!.semanticBundle))) {
      throw StateError(
        'Budget partner distribution drawable frame identity mismatch.',
      );
    }
    final old = value;
    _frames.remove(frame.semanticBundle.key);
    _frames[frame.semanticBundle.key] = frame;
    _trimCache(pinned: frame.semanticBundle.key);
    if (!identical(value, frame)) {
      value = frame;
      if (old != null && old.semanticBundle.key != frame.semanticBundle.key) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'BUDGET_DISTRIBUTION_ATOMIC_SWAP',
            coreRevision: frame.semanticBundle.key.coreRevision,
            scope:
                'fromPeriod=${old.semanticBundle.key.diagnosticLabel} '
                'toPeriod=${frame.semanticBundle.key.diagnosticLabel} '
                'oldFrameRetained=false',
          ),
        );
      }
    }
  }

  String _labelFor(BudgetLimitPeriod period) =>
      DashboardBudgetCategoryDistributionKey.fromPeriod(
        coreRevision: _snapshotForCurrentFrame()?.coreRevision ?? 0,
        period: period,
      ).diagnosticLabel;

  void _trimCache({DashboardBudgetCategoryDistributionKey? pinned}) {
    while (_frames.length > maximumFrames) {
      final removable = _frames.keys.firstWhere(
        (key) => key != pinned && key != _inFlightKey,
        orElse: () => _frames.keys.first,
      );
      if (removable == pinned && _frames.length == 1) return;
      _frames.remove(removable);
      evictionCount += 1;
    }
  }

  void _invalidateForCategoryMetadata() {
    _prepareGeneration += 1;
    final queued = _queuedForeground;
    _queuedForeground = null;
    if (queued != null && !queued.completer.isCompleted) {
      queued.completer.completeError(
        StateError('Budget distribution metadata changed during preparation.'),
      );
    }
    _semanticCache.clear();
    _frames.clear();
    if (value != null) value = null;
  }

  @override
  void dispose() {
    _prepareGeneration += 1;
    final queued = _queuedForeground;
    _queuedForeground = null;
    if (queued != null && !queued.completer.isCompleted) {
      queued.completer.completeError(
        StateError('Budget distribution drawable controller was disposed.'),
      );
    }
    _categories.removeListener(_invalidateForCategoryMetadata);
    super.dispose();
  }
}
