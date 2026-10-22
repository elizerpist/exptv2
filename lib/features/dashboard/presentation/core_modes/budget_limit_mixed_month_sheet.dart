import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../dashboard/application/dashboard_budget_presentation_controller.dart';
import 'budget_allocation_partition_slider.dart';

/// Prepared visual input for one quick-edit category row.  The manager owns
/// the target catalog and exact-month FinancialLimit identity; this sheet only
/// owns the short-lived interaction draft.
@immutable
final class BudgetLimitMixedCategoryEntry {
  const BudgetLimitMixedCategoryEntry({
    required this.handle,
    required this.title,
    required this.accent,
    required this.avatar,
    required this.amountScaled100,
    required this.hasLimit,
  });

  final int handle;
  final String title;
  final Color accent;
  final Widget avatar;
  final int amountScaled100;
  final bool hasLimit;
}

/// The full-screen internal month editor used solely by the manager's mixed
/// perspective. The manager route owns the page transition and Back stack;
/// this widget only owns the editor's short-lived RAM drafts.
///
/// It intentionally has one allocation lane for the whole month and ordinary
/// scalar sliders for category rows.  All allocation meaning remains in
/// [DashboardBudgetPartitionPresentation]; the draft only overlays exact
/// aggregate/category limits while a direct manipulation is in progress.
final class BudgetLimitMixedMonthEditor extends StatefulWidget {
  const BudgetLimitMixedMonthEditor({
    required this.year,
    required this.month,
    required this.partition,
    required this.initialAggregateAmountScaled100,
    required this.monthlyIncomeScaled100,
    required this.canUseIncomeSpec,
    required this.entries,
    required this.externalDraftAmounts,
    required this.initialHighlightedHandle,
    required this.onCategoryDraftChanged,
    required this.onCommitAggregate,
    required this.onCommitCategory,
    required this.onOpenCategoryDetail,
    required this.resolvedCategoryAmount,
    super.key,
  });

  final int year;
  final int month;
  final DashboardBudgetPartitionPresentation partition;
  final int? initialAggregateAmountScaled100;
  final int? monthlyIncomeScaled100;
  final bool canUseIncomeSpec;
  final List<BudgetLimitMixedCategoryEntry> entries;
  final Map<int, int> externalDraftAmounts;
  final int? initialHighlightedHandle;

  /// Allows the manager to retain this RAM-only value if another manager view
  /// is opened before its release-time mutation reconciles.
  final void Function(int handle, int amount) onCategoryDraftChanged;
  final Future<void> Function(int amount) onCommitAggregate;
  final Future<void> Function(int handle, int amount) onCommitCategory;
  final Future<void> Function(int handle) onOpenCategoryDetail;
  final int Function(int handle) resolvedCategoryAmount;

  @override
  State<BudgetLimitMixedMonthEditor> createState() =>
      _BudgetLimitMixedMonthEditorState();
}

final class _BudgetLimitMixedMonthEditorState
    extends State<BudgetLimitMixedMonthEditor> {
  static const _sliderStepScaled100 =
      BudgetAllocationPartitionSlider.stepScaled100;
  static const _fallbackAggregateRangeScaled100 = 100000000; // 1 000 000 Ft

  late final TextEditingController _aggregateController;
  late final FocusNode _aggregateFocusNode;
  late int _aggregateDraftScaled100;
  late int _committedAggregateScaled100;
  late final Map<int, int> _draftByHandle;
  late final Map<int, int> _committedByHandle;
  int? _highlightedHandle;
  int _highlightClearGeneration = 0;

  @override
  void initState() {
    super.initState();
    _aggregateDraftScaled100 = widget.initialAggregateAmountScaled100 ?? 0;
    _committedAggregateScaled100 = _aggregateDraftScaled100;
    _aggregateController = TextEditingController(
      text: (_aggregateDraftScaled100 ~/ 100).toString(),
    );
    _aggregateFocusNode = FocusNode()..addListener(_onAggregateFocusChanged);
    _draftByHandle = <int, int>{
      for (final entry in widget.entries)
        entry.handle:
            widget.externalDraftAmounts[entry.handle] ?? entry.amountScaled100,
    };
    _committedByHandle = Map<int, int>.of(_draftByHandle);
    _highlightedHandle = widget.initialHighlightedHandle;
    if (_highlightedHandle != null) {
      _scheduleHighlightClear(const Duration(milliseconds: 760));
    }
  }

  @override
  void didUpdateWidget(covariant BudgetLimitMixedMonthEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final entry in widget.entries) {
      final external = widget.externalDraftAmounts[entry.handle];
      if (external != null && _draftByHandle[entry.handle] != external) {
        _draftByHandle[entry.handle] = external;
        _committedByHandle[entry.handle] = external;
      }
    }
  }

  @override
  void dispose() {
    _highlightClearGeneration += 1;
    _aggregateFocusNode
      ..removeListener(_onAggregateFocusChanged)
      ..dispose();
    _aggregateController.dispose();
    super.dispose();
  }

  void _onAggregateFocusChanged() {
    if (!_aggregateFocusNode.hasFocus) _commitAggregate();
  }

  int _amountFromText(String text) =>
      (int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) * 100;

  int get _aggregateSliderMaxScaled100 {
    final income = widget.monthlyIncomeScaled100;
    if (income != null && income > 0) return income;
    // No income forecast is manufactured.  The fallback simply keeps the
    // current high-water value reachable, including an over-allocated state.
    return <int>[
      _fallbackAggregateRangeScaled100,
      _aggregateDraftScaled100,
      _partition.liveAllocatedTotalScaled100,
    ].reduce((a, b) => a > b ? a : b);
  }

  DashboardBudgetPartitionPresentation get _partition {
    var result = widget.partition.withAggregateLimitDraft(
      limitScaled100: _aggregateDraftScaled100,
    );
    for (final entry in _draftByHandle.entries) {
      result = result.withCategoryLimitDraft(
        categoryHandle: entry.key,
        limitScaled100: entry.value,
      );
    }
    return result;
  }

  int _categoryMaxScaled100(int handle) {
    final active = _draftByHandle[handle] ?? 0;
    final other = (_partition.liveAllocatedTotalScaled100 - active)
        .clamp(0, 0x7fffffffffffffff)
        .toInt();
    final available = (_aggregateDraftScaled100 - other)
        .clamp(0, 0x7fffffffffffffff)
        .toInt();
    // A legacy over-allocation must remain repairable: preserve the active
    // value as the range ceiling so the user can drag it down, while never
    // allowing a new increase beyond available allocation.
    return active > available ? active : available;
  }

  void _setAggregateDraft(int amount) {
    final next = amount.clamp(0, 0x7fffffffffffffff).toInt();
    if (next == _aggregateDraftScaled100) return;
    setState(() {
      _aggregateDraftScaled100 = next;
      final text = (next ~/ 100).toString();
      _aggregateController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _setAggregateText(String text) {
    final next = _amountFromText(text);
    if (next == _aggregateDraftScaled100) return;
    setState(() => _aggregateDraftScaled100 = next);
  }

  Future<void> _commitAggregate({bool force = false}) async {
    final amount = _aggregateDraftScaled100;
    if (!force && amount == _committedAggregateScaled100) return;
    // Mark before awaiting so focus loss plus submit can never race into two
    // exact-month writes.  The canonical edit coordinator remains latest-wins.
    _committedAggregateScaled100 = amount;
    await widget.onCommitAggregate(amount);
  }

  void _setCategoryDraft(int handle, int amount) {
    final max = _categoryMaxScaled100(handle);
    final next = BudgetAllocationPartitionSlider.snapToStep(
      amountScaled100: amount,
      maxScaled100: max,
    );
    if (next == _draftByHandle[handle]) return;
    HapticFeedback.selectionClick();
    _activateCategory(handle);
    setState(() {
      _draftByHandle[handle] = next;
    });
    widget.onCategoryDraftChanged(handle, next);
  }

  Future<void> _commitCategory(int handle) async {
    final amount = _draftByHandle[handle] ?? 0;
    if (amount != _committedByHandle[handle]) {
      _committedByHandle[handle] = amount;
      await widget.onCommitCategory(handle, amount);
    }
    _scheduleHighlightClear(const Duration(milliseconds: 220));
  }

  Future<void> _openCategoryDetail(int handle) async {
    await widget.onOpenCategoryDetail(handle);
    if (!mounted) return;
    final amount = widget.resolvedCategoryAmount(handle);
    setState(() {
      _draftByHandle[handle] = amount;
      _committedByHandle[handle] = amount;
      _highlightedHandle = handle;
    });
    _scheduleHighlightClear(const Duration(milliseconds: 220));
  }

  void _activateCategory(int handle) {
    _highlightClearGeneration += 1;
    if (_highlightedHandle == handle) return;
    setState(() => _highlightedHandle = handle);
  }

  void _scheduleHighlightClear(Duration delay) {
    final generation = ++_highlightClearGeneration;
    Future<void>.delayed(delay).then((_) {
      if (!mounted || generation != _highlightClearGeneration) return;
      setState(() => _highlightedHandle = null);
    });
  }

  Future<void> _useIncomeSpec() async {
    final income = widget.monthlyIncomeScaled100;
    if (!widget.canUseIncomeSpec || income == null || income <= 0) return;
    _setAggregateDraft(income);
    await _commitAggregate();
  }

  @override
  Widget build(BuildContext context) {
    final partition = _partition;
    final allocated = partition.liveAllocatedTotalScaled100;
    final overAllocated = allocated - _aggregateDraftScaled100;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'HAVI KERET',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: .5,
              color: Color(0xff68758e),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey<String>(
                    'budget-limit-mixed-aggregate-input',
                  ),
                  controller: _aggregateController,
                  focusNode: _aggregateFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 'Ft',
                    border: InputBorder.none,
                  ),
                  onChanged: _setAggregateText,
                  onSubmitted: (_) => _commitAggregate(),
                  onEditingComplete: _commitAggregate,
                ),
              ),
              if (widget.canUseIncomeSpec &&
                  widget.monthlyIncomeScaled100 != null &&
                  widget.monthlyIncomeScaled100! > 0)
                Tooltip(
                  message: 'Budget beállítása a havi bevételre',
                  child: TextButton.icon(
                    key: const ValueKey<String>(
                      'budget-limit-mixed-spec-income',
                    ),
                    onPressed: _useIncomeSpec,
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: const Text('Bevételhez'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            key: const ValueKey<String>('budget-limit-mixed-partition'),
            child: BudgetAggregatePartitionSlider(
              partition: partition,
              valueScaled100: _aggregateDraftScaled100,
              maxScaled100: _aggregateSliderMaxScaled100,
              enabled: _aggregateSliderMaxScaled100 > 0,
              highlightedCategoryHandle: _highlightedHandle,
              onChanged: _setAggregateDraft,
              onChangeEnd: (amount) {
                _setAggregateDraft(amount);
                _commitAggregate();
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MixedMetric(
                  label: 'Kiosztva',
                  amount: _mixedFormatAmount(allocated),
                ),
              ),
              Expanded(
                child: _MixedMetric(
                  label: overAllocated > 0 ? 'Túlkiosztás' : 'Szabad',
                  amount: _mixedFormatAmount(
                    overAllocated > 0
                        ? overAllocated
                        : partition.unallocatedLimitScaled100,
                  ),
                  danger: overAllocated > 0,
                ),
              ),
            ],
          ),
          if (overAllocated > 0) ...[
            const SizedBox(height: 5),
            const Text(
              'A kategórialimitek nem változtak automatikusan.',
              style: TextStyle(fontSize: 11, color: Color(0xffb9485e)),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Kategóriák',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: ListView.builder(
              key: const ValueKey<String>('budget-limit-mixed-category-list'),
              itemCount: widget.entries.length,
              itemBuilder: (context, index) {
                final entry = widget.entries[index];
                final amount = _draftByHandle[entry.handle] ?? 0;
                final max = _categoryMaxScaled100(entry.handle);
                return _BudgetLimitMixedCategoryRow(
                  entry: entry,
                  amountScaled100: amount,
                  showNoLimit: !entry.hasLimit && amount == 0,
                  maxScaled100: max,
                  selected: entry.handle == _highlightedHandle,
                  onTap: () => _openCategoryDetail(entry.handle),
                  onChangeStart: () => _activateCategory(entry.handle),
                  onChanged: (value) =>
                      _setCategoryDraft(entry.handle, value.round()),
                  onChangeEnd: (_) => _commitCategory(entry.handle),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _MixedMetric extends StatelessWidget {
  const _MixedMetric({
    required this.label,
    required this.amount,
    this.danger = false,
  });

  final String label;
  final String amount;
  final bool danger;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xff68758e)),
      ),
      const SizedBox(height: 2),
      Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: danger ? const Color(0xffc24860) : const Color(0xff1c2942),
        ),
      ),
    ],
  );
}

final class _BudgetLimitMixedCategoryRow extends StatelessWidget {
  const _BudgetLimitMixedCategoryRow({
    required this.entry,
    required this.amountScaled100,
    required this.showNoLimit,
    required this.maxScaled100,
    required this.selected,
    required this.onTap,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final BudgetLimitMixedCategoryEntry entry;
  final int amountScaled100;
  final bool showNoLimit;
  final int maxScaled100;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final max = maxScaled100 < 0 ? 0 : maxScaled100;
    // Material Slider requires max > min even for a genuinely unavailable
    // allocation.  The disabled one-unit visual range keeps the thumb at its
    // semantic zero without inventing a positive FinancialLimit.
    final sliderMax = max == 0 ? 1 : max;
    final value = amountScaled100.clamp(0, sliderMax).toDouble();
    final divisions =
        (sliderMax / _BudgetLimitMixedMonthEditorState._sliderStepScaled100)
            .round()
            .clamp(1, 2000)
            .toInt();
    return AnimatedContainer(
      key: ValueKey<String>('budget-limit-mixed-category-${entry.handle}'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
      decoration: BoxDecoration(
        color: selected
            ? entry.accent.withValues(alpha: .10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: entry.accent.withValues(alpha: .22))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            key: ValueKey<String>(
              'budget-limit-mixed-category-tap-${entry.handle}',
            ),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 36,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox.square(
                        dimension:
                            BudgetCategoryAvatarGeometry.avatarCanvasSize,
                        child: entry.avatar,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    showNoLimit ? '—' : _mixedFormatAmount(amountScaled100),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            slider: true,
            label: '${entry.title} havi keret',
            value: '${amountScaled100 ~/ 100} Ft',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: entry.accent,
                inactiveTrackColor: const Color(0xffe3e7ef),
                thumbColor: entry.accent,
                overlayColor: entry.accent.withValues(alpha: .12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
              ),
              child: Slider(
                key: ValueKey<String>(
                  'budget-limit-mixed-category-slider-${entry.handle}',
                ),
                min: 0,
                max: sliderMax.toDouble(),
                value: value,
                divisions: divisions,
                onChangeStart: (_) => onChangeStart(),
                onChanged: max > 0 ? onChanged : null,
                onChangeEnd: max > 0 ? onChangeEnd : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _mixedFormatAmount(int? amountScaled100) {
  if (amountScaled100 == null) return '—';
  final value = amountScaled100 ~/ 100;
  final raw = value.toString();
  final parts = <String>[];
  for (var end = raw.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end);
    parts.add(raw.substring(start, end));
  }
  return '${parts.reversed.join(' ')} Ft';
}
