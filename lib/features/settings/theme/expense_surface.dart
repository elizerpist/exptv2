import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
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

enum ExpenseSurfaceProfile { standard, headerCard, activeNavItem }

final Map<String, String> _expenseSurfaceDebugLogSignatures =
    <String, String>{};

class ExpenseSurface {
  const ExpenseSurface._();

  static const Duration pressDuration = Duration(milliseconds: 110);
  static const WidgetStateProperty<Color?> transparentMaterialOverlayColor =
      WidgetStatePropertyAll<Color?>(Colors.transparent);
  static const WidgetStateProperty<Color?> transparentOverlayColor =
      WidgetStatePropertyAll<Color?>(Colors.transparent);

  static bool materialFeedbackEnabled(ExpenseSurfaceInteraction style) {
    return !style.hasPressEffect;
  }

  static BoxDecoration decoration({
    required ExpenseSurfaceInteraction style,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    bool pressed = false,
    bool primary = false,
    Color? primaryColor,
    Border? neutralBorder,
    List<BoxShadow>? neutralShadow,
    ExpenseSurfaceProfile profile = ExpenseSurfaceProfile.standard,
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
    final activeNavGradient = _activeNavGradient(
      profile,
      depth,
      primaryColor ?? AppColors.primary,
    );
    return switch (depth) {
      _SurfaceDepth.neutral => BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: neutralBorder,
        boxShadow: neutralShadow,
      ),
      _SurfaceDepth.raised => BoxDecoration(
        color: color,
        gradient: activeNavGradient,
        borderRadius: borderRadius,
        border: neutralShadow == null
            ? Border.all(color: Colors.white.withValues(alpha: 0.72))
            : null,
        boxShadow: neutralShadow ??
            const <BoxShadow>[
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
        gradient: activeNavGradient,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
      ),
      _SurfaceDepth.deepInset => BoxDecoration(
        color: color,
        gradient: activeNavGradient,
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

  static List<BoxShadow> insetShadowTokens({
    required ExpenseSurfaceInteraction style,
    required bool pressed,
    required bool primary,
    Color? primaryColor,
    ExpenseSurfaceProfile profile = ExpenseSurfaceProfile.standard,
  }) {
    final depth = _depthFor(style, pressed);
    if (depth == _SurfaceDepth.neutral) return const <BoxShadow>[];
    if (profile == ExpenseSurfaceProfile.activeNavItem && !primary) {
      final navPrimaryColor = primaryColor ?? AppColors.primary;
      return switch (depth) {
        _SurfaceDepth.inset => <BoxShadow>[
          BoxShadow(
            color: navPrimaryColor.withValues(alpha: 0.20),
            offset: const Offset(4, 4),
            blurRadius: 9,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.88),
            offset: const Offset(-4, -4),
            blurRadius: 9,
          ),
        ],
        _SurfaceDepth.deepInset => <BoxShadow>[
          BoxShadow(
            color: navPrimaryColor.withValues(alpha: 0.24),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.88),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
        _ => const <BoxShadow>[],
      };
    }
    if (primary) {
      return _primaryInsetShadowTokens(
        style: style,
        pressed: pressed,
        depth: depth,
        primaryColor: primaryColor ?? AppColors.primary,
      );
    }
    if (depth == _SurfaceDepth.raised) return const <BoxShadow>[];
    if (style == ExpenseSurfaceInteraction.neutralInset && pressed) {
      return <BoxShadow>[
        BoxShadow(
          color: AppColors.gray400.withValues(alpha: 0.34),
          offset: const Offset(4, 4),
          blurRadius: 9,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.88),
          offset: const Offset(-4, -4),
          blurRadius: 9,
        ),
      ];
    }
    if (style == ExpenseSurfaceInteraction.raisedInset && pressed) {
      return <BoxShadow>[
        BoxShadow(
          color: AppColors.gray400.withValues(alpha: 0.30),
          offset: const Offset(4, 4),
          blurRadius: 9,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.88),
          offset: const Offset(-4, -4),
          blurRadius: 9,
        ),
      ];
    }
    if (depth == _SurfaceDepth.deepInset) {
      return <BoxShadow>[
        BoxShadow(
          color: AppColors.gray400.withValues(alpha: 0.42),
          offset: const Offset(8, 8),
          blurRadius: 15,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.92),
          offset: const Offset(-7, -7),
          blurRadius: 14,
        ),
      ];
    }
    if (profile == ExpenseSurfaceProfile.headerCard) {
      return <BoxShadow>[
        BoxShadow(
          color: AppColors.gray400.withValues(alpha: 0.36),
          offset: const Offset(9, 9),
          blurRadius: 19,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.92),
          offset: const Offset(-9, -9),
          blurRadius: 19,
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.gray400.withValues(alpha: 0.35),
        offset: const Offset(6, 6),
        blurRadius: 13,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.92),
        offset: const Offset(-6, -6),
        blurRadius: 13,
      ),
    ];
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
    final inset = depth == _SurfaceDepth.inset;
    final solidNeutralPress =
        style == ExpenseSurfaceInteraction.neutralInset && pressed;
    final light = _accentLight(color);
    final dark = _accentDark(color);
    return BoxDecoration(
      color: color,
      gradient: solidNeutralPress
          ? null
          : raised
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[light, color, dark],
              stops: const [0, 0.46, 1],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[dark, color, light],
              stops: inset ? const [0, 0.52, 1] : const [0, 0.5, 1],
            ),
      borderRadius: borderRadius,
      border: null,
      boxShadow: raised
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(8, 8),
                blurRadius: 17,
              ),
              BoxShadow(
                color: Color(0xD9FFFFFF),
                offset: Offset(-7, -7),
                blurRadius: 16,
              ),
            ]
          : pressed && style != ExpenseSurfaceInteraction.insetInset
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x22000000),
                offset: Offset(0, 2),
                blurRadius: 7,
              ),
            ]
          : null,
    );
  }

  static List<BoxShadow> _primaryInsetShadowTokens({
    required ExpenseSurfaceInteraction style,
    required bool pressed,
    required _SurfaceDepth depth,
    required Color primaryColor,
  }) {
    if (depth == _SurfaceDepth.raised) {
      return <BoxShadow>[
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.42),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
        BoxShadow(
          color: _primaryShadowDark(primaryColor).withValues(alpha: 0.45),
          offset: const Offset(0, -4),
          blurRadius: 8,
        ),
      ];
    }
    if (style == ExpenseSurfaceInteraction.neutralInset && pressed) {
      return <BoxShadow>[
        BoxShadow(
          color: _primaryShadowDark(primaryColor).withValues(alpha: 0.48),
          offset: const Offset(5, 5),
          blurRadius: 10,
        ),
        BoxShadow(
          color: ExpenseSurface._accentLight(
            primaryColor,
          ).withValues(alpha: 0.34),
          offset: const Offset(-4, -4),
          blurRadius: 9,
        ),
      ];
    }
    if (style == ExpenseSurfaceInteraction.insetInset && pressed) {
      return <BoxShadow>[
        BoxShadow(
          color: _primaryShadowDark(primaryColor).withValues(alpha: 0.64),
          offset: const Offset(7, 7),
          blurRadius: 13,
        ),
        BoxShadow(
          color: ExpenseSurface._accentLight(
            primaryColor,
          ).withValues(alpha: 0.38),
          offset: const Offset(-5, -5),
          blurRadius: 11,
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: _primaryShadowDark(primaryColor).withValues(alpha: 0.56),
        offset: const Offset(5, 5),
        blurRadius: 10,
      ),
      BoxShadow(
        color: ExpenseSurface._accentLight(
          primaryColor,
        ).withValues(alpha: 0.36),
        offset: const Offset(-4, -4),
        blurRadius: 9,
      ),
    ];
  }

  static LinearGradient? _activeNavGradient(
    ExpenseSurfaceProfile profile,
    _SurfaceDepth depth,
    Color primaryColor,
  ) {
    if (profile != ExpenseSurfaceProfile.activeNavItem) return null;
    if (depth != _SurfaceDepth.inset && depth != _SurfaceDepth.deepInset) {
      return null;
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        _accentDark(primaryColor).withValues(alpha: 0.16),
        _accentLight(primaryColor).withValues(alpha: 0.10),
      ],
    );
  }

  static Color _primaryShadowDark(Color color) {
    return Color.lerp(color, Colors.black, 0.55)!;
  }

  static _SurfaceDepth _depthFor(
    ExpenseSurfaceInteraction style,
    bool pressed,
  ) {
    return switch (style) {
      ExpenseSurfaceInteraction.neutralNeutral => _SurfaceDepth.neutral,
      ExpenseSurfaceInteraction.neutralInset =>
        pressed ? _SurfaceDepth.inset : _SurfaceDepth.neutral,
      ExpenseSurfaceInteraction.insetInset =>
        pressed ? _SurfaceDepth.deepInset : _SurfaceDepth.inset,
      ExpenseSurfaceInteraction.raisedInset =>
        pressed ? _SurfaceDepth.inset : _SurfaceDepth.raised,
    };
  }

  static bool needsInnerOverlay({
    required ExpenseSurfaceInteraction style,
    required bool pressed,
    required bool primary,
    Color? primaryColor,
    ExpenseSurfaceProfile profile = ExpenseSurfaceProfile.standard,
  }) {
    return insetShadowTokens(
      style: style,
      pressed: pressed,
      primary: primary,
      primaryColor: primaryColor,
      profile: profile,
    ).isNotEmpty;
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
    this.clipContent = true,
    this.profile = ExpenseSurfaceProfile.standard,
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
  final bool clipContent;
  final ExpenseSurfaceProfile profile;

  @override
  Widget build(BuildContext context) {
    final offset = ExpenseSurface.pressOffset(style: style, pressed: pressed);
    final innerShadows = ExpenseSurface.insetShadowTokens(
      style: style,
      pressed: pressed,
      primary: primary,
      primaryColor: primaryColor ?? (primary ? AppColors.primary : color),
      profile: profile,
    );
    final decoration = ExpenseSurface.decoration(
      style: style,
      color: color,
      borderRadius: borderRadius,
      pressed: pressed,
      primary: primary,
      primaryColor: primaryColor,
      neutralBorder: neutralBorder,
      neutralShadow: neutralShadow,
      profile: profile,
    );
    _logExpenseSurfaceDebug(
      key: surfaceKey,
      style: style,
      color: color,
      primary: primary,
      pressed: pressed,
      offset: offset,
      profile: profile,
      decoration: decoration,
      innerShadowCount: innerShadows.length,
    );
    final innerShadowLayer = innerShadows.isNotEmpty
        ? Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ExpenseSurfaceInnerPainter(
                  borderRadius: borderRadius,
                  shadows: innerShadows,
                ),
              ),
            ),
          )
        : null;
    final content = Stack(
      fit: StackFit.passthrough,
      children: [
        ?innerShadowLayer,
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ],
    );
    final surface = Container(
      key: surfaceKey,
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      decoration: decoration,
      child: clipContent
          ? ClipRRect(borderRadius: borderRadius, child: content)
          : content,
    );
    if (!animatePress) {
      return Transform.translate(offset: offset, child: surface);
    }
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

class ExpenseSurfaceButton extends StatelessWidget {
  const ExpenseSurfaceButton({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    this.icon,
    this.saving = false,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.color = AppColors.primary,
    this.foregroundColor = AppColors.white,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool saving;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final text = saving ? 'Mentés...' : label;
    if (!surfaceStyle.hasPressEffect) {
      final style = FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      );
      return icon == null
          ? FilledButton(
              key: buttonKey,
              onPressed: saving ? null : onPressed,
              style: style,
              child: Text(text),
            )
          : FilledButton.icon(
              key: buttonKey,
              onPressed: saving ? null : onPressed,
              icon: Icon(icon, size: 19),
              label: Text(text),
              style: style,
            );
    }
    return ExpensePressable(
      enabled: onPressed != null && !saving,
      builder: (context, pressed) {
        return GestureDetector(
          key: buttonKey,
          behavior: HitTestBehavior.opaque,
          onTap: saving ? null : onPressed,
          child: ExpenseSurfaceContainer(
            style: surfaceStyle,
            color: color,
            primary: true,
            primaryColor: color,
            borderRadius: BorderRadius.circular(25),
            pressed: pressed,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: foregroundColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseSurfaceInnerPainter extends CustomPainter {
  const _ExpenseSurfaceInnerPainter({
    required this.borderRadius,
    required this.shadows,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    for (final shadow in shadows) {
      _drawInnerShadow(canvas, rect, rrect, shadow);
    }
  }

  void _drawInnerShadow(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    BoxShadow shadow,
  ) {
    canvas.saveLayer(rect, Paint());
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, Paint()..color = shadow.color);
    canvas.drawRRect(
      rrect.shift(shadow.offset),
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          _blurSigma(shadow.blurRadius),
        ),
    );
    canvas.restore();
  }

  double _blurSigma(double radius) {
    if (radius <= 0) return 0;
    return radius * 0.57735 + 0.5;
  }

  @override
  bool shouldRepaint(covariant _ExpenseSurfaceInnerPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shadows.length != shadows.length ||
        !_sameShadows(oldDelegate.shadows, shadows);
  }

  bool _sameShadows(List<BoxShadow> previous, List<BoxShadow> next) {
    if (previous.length != next.length) return false;
    for (var index = 0; index < previous.length; index++) {
      final left = previous[index];
      final right = next[index];
      if (left.color != right.color ||
          left.offset != right.offset ||
          left.blurRadius != right.blurRadius) {
        return false;
      }
    }
    return true;
  }
}

void _logExpenseSurfaceDebug({
  required Key? key,
  required ExpenseSurfaceInteraction style,
  required Color color,
  required bool primary,
  required bool pressed,
  required Offset offset,
  required ExpenseSurfaceProfile profile,
  required BoxDecoration decoration,
  required int innerShadowCount,
}) {
  final label = _surfaceDebugLabel(key);
  if (label == null || !_shouldLogSurface(label)) return;
  final message =
      '[ThemeSurface] surface key=$label '
      'style=${style.nativeValue} profile=${profile.name} '
      'color=${_hex(color)} primary=$primary pressed=$pressed '
      'offset=${offset.dx.toStringAsFixed(0)},${offset.dy.toStringAsFixed(0)} '
      'gradient=${decoration.gradient != null} '
      'border=${decoration.border != null} '
      'outerShadows=${decoration.boxShadow?.length ?? 0} '
      'innerShadows=$innerShadowCount';
  final alreadyVisible = DebugConsole.entries.any(
    (entry) => entry.contains(message),
  );
  if (_expenseSurfaceDebugLogSignatures[label] == message && alreadyVisible) {
    return;
  }
  _expenseSurfaceDebugLogSignatures[label] = message;
  DebugConsole.log(message);
}

String? _surfaceDebugLabel(Key? key) {
  if (key is ValueKey<Object?>) return key.value?.toString();
  return null;
}

bool _shouldLogSurface(String label) {
  return label == 'expt-bottom-nav' ||
      label == 'expt-fab' ||
      label == 'summary-pill-container' ||
      label == 'search-pill-container' ||
      label == 'transaction-header-surface' ||
      label == 'header-fast-info-surface' ||
      label == 'header-category-button-surface' ||
      label == 'header-expand-button-surface' ||
      (label.startsWith('bottom-nav-') && label.endsWith('-surface')) ||
      label.startsWith('transaction-type-pill-') ||
      label.startsWith('transaction-logbox-content-') ||
      label.startsWith('transaction-logbox-avatar-surface-');
}

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
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
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePressed = widget.forcePressed || _pressed;
    if (!widget.enabled) return widget.builder(context, effectivePressed);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _releaseTimer?.cancel();
        _setPressed(true);
      },
      onPointerUp: (_) => _releasePressedSoon(),
      onPointerCancel: (_) => _releasePressedSoon(),
      child: widget.builder(context, effectivePressed),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _releasePressedSoon() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(milliseconds: 120), () {
      _setPressed(false);
    });
  }
}

enum _SurfaceDepth { neutral, raised, inset, deepInset }
