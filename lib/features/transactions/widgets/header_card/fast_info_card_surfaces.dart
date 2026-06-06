import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../state/fast_info_metrics_resolver.dart';
import '../category_menu/category_icon_badge.dart';
import 'fast_info_visuals.dart';

typedef FastInfoCardDropCallback = void Function(int index, String cardId);

final Map<String, String> _fastInfoDebugLogSignatures = <String, String>{};

void _logFastInfoDebugOnce(String key, String message) {
  final alreadyVisible = DebugConsole.entries.any(
    (entry) => entry.contains(message),
  );
  if (_fastInfoDebugLogSignatures[key] == message && alreadyVisible) return;
  _fastInfoDebugLogSignatures[key] = message;
  DebugConsole.log(message);
}

class FastInfoPillCard extends StatelessWidget {
  const FastInfoPillCard({
    super.key,
    required this.slot,
    required this.metric,
    required this.index,
    this.slotKeyPrefix = 'fastinfo-pill',
    this.dropKeyPrefix = 'fastinfo-pill',
    this.clearKeyPrefix = 'fastinfo-clear-pill',
    this.height = 38,
    this.onDropCard,
    this.onClear,
    this.onTap,
  });

  final FastInfoSlot? slot;
  final FastInfoMetricResult? metric;
  final int index;
  final String slotKeyPrefix;
  final String dropKeyPrefix;
  final String clearKeyPrefix;
  final double height;
  final FastInfoCardDropCallback? onDropCard;
  final ValueChanged<int>? onClear;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return _wrapDropTarget(
      Stack(
        clipBehavior: Clip.none,
        children: [
          _tapTarget(
            Container(
              key: ValueKey('$slotKeyPrefix-slot-$index'),
              width: double.infinity,
              height: height,
              alignment: Alignment.center,
              padding: EdgeInsets.only(
                left: 14,
                right: onClear != null && slot != null ? 38 : 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(19),
                border: slot == null
                    ? Border.all(
                        color: AppColors.gray300,
                        style: BorderStyle.solid,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: slot == null
                  ? Text(
                      'Üres pill slot',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : _filledPillContent(slot!, metric),
            ),
          ),
          if (onClear != null && slot != null)
            Positioned(
              right: 2,
              top: 1,
              child: IconButton(
                key: ValueKey('$clearKeyPrefix-$index'),
                onPressed: () => onClear!(index),
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.gray500,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                tooltip: 'Slot ürítése',
              ),
            ),
        ],
      ),
    );
  }

  Widget _filledPillContent(FastInfoSlot slot, FastInfoMetricResult? metric) {
    if (slot.id == 'mai_koltes') {
      return _DailySpendPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'heti_koltes') {
      return _WeeklySpendPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'havi_koltes') {
      return _MonthlySpendPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'megtakaritas') {
      return _SavingsPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'koltesi_trend') {
      return _RollingTrendPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'legutobbi_tranzakcio') {
      return _LatestTransactionPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'varhato_ho_vegi_koltes') {
      return _ForecastPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'leggyorsabban_fogyo_kategorialimit') {
      return _TightestLimitPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'leggyakoribb_kereskedo') {
      return _TopMerchantPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'atlagos_napi_koltes') {
      return _AverageDailyPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'no_spend_napok_szama') {
      return _NoSpendPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'top_kategoria_heten') {
      return _TopCategoriesPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'legnagyobb_novekedo_kategoria') {
      return _CategoryChangePillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'kovetkezo_ismetlo_kiadas') {
      return _NextFixedPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'havi_fix_koltseg_osszesen') {
      return _MonthlyFixedPillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'bevetel_ebben_a_honapban') {
      return _MonthlyIncomePillContent(slot: slot, metric: metric);
    }
    if (slot.id == 'kiadas_bevetel_arany') {
      return _IncomeSpentPillContent(slot: slot, metric: metric);
    }

    final primary = metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat';
    final secondary = metric?.secondaryValues.isNotEmpty == true
        ? metric!.secondaryValues.first
        : metric?.pillValue ?? '';
    return Row(
      children: [
        SizedBox(
          width: 94,
          child: Text(
            slot.label,
            key: ValueKey('fastinfo-pill-title-${slot.id}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                primary,
                key: ValueKey('fastinfo-pill-primary-${slot.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondary,
                  key: ValueKey('fastinfo-pill-secondary-${slot.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 78,
          child: FastInfoVisual(
            slot: slot,
            metric: metric,
            includeTrend: false,
          ),
        ),
        if (metric?.trend case final trend?) ...[
          const SizedBox(width: 4),
          FastInfoPillTrend(
            key: ValueKey('fastinfo-trend-${slot.id}'),
            slotId: slot.id,
            trend: trend,
          ),
        ],
      ],
    );
  }

  Widget _tapTarget(Widget child) {
    final currentSlot = slot;
    if (currentSlot == null || onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap!(currentSlot.id),
      child: child,
    );
  }

  Widget _wrapDropTarget(Widget child) {
    if (onDropCard == null) return child;
    return DragTarget<String>(
      key: ValueKey('$dropKeyPrefix-drop-$index'),
      onAcceptWithDetails: (details) => onDropCard!(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final dropReady = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: dropReady ? 1.03 : 1,
          duration: const Duration(milliseconds: 120),
          child: _DropReadyFrame(
            frameKey: ValueKey('$dropKeyPrefix-drop-frame-$index'),
            dropReady: dropReady,
            radius: 20,
            child: child,
          ),
        );
      },
    );
  }
}

class _DailySpendPillContent extends StatelessWidget {
  const _DailySpendPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 98,
          child: Text(
            slot.label,
            key: ValueKey('fastinfo-pill-title-${slot.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: 7.6,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _dailyPillPrimary(metric),
                key: ValueKey('fastinfo-pill-primary-${slot.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (_dailyPillSecondary(metric).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _dailyPillSecondary(metric),
                  key: ValueKey('fastinfo-pill-secondary-${slot.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: _DailyPillLimitMarkerBar(
            slotId: slot.id,
            progress: metric?.progress,
            marker: metric?.visual.marker,
            semantic: metric?.semantic ?? FastInfoSemantic.neutral,
          ),
        ),
      ],
    );
  }

  String _dailyPillPrimary(FastInfoMetricResult? value) {
    final primary = value?.primaryValue ?? value?.pillValue ?? 'Nincs adat';
    return primary.replaceFirst(RegExp(r'\s+elköltve$'), '');
  }

  String _dailyPillSecondary(FastInfoMetricResult? value) {
    final values = value?.secondaryValues ?? const <String>[];
    for (final item in values) {
      if (item.trim().endsWith('költhető')) return item.trim();
    }
    return '';
  }
}

class _DailyPillLimitMarkerBar extends StatelessWidget {
  const _DailyPillLimitMarkerBar({
    required this.slotId,
    required this.progress,
    required this.marker,
    required this.semantic,
  });

  final String slotId;
  final double? progress;
  final double? marker;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress?.clamp(0.0, 1.0) ?? 0.0;
    final markerValue = marker;
    if (progress == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows = markerValue != null && markerValue > 1;
        final chartWidth = constraints.maxWidth.clamp(0.0, 84.0);
        final scaleWidth = (chartWidth - 6).clamp(0.0, 78.0);
        final leftInset = (chartWidth - scaleWidth) / 2;
        final overflowWidth = overflows ? 14.0 : 0.0;
        final barWidth = overflows
            ? scaleWidth - overflowWidth - 2
            : scaleWidth;
        final markerX = markerValue == null
            ? null
            : overflows
            ? leftInset + scaleWidth - 5
            : leftInset + barWidth * markerValue.clamp(0.0, 1.0);
        final labelLeft = markerX == null
            ? 0.0
            : (markerX - 7).clamp(0.0, chartWidth - 16);
        return SizedBox(
          key: ValueKey('fastinfo-daily-pill-limit-$slotId'),
          width: chartWidth,
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: leftInset,
                top: 11,
                width: barWidth,
                child: _DailyPillBaseBar(
                  progress: progressValue,
                  semantic: semantic,
                ),
              ),
              if (overflows)
                Positioned(
                  key: ValueKey('fastinfo-daily-pill-overflow-$slotId'),
                  left: leftInset + barWidth + 2,
                  top: 14,
                  width: overflowWidth,
                  child: const _DashedOverflowLine(),
                ),
              if (markerX != null) ...[
                Positioned(
                  left: labelLeft,
                  top: 0,
                  child: Text(
                    'átl',
                    maxLines: 1,
                    style: TextStyle(
                      color: overflows
                          ? const Color(0xFF92400E)
                          : AppColors.gray500,
                      fontSize: 5,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
                Positioned(
                  left: markerX.clamp(0.0, chartWidth - 2),
                  top: 6,
                  child: Container(
                    width: 2,
                    height: 17,
                    decoration: BoxDecoration(
                      color: overflows
                          ? const Color(0xFFF59E0B)
                          : AppColors.gray700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DailyPillBaseBar extends StatelessWidget {
  const _DailyPillBaseBar({required this.progress, required this.semantic});

  final double progress;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(999),
              ),
            ),
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _fastInfoSemanticColor(semantic),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedOverflowLine extends StatelessWidget {
  const _DashedOverflowLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index += 1) ...[
          Expanded(child: Container(height: 2, color: const Color(0xFFF59E0B))),
          if (index < 2) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _WeeklySpendPillContent extends StatelessWidget {
  const _WeeklySpendPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final paceText = _weeklyPaceText(metric);
    return Row(
      children: [
        SizedBox(
          width: 98,
          child: Text(
            slot.label,
            key: ValueKey('fastinfo-pill-title-${slot.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: 7.6,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
                key: ValueKey('fastinfo-pill-primary-${slot.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (paceText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  paceText,
                  key: ValueKey('fastinfo-pill-secondary-${slot.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: _WeeklyBalanceMeter(
            slotId: slot.id,
            value: metric?.visual.value,
            semantic: metric?.visual.semantic ?? FastInfoSemantic.neutral,
          ),
        ),
      ],
    );
  }
}

class _WeeklyBalanceMeter extends StatelessWidget {
  const _WeeklyBalanceMeter({
    required this.slotId,
    required this.value,
    required this.semantic,
  });

  final String slotId;
  final double? value;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final normalized = (value ?? 0).clamp(-1.0, 1.0).toDouble();
    const chartLeft = 3.0;
    const chartTop = 2.0;
    const chartWidth = 78.0;
    const chartHeight = 19.0;
    const centerX = chartLeft + chartWidth / 2;
    const usableHalf = chartWidth / 2 - 5;
    final deltaWidth = normalized == 0
        ? 0.0
        : (normalized.abs() * usableHalf).clamp(1.0, usableHalf).toDouble();
    final deltaLeft = normalized >= 0 ? centerX : centerX - deltaWidth;

    return SizedBox(
      key: ValueKey('fastinfo-weekly-balance-$slotId'),
      width: 84,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: chartLeft,
            top: chartTop + 9,
            width: chartWidth,
            height: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: centerX - 1,
            top: chartTop + 2,
            width: 2,
            height: chartHeight - 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (deltaWidth > 0)
            Positioned(
              left: deltaLeft,
              top: chartTop + 6,
              width: deltaWidth,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _fastInfoSemanticColor(semantic),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthlySpendPillContent extends StatelessWidget {
  const _MonthlySpendPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final indexText = _monthlyIndexText(metric);
    return Row(
      children: [
        SizedBox(
          width: 98,
          child: Text(
            slot.label,
            key: ValueKey('fastinfo-pill-title-${slot.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: 7.6,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
                key: ValueKey('fastinfo-pill-primary-${slot.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (indexText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  indexText,
                  key: ValueKey('fastinfo-pill-secondary-${slot.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: _MonthlyIndexMeter(
            slotId: slot.id,
            value: metric?.visual.value,
          ),
        ),
      ],
    );
  }
}

class _MonthlyIndexMeter extends StatelessWidget {
  const _MonthlyIndexMeter({required this.slotId, required this.value});

  final String slotId;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final needle = (value ?? 0).clamp(0.0, 1.0).toDouble();
    const chartLeft = 3.0;
    const chartTop = 3.0;
    const chartWidth = 78.0;
    const barTop = chartTop + 7;
    return SizedBox(
      key: ValueKey('fastinfo-monthly-index-$slotId'),
      width: 84,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: chartLeft,
            top: barTop,
            width: chartWidth,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 33,
                    child: SizedBox.expand(
                      key: ValueKey('fastinfo-monthly-index-good-$slotId'),
                      child: const ColoredBox(color: AppColors.income),
                    ),
                  ),
                  Expanded(
                    flex: 32,
                    child: SizedBox.expand(
                      key: ValueKey('fastinfo-monthly-index-warning-$slotId'),
                      child: const ColoredBox(color: Color(0xFFF59E0B)),
                    ),
                  ),
                  Expanded(
                    flex: 35,
                    child: SizedBox.expand(
                      key: ValueKey('fastinfo-monthly-index-bad-$slotId'),
                      child: const ColoredBox(color: AppColors.expense),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: chartLeft + chartWidth * needle - 1,
            top: chartTop + 1,
            width: 2,
            height: 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray700,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsPillContent extends StatelessWidget {
  const _SavingsPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
            secondary:
                _secondaryStarting(metric, 'várható cél:') ??
                _secondaryStarting(metric, 'cél'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: _SavingProjectionMeter(slotId: slot.id, metric: metric),
        ),
      ],
    );
  }
}

class _RollingTrendPillContent extends StatelessWidget {
  const _RollingTrendPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
            secondary: _rollingPillSecondary(metric),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: Align(
            alignment: Alignment.center,
            child: _RollingPillBand(
              slotId: slot.id,
              value: metric?.visual.value,
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestTransactionPillContent extends StatelessWidget {
  const _LatestTransactionPillContent({
    required this.slot,
    required this.metric,
  });

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
            secondary: _latestMerchantCategory(metric).join(' · '),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: _FastInfoAvatarBadge(
            key: ValueKey('fastinfo-last-transaction-pill-avatar-${slot.id}'),
            avatar: metric?.avatar ?? metric?.visual.avatar,
            size: 25,
            iconSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ForecastPillContent extends StatelessWidget {
  const _ForecastPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
            secondary:
                _secondaryStarting(metric, 'havi keret') ??
                _secondaryStarting(metric, 'sáv') ??
                '',
          ),
        ),
        const SizedBox(width: 8),
        _ProjectionLimitMeter(
          key: ValueKey('fastinfo-forecast-pill-limit-${slot.id}'),
          value: metric?.visual.value ?? metric?.progress,
          semantic:
              metric?.semantic ??
              metric?.visual.semantic ??
              FastInfoSemantic.neutral,
        ),
      ],
    );
  }
}

class _TightestLimitPillContent extends StatelessWidget {
  const _TightestLimitPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Legszűkebb limit'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary:
                _secondaryStarting(metric, 'várható') ??
                metric?.pillValue ??
                'Nincs adat',
            secondary:
                _secondaryContaining(metric, 'hó végére') ??
                '${metric?.primaryValue ?? ''} hó végére'.trim(),
          ),
        ),
        const SizedBox(width: 8),
        _OverflowProjectionMeter(
          key: ValueKey('fastinfo-tightest-limit-pill-overflow-${slot.id}'),
          value: metric?.visual.value ?? metric?.progress,
          semantic:
              metric?.visual.semantic ??
              metric?.semantic ??
              FastInfoSemantic.neutral,
        ),
      ],
    );
  }
}

class _TopMerchantPillContent extends StatelessWidget {
  const _TopMerchantPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Gyakori kereskedő'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _secondaryContaining(metric, 'aktív nap') ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _MerchantDaysStrip(
          key: ValueKey('fastinfo-merchant-days-${slot.id}'),
          points: metric?.visual.points ?? const <FastInfoVisualPoint>[],
        ),
      ],
    );
  }
}

class _AverageDailyPillContent extends StatelessWidget {
  const _AverageDailyPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Napi átlag'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
            secondary: _secondaryContaining(metric, 'kiugró') ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _AverageSpikeChart(
          key: ValueKey('fastinfo-average-spike-${slot.id}'),
          values: metric?.visual.values ?? metric?.series ?? const <double>[],
          width: 84,
          height: 24,
          markSpikes: true,
        ),
      ],
    );
  }
}

class _NoSpendPillContent extends StatelessWidget {
  const _NoSpendPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Költésmentes napok'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _secondaryStarting(metric, 'elmúlt 7') ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _NoSpendWeekStrip(
          key: ValueKey('fastinfo-no-spend-week-${slot.id}'),
          values: metric?.visual.values ?? const <double>[],
        ),
      ],
    );
  }
}

class _TopCategoriesPillContent extends StatelessWidget {
  const _TopCategoriesPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Top kategóriák'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _topCategoriesPillSecondary(metric),
          ),
        ),
        const SizedBox(width: 8),
        _TopCategoryIcons(
          key: ValueKey('fastinfo-top-categories-icons-${slot.id}'),
          points: metric?.visual.points ?? const <FastInfoVisualPoint>[],
        ),
      ],
    );
  }
}

class _CategoryChangePillContent extends StatelessWidget {
  const _CategoryChangePillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Kategóriaváltozás'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _secondaryAt(metric, 0),
          ),
        ),
        const SizedBox(width: 8),
        _CategoryChangeMeter(
          key: ValueKey('fastinfo-category-change-meter-${slot.id}'),
          value: metric?.visual.value,
          semantic:
              metric?.trend?.semantic ??
              metric?.visual.semantic ??
              FastInfoSemantic.neutral,
        ),
      ],
    );
  }
}

class _NextFixedPillContent extends StatelessWidget {
  const _NextFixedPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Következő fix'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _afterSeparator(_secondaryAt(metric, 0)),
          ),
        ),
        const SizedBox(width: 8),
        _FixedWeekBars(
          key: ValueKey('fastinfo-next-fixed-pill-week-${slot.id}'),
          values: metric?.visual.values ?? const <double>[],
        ),
      ],
    );
  }
}

class _MonthlyFixedPillContent extends StatelessWidget {
  const _MonthlyFixedPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Havi fixek'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _secondaryContaining(metric, 'fixből') ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _MonthlyFixedSplit(
          key: ValueKey('fastinfo-monthly-fixed-pill-split-${slot.id}'),
          done: metric?.visual.value,
          todo: metric?.visual.compareValue,
        ),
      ],
    );
  }
}

class _MonthlyIncomePillContent extends StatelessWidget {
  const _MonthlyIncomePillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Havi bevétel'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary:
                '${_compactDisplayAmount(metric?.primaryValue)} beérkezett',
          ),
        ),
        const SizedBox(width: 8),
        _IncomeCompareBars(
          key: ValueKey('fastinfo-income-compare-${slot.id}'),
          previous: metric?.visual.compareValue,
          current: metric?.visual.value,
        ),
      ],
    );
  }
}

class _IncomeSpentPillContent extends StatelessWidget {
  const _IncomeSpentPillContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillTitle(slot: slot, label: 'Bevétel elköltve'),
        const SizedBox(width: 8),
        Expanded(
          child: _PillValues(
            slotId: slot.id,
            primary: metric?.pillValue ?? metric?.primaryValue ?? 'Nincs adat',
            secondary: _secondaryContaining(metric, 'bevételből') ?? '',
          ),
        ),
        const SizedBox(width: 8),
        _IncomeSpentSplit(
          key: ValueKey('fastinfo-income-spent-split-${slot.id}'),
          remaining: metric?.visual.value,
          spent: metric?.visual.compareValue ?? metric?.progress,
        ),
      ],
    );
  }
}

class _PillTitle extends StatelessWidget {
  const _PillTitle({required this.slot, this.label});

  final FastInfoSlot slot;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      child: Text(
        label ?? slot.label,
        key: ValueKey('fastinfo-pill-title-${slot.id}'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.gray700,
          fontSize: 7.6,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
    );
  }
}

class _PillValues extends StatelessWidget {
  const _PillValues({
    required this.slotId,
    required this.primary,
    required this.secondary,
  });

  final String slotId;
  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final secondaryText = secondary?.trim() ?? '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          primary,
          key: ValueKey('fastinfo-pill-primary-$slotId'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray800,
            fontSize: 12.3,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        if (secondaryText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            secondaryText,
            key: ValueKey('fastinfo-pill-secondary-$slotId'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _SavingProjectionMeter extends StatelessWidget {
  const _SavingProjectionMeter({required this.slotId, required this.metric});

  final String slotId;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final now = (metric?.progress ?? metric?.visual.value ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    final expected = (metric?.visual.marker ?? metric?.visual.compareValue)
        ?.clamp(0.0, 1.0)
        .toDouble();
    const chartLeft = 3.0;
    const chartWidth = 78.0;
    return SizedBox(
      key: ValueKey('fastinfo-saving-projection-$slotId'),
      width: 84,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: chartLeft,
            top: 11,
            width: chartWidth,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.gray200),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: now,
                    child: const ColoredBox(color: AppColors.income),
                  ),
                ],
              ),
            ),
          ),
          if (expected != null)
            Positioned(
              left: chartLeft + chartWidth * expected - 1,
              top: 4,
              width: 2,
              height: 17,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FastInfoBoxCard extends StatelessWidget {
  const FastInfoBoxCard({
    super.key,
    required this.slot,
    required this.metric,
    required this.index,
    this.slotKeyPrefix = 'fastinfo-box',
    this.dropKeyPrefix = 'fastinfo-box',
    this.clearKeyPrefix = 'fastinfo-clear-box',
    this.height = 136,
    this.onDropCard,
    this.onClear,
    this.onTap,
  });

  final FastInfoSlot? slot;
  final FastInfoMetricResult? metric;
  final int index;
  final String slotKeyPrefix;
  final String dropKeyPrefix;
  final String clearKeyPrefix;
  final double height;
  final FastInfoCardDropCallback? onDropCard;
  final ValueChanged<int>? onClear;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return _wrapDropTarget(
      Stack(
        clipBehavior: Clip.none,
        children: [
          _tapTarget(
            Container(
              key: ValueKey('$slotKeyPrefix-slot-$index'),
              width: double.infinity,
              height: height,
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                onClear != null && slot != null ? 28 : 10,
                8,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: slot == null
                    ? Border.all(color: AppColors.gray300)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: slot == null
                  ? _emptyBoxContent()
                  : _filledBoxContent(slot!, metric),
            ),
          ),
          if (onClear != null && slot != null)
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                key: ValueKey('$clearKeyPrefix-$index'),
                onPressed: () => onClear!(index),
                icon: const Icon(
                  Icons.close,
                  size: 15,
                  color: AppColors.gray500,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                tooltip: 'Slot ürítése',
              ),
            ),
        ],
      ),
    );
  }

  Widget _tapTarget(Widget child) {
    final currentSlot = slot;
    if (currentSlot == null || onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap!(currentSlot.id),
      child: child,
    );
  }

  Widget _emptyBoxContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Üres box',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray400,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Text(
          'Slot',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray800,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _filledBoxContent(FastInfoSlot slot, FastInfoMetricResult? metric) {
    if (slot.id == 'mai_koltes') {
      return _DailySpendBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'heti_koltes') {
      return _WeeklySpendBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'havi_koltes') {
      return _MonthlySpendBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'megtakaritas') {
      return _SavingsBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'koltesi_trend') {
      return _RollingTrendBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'legutobbi_tranzakcio') {
      return _LatestTransactionBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'varhato_ho_vegi_koltes') {
      return _ForecastBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'leggyorsabban_fogyo_kategorialimit') {
      return _TightestLimitBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'leggyakoribb_kereskedo') {
      return _TopMerchantBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'atlagos_napi_koltes') {
      return _AverageDailyBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'no_spend_napok_szama') {
      return _NoSpendBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'top_kategoria_heten') {
      return _TopCategoriesBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'legnagyobb_novekedo_kategoria') {
      return _CategoryChangeBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'kovetkezo_ismetlo_kiadas') {
      return _NextFixedBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'havi_fix_koltseg_osszesen') {
      return _MonthlyFixedBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'bevetel_ebben_a_honapban') {
      return _MonthlyIncomeBoxContent(slot: slot, metric: metric);
    }
    if (slot.id == 'kiadas_bevetel_arany') {
      return _IncomeSpentBoxContent(slot: slot, metric: metric);
    }

    final secondaryValues =
        metric?.secondaryValues.take(3).toList() ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slot.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          metric?.primaryValue ?? 'Nincs adat',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray800,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final secondary in secondaryValues)
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 8,
              height: 1.1,
            ),
          ),
        const Spacer(),
        FastInfoVisual(slot: slot, metric: metric),
      ],
    );
  }

  Widget _wrapDropTarget(Widget child) {
    if (onDropCard == null) return child;
    return DragTarget<String>(
      key: ValueKey('$dropKeyPrefix-drop-$index'),
      onAcceptWithDetails: (details) => onDropCard!(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final dropReady = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: dropReady ? 1.03 : 1,
          duration: const Duration(milliseconds: 120),
          child: _DropReadyFrame(
            frameKey: ValueKey('$dropKeyPrefix-drop-frame-$index'),
            dropReady: dropReady,
            radius: 8,
            child: child,
          ),
        );
      },
    );
  }
}

class _SavingsBoxContent extends StatelessWidget {
  const _SavingsBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final progress = (metric?.progress ?? metric?.visual.value ?? 0)
        .clamp(0.0, 1.0)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BoxTitle(slot.label),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        if (_secondaryStarting(metric, 'bevétel') case final subtitle?) ...[
          const SizedBox(height: 2),
          _BoxSecondary(subtitle),
        ],
        const Spacer(),
        const _BoxMicroLabel('Cél haladás:'),
        const SizedBox(height: 3),
        Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _fastInfoSemanticColor(
                      metric?.semantic ?? FastInfoSemantic.neutral,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_secondaryStarting(metric, 'cél:') case final goal?) ...[
          const SizedBox(height: 3),
          Center(child: _BoxSecondary(goal, fontSize: 6.6)),
        ],
        const SizedBox(height: 5),
        const _BoxMicroLabel('Havi állás:'),
        const SizedBox(height: 2),
        Text(
          _positiveCompact(metric),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.income,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _RollingTrendBoxContent extends StatelessWidget {
  const _RollingTrendBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final previous = _secondaryStarting(metric, 'előző 30 nap:');
    final trend = metric?.trend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BoxTitle(slot.label),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        if (previous != null) ...[
          const SizedBox(height: 2),
          _BoxSecondary(previous),
        ],
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Fix tételek nélkül',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.2,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        const Spacer(),
        const _BoxMicroLabel('30 nap vs előző 30:'),
        const SizedBox(height: 4),
        _RollingSplitBar(
          key: ValueKey('fastinfo-rolling-split-${slot.id}'),
          slotId: slot.id,
          value: metric?.visual.value,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _BoxSecondary(
                _compactPreviousLabel(previous),
                fontSize: 6.4,
              ),
            ),
            Flexible(
              child: _BoxSecondary(metric?.pillValue ?? '', fontSize: 6.4),
            ),
          ],
        ),
        if (trend != null) ...[
          const SizedBox(height: 5),
          const _BoxMicroLabel('Változás:'),
          const SizedBox(height: 2),
          _DailyTrendValue(trend: trend),
        ],
      ],
    );
  }
}

class _LatestTransactionBoxContent extends StatelessWidget {
  const _LatestTransactionBoxContent({
    required this.slot,
    required this.metric,
  });

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final names = _latestMerchantCategory(metric);
    final time = (metric?.secondaryValues.length ?? 0) > 1
        ? metric!.secondaryValues[1]
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BoxTitle(slot.label),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 2),
          _BoxSecondary(time),
        ],
        const Spacer(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FastInfoAvatarBadge(
                key: ValueKey('fastinfo-last-transaction-avatar-${slot.id}'),
                avatar: metric?.avatar ?? metric?.visual.avatar,
                size: 32,
                iconSize: 18,
              ),
              const SizedBox(height: 4),
              Text(
                names.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 7.4,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                names.length > 1 ? names[1] : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 6.6,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _BoxMicroLabel('Összeg:'),
        const SizedBox(height: 2),
        Text(
          metric?.primaryValue ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: (metric?.primaryValue.startsWith('+') ?? false)
                ? AppColors.income
                : AppColors.expense,
            fontSize: 10.4,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ForecastBoxContent extends StatelessWidget {
  const _ForecastBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Várható hó végi'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        const SizedBox(height: 3),
        _SmallBadge(text: 'Fix-korrigált becslés'),
        const Spacer(),
        const _BoxMicroLabel('Becslés trend:'),
        const SizedBox(height: 3),
        _ForecastLineChart(
          key: ValueKey('fastinfo-forecast-line-${slot.id}'),
          values: metric?.visual.values ?? metric?.series ?? const <double>[],
          width: 98,
          height: 29,
        ),
        const SizedBox(height: 2),
        const Center(
          child: _BoxSecondary('elmúlt 7 nap · today kék', fontSize: 6.6),
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Becslési sáv:'),
        const SizedBox(height: 2),
        _ForecastRangeMeter(
          key: ValueKey('fastinfo-forecast-range-${slot.id}'),
        ),
      ],
    );
  }
}

class _TightestLimitBoxContent extends StatelessWidget {
  const _TightestLimitBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final progress =
        (metric?.progress ??
                metric?.visual.compareValue ??
                metric?.visual.value ??
                0)
            .clamp(0.0, 1.0)
            .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Legszűkebb limit'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        if (_secondaryAt(metric, 0).isNotEmpty) ...[
          const SizedBox(height: 2),
          _BoxSecondary(_secondaryAt(metric, 0)),
        ],
        const SizedBox(height: 4),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FastInfoAvatarBadge(
                key: ValueKey('fastinfo-tightest-limit-avatar-${slot.id}'),
                avatar: metric?.avatar ?? metric?.visual.avatar,
                size: 25,
                iconSize: 14,
              ),
              const SizedBox(height: 2),
              _BoxSecondary(
                _secondaryContaining(metric, 'maradt') ?? '',
                fontSize: 6.8,
              ),
            ],
          ),
        ),
        const Spacer(),
        const _BoxMicroLabel('Limit állás:'),
        const SizedBox(height: 3),
        _TightestLimitProgress(
          key: ValueKey('fastinfo-tightest-limit-progress-${slot.id}'),
          progress: progress,
          semantic: metric?.semantic ?? FastInfoSemantic.neutral,
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Figyelendő:'),
        const SizedBox(height: 2),
        Text(
          _percentFromRatio(progress),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _fastInfoSemanticColor(
              metric?.semantic ?? FastInfoSemantic.neutral,
            ),
            fontSize: 10.4,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _TopMerchantBoxContent extends StatelessWidget {
  const _TopMerchantBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Gyakori kereskedő'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        const SizedBox(height: 2),
        _BoxSecondary(
          _secondaryStarting(metric, 'legtöbb') ?? 'legtöbb tranzakció',
        ),
        const SizedBox(height: 4),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FastInfoAvatarBadge(
                key: ValueKey('fastinfo-top-merchant-avatar-${slot.id}'),
                avatar: metric?.avatar ?? metric?.visual.avatar,
                size: 25,
                iconSize: 14,
              ),
              const SizedBox(height: 2),
              _BoxSecondary(_merchantCategoryName(metric), fontSize: 6.8),
            ],
          ),
        ),
        const Spacer(),
        const _BoxMicroLabel('Tranzakció:'),
        const SizedBox(height: 2),
        _BoxSecondary(
          _secondaryContaining(metric, 'alkalom') ?? '',
          fontSize: 7.3,
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Összesen:'),
        const SizedBox(height: 2),
        _BoxSecondary(_secondaryEnding(metric, 'Ft') ?? '', fontSize: 7.3),
      ],
    );
  }
}

class _AverageDailyBoxContent extends StatelessWidget {
  const _AverageDailyBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Napi átlag'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(
          _secondaryStarting(metric, 'elmúlt') ?? 'elmúlt 30 nap átlaga',
        ),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Fixek nélkül'),
        const Spacer(),
        const _BoxMicroLabel('Költési ritmus:'),
        const SizedBox(height: 3),
        _AverageSpikeChart(
          key: ValueKey('fastinfo-average-line-${slot.id}'),
          values: metric?.visual.values ?? metric?.series ?? const <double>[],
          width: 98,
          height: 29,
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Elég még:'),
        const SizedBox(height: 2),
        _BoxBottomValue(_bufferDays(metric)),
      ],
    );
  }
}

class _NoSpendBoxContent extends StatelessWidget {
  const _NoSpendBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Költésmentes'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(
          _secondaryStarting(metric, 'aktuális') ?? 'aktuális hónapban',
        ),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Fixek nélkül'),
        const Spacer(),
        const _BoxMicroLabel('Havi ritmus:'),
        const SizedBox(height: 4),
        _NoSpendMonthStrip(
          key: ValueKey('fastinfo-no-spend-month-${slot.id}'),
          points: metric?.visual.points ?? const <FastInfoVisualPoint>[],
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Arány:'),
        const SizedBox(height: 2),
        _BoxBottomValue(_noSpendRatio(metric), color: AppColors.income),
      ],
    );
  }
}

class _TopCategoriesBoxContent extends StatelessWidget {
  const _TopCategoriesBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Top kategóriák'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(_secondaryStarting(metric, 'ma') ?? ''),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Fixek nélkül'),
        const Spacer(),
        const _BoxMicroLabel('Ma / hét / hó:'),
        const SizedBox(height: 4),
        _TopCategoryList(
          key: ValueKey('fastinfo-top-categories-list-${slot.id}'),
          points: metric?.visual.points ?? const <FastInfoVisualPoint>[],
        ),
      ],
    );
  }
}

class _CategoryChangeBoxContent extends StatelessWidget {
  const _CategoryChangeBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final semantic =
        metric?.trend?.semantic ??
        metric?.visual.semantic ??
        FastInfoSemantic.neutral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Kategóriaváltozás'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(_secondaryAt(metric, 0)),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Legnagyobb Ft változás'),
        const Spacer(),
        const _BoxMicroLabel('Mini vonal:'),
        const SizedBox(height: 3),
        _CategoryChangeLines(
          key: ValueKey('fastinfo-category-change-lines-${slot.id}'),
          values: metric?.visual.values ?? const <double>[],
          semantic: semantic,
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Változás:'),
        const SizedBox(height: 2),
        _BoxBottomValue(
          _secondaryAt(metric, 0),
          color: _fastInfoSemanticColor(semantic),
        ),
      ],
    );
  }
}

class _NextFixedBoxContent extends StatelessWidget {
  const _NextFixedBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Következő fix'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(_secondaryAt(metric, 0)),
        const SizedBox(height: 2),
        const _SmallBadge(text: 'Időzített'),
        const SizedBox(height: 2),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FastInfoAvatarBadge(
                key: ValueKey('fastinfo-next-fixed-avatar-${slot.id}'),
                avatar: metric?.avatar ?? metric?.visual.avatar,
                size: 20,
                iconSize: 12,
              ),
              _BoxSecondary(_secondaryAt(metric, 2), fontSize: 6.5),
            ],
          ),
        ),
        const Spacer(),
        const _BoxMicroLabel('Következő 7 nap:'),
        const SizedBox(height: 3),
        _FixedWeekBars(
          key: ValueKey('fastinfo-next-fixed-week-${slot.id}'),
          values: metric?.visual.values ?? const <double>[],
          width: double.infinity,
        ),
        const SizedBox(height: 2),
        _BoxSecondary(_secondaryAt(metric, 1), fontSize: 7),
      ],
    );
  }
}

class _MonthlyFixedBoxContent extends StatelessWidget {
  const _MonthlyFixedBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Havi fixek'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(_secondaryAt(metric, 0)),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Időzített'),
        const Spacer(),
        const _BoxMicroLabel('Levont / hátra:'),
        const SizedBox(height: 4),
        _MonthlyFixedSplit(
          key: ValueKey('fastinfo-monthly-fixed-split-${slot.id}'),
          done: metric?.visual.value,
          todo: metric?.visual.compareValue,
          width: double.infinity,
          height: 13,
        ),
        const SizedBox(height: 2),
        _SplitLabels(left: _splitDone(metric), right: _splitTodo(metric)),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Legnagyobb:'),
        const SizedBox(height: 2),
        _BoxBottomValue(_secondaryAt(metric, 2)),
      ],
    );
  }
}

class _MonthlyIncomeBoxContent extends StatelessWidget {
  const _MonthlyIncomeBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Havi bevétel'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(
          _secondaryStarting(metric, 'eddig') ?? 'eddig beérkezett',
        ),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Ghost bevétel kell'),
        const Spacer(),
        const _BoxMicroLabel('Bevételi tempó:'),
        const SizedBox(height: 3),
        _IncomeBars(
          key: ValueKey('fastinfo-income-bars-${slot.id}'),
          previous: metric?.visual.compareValue,
          current: metric?.visual.value,
          expected: metric?.visual.marker,
        ),
        const SizedBox(height: 2),
        const Center(
          child: _BoxSecondary('előző / most / várt', fontSize: 6.3),
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Fedezet:'),
        const SizedBox(height: 2),
        _BoxBottomValue(_coverageDays(metric)),
      ],
    );
  }
}

class _IncomeSpentBoxContent extends StatelessWidget {
  const _IncomeSpentBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final semantic =
        metric?.visual.semantic ?? metric?.semantic ?? FastInfoSemantic.neutral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BoxTitle('Bevétel elköltve'),
        const SizedBox(height: 3),
        _BoxPrimary(metric?.primaryValue ?? 'Nincs adat'),
        _BoxSecondary(_secondaryAt(metric, 0)),
        const SizedBox(height: 3),
        const _SmallBadge(text: 'Valós kiadás'),
        const Spacer(),
        const _BoxMicroLabel('Arány:'),
        const SizedBox(height: 4),
        _IncomeSpentRatioBar(
          key: ValueKey('fastinfo-income-spent-ratio-${slot.id}'),
          ratio: metric?.visual.compareValue ?? metric?.progress,
          semantic: semantic,
        ),
        const SizedBox(height: 2),
        const Center(
          child: _BoxSecondary(
            'zöld <75 · sárga 75-100 · piros >100',
            fontSize: 5.8,
          ),
        ),
        const SizedBox(height: 4),
        const _BoxMicroLabel('Összes tartalék:'),
        const SizedBox(height: 2),
        _BoxBottomValue(_reserveText(metric)),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: 6.2,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}

class _BoxBottomValue extends StatelessWidget {
  const _BoxBottomValue(this.text, {this.color = AppColors.gray800});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 10.4,
        fontWeight: FontWeight.w900,
        height: 1.0,
      ),
    );
  }
}

class _AverageSpikeChart extends StatelessWidget {
  const _AverageSpikeChart({
    super.key,
    required this.values,
    required this.width,
    required this.height,
    this.markSpikes = false,
  });

  final List<double> values;
  final double width;
  final double height;
  final bool markSpikes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparkLinePainter(
          values: values.isEmpty ? const <double>[1, 2, 1.4, 2.2] : values,
          lineColor: const Color(0xFF06B6D4),
          markSpikes: markSpikes,
        ),
      ),
    );
  }
}

class _NoSpendWeekStrip extends StatelessWidget {
  const _NoSpendWeekStrip({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final visible = values.isEmpty
        ? const <double>[0, 0, 0, 0, 0, 0, 0]
        : values.take(7).toList(growable: false);
    return SizedBox(
      width: 78,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < visible.length; index += 1) ...[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visible[index] > 0
                      ? AppColors.income
                      : AppColors.expense,
                  borderRadius: BorderRadius.circular(3),
                  border: index == visible.length - 1
                      ? Border.all(color: const Color(0xFF06B6D4), width: 1)
                      : null,
                ),
                child: const SizedBox(height: 12),
              ),
            ),
            if (index < visible.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _NoSpendMonthStrip extends StatelessWidget {
  const _NoSpendMonthStrip({super.key, required this.points});

  final List<FastInfoVisualPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.isEmpty
        ? List<FastInfoVisualPoint>.generate(
            31,
            (index) => FastInfoVisualPoint(label: '${index + 1}', value: 0),
          )
        : points.take(31).toList(growable: false);
    return SizedBox(
      width: 98,
      height: 17,
      child: Row(
        children: [
          for (var index = 0; index < visible.length; index += 1) ...[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visible[index].isFuture
                      ? AppColors.gray300
                      : visible[index].value > 0
                      ? AppColors.income
                      : AppColors.expense,
                  borderRadius: BorderRadius.circular(2),
                  border: visible[index].isToday
                      ? Border.all(color: const Color(0xFF06B6D4), width: 1)
                      : null,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            if (index < visible.length - 1) const SizedBox(width: 1),
          ],
        ],
      ),
    );
  }
}

class _TopCategoryIcons extends StatelessWidget {
  const _TopCategoryIcons({super.key, required this.points});

  final List<FastInfoVisualPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.take(3).toList(growable: false);
    return SizedBox(
      width: 80,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < visible.length; index += 1) ...[
            _FastInfoAvatarBadge(
              avatar: visible[index].avatar,
              size: 21,
              iconSize: 12,
            ),
            if (index < visible.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _TopCategoryList extends StatelessWidget {
  const _TopCategoryList({super.key, required this.points});

  final List<FastInfoVisualPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.take(3).toList(growable: false);
    return Column(
      children: [
        for (final point in visible) ...[
          Row(
            children: [
              SizedBox(
                width: 16,
                child: _BoxSecondary(
                  _categoryPointPeriod(point),
                  fontSize: 6.6,
                ),
              ),
              _FastInfoAvatarBadge(
                avatar: point.avatar,
                size: 16,
                iconSize: 10,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${_categoryPointName(point)} ${_compactMetricAmount(point.value)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 6.8,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
        ],
      ],
    );
  }
}

class _CategoryChangeMeter extends StatelessWidget {
  const _CategoryChangeMeter({
    super.key,
    required this.value,
    required this.semantic,
  });

  final double? value;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final delta = (value ?? 0).clamp(-1.0, 1.0).toDouble();
    final widthFactor = delta.abs().clamp(.06, 1.0).toDouble();
    final color = _fastInfoSemanticColor(semantic);
    return SizedBox(
      width: 78,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 9,
            height: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 2,
            width: 2,
            height: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            left: delta >= 0 ? 39 : 39 - 31 * widthFactor,
            top: 6,
            width: 31 * widthFactor,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChangeLines extends StatelessWidget {
  const _CategoryChangeLines({
    super.key,
    required this.values,
    required this.semantic,
  });

  final List<double> values;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final previous = values.isNotEmpty ? values.first : 1.0;
    final current = values.length > 1 ? values[1] : previous;
    return SizedBox(
      width: 98,
      height: 29,
      child: CustomPaint(
        painter: _CategoryChangeLinesPainter(
          previous: previous,
          current: current,
          color: _fastInfoSemanticColor(semantic),
        ),
      ),
    );
  }
}

class _FixedWeekBars extends StatelessWidget {
  const _FixedWeekBars({super.key, required this.values, this.width = 80});

  final List<double> values;
  final double width;

  @override
  Widget build(BuildContext context) {
    final visible = values.isEmpty
        ? const <double>[0, 1, 0, 2, 0, 0, 0]
        : values.take(7).toList(growable: false);
    final maxValue = visible.fold<double>(0, math.max);
    var firstHitUsed = false;
    return SizedBox(
      width: width,
      height: 23,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < visible.length; index += 1) ...[
            Expanded(
              child: Builder(
                builder: (context) {
                  final hit = visible[index] > 0;
                  final isNext = hit && !firstHitUsed;
                  if (isNext) firstHitUsed = true;
                  return FractionallySizedBox(
                    heightFactor: maxValue <= 0
                        ? .10
                        : (visible[index] / maxValue)
                              .clamp(.10, 1.0)
                              .toDouble(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isNext
                            ? AppColors.primary
                            : hit
                            ? const Color(0xFF06B6D4)
                            : AppColors.gray200,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                        border: isNext
                            ? Border.all(
                                color: const Color(0xFF06B6D4),
                                width: 1,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (index < visible.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _MonthlyFixedSplit extends StatelessWidget {
  const _MonthlyFixedSplit({
    super.key,
    required this.done,
    required this.todo,
    this.width = 78,
    this.height = 12,
  });

  final double? done;
  final double? todo;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final left = (done ?? .78).clamp(0.0, 1.0).toDouble();
    final right = (todo ?? math.max(0.0, 1 - left)).clamp(0.0, 1.0).toDouble();
    final total = math.max(.001, left + right);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: width,
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: math.max(1, (left / total * 1000).round()),
              child: const ColoredBox(color: AppColors.gray400),
            ),
            Expanded(
              flex: math.max(1, (right / total * 1000).round()),
              child: const ColoredBox(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitLabels extends StatelessWidget {
  const _SplitLabels({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BoxSecondary(left, fontSize: 6),
        _BoxSecondary(right, fontSize: 6),
      ],
    );
  }
}

class _IncomeCompareBars extends StatelessWidget {
  const _IncomeCompareBars({
    super.key,
    required this.previous,
    required this.current,
  });

  final double? previous;
  final double? current;

  @override
  Widget build(BuildContext context) {
    return _IncomeBarsBase(
      width: 78,
      height: 22,
      values: <double>[previous ?? 0, current ?? 0],
      colors: const <Color>[AppColors.gray400, AppColors.income],
    );
  }
}

class _IncomeBars extends StatelessWidget {
  const _IncomeBars({
    super.key,
    required this.previous,
    required this.current,
    required this.expected,
  });

  final double? previous;
  final double? current;
  final double? expected;

  @override
  Widget build(BuildContext context) {
    return _IncomeBarsBase(
      width: 98,
      height: 25,
      values: <double>[previous ?? 0, current ?? 0, expected ?? current ?? 0],
      colors: const <Color>[
        AppColors.gray400,
        AppColors.income,
        Color(0xFFF59E0B),
      ],
    );
  }
}

class _IncomeBarsBase extends StatelessWidget {
  const _IncomeBarsBase({
    required this.width,
    required this.height,
    required this.values,
    required this.colors,
  });

  final double width;
  final double height;
  final List<double> values;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, math.max);
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < values.length; index += 1) ...[
            SizedBox(
              width: values.length == 2 ? 18 : 16,
              child: FractionallySizedBox(
                heightFactor: maxValue <= 0
                    ? .18
                    : (values[index] / maxValue).clamp(.18, 1.0).toDouble(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            if (index < values.length - 1)
              SizedBox(width: values.length == 2 ? 8 : 6),
          ],
        ],
      ),
    );
  }
}

class _IncomeSpentSplit extends StatelessWidget {
  const _IncomeSpentSplit({
    super.key,
    required this.remaining,
    required this.spent,
  });

  final double? remaining;
  final double? spent;

  @override
  Widget build(BuildContext context) {
    final left = (remaining ?? 0).clamp(0.0, 1.0).toDouble();
    final right = (spent ?? 0).clamp(0.0, 1.0).toDouble();
    final total = math.max(.001, left + right);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 78,
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: math.max(1, (left / total * 1000).round()),
              child: const ColoredBox(color: AppColors.income),
            ),
            Expanded(
              flex: math.max(1, (right / total * 1000).round()),
              child: const ColoredBox(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeSpentRatioBar extends StatelessWidget {
  const _IncomeSpentRatioBar({
    super.key,
    required this.ratio,
    required this.semantic,
  });

  final double? ratio;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final value = (ratio ?? 0).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 13,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.gray200),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: ColoredBox(color: _fastInfoSemanticColor(semantic)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionLimitMeter extends StatelessWidget {
  const _ProjectionLimitMeter({
    super.key,
    required this.value,
    required this.semantic,
  });

  final double? value;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final ratio = (value ?? 0).clamp(0.0, 1.5).toDouble();
    final fill = ratio.clamp(0.0, 1.0).toDouble();
    const chartLeft = 3.0;
    const chartWidth = 78.0;
    return SizedBox(
      width: 84,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: chartLeft,
            right: 3,
            top: 11,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.gray200),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: ColoredBox(color: _fastInfoSemanticColor(semantic)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: chartLeft + chartWidth * fill - 1,
            top: 4,
            width: 2,
            height: 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowProjectionMeter extends StatelessWidget {
  const _OverflowProjectionMeter({
    super.key,
    required this.value,
    required this.semantic,
  });

  final double? value;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final ratio = (value ?? 0).clamp(0.0, 1.5).toDouble();
    final over = ratio > 1;
    final fill = ratio.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 84,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 3,
            top: 11,
            width: over ? 62 : 78,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.gray200),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: ColoredBox(color: _fastInfoSemanticColor(semantic)),
                  ),
                ],
              ),
            ),
          ),
          if (over)
            const Positioned(
              left: 67,
              right: 3,
              top: 14,
              child: _DashedLine(color: AppColors.expense),
            ),
          Positioned(
            left: over ? 75 : 3 + 78 * fill - 1,
            top: 4,
            width: 2,
            height: 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: over ? AppColors.expense : const Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastRangeMeter extends StatelessWidget {
  const _ForecastRangeMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 19,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            right: 4,
            top: 8,
            height: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: const [
                  Expanded(
                    flex: 36,
                    child: ColoredBox(color: AppColors.income),
                  ),
                  Expanded(
                    flex: 38,
                    child: ColoredBox(color: Color(0xFFF59E0B)),
                  ),
                  Expanded(
                    flex: 26,
                    child: ColoredBox(color: AppColors.expense),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            right: 16,
            top: 7,
            height: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.gray700.withValues(alpha: .18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 58,
            top: 2,
            width: 2,
            height: 15,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TightestLimitProgress extends StatelessWidget {
  const _TightestLimitProgress({
    super.key,
    required this.progress,
    required this.semantic,
  });

  final double progress;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    return _DailyLimitProgress(progress: progress, semantic: semantic);
  }
}

class _MerchantDaysStrip extends StatelessWidget {
  const _MerchantDaysStrip({super.key, required this.points});

  final List<FastInfoVisualPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.isEmpty
        ? List<FastInfoVisualPoint>.generate(
            14,
            (index) => FastInfoVisualPoint(label: '${index + 1}', value: 0),
          )
        : points.take(14).toList(growable: false);
    return SizedBox(
      width: 84,
      height: 24,
      child: Center(
        child: SizedBox(
          width: 78,
          height: 14,
          child: Row(
            children: [
              for (var index = 0; index < visible.length; index += 1) ...[
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: visible[index].value > 0
                          ? const Color(0xFF3B82F6)
                          : AppColors.gray200,
                      borderRadius: BorderRadius.circular(2),
                      border: visible[index].isToday
                          ? Border.all(color: const Color(0xFF06B6D4))
                          : null,
                    ),
                    child: const SizedBox(height: 9),
                  ),
                ),
                if (index < visible.length - 1) const SizedBox(width: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ForecastLineChart extends StatelessWidget {
  const _ForecastLineChart({
    super.key,
    required this.values,
    required this.width,
    required this.height,
  });

  final List<double> values;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ForecastLineChartPainter(
          values.isEmpty ? const [1, 2, 1.4, 2.2] : values,
        ),
      ),
    );
  }
}

class _ForecastLineChartPainter extends CustomPainter {
  const _ForecastLineChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    for (final y in <double>[
      size.height * .82,
      size.height * .50,
      size.height * .18,
    ]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = maxValue - minValue;
    final path = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < values.length; index += 1) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final normalized = spread <= 0 ? .5 : (values[index] - minValue) / spread;
      final y = size.height - normalized * (size.height - 2) - 1;
      final point = Offset(x, y);
      offsets.add(point);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    if (offsets.isNotEmpty) {
      final today = offsets.last;
      final dotPaint = Paint()..color = const Color(0xFF06B6D4);
      canvas.drawCircle(today, 2.6, dotPaint);
      canvas.drawCircle(
        today,
        2.6,
        Paint()
          ..color = AppColors.white
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastLineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _SparkLinePainter extends CustomPainter {
  const _SparkLinePainter({
    required this.values,
    required this.lineColor,
    this.markSpikes = false,
  });

  final List<double> values;
  final Color lineColor;
  final bool markSpikes;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    for (final y in <double>[
      size.height * .82,
      size.height * .50,
      size.height * .18,
    ]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = maxValue - minValue;
    final path = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < values.length; index += 1) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final normalized = spread <= 0 ? .5 : (values[index] - minValue) / spread;
      final y = size.height - normalized * (size.height - 2) - 1;
      offsets.add(Offset(x, y));
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    if (!markSpikes) return;
    final average =
        values.fold<double>(0, (sum, value) => sum + value) / values.length;
    final spikePaint = Paint()..color = AppColors.expense;
    final strokePaint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (
      var index = 0;
      index < values.length && index < offsets.length;
      index += 1
    ) {
      if (average <= 0 || values[index] <= average * 1.5) continue;
      canvas.drawCircle(offsets[index], 2.5, spikePaint);
      canvas.drawCircle(offsets[index], 2.5, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.markSpikes != markSpikes;
  }
}

class _CategoryChangeLinesPainter extends CustomPainter {
  const _CategoryChangeLinesPainter({
    required this.previous,
    required this.current,
    required this.color,
  });

  final double previous;
  final double current;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    for (final y in <double>[
      size.height * .82,
      size.height * .50,
      size.height * .18,
    ]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final oldY = size.height * .62;
    final newY = current >= previous ? size.height * .25 : size.height * .72;
    final oldPath = Path()
      ..moveTo(1, oldY + 4)
      ..cubicTo(
        size.width * .25,
        oldY,
        size.width * .55,
        oldY - 2,
        size.width - 1,
        oldY,
      );
    final newPath = Path()
      ..moveTo(1, oldY + 6)
      ..cubicTo(
        size.width * .25,
        oldY + 2,
        size.width * .55,
        newY + 4,
        size.width - 1,
        newY,
      );
    canvas.drawPath(
      oldPath,
      Paint()
        ..color = AppColors.gray400
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      newPath,
      Paint()
        ..color = color
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryChangeLinesPainter oldDelegate) {
    return oldDelegate.previous != previous ||
        oldDelegate.current != current ||
        oldDelegate.color != color;
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedLinePainter(color));
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 4, size.width), 0),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RollingSplitBar extends StatelessWidget {
  const _RollingSplitBar({
    super.key,
    required this.slotId,
    required this.value,
  });

  final String slotId;
  final double? value;

  @override
  Widget build(BuildContext context) {
    const height = 13.0;
    const segmentKeyPrefix = 'fastinfo-rolling-split';
    final current = (value ?? 1).clamp(0.0, 3.0).toDouble();
    final total = 1 + current;
    final previousFlex = math.max(1, (1 / total * 1000).round());
    final currentFlex = math.max(1, (current / total * 1000).round());
    _logFastInfoDebugOnce(
      'rolling-split-$segmentKeyPrefix-$slotId',
      '[FastInfo][30dTrend] split slot=$slotId prefix=$segmentKeyPrefix '
          'index=${_debugNumber(current)} prevFlex=$previousFlex '
          'currentFlex=$currentFlex height=${_debugNumber(height)}',
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: previousFlex,
              child: ColoredBox(
                key: ValueKey('$segmentKeyPrefix-prev-$slotId'),
                color: AppColors.gray400,
              ),
            ),
            Expanded(
              flex: currentFlex,
              child: ColoredBox(
                key: ValueKey('$segmentKeyPrefix-current-$slotId'),
                color: current > 1 ? AppColors.expense : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollingPillBand extends StatelessWidget {
  const _RollingPillBand({required this.slotId, required this.value});

  final String slotId;
  final double? value;

  @override
  Widget build(BuildContext context) {
    const width = 78.0;
    const height = 18.0;
    final index = (value ?? 1).clamp(0.0, 3.0).toDouble();
    final needle = _rollingBandNeedle(index);
    final needleLeft = (width * needle - 1).clamp(0.0, width - 2).toDouble();
    _logFastInfoDebugOnce(
      'rolling-pill-band-$slotId',
      '[FastInfo][30dTrend] pill band slot=$slotId '
          'index=${_debugNumber(index)} needle=${_debugNumber(needle)} '
          'width=${_debugNumber(width)} height=${_debugNumber(height)}',
    );
    return SizedBox(
      key: ValueKey('fastinfo-rolling-pill-band-$slotId'),
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 7,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: [
                  SizedBox(
                    width: width * .36,
                    child: ColoredBox(
                      key: ValueKey('fastinfo-rolling-pill-band-low-$slotId'),
                      color: AppColors.income,
                    ),
                  ),
                  SizedBox(
                    width: width * .28,
                    child: ColoredBox(
                      key: ValueKey('fastinfo-rolling-pill-band-mid-$slotId'),
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      key: ValueKey('fastinfo-rolling-pill-band-high-$slotId'),
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: needleLeft,
            top: 1,
            width: 2,
            height: 17,
            child: DecoratedBox(
              key: ValueKey('fastinfo-rolling-pill-band-needle-$slotId'),
              decoration: BoxDecoration(
                color: AppColors.gray700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _rollingBandNeedle(double index) {
  if (index <= 0) return .5;
  if (index < 1) {
    return (index * .36).clamp(.04, .36).toDouble();
  }
  if (index <= 1.1) {
    return (.36 + ((index - 1) / .1) * .28).clamp(.36, .64).toDouble();
  }
  return (.64 + ((index - 1.1) / .4) * .32).clamp(.64, .96).toDouble();
}

String _debugNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('00') ? value.toStringAsFixed(0) : fixed;
}

class _FastInfoAvatarBadge extends StatelessWidget {
  const _FastInfoAvatarBadge({
    super.key,
    required this.avatar,
    required this.size,
    required this.iconSize,
  });

  final FastInfoAvatar? avatar;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final value = avatar;
    if (value == null) return SizedBox(width: size, height: size);
    return Center(
      child: CategoryIconBadge(
        colorSlot: 0,
        iconSlot: value.iconSlot,
        size: size,
        iconSize: iconSize,
        backgroundColor: AppColors.fromHex(value.colorHex),
        showShadow: false,
      ),
    );
  }
}

class _BoxTitle extends StatelessWidget {
  const _BoxTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.gray600,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );
  }
}

class _BoxPrimary extends StatelessWidget {
  const _BoxPrimary(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 15,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxSecondary extends StatelessWidget {
  const _BoxSecondary(this.text, {this.fontSize = 8});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.gray500,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
    );
  }
}

class _BoxMicroLabel extends StatelessWidget {
  const _BoxMicroLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.gray500,
        fontSize: 6.3,
        fontWeight: FontWeight.w900,
        height: 1.0,
      ),
    );
  }
}

class _DailySpendBoxContent extends StatelessWidget {
  const _DailySpendBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final values = metric?.secondaryValues ?? const <String>[];
    final transactionText = values.isNotEmpty ? values[0] : '';
    final remainingText = values.length > 1 ? values[1] : '';
    final compareText = metric?.trend == null
        ? (values.length > 2 ? values[2] : '')
        : 'Napi átlaghoz képest:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slot.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 15,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _dailyBoxPrimary(metric),
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (transactionText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            transactionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
        const Spacer(),
        if (metric?.progress != null) ...[
          const Text(
            'Napi keret:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.3,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          _DailyLimitProgress(
            key: ValueKey('fastinfo-daily-limit-progress-${slot.id}'),
            progress: metric!.progress!,
            semantic: metric!.semantic,
          ),
          if (remainingText.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              remainingText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 6.6,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ],
        if (compareText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _dailyCompareLabel(compareText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 6.3,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
        if (metric?.trend case final trend?) ...[
          const SizedBox(height: 3),
          _DailyTrendValue(trend: trend),
        ],
      ],
    );
  }

  String _dailyBoxPrimary(FastInfoMetricResult? value) {
    final primary = value?.primaryValue ?? value?.pillValue ?? 'Nincs adat';
    return primary.replaceFirst(RegExp(r'\s+elköltve$'), '');
  }

  String _dailyCompareLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase() == 'napi átlaghoz képest:') {
      return 'Napi átlaghoz képest:';
    }
    return trimmed;
  }
}

class _WeeklySpendBoxContent extends StatelessWidget {
  const _WeeklySpendBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final transactionText = _weeklyTransactionText(metric);
    final remainingText = _weeklyRemainingText(metric);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slot.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 14,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (transactionText.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            transactionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Fixek nélkül a keret',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.2,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'Heti ritmus:',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 6.3,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        _WeeklyBoxBars(
          key: ValueKey('fastinfo-weekly-bars-${slot.id}'),
          bars: metric?.weeklyBars ?? const <FastInfoWeeklyBar>[],
        ),
        if (remainingText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            remainingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 6.6,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
        if (metric?.trend case final trend?) ...[
          const SizedBox(height: 5),
          const Text(
            'Heti átlaghoz képest:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.3,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          _DailyTrendValue(trend: trend),
        ],
      ],
    );
  }
}

class _WeeklyBoxBars extends StatelessWidget {
  const _WeeklyBoxBars({super.key, required this.bars});

  final List<FastInfoWeeklyBar> bars;

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars.isEmpty
        ? List<FastInfoWeeklyBar>.filled(
            7,
            const FastInfoWeeklyBar(
              value: 0,
              isFuture: true,
              semantic: FastInfoSemantic.neutral,
            ),
          )
        : bars;
    var maxValue = 0.0;
    for (final bar in visibleBars) {
      if (!bar.isFuture && bar.value > maxValue) maxValue = bar.value;
    }
    if (maxValue <= 0) maxValue = 1;
    final firstFutureIndex = visibleBars.indexWhere((bar) => bar.isFuture);
    final todayIndex = firstFutureIndex == -1
        ? visibleBars.length - 1
        : firstFutureIndex <= 0
        ? 0
        : firstFutureIndex - 1;

    return SizedBox(
      height: 23,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < visibleBars.length; index += 1) ...[
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: visibleBars[index].isFuture
                      ? 0.22
                      : (visibleBars[index].value / maxValue)
                            .clamp(0.22, 1.0)
                            .toDouble(),
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _weeklyBarColor(visibleBars[index]),
                      borderRadius: BorderRadius.circular(2),
                      border:
                          index == todayIndex && !visibleBars[index].isFuture
                          ? Border.all(color: const Color(0xFF06B6D4), width: 1)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (index < visibleBars.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

Color _weeklyBarColor(FastInfoWeeklyBar bar) {
  if (bar.isFuture) return AppColors.gray200;
  return _fastInfoSemanticColor(bar.semantic);
}

String? _secondaryStarting(FastInfoMetricResult? metric, String prefix) {
  final lowerPrefix = prefix.toLowerCase();
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().startsWith(lowerPrefix)) return trimmed;
  }
  return null;
}

String? _secondaryContaining(FastInfoMetricResult? metric, String fragment) {
  final lowerFragment = fragment.toLowerCase();
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().contains(lowerFragment)) return trimmed;
  }
  return null;
}

String? _secondaryEnding(FastInfoMetricResult? metric, String suffix) {
  final lowerSuffix = suffix.toLowerCase();
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().endsWith(lowerSuffix)) return trimmed;
  }
  return null;
}

String _secondaryAt(FastInfoMetricResult? metric, int index) {
  final values = metric?.secondaryValues ?? const <String>[];
  if (index < 0 || index >= values.length) return '';
  return values[index];
}

String _percentFromRatio(double ratio) => '${(ratio * 100).round()}%';

String _merchantCategoryName(FastInfoMetricResult? metric) {
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('tranzakció') ||
        trimmed.contains('alkalom') ||
        trimmed.contains('aktív nap') ||
        trimmed.endsWith('Ft') ||
        trimmed.startsWith('legtöbb')) {
      continue;
    }
    return trimmed;
  }
  return 'Kategória';
}

String _rollingPillSecondary(FastInfoMetricResult? metric) {
  final comparison = _secondaryStarting(metric, 'előző 30 naphoz');
  if (comparison != null) return comparison;
  final trend = metric?.trend;
  if (trend == null) {
    return _secondaryContaining(metric, 'fix') ?? '';
  }
  final arrow = trend.direction == FastInfoTrendDirection.up ? '↑' : '↓';
  final value = trend.text
      .replaceFirst(RegExp(r'^[↑↓]\s*'), '')
      .replaceFirst(RegExp(r'^\+'), '');
  return 'fix nélkül · $arrow$value';
}

String _topCategoriesPillSecondary(FastInfoMetricResult? metric) {
  final parts = <String>[];
  final week = _secondaryStarting(metric, 'Hét:');
  final month = _secondaryStarting(metric, 'Hó:');
  if (week != null) parts.add('Hét ${_lastAmountToken(week)}');
  if (month != null) parts.add('Hó ${_lastAmountToken(month)}');
  return parts.join(' · ');
}

String _afterSeparator(String value) {
  final parts = value.split('·').map((part) => part.trim()).toList();
  return parts.length > 1 ? parts.last : value;
}

String _bufferDays(FastInfoMetricResult? metric) {
  final value = _secondaryStarting(metric, 'Puffer:');
  if (value == null) return '';
  return value.replaceFirst(RegExp(r'^Puffer:\s*'), '');
}

String _noSpendRatio(FastInfoMetricResult? metric) {
  final value = _secondaryStarting(metric, 'arány:');
  if (value == null) return '';
  return value.replaceFirst(RegExp(r'^arány:\s*'), '');
}

String _coverageDays(FastInfoMetricResult? metric) {
  final value = _secondaryStarting(metric, 'Fedezet:');
  if (value == null) return '';
  return value.replaceFirst(RegExp(r'^Fedezet:\s*'), '');
}

String _reserveText(FastInfoMetricResult? metric) {
  final value = _secondaryStarting(metric, 'Összes tartalék:');
  if (value == null) return '';
  return value.replaceFirst(RegExp(r'^Összes tartalék:\s*'), '');
}

String _splitDone(FastInfoMetricResult? metric) {
  final value = _secondaryAt(metric, 0);
  final match = RegExp(r'levonva\s+([^·]+)').firstMatch(value);
  return match?.group(1)?.trim() ?? '';
}

String _splitTodo(FastInfoMetricResult? metric) {
  final value = _secondaryAt(metric, 0);
  final match = RegExp(r'hátra\s+(.+)$').firstMatch(value);
  return match?.group(1)?.trim() ?? '';
}

String _lastAmountToken(String value) {
  final parts = value
      .split(RegExp(r'[· ]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  return parts.last;
}

String _categoryPointName(FastInfoVisualPoint point) {
  final label = point.label.trim();
  if (label.isEmpty) return 'Kategória';
  final parts = label.split('|');
  if (parts.length < 2) return label;
  final name = parts.sublist(1).join('|').trim();
  return name.isEmpty ? 'Kategória' : name;
}

String _categoryPointPeriod(FastInfoVisualPoint point) {
  final label = point.label.trim();
  if (label.isEmpty) return '';
  return label.split('|').first.trim();
}

String _compactDisplayAmount(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final digits = value.replaceAll(RegExp(r'[^0-9-]'), '');
  final amount = int.tryParse(digits);
  if (amount == null) return value;
  return _compactMetricAmount(amount);
}

String _compactMetricAmount(num amount) {
  final value = amount.abs();
  if (value >= 1000000) return '${_trimCompact(value / 1000000)}M';
  if (value >= 1000) return '${_trimCompact(value / 1000)}k';
  return value.round().toString();
}

String _trimCompact(num value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1);
}

List<String> _latestMerchantCategory(FastInfoMetricResult? metric) {
  final raw = metric?.secondaryValues.isNotEmpty == true
      ? metric!.secondaryValues.first
      : 'Névtelen tranzakció · Nincs kategória';
  final parts = raw
      .split('·')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return const ['Névtelen tranzakció', 'Nincs kategória'];
  if (parts.length == 1) return [parts.first, ''];
  return [parts.first, parts[1]];
}

String _positiveCompact(FastInfoMetricResult? metric) {
  final value = metric?.pillValue ?? metric?.primaryValue ?? '';
  if (value.isEmpty || value.startsWith('+') || value.startsWith('-')) {
    return value;
  }
  return '+$value';
}

String _compactPreviousLabel(String? value) {
  if (value == null) return '';
  return value.replaceFirst(RegExp(r'^előző 30 nap:\s*'), '');
}

String _weeklyTransactionText(FastInfoMetricResult? metric) {
  return _weeklySecondaryWhere(metric, (value) => value.contains('tranzakció'));
}

String _weeklyRemainingText(FastInfoMetricResult? metric) {
  return _weeklySecondaryWhere(metric, (value) => value.endsWith('költhető'));
}

String _weeklyPaceText(FastInfoMetricResult? metric) {
  return _weeklySecondaryWhere(
    metric,
    (value) => value.startsWith('időarányhoz képest'),
  );
}

String _weeklySecondaryWhere(
  FastInfoMetricResult? metric,
  bool Function(String value) test,
) {
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (test(trimmed)) return trimmed;
  }
  return '';
}

class _MonthlySpendBoxContent extends StatelessWidget {
  const _MonthlySpendBoxContent({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slot.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray600,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 14,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric?.primaryValue ?? metric?.pillValue ?? 'Nincs adat',
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'aktuális hó eddig',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Előző hó azonos napjáig',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.2,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'Havi vonal:',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 6.3,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        _MonthlyLineChart(
          key: ValueKey('fastinfo-monthly-line-${slot.id}'),
          series: metric?.chartSeries ?? const <FastInfoChartSeries>[],
        ),
        const SizedBox(height: 2),
        const Text(
          'előző / aktuális / előző előtti',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 6.6,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        if (metric?.trend case final trend?) ...[
          const SizedBox(height: 4),
          const Text(
            'Azonos napig:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 6.3,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          _DailyTrendValue(trend: trend),
        ],
      ],
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  const _MonthlyLineChart({super.key, required this.series});

  final List<FastInfoChartSeries> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((item) => item.values.isEmpty)) {
      return const SizedBox(height: 29);
    }
    return SizedBox(
      height: 29,
      width: double.infinity,
      child: CustomPaint(painter: _MonthlyLineChartPainter(series)),
    );
  }
}

class _MonthlyLineChartPainter extends CustomPainter {
  const _MonthlyLineChartPainter(this.series);

  final List<FastInfoChartSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = _monthlyOrderedSeries(series);
    final values = ordered.expand((item) => item.values).toList();
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final spread = maxValue - minValue;
    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    for (final y in <double>[
      size.height * .82,
      size.height * .50,
      size.height * .18,
    ]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final colors = <Color>[
      AppColors.gray500,
      AppColors.expense,
      AppColors.gray300,
    ];
    for (var seriesIndex = 0; seriesIndex < ordered.length; seriesIndex += 1) {
      final points = ordered[seriesIndex].values;
      if (points.isEmpty) continue;
      final paint = Paint()
        ..color = colors[seriesIndex % colors.length]
        ..strokeWidth = seriesIndex == 1 ? 1.8 : 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var index = 0; index < points.length; index += 1) {
        final x = points.length == 1
            ? 0.0
            : size.width * index / (points.length - 1);
        final normalized = spread <= 0
            ? .5
            : (points[index] - minValue) / spread;
        final y = size.height - normalized * (size.height - 2) - 1;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  List<FastInfoChartSeries> _monthlyOrderedSeries(
    List<FastInfoChartSeries> source,
  ) {
    FastInfoChartSeries? byLabel(String label) {
      for (final item in source) {
        if (item.label.toLowerCase() == label.toLowerCase()) return item;
      }
      return null;
    }

    return <FastInfoChartSeries>[
      ?byLabel('Előző'),
      ?byLabel('Aktuális'),
      ?byLabel('Két hónapja'),
      for (final item in source)
        if (item.label != 'Előző' &&
            item.label != 'Aktuális' &&
            item.label != 'Két hónapja')
          item,
    ];
  }

  @override
  bool shouldRepaint(covariant _MonthlyLineChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

String _monthlyIndexText(FastInfoMetricResult? metric) {
  for (final value in metric?.secondaryValues ?? const <String>[]) {
    final trimmed = value.trim();
    if (trimmed.startsWith('előző hónap index:')) return trimmed;
  }
  return '';
}

class _DailyLimitProgress extends StatelessWidget {
  const _DailyLimitProgress({
    super.key,
    required this.progress,
    required this.semantic,
  });

  final double progress;
  final FastInfoSemantic semantic;

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.gray200),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: ColoredBox(color: _fastInfoSemanticColor(semantic)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTrendValue extends StatelessWidget {
  const _DailyTrendValue({required this.trend});

  final FastInfoTrend trend;

  @override
  Widget build(BuildContext context) {
    final color = _fastInfoSemanticColor(trend.semantic);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend.direction == FastInfoTrendDirection.up
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          trend.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

Color _fastInfoSemanticColor(FastInfoSemantic semantic) {
  return switch (semantic) {
    FastInfoSemantic.neutral => AppColors.primary,
    FastInfoSemantic.good => AppColors.income,
    FastInfoSemantic.warning => const Color(0xFFF59E0B),
    FastInfoSemantic.bad => AppColors.expense,
  };
}

class _DropReadyFrame extends StatelessWidget {
  const _DropReadyFrame({
    required this.frameKey,
    required this.dropReady,
    required this.radius,
    required this.child,
  });

  final Key frameKey;
  final bool dropReady;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: frameKey,
      duration: const Duration(milliseconds: 120),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dropReady ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
