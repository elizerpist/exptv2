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
    this.pillTop = 44,
    this.boxTop = 192,
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
            child: _buildPresentationRow(
              presentation: config.upperRowPresentation,
              slots: config.pills,
              pillSlotKeyPrefix: 'fastinfo-pill',
              pillDropKeyPrefix: 'fastinfo-pill',
              pillClearKeyPrefix: 'fastinfo-clear-pill',
              boxSlotKeyPrefix: 'fastinfo-upper-box',
              boxDropKeyPrefix: 'fastinfo-pill',
              boxClearKeyPrefix: 'fastinfo-clear-pill',
              onDropCard: onDropPillCard,
              onClear: onClearPillSlot,
            ),
          ),
          Positioned(
            top: boxTop,
            left: 20,
            right: 20,
            child: _buildPresentationRow(
              presentation: config.lowerRowPresentation,
              slots: config.boxes,
              pillSlotKeyPrefix: 'fastinfo-lower-pill',
              pillDropKeyPrefix: 'fastinfo-lower-pill',
              pillClearKeyPrefix: 'fastinfo-clear-box',
              boxSlotKeyPrefix: 'fastinfo-box',
              boxDropKeyPrefix: 'fastinfo-box',
              boxClearKeyPrefix: 'fastinfo-clear-box',
              onDropCard: onDropBoxCard,
              onClear: onClearBoxSlot,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationRow({
    required FastInfoRowPresentation presentation,
    required List<FastInfoSlot?> slots,
    required String pillSlotKeyPrefix,
    required String pillDropKeyPrefix,
    required String pillClearKeyPrefix,
    required String boxSlotKeyPrefix,
    required String boxDropKeyPrefix,
    required String boxClearKeyPrefix,
    required FastInfoCardDropCallback? onDropCard,
    required ValueChanged<int>? onClear,
  }) {
    return switch (presentation) {
      FastInfoRowPresentation.pill => _buildPillColumn(
        slots: slots,
        slotKeyPrefix: pillSlotKeyPrefix,
        dropKeyPrefix: pillDropKeyPrefix,
        clearKeyPrefix: pillClearKeyPrefix,
        onDropCard: onDropCard,
        onClear: onClear,
      ),
      FastInfoRowPresentation.box => _buildBoxRow(
        slots: slots,
        slotKeyPrefix: boxSlotKeyPrefix,
        dropKeyPrefix: boxDropKeyPrefix,
        clearKeyPrefix: boxClearKeyPrefix,
        onDropCard: onDropCard,
        onClear: onClear,
      ),
    };
  }

  Widget _buildPillColumn({
    required List<FastInfoSlot?> slots,
    required String slotKeyPrefix,
    required String dropKeyPrefix,
    required String clearKeyPrefix,
    required FastInfoCardDropCallback? onDropCard,
    required ValueChanged<int>? onClear,
  }) {
    return Column(
      children: [
        for (var i = 0; i < 3; i += 1) ...[
          FastInfoPillCard(
            slot: slots[i]?.asType(FastInfoSlotType.pill),
            metric: _metricFor(slots[i]),
            index: i,
            slotKeyPrefix: slotKeyPrefix,
            dropKeyPrefix: dropKeyPrefix,
            clearKeyPrefix: clearKeyPrefix,
            onDropCard: onDropCard,
            onClear: onClear,
            onTap: onCardTap,
          ),
          if (i != 2) const SizedBox(height: 10),
        ],
      ],
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
              slot: slots[i]?.asType(FastInfoSlotType.box),
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
