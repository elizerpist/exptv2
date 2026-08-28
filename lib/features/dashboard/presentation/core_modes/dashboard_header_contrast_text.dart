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
  }) : _textKey = key,
       super(key: null);

  final String data;
  final TextStyle style;
  final Color foreground;
  final DashboardHeaderTextContrastStyle contrastStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
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
    if (contrastStyle != DashboardHeaderTextContrastStyle.oppositeOutline) {
      return _text(fill);
    }
    return Stack(
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
  }
}
