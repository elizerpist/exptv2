import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../slots/category_icon_manager.dart';

class CategorySlotIcon extends StatelessWidget {
  const CategorySlotIcon({
    super.key,
    this.slot,
    this.iconName,
    required this.color,
    required this.size,
    this.listenForSlotChanges = true,
  }) : assert(slot != null || iconName != null);

  final int? slot;
  final String? iconName;
  final Color color;
  final double size;
  final bool listenForSlotChanges;

  @override
  Widget build(BuildContext context) {
    if (!listenForSlotChanges) {
      return _buildIcon();
    }

    return ValueListenableBuilder<int>(
      valueListenable: CategoryIconManager.revision,
      builder: (_, _, _) => _buildIcon(),
    );
  }

  Widget _buildIcon() {
    return SvgPicture.asset(
      iconName == null
          ? CategoryIconManager.assetPath(slot)
          : CategoryIconManager.assetPathForIconName(iconName!),
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) =>
          Icon(Icons.category_outlined, color: color, size: size),
    );
  }
}
