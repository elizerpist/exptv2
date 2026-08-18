import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../core/financial_limits/domain/financial_limit.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_target.dart';
import 'dashboard_budget_limit_edit_controller.dart';
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

@immutable
final class DashboardBudgetHeaderPresentation {
  const DashboardBudgetHeaderPresentation._({
    required this.target,
    required this.title,
    required this.actualScaled100,
    required this.limitScaled100,
    required this.limitKey,
    required this.coreRevision,
  });

  const DashboardBudgetHeaderPresentation.unavailable({
    required DashboardBudgetTarget target,
    required String title,
  }) : this._(
         target: target,
         title: title,
         actualScaled100: null,
         limitScaled100: null,
         limitKey: null,
         coreRevision: null,
       );

  const DashboardBudgetHeaderPresentation.available({
    required DashboardBudgetTarget target,
    required String title,
    required int actualScaled100,
    required int? limitScaled100,
    required FinancialLimitKey limitKey,
    required int coreRevision,
  }) : this._(
         target: target,
         title: title,
         actualScaled100: actualScaled100,
         limitScaled100: limitScaled100,
         limitKey: limitKey,
         coreRevision: coreRevision,
       );

  final DashboardBudgetTarget target;
  final String title;
  final int? actualScaled100;
  final int? limitScaled100;
  final FinancialLimitKey? limitKey;
  final int? coreRevision;

  bool get isAvailable => actualScaled100 != null;
  bool get hasLimit => limitScaled100 != null;

  DashboardBudgetLimitEditContext? get limitEditContext =>
      !isAvailable || limitKey == null || coreRevision == null
      ? null
      : DashboardBudgetLimitEditContext(
          key: limitKey!,
          coreRevision: coreRevision!,
          targetHandle: target.handle,
          actualScaled100: actualScaled100!,
          confirmedLimitScaled100: limitScaled100,
        );
}

@immutable
final class DashboardBudgetPresentationState {
  const DashboardBudgetPresentationState({
    required this.items,
    required this.selectedHandle,
    required this.header,
    required this.selectedLimitVisual,
  });

  final List<DashboardBudgetTargetPresentationItem> items;
  final int selectedHandle;
  final DashboardBudgetHeaderPresentation header;
  final BudgetCategoryAvatarSelectedLimitVisualState selectedLimitVisual;
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
    required TransactionDirectionController transactionDirection,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
    DashboardBudgetLimitEditController? limitEditController,
    ValueChanged<int>? onInputUpdated,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _transactionDirection = transactionDirection,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _limitEditController = limitEditController,
       _onInputUpdated = onInputUpdated,
       super(_initialState()) {
    _categoryCollection.addListener(_refreshCatalogForCategoryInput);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _transactionDirection.addListener(_refreshCatalogForDirection);
    _limitEditController?.addListener(_refreshForOptimisticLimitEdit);
    _refreshCatalog(notifyCategoryInput: true);
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final TransactionDirectionController _transactionDirection;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final DashboardBudgetLimitEditController? _limitEditController;
  final ValueChanged<int>? _onInputUpdated;

  static DashboardBudgetPresentationState _initialState() {
    const aggregate = DashboardBudgetTarget.aggregate();
    return DashboardBudgetPresentationState(
      items: const <DashboardBudgetTargetPresentationItem>[],
      selectedHandle: 0,
      header: const DashboardBudgetHeaderPresentation.unavailable(
        target: aggregate,
        title: 'Budget',
      ),
      selectedLimitVisual:
          BudgetCategoryAvatarSelectedLimitVisualState.unavailable(
            targetHandle: aggregate.handle,
          ),
    );
  }

  DashboardBudgetTargetCatalog? _catalog;
  PreparedBudgetLimitSnapshot? _snapshotUsedForCatalog;
  List<FluviCategory>? _lastReportedCategoryInput;
  int? _lastHeaderDiagnosticSignature;
  int? _lastProgressDiagnosticSignature;

  /// Called by the shared carousel only on semantic selection changes, never
  /// for a pixel or animation tick.
  void setTargetHandle(int handle) {
    final catalog = _catalog;
    if (catalog == null || handle < 0 || handle >= catalog.targetCount) return;
    if (handle == value.selectedHandle) return;
    final target = catalog.targetAtHandle(handle);
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

  void _refreshForOptimisticLimitEdit() {
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  void _refreshCatalog({bool notifyCategoryInput = false}) {
    final catalog = _buildCompatibleCatalog();
    final prior = _catalog;
    final priorIdentity =
        prior == null || value.selectedHandle >= prior.targetCount
        ? null
        : prior.targetAtHandle(value.selectedHandle).identity;
    final selectedHandle = _handleForIdentity(catalog, priorIdentity) ?? 0;
    _catalog = catalog;
    _snapshotUsedForCatalog = _snapshotForCurrentFrame();
    _publishCatalog(catalog: catalog, selectedHandle: selectedHandle);
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
    final ordered =
        snapshot?.orderedCategoryIds ??
        List<String>.unmodifiable(categories.map((category) => category.id));
    // A category collection from another core revision must never pair with
    // dense vectors from this one. Keep the aggregate only until an exact
    // compatible publication arrives.
    if (snapshot != null &&
        ordered.any((id) => !categoryById.containsKey(id))) {
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
    final header = _headerFor(selectedTarget);
    final selectedLimitVisual = _selectedLimitVisualFor(header);
    value = DashboardBudgetPresentationState(
      items: items,
      selectedHandle: selectedHandle,
      header: header,
      selectedLimitVisual: selectedLimitVisual,
    );
    _recordHeaderBinding(header);
    _recordProgressBinding(selectedLimitVisual);
  }

  /// The hot semantic tick path: retained catalog + selected dense RAM cell.
  /// It intentionally performs no category projection, item-list build, sort,
  /// search, repository read or native bridge call.
  void _publishHeaderOnly({
    required DashboardBudgetTargetCatalog catalog,
    required int selectedHandle,
  }) {
    final selectedTarget = catalog.targetAtHandle(selectedHandle);
    final header = _headerFor(selectedTarget);
    final selectedLimitVisual = _selectedLimitVisualFor(header);
    value = DashboardBudgetPresentationState(
      items: value.items,
      selectedHandle: selectedHandle,
      header: header,
      selectedLimitVisual: selectedLimitVisual,
    );
    _recordHeaderBinding(header);
    _recordProgressBinding(selectedLimitVisual);
  }

  BudgetCategoryAvatarSelectedLimitVisualState _selectedLimitVisualFor(
    DashboardBudgetHeaderPresentation header,
  ) {
    if (!header.isAvailable || header.limitKey == null) {
      return BudgetCategoryAvatarSelectedLimitVisualState.unavailable(
        targetHandle: header.target.handle,
      );
    }
    return BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: header.target.handle,
      limitKey: header.limitKey!,
      actualScaled100: header.actualScaled100!,
      effectiveLimitScaled100: header.limitScaled100,
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

  DashboardBudgetHeaderPresentation _headerFor(DashboardBudgetTarget target) {
    final frame = _visibleFrame.value;
    final snapshot = _snapshotForCurrentFrame();
    final title = _titleFor(target);
    if (frame == null ||
        snapshot == null ||
        snapshot.coreRevision != frame.coreRevision ||
        target.handle >= snapshot.targetCount) {
      _limitEditController?.invalidateIfContextChanged(null);
      return DashboardBudgetHeaderPresentation.unavailable(
        target: target,
        title: title,
      );
    }
    final key = _financialLimitKeyFor(
      target,
      period: _periodFor(frame.scope.timeScope),
    );
    _limitEditController?.invalidateIfContextChanged(key);
    late final PreparedBudgetLimitCell cell;
    try {
      cell = snapshot.cellAt(
        direction: _direction,
        period: _periodFor(frame.scope.timeScope),
        targetHandle: target.handle,
      );
    } on RangeError {
      // A prepared period outside the exact RAM window is unavailable, never a
      // reason to repair the snapshot through an interaction-time read.
      return DashboardBudgetHeaderPresentation.unavailable(
        target: target,
        title: title,
      );
    }
    _limitEditController?.observePreparedLimit(
      key: key,
      coreRevision: snapshot.coreRevision,
      confirmedLimitScaled100: cell.limitScaled100,
    );
    return DashboardBudgetHeaderPresentation.available(
      target: target,
      title: title,
      actualScaled100: cell.actualScaled100,
      limitScaled100:
          _limitEditController?.effectiveLimitFor(key, cell.limitScaled100) ??
          cell.limitScaled100,
      limitKey: key,
      coreRevision: snapshot.coreRevision,
    );
  }

  String _titleFor(DashboardBudgetTarget target) => target.isAggregate
      ? DashboardBudgetAggregateVisual.forDirection(_direction).title
      : target.category!.displayName;

  FinancialLimitKey _financialLimitKeyFor(
    DashboardBudgetTarget target, {
    required BudgetLimitPeriod period,
  }) => FinancialLimitKey(
    direction: switch (_direction) {
      LedgerDirection.income => FinancialLimitDirection.income,
      LedgerDirection.expense => FinancialLimitDirection.expense,
    },
    target: target.isAggregate
        ? const FinancialLimitAggregateTarget()
        : FinancialLimitCategoryTarget(target.category!.id),
    period: switch (period) {
      BudgetLimitSumPeriod() => const FinancialLimitSumPeriod(),
      BudgetLimitYearPeriod(:final year) => FinancialLimitYearPeriod(year),
      BudgetLimitMonthPeriod(:final year, :final month) =>
        FinancialLimitMonthPeriod(year, month),
    },
  );

  void _recordHeaderBinding(DashboardBudgetHeaderPresentation header) {
    final frame = _visibleFrame.value;
    final signature = Object.hash(
      frame?.coreRevision,
      _direction,
      frame?.scope.timeScope,
      header.target.handle,
      header.title,
      header.actualScaled100,
      header.limitScaled100,
    );
    if (_lastHeaderDiagnosticSignature == signature) return;
    _lastHeaderDiagnosticSignature = signature;
    if (!header.isAvailable) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PREPARED_VALUE_MISSING',
          coreRevision: frame?.coreRevision,
          direction: _direction.name,
          scope: 'targetHandle=${header.target.handle}',
        ),
      );
      return;
    }
    final scope = frame?.scope.timeScope;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_HEADER_VALUE_BOUND',
        coreRevision: frame?.coreRevision,
        direction: _direction.name,
        totalMinor: header.actualScaled100,
        scope:
            'plane=${_planeDiagnosticName(scope)} '
            'targetHandle=${header.target.handle} '
            'actualScaled100=${header.actualScaled100} '
            'hasLimit=${header.hasLimit} '
            'limitScaled100=${header.limitScaled100 ?? '-'}',
      ),
    );
  }

  void _recordProgressBinding(
    BudgetCategoryAvatarSelectedLimitVisualState visual,
  ) {
    final signature = Object.hash(
      visual.targetHandle,
      visual.limitKey,
      visual.actualScaled100,
      visual.effectiveLimitScaled100,
      visual.rawProgress,
      visual.sourceProgress,
    );
    if (_lastProgressDiagnosticSignature == signature) return;
    _lastProgressDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_BOUND',
        totalMinor: visual.actualScaled100,
        scope:
            'targetHandle=${visual.targetHandle} '
            'targetIdentity=${visual.limitKey?.target.runtimeType ?? '-'} '
            'hasPositiveLimit=${visual.hasPositiveLimit} '
            'effectiveLimitScaled100=${visual.effectiveLimitScaled100 ?? '-'} '
            'rawProgress=${visual.rawProgress} '
            'sourceProgress=${visual.sourceProgress}',
      ),
    );
    if (visual.rawProgress < 1 && visual.sourceProgress >= 1) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PROGRESS_IDENTITY_MISMATCH',
          scope:
              'targetHandle=${visual.targetHandle} '
              'rawProgress=${visual.rawProgress} '
              'sourceProgress=${visual.sourceProgress}',
        ),
      );
    }
  }

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

  BudgetLimitPeriod _periodFor(LedgerTimeScope scope) => switch (scope) {
    AllTimeScope() => const BudgetLimitPeriod.sum(),
    YearScope(:final year) => BudgetLimitPeriod.year(year),
    MonthScope(:final value) => BudgetLimitPeriod.month(
      value.year,
      value.month,
    ),
    DayScope(:final date) => BudgetLimitPeriod.month(date.year, date.month),
  };

  @override
  void dispose() {
    _categoryCollection.removeListener(_refreshCatalogForCategoryInput);
    _visibleFrame.removeListener(_refreshForVisibleFrame);
    _transactionDirection.removeListener(_refreshCatalogForDirection);
    _limitEditController?.removeListener(_refreshForOptimisticLimitEdit);
    super.dispose();
  }
}
