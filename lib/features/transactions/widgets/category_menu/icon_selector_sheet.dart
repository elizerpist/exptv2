import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../slots/category_icon_manager.dart';
import '../category_slot_icon.dart';

class IconSelectorSheet extends StatelessWidget {
  const IconSelectorSheet({
    super.key,
    required this.selectedIconName,
    required this.onSelected,
    this.accentColor = AppColors.primary,
  });

  final String selectedIconName;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            key: const ValueKey('icon-selector-sheet'),
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: GridView.builder(
                      key: const ValueKey('icon-selector-grid'),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 56,
                          ),
                      itemCount: CategoryIconManager.iconOptions.length,
                      itemBuilder: (context, index) {
                        final option = CategoryIconManager.iconOptions[index];
                        final selected = option.name == selectedIconName;
                        return _IconSelectorOption(
                          key: ValueKey('icon-selector-option-${option.name}'),
                          option: option,
                          selected: selected,
                          accentColor: accentColor,
                          onSelected: onSelected,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSelectorOption extends StatelessWidget {
  const _IconSelectorOption({
    super.key,
    required this.option,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  final CategoryIconOption option;
  final bool selected;
  final Color accentColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onSelected(option.name);
      },
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? accentColor : AppColors.gray200,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.12 : 0.06),
                offset: const Offset(0, 2),
                blurRadius: selected ? 4 : 3,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: CategorySlotIcon(
            iconName: option.name,
            color: selected ? accentColor : AppColors.gray600,
            size: _iconSize(option.name),
            listenForSlotChanges: false,
          ),
        ),
      ),
    );
  }

  double _iconSize(String name) {
    return switch (name) {
      'fingerprint-pattern' => 20,
      'hand-coins' => 21,
      'radiation' => 21,
      _ => 23,
    };
  }
}
