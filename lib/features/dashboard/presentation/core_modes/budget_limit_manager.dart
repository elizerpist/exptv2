import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/financial_limits/domain/financial_limit.dart';
import '../../../../core/financial_limits/domain/financial_limit_resolution.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../../dashboard/application/dashboard_budget_limit_edit_controller.dart';
import '../../../dashboard/application/dashboard_budget_presentation_controller.dart';
import '../../../dashboard/application/dashboard_budget_secondary_analysis.dart';
import '../../../dashboard/application/dashboard_budget_target.dart';
import '../../query/domain/ledger_direction.dart';
import '../../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';
import 'budget_allocation_partition_lane.dart';
import 'budget_allocation_partition_slider.dart';
import 'budget_target_avatar_carousel.dart';

/// Frozen intent emitted by the selected avatar.  The rail only emits this
/// presentation request; this fullscreen editor remains owned by the Budget
/// surface and never becomes a carousel/page route.
@immutable
final class BudgetLimitManagerRequest {
  const BudgetLimitManagerRequest({
    required this.direction,
    required this.target,
    required this.targetHandle,
    required this.title,
    required this.accent,
    required this.avatar,
    required this.coreRevision,
  });

  final LedgerDirection direction;
  final DashboardBudgetTarget target;
  final int targetHandle;
  final String title;
  final Color accent;

  /// Prepared by the avatar rail from the same visual authority as the
  /// selected target.  The manager never invents a second icon system.
  final Widget avatar;
  final int coreRevision;
}

/// Fullscreen, manual Budget-limit editor.  It intentionally consumes the
/// dashboard's immutable prepared bank for visuals; the one direction-wide
/// timeline read on open is indexed locally so target browsing never reads
/// persistence while still distinguishing historical revisions from overrides.
final class BudgetLimitManager extends StatefulWidget {
  const BudgetLimitManager({
    required this.request,
    required this.presentation,
    required this.limitEdits,
    super.key,
  });

  final BudgetLimitManagerRequest request;
  final DashboardBudgetPresentationController presentation;
  final DashboardBudgetLimitEditController limitEdits;

  @override
  State<BudgetLimitManager> createState() => _BudgetLimitManagerState();
}

/// A manager-local information architecture choice.  It has no persistence
/// meaning and always starts in the target/category view on a fresh open.
enum BudgetLimitManagerPerspective { category, allocation }

final class _BudgetLimitManagerState extends State<BudgetLimitManager> {
  late int _year;
  late final CenteredCarouselController _avatarCarouselController;
  List<BudgetTargetAvatarCarouselItem> _avatarItems =
      const <BudgetTargetAvatarCarouselItem>[];
  Map<int, List<FinancialLimit>> _timelineByTargetHandle =
      const <int, List<FinancialLimit>>{};
  late int _activeTargetHandle;
  bool _carouselInMotion = false;
  bool _monthSheetOpen = false;
  bool _loadingTimeline = true;
  var _perspective = BudgetLimitManagerPerspective.category;
  int? _allocationActiveCategoryHandle;

  FinancialLimitDirection get _direction => switch (widget.request.direction) {
    LedgerDirection.income => FinancialLimitDirection.income,
    LedgerDirection.expense => FinancialLimitDirection.expense,
  };

  DashboardBudgetTarget get _activeTarget =>
      widget.presentation.targetForManagerHandle(_activeTargetHandle) ??
      widget.request.target;

  FinancialLimitTarget get _target => _financialTargetFor(_activeTarget);

  String get _title => _activeAvatar?.title ?? widget.request.title;
  Color get _accent => _activeAvatar?.color ?? widget.request.accent;
  BudgetTargetAvatarCarouselItem? get _activeAvatar {
    for (final item in _avatarItems) {
      if (item.targetHandle == _activeTargetHandle) return item;
    }
    return null;
  }

  List<FinancialLimit> get _timeline =>
      _timelineByTargetHandle[_activeTargetHandle] ?? const <FinancialLimit>[];

  LocalDate get _logicalDate => widget.presentation.logicalAsOfDateForManager;

  @override
  void initState() {
    super.initState();
    _year = _logicalDate.year;
    _activeTargetHandle = widget.request.targetHandle;
    _avatarCarouselController = CenteredCarouselController(initialIndex: 0);
    widget.presentation.addListener(_onPresentationChanged);
    _loadTimeline();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshAvatarItems();
  }

  void _onPresentationChanged() {
    if (!mounted) return;
    _refreshAvatarItems();
  }

  void _refreshAvatarItems() {
    final atlas = PreparedVectorAssetAtlas.instance;
    if (!atlas.isReady) return;
    final profile = CategoryAvatarColorProfileScope.profileOf(context);
    final next = BudgetTargetAvatarCarouselItem.prepareAll(
      widget.presentation.value.items,
      atlas,
      avatarColorProfile: profile,
    );
    if (_sameAvatarItems(_avatarItems, next)) return;
    _avatarItems = next;
    final index = next.indexWhere(
      (item) => item.targetHandle == _activeTargetHandle,
    );
    _avatarCarouselController.installSemanticDomain(
      dataMode: CenteredCarouselDataMode.cyclic,
      finiteLength: next.length,
      selectedLogicalIndex: index < 0 ? 0 : index,
    );
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onPresentationChanged);
    _avatarCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    final values = await widget.limitEdits.loadLimitTimelinesForDirection(
      direction: _direction,
    );
    if (!mounted) return;
    setState(() {
      _timelineByTargetHandle = _indexTimelineByTarget(values);
      _loadingTimeline = false;
    });
  }

  Map<int, List<FinancialLimit>> _indexTimelineByTarget(
    List<FinancialLimit> values,
  ) => Map<int, List<FinancialLimit>>.unmodifiable({
    for (final item in widget.presentation.value.items)
      item.target.handle: List<FinancialLimit>.unmodifiable(
        values.where(
          (limit) => limit.key.target == _financialTargetFor(item.target),
        ),
      ),
  });

  int? _resolvedLimit(int year, int month) {
    return FinancialLimitResolution.resolve(
      limits: _timeline,
      direction: _direction,
      target: _target,
      year: year,
      month: month,
    )?.amountScaled100;
  }

  FinancialLimit? _baseFor(int year, int month) {
    return FinancialLimitResolution.baseRevisionAtOrBefore(
      limits: _timeline,
      direction: _direction,
      target: _target,
      year: year,
      month: month,
    );
  }

  FinancialLimit? _overrideFor(int year, int month) {
    return FinancialLimitResolution.exactMonthOverride(
      limits: _timeline,
      direction: _direction,
      target: _target,
      year: year,
      month: month,
    );
  }

  int? get _currentBase =>
      _resolvedLimit(_logicalDate.year, _logicalDate.month);

  DashboardBudgetTarget? _targetForHandle(int handle) =>
      widget.presentation.targetForManagerHandle(handle);

  int? _aggregateHandle() {
    for (final item in widget.presentation.value.items) {
      if (item.target.isAggregate) return item.target.handle;
    }
    return null;
  }

  int? _allocationCategoryHandle() {
    final existing = _allocationActiveCategoryHandle;
    if (existing != null && _targetForHandle(existing)?.isAggregate == false) {
      return existing;
    }
    for (final item in widget.presentation.value.items) {
      if (!item.target.isAggregate) return item.target.handle;
    }
    return null;
  }

  FinancialLimitTarget? _financialTargetForHandle(int handle) {
    final target = _targetForHandle(handle);
    return target == null ? null : _financialTargetFor(target);
  }

  int? _resolvedLimitForHandle(int handle, int year, int month) {
    final target = _financialTargetForHandle(handle);
    if (target == null) return null;
    return FinancialLimitResolution.resolve(
      limits: _timelineByTargetHandle[handle] ?? const <FinancialLimit>[],
      direction: _direction,
      target: target,
      year: year,
      month: month,
    )?.amountScaled100;
  }

  void _replaceLocal(FinancialLimit limit, {required int targetHandle}) {
    setState(() {
      _timelineByTargetHandle = <int, List<FinancialLimit>>{
        ..._timelineByTargetHandle,
        targetHandle: <FinancialLimit>[
          for (final current
              in _timelineByTargetHandle[targetHandle] ??
                  const <FinancialLimit>[])
            if (current.key != limit.key) current,
          limit,
        ],
      };
    });
  }

  void _removeLocal(FinancialLimitKey key, {required int targetHandle}) {
    setState(() {
      _timelineByTargetHandle = <int, List<FinancialLimit>>{
        ..._timelineByTargetHandle,
        targetHandle: <FinancialLimit>[
          for (final current
              in _timelineByTargetHandle[targetHandle] ??
                  const <FinancialLimit>[])
            if (current.key != key) current,
        ],
      };
    });
  }

  Future<void> _setBase(int amount) =>
      _setBaseForTarget(_activeTargetHandle, amount);

  Future<void> _setBaseForTarget(int targetHandle, int amount) async {
    // Capture the prepared/current value before the manager's optimistic
    // timeline replaces it.  The shared write coordinator needs that value
    // for a correct later reconciliation of this exact revision key.
    final activeTarget = _targetForHandle(targetHandle);
    if (activeTarget == null) return;
    final target = _financialTargetFor(activeTarget);
    final confirmedBase = _resolvedLimitForHandle(
      targetHandle,
      _logicalDate.year,
      _logicalDate.month,
    );
    final period = FinancialLimitBaseMonthlyRevisionPeriod(
      _logicalDate.year,
      _logicalDate.month,
    );
    final key = FinancialLimitKey(
      direction: _direction,
      target: target,
      period: period,
    );
    _replaceLocal(
      FinancialLimit(
        key: key,
        amountScaled100: amount,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
      targetHandle: targetHandle,
    );
    await widget.limitEdits.setBaseLimitEffectiveFromCurrentMonth(
      direction: _direction,
      target: target,
      effectiveFromYear: _logicalDate.year,
      effectiveFromMonth: _logicalDate.month,
      coreRevision:
          widget.presentation.preparedSnapshotForManager?.coreRevision ??
          widget.request.coreRevision,
      targetHandle: targetHandle,
      confirmedLimitScaled100: confirmedBase,
      amountScaled100: amount,
    );
  }

  Future<void> _setOverride(int year, int month, int amount) =>
      _setOverrideForTarget(_activeTargetHandle, year, month, amount);

  Future<void> _setOverrideForTarget(
    int targetHandle,
    int year,
    int month,
    int amount,
  ) async {
    final activeTarget = _targetForHandle(targetHandle);
    if (activeTarget == null) return;
    final target = _financialTargetFor(activeTarget);
    final key = FinancialLimitKey(
      direction: _direction,
      target: target,
      period: FinancialLimitMonthOverridePeriod(year, month),
    );
    _replaceLocal(
      FinancialLimit(
        key: key,
        amountScaled100: amount,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
      targetHandle: targetHandle,
    );
    final snapshot = widget.presentation.preparedSnapshotForManager;
    await widget.limitEdits.setMonthOverride(
      direction: _direction,
      target: target,
      year: year,
      month: month,
      coreRevision: snapshot?.coreRevision ?? widget.request.coreRevision,
      targetHandle: targetHandle,
      confirmedLimitScaled100: snapshot
          ?.cellAt(
            direction: widget.request.direction,
            period: BudgetLimitPeriod.month(year, month),
            targetHandle: targetHandle,
          )
          .limitScaled100,
      amountScaled100: amount,
    );
  }

  Future<void> _deleteOverride(int year, int month) =>
      _deleteOverrideForTarget(_activeTargetHandle, year, month);

  Future<void> _deleteOverrideForTarget(
    int targetHandle,
    int year,
    int month,
  ) async {
    final activeTarget = _targetForHandle(targetHandle);
    if (activeTarget == null) return;
    final target = _financialTargetFor(activeTarget);
    final key = FinancialLimitKey(
      direction: _direction,
      target: target,
      period: FinancialLimitMonthOverridePeriod(year, month),
    );
    _removeLocal(key, targetHandle: targetHandle);
    await widget.limitEdits.deleteMonthOverride(
      direction: _direction,
      target: target,
      year: year,
      month: month,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.presentation,
    builder: (context, _) {
      final snapshot = widget.presentation.preparedSnapshotForManager;
      final sum = snapshot == null
          ? null
          : DashboardBudgetSecondaryAnalysisProjector.project(
              snapshot: snapshot,
              direction: widget.request.direction,
              targetHandle: _activeTargetHandle,
              scope: const AllTimeScope(),
              logicalAsOfDate: _logicalDate,
            ).payload;
      final metrics = sum is DashboardBudgetSumAnalysis ? sum : null;
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff18233d),
          elevation: 0,
          leading: IconButton(
            key: const ValueKey<String>('budget-limit-manager-close'),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _perspective == BudgetLimitManagerPerspective.category
                    ? _title
                    : 'Keretkiosztás',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                widget.request.direction == LedgerDirection.expense
                    ? 'Kiadási keret'
                    : 'Bevételi cél',
                style: const TextStyle(fontSize: 11, color: Color(0xff73809a)),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const ValueKey<String>('budget-limit-manager-perspective'),
              tooltip: _perspective == BudgetLimitManagerPerspective.category
                  ? 'Kiosztási nézet'
                  : 'Kategória nézet',
              onPressed: _monthSheetOpen
                  ? null
                  : () => setState(() {
                      _perspective =
                          _perspective == BudgetLimitManagerPerspective.category
                          ? BudgetLimitManagerPerspective.allocation
                          : BudgetLimitManagerPerspective.category;
                    }),
              icon: Icon(
                _perspective == BudgetLimitManagerPerspective.category
                    ? Icons.account_tree_outlined
                    : Icons.grid_view_rounded,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _loadingTimeline
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:
                            _perspective ==
                                BudgetLimitManagerPerspective.category
                            ? <Widget>[
                                _avatarCarousel(),
                                const SizedBox(height: 14),
                                _baseEditorCard(),
                                const SizedBox(height: 10),
                                _metricsCard(metrics),
                                const SizedBox(height: 18),
                                _yearSelector(),
                                const SizedBox(height: 10),
                                _monthGrid(snapshot),
                              ]
                            : _allocationPerspective(snapshot),
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );

  Widget _avatarCarousel() => SizedBox(
    key: const ValueKey<String>('budget-limit-manager-avatar-carousel'),
    height: BudgetTargetAvatarCarouselGeometry.managerViewportHeight,
    child: _avatarItems.length < 2
        ? Center(
            child: SizedBox.square(
              key: const ValueKey<String>('budget-limit-manager-avatar'),
              dimension: 72,
              child: widget.request.avatar,
            ),
          )
        : BudgetTargetAvatarCarousel(
            items: _avatarItems,
            controller: _avatarCarouselController,
            height: BudgetTargetAvatarCarouselGeometry.managerViewportHeight,
            onPreviewChanged: _onAvatarPreview,
            onSelectionSettled: _onAvatarSettled,
            onMotionStarted: (_) => setState(() => _carouselInMotion = true),
            onMotionInterrupted: () =>
                setState(() => _carouselInMotion = false),
            itemBuilder: (context, item, metrics) {
              final avatar = SizedBox.square(
                dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
                child: item.avatarFor(selected: metrics.isSelected),
              );
              return metrics.isSelected
                  ? SizedBox(
                      height: BudgetTargetAvatarCarouselGeometry
                          .selectedInputSurfaceHeight,
                      child: Center(child: avatar),
                    )
                  : avatar;
            },
          ),
  );

  String _allocationDraftKey({
    required int year,
    required int month,
    required int handle,
  }) => '$year-$month-$handle';

  final Map<String, int> _allocationDraftByMonthAndHandle = <String, int>{};

  int _allocationValueFor({
    required int year,
    required int month,
    required int handle,
  }) =>
      _allocationDraftByMonthAndHandle[_allocationDraftKey(
        year: year,
        month: month,
        handle: handle,
      )] ??
      _resolvedLimitForHandle(handle, year, month) ??
      0;

  void _setAllocationDraft({
    required int year,
    required int month,
    required int handle,
    required int amount,
  }) => setState(() {
    _allocationDraftByMonthAndHandle[_allocationDraftKey(
          year: year,
          month: month,
          handle: handle,
        )] =
        amount;
  });

  /// Folds only manager-local, already-entered allocation drafts over the
  /// canonical exact-month partition.  The partition itself remains the one
  /// source of allocation semantics; this merely lets more than one category
  /// retain its local value while the user switches rows before committing.
  DashboardBudgetPartitionPresentation _partitionWithAllocationDrafts({
    required DashboardBudgetPartitionPresentation partition,
    required int year,
    required int month,
  }) {
    var result = partition;
    final aggregateHandle = _aggregateHandle();
    if (aggregateHandle != null) {
      result = result.withAggregateLimitDraft(
        limitScaled100: _resolvedLimitForHandle(aggregateHandle, year, month),
      );
    }
    for (final item in widget.presentation.value.items) {
      if (item.target.isAggregate) continue;
      final draft =
          _allocationDraftByMonthAndHandle[_allocationDraftKey(
            year: year,
            month: month,
            handle: item.target.handle,
          )];
      if (draft != null) {
        result = result.withCategoryLimitDraft(
          categoryHandle: item.target.handle,
          limitScaled100: draft,
        );
      }
    }
    return result;
  }

  int _categorySliderMax({
    required DashboardBudgetPartitionPresentation partition,
    required int handle,
  }) => BudgetAllocationPartitionSlider.maxForActiveCategory(
    partition: partition,
    activeCategoryHandle: handle,
  );

  int? _monthlyIncome(
    PreparedBudgetLimitSnapshot? snapshot,
    int year,
    int month,
  ) {
    final aggregateHandle = _aggregateHandle();
    if (snapshot == null ||
        aggregateHandle == null ||
        year < snapshot.yearWindowStart ||
        year > snapshot.yearWindowEndInclusive) {
      return null;
    }
    return snapshot
        .cellAt(
          direction: LedgerDirection.income,
          period: BudgetLimitPeriod.month(year, month),
          targetHandle: aggregateHandle,
        )
        .actualScaled100;
  }

  List<Widget> _allocationPerspective(PreparedBudgetLimitSnapshot? snapshot) {
    final categoryHandle = _allocationCategoryHandle();
    final aggregateHandle = _aggregateHandle();
    final year = _logicalDate.year;
    final month = _logicalDate.month;
    final preparedPartition = widget.presentation.partitionForManagerMonth(
      direction: widget.request.direction,
      year: year,
      month: month,
    );
    final effectivePartition = _partitionWithAllocationDrafts(
      partition: preparedPartition,
      year: year,
      month: month,
    );
    final monthlyIncome = _monthlyIncome(snapshot, year, month);
    return <Widget>[
      _allocationHero(
        partition: effectivePartition,
        categoryHandle: categoryHandle,
        aggregateHandle: aggregateHandle,
        monthlyIncome: monthlyIncome,
      ),
      const SizedBox(height: 18),
      const Text(
        'Alap kategórialimitek',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      const SizedBox(height: 8),
      _allocationCategoryList(
        partition: effectivePartition,
        activeHandle: categoryHandle,
        year: year,
        month: month,
      ),
      const SizedBox(height: 18),
      _yearSelector(),
      const SizedBox(height: 8),
      _allocationMonthRows(snapshot),
    ];
  }

  Widget _allocationHero({
    required DashboardBudgetPartitionPresentation partition,
    required int? categoryHandle,
    required int? aggregateHandle,
    required int? monthlyIncome,
  }) {
    final base = aggregateHandle == null
        ? null
        : _resolvedLimitForHandle(
            aggregateHandle,
            _logicalDate.year,
            _logicalDate.month,
          );
    return Container(
      key: const ValueKey<String>('budget-limit-manager-allocation-hero'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fc),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe3e7ef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALAP HAVI KIOSZTÁS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: .6,
              fontWeight: FontWeight.w900,
              color: Color(0xff68758e),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatAmount(base),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (aggregateHandle != null)
                IconButton(
                  key: const ValueKey<String>(
                    'budget-limit-manager-allocation-total-edit',
                  ),
                  tooltip: 'Teljes havi keret szerkesztése',
                  onPressed: () => _showAmountEditor(
                    title: 'Alap havi keret',
                    initial: base ?? 0,
                    onSave: (amount) =>
                        _setBaseForTarget(aggregateHandle, amount),
                  ),
                  icon: Icon(Icons.edit_rounded, color: _accent),
                ),
            ],
          ),
          const Text(
            'Alap havi keret',
            style: TextStyle(fontSize: 12, color: Color(0xff68758e)),
          ),
          const SizedBox(height: 14),
          if (categoryHandle != null && partition.hasPositiveAggregateLimit)
            BudgetAllocationPartitionSlider(
              partition: partition,
              activeCategoryHandle: categoryHandle,
              valueScaled100: _allocationValueFor(
                year: _logicalDate.year,
                month: _logicalDate.month,
                handle: categoryHandle,
              ),
              maxScaled100: _categorySliderMax(
                partition: partition,
                handle: categoryHandle,
              ),
              enabled:
                  _categorySliderMax(
                        partition: partition,
                        handle: categoryHandle,
                      ) >
                      0 ||
                  _allocationValueFor(
                        year: _logicalDate.year,
                        month: _logicalDate.month,
                        handle: categoryHandle,
                      ) >
                      0,
              onChanged: (amount) => _setAllocationDraft(
                year: _logicalDate.year,
                month: _logicalDate.month,
                handle: categoryHandle,
                amount: amount,
              ),
              onChangeEnd: (amount) =>
                  _setBaseForTarget(categoryHandle, amount),
            )
          else
            SizedBox(
              height: 18,
              child: BudgetAllocationPartitionLane(partition: partition),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _allocationMetric(
                  'Kiosztva',
                  _formatAmount(partition.liveAllocatedTotalScaled100),
                ),
              ),
              Expanded(
                child: _allocationMetric(
                  'Nincs kiosztva',
                  _formatAmount(partition.unallocatedLimitScaled100),
                ),
              ),
              if (widget.request.direction == LedgerDirection.expense &&
                  aggregateHandle != null &&
                  monthlyIncome != null &&
                  monthlyIncome > 0)
                TextButton.icon(
                  key: const ValueKey<String>(
                    'budget-limit-manager-spec-income',
                  ),
                  onPressed: () =>
                      _setBaseForTarget(aggregateHandle, monthlyIncome),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text('Bevételhez'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allocationMetric(String label, String amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
      ),
      const SizedBox(height: 2),
      Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );

  Widget _allocationCategoryList({
    required DashboardBudgetPartitionPresentation partition,
    required int? activeHandle,
    required int year,
    required int month,
  }) => Column(
    children: [
      for (final item in widget.presentation.value.items)
        if (!item.target.isAggregate)
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey<String>(
                'budget-limit-manager-allocation-category-${item.target.handle}',
              ),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(
                () => _allocationActiveCategoryHandle = item.target.handle,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: item.target.handle == activeHandle
                      ? _accent.withValues(alpha: .10)
                      : const Color(0xfffbfcff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.target.handle == activeHandle
                        ? _accent.withValues(alpha: .55)
                        : const Color(0xffe6e9f0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.target.category!.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      _formatAmount(
                        _allocationValueFor(
                          year: year,
                          month: month,
                          handle: item.target.handle,
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(partition.segmentForCategoryHandle(item.target.handle).totalRatio * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff68758e),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ],
  );

  Widget _allocationMonthRows(PreparedBudgetLimitSnapshot? snapshot) => Column(
    key: const ValueKey<String>('budget-limit-manager-allocation-month-rows'),
    children: [
      for (var month = 1; month <= 12; month += 1)
        _allocationMonthRow(snapshot, _year, month),
    ],
  );

  Widget _allocationMonthRow(
    PreparedBudgetLimitSnapshot? snapshot,
    int year,
    int month,
  ) {
    final partition = _partitionWithAllocationDrafts(
      partition: widget.presentation.partitionForManagerMonth(
        direction: widget.request.direction,
        year: year,
        month: month,
      ),
      year: year,
      month: month,
    );
    final aggregateHandle = _aggregateHandle();
    final total = aggregateHandle == null
        ? null
        : _resolvedLimitForHandle(aggregateHandle, year, month);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'budget-limit-manager-allocation-month-$year-$month',
        ),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAllocationMonthSheet(year, month, partition),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe5e8f0)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  _monthName(month),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 12,
                  child: BudgetAllocationPartitionLane(partition: partition),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatAmount(total),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baseEditorCard() => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const ValueKey<String>('budget-limit-manager-base-editor'),
      borderRadius: BorderRadius.circular(20),
      onTap: _carouselInMotion
          ? null
          : () => _showAmountEditor(
              title: 'Alap havi keret',
              initial: _currentBase ?? 0,
              onSave: _setBase,
            ),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Colors.white, _accent.withValues(alpha: .13)],
          ),
          border: Border.all(color: _accent.withValues(alpha: .22)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _accent.withValues(alpha: .12),
              offset: const Offset(1, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ALAP HAVI KERET',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: .6,
                fontWeight: FontWeight.w800,
                color: Color(0xff6b7890),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatAmount(_currentBase),
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff17233d),
                    ),
                  ),
                ),
                Icon(Icons.edit_rounded, color: _accent),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Az aktuális és jövőbeli hónapok alapértéke',
              style: TextStyle(fontSize: 12, color: Color(0xff69758d)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _metricsCard(DashboardBudgetSumAnalysis? analysis) {
    final available = analysis?.eligibleMonthCount ?? 0;
    final average = analysis?.averageUtilization;
    return Container(
      key: const ValueKey<String>('budget-limit-manager-metrics'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe7eaf2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Átlagos keretkihasználás',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff68758d),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  average == null ? '—' : '${(average * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: average?.clamp(0.0, 1.0).toDouble(),
                    minHeight: 5,
                    backgroundColor: const Color(0xffe3e7ef),
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 54, color: const Color(0xffe2e6ef)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keretbetartás',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff68758d),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  available == 0
                      ? '— / —'
                      : '${analysis!.monthsWithinBudget} / $available',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const Text(
                  'hónap',
                  style: TextStyle(fontSize: 11, color: Color(0xff68758d)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearSelector() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        key: const ValueKey<String>('budget-limit-manager-year-previous'),
        onPressed: () => setState(() => _year -= 1),
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Text(
        '$_year',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      IconButton(
        key: const ValueKey<String>('budget-limit-manager-year-next'),
        onPressed: () => setState(() => _year += 1),
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );

  Widget _monthGrid(PreparedBudgetLimitSnapshot? snapshot) => GridView.builder(
    key: const ValueKey<String>('budget-limit-manager-month-grid'),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 12,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: .83,
    ),
    itemBuilder: (context, index) {
      final month = index + 1;
      final info = _monthInfo(snapshot, _year, month);
      return _BudgetLimitMonthCard(
        info: info,
        accent: _accent,
        onTap: _carouselInMotion ? null : () => _showMonthSheet(info),
      );
    },
  );

  _BudgetLimitMonthInfo _monthInfo(
    PreparedBudgetLimitSnapshot? snapshot,
    int year,
    int month,
  ) {
    final linear = year * 12 + month;
    final logical = _logicalDate.year * 12 + _logicalDate.month;
    final isCurrent = linear == logical;
    final isFuture = linear > logical;
    PreparedBudgetLimitCell? cell;
    if (snapshot != null &&
        year >= snapshot.yearWindowStart &&
        year <= snapshot.yearWindowEndInclusive) {
      cell = snapshot.cellAt(
        direction: widget.request.direction,
        period: BudgetLimitPeriod.month(year, month),
        targetHandle: _activeTargetHandle,
      );
    }
    final override = _overrideFor(year, month);
    final limit = _resolvedLimit(year, month) ?? cell?.limitScaled100;
    final actual = cell?.actualScaled100;
    return _BudgetLimitMonthInfo(
      year: year,
      month: month,
      resolvedLimitScaled100: limit,
      historicalBaseScaled100: _baseFor(year, month)?.amountScaled100,
      actualScaled100: actual,
      isCurrent: isCurrent,
      isFuture: isFuture,
      hasOverride: override != null,
    );
  }

  void _onAvatarPreview(int logicalIndex) {
    if (_avatarItems.isEmpty) return;
    final targetHandle =
        _avatarItems[budgetTargetAvatarCarouselModulo(
              logicalIndex,
              _avatarItems.length,
            )]
            .targetHandle;
    if (targetHandle == _activeTargetHandle) return;
    if (_monthSheetOpen) {
      _monthSheetOpen = false;
      Navigator.of(context).maybePop();
    }
    setState(() => _activeTargetHandle = targetHandle);
  }

  void _onAvatarSettled(int logicalIndex) {
    if (_avatarItems.isEmpty) return;
    final targetHandle =
        _avatarItems[budgetTargetAvatarCarouselModulo(
              logicalIndex,
              _avatarItems.length,
            )]
            .targetHandle;
    setState(() {
      _activeTargetHandle = targetHandle;
      _carouselInMotion = false;
    });
  }

  Future<void> _showAmountEditor({
    required String title,
    required int initial,
    required Future<void> Function(int amount) onSave,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _BudgetLimitAmountEditorSheet(
      title: title,
      initial: initial,
      onSave: onSave,
    ),
  );

  Future<void> _showMonthSheet(_BudgetLimitMonthInfo info) async {
    final activeTargetHandle = _activeTargetHandle;
    final activeTarget = _activeTarget;
    final partition = _partitionWithAllocationDrafts(
      partition: widget.presentation.partitionForManagerMonth(
        direction: widget.request.direction,
        year: info.year,
        month: info.month,
      ),
      year: info.year,
      month: info.month,
    );
    _monthSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => _BudgetLimitMonthSheet(
          info: info,
          accent: _accent,
          targetHandle: activeTargetHandle,
          targetTitle: _title,
          targetIsAggregate: activeTarget.isAggregate,
          partition: partition,
          onSetOverride: (amount) async {
            await _setOverride(info.year, info.month, amount);
          },
          onDeleteOverride: () async {
            await _deleteOverride(info.year, info.month);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        ),
      );
    } finally {
      _monthSheetOpen = false;
    }
  }

  Future<void> _showAllocationMonthSheet(
    int year,
    int month,
    DashboardBudgetPartitionPresentation partition,
  ) async {
    final initialHandle = _allocationCategoryHandle();
    if (initialHandle == null) return;
    final aggregateHandle = _aggregateHandle();
    _monthSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _BudgetLimitAllocationMonthSheet(
          year: year,
          month: month,
          partition: partition,
          accent: _accent,
          aggregateAmountScaled100: aggregateHandle == null
              ? null
              : _resolvedLimitForHandle(aggregateHandle, year, month),
          monthlyIncomeScaled100: _monthlyIncome(
            widget.presentation.preparedSnapshotForManager,
            year,
            month,
          ),
          canUseIncomeSpec:
              widget.request.direction == LedgerDirection.expense &&
              aggregateHandle != null,
          entries: <_BudgetLimitAllocationEntry>[
            for (final item in widget.presentation.value.items)
              if (!item.target.isAggregate)
                _BudgetLimitAllocationEntry(
                  handle: item.target.handle,
                  title: item.target.category!.displayName,
                  amountScaled100: _allocationValueFor(
                    year: year,
                    month: month,
                    handle: item.target.handle,
                  ),
                ),
          ],
          initialHandle: initialHandle,
          onDraftChanged: (handle, amount) => _setAllocationDraft(
            year: year,
            month: month,
            handle: handle,
            amount: amount,
          ),
          onCommit: (handle, amount) =>
              _setOverrideForTarget(handle, year, month, amount),
          onSetAggregateToIncome: aggregateHandle == null
              ? null
              : (amount) =>
                    _setOverrideForTarget(aggregateHandle, year, month, amount),
        ),
      );
    } finally {
      _monthSheetOpen = false;
    }
  }
}

FinancialLimitTarget _financialTargetFor(DashboardBudgetTarget target) =>
    target.isAggregate
    ? const FinancialLimitAggregateTarget()
    : FinancialLimitCategoryTarget(target.category!.id);

bool _sameAvatarItems(
  List<BudgetTargetAvatarCarouselItem> current,
  List<BudgetTargetAvatarCarouselItem> next,
) {
  if (current.length != next.length) return false;
  for (var index = 0; index < current.length; index += 1) {
    final existing = current[index];
    final candidate = next[index];
    if (existing.targetHandle != candidate.targetHandle ||
        existing.stableId != candidate.stableId ||
        existing.artworkIdentity != candidate.artworkIdentity) {
      return false;
    }
  }
  return true;
}

/// Owns its [TextEditingController] for the full route lifetime.  The manager
/// itself may rebuild optimistically while a save is in flight, so disposing a
/// controller from the caller immediately after `Navigator.pop` would race
/// the bottom-sheet exit animation.
final class _BudgetLimitAmountEditorSheet extends StatefulWidget {
  const _BudgetLimitAmountEditorSheet({
    required this.title,
    required this.initial,
    required this.onSave,
  });

  final String title;
  final int initial;
  final Future<void> Function(int amount) onSave;

  @override
  State<_BudgetLimitAmountEditorSheet> createState() =>
      _BudgetLimitAmountEditorSheetState();
}

final class _BudgetLimitAmountEditorSheetState
    extends State<_BudgetLimitAmountEditorSheet> {
  late final TextEditingController _controller;
  late int _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _controller = TextEditingController(text: (_draft ~/ 100).toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyDelta(int deltaForints) {
    setState(() {
      _draft = (_draft + deltaForints * 100)
          .clamp(0, 0x7fffffffffffffff)
          .toInt();
      _controller.text = (_draft ~/ 100).toString();
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      8,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'Ft',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _draft =
              (int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) *
              100,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[-10000, -1000, 1000, 10000]
              .map(
                (delta) => OutlinedButton(
                  onPressed: () => _applyDelta(delta),
                  child: Text('${delta > 0 ? '+' : '−'}${delta.abs()}'),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await widget.onSave(_draft);
            if (mounted) navigator.pop();
          },
          child: const Text('Mentés'),
        ),
      ],
    ),
  );
}

@immutable
final class _BudgetLimitMonthInfo {
  const _BudgetLimitMonthInfo({
    required this.year,
    required this.month,
    required this.resolvedLimitScaled100,
    required this.historicalBaseScaled100,
    required this.actualScaled100,
    required this.isCurrent,
    required this.isFuture,
    required this.hasOverride,
  });

  final int year;
  final int month;
  final int? resolvedLimitScaled100;
  final int? historicalBaseScaled100;
  final int? actualScaled100;
  final bool isCurrent;
  final bool isFuture;
  final bool hasOverride;

  bool get isClosed => !isCurrent && !isFuture;
  double? get utilization =>
      actualScaled100 == null ||
          resolvedLimitScaled100 == null ||
          resolvedLimitScaled100! <= 0
      ? null
      : actualScaled100! / resolvedLimitScaled100!;
}

final class _BudgetLimitMonthCard extends StatelessWidget {
  const _BudgetLimitMonthCard({
    required this.info,
    required this.accent,
    required this.onTap,
  });

  final _BudgetLimitMonthInfo info;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = info.utilization;
    final completedGood = ratio != null && ratio <= 1;
    final progressColor = info.isCurrent
        ? (ratio != null && ratio > 1 ? const Color(0xffe05b73) : accent)
        : completedGood
        ? const Color(0xff26ae83)
        : const Color(0xffe05b73);
    final state = info.resolvedLimitScaled100 == null
        ? 'Nincs keret'
        : info.hasOverride
        ? 'Egyedi'
        : info.isCurrent
        ? 'Folyamatban'
        : '';
    return Semantics(
      button: true,
      label:
          '${_monthName(info.month)} ${info.year}, $state ${_formatAmount(info.resolvedLimitScaled100)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>(
            'budget-limit-manager-month-card-${info.year}-${info.month}',
          ),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: info.isCurrent
                  ? accent.withValues(alpha: .08)
                  : const Color(0xfffbfcff),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: info.hasOverride
                    ? accent.withValues(alpha: .55)
                    : const Color(0xffe3e7ef),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthName(info.month),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff5d6a82),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatAmount(info.resolvedLimitScaled100),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff1c2942),
                        ),
                      ),
                    ),
                  ),
                ),
                if (info.resolvedLimitScaled100 != null && !info.isFuture)
                  _MiniUtilizationRail(
                    ratio: ratio,
                    color: progressColor,
                    showOvershoot: ratio != null && ratio > 1.2,
                  )
                else if (info.resolvedLimitScaled100 != null)
                  const _MiniUtilizationRail(
                    ratio: null,
                    color: Color(0xffcfd6e2),
                    showOvershoot: false,
                  ),
                const SizedBox(height: 4),
                Text(
                  state,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: state == 'Nincs keret'
                        ? const Color(0xff8993a7)
                        : progressColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _MiniUtilizationRail extends StatelessWidget {
  const _MiniUtilizationRail({
    required this.ratio,
    required this.color,
    required this.showOvershoot,
  });
  final double? ratio;
  final Color color;
  final bool showOvershoot;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xffe4e8f0),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        if (ratio != null)
          FractionallySizedBox(
            widthFactor: (ratio! / 1.2).clamp(0.0, 1.0).toDouble(),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        Positioned(
          left: constraints.maxWidth * (1 / 1.2),
          top: 0,
          bottom: 0,
          child: Container(width: 1, color: Colors.white.withValues(alpha: .8)),
        ),
        if (showOvershoot)
          const Positioned(
            right: 0,
            top: -1,
            child: Icon(Icons.error_rounded, size: 8, color: Color(0xffe05b73)),
          ),
      ],
    ),
  );
}

final class _BudgetLimitMonthSheet extends StatefulWidget {
  const _BudgetLimitMonthSheet({
    required this.info,
    required this.accent,
    required this.targetHandle,
    required this.targetTitle,
    required this.targetIsAggregate,
    required this.partition,
    required this.onSetOverride,
    required this.onDeleteOverride,
  });

  final _BudgetLimitMonthInfo info;
  final Color accent;
  final int targetHandle;
  final String targetTitle;
  final bool targetIsAggregate;
  final DashboardBudgetPartitionPresentation partition;
  final Future<void> Function(int) onSetOverride;
  final Future<void> Function() onDeleteOverride;

  @override
  State<_BudgetLimitMonthSheet> createState() => _BudgetLimitMonthSheetState();
}

final class _BudgetLimitMonthSheetState extends State<_BudgetLimitMonthSheet> {
  late final TextEditingController _controller;
  var _isEditing = false;
  late int _sliderDraftScaled100;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ((widget.info.resolvedLimitScaled100 ?? 0) ~/ 100).toString(),
    )..addListener(_onDraftChanged);
    _sliderDraftScaled100 = widget.info.resolvedLimitScaled100 ?? 0;
  }

  @override
  void dispose() {
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onDraftChanged() {
    if (!_isEditing) return;
    _sliderDraftScaled100 = _overrideDraftScaled100;
    if (mounted) setState(() {});
  }

  void _adjustOverride(int deltaForints) {
    final current =
        int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    _controller.text = (current + deltaForints)
        .clamp(0, 0x7fffffffffffffff)
        .toString();
  }

  int get _overrideDraftScaled100 =>
      (int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) *
      100;

  DashboardBudgetPartitionPresentation get _displayedPartition => _isEditing
      ? widget.partition.withCategoryLimitDraft(
          categoryHandle: widget.targetHandle,
          limitScaled100: _overrideDraftScaled100,
        )
      : widget.partition;

  int get _categorySliderMaxScaled100 {
    if (widget.targetIsAggregate ||
        !widget.partition.hasPositiveAggregateLimit) {
      return 0;
    }
    final active =
        widget.partition.effectiveLimitForCategoryHandle(widget.targetHandle) ??
        0;
    final otherAllocated =
        (widget.partition.liveAllocatedTotalScaled100 -
                (active > 0 ? active : 0))
            .clamp(0, 0x7fffffffffffffff)
            .toInt();
    return ((widget.partition.effectiveAggregateLimitScaled100 ?? 0) -
            otherAllocated)
        .clamp(0, 0x7fffffffffffffff)
        .toInt();
  }

  void _setSliderDraft(int value) {
    setState(() {
      _isEditing = true;
      _sliderDraftScaled100 = value;
      _controller.value = TextEditingValue(
        text: (value ~/ 100).toString(),
        selection: TextSelection.collapsed(
          offset: (value ~/ 100).toString().length,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final ratio = info.utilization;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthLongName(info.month)} ${info.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (info.hasOverride) _chip('Egyedi', widget.accent),
              if (info.isCurrent) _chip('Folyamatban', widget.accent),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            info.isClosed && !info.hasOverride ? 'Akkori keret' : 'Keret',
            style: const TextStyle(
              color: Color(0xff6a768c),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatAmount(info.resolvedLimitScaled100),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey<String>('budget-limit-month-sheet-edit'),
                tooltip: info.hasOverride
                    ? 'Egyedi keret szerkesztése'
                    : 'Egyedi keret beállítása',
                onPressed: () => setState(() => _isEditing = true),
                icon: Icon(Icons.edit_rounded, color: widget.accent),
              ),
            ],
          ),
          if (info.historicalBaseScaled100 != null && info.hasOverride) ...[
            const SizedBox(height: 4),
            Text(
              'Alap havi keret: ${_formatAmount(info.historicalBaseScaled100)}',
              style: const TextStyle(fontSize: 12, color: Color(0xff6a768c)),
            ),
          ] else if (info.isClosed && !info.hasOverride)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Ezt az akkori alap havi keretből örökli.',
                style: TextStyle(fontSize: 12, color: Color(0xff6a768c)),
              ),
            ),
          if (info.resolvedLimitScaled100 == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Ehhez a hónaphoz még nincs beállítva keret.',
                style: TextStyle(fontSize: 12, color: Color(0xff6a768c)),
              ),
            )
          else if (info.isFuture && !info.hasOverride)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Az alap havi keretből örökli.',
                style: TextStyle(fontSize: 12, color: Color(0xff6a768c)),
              ),
            ),
          if (info.isClosed &&
              info.actualScaled100 != null &&
              info.resolvedLimitScaled100 != null) ...[
            const SizedBox(height: 15),
            const Text('Költés', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              _formatAmount(info.actualScaled100),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            if (ratio != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _closedMonthDeltaCopy(info),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ratio > 1
                        ? const Color(0xffd94f69)
                        : const Color(0xff288e6e),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            _MiniUtilizationRail(
              ratio: ratio,
              color: ratio != null && ratio > 1
                  ? const Color(0xffe05b73)
                  : const Color(0xff26ae83),
              showOvershoot: ratio != null && ratio > 1.2,
            ),
            const SizedBox(height: 4),
            Text(
              ratio == null
                  ? '—'
                  : '${(ratio * 100).round()}% hónap végi állapot',
              style: const TextStyle(fontSize: 12, color: Color(0xff68758e)),
            ),
          ],
          if (info.isCurrent &&
              info.actualScaled100 != null &&
              info.resolvedLimitScaled100 != null) ...[
            const SizedBox(height: 15),
            const Text(
              'Eddigi költés',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _formatAmount(info.actualScaled100),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            _MiniUtilizationRail(
              ratio: ratio,
              color: ratio != null && ratio > 1
                  ? const Color(0xffe05b73)
                  : widget.accent,
              showOvershoot: ratio != null && ratio > 1.2,
            ),
            const SizedBox(height: 4),
            Text(
              ratio == null ? '—' : '${(ratio * 100).round()}% felhasználva',
              style: const TextStyle(fontSize: 12, color: Color(0xff68758e)),
            ),
          ],
          if (info.isFuture) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff6f7fa),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ehhez a hónaphoz még nincs költési adat.',
                style: TextStyle(fontSize: 12, color: Color(0xff68758e)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _BudgetLimitMonthPartitionContext(
            partition: _displayedPartition,
            accent: widget.accent,
            targetHandle: widget.targetHandle,
            targetTitle: widget.targetTitle,
            targetIsAggregate: widget.targetIsAggregate,
            year: info.year,
            month: info.month,
            slider: widget.targetIsAggregate
                ? null
                : BudgetAllocationPartitionSlider(
                    partition: _displayedPartition,
                    activeCategoryHandle: widget.targetHandle,
                    valueScaled100: _sliderDraftScaled100,
                    maxScaled100: _categorySliderMaxScaled100,
                    enabled:
                        _categorySliderMaxScaled100 > 0 ||
                        _sliderDraftScaled100 > 0,
                    onChanged: _setSliderDraft,
                    onChangeEnd: widget.onSetOverride,
                  ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            const Text(
              'Egyedi keret beállítása',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey<String>('budget-limit-month-sheet-amount'),
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: 'Ft',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <int>[-10000, -1000, 1000, 10000]
                  .map(
                    (delta) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: OutlinedButton(
                          onPressed: () => _adjustOverride(delta),
                          child: Text(
                            '${delta > 0 ? '+' : '−'}${delta.abs() ~/ 1000}k',
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => widget.onSetOverride(_overrideDraftScaled100),
              child: const Text('Egyedi keret mentése'),
            ),
            if (info.hasOverride)
              TextButton(
                onPressed: widget.onDeleteOverride,
                child: const Text('Vissza az alapértékhez'),
              ),
          ],
        ],
      ),
    );
  }

  String _closedMonthDeltaCopy(_BudgetLimitMonthInfo info) {
    final actual = info.actualScaled100 ?? 0;
    final limit = info.resolvedLimitScaled100 ?? 0;
    final delta = actual - limit;
    if (delta > 0) return '+${_formatAmount(delta)} túllépted a keretet';
    if (delta < 0) return '${_formatAmount(-delta)} a keret alatt maradt';
    return 'Pontosan elérted a keretet';
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

/// Expanded, exact-month counterpart of the Header allocation lane.  It owns
/// no allocation formula: all segment and total values come from the same
/// immutable [DashboardBudgetPartitionPresentation] as the Header.
final class _BudgetLimitMonthPartitionContext extends StatelessWidget {
  const _BudgetLimitMonthPartitionContext({
    required this.partition,
    required this.accent,
    required this.targetHandle,
    required this.targetTitle,
    required this.targetIsAggregate,
    required this.year,
    required this.month,
    this.slider,
  });

  final DashboardBudgetPartitionPresentation partition;
  final Color accent;
  final int targetHandle;
  final String targetTitle;
  final bool targetIsAggregate;
  final int year;
  final int month;
  final Widget? slider;

  @override
  Widget build(BuildContext context) {
    if (!partition.hasPositiveAggregateLimit) return const SizedBox.shrink();
    final segment = partition.segmentForCategoryHandle(targetHandle);
    final categoryLimit = targetIsAggregate
        ? partition.effectiveAggregateLimitScaled100
        : partition.effectiveLimitForCategoryHandle(targetHandle);
    final share = targetIsAggregate ? 1.0 : segment.totalRatio;
    return Container(
      key: const ValueKey<String>('budget-limit-month-sheet-partition'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Helye a havi keretben',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${_monthLongName(month)} $year · Teljes havi keret',
            style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
          ),
          const SizedBox(height: 2),
          Text(
            _formatAmount(partition.effectiveAggregateLimitScaled100),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 11),
          slider ??
              SizedBox(
                height: 18,
                child: BudgetAllocationPartitionLane(
                  partition: partition,
                  highlightedCategoryHandle: targetIsAggregate
                      ? null
                      : targetHandle,
                ),
              ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category_rounded, size: 12, color: accent),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  targetTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 27, top: 1),
            child: Text(
              '${_formatAmount(categoryLimit)} a teljes keretből',
              style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Kiosztva összesen',
                  _formatAmount(partition.liveAllocatedTotalScaled100),
                  '${(partition.allocationRawRatio * 100).round()}%',
                ),
              ),
              Expanded(
                child: _metric(
                  'Nincs kiosztva',
                  _formatAmount(partition.unallocatedLimitScaled100),
                  '${(partition.unallocatedRatio * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String amount, String ratio) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xff68758e)),
      ),
      const SizedBox(height: 2),
      Text(
        amount,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      Text(
        ratio,
        style: const TextStyle(fontSize: 10, color: Color(0xff68758e)),
      ),
    ],
  );
}

@immutable
final class _BudgetLimitAllocationEntry {
  const _BudgetLimitAllocationEntry({
    required this.handle,
    required this.title,
    required this.amountScaled100,
  });

  final int handle;
  final String title;
  final int amountScaled100;
}

/// Time-centric sibling of the category month sheet.  It deliberately takes
/// an immutable prepared partition and only publishes a local draft while the
/// handle moves; the manager performs the single exact-month write on release.
final class _BudgetLimitAllocationMonthSheet extends StatefulWidget {
  const _BudgetLimitAllocationMonthSheet({
    required this.year,
    required this.month,
    required this.partition,
    required this.accent,
    required this.aggregateAmountScaled100,
    required this.monthlyIncomeScaled100,
    required this.canUseIncomeSpec,
    required this.entries,
    required this.initialHandle,
    required this.onDraftChanged,
    required this.onCommit,
    required this.onSetAggregateToIncome,
  });

  final int year;
  final int month;
  final DashboardBudgetPartitionPresentation partition;
  final Color accent;
  final int? aggregateAmountScaled100;
  final int? monthlyIncomeScaled100;
  final bool canUseIncomeSpec;
  final List<_BudgetLimitAllocationEntry> entries;
  final int initialHandle;
  final void Function(int handle, int amount) onDraftChanged;
  final Future<void> Function(int handle, int amount) onCommit;
  final Future<void> Function(int amount)? onSetAggregateToIncome;

  @override
  State<_BudgetLimitAllocationMonthSheet> createState() =>
      _BudgetLimitAllocationMonthSheetState();
}

final class _BudgetLimitAllocationMonthSheetState
    extends State<_BudgetLimitAllocationMonthSheet> {
  late int _activeHandle;
  late final Map<int, int> _draftByHandle;

  @override
  void initState() {
    super.initState();
    _activeHandle = widget.initialHandle;
    _draftByHandle = <int, int>{
      for (final entry in widget.entries) entry.handle: entry.amountScaled100,
    };
  }

  int get _activeAmount => _draftByHandle[_activeHandle] ?? 0;

  int get _maxAmount {
    return BudgetAllocationPartitionSlider.maxForActiveCategory(
      partition: _partition,
      activeCategoryHandle: _activeHandle,
    );
  }

  DashboardBudgetPartitionPresentation get _partition {
    var result = widget.partition;
    for (final entry in _draftByHandle.entries) {
      result = result.withCategoryLimitDraft(
        categoryHandle: entry.key,
        limitScaled100: entry.value,
      );
    }
    return result;
  }

  void _setDraft(int amount) {
    setState(() => _draftByHandle[_activeHandle] = amount);
    widget.onDraftChanged(_activeHandle, amount);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      8,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_monthLongName(widget.month)} ${widget.year}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Keretkiosztás',
          style: TextStyle(fontSize: 12, color: Color(0xff68758e)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_formatAmount(widget.aggregateAmountScaled100 ?? widget.partition.effectiveAggregateLimitScaled100)} teljes havi keret',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (widget.canUseIncomeSpec &&
                widget.monthlyIncomeScaled100 != null &&
                widget.monthlyIncomeScaled100! > 0)
              Tooltip(
                message: 'Budget beállítása a havi bevételre',
                child: TextButton.icon(
                  key: const ValueKey<String>(
                    'budget-limit-allocation-sheet-spec-income',
                  ),
                  onPressed: () => widget.onSetAggregateToIncome!(
                    widget.monthlyIncomeScaled100!,
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text('Bevételhez'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        BudgetAllocationPartitionSlider(
          partition: _partition,
          activeCategoryHandle: _activeHandle,
          valueScaled100: _activeAmount,
          maxScaled100: _maxAmount,
          enabled: _maxAmount > 0 || _activeAmount > 0,
          onChanged: _setDraft,
          onChangeEnd: (amount) => widget.onCommit(_activeHandle, amount),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _allocationMetric(
                'Kiosztva',
                _formatAmount(_partition.liveAllocatedTotalScaled100),
              ),
            ),
            Expanded(
              child: _allocationMetric(
                'Szabad',
                _formatAmount(_partition.unallocatedLimitScaled100),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Kategóriák', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        for (final entry in widget.entries)
          ListTile(
            key: ValueKey<String>(
              'budget-limit-allocation-sheet-category-${entry.handle}',
            ),
            contentPadding: EdgeInsets.zero,
            selected: entry.handle == _activeHandle,
            selectedTileColor: widget.accent.withValues(alpha: .10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              entry.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${(widget.partition.segmentForCategoryHandle(entry.handle).totalRatio * 100).round()}% a teljes keretből',
            ),
            trailing: Text(
              _formatAmount(_draftByHandle[entry.handle]),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            onTap: () => setState(() => _activeHandle = entry.handle),
          ),
      ],
    ),
  );

  Widget _allocationMetric(String label, String amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
      ),
      Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

String _formatAmount(int? scaled100) {
  if (scaled100 == null) return '—';
  final forints = scaled100 ~/ 100;
  final digits = forints.toString();
  final parts = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end).toInt();
    parts.add(digits.substring(start, end));
  }
  return '${parts.reversed.join(' ')} Ft';
}

String _monthName(int month) => const <String>[
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

String _monthLongName(int month) => const <String>[
  'Január',
  'Február',
  'Március',
  'Április',
  'Május',
  'Június',
  'Július',
  'Augusztus',
  'Szeptember',
  'Október',
  'November',
  'December',
][month - 1];
