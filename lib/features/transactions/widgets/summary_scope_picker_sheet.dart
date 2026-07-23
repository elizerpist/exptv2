import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import 'category_menu/category_card.dart';
import 'slide_up_panel_metrics.dart';

class SummaryScopeSelection {
  const SummaryScopeSelection({
    required this.yearEnabled,
    required this.monthEnabled,
    required this.year,
    required this.month,
  });

  final bool yearEnabled;
  final bool monthEnabled;
  final int year;
  final int month;
}

class SummaryScopePickerSheet extends StatefulWidget {
  const SummaryScopePickerSheet({
    super.key,
    required this.initialSelection,
    required this.accentColor,
    required this.buttonSurfaceStyle,
    required this.onApply,
  });

  final SummaryScopeSelection initialSelection;
  final Color accentColor;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ValueChanged<SummaryScopeSelection> onApply;

  @override
  State<SummaryScopePickerSheet> createState() =>
      _SummaryScopePickerSheetState();
}

class _SummaryScopePickerSheetState extends State<SummaryScopePickerSheet> {
  late bool _yearEnabled;
  late bool _monthEnabled;
  late int _year;
  late int _month;
  double _yearDrag = 0;
  double _monthDrag = 0;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _yearEnabled = selection.yearEnabled;
    _monthEnabled = selection.monthEnabled && selection.yearEnabled;
    _year = selection.year;
    _month = selection.month.clamp(1, 12).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 8;
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('summary-scope-picker-sheet'),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SlideUpPanelMetrics.horizontalInset,
            12,
            SlideUpPanelMetrics.horizontalInset,
            bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Időszak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 18),
              _ScopeRow(
                rowKey: const ValueKey('summary-scope-year-row'),
                title: 'Év',
                enabled: _yearEnabled,
                value: _year.toString(),
                accentColor: widget.accentColor,
                onEnabledChanged: _setYearEnabled,
                onDecrease: () => setState(() => _year -= 1),
                onIncrease: () => setState(() => _year += 1),
                onVerticalDragUpdate: (details) {
                  _yearDrag += details.delta.dy;
                  while (_yearDrag <= -26) {
                    _yearDrag += 26;
                    setState(() => _year += 1);
                  }
                  while (_yearDrag >= 26) {
                    _yearDrag -= 26;
                    setState(() => _year -= 1);
                  }
                },
                onVerticalDragEnd: () => _yearDrag = 0,
              ),
              const SizedBox(height: 10),
              _ScopeRow(
                rowKey: const ValueKey('summary-scope-month-row'),
                title: 'Hónap',
                enabled: _monthEnabled,
                value: _monthName(_month),
                accentColor: widget.accentColor,
                onEnabledChanged: _setMonthEnabled,
                onDecrease: () => setState(() => _month = _shiftMonth(-1)),
                onIncrease: () => setState(() => _month = _shiftMonth(1)),
                onVerticalDragUpdate: (details) {
                  _monthDrag += details.delta.dy;
                  while (_monthDrag <= -26) {
                    _monthDrag += 26;
                    setState(() => _month = _shiftMonth(1));
                  }
                  while (_monthDrag >= 26) {
                    _monthDrag -= 26;
                    setState(() => _month = _shiftMonth(-1));
                  }
                },
                onVerticalDragEnd: () => _monthDrag = 0,
              ),
              const SizedBox(height: 18),
              ExpenseSurfaceButton(
                buttonKey: const ValueKey('summary-scope-apply-button'),
                label: 'Szűrőbeállítás',
                onPressed: _apply,
                surfaceStyle: widget.buttonSurfaceStyle,
                color: widget.accentColor,
                foregroundColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setYearEnabled(bool enabled) {
    setState(() {
      _yearEnabled = enabled;
      if (!enabled) _monthEnabled = false;
    });
  }

  void _setMonthEnabled(bool enabled) {
    setState(() {
      _monthEnabled = enabled;
      if (enabled) _yearEnabled = true;
    });
  }

  int _shiftMonth(int direction) {
    final next = _month + direction;
    if (next < 1) return 12;
    if (next > 12) return 1;
    return next;
  }

  void _apply() {
    widget.onApply(
      SummaryScopeSelection(
        yearEnabled: _yearEnabled,
        monthEnabled: _monthEnabled && _yearEnabled,
        year: _year,
        month: _month,
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
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
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.rowKey,
    required this.title,
    required this.enabled,
    required this.value,
    required this.accentColor,
    required this.onEnabledChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final Key rowKey;
  final String title;
  final bool enabled;
  final String value;
  final Color accentColor;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final VoidCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final scopeKey = title == 'Hónap' ? 'month' : 'year';
    return SizedBox(
      key: rowKey,
      child: Stack(
        children: [
          ExpenseSurfaceContainer(
            surfaceKey: ValueKey('summary-scope-$scopeKey-surface'),
            style: ExpenseSurfaceInteraction.neutralNeutral,
            color: AppColors.gray100,
            borderRadius: radius,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            neutralBorder: Border.all(color: AppColors.gray200),
            neutralShadow: categoryNeutralShadow(
              ExpenseSurfaceInteraction.neutralNeutral,
            ),
            child: Row(
              children: [
                Switch(
                  key: ValueKey('$title-summary-scope-switch'),
                  value: enabled,
                  activeThumbColor: accentColor,
                  onChanged: onEnabledChanged,
                ),
                SizedBox(
                  width: 58,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray700,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('$title-summary-scope-decrease'),
                  onPressed: enabled ? onDecrease : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('$title-summary-scope-drag-value'),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: enabled ? onVerticalDragUpdate : null,
                    onVerticalDragEnd: enabled
                        ? (_) => onVerticalDragEnd()
                        : null,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: enabled ? AppColors.gray900 : AppColors.gray400,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('$title-summary-scope-increase'),
                  onPressed: enabled ? onIncrease : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          if (enabled)
            Positioned.fill(
              child: CategoryActiveBorder(
                key: ValueKey('summary-scope-$scopeKey-active-border'),
                radius: radius,
                color: accentColor,
              ),
            ),
        ],
      ),
    );
  }
}
