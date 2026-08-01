import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../catalog/category_icon_catalog.dart';

class CategoryIconView extends StatelessWidget {
  const CategoryIconView({
    required this.iconId,
    this.size = 24,
    this.color,
    super.key,
  });

  final String iconId;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final token = CategoryIconCatalog.resolve(iconId);
    return SvgPicture.asset(
      token.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: token.semanticName,
    );
  }
}
