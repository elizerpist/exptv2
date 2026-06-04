import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../state/fast_info_metrics_resolver.dart';
import 'fast_info_visuals.dart';

typedef FastInfoCardDropCallback = void Function(int index, String cardId);

class FastInfoPanel extends StatelessWidget {
  const FastInfoPanel({
    super.key,
    required this.config,
    this.backgroundColor = AppColors.gray100,
    this.pillTop = 54,
    this.boxTop = 202,
    this.metrics = const <String, FastInfoMetricResult>{},
    this.onDropPillCard,
    this.onDropBoxCard,
    this.onClearPillSlot,
    this.onClearBoxSlot,
  });

  final FastInfoConfig config;
  final Color backgroundColor;
  final Map<String, FastInfoMetricResult> metrics;
  final double pillTop;
  final double boxTop;
  final FastInfoCardDropCallback? onDropPillCard;
  final FastInfoCardDropCallback? onDropBoxCard;
  final ValueChanged<int>? onClearPillSlot;
  final ValueChanged<int>? onClearBoxSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('fast-info-panel'),
      height: 328,
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned(
            top: pillTop,
            left: 20,
            right: 20,
            child: Column(
              children: [
                for (var i = 0; i < 3; i += 1) ...[
                  _FastInfoPill(
                    slot: config.pills[i],
                    metric: _metricFor(config.pills[i]),
                    index: i,
                    onDropCard: onDropPillCard,
                    onClear: onClearPillSlot,
                  ),
                  if (i != 2) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Positioned(
            top: boxTop,
            left: 20,
            right: 20,
            child: Row(
              children: [
                for (var i = 0; i < 3; i += 1) ...[
                  Expanded(
                    child: _FastInfoBox(
                      slot: config.boxes[i],
                      metric: _metricFor(config.boxes[i]),
                      index: i,
                      onDropCard: onDropBoxCard,
                      onClear: onClearBoxSlot,
                    ),
                  ),
                  if (i != 2) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  FastInfoMetricResult? _metricFor(FastInfoSlot? slot) {
    if (slot == null) return null;
    return metrics[slot.id];
  }
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

class _FastInfoPill extends StatelessWidget {
  const _FastInfoPill({
    required this.slot,
    required this.metric,
    required this.index,
    this.onDropCard,
    this.onClear,
  });

  final FastInfoSlot? slot;
  final FastInfoMetricResult? metric;
  final int index;
  final FastInfoCardDropCallback? onDropCard;
  final ValueChanged<int>? onClear;

  @override
  Widget build(BuildContext context) {
    return _wrapDropTarget(
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: ValueKey('fastinfo-pill-slot-$index'),
            width: double.infinity,
            height: 38,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    metric?.pillValue ??
                        (slot == null ? 'Üres pill slot' : 'Nincs adat'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: slot == null
                          ? AppColors.gray400
                          : AppColors.gray800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (metric?.trend case final trend?) ...[
                  const SizedBox(width: 5),
                  FastInfoPillTrend(
                    key: ValueKey('fastinfo-trend-${slot!.id}'),
                    slotId: slot!.id,
                    trend: trend,
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null && slot != null)
            Positioned(
              right: 2,
              top: 1,
              child: IconButton(
                key: ValueKey('fastinfo-clear-pill-$index'),
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

  Widget _wrapDropTarget(Widget child) {
    if (onDropCard == null) return child;
    return DragTarget<String>(
      key: ValueKey('fastinfo-pill-drop-$index'),
      onAcceptWithDetails: (details) => onDropCard!(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final dropReady = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: dropReady ? 1.03 : 1,
          duration: const Duration(milliseconds: 120),
          child: _DropReadyFrame(
            frameKey: ValueKey('fastinfo-pill-drop-frame-$index'),
            dropReady: dropReady,
            radius: 20,
            child: child,
          ),
        );
      },
    );
  }
}

class _FastInfoBox extends StatelessWidget {
  const _FastInfoBox({
    required this.slot,
    required this.metric,
    required this.index,
    this.onDropCard,
    this.onClear,
  });

  final FastInfoSlot? slot;
  final FastInfoMetricResult? metric;
  final int index;
  final FastInfoCardDropCallback? onDropCard;
  final ValueChanged<int>? onClear;

  @override
  Widget build(BuildContext context) {
    return _wrapDropTarget(
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: ValueKey('fastinfo-box-slot-$index'),
            width: double.infinity,
            height: 112,
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
          if (onClear != null && slot != null)
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                key: ValueKey('fastinfo-clear-box-$index'),
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
      key: ValueKey('fastinfo-box-drop-$index'),
      onAcceptWithDetails: (details) => onDropCard!(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final dropReady = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: dropReady ? 1.03 : 1,
          duration: const Duration(milliseconds: 120),
          child: _DropReadyFrame(
            frameKey: ValueKey('fastinfo-box-drop-frame-$index'),
            dropReady: dropReady,
            radius: 8,
            child: child,
          ),
        );
      },
    );
  }
}
