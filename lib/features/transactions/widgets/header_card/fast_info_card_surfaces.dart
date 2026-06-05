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
