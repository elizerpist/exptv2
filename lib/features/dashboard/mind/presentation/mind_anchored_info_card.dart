import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Places a presentation-local infocard beside an actual global tap anchor.
/// It is intentionally data-free: selection remains owned by its feature page,
/// while this primitive supplies the one shared safe-bounds placement policy.
final class MindAnchoredInfoCard extends StatelessWidget {
  const MindAnchoredInfoCard({
    super.key,
    required this.globalAnchor,
    required this.cardKey,
    required this.child,
    this.estimatedWidth = 126,
    this.estimatedHeight = 48,
    this.edgeInset = 2,
    this.ignorePointer = false,
  });

  final Offset globalAnchor;
  final GlobalKey cardKey;
  final Widget child;
  final double estimatedWidth;
  final double estimatedHeight;
  final double edgeInset;
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) {
      final box = cardKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
      final anchor = globalAnchor - origin;
      final width = box?.size.width ?? estimatedWidth + edgeInset * 2;
      final height = box?.size.height ?? estimatedHeight + edgeInset * 2;
      final left = (anchor.dx - estimatedWidth / 2)
          .clamp(
            edgeInset,
            math.max(edgeInset, width - estimatedWidth - edgeInset),
          )
          .toDouble();
      final above = anchor.dy - estimatedHeight - 4;
      final top = (above >= edgeInset ? above : anchor.dy + 10)
          .clamp(
            edgeInset,
            math.max(edgeInset, height - estimatedHeight - edgeInset),
          )
          .toDouble();
      return Positioned(
        top: top,
        left: left,
        child: ignorePointer ? IgnorePointer(child: child) : child,
      );
    },
  );
}
