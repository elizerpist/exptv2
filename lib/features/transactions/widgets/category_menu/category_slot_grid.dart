import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../slots/category_color_manager.dart';
import '../../slots/category_icon_manager.dart';

class CategorySlotGrid extends StatelessWidget {
  const CategorySlotGrid.colors({
    super.key,
    required this.selectedSlot,
    required this.onSelected,
  }) : mode = _SlotGridMode.colors;

  const CategorySlotGrid.icons({
    super.key,
    required this.selectedSlot,
    required this.onSelected,
  }) : mode = _SlotGridMode.icons;

  final _SlotGridMode mode;
  final int selectedSlot;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final slots = mode == _SlotGridMode.colors
        ? CategoryColorManager.slots
        : CategoryIconManager.slots;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 48,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final selected = selectedSlot == slot;
        return GestureDetector(
          key: ValueKey(
            mode == _SlotGridMode.colors
                ? 'color-slot-$slot'
                : 'icon-slot-$slot',
          ),
          onTap: () => onSelected(slot),
          child: mode == _SlotGridMode.colors
              ? _ColorSlot(slot: slot, selected: selected)
              : _IconSlot(slot: slot, selected: selected),
        );
      },
    );
  }
}

enum _SlotGridMode { colors, icons }

class _ColorSlot extends StatelessWidget {
  const _ColorSlot({required this.slot, required this.selected});

  final int slot;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: AppColors.primary, width: 3)
            : null,
      ),
      padding: EdgeInsets.all(selected ? 2 : 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CategoryColorManager.color(slot),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({required this.slot, required this.selected});

  final int slot;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.gray100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.gray200,
          width: selected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.15 : 0.08),
            offset: const Offset(0, 2),
            blurRadius: selected ? 4 : 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ImageIcon(
        CategoryIconManager.assetImage(slot),
        color: selected ? AppColors.white : AppColors.gray500,
        size: 32,
      ),
    );
  }
}
