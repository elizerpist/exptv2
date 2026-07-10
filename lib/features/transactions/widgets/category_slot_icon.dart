import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/debug/debug_console.dart';
import '../slots/category_icon_manager.dart';

final Map<String, Future<String>> _strokeAdjustedSvgCache =
    <String, Future<String>>{};
final Map<String, String> _strokeAdjustedSvgDataCache = <String, String>{};
final Set<String> _loggedFirstIconRenderSources = <String>{};
final Set<String> _loggedFirstIconPlaceholderSources = <String>{};

class CategorySlotIcon extends StatelessWidget {
  const CategorySlotIcon({
    super.key,
    this.slot,
    this.iconName,
    required this.color,
    required this.size,
    this.listenForSlotChanges = true,
    this.strokeWidth,
    this.debugSource,
  }) : assert(slot != null || iconName != null);

  final int? slot;
  final String? iconName;
  final Color color;
  final double size;
  final bool listenForSlotChanges;
  final double? strokeWidth;
  final String? debugSource;

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
        _logIconRender(
          source: debugSource,
          assetPath: assetPath,
          cacheHit: true,
          strokeWidth: requestedStrokeWidth,
        );
        return _svgPicture(cachedSvg);
      }
      final requestedAt = DateTime.now();
      final future = _strokeAdjustedSvgFuture(assetPath, requestedStrokeWidth);
      return FutureBuilder<String>(
        future: future,
        builder: (context, snapshot) {
          final svg = snapshot.data ?? _strokeAdjustedSvgDataCache[cacheKey];
          if (svg == null) {
            _logIconPlaceholder(
              source: debugSource,
              assetPath: assetPath,
              strokeWidth: requestedStrokeWidth,
            );
            return _iconPlaceholder();
          }
          _logIconRender(
            source: debugSource,
            assetPath: assetPath,
            cacheHit: false,
            strokeWidth: requestedStrokeWidth,
            elapsed: DateTime.now().difference(requestedAt),
          );
          return _svgPicture(svg);
        },
      );
    }
    _logIconRender(
      source: debugSource,
      assetPath: assetPath,
      cacheHit: false,
      strokeWidth: null,
    );
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

Future<void> warmUpCategorySlotIconCache({
  Iterable<int>? slots,
  required double strokeWidth,
}) async {
  final stopwatch = Stopwatch()..start();
  final selectedSlots = (slots ?? CategoryIconManager.slots).toSet();
  final assetPaths = <String>{
    for (final slot in selectedSlots) CategoryIconManager.assetPath(slot),
  };
  DebugConsole.log(
    '[IconLoad] asset warmup start slots=${selectedSlots.length} '
    'assets=${assetPaths.length} stroke=${_strokeText(strokeWidth)}',
  );
  await Future.wait([
    for (final assetPath in assetPaths)
      _strokeAdjustedSvgFuture(assetPath, strokeWidth),
  ]);
  DebugConsole.log(
    '[IconLoad] asset warmup end assets=${assetPaths.length} '
    'elapsed=${stopwatch.elapsedMilliseconds}ms',
  );
}

@visibleForTesting
void resetCategorySlotIconCacheForTests() {
  _strokeAdjustedSvgCache.clear();
  _strokeAdjustedSvgDataCache.clear();
  resetCategorySlotIconDiagnosticsForTests();
}

@visibleForTesting
void resetCategorySlotIconDiagnosticsForTests() {
  _loggedFirstIconRenderSources.clear();
  _loggedFirstIconPlaceholderSources.clear();
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

void _logIconPlaceholder({
  required String? source,
  required String assetPath,
  required double strokeWidth,
}) {
  if (source == null) return;
  if (!_loggedFirstIconPlaceholderSources.add(source)) return;
  DebugConsole.log(
    '[LogBoxIcon] first placeholder source=$source asset=$assetPath '
    'stroke=${_strokeText(strokeWidth)} cacheHit=false',
  );
}

void _logIconRender({
  required String? source,
  required String assetPath,
  required bool cacheHit,
  required double? strokeWidth,
  Duration? elapsed,
}) {
  if (source == null) return;
  if (!_loggedFirstIconRenderSources.add(source)) return;
  final stroke = strokeWidth == null
      ? 'asset-default'
      : _strokeText(strokeWidth);
  final elapsedText = elapsed == null
      ? ''
      : ' elapsed=${elapsed.inMilliseconds}ms';
  DebugConsole.log(
    '[LogBoxIcon] first render source=$source asset=$assetPath '
    'stroke=$stroke cacheHit=$cacheHit$elapsedText',
  );
}

String _strokeText(double value) {
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
