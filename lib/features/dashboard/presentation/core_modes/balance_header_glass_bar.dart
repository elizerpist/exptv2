import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_glass_ui_kit/flutter_glass_ui_kit.dart' as glass_ui;
import 'package:glass_kit/glass_kit.dart' as glass_kit;
import 'package:glassmorphism/glassmorphism.dart' as glassmorphism;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;

import 'balance_header_glass_configuration.dart';
import 'dashboard_partition_lane_geometry.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';

/// Shared geometry/data host for every Balance Header material adapter.
///
/// The only variable beneath each renderer is its material. Size, position,
/// capsule clipping and income ratio are resolved once here, keeping visual
/// A/B comparisons honest and keeping financial inputs resident.
final class BalanceHeaderGlassBar extends StatelessWidget {
  const BalanceHeaderGlassBar({
    super.key,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.heightPercent,
    required this.configuration,
    required this.plotTop,
    required this.plotHeight,
    required this.valueTop,
  });

  final int incomeMinor;
  final int expenseMinor;
  final double heightPercent;
  final BalanceHeaderGlassConfiguration configuration;
  final double plotTop;
  final double plotHeight;
  final double valueTop;

  static double incomeRatioFor({
    required int incomeMinor,
    required int expenseMinor,
  }) {
    final income = math.max(0, incomeMinor);
    final expense = math.max(0, expenseMinor);
    final denominator = income + expense;
    return denominator == 0
        ? .5
        : (income / denominator).clamp(0.0, 1.0).toDouble();
  }

  static double topFor({
    required double plotTop,
    required double plotHeight,
    required double valueTop,
    required double height,
    required double verticalPosition,
  }) => DashboardPartitionLaneGeometry.balanceHeaderTopFor(
    plotTop: plotTop,
    plotHeight: plotHeight,
    valueTop: valueTop,
    height: height,
    verticalPosition: verticalPosition,
  );

  @override
  Widget build(BuildContext context) {
    final height = DashboardPartitionLaneGeometry.balanceHeaderThicknessFor(
      heightPercent,
    );
    final ratio = incomeRatioFor(
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
    );
    final top = topFor(
      plotTop: plotTop,
      plotHeight: plotHeight,
      valueTop: valueTop,
      height: height,
      verticalPosition: configuration.verticalPosition,
    );
    return Positioned(
      key: const ValueKey<String>('balance-header-income-expense-partition'),
      left: DashboardHeaderTrendChartStyle.plotLeft,
      right: DashboardHeaderTrendChartStyle.plotLeft,
      top: top,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final radius = height / 2;
          return RepaintBoundary(
            key: ValueKey<String>(
              'balance-header-glass-${configuration.renderer.name}',
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _BalanceGlassMaterial(
                  physicalKey: const ValueKey<String>(
                    'balance-header-glass-physical-body',
                  ),
                  trackMaterial: configuration.materialFor(incomeFill: false),
                  incomeMaterial: configuration.materialFor(incomeFill: true),
                  incomeRatio: ratio,
                  renderer: configuration.renderer,
                  quality: configuration.quality,
                  borderRadius: radius,
                ),
                _BalanceGlassBarLabels(incomeRatio: ratio),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _BalanceGlassBarLabels extends StatelessWidget {
  const _BalanceGlassBarLabels({required this.incomeRatio});

  final double incomeRatio;

  @override
  Widget build(BuildContext context) {
    final incomePercent = (incomeRatio * 100).round();
    final expensePercent = 100 - incomePercent;
    const style = TextStyle(
      color: Color(0xe6ffffff),
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w900,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$incomePercent%', style: style),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('$expensePercent%', style: style),
            ),
          ),
        ],
      ),
    );
  }
}

/// One package-specific physical material surface. Geometry and financial
/// inputs are already resolved by the host. The income ratio is deliberately
/// an internal material field, never another backdrop or glass surface.
final class _BalanceGlassMaterial extends StatelessWidget {
  const _BalanceGlassMaterial({
    required this.physicalKey,
    required this.trackMaterial,
    required this.incomeMaterial,
    required this.incomeRatio,
    required this.renderer,
    required this.quality,
    required this.borderRadius,
  });

  final Key physicalKey;
  final BalanceGlassMaterialConfiguration trackMaterial;
  final BalanceGlassMaterialConfiguration incomeMaterial;
  final double incomeRatio;
  final BalanceHeaderGlassRenderer renderer;
  final BalanceGlassQuality quality;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: physicalKey,
    child: switch (renderer) {
      BalanceHeaderGlassRenderer.baseline => _baseline(),
      BalanceHeaderGlassRenderer.flutterNative => _native(),
      BalanceHeaderGlassRenderer.glassKit => _glassKit(),
      BalanceHeaderGlassRenderer.glassmorphism => _glassmorphism(),
      BalanceHeaderGlassRenderer.flutterGlassUiKit => _flutterGlassUiKit(),
      BalanceHeaderGlassRenderer.liquidGlassWidgets => _liquidGlass(),
    },
  );

  Widget _baseline() => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: _baselineGradient(const Color(0xffdc4e75), trackMaterial),
      boxShadow: _shadows(trackMaterial),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _BalanceGlassIncomeMaterialField(
          material: incomeMaterial,
          incomeRatio: incomeRatio,
          borderRadius: borderRadius,
          baseline: true,
        ),
        if (trackMaterial.borderWidth > 0)
          IgnorePointer(
            child: CustomPaint(
              painter: _BalanceGlassGradientBorderPainter(
                gradient: _borderGradient(trackMaterial),
                borderRadius: borderRadius,
                borderWidth: trackMaterial.borderWidth,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _native() {
    final body = _BalanceGlassMaterialFields(
      trackMaterial: trackMaterial,
      incomeMaterial: incomeMaterial,
      incomeRatio: incomeRatio,
      borderRadius: borderRadius,
      paintsTrack: true,
      paintsLocalizedRim: true,
    );
    return _shadowWrapper(
      trackMaterial,
      ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filterConfig: ImageFilterConfig.blur(
            sigmaX: trackMaterial.blurX,
            sigmaY: trackMaterial.blurY,
            bounded: trackMaterial.boundedBlur,
            tileMode: _tileMode(trackMaterial.tileMode),
          ),
          blendMode: _blendMode(trackMaterial.blendMode),
          child: body,
        ),
      ),
    );
  }

  Widget _glassKit() => glass_kit.GlassContainer(
    blur: trackMaterial.blurX,
    isFrostedGlass: trackMaterial.frostedGlass,
    frostedOpacity: trackMaterial.frostedOpacity,
    color: _color(trackMaterial.tintArgb, trackMaterial.tintOpacity),
    gradient: _materialGradient(trackMaterial, blendTint: true),
    borderColor: _color(trackMaterial.borderArgb, trackMaterial.borderOpacity),
    borderGradient: _borderGradient(trackMaterial),
    borderWidth: trackMaterial.borderWidth,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: _shadows(trackMaterial),
    child: _packageMaterialField(),
  );

  Widget _glassmorphism() => glassmorphism.GlassmorphicContainer(
    borderRadius: borderRadius,
    blur: trackMaterial.blurX,
    border: trackMaterial.borderWidth,
    linearGradient: _materialGradient(trackMaterial, blendTint: true),
    borderGradient: _borderGradient(trackMaterial),
    boxShadow: _shadows(trackMaterial),
    child: _packageMaterialField(),
  );

  Widget _flutterGlassUiKit() => _shadowWrapper(
    trackMaterial,
    glass_ui.GlassContainer(
      blur: trackMaterial.blurX,
      opacity: trackMaterial.tintOpacity,
      frostColor: _color(trackMaterial.tintArgb, trackMaterial.tintOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      borderWidth: trackMaterial.borderWidth,
      borderGradient: _borderGradient(trackMaterial),
      backgroundGradient: _materialGradient(trackMaterial),
      performance: trackMaterial.performanceLow
          ? glass_ui.GlassPerformance.low
          : glass_ui.GlassPerformance.medium,
      enableBlur: trackMaterial.blurX > 0,
      child: _packageMaterialField(),
    ),
  );

  Widget _liquidGlass() => liquid.GlassContainer(
    // The exact 1.8.1 source documents this as the valid independent
    // per-widget Premium path. A page-wide sampling scope is not required by
    // Impeller Premium and would broaden this small Header-only surface.
    useOwnLayer: true,
    quality: switch (quality) {
      BalanceGlassQuality.minimal => liquid.GlassQuality.minimal,
      BalanceGlassQuality.standard => liquid.GlassQuality.standard,
      BalanceGlassQuality.premium => liquid.GlassQuality.premium,
    },
    shape: liquid.LiquidRoundedRectangle(borderRadius: borderRadius),
    settings: liquid.LiquidGlassSettings(
      visibility: trackMaterial.tintOpacity,
      glassColor: _color(trackMaterial.tintArgb, trackMaterial.tintOpacity),
      thickness: trackMaterial.thickness,
      blur: trackMaterial.blurX,
      chromaticAberration: trackMaterial.chromaticAberration,
      lightAngle: trackMaterial.lightAngle,
      lightIntensity: trackMaterial.lightIntensity,
      ambientStrength: trackMaterial.ambientStrength,
      ambientRim: trackMaterial.ambientRim,
      fresnelStrength: trackMaterial.fresnelStrength,
      refractiveIndex: trackMaterial.refractiveIndex,
      saturation: trackMaterial.saturation,
      glowIntensity: trackMaterial.glowIntensity,
      specularSharpness: switch (trackMaterial.specularSharpness) {
        BalanceGlassSpecularSharpness.soft =>
          liquid.GlassSpecularSharpness.soft,
        BalanceGlassSpecularSharpness.medium =>
          liquid.GlassSpecularSharpness.medium,
        BalanceGlassSpecularSharpness.sharp =>
          liquid.GlassSpecularSharpness.sharp,
      },
      standardOpacityMultiplier: trackMaterial.standardOpacityMultiplier,
      shadowElevation: trackMaterial.shadowElevation,
      shadow: _shadows(trackMaterial),
      whitenStrength: trackMaterial.whitenStrength,
      whitenGated: trackMaterial.whitenGated,
      edgeAbsorption: trackMaterial.edgeAbsorption,
      backerColor: trackMaterial.backerArgb == 0
          ? null
          : Color(trackMaterial.backerArgb),
      bodyMode: switch (trackMaterial.bodyMode) {
        BalanceGlassBodyMode.adaptive => liquid.GlassBodyMode.adaptive,
        BalanceGlassBodyMode.clear => liquid.GlassBodyMode.clear,
      },
      platformViewMode: switch (trackMaterial.platformViewMode) {
        BalanceGlassPlatformViewMode.fallbackColor =>
          liquid.PlatformViewGlassMode.fallbackColor,
        BalanceGlassPlatformViewMode.passthrough =>
          liquid.PlatformViewGlassMode.passthrough,
      },
      platformViewFallbackColor: trackMaterial.platformViewFallbackArgb == 0
          ? null
          : Color(trackMaterial.platformViewFallbackArgb),
    ),
    allowElevation: trackMaterial.shadowEnabled,
    glowIntensity: trackMaterial.glowIntensity,
    platformViewBackdrop:
        trackMaterial.platformViewMode ==
        BalanceGlassPlatformViewMode.fallbackColor,
    child: _BalanceGlassMaterialFields(
      trackMaterial: trackMaterial,
      incomeMaterial: incomeMaterial,
      incomeRatio: incomeRatio,
      borderRadius: borderRadius,
      paintsTrack: true,
      paintsLocalizedRim: true,
    ),
  );

  Widget _packageMaterialField() => _BalanceGlassIncomeMaterialField(
    material: incomeMaterial,
    incomeRatio: incomeRatio,
    borderRadius: borderRadius,
  );

  static Color _color(int argb, double opacity) =>
      Color(argb).withValues(alpha: opacity.clamp(0, 1).toDouble());

  static Color _materialColor(
    BalanceGlassMaterialConfiguration material,
    int argb,
    double opacity, {
    required bool blendTint,
  }) {
    final base = _color(argb, opacity);
    return blendTint
        ? Color.alphaBlend(
            _color(material.tintArgb, material.tintOpacity),
            base,
          )
        : base;
  }

  static LinearGradient _materialGradient(
    BalanceGlassMaterialConfiguration material, {
    bool blendTint = false,
  }) => _gradient(
    _materialColor(
      material,
      material.gradientStartArgb,
      material.gradientStartOpacity,
      blendTint: blendTint,
    ),
    _materialColor(
      material,
      material.gradientEndArgb,
      material.gradientEndOpacity,
      blendTint: blendTint,
    ),
    material.gradientDirection,
    startStop: material.gradientStartStop,
    endStop: material.gradientEndStop,
  );

  static LinearGradient _borderGradient(
    BalanceGlassMaterialConfiguration material,
  ) => _gradient(
    Color.alphaBlend(
      _color(material.borderArgb, material.borderOpacity),
      _color(
        material.borderGradientStartArgb,
        material.borderGradientStartOpacity,
      ),
    ),
    Color.alphaBlend(
      _color(material.borderArgb, material.borderOpacity),
      _color(material.borderGradientEndArgb, material.borderGradientEndOpacity),
    ),
    material.borderGradientDirection,
    startStop: material.borderGradientStartStop,
    endStop: material.borderGradientEndStop,
  );

  static LinearGradient _gradient(
    Color start,
    Color end,
    BalanceGlassDirection direction, {
    double startStop = 0,
    double endStop = 1,
  }) {
    final normalizedStart = startStop.clamp(0, 1).toDouble();
    final normalizedEnd = endStop.clamp(normalizedStart, 1).toDouble();
    return LinearGradient(
      begin: switch (direction) {
        BalanceGlassDirection.leftToRight => Alignment.centerLeft,
        BalanceGlassDirection.topToBottom => Alignment.topCenter,
        BalanceGlassDirection.diagonalDown => Alignment.topLeft,
        BalanceGlassDirection.diagonalUp => Alignment.bottomLeft,
      },
      end: switch (direction) {
        BalanceGlassDirection.leftToRight => Alignment.centerRight,
        BalanceGlassDirection.topToBottom => Alignment.bottomCenter,
        BalanceGlassDirection.diagonalDown => Alignment.bottomRight,
        BalanceGlassDirection.diagonalUp => Alignment.topRight,
      },
      colors: <Color>[start, end],
      stops: <double>[normalizedStart, normalizedEnd],
    );
  }

  static LinearGradient _baselineGradient(
    Color base,
    BalanceGlassMaterialConfiguration material,
  ) => _gradient(
    Color.alphaBlend(
      _color(material.gradientStartArgb, material.gradientStartOpacity),
      Color.alphaBlend(_color(material.tintArgb, material.tintOpacity), base),
    ),
    Color.alphaBlend(
      _color(material.gradientEndArgb, material.gradientEndOpacity),
      Color.alphaBlend(_color(material.tintArgb, material.tintOpacity), base),
    ),
    material.gradientDirection,
    startStop: material.gradientStartStop,
    endStop: material.gradientEndStop,
  );

  static Widget _shadowWrapper(
    BalanceGlassMaterialConfiguration material,
    Widget child,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: _shadows(material),
    ),
    child: child,
  );

  static List<BoxShadow> _shadows(BalanceGlassMaterialConfiguration material) =>
      material.shadowEnabled
      ? <BoxShadow>[
          BoxShadow(
            color: _color(material.shadowArgb, material.shadowOpacity),
            blurRadius: material.shadowBlur,
            spreadRadius: material.shadowSpread,
            offset: Offset(material.shadowOffsetX, material.shadowOffsetY),
          ),
        ]
      : const <BoxShadow>[];

  static ui.TileMode _tileMode(BalanceGlassTileMode mode) => switch (mode) {
    BalanceGlassTileMode.clamp => ui.TileMode.clamp,
    BalanceGlassTileMode.repeated => ui.TileMode.repeated,
    BalanceGlassTileMode.mirror => ui.TileMode.mirror,
    BalanceGlassTileMode.decal => ui.TileMode.decal,
  };

  static BlendMode _blendMode(BalanceGlassBlendMode mode) => switch (mode) {
    BalanceGlassBlendMode.srcOver => BlendMode.srcOver,
    BalanceGlassBlendMode.screen => BlendMode.screen,
    BalanceGlassBlendMode.plus => BlendMode.plus,
    BalanceGlassBlendMode.softLight => BlendMode.softLight,
  };
}

/// Native material paint under the one [BackdropFilter]. The track is painted
/// once; only a bounded internal material field changes at the income ratio.
final class _BalanceGlassMaterialFields extends StatelessWidget {
  const _BalanceGlassMaterialFields({
    required this.trackMaterial,
    required this.incomeMaterial,
    required this.incomeRatio,
    required this.borderRadius,
    required this.paintsTrack,
    required this.paintsLocalizedRim,
  });

  final BalanceGlassMaterialConfiguration trackMaterial;
  final BalanceGlassMaterialConfiguration incomeMaterial;
  final double incomeRatio;
  final double borderRadius;
  final bool paintsTrack;
  final bool paintsLocalizedRim;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      if (paintsTrack) _nativeTrack(),
      _BalanceGlassIncomeMaterialField(
        material: incomeMaterial,
        incomeRatio: incomeRatio,
        borderRadius: borderRadius,
      ),
      if (paintsLocalizedRim && trackMaterial.specularOpacity > 0)
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: .18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(
                        alpha: trackMaterial.specularOpacity,
                      ),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      if (paintsTrack && trackMaterial.borderWidth > 0)
        IgnorePointer(
          child: CustomPaint(
            painter: _BalanceGlassGradientBorderPainter(
              gradient: _BalanceGlassMaterial._borderGradient(trackMaterial),
              borderRadius: borderRadius,
              borderWidth: trackMaterial.borderWidth,
            ),
          ),
        ),
    ],
  );

  Widget _nativeTrack() => DecoratedBox(
    key: const ValueKey<String>('balance-header-glass-native-track-tint'),
    decoration: BoxDecoration(
      color: _BalanceGlassMaterial._color(
        trackMaterial.tintArgb,
        trackMaterial.tintOpacity,
      ),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _BalanceGlassMaterial._materialGradient(trackMaterial),
      ),
    ),
  );
}

final class _BalanceGlassGradientBorderPainter extends CustomPainter {
  const _BalanceGlassGradientBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.borderWidth,
  });

  final Gradient gradient;
  final double borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = borderWidth / 2;
    final borderRect = rect.deflate(inset);
    final radius = math.max(0, borderRadius - inset).toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(borderRect, Radius.circular(radius)),
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_BalanceGlassGradientBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth;
}

/// A bounded tint/gradient field inside an existing glass sheet. It has no
/// filter, package glass container, shadow or independent backdrop owner.
final class _BalanceGlassIncomeMaterialField extends StatelessWidget {
  const _BalanceGlassIncomeMaterialField({
    required this.material,
    required this.incomeRatio,
    required this.borderRadius,
    this.baseline = false,
  });

  final BalanceGlassMaterialConfiguration material;
  final double incomeRatio;
  final double borderRadius;
  final bool baseline;

  @override
  Widget build(BuildContext context) {
    final ratio = incomeRatio.clamp(0, 1).toDouble();
    if (ratio == 0) return const SizedBox.expand();
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: ratio,
        child: ClipRRect(
          key: const ValueKey<String>(
            'balance-header-glass-income-material-field',
          ),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(borderRadius),
            right: ratio == 1 ? Radius.circular(borderRadius) : Radius.zero,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: baseline
                      ? _BalanceGlassMaterial._baselineGradient(
                          const Color(0xff1f9f70),
                          material,
                        )
                      : _BalanceGlassMaterial._materialGradient(material),
                ),
              ),
              if (material.specularOpacity > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: .20,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(
                                alpha: material.specularOpacity,
                              ),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
