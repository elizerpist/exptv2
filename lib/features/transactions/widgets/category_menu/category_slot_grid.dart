import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../slots/category_color_manager.dart';
import '../../slots/category_icon_manager.dart';

class CategorySlotGrid extends StatelessWidget {
  const CategorySlotGrid.colors({
    super.key,
    required this.selectedSlot,
    required this.onSelected,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.selectedSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  }) : mode = CategorySlotGridMode.colors;

  const CategorySlotGrid.icons({
    super.key,
    required this.selectedSlot,
    required this.onSelected,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.selectedSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  }) : mode = CategorySlotGridMode.icons;

  final CategorySlotGridMode mode;
  final int selectedSlot;
  final ValueChanged<int> onSelected;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final slots = mode == CategorySlotGridMode.colors
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
            mode == CategorySlotGridMode.colors
                ? 'color-slot-$slot'
                : 'icon-slot-$slot',
          ),
          onTap: () => onSelected(slot),
          child: mode == CategorySlotGridMode.colors
              ? _ColorSlot(
                  slot: slot,
                  selected: selected,
                  surfaceStyle: surfaceStyle,
                  selectedSurfaceStyle: selectedSurfaceStyle,
                  accentColor: accentColor,
                )
              : _IconSlot(
                  slot: slot,
                  selected: selected,
                  surfaceStyle: surfaceStyle,
                  selectedSurfaceStyle: selectedSurfaceStyle,
                  accentColor: accentColor,
                ),
        );
      },
    );
  }
}

enum CategorySlotGridMode { colors, icons }

class _ColorSlot extends StatelessWidget {
  const _ColorSlot({
    required this.slot,
    required this.selected,
    required this.surfaceStyle,
    required this.selectedSurfaceStyle,
    required this.accentColor,
  });

  final int slot;
  final bool selected;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final style = selected ? selectedSurfaceStyle : surfaceStyle;
    if (style.hasPressEffect ||
        surfaceStyle.hasPressEffect ||
        selectedSurfaceStyle.hasPressEffect) {
      return ExpenseSurfaceContainer(
        surfaceKey: ValueKey('color-slot-surface-$slot'),
        style: style,
        color: CategoryColorManager.color(slot),
        borderRadius: BorderRadius.circular(24),
        pressed: false,
        primaryColor: CategoryColorManager.color(slot),
        child: const SizedBox.expand(),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? Border.all(color: accentColor, width: 3) : null,
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
  const _IconSlot({
    required this.slot,
    required this.selected,
    required this.surfaceStyle,
    required this.selectedSurfaceStyle,
    required this.accentColor,
  });

  final int slot;
  final bool selected;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final style = selected ? selectedSurfaceStyle : surfaceStyle;
    if (style.hasPressEffect ||
        surfaceStyle.hasPressEffect ||
        selectedSurfaceStyle.hasPressEffect) {
      return ExpenseSurfaceContainer(
        surfaceKey: ValueKey('icon-slot-surface-$slot'),
        style: style,
        color: selected ? accentColor : AppColors.gray100,
        borderRadius: BorderRadius.circular(25),
        pressed: false,
        primary: selected,
        primaryColor: accentColor,
        child: Center(
          child: ImageIcon(
            CategoryIconManager.assetImage(slot),
            color: selected ? AppColors.white : AppColors.gray500,
            size: 32,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: selected ? accentColor : AppColors.gray100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selected ? accentColor : AppColors.gray200,
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
