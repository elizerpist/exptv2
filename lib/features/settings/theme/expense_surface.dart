import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ExpenseSurfaceInteraction {
  neutralNeutral('neutralNeutral'),
  neutralInset('neutralInset'),
  insetInset('insetInset'),
  raisedInset('raisedInset');

  const ExpenseSurfaceInteraction(this.nativeValue);

  final String nativeValue;

  static ExpenseSurfaceInteraction fromAny(Object? value) {
    final raw = value?.toString();
    return ExpenseSurfaceInteraction.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => ExpenseSurfaceInteraction.neutralNeutral,
    );
  }

  String get displayTitle => switch (this) {
    ExpenseSurfaceInteraction.neutralNeutral => 'Neutrális -> neutrális',
    ExpenseSurfaceInteraction.neutralInset => 'Neutrális -> befelé',
    ExpenseSurfaceInteraction.insetInset => 'Befelé -> befelé',
    ExpenseSurfaceInteraction.raisedInset => 'Kifelé -> befelé',
  };

  String get description => switch (this) {
    ExpenseSurfaceInteraction.neutralNeutral =>
      'Jelenlegi alapállapot, extra nyomási effekt nélkül',
    ExpenseSurfaceInteraction.neutralInset =>
      'Alapból neutrális, érintéskor benyomott hatás',
    ExpenseSurfaceInteraction.insetInset =>
      'Alapból is mélyített, érintéskor erősebb mélyítés',
    ExpenseSurfaceInteraction.raisedInset =>
      'Alapból kiemelt, érintéskor benyomott hatás',
  };

  bool get hasPressEffect => this != ExpenseSurfaceInteraction.neutralNeutral;
}

class ExpenseSurface {
  const ExpenseSurface._();

  static const Duration pressDuration = Duration(milliseconds: 110);

  static BoxDecoration decoration({
    required ExpenseSurfaceInteraction style,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    bool pressed = false,
    bool primary = false,
    Color? primaryColor,
    Border? neutralBorder,
    List<BoxShadow>? neutralShadow,
  }) {
    final depth = _depthFor(style, pressed);
    if (primary) {
      return _primaryDecoration(
        depth: depth,
        style: style,
        pressed: pressed,
        borderRadius: borderRadius,
        color: primaryColor ?? AppColors.primary,
        neutralShadow: neutralShadow,
      );
    }
    return switch (depth) {
      _SurfaceDepth.neutral => BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: neutralBorder,
        boxShadow: neutralShadow,
      ),
      _SurfaceDepth.raised => BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x5794A3B8),
            offset: Offset(7, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0xEBFFFFFF),
            offset: Offset(-7, -7),
            blurRadius: 15,
          ),
        ],
      ),
      _SurfaceDepth.inset => BoxDecoration(
        color: color,
        gradient: _insetGradient(color),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
      ),
      _SurfaceDepth.deepInset => BoxDecoration(
        color: color,
        gradient: _deepInsetGradient(color),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
      ),
    };
  }

  static Offset pressOffset({
    required ExpenseSurfaceInteraction style,
    required bool pressed,
  }) {
    if (!pressed || style == ExpenseSurfaceInteraction.neutralNeutral) {
      return Offset.zero;
    }
    return switch (style) {
      ExpenseSurfaceInteraction.neutralNeutral => Offset.zero,
      ExpenseSurfaceInteraction.neutralInset => const Offset(0, 2),
      ExpenseSurfaceInteraction.insetInset => const Offset(0, 1),
      ExpenseSurfaceInteraction.raisedInset => const Offset(0, 2),
    };
  }

  static BoxDecoration _primaryDecoration({
    required _SurfaceDepth depth,
    required ExpenseSurfaceInteraction style,
    required bool pressed,
    required BorderRadiusGeometry borderRadius,
    required Color color,
    required List<BoxShadow>? neutralShadow,
  }) {
    if (depth == _SurfaceDepth.neutral) {
      return BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: neutralShadow,
      );
    }
    final raised = depth == _SurfaceDepth.raised;
    final light = _accentLight(color);
    final dark = _accentDark(color);
    return BoxDecoration(
      color: color,
      gradient: raised
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                light,
                color,
                dark,
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                dark,
                color,
                light,
              ],
            ),
      borderRadius: borderRadius,
      border: null,
      boxShadow: raised
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x570891B2),
                offset: Offset(8, 8),
                blurRadius: 17,
              ),
              BoxShadow(
                color: Color(0xD9FFFFFF),
                offset: Offset(-7, -7),
                blurRadius: 16,
              ),
            ]
          : style == ExpenseSurfaceInteraction.neutralInset && pressed
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x2406B6D4),
                offset: Offset(0, 2),
                blurRadius: 7,
              ),
            ]
          : null,
    );
  }

  static _SurfaceDepth _depthFor(
    ExpenseSurfaceInteraction style,
    bool pressed,
  ) {
    return switch (style) {
      ExpenseSurfaceInteraction.neutralNeutral => _SurfaceDepth.neutral,
      ExpenseSurfaceInteraction.neutralInset => pressed
          ? _SurfaceDepth.inset
          : _SurfaceDepth.neutral,
      ExpenseSurfaceInteraction.insetInset => pressed
          ? _SurfaceDepth.deepInset
          : _SurfaceDepth.inset,
      ExpenseSurfaceInteraction.raisedInset => pressed
          ? _SurfaceDepth.inset
          : _SurfaceDepth.raised,
    };
  }

  static LinearGradient _insetGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(color, AppColors.gray400, 0.16)!,
        color,
        Color.lerp(color, Colors.white, 0.34)!,
      ],
    );
  }

  static LinearGradient _deepInsetGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(color, AppColors.gray500, 0.22)!,
        Color.lerp(color, AppColors.gray400, 0.08)!,
        Color.lerp(color, Colors.white, 0.28)!,
      ],
    );
  }

  static bool needsInnerOverlay({
    required ExpenseSurfaceInteraction style,
    required bool pressed,
    required bool primary,
  }) {
    final depth = _depthFor(style, pressed);
    return primary
        ? depth != _SurfaceDepth.neutral
        : depth == _SurfaceDepth.inset || depth == _SurfaceDepth.deepInset;
  }

  static Color _accentLight(Color color) {
    if (color == AppColors.primary) return AppColors.primaryLight;
    return Color.lerp(color, Colors.white, 0.42)!;
  }

  static Color _accentDark(Color color) {
    if (color == AppColors.primary) return AppColors.primaryDark;
    return Color.lerp(color, Colors.black, 0.22)!;
  }
}

class ExpenseSurfaceContainer extends StatelessWidget {
  const ExpenseSurfaceContainer({
    super.key,
    this.surfaceKey,
    required this.style,
    required this.color,
    required this.borderRadius,
    required this.child,
    this.pressed = false,
    this.primary = false,
    this.primaryColor,
    this.neutralBorder,
    this.neutralShadow,
    this.margin,
    this.padding,
    this.constraints,
    this.width,
    this.height,
    this.animatePress = true,
  });

  final Key? surfaceKey;
  final ExpenseSurfaceInteraction style;
  final Color color;
  final BorderRadius borderRadius;
  final Widget child;
  final bool pressed;
  final bool primary;
  final Color? primaryColor;
  final Border? neutralBorder;
  final List<BoxShadow>? neutralShadow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final bool animatePress;

  @override
  Widget build(BuildContext context) {
    final offset = ExpenseSurface.pressOffset(style: style, pressed: pressed);
    final surface = Container(
      key: surfaceKey,
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      decoration: ExpenseSurface.decoration(
        style: style,
        color: color,
        borderRadius: borderRadius,
        pressed: pressed,
        primary: primary,
        primaryColor: primaryColor,
        neutralBorder: neutralBorder,
        neutralShadow: neutralShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
            if (ExpenseSurface.needsInnerOverlay(
              style: style,
              pressed: pressed,
              primary: primary,
            ))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ExpenseSurfaceInnerPainter(
                      style: style,
                      pressed: pressed,
                      primary: primary,
                      primaryColor: primaryColor ?? color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!animatePress) return Transform.translate(offset: offset, child: surface);
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: Offset.zero, end: offset),
      duration: ExpenseSurface.pressDuration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: surface,
    );
  }
}

class _ExpenseSurfaceInnerPainter extends CustomPainter {
  const _ExpenseSurfaceInnerPainter({
    required this.style,
    required this.pressed,
    required this.primary,
    required this.primaryColor,
  });

  final ExpenseSurfaceInteraction style;
  final bool pressed;
  final bool primary;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final primaryDark = ExpenseSurface._accentDark(primaryColor);
    final primaryLight = ExpenseSurface._accentLight(primaryColor);
    final darkAlpha = primary
        ? (pressed ? 0.64 : 0.45)
        : style == ExpenseSurfaceInteraction.insetInset && pressed
        ? 0.42
        : 0.35;
    final lightAlpha = primary ? 0.38 : 0.92;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.center,
          colors: [
            (primary ? primaryDark : AppColors.gray400).withValues(
              alpha: darkAlpha,
            ),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.center,
          colors: [
            (primary ? primaryLight : Colors.white).withValues(
              alpha: lightAlpha,
            ),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    if (primary && !pressed) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.white.withValues(alpha: 0.42),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpenseSurfaceInnerPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.pressed != pressed ||
        oldDelegate.primary != primary ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class ExpensePressable extends StatefulWidget {
  const ExpensePressable({
    super.key,
    required this.builder,
    this.enabled = true,
    this.forcePressed = false,
  });

  final Widget Function(BuildContext context, bool pressed) builder;
  final bool enabled;
  final bool forcePressed;

  @override
  State<ExpensePressable> createState() => _ExpensePressableState();
}

class _ExpensePressableState extends State<ExpensePressable> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectivePressed = widget.forcePressed || _pressed;
    if (!widget.enabled) return widget.builder(context, effectivePressed);
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: widget.builder(context, effectivePressed),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }
}

enum _SurfaceDepth { neutral, raised, inset, deepInset }
