import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../state/fast_info_metrics_resolver.dart';
import 'fast_info_visuals.dart';

typedef FastInfoCardDropCallback = void Function(int index, String cardId);

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
              child: const Row(
                children: [
                  Expanded(
                    flex: 33,
                    child: ColoredBox(color: AppColors.income),
                  ),
                  Expanded(
                    flex: 32,
                    child: ColoredBox(color: Color(0xFFF59E0B)),
                  ),
                  Expanded(
                    flex: 35,
                    child: ColoredBox(color: AppColors.expense),
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
