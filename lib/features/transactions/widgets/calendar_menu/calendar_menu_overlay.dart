import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/calendar_render_builder.dart';
import '../../models/calendar_menu_mode.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';
import 'calendar_canvas.dart';
import 'calendar_mode_selector.dart';
import 'calendar_value_slider_panel.dart';

class CalendarMenuOverlay extends StatefulWidget {
  const CalendarMenuOverlay({
    super.key,
    required this.transactions,
    required this.categories,
    required this.onClose,
    required this.onMonthSelect,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final VoidCallback onClose;
  final void Function(int year, int month) onMonthSelect;

  @override
  State<CalendarMenuOverlay> createState() => _CalendarMenuOverlayState();
}

class _CalendarMenuOverlayState extends State<CalendarMenuOverlay> {
  var _year = DateTime.now().year;
  var _mode = CalendarMenuMode.normal;
  var _transitionLocked = false;
  var _thresholdValue = 1000.0;
  var _heatmapMinValue = 0.0;
  var _heatmapCurrentValue = 10000.0;
  var _heatmapMaxValue = 50000.0;
  double? _customThresholdMin;
  double? _customThresholdMax;

  @override
  Widget build(BuildContext context) {
    final data = CalendarRenderBuilder.buildYear(
      year: _year,
      transactions: widget.transactions,
      categories: widget.categories,
      thresholdValue: _thresholdValue,
      heatmapMinValue: _heatmapMinValue,
      heatmapCurrentValue: _heatmapCurrentValue,
      customThresholdMin: _customThresholdMin,
      customThresholdMax: _customThresholdMax,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          key: const ValueKey('calendar-menu-overlay'),
          top: 286,
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            const SizedBox(width: 100),
                            Expanded(
                              child: _YearNavigator(
                                year: _year,
                                onPrevious: () => setState(() => _year -= 1),
                                onNext: () => setState(() => _year += 1),
                              ),
                            ),
                            CalendarModeSelector(
                              activeMode: _mode,
                              transitionLocked: _transitionLocked,
                              onModeChanged: _setMode,
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      Text(
                        _mode.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CalendarCanvas(
                            data: data,
                            mode: _mode,
                            thresholdValue: _thresholdValue,
                            heatmapMinValue: _heatmapMinValue,
                            heatmapCurrentValue: _heatmapCurrentValue,
                            onMonthSelected: widget.onMonthSelect,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mode == CalendarMenuMode.normal &&
                      data.thresholdRange.min != data.thresholdRange.max)
                    CalendarValueSliderPanel.threshold(
                      value: _thresholdValue,
                      min: data.thresholdRange.min,
                      max: data.thresholdRange.max,
                      onChanged: (value) => setState(() => _thresholdValue = value),
                      onMinChanged: (value) => setState(
                        () => _customThresholdMin = value < 0 ? 0 : value,
                      ),
                      onMaxChanged: (value) => setState(
                        () => _customThresholdMax =
                            value <= data.thresholdRange.min
                                ? data.thresholdRange.min + 1
                                : value,
                      ),
                    ),
                  if (_mode == CalendarMenuMode.heatmap)
                    CalendarValueSliderPanel.heatmap(
                      value: _heatmapCurrentValue,
                      min: _heatmapMinValue,
                      max: _heatmapMaxValue,
                      onChanged: (value) {
                        setState(() => _heatmapCurrentValue = value);
                      },
                      onMinChanged: (value) {
                        setState(() {
                          _heatmapMinValue = value < 0 ? 0 : value;
                          if (_heatmapCurrentValue <= _heatmapMinValue) {
                            _heatmapCurrentValue = _heatmapMinValue + 100;
                          }
                        });
                      },
                      onMaxChanged: (value) {
                        setState(() {
                          _heatmapMaxValue = value <= _heatmapMinValue
                              ? _heatmapMinValue + 1000
                              : value;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setMode(CalendarMenuMode mode) {
    if (_transitionLocked || mode == _mode) return;
    setState(() {
      _transitionLocked = true;
      _mode = mode;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _transitionLocked = false);
    });
  }
}

class _YearNavigator extends StatelessWidget {
  const _YearNavigator({
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const ValueKey('calendar-prev-year'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, color: AppColors.gray500),
          iconSize: 24,
        ),
        Text(
          '$year',
          style: const TextStyle(
            color: AppColors.gray800,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          key: const ValueKey('calendar-next-year'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: AppColors.gray500),
          iconSize: 24,
        ),
      ],
    );
  }
}
