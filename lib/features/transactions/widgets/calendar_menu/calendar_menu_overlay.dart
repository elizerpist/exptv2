import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/calendar_render_builder.dart';
import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';
import '../transaction_menu_metrics.dart';
import 'calendar_canvas.dart';
import 'calendar_value_slider_panel.dart';
import 'focused_month_canvas.dart';
import 'month_stats_charts.dart';

const _sliderOverlayHeight = 190.0;

class CalendarMenuOverlay extends StatefulWidget {
  const CalendarMenuOverlay({
    super.key,
    required this.transactions,
    required this.categories,
    required this.onClose,
    required this.onMonthSelect,
    this.fullScreen = false,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final VoidCallback onClose;
  final void Function(int year, int month) onMonthSelect;
  final bool fullScreen;

  @override
  State<CalendarMenuOverlay> createState() => _CalendarMenuOverlayState();
}

class _CalendarMenuOverlayState extends State<CalendarMenuOverlay> {
  var _year = DateTime.now().year;
  var _mode = CalendarMenuMode.category;
  var _transitionLocked = false;
  late final ValueNotifier<double> _thresholdValue;
  late final ValueNotifier<double> _heatmapMinValue;
  late final ValueNotifier<double> _heatmapCurrentValue;
  late final ValueNotifier<double> _heatmapMaxValue;
  int? _focusedMonth;
  double? _customThresholdMin;
  double? _customThresholdMax;
  int? _cachedDataYear;
  List<TransactionRecord>? _cachedDataTransactions;
  List<TransactionCategory>? _cachedDataCategories;
  double? _cachedDataCustomThresholdMin;
  double? _cachedDataCustomThresholdMax;
  CalendarYearRenderData? _cachedData;

  @override
  void initState() {
    super.initState();
    _thresholdValue = ValueNotifier<double>(1000);
    _heatmapMinValue = ValueNotifier<double>(0);
    _heatmapCurrentValue = ValueNotifier<double>(10000);
    _heatmapMaxValue = ValueNotifier<double>(50000);
  }

  @override
  void didUpdateWidget(covariant CalendarMenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.transactions, widget.transactions) ||
        !identical(oldWidget.categories, widget.categories)) {
      _clearCalendarDataCache();
    }
  }

  @override
  void dispose() {
    _thresholdValue.dispose();
    _heatmapMinValue.dispose();
    _heatmapCurrentValue.dispose();
    _heatmapMaxValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = _buildPanel();
    if (widget.fullScreen) return panel;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: TransactionMenuMetrics.overlayTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: panel,
        ),
      ],
    );
  }

  Widget _buildPanel() {
    final data = _calendarData();
    final focusedMonth = _focusedMonth == null
        ? null
        : data.months[(_focusedMonth! - 1).clamp(0, data.months.length - 1)];
    final radius = widget.fullScreen
        ? BorderRadius.zero
        : const BorderRadius.vertical(top: Radius.circular(30));
    final topInset = widget.fullScreen
        ? MediaQuery.paddingOf(context).top
        : 0.0;
    return Material(
      key: const ValueKey('calendar-menu-overlay'),
      color: AppColors.white,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: widget.fullScreen ? AppColors.white : AppColors.gray200,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: topInset + 8),
                _CalendarHeader(
                  mode: _mode,
                  year: _year,
                  focusedMonth: focusedMonth,
                  transitionLocked: _transitionLocked,
                  onPreviousYear: focusedMonth == null
                      ? () => setState(() => _year -= 1)
                      : null,
                  onNextYear: focusedMonth == null
                      ? () => setState(() => _year += 1)
                      : null,
                  onBack: focusedMonth == null
                      ? null
                      : () => setState(() => _focusedMonth = null),
                  onMenuAction: _handleMenuAction,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: focusedMonth == null
                        ? _CalendarSliderValuesBuilder(
                            thresholdValue: _thresholdValue,
                            heatmapMinValue: _heatmapMinValue,
                            heatmapCurrentValue: _heatmapCurrentValue,
                            heatmapMaxValue: _heatmapMaxValue,
                            builder:
                                (
                                  context,
                                  threshold,
                                  heatmapMin,
                                  heatmapCurrent,
                                  _,
                                ) {
                                  return CalendarCanvas(
                                    data: data,
                                    mode: _mode,
                                    thresholdValue: threshold,
                                    heatmapMinValue: heatmapMin,
                                    heatmapCurrentValue: heatmapCurrent,
                                    onMonthSelected: _selectMonth,
                                  );
                                },
                          )
                        : _FocusedMonthView(
                            month: focusedMonth,
                            mode: _mode,
                            transactions: widget.transactions,
                            categories: widget.categories,
                            thresholdValue: _thresholdValue,
                            heatmapMinValue: _heatmapMinValue,
                            heatmapCurrentValue: _heatmapCurrentValue,
                          ),
                  ),
                ),
              ],
            ),
            if (_mode == CalendarMenuMode.category &&
                data.thresholdRange.min != data.thresholdRange.max)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _sliderOverlayHeight,
                child: ValueListenableBuilder<double>(
                  valueListenable: _thresholdValue,
                  builder: (context, threshold, _) {
                    return CalendarValueSliderPanel.threshold(
                      value: threshold,
                      min: data.thresholdRange.min,
                      max: data.thresholdRange.max,
                      onChanged: (value) => _thresholdValue.value = value,
                      onMinChanged: (value) {
                        final next = value < 0 ? 0.0 : value;
                        setState(() {
                          _customThresholdMin = next;
                          if (_thresholdValue.value < next) {
                            _thresholdValue.value = next;
                          }
                          _clearCalendarDataCache();
                        });
                      },
                      onMaxChanged: (value) {
                        final next = value <= data.thresholdRange.min
                            ? data.thresholdRange.min + 1
                            : value;
                        setState(() {
                          _customThresholdMax = next;
                          if (_thresholdValue.value > next) {
                            _thresholdValue.value = next;
                          }
                          _clearCalendarDataCache();
                        });
                      },
                    );
                  },
                ),
              ),
            if (_mode == CalendarMenuMode.heatmap)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _sliderOverlayHeight,
                child: _CalendarSliderValuesBuilder(
                  thresholdValue: _thresholdValue,
                  heatmapMinValue: _heatmapMinValue,
                  heatmapCurrentValue: _heatmapCurrentValue,
                  heatmapMaxValue: _heatmapMaxValue,
                  builder:
                      (context, _, heatmapMin, heatmapCurrent, heatmapMax) {
                        return CalendarValueSliderPanel.heatmap(
                          value: heatmapCurrent,
                          min: heatmapMin,
                          max: heatmapMax,
                          onChanged: (value) {
                            _heatmapCurrentValue.value = value;
                          },
                          onMinChanged: (value) {
                            final next = value < 0 ? 0.0 : value;
                            _heatmapMinValue.value = next;
                            if (_heatmapCurrentValue.value <= next) {
                              _heatmapCurrentValue.value = next + 100;
                            }
                            if (_heatmapMaxValue.value <= next) {
                              _heatmapMaxValue.value = next + 1000;
                            }
                          },
                          onMaxChanged: (value) {
                            final next = value <= heatmapMin
                                ? heatmapMin + 1000
                                : value;
                            _heatmapMaxValue.value = next;
                            if (_heatmapCurrentValue.value > next) {
                              _heatmapCurrentValue.value = next;
                            }
                          },
                        );
                      },
                ),
              ),
          ],
        ),
      ),
    );
  }

  CalendarYearRenderData _calendarData() {
    final cached = _cachedData;
    if (cached != null &&
        _cachedDataYear == _year &&
        identical(_cachedDataTransactions, widget.transactions) &&
        identical(_cachedDataCategories, widget.categories) &&
        _cachedDataCustomThresholdMin == _customThresholdMin &&
        _cachedDataCustomThresholdMax == _customThresholdMax) {
      return cached;
    }

    final stopwatch = Stopwatch()..start();
    final data = CalendarRenderBuilder.buildYear(
      year: _year,
      transactions: widget.transactions,
      categories: widget.categories,
      thresholdValue: _thresholdValue.value,
      heatmapMinValue: _heatmapMinValue.value,
      heatmapCurrentValue: _heatmapCurrentValue.value,
      customThresholdMin: _customThresholdMin,
      customThresholdMax: _customThresholdMax,
    );
    _cachedData = data;
    _cachedDataYear = _year;
    _cachedDataTransactions = widget.transactions;
    _cachedDataCategories = widget.categories;
    _cachedDataCustomThresholdMin = _customThresholdMin;
    _cachedDataCustomThresholdMax = _customThresholdMax;
    DebugConsole.log(
      '[Perf] CalendarRender build source=overlay year=$_year '
      'transactions=${widget.transactions.length} '
      'categories=${widget.categories.length} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    return data;
  }

  void _clearCalendarDataCache() {
    _cachedData = null;
  }

  void _selectMonth(int year, int month) {
    widget.onMonthSelect(year, month);
    setState(() {
      _year = year;
      _focusedMonth = month;
    });
  }

  void _handleMenuAction(_StatsMenuAction action) {
    final mode = action.mode;
    if (mode != null) {
      _setMode(mode);
      return;
    }
    final message = switch (action.exportAction) {
      _StatsExportAction.csv => 'CSV export később érkezik',
      _StatsExportAction.pdf => 'PDF export később érkezik',
      null => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

class _CalendarSliderValuesBuilder extends StatelessWidget {
  const _CalendarSliderValuesBuilder({
    required this.thresholdValue,
    required this.heatmapMinValue,
    required this.heatmapCurrentValue,
    required this.heatmapMaxValue,
    required this.builder,
  });

  final ValueListenable<double> thresholdValue;
  final ValueListenable<double> heatmapMinValue;
  final ValueListenable<double> heatmapCurrentValue;
  final ValueListenable<double> heatmapMaxValue;
  final Widget Function(
    BuildContext context,
    double thresholdValue,
    double heatmapMinValue,
    double heatmapCurrentValue,
    double heatmapMaxValue,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: thresholdValue,
      builder: (context, threshold, _) {
        return ValueListenableBuilder<double>(
          valueListenable: heatmapMinValue,
          builder: (context, heatmapMin, _) {
            return ValueListenableBuilder<double>(
              valueListenable: heatmapCurrentValue,
              builder: (context, heatmapCurrent, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: heatmapMaxValue,
                  builder: (context, heatmapMax, _) {
                    return builder(
                      context,
                      threshold,
                      heatmapMin,
                      heatmapCurrent,
                      heatmapMax,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.mode,
    required this.year,
    required this.focusedMonth,
    required this.transitionLocked,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onBack,
    required this.onMenuAction,
  });

  final CalendarMenuMode mode;
  final int year;
  final CalendarMonthRenderData? focusedMonth;
  final bool transitionLocked;
  final VoidCallback? onPreviousYear;
  final VoidCallback? onNextYear;
  final VoidCallback? onBack;
  final ValueChanged<_StatsMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final month = focusedMonth;
    return SizedBox(
      height: month == null ? 78 : 70,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mode.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 2),
                if (month == null)
                  _YearNavigator(
                    year: year,
                    onPrevious: onPreviousYear!,
                    onNext: onNextYear!,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${month.name} $year',
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBack != null)
                  IconButton(
                    key: const ValueKey('calendar-focus-back'),
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.gray700,
                    ),
                    tooltip: 'Vissza az éves nézethez',
                  ),
                _StatsMenuButton(
                  activeMode: mode,
                  transitionLocked: transitionLocked,
                  onSelected: onMenuAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsMenuButton extends StatelessWidget {
  const _StatsMenuButton({
    required this.activeMode,
    required this.transitionLocked,
    required this.onSelected,
  });

  final CalendarMenuMode activeMode;
  final bool transitionLocked;
  final ValueChanged<_StatsMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_StatsMenuAction>(
      key: const ValueKey('stats-menu-trigger'),
      tooltip: 'Stats menu',
      enabled: !transitionLocked,
      icon: const Icon(Icons.more_vert, color: AppColors.gray700),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final mode in CalendarMenuMode.values)
          PopupMenuItem<_StatsMenuAction>(
            value: _StatsMenuAction.mode(mode),
            child: _StatsMenuRow(
              key: ValueKey('stats-menu-mode-${mode.name}'),
              icon: mode == activeMode
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: mode == activeMode ? AppColors.primary : AppColors.gray500,
              label: mode.title,
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<_StatsMenuAction>(
          value: _StatsMenuAction.export(_StatsExportAction.csv),
          child: _StatsMenuRow(
            key: ValueKey('stats-menu-export-csv'),
            icon: Icons.table_chart_outlined,
            color: AppColors.gray600,
            label: 'Export CSV',
          ),
        ),
        const PopupMenuItem<_StatsMenuAction>(
          value: _StatsMenuAction.export(_StatsExportAction.pdf),
          child: _StatsMenuRow(
            key: ValueKey('stats-menu-export-pdf'),
            icon: Icons.picture_as_pdf_outlined,
            color: AppColors.gray600,
            label: 'Export PDF',
          ),
        ),
      ],
    );
  }
}

class _StatsMenuRow extends StatelessWidget {
  const _StatsMenuRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusedMonthView extends StatelessWidget {
  const _FocusedMonthView({
    required this.month,
    required this.mode,
    required this.transactions,
    required this.categories,
    required this.thresholdValue,
    required this.heatmapMinValue,
    required this.heatmapCurrentValue,
  });

  final CalendarMonthRenderData month;
  final CalendarMenuMode mode;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final ValueListenable<double> thresholdValue;
  final ValueListenable<double> heatmapMinValue;
  final ValueListenable<double> heatmapCurrentValue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('calendar-focus-month-view'),
      padding: const EdgeInsets.only(bottom: 144),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: thresholdValue,
            builder: (context, threshold, _) {
              return ValueListenableBuilder<double>(
                valueListenable: heatmapMinValue,
                builder: (context, heatmapMin, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: heatmapCurrentValue,
                    builder: (context, heatmapCurrent, _) {
                      return FocusedMonthCanvas(
                        month: month,
                        mode: mode,
                        thresholdValue: threshold,
                        heatmapMinValue: heatmapMin,
                        heatmapCurrentValue: heatmapCurrent,
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          MonthStatsCharts(
            year: month.year,
            month: month.month,
            transactions: transactions,
            categories: categories,
          ),
        ],
      ),
    );
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey('calendar-prev-year'),
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: AppColors.gray500),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 42, height: 48),
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 42, height: 48),
          ),
        ],
      ),
    );
  }
}

enum _StatsExportAction { csv, pdf }

class _StatsMenuAction {
  const _StatsMenuAction.mode(this.mode) : exportAction = null;

  const _StatsMenuAction.export(this.exportAction) : mode = null;

  final CalendarMenuMode? mode;
  final _StatsExportAction? exportAction;
}
