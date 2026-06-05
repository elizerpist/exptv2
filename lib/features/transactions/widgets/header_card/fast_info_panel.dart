import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../state/fast_info_metrics_resolver.dart';
import 'fast_info_card_surfaces.dart';

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
    this.onCardTap,
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
  final ValueChanged<String>? onCardTap;

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
            child: config.layoutMode == FastInfoLayoutMode.sixBoxes
                ? _buildUpperBoxRow()
                : _buildPillColumn(),
          ),
          Positioned(
            top: boxTop,
            left: 20,
            right: 20,
            child: _buildBoxRow(
              slots: config.boxes,
              slotKeyPrefix: 'fastinfo-box',
              dropKeyPrefix: 'fastinfo-box',
              clearKeyPrefix: 'fastinfo-clear-box',
              onDropCard: onDropBoxCard,
              onClear: onClearBoxSlot,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillColumn() {
    return Column(
      children: [
        for (var i = 0; i < 3; i += 1) ...[
          FastInfoPillCard(
            slot: config.pills[i],
            metric: _metricFor(config.pills[i]),
            index: i,
            onDropCard: onDropPillCard,
            onClear: onClearPillSlot,
            onTap: onCardTap,
          ),
          if (i != 2) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildUpperBoxRow() {
    return _buildBoxRow(
      slots: [
        for (final slot in config.pills) slot?.asType(FastInfoSlotType.box),
      ],
      slotKeyPrefix: 'fastinfo-upper-box',
      dropKeyPrefix: 'fastinfo-pill',
      clearKeyPrefix: 'fastinfo-clear-pill',
      onDropCard: onDropPillCard,
      onClear: onClearPillSlot,
    );
  }

  Widget _buildBoxRow({
    required List<FastInfoSlot?> slots,
    required String slotKeyPrefix,
    required String dropKeyPrefix,
    required String clearKeyPrefix,
    required FastInfoCardDropCallback? onDropCard,
    required ValueChanged<int>? onClear,
  }) {
    return Row(
      children: [
        for (var i = 0; i < 3; i += 1) ...[
          Expanded(
            child: FastInfoBoxCard(
              slot: slots[i],
              metric: _metricFor(slots[i]),
              index: i,
              slotKeyPrefix: slotKeyPrefix,
              dropKeyPrefix: dropKeyPrefix,
              clearKeyPrefix: clearKeyPrefix,
              onDropCard: onDropCard,
              onClear: onClear,
              onTap: onCardTap,
            ),
          ),
          if (i != 2) const SizedBox(width: 10),
        ],
      ],
    );
  }

  FastInfoMetricResult? _metricFor(FastInfoSlot? slot) {
    if (slot == null) return null;
    return metrics[slot.id];
  }
}
