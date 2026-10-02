import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Pure Header-excluded allocation for Balance's temporary unified scaffold.
/// The rectangles are allocation slots; any visual gutters are insets applied
/// by the renderer and never alter the required 60/40 and 70/30/50/50 maths.
@immutable
final class BalanceFourSectionLayout {
  /// The existing authored four-card content has a meaningful compact-phone
  /// lower bound. Below it, preserving all four live cards would produce
  /// clipped text/plots; the Balance surface retains its established
  /// carousel/detail fallback for such transient geometry.
  static const minimumRenderableBodyWidth = 240.0;
  static const minimumRenderableBodyHeight = 180.0;

  const BalanceFourSectionLayout._({
    required this.card1,
    required this.card2,
    required this.card3,
    required this.card4,
  });

  final Rect card1;
  final Rect card2;
  final Rect card3;
  final Rect card4;

  static bool canRenderWithin(Rect bodyRect) =>
      bodyRect.width >= minimumRenderableBodyWidth &&
      bodyRect.height >= minimumRenderableBodyHeight;

  static BalanceFourSectionLayout resolve(Rect bodyRect) {
    final topHeight = bodyRect.height * .60;
    final bottomHeight = bodyRect.height - topHeight;
    final topLeftWidth = bodyRect.width * .70;
    final topRightWidth = bodyRect.width - topLeftWidth;
    final bottomLeftWidth = bodyRect.width * .50;
    final bottomRightWidth = bodyRect.width - bottomLeftWidth;
    return BalanceFourSectionLayout._(
      card1: Rect.fromLTWH(
        bodyRect.left,
        bodyRect.top + topHeight,
        bottomLeftWidth,
        bottomHeight,
      ),
      card2: Rect.fromLTWH(
        bodyRect.left + bottomLeftWidth,
        bodyRect.top + topHeight,
        bottomRightWidth,
        bottomHeight,
      ),
      card3: Rect.fromLTWH(
        bodyRect.left,
        bodyRect.top,
        topLeftWidth,
        topHeight,
      ),
      card4: Rect.fromLTWH(
        bodyRect.left + topLeftWidth,
        bodyRect.top,
        topRightWidth,
        topHeight,
      ),
    );
  }
}
