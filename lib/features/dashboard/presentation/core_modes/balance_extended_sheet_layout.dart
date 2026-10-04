import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show EdgeInsets;

import 'balance_alternative_visual_tokens.dart';

/// The exact Havi 2 / Éves child-allocation grammar from the canonical HTML
/// extended sheet. The Header is purposefully excluded: [bodyRect] starts at
/// the first content pixel below the unified Header seam.
@immutable
final class BalanceExtendedSheetLayout {
  const BalanceExtendedSheetLayout._({
    required this.bodyRect,
    required this.card3,
    required this.card4,
    required this.card5,
    required this.combined,
  });

  final Rect bodyRect;
  final Rect card3;
  final Rect card4;
  final Rect card5;
  final Rect combined;

  static BalanceExtendedSheetLayout resolve(Rect bodyRect) {
    final topHeight = bodyRect.height * .60;
    final bottomHeight = bodyRect.height - topHeight;
    final card3Width = bodyRect.width * .70;
    final rightWidth = bodyRect.width - card3Width;
    final halfRightHeight = topHeight / 2;
    return BalanceExtendedSheetLayout._(
      bodyRect: bodyRect,
      card3: Rect.fromLTWH(bodyRect.left, bodyRect.top, card3Width, topHeight),
      card4: Rect.fromLTWH(
        bodyRect.left + card3Width,
        bodyRect.top,
        rightWidth,
        halfRightHeight,
      ),
      card5: Rect.fromLTWH(
        bodyRect.left + card3Width,
        bodyRect.top + halfRightHeight,
        rightWidth,
        halfRightHeight,
      ),
      combined: Rect.fromLTWH(
        bodyRect.left,
        bodyRect.top + topHeight,
        bodyRect.width,
        bottomHeight,
      ),
    );
  }

  /// Preserves the shared 6px seams between adjacent surfaces but gives edge
  /// slots all of the Mother Card's usable left/right width. The old uniform
  /// inset incorrectly spent six pixels on each outer edge as well.
  EdgeInsets childInsetsFor(Rect slot) {
    const epsilon = .001;
    final touchesLeft = slot.left <= bodyRect.left + epsilon;
    final touchesRight = slot.right >= bodyRect.right - epsilon;
    return EdgeInsets.fromLTRB(
      touchesLeft ? 0 : BalanceAlternativeHtmlTokens.halfGutter,
      BalanceAlternativeHtmlTokens.halfGutter,
      touchesRight ? 0 : BalanceAlternativeHtmlTokens.halfGutter,
      BalanceAlternativeHtmlTokens.halfGutter,
    );
  }
}
