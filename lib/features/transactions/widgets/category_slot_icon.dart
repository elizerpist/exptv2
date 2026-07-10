import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../slots/category_icon_manager.dart';

final Map<String, Future<String>> _strokeAdjustedSvgCache =
    <String, Future<String>>{};
final Map<String, String> _strokeAdjustedSvgDataCache = <String, String>{};

class CategorySlotIcon extends StatelessWidget {
  const CategorySlotIcon({
    super.key,
    this.slot,
    this.iconName,
    required this.color,
    required this.size,
    this.listenForSlotChanges = true,
    this.strokeWidth,
  }) : assert(slot != null || iconName != null);

  final int? slot;
  final String? iconName;
  final Color color;
  final double size;
  final bool listenForSlotChanges;
  final double? strokeWidth;

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
    final assetPath = iconName == null
        ? CategoryIconManager.assetPath(slot)
        : CategoryIconManager.assetPathForIconName(iconName!);
    final requestedStrokeWidth = strokeWidth;
    if (requestedStrokeWidth != null) {
      final cacheKey = '$assetPath:${_strokeText(requestedStrokeWidth)}';
      final cachedSvg = _strokeAdjustedSvgDataCache[cacheKey];
      if (cachedSvg != null) {
        return _svgPicture(cachedSvg);
      }
      final future = _strokeAdjustedSvgFuture(assetPath, requestedStrokeWidth);
      return FutureBuilder<String>(
        future: future,
        builder: (context, snapshot) {
          final svg = snapshot.data ?? _strokeAdjustedSvgDataCache[cacheKey];
          if (svg == null) {
            return _iconPlaceholder();
          }
          return _svgPicture(svg);
        },
      );
    }
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => _iconPlaceholder(),
    );
  }

  Widget _iconPlaceholder() {
    return SizedBox.square(dimension: size);
  }

  Widget _svgPicture(String svg) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => _iconPlaceholder(),
    );
  }
}

Future<String> _strokeAdjustedSvgFuture(String assetPath, double strokeWidth) {
  final cacheKey = '$assetPath:${_strokeText(strokeWidth)}';
  return _strokeAdjustedSvgCache.putIfAbsent(cacheKey, () async {
    final svg = await rootBundle.loadString(assetPath);
    final rewritten = rewriteCategoryIconStrokeWidth(svg, strokeWidth);
    _strokeAdjustedSvgDataCache[cacheKey] = rewritten;
    return rewritten;
  });
}

String rewriteCategoryIconStrokeWidth(String svg, double strokeWidth) {
  return svg.replaceAll(
    RegExp('stroke-width="[^"]+"'),
    'stroke-width="${_strokeText(strokeWidth)}"',
  );
}

String _strokeText(double value) {
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
