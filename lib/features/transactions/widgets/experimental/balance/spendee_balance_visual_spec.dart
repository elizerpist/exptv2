import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A CSS Images level-3 linear gradient.
///
/// Flutter's [LinearGradient] alignments do not preserve a CSS angle on
/// non-square bounds. CSS extends the gradient line to the box corners; this
/// implementation derives those pixel endpoints from the actual paint rect.
@immutable
class CssLinearGradient extends Gradient {
  const CssLinearGradient({
    required this.cssDegrees,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
  });

  final double cssDegrees;
  final TileMode tileMode;

  ({Offset start, Offset end}) endpointsFor(Rect rect) {
    final radians = cssDegrees * math.pi / 180;
    final direction = Offset(math.sin(radians), -math.cos(radians));
    final lineLength =
        rect.width * direction.dx.abs() + rect.height * direction.dy.abs();
    final halfVector = direction * (lineLength / 2);
    return (start: rect.center - halfVector, end: rect.center + halfVector);
  }

  @override
  ui.Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final (:start, :end) = endpointsFor(rect);
    final resolvedStops =
        stops ??
        List<double>.generate(
          colors.length,
          (index) => index / (colors.length - 1),
          growable: false,
        );
    return ui.Gradient.linear(start, end, colors, resolvedStops, tileMode);
  }

  @override
  CssLinearGradient scale(double factor) {
    return CssLinearGradient(
      cssDegrees: cssDegrees,
      colors: colors
          .map((color) => Color.lerp(null, color, factor)!)
          .toList(growable: false),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  CssLinearGradient withOpacity(double opacity) {
    return CssLinearGradient(
      cssDegrees: cssDegrees,
      colors: colors
          .map((color) => color.withValues(alpha: color.a * opacity))
          .toList(growable: false),
      stops: stops,
      tileMode: tileMode,
    );
  }
}

/// Final B3M-A3 values after the base, `time-rail-compact`, and `permanent`
/// selector cascade.
abstract final class SpendeeBalanceVisualSpec {
  static const weight750 = <ui.FontVariation>[ui.FontVariation('wght', 750)];
  static const weight850 = <ui.FontVariation>[ui.FontVariation('wght', 850)];
  static const weight950 = <ui.FontVariation>[ui.FontVariation('wght', 950)];

  static const viewport = Size(412, 892);
  static const canvas = Size(410, 890);
  static const screenBorderWidth = 1.0;
  static const screenRadius = 34.0;

  /// Approved HTML permanent-screen Grey 100 page surface.
  static const pageBackground = Color(0xFFF1F5F9);
  static const horizontalInset = 16.0;
  static const contentWidth = 378.0;
  static const stackGap = 11.0;

  static const brandTop = 48.0;
  static const brandHeight = 49.0;
  static const logoSize = 56.0;

  static const heroTop = 104.0;
  static const heroExpandedHeight = 126.0;
  static const heroCollapsedHeight = 104.0;
  static const heroRadius = 24.0;
  static const heroPadding = EdgeInsets.fromLTRB(20, 16, 20, 12);
  static const menuTop = 118.0;
  static const menuRight = 36.0;

  static const insightTop = 241.0;
  static const insightHeight = 104.0;
  static const insightGap = 9.0;

  static const detailTop = 356.0;

  /// `balance_latest_layout.html`: 208px card + 4px gap + 6px pagination.
  static const detailStageHeight = 218.0;
  static const detailCardHeight = 208.0;
  static const detailPaginationHeight = 6.0;
  static const detailPaginationGap = 4.0;
  static const detailDotInactive = 4.0;
  static const detailDotActive = 6.0;
  static const detailDotColor = Color(0xFFE1E4EC);
  static const detailDotActiveColor = Color(0xFFE84CAE);

  static const actionTop = 585.0;
  static const actionHeight = 42.0;
  static const actionSideInset = 4.0;
  static const actionGap = 10.0;
  static const actionRadius = 16.0;
  static const actionPulseDuration = Duration(milliseconds: 420);

  static const summaryTop = 638.0;
  static const summaryHeight = 59.0;
  static const summaryRadius = 20.0;
  static const summaryHorizontalPadding = 15.0;
  static const summaryColumnGap = 9.0;
  static const summarySettleDuration = Duration(milliseconds: 160);
  static const summarySurfaceColor = Color(0xF0FFFFFF);
  static const summarySurfaceBorder = Border.fromBorderSide(
    BorderSide(color: Color(0x1A666FAB)),
  );
  static const summarySurfaceShadows = <BoxShadow>[
    BoxShadow(color: Color(0x14524B93), offset: Offset(0, 8), blurRadius: 17),
    BoxShadow(
      color: Color(0xF0FFFFFF),
      offset: Offset(0, 1),
      blurRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
  ];

  static const searchTop = 708.0;
  static const searchHeight = 39.0;
  static const searchGap = 9.0;
  static const searchFieldRadius = 21.0;
  static const filterWidth = 40.0;
  static const filterRadius = 17.0;

  static const timeRailTop = 758.0;
  static const timeRailHeight = 79.0;
  static const timeRailControlHeight = 21.0;
  static const timeRailViewportHeight = 37.0;
  static const timeRailSlotDistance = 69.2;
  static const timeRailVisibleLogicalDistance = 2;
  static const handleSize = Size(92, 21);
  static const handleBarSize = Size(22, 3);
  static const yearPillSize = Size(49, 30);
  static const activeYearPillSize = Size(68, 37);
  static const railDotSize = 5.0;

  static const bottomNavHeight = 80.0;
  static const bottomNavTop = 810.0;

  static const transactionViewportHeight = 422.0;
  static const dayCardRadius = 18.0;
  static const transactionRowMinHeight = 55.0;
  static const transactionAvatarSize = 34.0;
  static const transactionEditSize = 24.0;
  static const transactionRowGap = 10.0;
  static const transactionRowPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  static const heroGradient = CssLinearGradient(
    cssDegrees: 118,
    colors: [
      Color(0xFF8079E9),
      Color(0xFFA879EE),
      Color(0xFFE985D9),
      Color(0xFFFF8CAD),
    ],
    stops: [0, .38, .69, 1],
  );

  static const fabGradient = CssLinearGradient(
    cssDegrees: 140,
    colors: [Color(0xFF6065F5), Color(0xFF8C5CEF), Color(0xFFF25CBF)],
    stops: [0, .52, 1],
  );

  static const heroBorder = Border.fromBorderSide(
    BorderSide(color: Color(0x9EFFFFFF)),
  );

  static const heroShadows = <BoxShadow>[
    BoxShadow(color: Color(0x3DC359B8), offset: Offset(0, 16), blurRadius: 34),
    BoxShadow(color: Color(0x1F50459C), offset: Offset(0, 6), blurRadius: 14),
    BoxShadow(
      color: Color(0x7AFFFFFF),
      offset: Offset(0, 1),
      blurRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
  ];

  static const cardShadow = BoxShadow(
    color: Color(0x1A524B93),
    offset: Offset(0, 12),
    blurRadius: 25,
  );

  static const dayCardShadows = <BoxShadow>[
    BoxShadow(color: Color(0x14524B93), offset: Offset(0, 9), blurRadius: 19),
  ];

  /// Converts a CSS linear-gradient angle (0° up, 90° right) to Flutter box
  /// alignment endpoints.
  static Alignment angleAlignment(double cssDegrees, {required bool start}) {
    final radians = cssDegrees * math.pi / 180;
    final dx = math.sin(radians);
    final dy = -math.cos(radians);
    return start ? Alignment(-dx, -dy) : Alignment(dx, dy);
  }
}
