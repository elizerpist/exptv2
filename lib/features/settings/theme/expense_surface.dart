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

  static BoxDecoration decoration({
    required ExpenseSurfaceInteraction style,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    bool pressed = false,
    bool primary = false,
    Border? neutralBorder,
    List<BoxShadow>? neutralShadow,
  }) {
    final depth = _depthFor(style, pressed);
    if (primary) {
      return _primaryDecoration(
        depth: depth,
        borderRadius: borderRadius,
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
        boxShadow: _raisedShadow(color),
      ),
      _SurfaceDepth.inset => BoxDecoration(
        color: color,
        gradient: _insetGradient(color),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        boxShadow: _insetShadow(color),
      ),
      _SurfaceDepth.deepInset => BoxDecoration(
        color: color,
        gradient: _deepInsetGradient(color),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
        boxShadow: _deepInsetShadow(color),
      ),
    };
  }

  static BoxDecoration _primaryDecoration({
    required _SurfaceDepth depth,
    required BorderRadiusGeometry borderRadius,
    required List<BoxShadow>? neutralShadow,
  }) {
    if (depth == _SurfaceDepth.neutral) {
      return BoxDecoration(
        color: AppColors.primary,
        borderRadius: borderRadius,
        boxShadow: neutralShadow,
      );
    }
    final raised = depth == _SurfaceDepth.raised;
    return BoxDecoration(
      color: AppColors.primary,
      gradient: raised
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.primaryLight,
                AppColors.primary,
                AppColors.primaryDark,
              ],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
      borderRadius: borderRadius,
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
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x780E7490),
                offset: Offset(4, 4),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Color(0x5C67E8F9),
                offset: Offset(-4, -4),
                blurRadius: 9,
              ),
            ],
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

  static List<BoxShadow> _raisedShadow(Color color) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.lerp(color, AppColors.gray400, 0.64)!.withValues(
          alpha: 0.38,
        ),
        offset: const Offset(7, 7),
        blurRadius: 15,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.92),
        offset: const Offset(-7, -7),
        blurRadius: 15,
      ),
    ];
  }

  static List<BoxShadow> _insetShadow(Color color) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.lerp(color, AppColors.gray500, 0.72)!.withValues(
          alpha: 0.30,
        ),
        offset: const Offset(3, 3),
        blurRadius: 7,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.74),
        offset: const Offset(-3, -3),
        blurRadius: 7,
      ),
    ];
  }

  static List<BoxShadow> _deepInsetShadow(Color color) {
    return <BoxShadow>[
      BoxShadow(
        color: Color.lerp(color, AppColors.gray600, 0.72)!.withValues(
          alpha: 0.36,
        ),
        offset: const Offset(4, 4),
        blurRadius: 9,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.72),
        offset: const Offset(-4, -4),
        blurRadius: 9,
      ),
    ];
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
