import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../core/financial_limits/domain/financial_limit.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/time_label_formatter.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_live_analysis_projection.dart';
import 'dashboard_budget_target.dart';
import 'dashboard_budget_limit_edit_controller.dart';
import 'dashboard_live_interaction_coordinator.dart';
import 'dashboard_budget_month_end_projection.dart';
import 'dashboard_budget_period.dart';
import 'dashboard_budget_scope_analysis.dart';
import 'transaction_direction_controller.dart';

/// Immutable, presentation-only target input for the Budget rail. Aggregate
/// targets deliberately have no category ID and therefore cannot leak into
/// category filtering or inventory ownership.
@immutable
final class DashboardBudgetTargetPresentationItem {
  const DashboardBudgetTargetPresentationItem({
    required this.target,
    required this.title,
    required this.baseColorArgb,
    required this.iconAssetKey,
    this.colorId,
    this.iconId,
    this.gradientStartArgb,
    this.gradientEndArgb,
  });

  final DashboardBudgetTarget target;
  final String title;
  final int baseColorArgb;
  final String iconAssetKey;
  final String? colorId;
  final String? iconId;
  final int? gradientStartArgb;
  final int? gradientEndArgb;

  String get stableId => switch (target.identity) {
    DashboardBudgetAggregateTarget() => 'aggregate',
    DashboardBudgetCategoryTarget(:final categoryId) => 'category:$categoryId',
  };
}

/// Distinguishes canonical utilization from the DAY-only derived pace.
/// This is presentation analysis mode, not another persisted Budget period.
enum DashboardBudgetAnalysisMode {
  actualUtilization,
  dailyPace,
  annualSegments,
  typicalMarker,
}

@immutable
final class DashboardBudgetLiveSelectionState {
  const DashboardBudgetLiveSelectionState._({
    required this.direction,
    required this.target,
    required this.title,
    required this.displayNumeratorScaled100,
    required this.displayDenominatorScaled100,
    required this.canonicalActualScaled100ForLimitEdit,
    required this.limitScaled100,
    required this.limitKey,
    required this.editContext,
    required this.coreRevision,
    required this.analysisScopeLabel,
    required this.analysisMode,
    required this.scopeAnalysis,
    required this.monthEndProjection,
    required this.visual,
  });

  factory DashboardBudgetLiveSelectionState.unavailable({
    required LedgerDirection direction,
    required DashboardBudgetTarget target,
    required String title,
    String analysisScopeLabel = '—',
  }) => DashboardBudgetLiveSelectionState._(
    direction: direction,
    target: target,
    title: title,
    displayNumeratorScaled100: null,
    displayDenominatorScaled100: null,
    canonicalActualScaled100ForLimitEdit: null,
    limitScaled100: null,
    limitKey: null,
    editContext: null,
    coreRevision: null,
    analysisScopeLabel: analysisScopeLabel,
    analysisMode: DashboardBudgetAnalysisMode.actualUtilization,
    scopeAnalysis: null,
    monthEndProjection: null,
    visual: BudgetCategoryAvatarSelectedLimitVisualState.unavailable(
      targetHandle: target.handle,
    ),
  );

  factory DashboardBudgetLiveSelectionState.available({
    required LedgerDirection direction,
    required DashboardBudgetTarget target,
    required String title,
    required DashboardBudgetScopeAnalysis scopeAnalysis,
    required FinancialLimitKey? limitKey,
    required DashboardBudgetEditContext? editContext,
    required int coreRevision,
    required String analysisScopeLabel,
    required DashboardBudgetAnalysisMode analysisMode,
    List<BudgetProgressRingAnnualSegment> annualSegments =
        const <BudgetProgressRingAnnualSegment>[],
    double? typicalMarkerPosition,
    DashboardBudgetMonthEndProjection? monthEndProjection,
  }) => DashboardBudgetLiveSelectionState._(
    direction: direction,
    target: target,
    title: title,
    displayNumeratorScaled100: scopeAnalysis.displayNumeratorScaled100,
    displayDenominatorScaled100: scopeAnalysis.displayDenominatorScaled100,
    canonicalActualScaled100ForLimitEdit:
        scopeAnalysis.canonicalActualScaled100ForLimitEdit,
    // The canonical monthly/year/base limit remains available for edit and
    // persistence semantics. DAY's Header visual denominator is its allowed
    // daily average and is intentionally separate above.
    limitScaled100: scopeAnalysis.canonicalLimitScaled100ForEdit,
    limitKey: limitKey,
    editContext: editContext,
    coreRevision: coreRevision,
    analysisScopeLabel: analysisScopeLabel,
    analysisMode: analysisMode,
    scopeAnalysis: scopeAnalysis,
    monthEndProjection: monthEndProjection,
    visual: BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: target.handle,
      limitKey: limitKey,
      displayNumeratorScaled100: scopeAnalysis.displayNumeratorScaled100!,
      displayDenominatorScaled100: scopeAnalysis.displayDenominatorScaled100,
      rawProgressOverride: scopeAnalysis.rawRatio,
      chromeGeometry: switch (analysisMode) {
        DashboardBudgetAnalysisMode.actualUtilization =>
          BudgetLimitProgressChromeGeometry.circular,
        DashboardBudgetAnalysisMode.dailyPace =>
          BudgetLimitProgressChromeGeometry.verticalProjection,
        DashboardBudgetAnalysisMode.annualSegments =>
          BudgetLimitProgressChromeGeometry.annualSegments,
        DashboardBudgetAnalysisMode.typicalMarker =>
          BudgetLimitProgressChromeGeometry.typicalMarker,
      },
      annualSegments: annualSegments,
      typicalMarkerPosition: typicalMarkerPosition,
    ),
  );

  final LedgerDirection direction;
  final DashboardBudgetTarget target;
  final String title;

  /// The amount rendered by the Header. In DAY mode this is a derived
  /// actual daily average, never the canonical accounting actual or forecast.
  final int? displayNumeratorScaled100;

  /// The Header's paired denominator. In DAY mode this is allowed daily
  /// average; it is deliberately not the persisted monthly limit amount.
  final int? displayDenominatorScaled100;

  /// The containing-period prepared actual used by existing monthly limit
  /// editing and allocation semantics. It must not be replaced by a forecast.
  final int? canonicalActualScaled100ForLimitEdit;
  final int? limitScaled100;
  final FinancialLimitKey? limitKey;
  final DashboardBudgetEditContext? editContext;
  final int? coreRevision;
  final String analysisScopeLabel;
  final DashboardBudgetAnalysisMode analysisMode;
  final DashboardBudgetScopeAnalysis? scopeAnalysis;
  final DashboardBudgetMonthEndProjection? monthEndProjection;
  final BudgetCategoryAvatarSelectedLimitVisualState visual;

  bool get isAvailable => displayNumeratorScaled100 != null;
  bool get hasLimit => limitScaled100 != null;
  int? get monthlyLimitScaled100 => limitScaled100;

  /// Rebinds a retained, compatible prepared selection to the active scalar
  /// draft while its next snapshot is unavailable. This preserves the one
  /// direct-edit authority without inventing a second Budget analysis or
  /// allowing a Header renderer gap to repaint an older confirmed limit.
  DashboardBudgetLiveSelectionState withActiveScalarLimit(
    int effectiveLimitScaled100,
  ) {
    final projection = monthEndProjection;
    final displayDenominator =
        analysisMode == DashboardBudgetAnalysisMode.dailyPace
        ? projection == null ||
                  projection.daysInMonth == 0 ||
                  effectiveLimitScaled100 <= 0
              ? null
              : (effectiveLimitScaled100 + projection.daysInMonth ~/ 2) ~/
                    projection.daysInMonth
        : effectiveLimitScaled100;
    final rawProgress =
        analysisMode == DashboardBudgetAnalysisMode.dailyPace &&
            projection != null &&
            effectiveLimitScaled100 > 0 &&
            projection.elapsedCalendarDays > 0
        ? projection.monthToDateActualScaled100 *
              projection.daysInMonth /
              (projection.elapsedCalendarDays * effectiveLimitScaled100)
        : displayNumeratorScaled100 != null &&
              displayDenominator != null &&
              displayDenominator > 0
        ? displayNumeratorScaled100! / displayDenominator
        : 0.0;
    return DashboardBudgetLiveSelectionState._(
      direction: direction,
      target: target,
      title: title,
      displayNumeratorScaled100: displayNumeratorScaled100,
      displayDenominatorScaled100: displayDenominator,
      canonicalActualScaled100ForLimitEdit:
          canonicalActualScaled100ForLimitEdit,
      limitScaled100: effectiveLimitScaled100,
      limitKey: limitKey,
      editContext: editContext,
      coreRevision: coreRevision,
      analysisScopeLabel: analysisScopeLabel,
      analysisMode: analysisMode,
      scopeAnalysis: scopeAnalysis,
      monthEndProjection: monthEndProjection,
      visual: BudgetCategoryAvatarSelectedLimitVisualState.available(
        targetHandle: target.handle,
        limitKey: limitKey,
        displayNumeratorScaled100: displayNumeratorScaled100!,
        displayDenominatorScaled100: displayDenominator,
        rawProgressOverride: rawProgress,
        chromeGeometry: switch (analysisMode) {
          DashboardBudgetAnalysisMode.actualUtilization =>
            BudgetLimitProgressChromeGeometry.circular,
          DashboardBudgetAnalysisMode.dailyPace =>
            BudgetLimitProgressChromeGeometry.verticalProjection,
          DashboardBudgetAnalysisMode.annualSegments =>
            BudgetLimitProgressChromeGeometry.annualSegments,
          DashboardBudgetAnalysisMode.typicalMarker =>
            BudgetLimitProgressChromeGeometry.typicalMarker,
        },
      ),
    );
  }

  DashboardBudgetLimitEditContext? get limitEditContext =>
      editContext is DashboardBudgetLimitEditContext
      ? editContext as DashboardBudgetLimitEditContext
      : null;
}

/// The Header's vocabulary is a projection of the typed Budget analysis, not
/// a second interpretation of the selected time plane.  Keeping it here
/// prevents DAY/MONTH/YEAR/SUM wording from drifting across Header widgets.
@immutable
final class DashboardBudgetHeaderMetricPresentation {
  const DashboardBudgetHeaderMetricPresentation._({
    required this.metricLabel,
    required this.modeLabel,
    required this.usesPerDayAmounts,
    required this.supportingStatusKind,
  });

  factory DashboardBudgetHeaderMetricPresentation.forAnalysis(
    DashboardBudgetScopeAnalysis? analysis,
  ) => switch (analysis) {
    DashboardBudgetDayProjectionAnalysis() =>
      const DashboardBudgetHeaderMetricPresentation._day(),
    DashboardBudgetMonthAnalysis() =>
      const DashboardBudgetHeaderMetricPresentation._month(),
    DashboardBudgetYearAnalysis() =>
      const DashboardBudgetHeaderMetricPresentation._year(),
    DashboardBudgetTypicalMonthAnalysis() =>
      const DashboardBudgetHeaderMetricPresentation._sum(),
    null => const DashboardBudgetHeaderMetricPresentation._unavailable(),
  };

  const DashboardBudgetHeaderMetricPresentation._day()
    : this._(
        metricLabel: 'Napi tempó',
        modeLabel: 'tempó',
        usesPerDayAmounts: true,
        supportingStatusKind: DashboardBudgetHeaderSupportingStatusKind.pace,
      );

  const DashboardBudgetHeaderMetricPresentation._month()
    : this._(
        metricLabel: 'Havi állás',
        modeLabel: 'havi budget',
        usesPerDayAmounts: false,
        supportingStatusKind:
            DashboardBudgetHeaderSupportingStatusKind.utilization,
      );

  const DashboardBudgetHeaderMetricPresentation._year()
    : this._(
        metricLabel: 'Éves állás',
        modeLabel: 'éves budget',
        usesPerDayAmounts: false,
        supportingStatusKind:
            DashboardBudgetHeaderSupportingStatusKind.annualAggregate,
      );

  const DashboardBudgetHeaderMetricPresentation._sum()
    : this._(
        metricLabel: 'Havi átlag',
        modeLabel: 'alap budget',
        usesPerDayAmounts: false,
        supportingStatusKind:
            DashboardBudgetHeaderSupportingStatusKind.typicalUtilization,
      );

  const DashboardBudgetHeaderMetricPresentation._unavailable()
    : this._(
        metricLabel: 'Budget',
        modeLabel: 'budget',
        usesPerDayAmounts: false,
        supportingStatusKind: DashboardBudgetHeaderSupportingStatusKind.none,
      );

  final String metricLabel;
  final String modeLabel;
  final bool usesPerDayAmounts;
  final DashboardBudgetHeaderSupportingStatusKind supportingStatusKind;
}

enum DashboardBudgetHeaderSupportingStatusKind {
  none,
  pace,
  utilization,
  annualAggregate,
  typicalUtilization,
}

/// Rendering adapter for the header. It owns no independent data: all values
/// are proxied from the exact same immutable selection used by the ring.
@immutable
final class DashboardBudgetHeaderPresentation {
  const DashboardBudgetHeaderPresentation(this._selection);

  final DashboardBudgetLiveSelectionState _selection;

  DashboardBudgetTarget get target => _selection.target;
  String get title => _selection.title;
  int? get displayNumeratorScaled100 => _selection.displayNumeratorScaled100;
  int? get displayDenominatorScaled100 =>
      _selection.displayDenominatorScaled100;
  int? get canonicalActualScaled100ForLimitEdit =>
      _selection.canonicalActualScaled100ForLimitEdit;
  DashboardBudgetMonthEndProjection? get monthEndProjection =>
      _selection.monthEndProjection;
  DashboardBudgetScopeAnalysis? get scopeAnalysis => _selection.scopeAnalysis;
  int? get limitScaled100 => _selection.limitScaled100;
  FinancialLimitKey? get limitKey => _selection.limitKey;
  DashboardBudgetEditContext? get editContext => _selection.editContext;
  int? get coreRevision => _selection.coreRevision;
  String get analysisScopeLabel => _selection.analysisScopeLabel;
  DashboardBudgetHeaderMetricPresentation get metric =>
      DashboardBudgetHeaderMetricPresentation.forAnalysis(scopeAnalysis);
  bool get isAvailable => _selection.isAvailable;
  bool get hasLimit => _selection.hasLimit;
  DashboardBudgetLimitEditContext? get limitEditContext =>
      _selection.limitEditContext;
}

/// One resolved category segment. This remains scalar so the painter can walk
/// the prepared bank in canonical order without allocating a category list on
/// an optimistic semantic tick.
@immutable
final class DashboardBudgetPartitionSegmentPresentation {
  const DashboardBudgetPartitionSegmentPresentation._({
    required this.opaqueRatio,
    required this.translucentRatio,
  });

  static const empty = DashboardBudgetPartitionSegmentPresentation._(
    opaqueRatio: 0,
    translucentRatio: 0,
  );

  final double opaqueRatio;
  final double translucentRatio;

  double get totalRatio => opaqueRatio + translucentRatio;
}

/// Immutable, same-publication Budget allocation partition. It retains the
/// prepared direction bank and catalog references; renderer traversal derives
/// only each individual segment while the allocation total is already a scalar.
@immutable
final class DashboardBudgetPartitionPresentation {
  const DashboardBudgetPartitionPresentation._({
    required this.direction,
    required this.period,
    required this.periodSliceIndex,
    required this.coreRevision,
    required this.bank,
    required this.catalog,
    required this.aggregateActualScaled100,
    required this.effectiveAggregateLimitScaled100,
    required this.preparedAllocatedTotalScaled100,
    required this.optimisticAllocationDeltaScaled100,
    required this.effectiveLimitByTargetHandle,
    required this.categoryOverlay,
  });

  const DashboardBudgetPartitionPresentation.unavailable({
    required this.direction,
  }) : period = null,
       periodSliceIndex = null,
       coreRevision = null,
       bank = null,
       catalog = null,
       aggregateActualScaled100 = null,
       effectiveAggregateLimitScaled100 = null,
       preparedAllocatedTotalScaled100 = 0,
       optimisticAllocationDeltaScaled100 = 0,
       effectiveLimitByTargetHandle = const <int, int>{},
       categoryOverlay = DashboardBudgetCategoryAllocationOverlay.empty;

  final LedgerDirection direction;
  final BudgetLimitPeriod? period;
  final int? periodSliceIndex;
  final int? coreRevision;
  final PreparedBudgetLimitDirectionBank? bank;
  final DashboardBudgetTargetCatalog? catalog;
  final int? aggregateActualScaled100;
  final int? effectiveAggregateLimitScaled100;
  final int preparedAllocatedTotalScaled100;
  final int optimisticAllocationDeltaScaled100;

  /// Sparse optimistic corrections over the immutable prepared dense bank.
  /// It is populated only while a base or YEAR vector mutation is active or
  /// pending; ordinary temporal ticks keep using the prepared cells directly.
  final Map<int, int> effectiveLimitByTargetHandle;
  final DashboardBudgetCategoryAllocationOverlay categoryOverlay;

  bool get isAvailable =>
      period != null &&
      periodSliceIndex != null &&
      bank != null &&
      catalog != null;
  bool get hasPositiveAggregateLimit =>
      effectiveAggregateLimitScaled100 != null &&
      effectiveAggregateLimitScaled100! > 0;
  int get liveAllocatedTotalScaled100 {
    final total =
        preparedAllocatedTotalScaled100 + optimisticAllocationDeltaScaled100;
    return total > 0 ? total : 0;
  }

  double get allocationRawRatio {
    final denominator = effectiveAggregateLimitScaled100;
    if (denominator == null || denominator <= 0) return 0;
    return liveAllocatedTotalScaled100 / denominator;
  }

  double get allocationVisualCoverage =>
      allocationRawRatio.clamp(0.0, 1.0).toDouble();

  int? effectiveLimitForCategoryHandle(int handle) {
    final directionBank = bank;
    final targetCatalog = catalog;
    final slice = periodSliceIndex;
    if (directionBank == null || targetCatalog == null || slice == null) {
      return null;
    }
    if (handle <= 0 || handle >= directionBank.targetCount) return null;
    final target = targetCatalog.targetAtHandle(handle);
    final categoryId = target.category?.id;
    if (categoryId == null) return null;
    final optimisticLimit = effectiveLimitByTargetHandle[handle];
    if (optimisticLimit != null) return optimisticLimit;
    return categoryOverlay.hasOverrideForCategoryId(categoryId)
        ? categoryOverlay.effectiveLimitForCategoryId(categoryId)
        : directionBank
              .cellAt(periodSliceIndex: slice, targetHandle: handle)
              .limitScaled100;
  }

  DashboardBudgetPartitionSegmentPresentation segmentForCategoryHandle(
    int handle,
  ) {
    final denominator = effectiveAggregateLimitScaled100;
    final directionBank = bank;
    final slice = periodSliceIndex;
    if (denominator == null ||
        denominator <= 0 ||
        directionBank == null ||
        slice == null) {
      return DashboardBudgetPartitionSegmentPresentation.empty;
    }
    final limit = effectiveLimitForCategoryHandle(handle);
    if (limit == null || limit <= 0) {
      return DashboardBudgetPartitionSegmentPresentation.empty;
    }
    final actual = directionBank
        .cellAt(periodSliceIndex: slice, targetHandle: handle)
        .actualScaled100;
    final opaqueAmount = actual.clamp(0, limit);
    return DashboardBudgetPartitionSegmentPresentation._(
      opaqueRatio: opaqueAmount / denominator,
      translucentRatio: (limit - opaqueAmount) / denominator,
    );
  }
}

@immutable
final class DashboardBudgetPresentationState {
  const DashboardBudgetPresentationState({
    required this.items,
    required this.selectedHandle,
    this.visibleModeEpoch = 0,
    this.liveAnalysis = const DashboardBudgetLiveAnalysisProjection.unavailable(
      direction: LedgerDirection.expense,
      targetHandle: 0,
    ),
    required this.liveSelection,
    required this.partition,
  });

  final List<DashboardBudgetTargetPresentationItem> items;
  final int selectedHandle;

  /// The dashboard-core visibility epoch that produced this atomic Budget
  /// frame. It prevents a same-target return to Budget from being collapsed
  /// into a stale no-op by a renderer or publication observer.
  final int visibleModeEpoch;
  final DashboardBudgetLiveAnalysisProjection liveAnalysis;
  final DashboardBudgetLiveSelectionState liveSelection;
  final DashboardBudgetPartitionPresentation partition;

  DashboardBudgetHeaderPresentation get header =>
      DashboardBudgetHeaderPresentation(liveSelection);
  BudgetCategoryAvatarSelectedLimitVisualState get selectedLimitVisual =>
      liveSelection.visual;
}

/// Bounded per-prepared-revision SUM source cache. The average is independent
/// of a base-limit edit, so only the small denominator adapter is rebuilt
/// during an optimistic SUM gesture; an avatar carousel tick never walks the
/// history window again.
@immutable
final class _TypicalMonthAverageCacheKey {
  const _TypicalMonthAverageCacheKey({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final int yearWindowStart;
  final int yearWindowEndInclusive;

  @override
  bool operator ==(Object other) =>
      other is _TypicalMonthAverageCacheKey &&
      other.coreRevision == coreRevision &&
      other.direction == direction &&
      other.targetHandle == targetHandle &&
      other.yearWindowStart == yearWindowStart &&
      other.yearWindowEndInclusive == yearWindowEndInclusive;

  @override
  int get hashCode => Object.hash(
    coreRevision,
    direction,
    targetHandle,
    yearWindowStart,
    yearWindowEndInclusive,
  );
}

/// Headless, CoreDashboard-lifetime binding between immutable target visuals,
/// an exact prepared limit bank and the local Budget header. It owns no I/O,
/// carousel physics, Query or LogBox state. A semantic target change resolves
/// one dense RAM cell and publishes only this narrow presentation state.
final class DashboardBudgetPresentationController
    extends ValueNotifier<DashboardBudgetPresentationState> {
  DashboardBudgetPresentationController({
    required ValueListenable<List<FluviCategory>> categoryCollection,
    required ValueListenable<DashboardVisibleFrame?> visibleFrame,
    DashboardLiveInteractionCoordinator? liveInteractions,
    required TransactionDirectionController transactionDirection,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
    required LocalDate logicalAsOfDate,
    DashboardBudgetLimitEditController? limitEditController,
    ValueChanged<int>? onInputUpdated,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _liveInteractions = liveInteractions,
       _transactionDirection = transactionDirection,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _logicalAsOfDate = logicalAsOfDate,
       _limitEditController = limitEditController,
       _onInputUpdated = onInputUpdated,
       super(_initialState()) {
    _categoryCollection.addListener(_refreshCatalogForCategoryInput);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _liveInteractions?.addListener(_refreshForLiveInteraction);
    _transactionDirection.addListener(_refreshCatalogForDirection);
    _limitEditController?.addListener(_refreshForOptimisticLimitEdit);
    _refreshCatalog(notifyCategoryInput: true);
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final DashboardLiveInteractionCoordinator? _liveInteractions;
  final TransactionDirectionController _transactionDirection;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final LocalDate _logicalAsOfDate;
  final DashboardBudgetLimitEditController? _limitEditController;
  final ValueChanged<int>? _onInputUpdated;
  DashboardBudgetEditContext? _lastDirectInputEditContext;

  static DashboardBudgetPresentationState _initialState() {
    const aggregate = DashboardBudgetTarget.aggregate();
    return DashboardBudgetPresentationState(
      items: const <DashboardBudgetTargetPresentationItem>[],
      selectedHandle: 0,
      liveAnalysis: const DashboardBudgetLiveAnalysisProjection.unavailable(
        direction: LedgerDirection.expense,
        targetHandle: 0,
      ),
      liveSelection: DashboardBudgetLiveSelectionState.unavailable(
        direction: LedgerDirection.expense,
        target: aggregate,
        title: 'Budget',
      ),
      partition: const DashboardBudgetPartitionPresentation.unavailable(
        direction: LedgerDirection.expense,
      ),
    );
  }

  DashboardBudgetTargetCatalog? _catalog;
  PreparedBudgetLimitSnapshot? _snapshotUsedForCatalog;
  final Map<LedgerDirection, DashboardBudgetTargetIdentity?>
  _selectedIdentityByDirection =
      <LedgerDirection, DashboardBudgetTargetIdentity?>{};
  List<FluviCategory>? _lastReportedCategoryInput;
  int? _lastHeaderDiagnosticSignature;
  String? _lastLimitStateDiagnosticSummary;
  int? _lastLimitUnavailabilityDiagnosticSignature;
  int? _lastProgressDiagnosticSignature;
  int? _lastPartitionDiagnosticSignature;
  int? _lastLiveAnalysisDiagnosticSignature;
  int? _lastMonthEndProjectionDiagnosticSignature;
  int? _lastDirectionDomainDiagnosticSignature;
  int _visibleModeEpoch = 0;
  PreparedBudgetLimitSnapshot? _typicalAverageCacheSnapshot;
  final Map<_TypicalMonthAverageCacheKey, DashboardBudgetTypicalMonthAverage>
  _typicalAverageByPreparedTarget =
      <_TypicalMonthAverageCacheKey, DashboardBudgetTypicalMonthAverage>{};

  /// Called by the shared carousel only on semantic selection changes, never
  /// for a pixel or animation tick.
  void setTargetHandle(int handle) {
    final catalog = _catalog;
    if (catalog == null || handle < 0 || handle >= catalog.targetCount) return;
    if (handle == value.selectedHandle) return;
    final target = catalog.targetAtHandle(handle);
    _selectedIdentityByDirection[_direction] = target.identity;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_TARGET_SELECTION_CHANGED',
        direction: _direction.name,
        scope:
            'targetHandle=$handle '
            'targetKind=${target.isAggregate ? 'aggregate' : 'category'} '
            'categoryId=${target.category?.id ?? '-'} logicalIndex=$handle',
      ),
    );
    _publishHeaderOnly(catalog: catalog, selectedHandle: handle);
  }

  /// Resolves an already-prepared target without changing the visible Budget
  /// selection.  The Query/LogBox semantic commit owns when [setTargetHandle]
  /// may promote this target.
  DashboardBudgetTarget? targetForHandle(int handle) {
    final catalog = _catalog;
    if (catalog == null || handle < 0 || handle >= catalog.targetCount) {
      return null;
    }
    return catalog.targetAtHandle(handle);
  }

  /// Checks a persistence key against the current visible authority without
  /// consulting the retained Header. It deliberately still works while the
  /// next immutable snapshot is being prepared, so an old direct-edit draft
  /// cannot commit after an already-visible target/scope replacement.
  bool isLimitEditKeyCurrent(FinancialLimitKey key) {
    final authority = _currentVisibleEditAuthority();
    if (authority == null) return false;
    final period = DashboardBudgetPeriodResolver.fromTimeScope(authority.scope);
    return _financialLimitKeyFor(authority.target, period: period) == key;
  }

  /// YEAR's derived vector has no scalar key; validate its typed identity
  /// against the same unprepared visible authority before a batch can write.
  bool isYearLimitEditContextCurrent(
    DashboardBudgetYearLimitEditContext context,
  ) {
    final authority = _currentVisibleEditAuthority();
    if (authority == null) return false;
    final scope = authority.scope;
    if (scope is! YearScope) return false;
    return context.direction == _financialLimitDirection &&
        context.target == _financialLimitTargetFor(authority.target) &&
        context.year == scope.year;
  }

  /// Returns the last exact selected-target/scope edit context while that
  /// canonical semantic authority is still current. Header is only a renderer
  /// of the same selection; a transient Header/snapshot replacement therefore
  /// cannot remove the Avatar's direct input owner.
  ///
  /// The context is retained only for the same scalar FinancialLimit key or
  /// the same typed YEAR target. A concrete target or temporal replacement
  /// never reuses it, and [DashboardBudgetLimitEditController] still validates
  /// the key/context again immediately before persistence.
  DashboardBudgetEditContext? directInputEditContext() {
    final authority = _currentVisibleEditAuthority();
    if (authority == null) return null;
    final retained = _lastDirectInputEditContext;
    if (retained != null && _matchesDirectInputAuthority(retained, authority)) {
      return retained;
    }
    final current = value.liveSelection.editContext;
    if (current == null || !_matchesDirectInputAuthority(current, authority)) {
      return null;
    }
    _lastDirectInputEditContext = current;
    return current;
  }

  bool _matchesDirectInputAuthority(
    DashboardBudgetEditContext context,
    ({DashboardBudgetTarget target, LedgerTimeScope scope, int coreRevision})
    authority,
  ) => switch (context) {
    DashboardBudgetLimitEditContext(:final key) =>
      _financialLimitKeyFor(
            authority.target,
            period: DashboardBudgetPeriodResolver.fromTimeScope(
              authority.scope,
            ),
          ) ==
          key,
    DashboardBudgetYearLimitEditContext(
      :final direction,
      :final target,
      :final year,
    ) =>
      authority.scope is YearScope &&
          direction == _financialLimitDirection &&
          target == _financialLimitTargetFor(authority.target) &&
          year == (authority.scope as YearScope).year,
  };

  /// Replays the current RAM-resident Budget authority when Budget becomes
  /// visible again. A mode transition changes the visible publication identity
  /// even when target, direction, scope and prepared revision are unchanged.
  ///
  /// This does no I/O and retains the existing dense catalog/cell hot path.
  void publishForVisibleBudgetEpoch(int modeEpoch) {
    if (modeEpoch <= _visibleModeEpoch) return;
    _visibleModeEpoch = modeEpoch;
    final snapshot = _snapshotForCurrentFrame();
    final catalog = _catalog;
    if (catalog == null || !identical(snapshot, _snapshotUsedForCatalog)) {
      _refreshCatalog();
    } else {
      _publishHeaderOnly(
        catalog: catalog,
        selectedHandle: value.selectedHandle,
      );
    }
    final published = value;
    final live = published.liveAnalysis;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_VISIBLE_PUBLICATION_REPLAYED',
        coreRevision: live.coreRevision,
        direction: live.direction.name,
        scope:
            'modeEpoch=$modeEpoch '
            'interactionGeneration=${live.interactionGeneration} '
            'targetHandle=${published.selectedHandle} '
            'analysisScope=${live.scope?.canonicalKey ?? '-'} '
            'available=${published.liveSelection.isAvailable} '
            'hasLimit=${published.header.hasLimit}',
      ),
    );
  }

  /// Category collection changes are the only source of rail-item rebuilding.
  /// A semantic time tick deliberately bypasses this lane and resolves only the
  /// dense header cell below.
  void _refreshCatalogForCategoryInput() {
    _refreshCatalog(notifyCategoryInput: true);
  }

  /// Direction changes alter only the aggregate visual and its direction
  /// vector; they do not represent another category-inventory publication.
  void _refreshCatalogForDirection() {
    _refreshCatalog();
  }

  void _refreshForVisibleFrame() {
    final snapshot = _snapshotForCurrentFrame();
    if (!identical(snapshot, _snapshotUsedForCatalog)) {
      // A new exact revision can carry a changed ordered category domain. Do
      // the structural join once, then keep semantic time ticks list-free.
      _refreshCatalog();
      return;
    }
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  /// Live direct input owns Budget's foreground temporal projection. A
  /// [DashboardVisibleFrame] is still kept for initial/revision
  /// reconciliation, but scene coverage must never decide whether the header,
  /// ring or partition follows an accepted temporal crossing.
  void _refreshForLiveInteraction() {
    final snapshot = _snapshotForCurrentFrame();
    if (!identical(snapshot, _snapshotUsedForCatalog)) {
      _refreshCatalog();
      return;
    }
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  void _refreshForOptimisticLimitEdit() {
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  void _refreshCatalog({bool notifyCategoryInput = false}) {
    final catalog = _buildCompatibleCatalog();
    final selectedHandle =
        _handleForIdentity(catalog, _selectedIdentityByDirection[_direction]) ??
        0;
    _selectedIdentityByDirection[_direction] = catalog
        .targetAtHandle(selectedHandle)
        .identity;
    _catalog = catalog;
    _snapshotUsedForCatalog = _snapshotForCurrentFrame();
    _evictTypicalAverageCacheFor(_snapshotUsedForCatalog);
    _publishCatalog(catalog: catalog, selectedHandle: selectedHandle);
    _recordDirectionDomain(catalog, _snapshotUsedForCatalog);
    if (notifyCategoryInput &&
        !_sameCategoryInput(
          _lastReportedCategoryInput,
          _categoryCollection.value,
        )) {
      _lastReportedCategoryInput = List<FluviCategory>.unmodifiable(
        _categoryCollection.value,
      );
      // This diagnostic retains its established inventory meaning: aggregate
      // targets are Budget-domain presentation entries, not categories.
      _onInputUpdated?.call(_categoryCollection.value.length);
    }
  }

  DashboardBudgetTargetCatalog _buildCompatibleCatalog() {
    final snapshot = _snapshotForCurrentFrame();
    final categories = _categoryCollection.value;
    final categoryById = <String, FluviCategory>{
      for (final category in categories) category.id: category,
    };
    // Prepared membership/order is the only Budget target-domain authority.
    // Until an exact direction bank arrives, expose aggregate only rather
    // than leaking the category inventory from the opposite direction.
    if (snapshot == null) {
      return DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[],
      );
    }
    final ordered = snapshot.directionBank(_direction).orderedCategoryIds;
    // A category collection from another core revision must never pair with
    // dense vectors from this one. Keep the aggregate only until an exact
    // compatible publication arrives.
    if (ordered.any((id) => !categoryById.containsKey(id))) {
      return DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[],
      );
    }
    return DashboardBudgetTargetCatalog.fromCategories(
      List<DashboardBudgetCategoryVisual>.unmodifiable([
        for (final id in ordered)
          DashboardBudgetCategoryVisual(
            id: categoryById[id]!.id,
            displayName: categoryById[id]!.name,
            colorId: categoryById[id]!.colorId,
            iconId: categoryById[id]!.iconId,
          ),
      ]),
    );
  }

  int? _handleForIdentity(
    DashboardBudgetTargetCatalog catalog,
    DashboardBudgetTargetIdentity? identity,
  ) {
    if (identity == null) return null;
    for (final target in catalog.targets) {
      if (target.identity == identity) return target.handle;
    }
    return null;
  }

  static bool _sameCategoryInput(
    List<FluviCategory>? previous,
    List<FluviCategory> next,
  ) {
    if (previous == null || previous.length != next.length) return false;
    for (var index = 0; index < next.length; index += 1) {
      final left = previous[index];
      final right = next[index];
      if (left.id != right.id ||
          left.name != right.name ||
          left.colorId != right.colorId ||
          left.iconId != right.iconId ||
          left.updatedAtUtcMs != right.updatedAtUtcMs) {
        return false;
      }
    }
    return true;
  }

  void _publishCatalog({
    required DashboardBudgetTargetCatalog catalog,
    required int selectedHandle,
  }) {
    final items = List<DashboardBudgetTargetPresentationItem>.unmodifiable([
      for (final target in catalog.targets) _itemFor(target),
    ]);
    final selectedTarget = catalog.targetAtHandle(selectedHandle);
    final liveAnalysis = _liveAnalysisFor(selectedHandle);
    final liveSelection = _liveSelectionFor(selectedTarget, liveAnalysis);
    final partition = _partitionFor(
      catalog: catalog,
      liveAnalysis: liveAnalysis,
    );
    value = DashboardBudgetPresentationState(
      items: items,
      selectedHandle: selectedHandle,
      visibleModeEpoch: _visibleModeEpoch,
      liveAnalysis: liveAnalysis,
      liveSelection: liveSelection,
      partition: partition,
    );
    _recordLiveAnalysisBinding(liveAnalysis);
    _recordHeaderBinding(liveSelection, liveAnalysis);
    _recordProgressBinding(liveSelection, liveAnalysis);
    _recordMonthEndProjection(liveSelection, liveAnalysis);
    _recordPartitionBinding(
      partition,
      selectedHandle: selectedHandle,
      liveAnalysis: liveAnalysis,
    );
  }

  /// The hot semantic tick path: retained catalog + selected dense RAM cell.
  /// It intentionally performs no category projection, item-list build, sort,
  /// search, repository read or native bridge call.
  void _publishHeaderOnly({
    required DashboardBudgetTargetCatalog catalog,
    required int selectedHandle,
  }) {
    final selectedTarget = catalog.targetAtHandle(selectedHandle);
    final liveAnalysis = _liveAnalysisFor(selectedHandle);
    final liveSelection = _liveSelectionFor(selectedTarget, liveAnalysis);
    final partition = _partitionFor(
      catalog: catalog,
      liveAnalysis: liveAnalysis,
    );
    value = DashboardBudgetPresentationState(
      items: value.items,
      selectedHandle: selectedHandle,
      visibleModeEpoch: _visibleModeEpoch,
      liveAnalysis: liveAnalysis,
      liveSelection: liveSelection,
      partition: partition,
    );
    _recordLiveAnalysisBinding(liveAnalysis);
    _recordHeaderBinding(liveSelection, liveAnalysis);
    _recordProgressBinding(liveSelection, liveAnalysis);
    _recordMonthEndProjection(liveSelection, liveAnalysis);
    _recordPartitionBinding(
      partition,
      selectedHandle: selectedHandle,
      liveAnalysis: liveAnalysis,
    );
  }

  DashboardBudgetTargetPresentationItem _itemFor(DashboardBudgetTarget target) {
    if (target.isAggregate) {
      final aggregate = DashboardBudgetAggregateVisual.forDirection(_direction);
      return DashboardBudgetTargetPresentationItem(
        target: target,
        title: aggregate.title,
        baseColorArgb: aggregate.middleColorArgb,
        iconAssetKey: aggregate.iconAssetKey,
        gradientStartArgb: aggregate.startColorArgb,
        gradientEndArgb: aggregate.endColorArgb,
      );
    }
    final category = target.category!;
    return DashboardBudgetTargetPresentationItem(
      target: target,
      title: category.displayName,
      baseColorArgb: 0,
      iconAssetKey: 'category',
      colorId: category.colorId,
      iconId: category.iconId,
    );
  }

  DashboardBudgetLiveAnalysisProjection _liveAnalysisFor(int targetHandle) {
    final resolved = DashboardBudgetLiveAnalysisProjection.resolve(
      liveInteraction: _liveInteractions?.frame,
      visibleFrame: _visibleFrame.value,
      preparedCoreRevision: _snapshotForCurrentFrame()?.coreRevision,
      selectedDirection: _direction,
      selectedTargetHandle: targetHandle,
    );
    if (resolved.isAvailable) return resolved;

    _invalidateEditsForResolvedVisibleAuthority();

    // A direct edit owns its compatible visible draft across a preparation
    // gap. Retain the last atomic analysis only for its exact selected target
    // and key; a real target/scope publication below still invalidates it.
    final active = _limitEditController?.value;
    final previous = value;
    if (active != null &&
        active.targetHandle == targetHandle &&
        previous.selectedHandle == targetHandle &&
        previous.liveAnalysis.isAvailable &&
        previous.liveSelection.limitKey == active.key) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_LIMIT_EDIT_ACTIVE_ANALYSIS_RETAINED',
          coreRevision: previous.liveAnalysis.coreRevision,
          direction: previous.liveAnalysis.direction.name,
          scope:
              'generation=${active.generation} '
              'targetHandle=$targetHandle '
              'analysisScope=${previous.liveAnalysis.scope?.canonicalKey ?? '-'}',
        ),
      );
      return previous.liveAnalysis;
    }
    return resolved;
  }

  /// Resolves identity only from the current foreground/visible authority. It
  /// intentionally does not require the matching prepared Budget snapshot:
  /// this is the narrow persistence-safety path for a direct edit while that
  /// snapshot is in flight.
  ({DashboardBudgetTarget target, LedgerTimeScope scope, int coreRevision})?
  _currentVisibleEditAuthority() {
    final live = _liveInteractions?.frame;
    final visible = _visibleFrame.value;
    final visibleMatchesDirection =
        visible != null && visible.direction == _direction;
    // A retained foreground frame is authoritative only while it is at least
    // as new as the committed navigation and revision. Core revisions are
    // deliberately reused across navigation-only preparations, so revision
    // alone cannot order January against a visible February replacement.
    // The coordinator intentionally retains its latest accepted frame; it
    // must never outvote a later visible navigation epoch merely because the
    // matching Budget snapshot is still preparing.
    final useLive =
        live != null &&
        live.coreRevision != null &&
        live.direction == _direction &&
        (!visibleMatchesDirection ||
            (live.temporalCandidate.navigationEpoch >=
                    visible.navigationEpoch &&
                live.coreRevision! >= visible.coreRevision));
    if (!useLive && !visibleMatchesDirection) {
      return null;
    }
    final targetHandle = useLive
        ? live.budgetTargetHandle ?? value.selectedHandle
        : value.selectedHandle;
    final catalog = _catalog;
    if (catalog == null ||
        targetHandle < 0 ||
        targetHandle >= catalog.targetCount) {
      return null;
    }
    return (
      target: catalog.targetAtHandle(targetHandle),
      scope: useLive
          ? live.temporalCandidate.effectiveScope
          : visible!.scope.timeScope,
      coreRevision: useLive ? live.coreRevision! : visible!.coreRevision,
    );
  }

  void _invalidateEditsForResolvedVisibleAuthority() {
    final authority = _currentVisibleEditAuthority();
    if (authority == null) {
      _limitEditController?.invalidateIfContextChanged(null);
      _limitEditController?.invalidateYearIfContextChanged(null);
      return;
    }
    final period = DashboardBudgetPeriodResolver.fromTimeScope(authority.scope);
    _limitEditController?.invalidateIfResolvedContextChanged(
      _financialLimitKeyFor(authority.target, period: period),
    );
    _limitEditController?.invalidateYearIfResolvedContextChanged(
      direction: _financialLimitDirection,
      target: _financialLimitTargetFor(authority.target),
      year: switch (authority.scope) {
        YearScope(:final year) => year,
        _ => null,
      },
      coreRevision: authority.coreRevision,
    );
  }

  DashboardBudgetLiveSelectionState _liveSelectionFor(
    DashboardBudgetTarget target,
    DashboardBudgetLiveAnalysisProjection liveAnalysis,
  ) {
    final snapshot = _snapshotForCurrentFrame();
    final title = _titleFor(target);
    final unavailableReason = snapshot == null
        ? 'snapshotUnavailable'
        : !liveAnalysis.isAvailable
        ? 'liveAnalysisUnavailable'
        : snapshot.coreRevision != liveAnalysis.coreRevision
        ? 'snapshotRevisionMismatch'
        : liveAnalysis.targetHandle != target.handle
        ? 'targetHandleMismatch'
        : target.handle >= snapshot.targetCountFor(_direction)
        ? 'targetHandleOutsideSnapshot'
        : null;
    if (unavailableReason != null) {
      _invalidateEditsForResolvedVisibleAuthority();
      final active = _limitEditController?.value;
      final previous = value.liveSelection;
      final retainsActiveDraft =
          active != null &&
          active.targetHandle == target.handle &&
          previous.target.handle == target.handle &&
          previous.limitKey == active.key &&
          previous.isAvailable;
      _recordLimitSelectionUnavailable(
        reason: unavailableReason,
        target: target,
        liveAnalysis: liveAnalysis,
        snapshot: snapshot,
        retainsActiveDraft: retainsActiveDraft,
      );
      if (retainsActiveDraft) {
        // The selected Header/ring object was already recomputed from this
        // exact draft on the preceding direct tick. Reusing that immutable
        // compatible publication avoids a visible unavailable frame while
        // waiting for the next canonical preparation.
        return previous.withActiveScalarLimit(
          active.effectiveLimitScaled100 ?? 0,
        );
      }
      return DashboardBudgetLiveSelectionState.unavailable(
        direction: _direction,
        target: target,
        title: title,
      );
    }
    final preparedSnapshot = snapshot!;
    final visibleScope = liveAnalysis.scope!;
    final preparedBudgetPeriod = DashboardBudgetPeriodResolver.fromTimeScope(
      visibleScope,
    );
    final key = _financialLimitKeyFor(target, period: preparedBudgetPeriod);
    _limitEditController?.invalidateIfContextChanged(key);
    late final PreparedBudgetLimitCell cell;
    try {
      cell = preparedSnapshot.cellAt(
        direction: _direction,
        period: preparedBudgetPeriod,
        targetHandle: target.handle,
      );
    } on RangeError {
      // A prepared period outside the exact RAM window is unavailable, never a
      // reason to repair the snapshot through an interaction-time read.
      _recordLimitSelectionUnavailable(
        reason: 'periodOutsidePreparedWindow',
        target: target,
        liveAnalysis: liveAnalysis,
        snapshot: preparedSnapshot,
      );
      return DashboardBudgetLiveSelectionState.unavailable(
        direction: _direction,
        target: target,
        title: title,
        analysisScopeLabel: _analysisScopeLabel(visibleScope),
      );
    }
    final effectiveLimitScaled100 = _effectiveLimitForPreparedCell(
      snapshot: preparedSnapshot,
      target: target,
      period: preparedBudgetPeriod,
      cell: cell,
    );
    final monthEndProjection = _monthEndProjectionFor(
      snapshot: preparedSnapshot,
      direction: _direction,
      targetHandle: target.handle,
      scope: visibleScope,
      canonicalMonthlyActualScaled100: cell.actualScaled100,
      effectiveMonthlyLimitScaled100: effectiveLimitScaled100,
    );
    final scopeAnalysis = switch (visibleScope) {
      DayScope() => DashboardBudgetDayProjectionAnalysis(
        projection: monthEndProjection!,
        canonicalMonthlyActualScaled100: cell.actualScaled100,
      ),
      MonthScope() => DashboardBudgetMonthAnalysis(
        monthlyActualScaled100: cell.actualScaled100,
        resolvedMonthlyLimitScaled100: effectiveLimitScaled100,
      ),
      YearScope(:final year) => _yearAnalysisFor(
        snapshot: preparedSnapshot,
        target: target,
        year: year,
        annualActualScaled100: cell.actualScaled100,
      ),
      AllTimeScope() => _typicalMonthAnalysisFor(
        snapshot: preparedSnapshot,
        target: target,
        baseMonthlyLimitScaled100: effectiveLimitScaled100,
      ),
    };
    if (scopeAnalysis.displayNumeratorScaled100 == null) {
      _recordLimitSelectionUnavailable(
        reason: 'scopeAnalysisDisplayNumeratorUnavailable',
        target: target,
        liveAnalysis: liveAnalysis,
        snapshot: snapshot,
      );
      return DashboardBudgetLiveSelectionState.unavailable(
        direction: _direction,
        target: target,
        title: title,
        analysisScopeLabel: _analysisScopeLabel(visibleScope),
      );
    }
    final analysisMode = switch (scopeAnalysis) {
      DashboardBudgetDayProjectionAnalysis() =>
        DashboardBudgetAnalysisMode.dailyPace,
      DashboardBudgetYearAnalysis() =>
        DashboardBudgetAnalysisMode.annualSegments,
      DashboardBudgetTypicalMonthAnalysis() =>
        DashboardBudgetAnalysisMode.typicalMarker,
      DashboardBudgetMonthAnalysis() =>
        DashboardBudgetAnalysisMode.actualUtilization,
    };
    final annualSegments = scopeAnalysis is DashboardBudgetYearAnalysis
        ? _annualSegmentsFor(
            scopeAnalysis,
            year: (visibleScope as YearScope).year,
          )
        : const <BudgetProgressRingAnnualSegment>[];
    final editContext = _editContextFor(
      target: target,
      visibleScope: visibleScope,
      scopeAnalysis: scopeAnalysis,
      scalarKey: key,
      coreRevision: preparedSnapshot.coreRevision,
    );
    if (editContext != null) _lastDirectInputEditContext = editContext;
    _limitEditController?.invalidateYearIfContextChanged(
      editContext is DashboardBudgetYearLimitEditContext ? editContext : null,
    );
    return DashboardBudgetLiveSelectionState.available(
      direction: _direction,
      target: target,
      title: title,
      scopeAnalysis: scopeAnalysis,
      limitKey: key,
      editContext: editContext,
      coreRevision: preparedSnapshot.coreRevision,
      analysisScopeLabel: _analysisScopeLabel(visibleScope),
      analysisMode: analysisMode,
      annualSegments: annualSegments,
      typicalMarkerPosition:
          scopeAnalysis is DashboardBudgetTypicalMonthAnalysis
          ? scopeAnalysis.rawRatio
          : null,
      monthEndProjection: monthEndProjection,
    );
  }

  /// A physical Header disappearance must be diagnosable from its canonical
  /// producer inputs. This does not retain or repair a value; it records why
  /// the selection resolver could not publish one for this exact authority.
  void _recordLimitSelectionUnavailable({
    required String reason,
    required DashboardBudgetTarget target,
    required DashboardBudgetLiveAnalysisProjection liveAnalysis,
    required PreparedBudgetLimitSnapshot? snapshot,
    bool retainsActiveDraft = false,
  }) {
    final visible = _visibleFrame.value;
    final interaction = _liveInteractions?.frame;
    final signature = Object.hash(
      reason,
      target.handle,
      _direction,
      liveAnalysis.provenanceKey,
      snapshot?.coreRevision,
      snapshot?.targetCountFor(_direction),
      visible?.navigationEpoch,
      visible?.presentationEpoch,
      interaction?.generation,
      retainsActiveDraft,
    );
    if (_lastLimitUnavailabilityDiagnosticSignature == signature) return;
    _lastLimitUnavailabilityDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'LIMIT|SELECTION_UNAVAILABLE',
        coreRevision: liveAnalysis.coreRevision ?? visible?.coreRevision,
        direction: _direction.name,
        queryKey: visible?.scope.key.value,
        scope:
            'reason=$reason '
            'selectedHandle=${value.selectedHandle} '
            'targetHandle=${target.handle} '
            'liveTargetHandle=${liveAnalysis.targetHandle} '
            'liveAnalysisAvailable=${liveAnalysis.isAvailable} '
            'analysisScope=${liveAnalysis.scope?.canonicalKey ?? '-'} '
            'interactionGeneration=${liveAnalysis.interactionGeneration} '
            'interactionFrameGeneration=${interaction?.generation ?? '-'} '
            'snapshotPresent=${snapshot != null} '
            'snapshotRevision=${snapshot?.coreRevision ?? '-'} '
            'snapshotTargetCount=${snapshot?.targetCountFor(_direction) ?? '-'} '
            'visibleRevision=${visible?.coreRevision ?? '-'} '
            'navigationEpoch=${visible?.navigationEpoch ?? '-'} '
            'presentationEpoch=${visible?.presentationEpoch ?? '-'} '
            'visibleModeEpoch=$_visibleModeEpoch '
            'activeDraftRetained=$retainsActiveDraft',
      ),
    );
  }

  DashboardBudgetEditContext? _editContextFor({
    required DashboardBudgetTarget target,
    required LedgerTimeScope visibleScope,
    required DashboardBudgetScopeAnalysis scopeAnalysis,
    required FinancialLimitKey? scalarKey,
    required int coreRevision,
  }) {
    if (visibleScope is YearScope &&
        scopeAnalysis is DashboardBudgetYearAnalysis) {
      return DashboardBudgetYearLimitEditContext(
        direction: _financialLimitDirection,
        target: _financialLimitTargetFor(target),
        coreRevision: coreRevision,
        targetHandle: target.handle,
        year: visibleScope.year,
        monthOverrideKeys: <FinancialLimitKey>[
          for (var month = 1; month <= 12; month += 1)
            _financialLimitKeyFor(
              target,
              period: BudgetLimitPeriod.month(visibleScope.year, month),
            )!,
        ],
        confirmedMonthlyLimitsScaled100: <int>[
          for (final limit in scopeAnalysis.monthlyResolvedLimitsScaled100)
            limit ?? 0,
        ],
        canonicalAnnualActualScaled100:
            scopeAnalysis.canonicalActualScaled100ForLimitEdit ?? 0,
      );
    }
    if (scalarKey == null) return null;
    return DashboardBudgetLimitEditContext(
      key: scalarKey,
      coreRevision: coreRevision,
      targetHandle: target.handle,
      actualScaled100: scopeAnalysis.canonicalActualScaled100ForLimitEdit,
      confirmedLimitScaled100: scopeAnalysis.canonicalLimitScaled100ForEdit,
    );
  }

  /// Resolves an optimistic edit without allowing a pending base mutation to
  /// overwrite an explicit month override. Provenance arrives with the dense
  /// prepared bank, so this is O(1) and never falls back to a repository read.
  int? _effectiveLimitForPreparedCell({
    required PreparedBudgetLimitSnapshot snapshot,
    required DashboardBudgetTarget target,
    required BudgetLimitPeriod period,
    required PreparedBudgetLimitCell cell,
  }) {
    final edits = _limitEditController;
    if (edits == null) return cell.limitScaled100;
    final directKey = _financialLimitKeyFor(target, period: period);
    if (directKey != null) {
      edits.observePreparedLimit(
        key: directKey,
        coreRevision: snapshot.coreRevision,
        confirmedLimitScaled100: cell.limitScaled100,
      );
      if (edits.hasOverlayFor(directKey)) {
        return edits.effectiveLimitFor(directKey, cell.limitScaled100);
      }
    }
    if (period is! BudgetLimitMonthPeriod ||
        cell.limitSource != PreparedBudgetLimitSource.base) {
      return cell.limitScaled100;
    }
    final baseKey = _baseMonthlyLimitKeyFor(target);
    final baseCell = snapshot.cellAt(
      direction: _direction,
      period: const BudgetLimitPeriod.sum(),
      targetHandle: target.handle,
    );
    edits.observePreparedLimit(
      key: baseKey,
      coreRevision: snapshot.coreRevision,
      confirmedLimitScaled100: baseCell.limitScaled100,
    );
    return edits.effectiveLimitFor(baseKey, cell.limitScaled100);
  }

  DashboardBudgetYearAnalysis _yearAnalysisFor({
    required PreparedBudgetLimitSnapshot snapshot,
    required DashboardBudgetTarget target,
    required int year,
    required int annualActualScaled100,
  }) {
    final limits = <int?>[];
    final actuals = <int>[];
    for (var month = 1; month <= 12; month += 1) {
      final period = BudgetLimitPeriod.month(year, month);
      final cell = snapshot.cellAt(
        direction: _direction,
        period: period,
        targetHandle: target.handle,
      );
      limits.add(
        _effectiveLimitForPreparedCell(
          snapshot: snapshot,
          target: target,
          period: period,
          cell: cell,
        ),
      );
      actuals.add(cell.actualScaled100);
    }
    final yearContext = DashboardBudgetYearLimitEditContext(
      direction: _financialLimitDirection,
      target: _financialLimitTargetFor(target),
      coreRevision: snapshot.coreRevision,
      targetHandle: target.handle,
      year: year,
      monthOverrideKeys: <FinancialLimitKey>[
        for (var month = 1; month <= 12; month += 1)
          _financialLimitKeyFor(
            target,
            period: BudgetLimitPeriod.month(year, month),
          )!,
      ],
      confirmedMonthlyLimitsScaled100: <int>[
        for (final limit in limits) limit ?? 0,
      ],
      canonicalAnnualActualScaled100: annualActualScaled100,
    );
    final edits = _limitEditController;
    if (edits != null) {
      edits.observePreparedYearLimits(
        yearContext,
        confirmedMonthlyLimitsScaled100:
            yearContext.confirmedMonthlyLimitsScaled100,
        coreRevision: snapshot.coreRevision,
      );
      if (edits.hasYearOverlayFor(yearContext)) {
        final effective = edits.effectiveYearLimitsFor(yearContext);
        for (var index = 0; index < 12; index += 1) {
          limits[index] = effective[index];
        }
      }
    }
    return DashboardBudgetYearAnalysis(
      annualActualScaled100: annualActualScaled100,
      annualResolvedLimitScaled100: limits.any((limit) => limit == null)
          ? null
          : limits.whereType<int>().fold<int>(0, (sum, limit) => sum + limit),
      monthlyActualsScaled100: List<int>.unmodifiable(actuals),
      monthlyResolvedLimitsScaled100: List<int?>.unmodifiable(limits),
    );
  }

  List<BudgetProgressRingAnnualSegment> _annualSegmentsFor(
    DashboardBudgetYearAnalysis analysis, {
    required int year,
  }) => List<BudgetProgressRingAnnualSegment>.unmodifiable([
    for (var index = 0; index < 12; index += 1)
      BudgetProgressRingAnnualSegment(
        health: _annualSegmentHealthFor(
          actualScaled100: analysis.monthlyActualsScaled100[index],
          resolvedMonthlyLimitScaled100:
              analysis.monthlyResolvedLimitsScaled100[index],
          isFuture:
              year > _logicalAsOfDate.year ||
              (year == _logicalAsOfDate.year &&
                  index + 1 > _logicalAsOfDate.month),
        ),
      ),
  ]);

  BudgetProgressRingAnnualSegmentHealth _annualSegmentHealthFor({
    required int actualScaled100,
    required int? resolvedMonthlyLimitScaled100,
    required bool isFuture,
  }) => BudgetProgressRingAnnualSegmentHealthResolver.resolve(
    actualScaled100: actualScaled100,
    resolvedMonthlyLimitScaled100: resolvedMonthlyLimitScaled100,
    isFuture: isFuture,
  );

  DashboardBudgetTypicalMonthAnalysis _typicalMonthAnalysisFor({
    required PreparedBudgetLimitSnapshot snapshot,
    required DashboardBudgetTarget target,
    required int? baseMonthlyLimitScaled100,
  }) {
    final cacheKey = _TypicalMonthAverageCacheKey(
      coreRevision: snapshot.coreRevision,
      direction: _direction,
      targetHandle: target.handle,
      yearWindowStart: snapshot.yearWindowStart,
      yearWindowEndInclusive: snapshot.yearWindowEndInclusive,
    );
    final average = _typicalAverageByPreparedTarget.putIfAbsent(
      cacheKey,
      () => _computeTypicalMonthAverage(snapshot: snapshot, target: target),
    );
    return DashboardBudgetTypicalMonthAnalysis(
      average: average,
      baseMonthlyLimitScaled100: baseMonthlyLimitScaled100,
    );
  }

  DashboardBudgetTypicalMonthAverage _computeTypicalMonthAverage({
    required PreparedBudgetLimitSnapshot snapshot,
    required DashboardBudgetTarget target,
  }) {
    final lastCompleted = _lastCompletedMonthInWindow(snapshot);
    if (lastCompleted == null) {
      return const DashboardBudgetTypicalMonthAverage.unavailable();
    }
    var firstHistoryMonthLinear = -1;
    var total = 0;
    var count = 0;
    for (
      var linear = snapshot.yearWindowStart * 12;
      linear <= lastCompleted;
      linear += 1
    ) {
      final year = linear ~/ 12;
      final month = linear % 12 + 1;
      if (year < snapshot.yearWindowStart) continue;
      final actual = snapshot
          .cellAt(
            direction: _direction,
            period: BudgetLimitPeriod.month(year, month),
            targetHandle: target.handle,
          )
          .actualScaled100;
      if (firstHistoryMonthLinear < 0 && actual > 0) {
        firstHistoryMonthLinear = linear;
      }
      if (firstHistoryMonthLinear >= 0) {
        total += actual;
        count += 1;
      }
    }
    return DashboardBudgetTypicalMonthAverage.resolve(
      completedMonthSpendScaled100: total,
      completedMonthCount: count,
    );
  }

  void _evictTypicalAverageCacheFor(PreparedBudgetLimitSnapshot? snapshot) {
    if (identical(_typicalAverageCacheSnapshot, snapshot)) return;
    _typicalAverageCacheSnapshot = snapshot;
    _typicalAverageByPreparedTarget.clear();
  }

  int? _lastCompletedMonthInWindow(PreparedBudgetLimitSnapshot snapshot) {
    final logicalLinear =
        _logicalAsOfDate.year * 12 + _logicalAsOfDate.month - 1;
    final latest = logicalLinear - 1;
    final windowStart = snapshot.yearWindowStart * 12;
    final windowEnd = snapshot.yearWindowEndInclusive * 12 + 11;
    return latest < windowStart ? null : latest.clamp(windowStart, windowEnd);
  }

  DashboardBudgetPartitionPresentation _partitionFor({
    required DashboardBudgetTargetCatalog catalog,
    required DashboardBudgetLiveAnalysisProjection liveAnalysis,
  }) {
    final snapshot = _snapshotForCurrentFrame();
    if (!liveAnalysis.isAvailable ||
        snapshot == null ||
        snapshot.coreRevision != liveAnalysis.coreRevision) {
      return DashboardBudgetPartitionPresentation.unavailable(
        direction: _direction,
      );
    }
    final period = DashboardBudgetPeriodResolver.fromTimeScope(
      liveAnalysis.scope!,
    );
    final bank = snapshot.directionBank(_direction);
    final aggregate = catalog.targetAtHandle(0);
    final aggregateKey = _financialLimitKeyFor(aggregate, period: period);
    late final int slice;
    late final PreparedBudgetLimitCell aggregateCell;
    try {
      slice = snapshot.sliceIndexFor(period);
      aggregateCell = bank.cellAt(periodSliceIndex: slice, targetHandle: 0);
    } on RangeError {
      return DashboardBudgetPartitionPresentation.unavailable(
        direction: _direction,
      );
    }
    final edits = _limitEditController;
    final effectiveAggregateLimitScaled100 = switch (period) {
      BudgetLimitYearPeriod(:final year) => _yearAnalysisFor(
        snapshot: snapshot,
        target: aggregate,
        year: year,
        annualActualScaled100: aggregateCell.actualScaled100,
      ).displayDenominatorScaled100,
      _ => _effectiveLimitForPreparedCell(
        snapshot: snapshot,
        target: aggregate,
        period: period,
        cell: aggregateCell,
      ),
    };
    final financialDirection = switch (_direction) {
      LedgerDirection.income => FinancialLimitDirection.income,
      LedgerDirection.expense => FinancialLimitDirection.expense,
    };
    if (aggregateKey != null) {
      edits?.observePreparedCategoryAllocationScope(
        direction: financialDirection,
        period: aggregateKey.period,
        coreRevision: snapshot.coreRevision,
        confirmedLimitForCategoryId: (categoryId) {
          final handle = catalog.handleForCategoryId(categoryId);
          return handle == null
              ? null
              : bank
                    .cellAt(periodSliceIndex: slice, targetHandle: handle)
                    .limitScaled100;
        },
      );
    }
    final categoryOverlay = aggregateKey == null
        ? DashboardBudgetCategoryAllocationOverlay.empty
        : edits?.categoryAllocationOverlayFor(
                direction: financialDirection,
                period: aggregateKey.period,
              ) ??
              DashboardBudgetCategoryAllocationOverlay.empty;
    final effectiveLimitByTargetHandle = <int, int>{};
    var inheritedOrYearAllocationDeltaScaled100 = 0;
    if (edits?.hasScalarOverlay == true && period is BudgetLimitMonthPeriod) {
      // A base edit changes every inherited month immediately. Walk only the
      // retained category handles while an overlay exists; normal time ticks
      // retain the O(1) prepared-bank path.
      for (var handle = 1; handle < bank.targetCount; handle += 1) {
        final cell = bank.cellAt(periodSliceIndex: slice, targetHandle: handle);
        if (cell.limitSource != PreparedBudgetLimitSource.base) continue;
        final target = catalog.targetAtHandle(handle);
        final baseKey = _baseMonthlyLimitKeyFor(target);
        if (!edits!.hasOverlayFor(baseKey)) continue;
        final effective = edits.effectiveLimitFor(baseKey, cell.limitScaled100);
        if (effective == null || effective == cell.limitScaled100) continue;
        effectiveLimitByTargetHandle[handle] = effective;
        inheritedOrYearAllocationDeltaScaled100 +=
            _positiveLimit(effective) - _positiveLimit(cell.limitScaled100);
      }
    }
    if (edits?.hasYearOverlay == true && period is BudgetLimitYearPeriod) {
      // A derived YEAR edit owns exactly twelve overrides. Resolve each
      // category's bounded vector here only while that one semantic mutation
      // is live, so the allocation lane cannot disagree with Header/ring.
      for (var handle = 1; handle < bank.targetCount; handle += 1) {
        final target = catalog.targetAtHandle(handle);
        final cell = bank.cellAt(periodSliceIndex: slice, targetHandle: handle);
        final effective = _yearAnalysisFor(
          snapshot: snapshot,
          target: target,
          year: period.year,
          annualActualScaled100: cell.actualScaled100,
        ).displayDenominatorScaled100;
        if (effective == null || effective == cell.limitScaled100) continue;
        effectiveLimitByTargetHandle[handle] = effective;
        inheritedOrYearAllocationDeltaScaled100 +=
            _positiveLimit(effective) - _positiveLimit(cell.limitScaled100);
      }
    }
    return DashboardBudgetPartitionPresentation._(
      direction: _direction,
      period: period,
      periodSliceIndex: slice,
      coreRevision: snapshot.coreRevision,
      bank: bank,
      catalog: catalog,
      // Partition allocation is a canonical financial rule. It must never
      // consume the DAY forecast display numerator.
      aggregateActualScaled100: aggregateCell.actualScaled100,
      effectiveAggregateLimitScaled100: effectiveAggregateLimitScaled100,
      preparedAllocatedTotalScaled100:
          bank.allocatedCategoryLimitTotalScaled100ByPeriodSlice[slice],
      optimisticAllocationDeltaScaled100:
          categoryOverlay.allocationDeltaScaled100 +
          inheritedOrYearAllocationDeltaScaled100,
      effectiveLimitByTargetHandle: Map<int, int>.unmodifiable(
        effectiveLimitByTargetHandle,
      ),
      categoryOverlay: categoryOverlay,
    );
  }

  static String _analysisScopeLabel(LedgerTimeScope scope) => switch (scope) {
    AllTimeScope() => 'Összesen',
    YearScope(:final year) => '$year',
    MonthScope(:final value) => DashboardTimeLabelFormatter.yearMonth(value),
    DayScope(:final date) => DashboardTimeLabelFormatter.date(
      YearMonth(year: date.year, month: date.month),
      date.day,
    ),
  };

  DashboardBudgetMonthEndProjection? _monthEndProjectionFor({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LedgerTimeScope scope,
    required int canonicalMonthlyActualScaled100,
    required int? effectiveMonthlyLimitScaled100,
  }) {
    if (scope is! DayScope) return null;
    final date = scope.date;
    final rhythm = snapshot.spendingRhythmSnapshot;
    final bank = rhythm == null || rhythm.coreRevision != snapshot.coreRevision
        ? null
        : rhythm.directionBank(direction);
    final monthToDate = bank == null || targetHandle >= bank.targetCount
        ? 0
        : bank
              .targetView(targetHandle)
              .actualForMonthThroughEpochDay(
                year: date.year,
                month: date.month,
                throughEpochDay: _logicalAsOfDate.epochDay,
              );
    return DashboardBudgetMonthEndProjection.derive(
      coreRevision: snapshot.coreRevision,
      direction: direction,
      targetHandle: targetHandle,
      year: date.year,
      month: date.month,
      logicalAsOfDate: _logicalAsOfDate,
      monthToDateActualScaled100: monthToDate,
      finalMonthActualScaled100: canonicalMonthlyActualScaled100,
      effectiveMonthlyLimitScaled100: effectiveMonthlyLimitScaled100,
    );
  }

  String _titleFor(DashboardBudgetTarget target) => target.isAggregate
      ? DashboardBudgetAggregateVisual.forDirection(_direction).title
      : target.category!.displayName;

  FinancialLimitKey? _financialLimitKeyFor(
    DashboardBudgetTarget target, {
    required BudgetLimitPeriod period,
  }) {
    final storedPeriod = switch (period) {
      BudgetLimitSumPeriod() => const FinancialLimitBaseMonthlyPeriod(),
      // A YEAR limit is a derived twelve-month vector, not one stored key.
      BudgetLimitYearPeriod() => null,
      BudgetLimitMonthPeriod(:final year, :final month) =>
        FinancialLimitMonthOverridePeriod(year, month),
    };
    if (storedPeriod == null) return null;
    return FinancialLimitKey(
      direction: _financialLimitDirection,
      target: _financialLimitTargetFor(target),
      period: storedPeriod,
    );
  }

  FinancialLimitKey _baseMonthlyLimitKeyFor(DashboardBudgetTarget target) =>
      FinancialLimitKey(
        direction: _financialLimitDirection,
        target: _financialLimitTargetFor(target),
        period: const FinancialLimitBaseMonthlyPeriod(),
      );

  FinancialLimitDirection get _financialLimitDirection => switch (_direction) {
    LedgerDirection.income => FinancialLimitDirection.income,
    LedgerDirection.expense => FinancialLimitDirection.expense,
  };

  static int _positiveLimit(int? value) =>
      value != null && value > 0 ? value : 0;

  FinancialLimitTarget _financialLimitTargetFor(DashboardBudgetTarget target) =>
      target.isAggregate
      ? const FinancialLimitAggregateTarget()
      : FinancialLimitCategoryTarget(target.category!.id);

  void _recordLiveAnalysisBinding(
    DashboardBudgetLiveAnalysisProjection liveAnalysis,
  ) {
    final signature = Object.hash(
      liveAnalysis.interactionGeneration,
      liveAnalysis.coreRevision,
      liveAnalysis.direction,
      liveAnalysis.scope?.canonicalKey,
      liveAnalysis.targetHandle,
      liveAnalysis.isLiveInteraction,
    );
    if (_lastLiveAnalysisDiagnosticSignature == signature) return;
    _lastLiveAnalysisDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_LIVE_ANALYSIS_BOUND',
        coreRevision: liveAnalysis.coreRevision,
        direction: liveAnalysis.direction.name,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'scope=${liveAnalysis.scope?.canonicalKey ?? '-'} '
            'targetHandle=${liveAnalysis.targetHandle} '
            'source=${liveAnalysis.isLiveInteraction ? 'liveInteraction' : 'visibleFrame'}',
      ),
    );
  }

  void _recordHeaderBinding(
    DashboardBudgetLiveSelectionState header,
    DashboardBudgetLiveAnalysisProjection liveAnalysis,
  ) {
    final signature = Object.hash(
      liveAnalysis.interactionGeneration,
      liveAnalysis.coreRevision,
      _direction,
      liveAnalysis.scope,
      header.target.handle,
      header.title,
      header.analysisScopeLabel,
      header.displayNumeratorScaled100,
      header.displayDenominatorScaled100,
      header.limitScaled100,
    );
    if (_lastHeaderDiagnosticSignature == signature) return;
    final previous = _lastLimitStateDiagnosticSummary;
    _lastHeaderDiagnosticSignature = signature;
    final next =
        'available=${header.isAvailable};target=${header.target.handle};'
        'numerator=${header.displayNumeratorScaled100 ?? '-'};'
        'denominator=${header.displayDenominatorScaled100 ?? '-'};'
        'limit=${header.limitScaled100 ?? '-'}';
    _lastLimitStateDiagnosticSummary = next;
    final snapshot = _snapshotForCurrentFrame();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'LIMIT|STATE',
        coreRevision: liveAnalysis.coreRevision,
        direction: _direction.name,
        scope:
            'previous=${previous ?? 'none'} next=$next '
            'reason=${header.isAvailable ? 'bound' : 'unavailable'} '
            'interactionGeneration=${liveAnalysis.interactionGeneration} '
            'liveAnalysisAvailable=${liveAnalysis.isAvailable} '
            'analysisScope=${liveAnalysis.scope?.canonicalKey ?? '-'} '
            'snapshotPresent=${snapshot != null} '
            'snapshotRevision=${snapshot?.coreRevision ?? '-'} '
            'selectedHandle=${value.selectedHandle} '
            'visibleModeEpoch=$_visibleModeEpoch',
      ),
    );
    if (!header.isAvailable) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PREPARED_VALUE_MISSING',
          coreRevision: liveAnalysis.coreRevision,
          direction: _direction.name,
          scope:
              'generation=${liveAnalysis.interactionGeneration} '
              'targetHandle=${header.target.handle}',
        ),
      );
      return;
    }
    final scope = liveAnalysis.scope;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_HEADER_VALUE_BOUND',
        coreRevision: liveAnalysis.coreRevision,
        direction: _direction.name,
        totalMinor: header.displayNumeratorScaled100,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'plane=${_planeDiagnosticName(scope)} '
            'targetHandle=${header.target.handle} '
            'displayNumeratorScaled100=${header.displayNumeratorScaled100} '
            'displayDenominatorScaled100=${header.displayDenominatorScaled100 ?? '-'} '
            'hasLimit=${header.hasLimit} '
            'canonicalLimitScaled100=${header.limitScaled100 ?? '-'}',
      ),
    );
  }

  void _recordDirectionDomain(
    DashboardBudgetTargetCatalog catalog,
    PreparedBudgetLimitSnapshot? snapshot,
  ) {
    final signature = Object.hash(
      _direction,
      snapshot?.coreRevision,
      catalog.targetCount,
    );
    if (_lastDirectionDomainDiagnosticSignature == signature) return;
    _lastDirectionDomainDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DIRECTION_DOMAIN_READY',
        coreRevision: snapshot?.coreRevision,
        direction: _direction.name,
        scope:
            'categoryCount=${catalog.targetCount - 1} '
            'targetCount=${catalog.targetCount}',
      ),
    );
  }

  void _recordMonthEndProjection(
    DashboardBudgetLiveSelectionState selection,
    DashboardBudgetLiveAnalysisProjection liveAnalysis,
  ) {
    final projection = selection.monthEndProjection;
    if (projection == null) return;
    final scope = liveAnalysis.scope;
    final selectedDay = scope is DayScope ? scope.date : null;
    final signature = Object.hash(
      projection.key,
      projection.monthToDateActualScaled100,
      projection.actualDailyAverageScaled100,
      projection.allowedDailyAverageScaled100,
      projection.paceRatio,
      projection.projectedMonthEndScaled100,
      projection.effectiveMonthlyLimitScaled100,
    );
    if (_lastMonthEndProjectionDiagnosticSignature == signature) return;
    _lastMonthEndProjectionDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DAILY_PACE_BOUND',
        coreRevision: projection.key.coreRevision,
        direction: projection.key.direction.name,
        totalMinor: projection.actualDailyAverageScaled100,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'targetHandle=${projection.key.targetHandle} '
            'year=${projection.key.year} month=${projection.key.month} '
            'projectionEpoch=${projection.key.coreRevision}:'
            '${projection.key.direction.name}:${projection.key.targetHandle}:'
            '${projection.key.year}-${projection.key.month}:'
            '${projection.key.logicalAsOfDate}:'
            '${projection.key.effectiveMonthlyLimitScaled100 ?? '-'} '
            'logicalAsOfDate=${projection.key.logicalAsOfDate} '
            'monthToDateScaled100=${projection.monthToDateActualScaled100} '
            'elapsedCalendarDays=${projection.elapsedCalendarDays} '
            'daysInMonth=${projection.daysInMonth} '
            'actualDailyAverageScaled100=${projection.actualDailyAverageScaled100 ?? '-'} '
            'allowedDailyAverageScaled100=${projection.allowedDailyAverageScaled100 ?? '-'} '
            'paceRatio=${projection.paceRatio} '
            'projectedMonthEndScaled100=${projection.projectedMonthEndScaled100} '
            'effectiveMonthlyLimitScaled100=${projection.effectiveMonthlyLimitScaled100 ?? '-'} '
            'projectionRatio=${projection.projectionRatio} '
            'gaugeFillRatio=${projection.gaugeFillRatio} '
            'healthBand=${projection.healthBand.name} '
            'selectedDay=${selectedDay ?? '-'}',
      ),
    );
  }

  void _recordProgressBinding(
    DashboardBudgetLiveSelectionState selection,
    DashboardBudgetLiveAnalysisProjection liveAnalysis,
  ) {
    final visual = selection.visual;
    final signature = Object.hash(
      liveAnalysis.interactionGeneration,
      visual.targetHandle,
      visual.limitKey,
      visual.displayNumeratorScaled100,
      visual.displayDenominatorScaled100,
      visual.rawProgress,
      visual.visualProgress,
      selection.direction,
    );
    if (_lastProgressDiagnosticSignature == signature) return;
    _lastProgressDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_BOUND',
        totalMinor: visual.displayNumeratorScaled100,
        direction: selection.direction.name,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'targetHandle=${visual.targetHandle} '
            'targetIdentity=${visual.limitKey?.target.runtimeType ?? '-'} '
            'displayNumeratorScaled100=${visual.displayNumeratorScaled100 ?? '-'} '
            'hasPositiveLimit=${visual.hasPositiveLimit} '
            'displayDenominatorScaled100=${visual.displayDenominatorScaled100 ?? '-'} '
            'rawProgress=${visual.rawProgress} '
            'visualProgress=${visual.visualProgress}',
      ),
    );
    if (visual.rawProgress < 1 && visual.visualProgress >= 1) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PROGRESS_IDENTITY_MISMATCH',
          scope:
              'targetHandle=${visual.targetHandle} '
              'rawProgress=${visual.rawProgress} '
              'visualProgress=${visual.visualProgress}',
        ),
      );
    }
  }

  void _recordPartitionBinding(
    DashboardBudgetPartitionPresentation partition, {
    required int selectedHandle,
    required DashboardBudgetLiveAnalysisProjection liveAnalysis,
  }) {
    final signature = Object.hash(
      liveAnalysis.interactionGeneration,
      partition.direction,
      partition.period,
      partition.periodSliceIndex,
      partition.coreRevision,
      partition.aggregateActualScaled100,
      partition.effectiveAggregateLimitScaled100,
      partition.preparedAllocatedTotalScaled100,
      partition.optimisticAllocationDeltaScaled100,
      partition.liveAllocatedTotalScaled100,
      selectedHandle,
      Object.hashAll(
        partition.effectiveLimitByTargetHandle.entries.map(
          (entry) => Object.hash(entry.key, entry.value),
        ),
      ),
      partition.categoryOverlay,
    );
    if (_lastPartitionDiagnosticSignature == signature) return;
    _lastPartitionDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PARTITION_BOUND',
        coreRevision: partition.coreRevision,
        direction: partition.direction.name,
        totalMinor: partition.aggregateActualScaled100,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'period=${_budgetPeriodDiagnosticName(partition.period)} '
            'slice=${partition.periodSliceIndex ?? '-'} '
            'aggregateBudgetLimitScaled100=${partition.effectiveAggregateLimitScaled100 ?? '-'} '
            'aggregateActualScaled100=${partition.aggregateActualScaled100 ?? '-'} '
            'preparedAllocatedTotalScaled100=${partition.preparedAllocatedTotalScaled100} '
            'optimisticAllocationDeltaScaled100=${partition.optimisticAllocationDeltaScaled100} '
            'liveAllocatedTotalScaled100=${partition.liveAllocatedTotalScaled100} '
            'allocationRawRatio=${partition.allocationRawRatio} '
            'allocationVisualCoverage=${partition.allocationVisualCoverage} '
            'selectedTargetHandle=$selectedHandle '
            'segmentCount=${partition.bank?.targetCount == null ? 0 : partition.bank!.targetCount - 1} '
            'source=prepared+optimistic',
      ),
    );
  }

  static String _budgetPeriodDiagnosticName(BudgetLimitPeriod? period) =>
      switch (period) {
        BudgetLimitSumPeriod() => 'sum',
        BudgetLimitYearPeriod(:final year) => 'year:$year',
        BudgetLimitMonthPeriod(:final year, :final month) =>
          'month:$year-$month',
        null => 'unavailable',
      };

  String _planeDiagnosticName(LedgerTimeScope? scope) => switch (scope) {
    AllTimeScope() => 'sum',
    YearScope() => 'year',
    MonthScope() => 'month',
    DayScope() => 'day',
    null => 'unavailable',
  };

  LedgerDirection get _direction => switch (_transactionDirection.direction) {
    TransactionDirection.income => LedgerDirection.income,
    TransactionDirection.expense => LedgerDirection.expense,
  };

  @override
  void dispose() {
    _categoryCollection.removeListener(_refreshCatalogForCategoryInput);
    _visibleFrame.removeListener(_refreshForVisibleFrame);
    _liveInteractions?.removeListener(_refreshForLiveInteraction);
    _transactionDirection.removeListener(_refreshCatalogForDirection);
    _limitEditController?.removeListener(_refreshForOptimisticLimitEdit);
    super.dispose();
  }
}
