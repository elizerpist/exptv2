import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_catalog.dart';
import '../../../../core/categories/domain/category_repository.dart';
import '../../../../core/categories/domain/fluvi_category.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
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
import 'budget_secondary_analysis_card.dart';
import 'category_limit_allocation_progress_slider.dart';
import 'budget_limit_mixed_month_sheet.dart';
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
    this.categoryCollection,
    this.categoryRepository,
    super.key,
  });

  final BudgetLimitManagerRequest request;
  final DashboardBudgetPresentationController presentation;
  final DashboardBudgetLimitEditController limitEdits;

  /// The root-owned live category inventory.  The manager observes it but
  /// never keeps a second category catalog or performs category reads while
  /// rendering.
  final ValueListenable<List<FluviCategory>>? categoryCollection;

  /// The one native category write authority.  It is deliberately explicit so
  /// embedded/test hosts can remain limit-only without inventing another CRUD
  /// queue.
  final CategoryRepository? categoryRepository;

  @override
  State<BudgetLimitManager> createState() => _BudgetLimitManagerState();
}

/// A manager-local information architecture choice.  It has no persistence
/// meaning and always starts in the target/category view on a fresh open.
enum BudgetLimitManagerPerspective { category, allocation, mixed }

sealed class _BudgetLimitManagerPage {
  const _BudgetLimitManagerPage();
}

final class _BudgetLimitManagerOverviewPage extends _BudgetLimitManagerPage {
  const _BudgetLimitManagerOverviewPage();
}

final class _BudgetLimitManagerMonthPage extends _BudgetLimitManagerPage {
  const _BudgetLimitManagerMonthPage({
    required this.year,
    required this.month,
    required this.originatingTargetHandle,
  });

  final int year;
  final int month;
  final int originatingTargetHandle;
}

final class _BudgetLimitManagerState extends State<BudgetLimitManager> {
  static final MenuStyle _contextMenuStyle = MenuStyle(
    backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    elevation: const WidgetStatePropertyAll<double>(6),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(vertical: 6),
    ),
    fixedSize: const WidgetStatePropertyAll<Size>(Size.fromWidth(296)),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  late int _year;
  late final CenteredCarouselController _avatarCarouselController;
  List<BudgetTargetAvatarCarouselItem> _avatarItems =
      const <BudgetTargetAvatarCarouselItem>[];
  List<FinancialLimit> _timelineValues = const <FinancialLimit>[];
  Map<int, List<FinancialLimit>> _timelineByTargetHandle =
      const <int, List<FinancialLimit>>{};
  late int _activeTargetHandle;
  late String _activeTargetStableId;
  String? _categoryIdToSelectAfterCollectionUpdate;
  bool _carouselInMotion = false;
  bool _monthSheetOpen = false;
  bool _loadingTimeline = true;
  var _perspective = BudgetLimitManagerPerspective.category;
  _BudgetLimitManagerPage _page = const _BudgetLimitManagerOverviewPage();
  final ScrollController _rootScrollController = ScrollController();
  int? _allocationActiveCategoryHandle;
  String? _allocationActiveCategoryStableId;

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

  List<FinancialLimit> _timelineForHandle(int handle) =>
      _timelineByTargetHandle[handle] ?? const <FinancialLimit>[];

  LocalDate get _logicalDate => widget.presentation.logicalAsOfDateForManager;

  bool get _usesAvatarCentricRoot =>
      _perspective == BudgetLimitManagerPerspective.category ||
      _perspective == BudgetLimitManagerPerspective.mixed;

  bool get _isMonthEditor => _page is _BudgetLimitManagerMonthPage;

  @override
  void initState() {
    super.initState();
    _year = _logicalDate.year;
    _activeTargetHandle = widget.request.targetHandle;
    _activeTargetStableId = _stableIdForTarget(widget.request.target);
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
    if (next.isEmpty) {
      _avatarItems = next;
      return;
    }
    final matchingIndex = next.indexWhere(
      (item) => item.stableId == _activeTargetStableId,
    );
    final pendingCategoryId = _categoryIdToSelectAfterCollectionUpdate;
    final pendingIndex = pendingCategoryId == null
        ? -1
        : next.indexWhere(
            (item) => item.stableId == 'category:$pendingCategoryId',
          );
    if (pendingIndex >= 0) {
      _activeTargetStableId = next[pendingIndex].stableId;
      _activeTargetHandle = next[pendingIndex].targetHandle;
      _categoryIdToSelectAfterCollectionUpdate = null;
    } else if (matchingIndex >= 0) {
      _activeTargetHandle = next[matchingIndex].targetHandle;
    } else {
      // A deleted category cannot leave the manager pointing at a recycled
      // positional handle.  Aggregate is the only stable safe fallback.
      final aggregate = next.firstWhere(
        (item) => item.stableId == 'aggregate',
        orElse: () => next.first,
      );
      _activeTargetStableId = aggregate.stableId;
      _activeTargetHandle = aggregate.targetHandle;
    }
    final allocationStableId = _allocationActiveCategoryStableId;
    if (allocationStableId != null) {
      final allocationIndex = next.indexWhere(
        (item) => item.stableId == allocationStableId,
      );
      if (allocationIndex >= 0) {
        _allocationActiveCategoryHandle = next[allocationIndex].targetHandle;
      } else {
        _allocationActiveCategoryStableId = null;
        _allocationActiveCategoryHandle = null;
      }
    }
    _timelineByTargetHandle = _indexTimelineByTarget(_timelineValues);
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
    _rootScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    final values = await widget.limitEdits.loadLimitTimelinesForDirection(
      direction: _direction,
    );
    if (!mounted) return;
    setState(() {
      _timelineValues = List<FinancialLimit>.unmodifiable(values);
      _timelineByTargetHandle = _indexTimelineByTarget(_timelineValues);
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
    return FinancialLimitAvailability.positiveOrNull(
      _resolvedLimitRecord(
        limits: _timeline,
        target: _target,
        year: year,
        month: month,
      )?.amountScaled100,
    );
  }

  FinancialLimit? _resolvedLimitRecord({
    required Iterable<FinancialLimit> limits,
    required FinancialLimitTarget target,
    required int year,
    required int month,
  }) => FinancialLimitResolution.resolve(
    limits: limits,
    direction: _direction,
    target: target,
    year: year,
    month: month,
  );

  FinancialLimit? _resolvedLimitRecordForHandle(
    int handle,
    int year,
    int month,
  ) {
    final target = _financialTargetForHandle(handle);
    if (target == null) return null;
    return _resolvedLimitRecord(
      limits: _timelineByTargetHandle[handle] ?? const <FinancialLimit>[],
      target: target,
      year: year,
      month: month,
    );
  }

  int? _resolvedLimitForHandle(int handle, int year, int month) {
    return FinancialLimitAvailability.positiveOrNull(
      _resolvedLimitRecordForHandle(handle, year, month)?.amountScaled100,
    );
  }

  FinancialLimit? _baseForTargetHandle(int handle, int year, int month) {
    final target = _financialTargetForHandle(handle);
    if (target == null) return null;
    return FinancialLimitResolution.baseRevisionAtOrBefore(
      limits: _timelineForHandle(handle),
      direction: _direction,
      target: target,
      year: year,
      month: month,
    );
  }

  FinancialLimit? _overrideForTargetHandle(int handle, int year, int month) {
    final target = _financialTargetForHandle(handle);
    if (target == null) return null;
    return FinancialLimitResolution.exactMonthOverride(
      limits: _timelineForHandle(handle),
      direction: _direction,
      target: target,
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
    final stableId = _allocationActiveCategoryStableId;
    if (stableId != null) {
      for (final item in _avatarItems) {
        if (item.stableId == stableId &&
            _targetForHandle(item.targetHandle)?.isAggregate == false) {
          _allocationActiveCategoryHandle = item.targetHandle;
          return item.targetHandle;
        }
      }
    }
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

  void _replaceLocal(FinancialLimit limit) {
    setState(() {
      _timelineValues = List<FinancialLimit>.unmodifiable(<FinancialLimit>[
        for (final current in _timelineValues)
          if (current.key != limit.key) current,
        limit,
      ]);
      _timelineByTargetHandle = _indexTimelineByTarget(_timelineValues);
    });
  }

  void _removeLocal(FinancialLimitKey key) {
    setState(() {
      _timelineValues = List<FinancialLimit>.unmodifiable(<FinancialLimit>[
        for (final current in _timelineValues)
          if (current.key != key) current,
      ]);
      _timelineByTargetHandle = _indexTimelineByTarget(_timelineValues);
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

  /// A base "delete" is a future-effective zero revision, never a physical
  /// deletion. Removing the record would reveal an older base revision and
  /// silently rewrite the user's intended no-limit state.
  Future<void> _setNoBaseForTarget(int targetHandle) async {
    final activeTarget = _targetForHandle(targetHandle);
    if (activeTarget == null) return;
    final target = _financialTargetFor(activeTarget);
    final key = FinancialLimitKey(
      direction: _direction,
      target: target,
      period: FinancialLimitBaseMonthlyRevisionPeriod(
        _logicalDate.year,
        _logicalDate.month,
      ),
    );
    final confirmedBase = _resolvedLimitForHandle(
      targetHandle,
      _logicalDate.year,
      _logicalDate.month,
    );
    _replaceLocal(
      FinancialLimit(
        key: key,
        amountScaled100: 0,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );
    await widget.limitEdits.setNoBaseLimitEffectiveFromCurrentMonth(
      direction: _direction,
      target: target,
      effectiveFromYear: _logicalDate.year,
      effectiveFromMonth: _logicalDate.month,
      coreRevision:
          widget.presentation.preparedSnapshotForManager?.coreRevision ??
          widget.request.coreRevision,
      targetHandle: targetHandle,
      confirmedLimitScaled100: confirmedBase,
    );
  }

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

  /// An exact monthly "delete" must suppress an inherited base for that
  /// month. A zero override is therefore a deliberate no-limit marker;
  /// [_deleteOverrideForTarget] is reserved for "Vissza az alapértékhez".
  Future<void> _setNoMonthLimitForTarget(
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
    _replaceLocal(
      FinancialLimit(
        key: key,
        amountScaled100: 0,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    );
    final snapshot = widget.presentation.preparedSnapshotForManager;
    await widget.limitEdits.setNoMonthLimit(
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
    );
  }

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
    _removeLocal(key);
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
      final page = _page;
      final monthPage = page is _BudgetLimitManagerMonthPage ? page : null;
      return PopScope(
        canPop: monthPage == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && monthPage != null) _returnToOverview();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff18233d),
            elevation: 0,
            leading: IconButton(
              key: ValueKey<String>(
                monthPage == null
                    ? 'budget-limit-manager-close'
                    : 'budget-limit-manager-month-back',
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: monthPage == null
                  ? () => Navigator.of(context).maybePop()
                  : _returnToOverview,
            ),
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthPage == null
                      ? (_usesAvatarCentricRoot ? _title : 'Keretkiosztás')
                      : '${_monthLongName(monthPage.month)} ${monthPage.year}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  monthPage == null
                      ? (widget.request.direction == LedgerDirection.expense
                            ? 'Kiadási keret'
                            : 'Bevételi cél')
                      : 'Keretkiosztás',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff73809a),
                  ),
                ),
              ],
            ),
            actions: [
              if (monthPage != null) _monthContextMenu(monthPage),
              if (monthPage == null)
                IconButton(
                  key: const ValueKey<String>(
                    'budget-limit-manager-perspective',
                  ),
                  tooltip: switch (_perspective) {
                    BudgetLimitManagerPerspective.category =>
                      'Keretkezelő nézet: Avatar szerint',
                    BudgetLimitManagerPerspective.allocation =>
                      'Keretkezelő nézet: Hónap szerint',
                    BudgetLimitManagerPerspective.mixed =>
                      'Keretkezelő nézet: Kevert',
                  },
                  onPressed: _monthSheetOpen
                      ? null
                      : () => setState(() {
                          _perspective = switch (_perspective) {
                            BudgetLimitManagerPerspective.category =>
                              BudgetLimitManagerPerspective.allocation,
                            BudgetLimitManagerPerspective.allocation =>
                              BudgetLimitManagerPerspective.mixed,
                            BudgetLimitManagerPerspective.mixed =>
                              BudgetLimitManagerPerspective.category,
                          };
                        }),
                  icon: Icon(switch (_perspective) {
                    BudgetLimitManagerPerspective.category =>
                      Icons.account_tree_outlined,
                    BudgetLimitManagerPerspective.allocation =>
                      Icons.grid_view_rounded,
                    BudgetLimitManagerPerspective.mixed =>
                      Icons.view_carousel_outlined,
                  }),
                ),
              if (monthPage == null) _rootContextMenu(),
            ],
          ),
          body: SafeArea(
            top: false,
            child: _loadingTimeline
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      final enteringMonth =
                          child.key ==
                          const ValueKey<String>(
                            'budget-limit-manager-month-page',
                          );
                      return ClipRect(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: enteringMonth
                                ? const Offset(1, 0)
                                : const Offset(-.16, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: monthPage == null
                        ? _buildOverviewBody(snapshot, metrics)
                        : _buildMonthEditorBody(monthPage),
                  ),
          ),
        ),
      );
    },
  );

  Widget _buildOverviewBody(
    PreparedBudgetLimitSnapshot? snapshot,
    DashboardBudgetSumAnalysis? metrics,
  ) => KeyedSubtree(
    key: const ValueKey<String>('budget-limit-manager-overview-page'),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const PageStorageKey<String>(
          'budget-limit-manager-overview-scroll',
        ),
        controller: _rootScrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _usesAvatarCentricRoot
                ? <Widget>[
                    _avatarCarousel(),
                    const SizedBox(height: 14),
                    _baseEditorCard(),
                    const SizedBox(height: 10),
                    _metricsCard(metrics),
                    const SizedBox(height: 18),
                    _yearSelector(),
                    const SizedBox(height: 10),
                    _monthGrid(
                      snapshot,
                      mixed:
                          _perspective == BudgetLimitManagerPerspective.mixed,
                    ),
                  ]
                : _allocationPerspective(snapshot),
          ),
        ),
      ),
    ),
  );

  void _openMixedMonthEditor(_BudgetLimitMonthInfo info) {
    if (_aggregateHandle() == null) return;
    setState(() {
      _page = _BudgetLimitManagerMonthPage(
        year: info.year,
        month: info.month,
        originatingTargetHandle: _activeTargetHandle,
      );
    });
  }

  void _returnToOverview() {
    if (!_isMonthEditor) return;
    setState(() => _page = const _BudgetLimitManagerOverviewPage());
  }

  DashboardBudgetTargetPresentationItem? _targetVisualForHandle(int handle) {
    for (final item in widget.presentation.value.items) {
      if (item.target.handle == handle) return item;
    }
    return null;
  }

  Map<int, int> _draftsForMonth(int year, int month) =>
      Map<int, int>.unmodifiable(<int, int>{
        for (final item in _avatarItems)
          if (!_targetForHandle(item.targetHandle)!.isAggregate)
            item.targetHandle: _allocationValueFor(
              year: year,
              month: month,
              handle: item.targetHandle,
            ),
      });

  Widget _buildMonthEditorBody(_BudgetLimitManagerMonthPage page) {
    final aggregateHandle = _aggregateHandle();
    if (aggregateHandle == null) return const SizedBox.shrink();
    final aggregateRecord = _resolvedLimitRecordForHandle(
      aggregateHandle,
      page.year,
      page.month,
    );
    final partition = _partitionWithAllocationDrafts(
      partition: widget.presentation.partitionForManagerMonth(
        direction: widget.request.direction,
        year: page.year,
        month: page.month,
      ),
      year: page.year,
      month: page.month,
    );
    final entries = <BudgetLimitMixedCategoryEntry>[
      for (final item in _avatarItems)
        if (_targetForHandle(item.targetHandle)?.isAggregate == false)
          BudgetLimitMixedCategoryEntry(
            handle: item.targetHandle,
            title: item.title,
            accent: item.color,
            avatar: item.avatarFor(selected: false),
            amountScaled100: _allocationValueFor(
              year: page.year,
              month: page.month,
              handle: item.targetHandle,
            ),
            hasLimit:
                _resolvedLimitForHandle(
                  item.targetHandle,
                  page.year,
                  page.month,
                ) !=
                null,
          ),
    ];
    return KeyedSubtree(
      key: const ValueKey<String>('budget-limit-manager-month-page'),
      child: BudgetLimitMixedMonthEditor(
        key: ValueKey<String>(
          'budget-limit-mixed-month-editor-${page.year}-${page.month}',
        ),
        year: page.year,
        month: page.month,
        partition: partition,
        initialAggregateAmountScaled100: aggregateRecord == null
            ? FinancialLimitAvailability.positiveOrNull(
                partition.effectiveAggregateLimitScaled100,
              )
            : aggregateRecord.positiveAmountScaled100,
        monthlyIncomeScaled100: _monthlyIncome(
          widget.presentation.preparedSnapshotForManager,
          page.year,
          page.month,
        ),
        canUseIncomeSpec: widget.request.direction == LedgerDirection.expense,
        entries: entries,
        externalDraftAmounts: _draftsForMonth(page.year, page.month),
        initialHighlightedHandle:
            page.originatingTargetHandle == aggregateHandle
            ? null
            : page.originatingTargetHandle,
        onCategoryDraftChanged: (handle, amount) => _setAllocationDraft(
          year: page.year,
          month: page.month,
          handle: handle,
          amount: amount,
        ),
        onCommitAggregate: (amount) => _setOverrideForTarget(
          aggregateHandle,
          page.year,
          page.month,
          amount,
        ),
        onCommitCategory: (handle, amount) =>
            _setOverrideForTarget(handle, page.year, page.month, amount),
        onOpenCategoryDetail: (handle) => _showCategoryMonthSheetForHandle(
          year: page.year,
          month: page.month,
          targetHandle: handle,
          managesSheetOpenState: true,
          onDraftChanged: (amount) => _setAllocationDraft(
            year: page.year,
            month: page.month,
            handle: handle,
            amount: amount,
          ),
        ),
        resolvedCategoryAmount: (handle) => _allocationValueFor(
          year: page.year,
          month: page.month,
          handle: handle,
        ),
      ),
    );
  }

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
                    deleteLabel: 'Alap havi Budget törlése',
                    onDelete: () => _setNoBaseForTarget(aggregateHandle),
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
              onTap: () => setState(() {
                _allocationActiveCategoryHandle = item.target.handle;
                _allocationActiveCategoryStableId =
                    'category:${item.target.category!.id}';
              }),
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
              deleteLabel: _activeTarget.isAggregate
                  ? 'Alap havi Budget törlése'
                  : 'Alap kategórialimit törlése',
              onDelete: () => _setNoBaseForTarget(_activeTargetHandle),
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

  Widget _monthGrid(
    PreparedBudgetLimitSnapshot? snapshot, {
    required bool mixed,
  }) => GridView.builder(
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
        onTap: _carouselInMotion
            ? null
            : () => mixed ? _openMixedMonthEditor(info) : _showMonthSheet(info),
      );
    },
  );

  _BudgetLimitMonthInfo _monthInfo(
    PreparedBudgetLimitSnapshot? snapshot,
    int year,
    int month,
  ) => _monthInfoForTarget(snapshot, year, month, _activeTargetHandle);

  _BudgetLimitMonthInfo _monthInfoForTarget(
    PreparedBudgetLimitSnapshot? snapshot,
    int year,
    int month,
    int targetHandle,
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
        targetHandle: targetHandle,
      );
    }
    final override = _overrideForTargetHandle(targetHandle, year, month);
    final timelineRecord = _resolvedLimitRecordForHandle(
      targetHandle,
      year,
      month,
    );
    // A timeline record with amount zero is a deliberate no-limit override
    // or revision. Only a missing timeline record may use the still-prepared
    // snapshot as a loading fallback.
    final limit = timelineRecord == null
        ? FinancialLimitAvailability.positiveOrNull(cell?.limitScaled100)
        : timelineRecord.positiveAmountScaled100;
    final actual = cell?.actualScaled100;
    return _BudgetLimitMonthInfo(
      year: year,
      month: month,
      resolvedLimitScaled100: limit,
      historicalBaseScaled100: _baseForTargetHandle(
        targetHandle,
        year,
        month,
      )?.positiveAmountScaled100,
      actualScaled100: actual,
      isCurrent: isCurrent,
      isFuture: isFuture,
      hasOverride: override != null,
    );
  }

  void _onAvatarPreview(int logicalIndex) {
    if (_avatarItems.isEmpty) return;
    final item =
        _avatarItems[budgetTargetAvatarCarouselModulo(
          logicalIndex,
          _avatarItems.length,
        )];
    final targetHandle = item.targetHandle;
    if (targetHandle == _activeTargetHandle) return;
    if (_monthSheetOpen) {
      _monthSheetOpen = false;
      Navigator.of(context).maybePop();
    }
    setState(() {
      _activeTargetHandle = targetHandle;
      _activeTargetStableId = item.stableId;
    });
  }

  void _onAvatarSettled(int logicalIndex) {
    if (_avatarItems.isEmpty) return;
    final item =
        _avatarItems[budgetTargetAvatarCarouselModulo(
          logicalIndex,
          _avatarItems.length,
        )];
    final targetHandle = item.targetHandle;
    setState(() {
      _activeTargetHandle = targetHandle;
      _activeTargetStableId = item.stableId;
      _carouselInMotion = false;
    });
  }

  /// The root overflow belongs to the active avatar first. Global category
  /// navigation is intentionally one compact submenu below those actions.
  Widget _rootContextMenu() => MenuAnchor(
    style: _contextMenuStyle,
    alignmentOffset: const Offset(-8, 6),
    menuChildren: <Widget>[
      if (_activeManagedCategory case final category?) ...[
        if (!category.isSystemUncategorized)
          MenuItemButton(
            key: const ValueKey<String>('budget-limit-menu-category-edit'),
            onPressed: () => _showCategoryEditor(category: category),
            child: const Text('Kategória módosítása'),
          ),
        if (!category.isSystemUncategorized)
          MenuItemButton(
            key: const ValueKey<String>('budget-limit-menu-category-delete'),
            onPressed: () => _confirmCategoryDelete(category),
            child: const Text('Kategória törlése'),
          ),
      ] else
        MenuItemButton(
          key: const ValueKey<String>('budget-limit-menu-base-edit'),
          onPressed: () => _showAmountEditor(
            title: 'Alap havi Budget',
            initial: _currentBase ?? 0,
            onSave: _setBase,
            deleteLabel: 'Alap havi Budget törlése',
            onDelete: () => _setNoBaseForTarget(_activeTargetHandle),
          ),
          child: const Text('Alap havi Budget szerkesztése'),
        ),
      MenuItemButton(
        key: const ValueKey<String>('budget-limit-menu-base-delete'),
        onPressed: () => _setNoBaseForTarget(_activeTargetHandle),
        child: Text(
          _activeTarget.isAggregate
              ? 'Alap havi Budget törlése'
              : 'Alap kategórialimit törlése',
        ),
      ),
      const Divider(),
      _categoriesSubmenu(
        key: const ValueKey<String>('budget-limit-menu-categories'),
        onCategorySelected: _selectTargetFromMenu,
      ),
    ],
    builder: (context, controller, _) => IconButton(
      key: const ValueKey<String>('budget-limit-manager-more'),
      tooltip: 'További műveletek',
      onPressed: _monthSheetOpen
          ? null
          : () => controller.isOpen ? controller.close() : controller.open(),
      icon: const Icon(Icons.more_vert_rounded),
    ),
  );

  Widget _monthContextMenu(_BudgetLimitManagerMonthPage page) {
    final aggregateHandle = _aggregateHandle();
    final hasOverride =
        aggregateHandle != null &&
        _overrideForTargetHandle(aggregateHandle, page.year, page.month) !=
            null;
    return MenuAnchor(
      style: _contextMenuStyle,
      alignmentOffset: const Offset(-8, 6),
      menuChildren: <Widget>[
        if (aggregateHandle != null)
          MenuItemButton(
            key: const ValueKey<String>('budget-limit-month-menu-delete'),
            onPressed: () => _setNoMonthLimitForTarget(
              aggregateHandle,
              page.year,
              page.month,
            ),
            child: const Text('Havi Budget törlése'),
          ),
        if (aggregateHandle != null && hasOverride)
          MenuItemButton(
            key: const ValueKey<String>('budget-limit-month-menu-reset'),
            onPressed: () => _deleteOverrideForTarget(
              aggregateHandle,
              page.year,
              page.month,
            ),
            child: const Text('Vissza az alap Budgethez'),
          ),
        const Divider(),
        _categoriesSubmenu(
          key: const ValueKey<String>('budget-limit-month-menu-categories'),
          onCategorySelected: (handle) => _showCategoryMonthSheetForHandle(
            year: page.year,
            month: page.month,
            targetHandle: handle,
            managesSheetOpenState: true,
          ),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const ValueKey<String>('budget-limit-manager-month-more'),
        tooltip: 'További műveletek',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_vert_rounded),
      ),
    );
  }

  SubmenuButton _categoriesSubmenu({
    required Key key,
    required ValueChanged<int> onCategorySelected,
  }) => SubmenuButton(
    key: key,
    menuStyle: _contextMenuStyle,
    menuChildren: <Widget>[
      if (_canManageCategories)
        MenuItemButton(
          key: const ValueKey<String>('budget-limit-menu-category-create'),
          onPressed: () => _showCategoryEditor(),
          child: const Text('+ Új kategória'),
        ),
      if (_canManageCategories)
        MenuItemButton(
          key: const ValueKey<String>('budget-limit-menu-category-manage'),
          onPressed: _showCategoryManager,
          child: const Text('Kategóriák kezelése…'),
        ),
      if (_canManageCategories) const Divider(),
      for (final item in _avatarItems)
        if (!_targetForHandle(item.targetHandle)!.isAggregate)
          MenuItemButton(
            key: ValueKey<String>(
              'budget-limit-menu-category-${item.targetHandle}',
            ),
            onPressed: () => onCategorySelected(item.targetHandle),
            trailingIcon: item.targetHandle == _activeTargetHandle
                ? const Icon(Icons.check_rounded, size: 18)
                : null,
            child: Text(item.title),
          ),
    ],
    child: const Text('Kategóriák'),
  );

  FluviCategory? get _activeManagedCategory {
    final categoryId = _activeTarget.category?.id;
    if (categoryId == null) return null;
    for (final category
        in widget.categoryCollection?.value ?? const <FluviCategory>[]) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  void _selectTargetFromMenu(int targetHandle) {
    final index = _avatarItems.indexWhere(
      (item) => item.targetHandle == targetHandle,
    );
    if (index < 0) return;
    setState(() {
      _activeTargetHandle = targetHandle;
      _activeTargetStableId = _avatarItems[index].stableId;
    });
    unawaited(_avatarCarouselController.animateToIndex(index));
  }

  Future<void> _showCategoryEditor({FluviCategory? category}) async {
    final repository = widget.categoryRepository;
    if (repository == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 240),
        reverseDuration: Duration(milliseconds: 200),
      ),
      builder: (_) => Material(
        color: Colors.white,
        child: _BudgetCategoryEditorSheet(
          category: category,
          repository: repository,
          onCreated: _onManagerCategoryCreated,
        ),
      ),
    );
  }

  Future<void> _confirmCategoryDelete(FluviCategory category) async {
    final repository = widget.categoryRepository;
    if (repository == null || category.isSystemUncategorized) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategória törlése?'),
        content: Text(
          'A „${category.name}” kategória tranzakciói és kapcsolódó '
          'referenciái az Egyéb kategóriába kerülnek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffc9465c),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      await repository.deleteCategory(category.id);
      _onManagerCategoryDeleted(category.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A kategória törlése nem sikerült.')),
      );
    }
  }

  Future<void> _showAmountEditor({
    required String title,
    required int initial,
    required Future<void> Function(int amount) onSave,
    String? deleteLabel,
    Future<void> Function()? onDelete,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 240),
      reverseDuration: Duration(milliseconds: 200),
    ),
    builder: (_) => Material(
      color: Colors.white,
      child: _BudgetLimitAmountEditorSheet(
        title: title,
        initial: initial,
        onSave: onSave,
        deleteLabel: deleteLabel,
        onDelete: onDelete,
      ),
    ),
  );

  bool get _canManageCategories =>
      widget.categoryRepository != null && widget.categoryCollection != null;

  void _onManagerCategoryCreated(FluviCategory category) {
    if (!mounted) return;
    setState(() {
      _categoryIdToSelectAfterCollectionUpdate = category.id;
      final index = _avatarItems.indexWhere(
        (item) => item.stableId == 'category:${category.id}',
      );
      if (index >= 0) {
        _activeTargetStableId = _avatarItems[index].stableId;
        _activeTargetHandle = _avatarItems[index].targetHandle;
        _categoryIdToSelectAfterCollectionUpdate = null;
      }
      _allocationActiveCategoryStableId = 'category:${category.id}';
      _allocationActiveCategoryHandle = null;
    });
  }

  void _onManagerCategoryDeleted(String categoryId) {
    if (!mounted) return;
    setState(() {
      if (_activeTargetStableId == 'category:$categoryId') {
        _activeTargetStableId = 'aggregate';
        _activeTargetHandle = 0;
      }
      if (_allocationActiveCategoryStableId == 'category:$categoryId') {
        _allocationActiveCategoryStableId = null;
        _allocationActiveCategoryHandle = null;
      }
    });
  }

  Future<void> _showCategoryManager() async {
    final repository = widget.categoryRepository;
    final categories = widget.categoryCollection;
    if (repository == null || categories == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 240),
        reverseDuration: Duration(milliseconds: 200),
      ),
      builder: (_) => Material(
        color: Colors.white,
        child: _BudgetCategoryManagementSheet(
          categories: categories,
          repository: repository,
          onCategoryCreated: _onManagerCategoryCreated,
          onCategoryDeleted: _onManagerCategoryDeleted,
        ),
      ),
    );
  }

  Future<void> _showMonthSheet(_BudgetLimitMonthInfo info) async {
    await _showCategoryMonthSheetForHandle(
      year: info.year,
      month: info.month,
      targetHandle: _activeTargetHandle,
      managesSheetOpenState: true,
    );
  }

  Future<void> _showCategoryMonthSheetForHandle({
    required int year,
    required int month,
    required int targetHandle,
    required bool managesSheetOpenState,
    ValueChanged<int>? onDraftChanged,
  }) async {
    final target = _targetForHandle(targetHandle);
    if (target == null) return;
    final info = _monthInfoForTarget(
      widget.presentation.preparedSnapshotForManager,
      year,
      month,
      targetHandle,
    );
    BudgetTargetAvatarCarouselItem? item;
    for (final candidate in _avatarItems) {
      if (candidate.targetHandle == targetHandle) {
        item = candidate;
        break;
      }
    }
    final partition = _partitionWithAllocationDrafts(
      partition: widget.presentation.partitionForManagerMonth(
        direction: widget.request.direction,
        year: info.year,
        month: info.month,
      ),
      year: info.year,
      month: info.month,
    );
    if (managesSheetOpenState) _monthSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 240),
          reverseDuration: Duration(milliseconds: 200),
        ),
        builder: (sheetContext) => Material(
          color: Colors.white,
          child: _BudgetLimitMonthSheet(
            info: info,
            accent: item?.color ?? _accent,
            targetHandle: targetHandle,
            targetTitle: item?.title ?? _title,
            targetIsAggregate: target.isAggregate,
            partition: partition,
            snapshot: widget.presentation.preparedSnapshotForManager,
            direction: widget.request.direction,
            logicalAsOfDate: _logicalDate,
            targetVisual: _targetVisualForHandle(targetHandle),
            onCommitSliderLimit: (amount) => _setOverrideForTarget(
              targetHandle,
              info.year,
              info.month,
              amount,
            ),
            onSaveExplicitLimit: (amount) async {
              await _setOverrideForTarget(
                targetHandle,
                info.year,
                info.month,
                amount,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
            onSetNoLimit: () async {
              onDraftChanged?.call(0);
              await _setNoMonthLimitForTarget(
                targetHandle,
                info.year,
                info.month,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
            onResetToBase: () async {
              await _deleteOverrideForTarget(
                targetHandle,
                info.year,
                info.month,
              );
              onDraftChanged?.call(
                _resolvedLimitForHandle(targetHandle, info.year, info.month) ??
                    0,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
            onDraftChanged: onDraftChanged,
          ),
        ),
      );
    } finally {
      if (managesSheetOpenState) _monthSheetOpen = false;
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 240),
          reverseDuration: Duration(milliseconds: 200),
        ),
        builder: (_) => Material(
          color: Colors.white,
          child: _BudgetLimitAllocationMonthSheet(
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
                : (amount) => _setOverrideForTarget(
                    aggregateHandle,
                    year,
                    month,
                    amount,
                  ),
          ),
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

String _stableIdForTarget(DashboardBudgetTarget target) =>
    switch (target.identity) {
      DashboardBudgetAggregateTarget() => 'aggregate',
      DashboardBudgetCategoryTarget(:final categoryId) =>
        'category:$categoryId',
    };

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
        existing.title != candidate.title ||
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
    this.deleteLabel,
    this.onDelete,
  });

  final String title;
  final int initial;
  final Future<void> Function(int amount) onSave;
  final String? deleteLabel;
  final Future<void> Function()? onDelete;

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
        if (widget.onDelete case final onDelete?) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey<String>('budget-limit-amount-sheet-delete'),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await onDelete();
              if (mounted) navigator.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffc24860),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(widget.deleteLabel ?? 'Alaplimit törlése'),
          ),
        ],
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
    required this.snapshot,
    required this.direction,
    required this.logicalAsOfDate,
    required this.targetVisual,
    required this.onCommitSliderLimit,
    required this.onSaveExplicitLimit,
    required this.onSetNoLimit,
    required this.onResetToBase,
    this.onDraftChanged,
  });

  final _BudgetLimitMonthInfo info;
  final Color accent;
  final int targetHandle;
  final String targetTitle;
  final bool targetIsAggregate;
  final DashboardBudgetPartitionPresentation partition;
  final PreparedBudgetLimitSnapshot? snapshot;
  final LedgerDirection direction;
  final LocalDate logicalAsOfDate;
  final DashboardBudgetTargetPresentationItem? targetVisual;

  /// Slider release persists but intentionally keeps this secondary sheet
  /// open for continued direct manipulation.
  final Future<void> Function(int) onCommitSliderLimit;

  /// The explicit keyboard/form save is a different interaction: it commits
  /// then closes the sheet at its owner boundary.
  final Future<void> Function(int) onSaveExplicitLimit;
  final Future<void> Function() onSetNoLimit;
  final Future<void> Function() onResetToBase;
  final ValueChanged<int>? onDraftChanged;

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
    widget.onDraftChanged?.call(_sliderDraftScaled100);
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
    final available =
        ((widget.partition.effectiveAggregateLimitScaled100 ?? 0) -
                otherAllocated)
            .clamp(0, 0x7fffffffffffffff)
            .toInt();
    return _sliderDraftScaled100 > available
        ? _sliderDraftScaled100
        : available;
  }

  DashboardBudgetMonthSecondaryAnalysis? get _analysis {
    final snapshot = widget.snapshot;
    if (snapshot == null) return null;
    return DashboardBudgetSecondaryAnalysisProjector.projectMonthWithLimitDraft(
      snapshot: snapshot,
      direction: widget.direction,
      targetHandle: widget.targetHandle,
      year: widget.info.year,
      month: widget.info.month,
      logicalAsOfDate: widget.logicalAsOfDate,
      limitScaled100: _sliderDraftScaled100 > 0 ? _sliderDraftScaled100 : null,
    );
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
    widget.onDraftChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final slider = CategoryLimitSliderPresentation.resolve(
      actualScaled100: info.actualScaled100 ?? 0,
      limitScaled100: _sliderDraftScaled100,
      maxScaled100: _categorySliderMaxScaled100,
    );
    final analysis = _analysis;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.targetTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${_monthLongName(info.month)} ${info.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff6a768c),
                      ),
                    ),
                  ],
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
                  _formatAmount(
                    _sliderDraftScaled100 > 0 ? _sliderDraftScaled100 : null,
                  ),
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
          if (info.historicalBaseScaled100 != null && info.hasOverride)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'Alap havi keret: ${_formatAmount(info.historicalBaseScaled100)}',
                style: const TextStyle(fontSize: 12, color: Color(0xff6a768c)),
              ),
            ),
          const SizedBox(height: 10),
          if (!widget.targetIsAggregate)
            CategoryLimitAllocationProgressSlider(
              key: const ValueKey<String>(
                'budget-limit-category-progress-slider',
              ),
              presentation: slider,
              accent: widget.accent,
              enabled: slider.hasCapacity || _sliderDraftScaled100 > 0,
              onChanged: _setSliderDraft,
              onChangeEnd: widget.onCommitSliderLimit,
            ),
          const SizedBox(height: 4),
          _CategorySliderLabels(presentation: slider, future: info.isFuture),
          if (_isEditing) ...[
            const SizedBox(height: 16),
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
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await widget.onSaveExplicitLimit(_overrideDraftScaled100);
              },
              child: const Text('Egyedi keret mentése'),
            ),
          ],
          const SizedBox(height: 18),
          _CategoryMonthAnalysisBox(
            analysis: analysis,
            info: info,
            direction: widget.direction,
            targetVisual: widget.targetVisual,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            key: const ValueKey<String>('budget-limit-month-sheet-delete'),
            onPressed: widget.onSetNoLimit,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffc24860),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              widget.targetIsAggregate
                  ? 'Havi Budget törlése'
                  : 'Kategórialimit törlése',
            ),
          ),
          if (info.hasOverride)
            TextButton(
              key: const ValueKey<String>('budget-limit-month-sheet-reset'),
              onPressed: widget.onResetToBase,
              child: const Text('Vissza az alapértékhez'),
            ),
        ],
      ),
    );
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

final class _CategorySliderLabels extends StatelessWidget {
  const _CategorySliderLabels({
    required this.presentation,
    required this.future,
  });

  final CategoryLimitSliderPresentation presentation;
  final bool future;

  @override
  Widget build(BuildContext context) {
    if (future) {
      return const Text(
        'Még nincs költés ebben a hónapban',
        style: TextStyle(fontSize: 12, color: Color(0xff68758e)),
      );
    }
    final overspent = presentation.isOverspent;
    final right = overspent
        ? '${_formatAmount(presentation.overspendScaled100)} túllépés'
        : '${_formatAmount(presentation.remainingAllocatedScaled100)} maradt';
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_formatAmount(presentation.actualScaled100)} elköltve',
            style: const TextStyle(fontSize: 12, color: Color(0xff68758e)),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: overspent
                ? const Color(0xffc24860)
                : const Color(0xff68758e),
          ),
        ),
      ],
    );
  }
}

final class _CategoryMonthAnalysisBox extends StatelessWidget {
  const _CategoryMonthAnalysisBox({
    required this.analysis,
    required this.info,
    required this.direction,
    required this.targetVisual,
  });

  final DashboardBudgetMonthSecondaryAnalysis? analysis;
  final _BudgetLimitMonthInfo info;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;

  @override
  Widget build(BuildContext context) {
    final value = analysis;
    return KeyedSubtree(
      key: const ValueKey<String>('budget-limit-category-analysis-box'),
      child: value == null || info.isFuture
          ? const _CategoryMonthAnalysisUnavailable(
              message: 'a hónap még nem kezdődött el',
            )
          : !value.isAvailable || value.budgetUsedRatio == null
          ? const _CategoryMonthAnalysisUnavailable(
              message: 'nincs beállított havi keret',
            )
          : _CategoryMonthAnalysisAvailable(
              analysis: value,
              direction: direction,
              targetVisual: targetVisual,
              historical: info.isClosed,
            ),
    );
  }
}

final class _CategoryMonthAnalysisUnavailable extends StatelessWidget {
  const _CategoryMonthAnalysisUnavailable({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 218,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '—',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: Color(0xff68758e))),
      ],
    ),
  );
}

final class _CategoryMonthAnalysisAvailable extends StatelessWidget {
  const _CategoryMonthAnalysisAvailable({
    required this.analysis,
    required this.direction,
    required this.targetVisual,
    required this.historical,
  });

  final DashboardBudgetMonthSecondaryAnalysis analysis;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;
  final bool historical;

  @override
  Widget build(BuildContext context) {
    final values = historical
        ? <_CategoryAnalysisKpi>[
            _CategoryAnalysisKpi(
              'Záró összeg',
              _formatAmount(analysis.monthActualScaled100),
            ),
            _CategoryAnalysisKpi(
              'Záró eltérés',
              _formatSignedAmount(analysis.closingBudgetDeltaScaled100),
              valueColor: _historicalDeltaColor(
                direction,
                analysis.closingBudgetDeltaScaled100,
              ),
            ),
            _CategoryAnalysisKpi(
              'Napi átlag',
              _formatAmount(analysis.historicalDailyAverageScaled100),
            ),
          ]
        : <_CategoryAnalysisKpi>[
            _CategoryAnalysisKpi(
              'Várható zárás',
              _formatAmount(analysis.projectedMonthEndScaled100),
            ),
            _CategoryAnalysisKpi(
              'Várható eltérés',
              _formatSignedAmount(analysis.expectedDeltaScaled100),
              valueColor: _forecastDeltaColor(
                direction,
                analysis.expectedDeltaScaled100,
              ),
            ),
            _CategoryAnalysisKpi(
              'Napi mozgástér',
              _formatAmount(analysis.remainingDailyRoomScaled100),
            ),
          ];
    return Column(
      children: [
        SizedBox(
          key: const ValueKey<String>(
            'budget-limit-category-month-semicircle-viewport',
          ),
          height: 190,
          child: BudgetMonthUtilizationHero(
            key: const ValueKey<String>(
              'budget-limit-category-month-semicircle',
            ),
            analysis: analysis,
            direction: direction,
            targetVisual: targetVisual,
            gaugeKey: const ValueKey<String>(
              'budget-limit-category-month-gauge',
            ),
          ),
        ),
        const Divider(height: 18, color: Color(0xffe4e8f0)),
        Row(
          children: [
            for (var index = 0; index < values.length; index += 1) ...[
              if (index > 0)
                const SizedBox(
                  height: 30,
                  child: VerticalDivider(color: Color(0xffe4e8f0)),
                ),
              Expanded(child: _CategoryAnalysisKpiCell(values[index])),
            ],
          ],
        ),
      ],
    );
  }

  Color? _historicalDeltaColor(LedgerDirection direction, int? delta) {
    if (delta == null || delta == 0) return null;
    final positiveIsHealthy = direction == LedgerDirection.expense;
    final healthy = (delta > 0) == positiveIsHealthy;
    return healthy ? const Color(0xff288e6e) : const Color(0xffc24860);
  }

  Color? _forecastDeltaColor(LedgerDirection direction, int? delta) {
    if (delta == null || delta == 0) return null;
    // Forecast delta is projected - limit, whereas the closed value above is
    // limit - actual. Keep the expense meaning truthful in both displays.
    final positiveIsHealthy = direction == LedgerDirection.income;
    final healthy = (delta > 0) == positiveIsHealthy;
    return healthy ? const Color(0xff288e6e) : const Color(0xffc24860);
  }
}

@immutable
final class _CategoryAnalysisKpi {
  const _CategoryAnalysisKpi(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

final class _CategoryAnalysisKpiCell extends StatelessWidget {
  const _CategoryAnalysisKpiCell(this.kpi);
  final _CategoryAnalysisKpi kpi;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kpi.label,
          style: const TextStyle(fontSize: 9, color: Color(0xff68758e)),
        ),
        const SizedBox(height: 3),
        Text(
          kpi.value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: kpi.valueColor,
          ),
        ),
      ],
    ),
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

/// Manager-local CRUD shell over the app's one category collection and one
/// native [CategoryRepository]. It intentionally contains no copied catalog,
/// cache, or category persistence state: collection changes flow back through
/// the root controller and naturally refresh the manager carousel.
final class _BudgetCategoryManagementSheet extends StatelessWidget {
  const _BudgetCategoryManagementSheet({
    required this.categories,
    required this.repository,
    required this.onCategoryCreated,
    required this.onCategoryDeleted,
  });

  final ValueListenable<List<FluviCategory>> categories;
  final CategoryRepository repository;
  final ValueChanged<FluviCategory> onCategoryCreated;
  final ValueChanged<String> onCategoryDeleted;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .82,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategóriák kezelése',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Név, szín és ikon',
                      style: TextStyle(fontSize: 12, color: Color(0xff68758e)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('budget-category-create'),
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Új'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<List<FluviCategory>>(
              valueListenable: categories,
              builder: (context, values, _) {
                if (values.isEmpty) {
                  return const Center(
                    child: Text('Még nincs kezelhető kategória.'),
                  );
                }
                return ListView.separated(
                  key: const ValueKey<String>('budget-category-manager-list'),
                  itemCount: values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final category = values[index];
                    return _BudgetCategoryManagementRow(
                      category: category,
                      onEdit: category.isSystemUncategorized
                          ? null
                          : () => _showEditor(context, category: category),
                      onDelete: category.isSystemUncategorized
                          ? null
                          : () => _confirmDelete(context, category),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showEditor(
    BuildContext context, {
    FluviCategory? category,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 240),
        reverseDuration: Duration(milliseconds: 200),
      ),
      builder: (_) => Material(
        color: Colors.white,
        child: _BudgetCategoryEditorSheet(
          category: category,
          repository: repository,
          onCreated: onCategoryCreated,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FluviCategory category,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategória törlése?'),
        content: Text(
          'A „${category.name}” kategória tranzakciói és kapcsolódó '
          'referenciái az Egyéb kategóriába kerülnek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            key: ValueKey<String>(
              'budget-category-delete-confirm-${category.id}',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffc9465c),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      await repository.deleteCategory(category.id);
      onCategoryDeleted(category.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A kategória törlése nem sikerült.')),
      );
    }
  }
}

final class _BudgetCategoryManagementRow extends StatelessWidget {
  const _BudgetCategoryManagementRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final FluviCategory category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey<String>('budget-category-row-${category.id}'),
    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
    decoration: BoxDecoration(
      color: const Color(0xfffbfcff),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffe3e7ef)),
    ),
    child: Row(
      children: [
        _BudgetCategoryVisualPreview(
          colorId: category.colorId,
          iconId: category.iconId,
          size: 38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                category.isSystemUncategorized
                    ? 'Rendszerkategória'
                    : 'Kategória',
                style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            key: ValueKey<String>('budget-category-edit-${category.id}'),
            tooltip: 'Kategória szerkesztése',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        if (onDelete != null)
          IconButton(
            key: ValueKey<String>('budget-category-delete-${category.id}'),
            tooltip: 'Kategória törlése',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Color(0xffc9465c),
            ),
          ),
      ],
    ),
  );
}

/// One editor implementation for both category creation and visual/name
/// changes. Its selections are catalog IDs, never a locally invented visual
/// representation.
final class _BudgetCategoryEditorSheet extends StatefulWidget {
  const _BudgetCategoryEditorSheet({
    required this.category,
    required this.repository,
    required this.onCreated,
  });

  final FluviCategory? category;
  final CategoryRepository repository;
  final ValueChanged<FluviCategory> onCreated;

  @override
  State<_BudgetCategoryEditorSheet> createState() =>
      _BudgetCategoryEditorSheetState();
}

final class _BudgetCategoryEditorSheetState
    extends State<_BudgetCategoryEditorSheet> {
  late final TextEditingController _name;
  late String _colorId;
  late String _iconId;
  String? _error;
  bool _saving = false;

  bool get _isCreate => widget.category == null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _colorId = category?.colorId ?? CategoryCatalogIds.colorIds.first;
    _iconId = category?.iconId ?? CategoryCatalogIds.iconIds.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Adj meg egy kategórianevet.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final category = widget.category;
      final saved = category == null
          ? await widget.repository.createCategory(
              name: name,
              colorId: _colorId,
              iconId: _iconId,
            )
          : await widget.repository.updateCategory(
              id: category.id,
              name: name,
              colorId: _colorId,
              iconId: _iconId,
            );
      if (!mounted) return;
      if (_isCreate) widget.onCreated(saved);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'A kategória mentése nem sikerült. Ellenőrizd a nevet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isCreate ? 'Új kategória' : 'Kategória szerkesztése',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Center(
          child: _BudgetCategoryVisualPreview(
            colorId: _colorId,
            iconId: _iconId,
            size: 76,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey<String>('budget-category-name-input'),
          controller: _name,
          autofocus: _isCreate,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Kategória neve',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 20),
        const Text('Szín', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final colorId in CategoryCatalogIds.colorIds)
              _BudgetCategoryColorChoice(
                colorId: colorId,
                selected: colorId == _colorId,
                onTap: () => setState(() => _colorId = colorId),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SizedBox(
          height: 206,
          child: GridView.builder(
            key: const ValueKey<String>('budget-category-icon-grid'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: CategoryCatalogIds.iconIds.length,
            itemBuilder: (context, index) {
              final iconId = CategoryCatalogIds.iconIds[index];
              return _BudgetCategoryIconChoice(
                iconId: iconId,
                colorId: _colorId,
                selected: iconId == _iconId,
                onTap: () => setState(() => _iconId = iconId),
              );
            },
          ),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Color(0xffc9465c))),
        ],
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey<String>('budget-category-save'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Mentés…' : 'Mentés'),
        ),
      ],
    ),
  );
}

final class _BudgetCategoryColorChoice extends StatelessWidget {
  const _BudgetCategoryColorChoice({
    required this.colorId,
    required this.selected,
    required this.onTap,
  });

  final String colorId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = CategoryColorCatalog.resolve(colorId);
    return Semantics(
      selected: selected,
      label: 'Szín ${token.id}',
      child: InkWell(
        key: ValueKey<String>('budget-category-color-$colorId'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: token.gradient,
            border: Border.all(
              color: selected ? const Color(0xff18233d) : Colors.white,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

final class _BudgetCategoryIconChoice extends StatelessWidget {
  const _BudgetCategoryIconChoice({
    required this.iconId,
    required this.colorId,
    required this.selected,
    required this.onTap,
  });

  final String iconId;
  final String colorId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = CategoryIconCatalog.resolve(iconId);
    final color = CategoryColorCatalog.resolve(colorId).middleColor;
    return Semantics(
      selected: selected,
      label: '${token.semanticName} ikon',
      child: InkWell(
        key: ValueKey<String>('budget-category-icon-$iconId'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .18) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xffe1e6ef),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: PreparedVectorAssetAtlas.instance.isReady
                ? CategoryIconView(
                    picture: PreparedVectorAssetAtlas.instance.categoryIcon(
                      CategoryIconCatalog.handleOf(iconId),
                    ),
                    size: 20,
                    color: color,
                  )
                : Icon(Icons.category_rounded, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

final class _BudgetCategoryVisualPreview extends StatelessWidget {
  const _BudgetCategoryVisualPreview({
    required this.colorId,
    required this.iconId,
    required this.size,
  });

  final String colorId;
  final String iconId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final token = CategoryColorCatalog.resolve(colorId);
    return Semantics(
      label: 'Kategória előnézet',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: token.gradient,
          boxShadow: [
            BoxShadow(
              color: token.middleColor.withValues(alpha: .22),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: PreparedVectorAssetAtlas.instance.isReady
              ? CategoryIconView(
                  picture: PreparedVectorAssetAtlas.instance.categoryIcon(
                    CategoryIconCatalog.handleOf(iconId),
                  ),
                  size: size * .45,
                  color: Colors.white,
                )
              : Icon(
                  Icons.category_rounded,
                  size: size * .45,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
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

String _formatSignedAmount(int? scaled100) {
  if (scaled100 == null) return '—';
  if (scaled100 == 0) return _formatAmount(0);
  return '${scaled100 > 0 ? '+' : '−'}${_formatAmount(scaled100.abs())}';
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
