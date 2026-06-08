import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';

class MonthStatsCharts extends StatelessWidget {
  const MonthStatsCharts({
    super.key,
    required this.year,
    required this.month,
    required this.transactions,
    required this.categories,
  });

  final int year;
  final int month;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;

  @override
  Widget build(BuildContext context) {
    final stats = _MonthStatsData.build(
      year: year,
      month: month,
      transactions: transactions,
      categories: categories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChartCard(
          title: 'Cashflow',
          child: Column(
            children: [
              SizedBox(
                key: const ValueKey('month-cashflow-chart'),
                height: 104,
                child: CustomPaint(
                  painter: _CashflowPainter(stats),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              _CashflowLegend(stats: stats),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Napi ritmus',
          child: SizedBox(
            key: const ValueKey('month-daily-sparkline'),
            height: 132,
            child: CustomPaint(
              painter: _DailySparklinePainter(stats.dailyExpenses),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Kategóriák',
          child: _CategoryBreakdown(stats: stats),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Heti bontás',
          child: SizedBox(
            key: const ValueKey('month-weekly-bars'),
            height: 128,
            child: CustomPaint(
              painter: _WeeklyBarsPainter(stats.weeklyTotals),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Kiemelések',
          child: _HighlightTiles(stats: stats),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Havi részletek',
          child: _DeepStatsGrid(stats: stats),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Kereskedők',
          child: _MerchantStats(stats: stats),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CashflowLegend extends StatelessWidget {
  const _CashflowLegend({required this.stats});

  final _MonthStatsData stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LegendValue(
            label: 'Bevétel',
            value: '+${formatHuf(stats.income)}',
            color: AppColors.income,
          ),
        ),
        Expanded(
          child: _LegendValue(
            label: 'Kiadás',
            value: '-${formatHuf(stats.expense)}',
            color: AppColors.expense,
          ),
        ),
        Expanded(
          child: _LegendValue(
            label: 'Egyenleg',
            value:
                '${stats.balance >= 0 ? '+' : '-'}${formatHuf(stats.balance.abs())}',
            color: stats.balance >= 0 ? AppColors.primary : AppColors.expense,
          ),
        ),
      ],
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.stats});

  final _MonthStatsData stats;

  @override
  Widget build(BuildContext context) {
    final topCategories = stats.topCategories;
    return Row(
      key: const ValueKey('month-category-breakdown'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 104,
          child: CustomPaint(
            painter: _CategoryDonutPainter(topCategories),
            child: Center(
              child: Text(
                stats.expense == 0
                    ? '0%'
                    : '${topCategories.first.percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (final category in topCategories.take(3))
                _CategoryRow(category: category, total: stats.expense),
              if (topCategories.isEmpty)
                const Text(
                  'Nincs kategória adat',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.total});

  final _CategoryShare category;
  final double total;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0
        ? 0.0
        : (category.amount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${category.percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: fraction,
              color: category.color,
              backgroundColor: AppColors.gray100,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTiles extends StatelessWidget {
  const _HighlightTiles({required this.stats});

  final _MonthStatsData stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey('month-highlight-tiles'),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _HighlightTile(
          label: 'Tranzakció',
          value: stats.transactionCount.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        _HighlightTile(
          label: 'Napi átlag',
          value: formatHuf(stats.averageDailyExpense),
          icon: Icons.trending_up,
        ),
        _HighlightTile(
          label: 'Legdrágább nap',
          value: stats.mostExpensiveDay == null
              ? '-'
              : '${stats.mostExpensiveDay}.',
          icon: Icons.calendar_today_outlined,
        ),
        _HighlightTile(
          label: 'Legnagyobb tétel',
          value: stats.largestExpense == null
              ? '-'
              : formatHuf(stats.largestExpense!),
          icon: Icons.bolt_outlined,
        ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeepStatsGrid extends StatelessWidget {
  const _DeepStatsGrid({required this.stats});

  final _MonthStatsData stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _StatMetric('Havi nap', stats.daysInMonth.toString()),
      _StatMetric('Bevételi tétel', stats.incomeCount.toString()),
      _StatMetric('Kiadási tétel', stats.expenseCount.toString()),
      _StatMetric('Költős nap', stats.spendingDays.toString()),
      _StatMetric('Nullás nap', stats.noSpendDays.toString()),
      _StatMetric('Napi nettó', _signedHuf(stats.netPerDay)),
      _StatMetric('Költős napi átlag', formatHuf(stats.averageSpendDay)),
      _StatMetric('Átlag kiadás', formatHuf(stats.averageExpenseTransaction)),
      _StatMetric('Medián kiadás', formatHuf(stats.medianExpense)),
      _StatMetric('Átlag tétel', _signedHuf(stats.averageTransactionAmount)),
      _StatMetric('Bev/Kiad arány', stats.incomeExpenseRatio),
      _StatMetric('Hétköznap', formatHuf(stats.weekdayExpense)),
      _StatMetric('Hétvége', formatHuf(stats.weekendExpense)),
      _StatMetric('Kategória', stats.categoryCount.toString()),
      _StatMetric('Kereskedő', stats.merchantCount.toString()),
      _StatMetric('Első tétel', stats.firstTransactionDayText),
      _StatMetric('Utolsó tétel', stats.lastTransactionDayText),
      _StatMetric('Legjobb bevétel', stats.bestIncomeDayText),
      _StatMetric('Legnagyobb bev.', formatHuf(stats.largestIncome ?? 0)),
    ];
    return GridView.count(
      key: const ValueKey('month-deep-stats-grid'),
      crossAxisCount: 2,
      childAspectRatio: 2.72,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        for (final metric in metrics) _StatTile(metric: metric),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.metric});

  final _StatMetric metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantStats extends StatelessWidget {
  const _MerchantStats({required this.stats});

  final _MonthStatsData stats;

  @override
  Widget build(BuildContext context) {
    final merchants = stats.topMerchants;
    return Column(
      key: const ValueKey('month-merchant-stats'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (merchants.isEmpty)
          const Text(
            'Nincs kereskedő adat',
            style: TextStyle(color: AppColors.gray500, fontSize: 12),
          )
        else
          for (final merchant in merchants.take(5))
            _MerchantRow(merchant: merchant, total: stats.expense),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MerchantPill(
              label: 'Top',
              value: stats.topMerchantName,
            ),
            _MerchantPill(
              label: 'Legnagyobb',
              value: stats.largestExpenseMerchantName,
            ),
            _MerchantPill(
              label: 'Ismétlődő',
              value: stats.recurringCount.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.merchant, required this.total});

  final _MerchantShare merchant;
  final double total;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0
        ? 0.0
        : (merchant.amount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  merchant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${formatHuf(merchant.amount)} · ${merchant.count}x · '
                '${merchant.percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: fraction,
              color: AppColors.primary,
              backgroundColor: AppColors.gray100,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantPill extends StatelessWidget {
  const _MerchantPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashflowPainter extends CustomPainter {
  const _CashflowPainter(this.stats);

  final _MonthStatsData stats;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [stats.income, stats.expense, stats.balance.abs()];
    final maxValue = values.fold<double>(1, math.max);
    final colors = [
      AppColors.income,
      AppColors.expense,
      stats.balance >= 0 ? AppColors.primary : AppColors.expense,
    ];
    final labels = ['IN', 'OUT', 'NET'];
    final barWidth = size.width / 7;
    final gap = (size.width - barWidth * 3) / 4;
    final baseline = size.height - 18;
    final paint = Paint();
    _drawAxis(canvas, size, baseline);
    for (var i = 0; i < values.length; i += 1) {
      final height = (values[i] / maxValue) * (size.height - 34);
      final left = gap + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          baseline - height,
          barWidth,
          height.clamp(4, size.height),
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, paint..color = colors[i]);
      _drawText(
        canvas,
        labels[i],
        Offset(left + barWidth / 2, size.height - 7),
        9,
        FontWeight.w800,
        AppColors.gray500,
      );
    }
  }

  void _drawAxis(Canvas canvas, Size size, double baseline) {
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = AppColors.gray200
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CashflowPainter oldDelegate) =>
      oldDelegate.stats != stats;
}

class _DailySparklinePainter extends CustomPainter {
  const _DailySparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold<double>(1, math.max);
    final chart = Rect.fromLTWH(0, 6, size.width, size.height - 24);
    final gridPaint = Paint()
      ..color = AppColors.gray100
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i += 1) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    if (values.isEmpty) return;
    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i += 1) {
      final x =
          chart.left +
          (values.length == 1 ? 0 : chart.width * i / (values.length - 1));
      final y = chart.bottom - (values[i] / maxValue) * chart.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, chart.bottom);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(chart.right, chart.bottom);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = AppColors.primary.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DailySparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter(this.categories);

  final List<_CategoryShare> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.17;
    final total = categories.fold<double>(0, (sum, item) => sum + item.amount);
    var start = -math.pi / 2;
    if (total <= 0) {
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        math.pi * 2,
        false,
        Paint()
          ..color = AppColors.gray200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }
    for (final category in categories) {
      final sweep = (category.amount / total) * math.pi * 2;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        sweep,
        false,
        Paint()
          ..color = category.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_CategoryDonutPainter oldDelegate) {
    return oldDelegate.categories != categories;
  }
}

class _WeeklyBarsPainter extends CustomPainter {
  const _WeeklyBarsPainter(this.weeks);

  final List<_WeekTotal> weeks;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = weeks.fold<double>(1, (max, week) {
      return math.max(max, math.max(week.income, week.expense));
    });
    final chart = Rect.fromLTWH(0, 4, size.width, size.height - 22);
    final barWidth = chart.width / (weeks.length * 2.4);
    final gap =
        (chart.width - barWidth * weeks.length * 2) / (weeks.length + 1);
    for (var i = 0; i < weeks.length; i += 1) {
      final x = chart.left + gap + i * (barWidth * 2 + gap);
      _drawBar(
        canvas,
        x,
        chart,
        barWidth,
        weeks[i].income,
        maxValue,
        AppColors.income,
      );
      _drawBar(
        canvas,
        x + barWidth,
        chart,
        barWidth,
        weeks[i].expense,
        maxValue,
        AppColors.expense,
      );
      _drawText(
        canvas,
        'W${i + 1}',
        Offset(x + barWidth, size.height - 7),
        9,
        FontWeight.w800,
        AppColors.gray500,
      );
    }
  }

  void _drawBar(
    Canvas canvas,
    double left,
    Rect chart,
    double width,
    double value,
    double maxValue,
    Color color,
  ) {
    final height = (value / maxValue) * chart.height;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left,
        chart.bottom - height,
        width,
        height.clamp(3, chart.height),
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.82));
  }

  @override
  bool shouldRepaint(_WeeklyBarsPainter oldDelegate) =>
      oldDelegate.weeks != weeks;
}

void _drawText(
  Canvas canvas,
  String text,
  Offset center,
  double fontSize,
  FontWeight weight,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

String _signedHuf(double value) {
  return '${value >= 0 ? '+' : '-'}${formatHuf(value.abs())}';
}

String _merchantName(TransactionRecord record) {
  final name = record.displayMerchant.trim();
  return name.isEmpty ? 'Ismeretlen' : name;
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

class _MonthStatsData {
  const _MonthStatsData({
    required this.daysInMonth,
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
    required this.incomeCount,
    required this.expenseCount,
    required this.recurringCount,
    required this.averageDailyExpense,
    required this.averageSpendDay,
    required this.averageExpenseTransaction,
    required this.averageTransactionAmount,
    required this.medianExpense,
    required this.netPerDay,
    required this.spendingDays,
    required this.noSpendDays,
    required this.weekdayExpense,
    required this.weekendExpense,
    required this.categoryCount,
    required this.merchantCount,
    required this.firstTransactionDay,
    required this.lastTransactionDay,
    required this.bestIncomeDay,
    required this.largestIncome,
    required this.mostExpensiveDay,
    required this.largestExpense,
    required this.largestExpenseMerchantName,
    required this.dailyExpenses,
    required this.weeklyTotals,
    required this.topCategories,
    required this.topMerchants,
  });

  final int daysInMonth;
  final double income;
  final double expense;
  final double balance;
  final int transactionCount;
  final int incomeCount;
  final int expenseCount;
  final int recurringCount;
  final double averageDailyExpense;
  final double averageSpendDay;
  final double averageExpenseTransaction;
  final double averageTransactionAmount;
  final double medianExpense;
  final double netPerDay;
  final int spendingDays;
  final int noSpendDays;
  final double weekdayExpense;
  final double weekendExpense;
  final int categoryCount;
  final int merchantCount;
  final int? firstTransactionDay;
  final int? lastTransactionDay;
  final int? bestIncomeDay;
  final double? largestIncome;
  final int? mostExpensiveDay;
  final double? largestExpense;
  final String largestExpenseMerchantName;
  final List<double> dailyExpenses;
  final List<_WeekTotal> weeklyTotals;
  final List<_CategoryShare> topCategories;
  final List<_MerchantShare> topMerchants;

  String get firstTransactionDayText => firstTransactionDay == null
      ? '-'
      : '$firstTransactionDay.';

  String get lastTransactionDayText => lastTransactionDay == null
      ? '-'
      : '$lastTransactionDay.';

  String get bestIncomeDayText => bestIncomeDay == null ? '-' : '$bestIncomeDay.';

  String get incomeExpenseRatio {
    if (expense <= 0 && income <= 0) return '-';
    if (expense <= 0) return '∞';
    return '${(income / expense * 100).round()}%';
  }

  String get topMerchantName =>
      topMerchants.isEmpty ? '-' : topMerchants.first.name;

  static _MonthStatsData build({
    required int year,
    required int month,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final monthRecords = transactions
        .where((record) {
          final date = DateTime.tryParse(record.normalizedDate);
          return date != null && date.year == year && date.month == month;
        })
        .toList(growable: false);
    final dailyExpenses = List<double>.filled(daysInMonth, 0);
    final weeklyTotals = List<_WeekTotal>.generate(
      5,
      (_) => const _WeekTotal(),
    );
    final categoryTotals = <int, double>{};
    final merchantTotals = <String, _MerchantAccumulator>{};
    final categoriesById = {
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    var income = 0.0;
    var expense = 0.0;
    var incomeCount = 0;
    var expenseCount = 0;
    var recurringCount = 0;
    var weekdayExpense = 0.0;
    var weekendExpense = 0.0;
    double? largestIncome;
    double? largestExpense;
    var largestExpenseMerchantName = '-';
    final expenseAmounts = <double>[];
    final absoluteAmounts = <double>[];
    DateTime? firstTransactionDate;
    DateTime? lastTransactionDate;
    int? bestIncomeDay;
    var bestIncomeAmount = 0.0;

    for (final record in monthRecords) {
      final date = DateTime.tryParse(record.normalizedDate);
      if (date == null) continue;
      firstTransactionDate = firstTransactionDate == null ||
              date.isBefore(firstTransactionDate)
          ? date
          : firstTransactionDate;
      lastTransactionDate = lastTransactionDate == null ||
              date.isAfter(lastTransactionDate)
          ? date
          : lastTransactionDate;
      absoluteAmounts.add(record.amount.abs());
      if (record.isRecurringGenerated) recurringCount += 1;
      final weekIndex = ((date.day - 1) ~/ 7).clamp(0, weeklyTotals.length - 1);
      if (record.amount > 0) {
        incomeCount += 1;
        income += record.amount;
        if (record.amount > bestIncomeAmount) {
          bestIncomeAmount = record.amount;
          bestIncomeDay = date.day;
        }
        if (largestIncome == null || record.amount > largestIncome) {
          largestIncome = record.amount;
        }
        weeklyTotals[weekIndex] = weeklyTotals[weekIndex].copyWith(
          income: weeklyTotals[weekIndex].income + record.amount,
        );
      } else if (record.amount < 0) {
        expenseCount += 1;
        final absolute = record.amount.abs();
        expense += absolute;
        expenseAmounts.add(absolute);
        dailyExpenses[date.day - 1] += absolute;
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          weekendExpense += absolute;
        } else {
          weekdayExpense += absolute;
        }
        weeklyTotals[weekIndex] = weeklyTotals[weekIndex].copyWith(
          expense: weeklyTotals[weekIndex].expense + absolute,
        );
        categoryTotals.update(
          record.transactionCategoryID,
          (value) => value + absolute,
          ifAbsent: () => absolute,
        );
        if (largestExpense == null || absolute > largestExpense) {
          largestExpense = absolute;
          largestExpenseMerchantName = _merchantName(record);
        }
        final merchantName = _merchantName(record);
        merchantTotals.update(
          merchantName,
          (value) => value.add(absolute),
          ifAbsent: () => _MerchantAccumulator(amount: absolute, count: 1),
        );
      }
    }

    int? mostExpensiveDay;
    var mostExpensiveAmount = 0.0;
    var spendingDays = 0;
    for (var i = 0; i < dailyExpenses.length; i += 1) {
      if (dailyExpenses[i] > mostExpensiveAmount) {
        mostExpensiveAmount = dailyExpenses[i];
        mostExpensiveDay = i + 1;
      }
      if (dailyExpenses[i] > 0) spendingDays += 1;
    }

    final topCategories = categoryTotals.entries.map((entry) {
      final category = categoriesById[entry.key];
      return _CategoryShare(
        name: category?.name ?? 'Egyéb',
        amount: entry.value,
        color: category?.slotColor ?? AppColors.gray400,
        percentage: expense <= 0 ? 0 : (entry.value / expense) * 100,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    final topMerchants = merchantTotals.entries.map((entry) {
      return _MerchantShare(
        name: entry.key,
        amount: entry.value.amount,
        count: entry.value.count,
        percentage: expense <= 0 ? 0 : (entry.value.amount / expense) * 100,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return _MonthStatsData(
      daysInMonth: daysInMonth,
      income: income,
      expense: expense,
      balance: income - expense,
      transactionCount: monthRecords.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      recurringCount: recurringCount,
      averageDailyExpense: daysInMonth == 0 ? 0 : expense / daysInMonth,
      averageSpendDay: spendingDays == 0 ? 0 : expense / spendingDays,
      averageExpenseTransaction: expenseCount == 0 ? 0 : expense / expenseCount,
      averageTransactionAmount: absoluteAmounts.isEmpty
          ? 0
          : absoluteAmounts.fold<double>(0, (sum, value) => sum + value) /
                absoluteAmounts.length,
      medianExpense: _median(expenseAmounts),
      netPerDay: daysInMonth == 0 ? 0 : (income - expense) / daysInMonth,
      spendingDays: spendingDays,
      noSpendDays: daysInMonth - spendingDays,
      weekdayExpense: weekdayExpense,
      weekendExpense: weekendExpense,
      categoryCount: categoryTotals.length,
      merchantCount: merchantTotals.length,
      firstTransactionDay: firstTransactionDate?.day,
      lastTransactionDay: lastTransactionDate?.day,
      bestIncomeDay: bestIncomeDay,
      largestIncome: largestIncome,
      mostExpensiveDay: mostExpensiveDay,
      largestExpense: largestExpense,
      largestExpenseMerchantName: largestExpenseMerchantName,
      dailyExpenses: dailyExpenses,
      weeklyTotals: weeklyTotals,
      topCategories: topCategories,
      topMerchants: topMerchants,
    );
  }
}

class _WeekTotal {
  const _WeekTotal({this.income = 0, this.expense = 0});

  final double income;
  final double expense;

  _WeekTotal copyWith({double? income, double? expense}) {
    return _WeekTotal(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}

class _CategoryShare {
  const _CategoryShare({
    required this.name,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  final String name;
  final double amount;
  final Color color;
  final double percentage;
}

class _MerchantShare {
  const _MerchantShare({
    required this.name,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  final String name;
  final double amount;
  final int count;
  final double percentage;
}

class _MerchantAccumulator {
  const _MerchantAccumulator({required this.amount, required this.count});

  final double amount;
  final int count;

  _MerchantAccumulator add(double value) {
    return _MerchantAccumulator(amount: amount + value, count: count + 1);
  }
}

class _StatMetric {
  const _StatMetric(this.label, this.value);

  final String label;
  final String value;
}
