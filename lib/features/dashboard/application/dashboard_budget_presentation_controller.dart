import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_target.dart';
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
    required this.actualScaled100,
    required this.limitScaled100,
  });

  const DashboardBudgetHeaderPresentation.unavailable({
    required DashboardBudgetTarget target,
  }) : this._(target: target, actualScaled100: null, limitScaled100: null);

  const DashboardBudgetHeaderPresentation.available({
    required DashboardBudgetTarget target,
    required int actualScaled100,
    required int? limitScaled100,
  }) : this._(
         target: target,
         actualScaled100: actualScaled100,
         limitScaled100: limitScaled100,
       );

  final DashboardBudgetTarget target;
  final int? actualScaled100;
  final int? limitScaled100;

  bool get isAvailable => actualScaled100 != null;
  bool get hasLimit => limitScaled100 != null;
}

@immutable
final class DashboardBudgetPresentationState {
  const DashboardBudgetPresentationState({
    required this.items,
    required this.selectedHandle,
    required this.header,
  });

  final List<DashboardBudgetTargetPresentationItem> items;
  final int selectedHandle;
  final DashboardBudgetHeaderPresentation header;
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
    ValueChanged<int>? onInputUpdated,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _transactionDirection = transactionDirection,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _onInputUpdated = onInputUpdated,
       super(_initialState()) {
    _categoryCollection.addListener(_refreshCatalogForCategoryInput);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _transactionDirection.addListener(_refreshCatalogForDirection);
    _refreshCatalog(notifyCategoryInput: true);
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final TransactionDirectionController _transactionDirection;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final ValueChanged<int>? _onInputUpdated;

  static DashboardBudgetPresentationState _initialState() {
    const aggregate = DashboardBudgetTarget.aggregate();
    return DashboardBudgetPresentationState(
      items: const <DashboardBudgetTargetPresentationItem>[],
      selectedHandle: 0,
      header: const DashboardBudgetHeaderPresentation.unavailable(
        target: aggregate,
      ),
    );
  }

  DashboardBudgetTargetCatalog? _catalog;
  PreparedBudgetLimitSnapshot? _snapshotUsedForCatalog;
  List<FluviCategory>? _lastReportedCategoryInput;
  int? _lastHeaderDiagnosticSignature;

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
    value = DashboardBudgetPresentationState(
      items: items,
      selectedHandle: selectedHandle,
      header: header,
    );
    _recordHeaderBinding(header);
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
    value = DashboardBudgetPresentationState(
      items: value.items,
      selectedHandle: selectedHandle,
      header: header,
    );
    _recordHeaderBinding(header);
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
    if (frame == null ||
        snapshot == null ||
        snapshot.coreRevision != frame.coreRevision ||
        target.handle >= snapshot.targetCount) {
      return DashboardBudgetHeaderPresentation.unavailable(target: target);
    }
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
      return DashboardBudgetHeaderPresentation.unavailable(target: target);
    }
    return DashboardBudgetHeaderPresentation.available(
      target: target,
      actualScaled100: cell.actualScaled100,
      limitScaled100: cell.limitScaled100,
    );
  }

  void _recordHeaderBinding(DashboardBudgetHeaderPresentation header) {
    final frame = _visibleFrame.value;
    final signature = Object.hash(
      frame?.coreRevision,
      _direction,
      frame?.scope.timeScope,
      header.target.handle,
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
    super.dispose();
  }
}
