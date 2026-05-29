import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';

class FastInfoPanel extends StatelessWidget {
  const FastInfoPanel({
    super.key,
    required this.config,
    this.backgroundColor = AppColors.gray100,
  });

  final FastInfoConfig config;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('fast-info-panel'),
      height: 300,
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned(
            top: 54,
            left: 20,
            right: 20,
            child: Column(
              children: [
                for (var i = 0; i < 3; i += 1) ...[
                  _FastInfoPill(slot: config.pills[i], index: i),
                  if (i != 2) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Positioned(
            top: 202,
            left: 20,
            right: 20,
            child: Row(
              children: [
                for (var i = 0; i < 3; i += 1) ...[
                  Expanded(child: _FastInfoBox(slot: config.boxes[i], index: i)),
                  if (i != 2) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FastInfoPill extends StatelessWidget {
  const _FastInfoPill({required this.slot, required this.index});

  final FastInfoSlot? slot;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: slot == null ? Border.all(color: AppColors.gray300, style: BorderStyle.solid) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              slot?.label ?? 'Üres pill slot',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: slot == null ? AppColors.gray400 : AppColors.gray800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (slot != null)
            Text(
              slot!.value,
              style: const TextStyle(color: AppColors.gray600),
            ),
        ],
      ),
    );
  }
}

class _FastInfoBox extends StatelessWidget {
  const _FastInfoBox({required this.slot, required this.index});

  final FastInfoSlot? slot;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: slot == null ? Border.all(color: AppColors.gray300) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot?.label ?? 'Üres box',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: slot == null ? AppColors.gray400 : AppColors.gray600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            slot?.value ?? 'Slot',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (slot?.extra != null)
            Text(
              slot!.extra!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.expense, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
