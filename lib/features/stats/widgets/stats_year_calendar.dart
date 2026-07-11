import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import '../data/stats_year_data.dart';

class StatsYearCalendar extends StatelessWidget {
  const StatsYearCalendar({
    super.key,
    required this.data,
    this.monthCardColor = AppColors.gray50,
    this.heatColor,
    this.onMonthSelected,
  });

  final StatsYearData data;
  final Color monthCardColor;
  final Color? heatColor;
  final ValueChanged<StatsMonthData>? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        const columnGap = 14.88;
        const rowGap = 15.0;
        final cardWidth = (width - columnGap) / 2;
        return SingleChildScrollView(
          key: const ValueKey('stats-year-calendar-scroll'),
          child: SizedBox(
            key: const ValueKey('stats-year-calendar'),
            width: width,
            child: Wrap(
              key: const ValueKey('stats-year-calendar-paint'),
              spacing: columnGap,
              runSpacing: rowGap,
              children: [
                for (final month in data.months)
                  SizedBox(
                    width: cardWidth,
                    height: StatsMonthCard.cardHeight,
                    child: StatsMonthCard(
                      key: ValueKey('stats-month-card-${month.month}'),
                      month: month,
                      scopeLabel: _scopeLabel,
                      cardColor: monthCardColor,
                      heatColor: heatColor ?? _dataHeatColor,
                      onTap: onMonthSelected == null
                          ? null
                          : () => onMonthSelected!(month),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _scopeLabel {
    final type = data.activeType.label.toLowerCase();
    if (data.selectedCategoryIds.isEmpty) return type;
    if (data.selectedCategoryIds.length == 1) return '$type ${data.scopeLabel}';
    return '$type ${data.selectedCategoryIds.length} kategória';
  }

  Color get _dataHeatColor {
    if (data.selectedCategoryIds.length != 1) return AppColors.primary;
    final selectedId = data.selectedCategoryIds.single;
    for (final month in data.months) {
      for (final day in month.days) {
        if (day.dominantCategoryId == selectedId) {
          return day.dominantCategoryColor;
        }
      }
    }
    return AppColors.primary;
  }
}

class StatsMonthCard extends StatelessWidget {
  const StatsMonthCard({
    super.key,
    required this.month,
    required this.scopeLabel,
    required this.cardColor,
    required this.heatColor,
    this.onTap,
  });

  static const cardHeight = 200.0;

  final StatsMonthData month;
  final String scopeLabel;
  final Color cardColor;
  final Color heatColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (var index = 0; index < month.leadingBlankDays; index++)
        const SizedBox.shrink(),
      for (final day in month.days) _DayCell(day: day, heatColor: heatColor),
    ];
    while (cells.length < 42) {
      cells.add(const SizedBox.shrink());
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('stats-month-hit-${month.month}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: [
                SizedBox(
                  height: 26,
                  child: Center(
                    child: Text(
                      month.name,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'zárás',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 6.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatSignedHuf(month.closingAmount),
                        style: TextStyle(
                          color: _closingColor(month.closingAmount),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: heatColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$scopeLabel ${formatHuf(month.scopeTotal)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray600,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (final label in month.weekdayLabels)
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.gray500,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellWidth = constraints.maxWidth / 7;
                        final cellHeight = constraints.maxHeight / 6;
                        return GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          crossAxisCount: 7,
                          childAspectRatio: cellWidth / cellHeight,
                          children: cells,
                        );
                      },
                    ),
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

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.heatColor});

  final StatsDayData day;
  final Color heatColor;

  @override
  Widget build(BuildContext context) {
    final heated = day.meetsThreshold;
    final opacity = (0.10 + day.heatmapIntensity * 0.90)
        .clamp(0.10, 1.0)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: heated
              ? heatColor.withValues(alpha: opacity)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            day.day.toString(),
            style: TextStyle(
              color: heated ? AppColors.gray800 : AppColors.gray500,
              fontSize: 10,
              fontWeight: heated ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatSignedHuf(double value) {
  if (value == 0) return '0 Ft';
  return '${value > 0 ? '+' : '-'}${formatHuf(value.abs())}';
}

Color _closingColor(double value) {
  if (value > 0) return const Color(0xFF15803D);
  if (value < 0) return const Color(0xFFB91C1C);
  return AppColors.gray700;
}
