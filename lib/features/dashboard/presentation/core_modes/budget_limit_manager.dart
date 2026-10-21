import 'package:flutter/material.dart';

import '../../../../core/financial_limits/domain/financial_limit.dart';
import '../../../../core/financial_limits/domain/financial_limit_resolution.dart';
import '../../../dashboard/application/dashboard_budget_limit_edit_controller.dart';
import '../../../dashboard/application/dashboard_budget_presentation_controller.dart';
import '../../../dashboard/application/dashboard_budget_secondary_analysis.dart';
import '../../../dashboard/application/dashboard_budget_target.dart';
import '../../query/domain/ledger_direction.dart';
import '../../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';

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
/// dashboard's immutable prepared bank for visuals; the one timeline read on
/// open exists only to distinguish historical base revisions from overrides.
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

final class _BudgetLimitManagerState extends State<BudgetLimitManager> {
  late int _year;
  List<FinancialLimit> _timeline = const <FinancialLimit>[];
  bool _loadingTimeline = true;

  FinancialLimitDirection get _direction => switch (widget.request.direction) {
    LedgerDirection.income => FinancialLimitDirection.income,
    LedgerDirection.expense => FinancialLimitDirection.expense,
  };

  FinancialLimitTarget get _target => widget.request.target.isAggregate
      ? const FinancialLimitAggregateTarget()
      : FinancialLimitCategoryTarget(widget.request.target.category!.id);

  LocalDate get _logicalDate => widget.presentation.logicalAsOfDateForManager;

  @override
  void initState() {
    super.initState();
    _year = _logicalDate.year;
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final values = await widget.limitEdits.loadLimitTimeline(
      direction: _direction,
      target: _target,
    );
    if (!mounted) return;
    setState(() {
      _timeline = values;
      _loadingTimeline = false;
    });
  }

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

  void _replaceLocal(FinancialLimit limit) {
    setState(() {
      _timeline = <FinancialLimit>[
        for (final current in _timeline)
          if (current.key != limit.key) current,
        limit,
      ];
    });
  }

  void _removeLocal(FinancialLimitKey key) {
    setState(() {
      _timeline = <FinancialLimit>[
        for (final current in _timeline)
          if (current.key != key) current,
      ];
    });
  }

  Future<void> _setBase(int amount) async {
    // Capture the prepared/current value before the manager's optimistic
    // timeline replaces it.  The shared write coordinator needs that value
    // for a correct later reconciliation of this exact revision key.
    final confirmedBase = _currentBase;
    final period = FinancialLimitBaseMonthlyRevisionPeriod(
      _logicalDate.year,
      _logicalDate.month,
    );
    final key = FinancialLimitKey(
      direction: _direction,
      target: _target,
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
      target: _target,
      effectiveFromYear: _logicalDate.year,
      effectiveFromMonth: _logicalDate.month,
      coreRevision:
          widget.presentation.preparedSnapshotForManager?.coreRevision ??
          widget.request.coreRevision,
      targetHandle: widget.request.targetHandle,
      confirmedLimitScaled100: confirmedBase,
      amountScaled100: amount,
    );
  }

  Future<void> _setOverride(int year, int month, int amount) async {
    final key = FinancialLimitKey(
      direction: _direction,
      target: _target,
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
      target: _target,
      year: year,
      month: month,
      coreRevision: snapshot?.coreRevision ?? widget.request.coreRevision,
      targetHandle: widget.request.targetHandle,
      confirmedLimitScaled100: snapshot
          ?.cellAt(
            direction: widget.request.direction,
            period: BudgetLimitPeriod.month(year, month),
            targetHandle: widget.request.targetHandle,
          )
          .limitScaled100,
      amountScaled100: amount,
    );
  }

  Future<void> _deleteOverride(int year, int month) async {
    final key = FinancialLimitKey(
      direction: _direction,
      target: _target,
      period: FinancialLimitMonthOverridePeriod(year, month),
    );
    _removeLocal(key);
    await widget.limitEdits.deleteMonthOverride(
      direction: _direction,
      target: _target,
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
              targetHandle: widget.request.targetHandle,
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
                widget.request.title,
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
                        children: [
                          Center(child: _avatar()),
                          const SizedBox(height: 14),
                          _baseEditorCard(),
                          const SizedBox(height: 10),
                          _metricsCard(metrics),
                          const SizedBox(height: 18),
                          _yearSelector(),
                          const SizedBox(height: 10),
                          _monthGrid(snapshot),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );

  Widget _avatar() => SizedBox.square(
    key: const ValueKey<String>('budget-limit-manager-avatar'),
    dimension: 72,
    child: widget.request.avatar,
  );

  Widget _baseEditorCard() => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const ValueKey<String>('budget-limit-manager-base-editor'),
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showAmountEditor(
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
            colors: <Color>[
              Colors.white,
              widget.request.accent.withValues(alpha: .13),
            ],
          ),
          border: Border.all(
            color: widget.request.accent.withValues(alpha: .22),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.request.accent.withValues(alpha: .12),
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
                Icon(Icons.edit_rounded, color: widget.request.accent),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.request.accent,
                    ),
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
        accent: widget.request.accent,
        onTap: () => _showMonthSheet(info),
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
        targetHandle: widget.request.targetHandle,
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _BudgetLimitMonthSheet(
        info: info,
        accent: widget.request.accent,
        onSetOverride: (amount) async {
          await _setOverride(info.year, info.month, amount);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
        onDeleteOverride: () async {
          await _deleteOverride(info.year, info.month);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
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
  final VoidCallback onTap;

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
    required this.onSetOverride,
    required this.onDeleteOverride,
  });

  final _BudgetLimitMonthInfo info;
  final Color accent;
  final Future<void> Function(int) onSetOverride;
  final Future<void> Function() onDeleteOverride;

  @override
  State<_BudgetLimitMonthSheet> createState() => _BudgetLimitMonthSheetState();
}

final class _BudgetLimitMonthSheetState extends State<_BudgetLimitMonthSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ((widget.info.resolvedLimitScaled100 ?? 0) ~/ 100).toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustOverride(int deltaForints) {
    final current =
        int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _controller.text = (current + deltaForints)
          .clamp(0, 0x7fffffffffffffff)
          .toString();
    });
  }

  int get _overrideDraftScaled100 =>
      (int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) *
      100;

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
          Text(
            _formatAmount(info.resolvedLimitScaled100),
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
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
            Text(
              'Költés: ${_formatAmount(info.actualScaled100)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
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
            Text(
              'Eddigi költés: ${_formatAmount(info.actualScaled100)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
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
          const SizedBox(height: 18),
          const Text(
            'Egyedi keret beállítása',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
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
