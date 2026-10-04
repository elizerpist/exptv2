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
  }) {
    // The upper bound derives from the same Header primary-value typography
    // token as the displayed Balance amount; the lower bound is the actual
    // chart safe bottom. A size change therefore automatically re-resolves
    // both bounds without magic fixed bar coordinates.
    final valueBottom =
        valueTop +
        DashboardHeaderTrendChartStyle.primaryValueTextMetrics.fontSize! *
            DashboardHeaderTrendChartStyle.primaryValueTextMetrics.height!;
    final topLimit = valueBottom + 7;
    final bottomLimit = math.max(topLimit, plotTop + plotHeight - height);
    return bottomLimit -
        (bottomLimit - topLimit) * verticalPosition.clamp(0.0, 1.0);
  }

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
          final fillWidth = constraints.maxWidth * ratio;
          return RepaintBoundary(
            key: ValueKey<String>(
              'balance-header-glass-${configuration.renderer.name}',
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _BalanceGlassMaterial(
                  material: configuration.materialFor(incomeFill: false),
                  renderer: configuration.renderer,
                  quality: configuration.quality,
                  borderRadius: radius,
                  isIncomeFill: false,
                ),
                if (fillWidth > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      key: const ValueKey<String>(
                        'balance-header-income-expense-income',
                      ),
                      width: fillWidth,
                      height: height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(radius),
                          right: ratio == 1
                              ? Radius.circular(radius)
                              : Radius.zero,
                        ),
                        child: _BalanceGlassMaterial(
                          material: configuration.materialFor(incomeFill: true),
                          renderer: configuration.renderer,
                          quality: configuration.quality,
                          borderRadius: radius,
                          isIncomeFill: true,
                        ),
                      ),
                    ),
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

/// One package-specific material surface. It deliberately owns no size or
/// financial inputs: callers have already resolved the common capsule.
final class _BalanceGlassMaterial extends StatelessWidget {
  const _BalanceGlassMaterial({
    required this.material,
    required this.renderer,
    required this.quality,
    required this.borderRadius,
    required this.isIncomeFill,
  });

  final BalanceGlassMaterialConfiguration material;
  final BalanceHeaderGlassRenderer renderer;
  final BalanceGlassQuality quality;
  final double borderRadius;
  final bool isIncomeFill;

  @override
  Widget build(BuildContext context) {
    final child = const SizedBox.expand();
    return switch (renderer) {
      BalanceHeaderGlassRenderer.baseline => _baseline(child),
      BalanceHeaderGlassRenderer.flutterNative => _native(child),
      BalanceHeaderGlassRenderer.glassKit => _glassKit(child),
      BalanceHeaderGlassRenderer.glassmorphism => _glassmorphism(child),
      BalanceHeaderGlassRenderer.flutterGlassUiKit => _flutterGlassUiKit(child),
      BalanceHeaderGlassRenderer.liquidGlassWidgets => _liquidGlass(child),
    };
  }

  Widget _baseline(Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: <Color>[
          (isIncomeFill ? const Color(0xff24ad73) : const Color(0xffe05672))
              .withValues(alpha: .95),
          isIncomeFill ? const Color(0xff24ad73) : const Color(0xffe05672),
        ],
      ),
    ),
    child: child,
  );

  Widget _native(Widget child) {
    final inner = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: _gradient(
              material.gradientStartArgb,
              material.gradientStartOpacity,
              material.gradientEndArgb,
              material.gradientEndOpacity,
              material.gradientDirection,
              startStop: material.gradientStartStop,
              endStop: material.gradientEndStop,
            ),
            border: Border.all(
              color: _color(material.borderArgb, material.borderOpacity),
              width: material.borderWidth,
            ),
            boxShadow: _shadows(material),
          ),
          child: child,
        ),
        if (material.specularOpacity > 0)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: material.specularOpacity),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const <double>[0, .55],
                ),
              ),
            ),
          ),
      ],
    );
    final filtered = material.backdropGrouping
        ? BackdropFilter.grouped(
            filterConfig: ImageFilterConfig.blur(
              sigmaX: material.blurX,
              sigmaY: material.blurY,
              bounded: material.boundedBlur,
              tileMode: _tileMode(material.tileMode),
            ),
            blendMode: _blendMode(material.blendMode),
            child: inner,
          )
        : BackdropFilter(
            filterConfig: ImageFilterConfig.blur(
              sigmaX: material.blurX,
              sigmaY: material.blurY,
              bounded: material.boundedBlur,
              tileMode: _tileMode(material.tileMode),
            ),
            blendMode: _blendMode(material.blendMode),
            child: inner,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: material.backdropGrouping
          ? BackdropGroup(child: filtered)
          : filtered,
    );
  }

  Widget _glassKit(Widget child) => glass_kit.GlassContainer(
    blur: material.blurX,
    isFrostedGlass: material.frostedGlass,
    frostedOpacity: material.frostedOpacity,
    color: _color(material.tintArgb, material.tintOpacity),
    gradient: _gradient(
      material.gradientStartArgb,
      material.gradientStartOpacity,
      material.gradientEndArgb,
      material.gradientEndOpacity,
      material.gradientDirection,
      startStop: material.gradientStartStop,
      endStop: material.gradientEndStop,
    ),
    borderColor: _color(material.borderArgb, material.borderOpacity),
    borderGradient: _gradient(
      material.borderGradientStartArgb,
      material.borderGradientStartOpacity,
      material.borderGradientEndArgb,
      material.borderGradientEndOpacity,
      material.borderGradientDirection,
      startStop: material.borderGradientStartStop,
      endStop: material.borderGradientEndStop,
    ),
    borderWidth: material.borderWidth,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: _shadows(material),
    child: child,
  );

  Widget _glassmorphism(Widget child) => glassmorphism.GlassmorphicContainer(
    borderRadius: borderRadius,
    blur: material.blurX,
    border: material.borderWidth,
    linearGradient: _gradient(
      material.gradientStartArgb,
      material.gradientStartOpacity,
      material.gradientEndArgb,
      material.gradientEndOpacity,
      material.gradientDirection,
      startStop: material.gradientStartStop,
      endStop: material.gradientEndStop,
    ),
    borderGradient: _gradient(
      material.borderGradientStartArgb,
      material.borderGradientStartOpacity,
      material.borderGradientEndArgb,
      material.borderGradientEndOpacity,
      material.borderGradientDirection,
      startStop: material.borderGradientStartStop,
      endStop: material.borderGradientEndStop,
    ),
    boxShadow: _shadows(material),
    child: child,
  );

  Widget _flutterGlassUiKit(Widget child) => glass_ui.GlassContainer(
    blur: material.blurX,
    opacity: material.tintOpacity,
    frostColor: _color(material.tintArgb, material.tintOpacity),
    borderRadius: BorderRadius.circular(borderRadius),
    borderWidth: material.borderWidth,
    borderGradient: _gradient(
      material.borderGradientStartArgb,
      material.borderGradientStartOpacity,
      material.borderGradientEndArgb,
      material.borderGradientEndOpacity,
      material.borderGradientDirection,
      startStop: material.borderGradientStartStop,
      endStop: material.borderGradientEndStop,
    ),
    backgroundGradient: _gradient(
      material.gradientStartArgb,
      material.gradientStartOpacity,
      material.gradientEndArgb,
      material.gradientEndOpacity,
      material.gradientDirection,
      startStop: material.gradientStartStop,
      endStop: material.gradientEndStop,
    ),
    performance: material.performanceLow
        ? glass_ui.GlassPerformance.low
        : glass_ui.GlassPerformance.medium,
    enableBlur: material.blurX > 0,
    child: child,
  );

  Widget _liquidGlass(Widget child) => liquid.GlassContainer(
    useOwnLayer: true,
    quality: switch (quality) {
      BalanceGlassQuality.minimal => liquid.GlassQuality.minimal,
      BalanceGlassQuality.standard => liquid.GlassQuality.standard,
      BalanceGlassQuality.premium => liquid.GlassQuality.premium,
    },
    shape: liquid.LiquidRoundedRectangle(borderRadius: borderRadius),
    settings: liquid.LiquidGlassSettings(
      visibility: material.tintOpacity,
      glassColor: _color(material.tintArgb, material.tintOpacity),
      thickness: material.thickness,
      blur: material.blurX,
      chromaticAberration: material.chromaticAberration,
      lightAngle: material.lightAngle,
      lightIntensity: material.lightIntensity,
      ambientStrength: material.ambientStrength,
      ambientRim: material.ambientRim,
      fresnelStrength: material.fresnelStrength,
      refractiveIndex: material.refractiveIndex,
      saturation: material.saturation,
      glowIntensity: material.glowIntensity,
      specularSharpness: switch (material.specularSharpness) {
        BalanceGlassSpecularSharpness.soft =>
          liquid.GlassSpecularSharpness.soft,
        BalanceGlassSpecularSharpness.medium =>
          liquid.GlassSpecularSharpness.medium,
        BalanceGlassSpecularSharpness.sharp =>
          liquid.GlassSpecularSharpness.sharp,
      },
      standardOpacityMultiplier: material.standardOpacityMultiplier,
      shadowElevation: material.shadowElevation,
      shadow: _shadows(material),
      whitenStrength: material.whitenStrength,
      whitenGated: material.whitenGated,
      edgeAbsorption: material.edgeAbsorption,
      backerColor: material.backerArgb == 0 ? null : Color(material.backerArgb),
      bodyMode: switch (material.bodyMode) {
        BalanceGlassBodyMode.adaptive => liquid.GlassBodyMode.adaptive,
        BalanceGlassBodyMode.clear => liquid.GlassBodyMode.clear,
      },
      platformViewMode: switch (material.platformViewMode) {
        BalanceGlassPlatformViewMode.fallbackColor =>
          liquid.PlatformViewGlassMode.fallbackColor,
        BalanceGlassPlatformViewMode.passthrough =>
          liquid.PlatformViewGlassMode.passthrough,
      },
      platformViewFallbackColor: material.platformViewFallbackArgb == 0
          ? null
          : Color(material.platformViewFallbackArgb),
    ),
    allowElevation: material.shadowEnabled,
    glowIntensity: material.glowIntensity,
    platformViewBackdrop:
        material.platformViewMode == BalanceGlassPlatformViewMode.fallbackColor,
    child: child,
  );

  static Color _color(int argb, double opacity) =>
      Color(argb).withValues(alpha: opacity.clamp(0, 1).toDouble());

  static LinearGradient _gradient(
    int startArgb,
    double startOpacity,
    int endArgb,
    double endOpacity,
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
      colors: <Color>[
        _color(startArgb, startOpacity),
        _color(endArgb, endOpacity),
      ],
      stops: <double>[normalizedStart, normalizedEnd],
    );
  }

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
