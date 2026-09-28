import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Exact SUM/YEAR alternative-body allocation. Card 4 and Card 5 divide the
/// prior top-right allocation only; callers apply visible gutters afterwards.
@immutable
final class BalanceFiveSectionLayout {
  const BalanceFiveSectionLayout._({
    required this.card1,
    required this.card2,
    required this.card3,
    required this.card4,
    required this.card5,
  });

  final Rect card1;
  final Rect card2;
  final Rect card3;
  final Rect card4;
  final Rect card5;

  static BalanceFiveSectionLayout resolve(Rect bodyRect) {
    final topHeight = bodyRect.height * .60;
    final halfTopRightHeight = topHeight * .50;
    final bottomHeight = bodyRect.height - topHeight;
    final topLeftWidth = bodyRect.width * .70;
    final topRightWidth = bodyRect.width - topLeftWidth;
    final bottomLeftWidth = bodyRect.width * .50;
    final bottomRightWidth = bodyRect.width - bottomLeftWidth;
    return BalanceFiveSectionLayout._(
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
        halfTopRightHeight,
      ),
      card5: Rect.fromLTWH(
        bodyRect.left + topLeftWidth,
        bodyRect.top + halfTopRightHeight,
        topRightWidth,
        halfTopRightHeight,
      ),
    );
  }
}
