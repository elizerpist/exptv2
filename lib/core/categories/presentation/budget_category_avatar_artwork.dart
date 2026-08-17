import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../assets/prepared_vector_asset_atlas.dart';
import 'category_icon_view.dart';

/// The source-authored Budget avatar body from the local visual reference's
/// `BudgetV2FluviSvg.avatarDisc` contract.
///
/// The body, its internal highlight/depth, and the lower coloured floor
/// shadow are one SVG artwork. Only the centre selection shell is Flutter
/// chrome; it is the reference Budget V2 selection treatment, not an avatar
/// substitute. [icon] is already decoded by [PreparedVectorAssetAtlas].
final class BudgetCategoryAvatarArtwork extends StatelessWidget {
  const BudgetCategoryAvatarArtwork({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.svgSource,
    required this.selected,
    this.canvasSize = 72,
    this.iconSize = 30,
    super.key,
  });

  final Color color;
  final PreparedVectorPicture icon;
  final String semanticsLabel;

  /// Built when the category presentation collection changes, never from a
  /// carousel tick. `flutter_svg` caches the parsed source by this value.
  final String svgSource;
  final bool selected;
  final double canvasSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final artwork = _BudgetCategoryAvatarDisc(
      source: svgSource,
      icon: icon,
      semanticLabel: semanticsLabel,
      canvasSize: selected ? 40 : canvasSize,
      iconSize: selected ? 18 : iconSize,
      coreOnly: selected,
    );
    if (!selected) return artwork;
    return Transform.scale(
      key: const ValueKey('budget-category-avatar-selection-scale'),
      alignment: Alignment.center,
      scale: 1.25,
      child: BudgetCategoryAvatarSelectionChrome(
        key: const ValueKey('budget-category-avatar-selection-chrome'),
        categoryColor: color,
        child: artwork,
      ),
    );
  }
}

final class _BudgetCategoryAvatarDisc extends StatelessWidget {
  const _BudgetCategoryAvatarDisc({
    required this.source,
    required this.icon,
    required this.semanticLabel,
    required this.canvasSize,
    required this.iconSize,
    required this.coreOnly,
  });

  final String source;
  final PreparedVectorPicture icon;
  final String semanticLabel;
  final double canvasSize;
  final double iconSize;
  final bool coreOnly;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: canvasSize,
    child: Semantics(
      image: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                source,
                fit: BoxFit.contain,
                clipBehavior: Clip.hardEdge,
              ),
            ),
          ),
          CategoryIconView(picture: icon, size: iconSize, color: Colors.white),
        ],
      ),
    ),
  );
}

/// The exact reference selection chrome around the centre core. It is kept
/// separate from the SVG avatar body so no Flutter shadow/gradient can be
/// mistaken for intrinsic category artwork.
final class BudgetCategoryAvatarSelectionChrome extends StatelessWidget {
  const BudgetCategoryAvatarSelectionChrome({
    required this.categoryColor,
    required this.child,
    super.key,
  });

  final Color categoryColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gradient = _SelectionArcGradient.fromCategoryColor(categoryColor);
    return SizedBox.square(
      dimension: 72,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SelectionChromePainter(
            startColor: gradient.start,
            middleColor: gradient.middle,
            endColor: gradient.end,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

final class _SelectionArcGradient {
  const _SelectionArcGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  factory _SelectionArcGradient.fromCategoryColor(Color start) {
    final hsl = HSLColor.fromColor(start);
    final end = hsl
        .withHue((hsl.hue - 46 + 360) % 360)
        .withSaturation((hsl.saturation * .9).clamp(0, 1).toDouble())
        .withLightness((hsl.lightness * .92).clamp(0, 1).toDouble())
        .toColor();
    return _SelectionArcGradient(
      start: start,
      middle: Color.lerp(start, end, .45)!,
      end: end,
    );
  }

  final Color start;
  final Color middle;
  final Color end;
}

/// Ported exactly from the reference's `BudgetV2LimitProgressPainter` for the
/// no-data centre state. It is selection chrome only; the category body's
/// authored depth and floor blob stay inside [BudgetCategoryAvatarSvg].
final class _SelectionChromePainter extends CustomPainter {
  const _SelectionChromePainter({
    required this.startColor,
    required this.middleColor,
    required this.endColor,
  });

  static const _sourceViewport = Size(308, 308);
  static const _sourceCenter = Offset(154, 154);
  static const _sourceFaceRadius = 122.0;
  static const _sourceTrackRadius = 96.0 * 1.12;
  static const _sourceTrackWidth = 24.0;
  static const _sourceGlossFraction = .24;

  final Color startColor;
  final Color middleColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _sourceViewport.width,
      size.height / _sourceViewport.height,
    );
    final offset = Offset(
      (size.width - _sourceViewport.width * scale) / 2,
      (size.height - _sourceViewport.height * scale) / 2,
    );
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);

    final faceRect = Rect.fromCircle(
      center: _sourceCenter,
      radius: _sourceFaceRadius,
    );
    final trackRect = Rect.fromCircle(
      center: _sourceCenter,
      radius: _sourceTrackRadius,
    );
    const startAngle = -math.pi / 2;
    const sweep = math.pi * 2 * .01;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(154, 266), width: 252, height: 68),
      Paint()
        ..color = const Color(0x1ABD7CE8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      const Offset(154, 166),
      _sourceFaceRadius,
      Paint()
        ..color = const Color(0x33A763D7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      _sourceCenter,
      _sourceFaceRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.32, -.44),
          radius: .78,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFBF9FF),
            Color(0xFFEFEAF8),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      _sourceCenter,
      _sourceFaceRadius,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final shellHighlight = Path()
      ..moveTo(72, 86)
      ..cubicTo(114, 48, 189, 42, 236, 84);
    canvas.drawPath(
      shellHighlight,
      Paint()
        ..color = const Color(0x8CFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0x73CFC7DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth + 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F4FF),
            Color(0xFFECE8F8),
            Color(0xFFDCD6EC),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2 * _sourceGlossFraction,
      false,
      Paint()
        ..color = const Color(0x85FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect.shift(const Offset(0, 5)),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = endColor.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      sweep,
      false,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[startColor, middleColor, endColor],
          stops: const <double>[0, .45, 1],
        ).createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = const Color(0x3DFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SelectionChromePainter oldDelegate) =>
      oldDelegate.startColor != startColor ||
      oldDelegate.middleColor != middleColor ||
      oldDelegate.endColor != endColor;
}

/// Literal source vector contract from the local visual reference.
/// `flutter_svg` does not support SVG filters, so retain the exact reference
/// compatibility transform: filters are removed but their authored geometry,
/// gradients, highlights, and lower floor ellipse remain in the artwork.
abstract final class BudgetCategoryAvatarSvg {
  static String flutterRenderable(String source) => source
      .replaceAll(RegExp(r'<filter\b[^>]*>.*?</filter>', dotAll: true), '')
      .replaceAll(RegExp(r'\sfilter="url\(#[^)]+\)"'), '');

  static String avatarDisc(Color color, int identity, {bool coreOnly = false}) {
    final hex = _hex(color).toLowerCase();
    final id = 'budgetAvatarDisc$identity';
    final light = _mixColor(hex, '#ffffff', .78);
    final main = _mixColor(hex, '#ffffff', .18);
    final depth = _mixColor(hex, '#24113f', .32);
    final shadow = _mixColor(hex, '#24113f', .18);
    final viewport = coreOnly ? '94 78 324 324' : '94 78 324 342';
    final coreAttribute = coreOnly
        ? ' data-budget-avatar-disc-core="true"'
        : '';
    final shadowFilter = coreOnly
        ? ''
        : '<filter id="${id}Shadow" x="-70%" y="-70%" width="240%" height="240%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="18" result="b"/><feOffset in="b" dx="0" dy="22" result="o"/><feFlood flood-color="$shadow" flood-opacity=".28" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>';
    final bodyFilter = coreOnly ? '' : ' filter="url(#${id}Shadow)"';
    final floorShadow = coreOnly
        ? ''
        : '<ellipse cx="256" cy="382" rx="126" ry="34" fill="$shadow" opacity=".10" filter="url(#${id}SoftBlur)"/>';
    return '''<svg class="budget-fluvi-avatar-disc" viewBox="$viewport" preserveAspectRatio="xMidYMid meet" aria-hidden="true" focusable="false" data-fluvi-avatar-disc="true"$coreAttribute data-budget-avatar-disc-color="$hex"><defs><radialGradient id="${id}Face" cx="32%" cy="26%" r="82%"><stop offset="0" stop-color="$light"/><stop offset=".38" stop-color="$main"/><stop offset=".72" stop-color="$hex"/><stop offset="1" stop-color="$depth"/></radialGradient><linearGradient id="${id}Rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".92"/><stop offset=".42" stop-color="#ffffff" stop-opacity=".38"/><stop offset="1" stop-color="$depth" stop-opacity=".55"/></linearGradient>$shadowFilter<filter id="${id}SoftBlur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter></defs><g data-fluvi-avatar-disc-body="true"$bodyFilter>$floorShadow<circle cx="256" cy="240" r="142" fill="url(#${id}Face)" stroke="url(#${id}Rim)" stroke-width="8"/><path d="M166 190 C205 132 300 118 353 174" fill="none" stroke="#ffffff" stroke-opacity=".42" stroke-width="20" stroke-linecap="round" filter="url(#${id}SoftBlur)"/><path d="M181 315 C233 357 307 355 350 311" fill="none" stroke="$depth" stroke-opacity=".18" stroke-width="24" stroke-linecap="round" filter="url(#${id}SoftBlur)"/></g></svg>''';
  }
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

String _mixColor(String source, String target, double amount) {
  final ratio = amount.clamp(0.0, 1.0);
  final channels = List<int>.generate(3, (index) {
    final start = int.parse(
      source.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    final end = int.parse(
      target.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    return (start + (end - start) * ratio).round();
  });
  return '#${channels.map((channel) => channel.toRadixString(16).padLeft(2, '0')).join()}';
}
