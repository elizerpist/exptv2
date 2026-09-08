import 'package:flutter/material.dart';

import '../dashboard_budget_header_presentation.dart';

/// One Header foreground-family text primitive. Decoration is paint-only: its
/// fill Text keeps the authored metrics, baseline, alignment and sole semantic
/// announcement across every contrast variant.
final class DashboardHeaderContrastText extends StatelessWidget {
  const DashboardHeaderContrastText({
    Key? key,
    required this.data,
    required this.style,
    required this.foreground,
    required this.contrastStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.paintIdentity,
    this.onPainted,
  }) : _textKey = key,
       super(key: null);

  final String data;
  final TextStyle style;
  final Color foreground;
  final DashboardHeaderTextContrastStyle contrastStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Immutable identity that the owning presentation controller correlates
  /// with its exact Header model. It is observation-only and has no visual,
  /// semantic, layout or state authority.
  final Object? paintIdentity;

  /// Invoked by a no-op foreground painter after this text subtree's paint
  /// pass. Callers must keep it bounded and free of widget state mutation.
  final VoidCallback? onPainted;
  final Key? _textKey;

  Color get _opposite =>
      foreground.computeLuminance() > .5 ? Colors.black : Colors.white;

  Text _text(TextStyle textStyle, {bool semanticFill = true}) => Text(
    data,
    key: semanticFill ? _textKey : null,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
    style: textStyle,
  );

  @override
  Widget build(BuildContext context) {
    final fill = style.copyWith(
      color: foreground,
      shadows:
          contrastStyle == DashboardHeaderTextContrastStyle.hardOppositeShadow
          ? <Shadow>[
              Shadow(
                color: _opposite.withValues(alpha: .88),
                offset: const Offset(1, 1),
                blurRadius: 0,
              ),
            ]
          : null,
    );
    final Widget text =
        contrastStyle != DashboardHeaderTextContrastStyle.oppositeOutline
        ? _text(fill)
        : Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              ExcludeSemantics(
                child: _text(
                  style.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = .75
                      ..color = _opposite,
                  ),
                  semanticFill: false,
                ),
              ),
              _text(fill),
            ],
          );
    final callback = onPainted;
    if (callback == null) return text;
    return CustomPaint(
      foregroundPainter: _DashboardHeaderPaintAcknowledgementPainter(
        identity: paintIdentity,
        onPainted: callback,
      ),
      child: text,
    );
  }
}

/// Paint-only acknowledgement wrapper. It deliberately draws no pixels and
/// lives after the child in [CustomPaint]'s foreground phase, so a callback is
/// evidence that the matching Header text subtree reached the paint pipeline.
final class _DashboardHeaderPaintAcknowledgementPainter extends CustomPainter {
  const _DashboardHeaderPaintAcknowledgementPainter({
    required this.identity,
    required this.onPainted,
  });

  final Object? identity;
  final VoidCallback onPainted;

  @override
  void paint(Canvas canvas, Size size) => onPainted();

  @override
  bool shouldRepaint(
    covariant _DashboardHeaderPaintAcknowledgementPainter oldDelegate,
  ) => !identical(oldDelegate.identity, identity);
}
