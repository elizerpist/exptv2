import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The selected material backend for the one shared Balance Header bar.
///
/// These are presentation adapters only. The bar's geometry and resident
/// income/expense ratio stay outside this value so changing material can never
/// create a second financial calculation path.
enum BalanceHeaderGlassRenderer {
  baseline,
  flutterNative,
  glassKit,
  glassmorphism,
  flutterGlassUiKit,
  liquidGlassWidgets;

  String get tunerLabel => switch (this) {
    BalanceHeaderGlassRenderer.baseline => 'Jelenlegi / alap',
    BalanceHeaderGlassRenderer.flutterNative => 'Flutter natív',
    BalanceHeaderGlassRenderer.glassKit => 'glass_kit',
    BalanceHeaderGlassRenderer.glassmorphism => 'glassmorphism',
    BalanceHeaderGlassRenderer.flutterGlassUiKit => 'flutter_glass_ui_kit',
    BalanceHeaderGlassRenderer.liquidGlassWidgets => 'liquid_glass_widgets',
  };
}

enum BalanceGlassQuality { minimal, standard, premium }

enum BalanceGlassTileMode { clamp, repeated, mirror, decal }

enum BalanceGlassBlendMode { srcOver, screen, plus, softLight }

enum BalanceGlassDirection {
  leftToRight,
  topToBottom,
  diagonalDown,
  diagonalUp,
}

enum BalanceGlassSpecularSharpness { soft, medium, sharp }

enum BalanceGlassBodyMode { adaptive, clear }

enum BalanceGlassPlatformViewMode { fallbackColor, passthrough }

/// Serializable material controls shared by the renderer adapters. Each
/// adapter consumes the fields its actual package exposes; values remain in
/// the app-owned model rather than leaking package classes into persistence.
@immutable
final class BalanceGlassMaterialConfiguration {
  const BalanceGlassMaterialConfiguration({
    this.blurX = 12,
    this.blurY = 12,
    this.boundedBlur = true,
    this.backdropGrouping = false,
    this.tileMode = BalanceGlassTileMode.clamp,
    this.blendMode = BalanceGlassBlendMode.srcOver,
    this.tintArgb = 0xffffffff,
    this.tintOpacity = .12,
    this.gradientStartArgb = 0xffffffff,
    this.gradientEndArgb = 0xffffffff,
    this.gradientStartOpacity = .20,
    this.gradientEndOpacity = .05,
    this.gradientDirection = BalanceGlassDirection.diagonalDown,
    this.gradientStartStop = 0,
    this.gradientEndStop = 1,
    this.borderWidth = 1,
    this.borderArgb = 0xffffffff,
    this.borderOpacity = .35,
    this.borderGradientStartArgb = 0xffffffff,
    this.borderGradientEndArgb = 0xffffffff,
    this.borderGradientStartOpacity = .60,
    this.borderGradientEndOpacity = .15,
    this.borderGradientDirection = BalanceGlassDirection.diagonalDown,
    this.borderGradientStartStop = 0,
    this.borderGradientEndStop = 1,
    this.frostedGlass = false,
    this.frostedOpacity = .08,
    this.specularOpacity = .22,
    this.shadowEnabled = true,
    this.shadowArgb = 0xff000000,
    this.shadowOpacity = .14,
    this.shadowBlur = 10,
    this.shadowSpread = 0,
    this.shadowOffsetX = 0,
    this.shadowOffsetY = 3,
    this.performanceLow = false,
    this.thickness = 20,
    this.chromaticAberration = .01,
    this.lightAngle = 1.57,
    this.lightIntensity = .50,
    this.ambientStrength = .10,
    this.ambientRim = 0,
    this.fresnelStrength = 1,
    this.refractiveIndex = 1.20,
    this.saturation = 1.5,
    this.glowIntensity = .25,
    this.specularSharpness = BalanceGlassSpecularSharpness.medium,
    this.standardOpacityMultiplier = 1,
    this.shadowElevation = 1,
    this.whitenStrength = 0,
    this.whitenGated = true,
    this.edgeAbsorption = 0,
    this.backerArgb = 0x00000000,
    this.bodyMode = BalanceGlassBodyMode.adaptive,
    this.platformViewMode = BalanceGlassPlatformViewMode.fallbackColor,
    this.platformViewFallbackArgb = 0x00000000,
  });

  final double blurX;
  final double blurY;
  final bool boundedBlur;
  final bool backdropGrouping;
  final BalanceGlassTileMode tileMode;
  final BalanceGlassBlendMode blendMode;
  final int tintArgb;
  final double tintOpacity;
  final int gradientStartArgb;
  final int gradientEndArgb;
  final double gradientStartOpacity;
  final double gradientEndOpacity;
  final BalanceGlassDirection gradientDirection;
  final double gradientStartStop;
  final double gradientEndStop;
  final double borderWidth;
  final int borderArgb;
  final double borderOpacity;
  final int borderGradientStartArgb;
  final int borderGradientEndArgb;
  final double borderGradientStartOpacity;
  final double borderGradientEndOpacity;
  final BalanceGlassDirection borderGradientDirection;
  final double borderGradientStartStop;
  final double borderGradientEndStop;
  final bool frostedGlass;
  final double frostedOpacity;
  final double specularOpacity;
  final bool shadowEnabled;
  final int shadowArgb;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowSpread;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final bool performanceLow;
  final double thickness;
  final double chromaticAberration;
  final double lightAngle;
  final double lightIntensity;
  final double ambientStrength;
  final double ambientRim;
  final double fresnelStrength;
  final double refractiveIndex;
  final double saturation;
  final double glowIntensity;
  final BalanceGlassSpecularSharpness specularSharpness;
  final double standardOpacityMultiplier;
  final double shadowElevation;
  final double whitenStrength;
  final bool whitenGated;
  final double edgeAbsorption;
  final int backerArgb;
  final BalanceGlassBodyMode bodyMode;
  final BalanceGlassPlatformViewMode platformViewMode;
  final int platformViewFallbackArgb;

  BalanceGlassMaterialConfiguration copyWith({
    double? blurX,
    double? blurY,
    bool? boundedBlur,
    bool? backdropGrouping,
    BalanceGlassTileMode? tileMode,
    BalanceGlassBlendMode? blendMode,
    int? tintArgb,
    double? tintOpacity,
    int? gradientStartArgb,
    int? gradientEndArgb,
    double? gradientStartOpacity,
    double? gradientEndOpacity,
    BalanceGlassDirection? gradientDirection,
    double? gradientStartStop,
    double? gradientEndStop,
    double? borderWidth,
    int? borderArgb,
    double? borderOpacity,
    int? borderGradientStartArgb,
    int? borderGradientEndArgb,
    double? borderGradientStartOpacity,
    double? borderGradientEndOpacity,
    BalanceGlassDirection? borderGradientDirection,
    double? borderGradientStartStop,
    double? borderGradientEndStop,
    bool? frostedGlass,
    double? frostedOpacity,
    double? specularOpacity,
    bool? shadowEnabled,
    int? shadowArgb,
    double? shadowOpacity,
    double? shadowBlur,
    double? shadowSpread,
    double? shadowOffsetX,
    double? shadowOffsetY,
    bool? performanceLow,
    double? thickness,
    double? chromaticAberration,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? ambientRim,
    double? fresnelStrength,
    double? refractiveIndex,
    double? saturation,
    double? glowIntensity,
    BalanceGlassSpecularSharpness? specularSharpness,
    double? standardOpacityMultiplier,
    double? shadowElevation,
    double? whitenStrength,
    bool? whitenGated,
    double? edgeAbsorption,
    int? backerArgb,
    BalanceGlassBodyMode? bodyMode,
    BalanceGlassPlatformViewMode? platformViewMode,
    int? platformViewFallbackArgb,
  }) => BalanceGlassMaterialConfiguration(
    blurX: blurX ?? this.blurX,
    blurY: blurY ?? this.blurY,
    boundedBlur: boundedBlur ?? this.boundedBlur,
    backdropGrouping: backdropGrouping ?? this.backdropGrouping,
    tileMode: tileMode ?? this.tileMode,
    blendMode: blendMode ?? this.blendMode,
    tintArgb: tintArgb ?? this.tintArgb,
    tintOpacity: tintOpacity ?? this.tintOpacity,
    gradientStartArgb: gradientStartArgb ?? this.gradientStartArgb,
    gradientEndArgb: gradientEndArgb ?? this.gradientEndArgb,
    gradientStartOpacity: gradientStartOpacity ?? this.gradientStartOpacity,
    gradientEndOpacity: gradientEndOpacity ?? this.gradientEndOpacity,
    gradientDirection: gradientDirection ?? this.gradientDirection,
    gradientStartStop: gradientStartStop ?? this.gradientStartStop,
    gradientEndStop: gradientEndStop ?? this.gradientEndStop,
    borderWidth: borderWidth ?? this.borderWidth,
    borderArgb: borderArgb ?? this.borderArgb,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    borderGradientStartArgb:
        borderGradientStartArgb ?? this.borderGradientStartArgb,
    borderGradientEndArgb: borderGradientEndArgb ?? this.borderGradientEndArgb,
    borderGradientStartOpacity:
        borderGradientStartOpacity ?? this.borderGradientStartOpacity,
    borderGradientEndOpacity:
        borderGradientEndOpacity ?? this.borderGradientEndOpacity,
    borderGradientDirection:
        borderGradientDirection ?? this.borderGradientDirection,
    borderGradientStartStop:
        borderGradientStartStop ?? this.borderGradientStartStop,
    borderGradientEndStop: borderGradientEndStop ?? this.borderGradientEndStop,
    frostedGlass: frostedGlass ?? this.frostedGlass,
    frostedOpacity: frostedOpacity ?? this.frostedOpacity,
    specularOpacity: specularOpacity ?? this.specularOpacity,
    shadowEnabled: shadowEnabled ?? this.shadowEnabled,
    shadowArgb: shadowArgb ?? this.shadowArgb,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowSpread: shadowSpread ?? this.shadowSpread,
    shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
    shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
    performanceLow: performanceLow ?? this.performanceLow,
    thickness: thickness ?? this.thickness,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
    lightAngle: lightAngle ?? this.lightAngle,
    lightIntensity: lightIntensity ?? this.lightIntensity,
    ambientStrength: ambientStrength ?? this.ambientStrength,
    ambientRim: ambientRim ?? this.ambientRim,
    fresnelStrength: fresnelStrength ?? this.fresnelStrength,
    refractiveIndex: refractiveIndex ?? this.refractiveIndex,
    saturation: saturation ?? this.saturation,
    glowIntensity: glowIntensity ?? this.glowIntensity,
    specularSharpness: specularSharpness ?? this.specularSharpness,
    standardOpacityMultiplier:
        standardOpacityMultiplier ?? this.standardOpacityMultiplier,
    shadowElevation: shadowElevation ?? this.shadowElevation,
    whitenStrength: whitenStrength ?? this.whitenStrength,
    whitenGated: whitenGated ?? this.whitenGated,
    edgeAbsorption: edgeAbsorption ?? this.edgeAbsorption,
    backerArgb: backerArgb ?? this.backerArgb,
    bodyMode: bodyMode ?? this.bodyMode,
    platformViewMode: platformViewMode ?? this.platformViewMode,
    platformViewFallbackArgb:
        platformViewFallbackArgb ?? this.platformViewFallbackArgb,
  );

  Map<String, Object> toJson() => <String, Object>{
    'blurX': blurX,
    'blurY': blurY,
    'boundedBlur': boundedBlur,
    'backdropGrouping': backdropGrouping,
    'tileMode': tileMode.name,
    'blendMode': blendMode.name,
    'tintArgb': tintArgb,
    'tintOpacity': tintOpacity,
    'gradientStartArgb': gradientStartArgb,
    'gradientEndArgb': gradientEndArgb,
    'gradientStartOpacity': gradientStartOpacity,
    'gradientEndOpacity': gradientEndOpacity,
    'gradientDirection': gradientDirection.name,
    'gradientStartStop': gradientStartStop,
    'gradientEndStop': gradientEndStop,
    'borderWidth': borderWidth,
    'borderArgb': borderArgb,
    'borderOpacity': borderOpacity,
    'borderGradientStartArgb': borderGradientStartArgb,
    'borderGradientEndArgb': borderGradientEndArgb,
    'borderGradientStartOpacity': borderGradientStartOpacity,
    'borderGradientEndOpacity': borderGradientEndOpacity,
    'borderGradientDirection': borderGradientDirection.name,
    'borderGradientStartStop': borderGradientStartStop,
    'borderGradientEndStop': borderGradientEndStop,
    'frostedGlass': frostedGlass,
    'frostedOpacity': frostedOpacity,
    'specularOpacity': specularOpacity,
    'shadowEnabled': shadowEnabled,
    'shadowArgb': shadowArgb,
    'shadowOpacity': shadowOpacity,
    'shadowBlur': shadowBlur,
    'shadowSpread': shadowSpread,
    'shadowOffsetX': shadowOffsetX,
    'shadowOffsetY': shadowOffsetY,
    'performanceLow': performanceLow,
    'thickness': thickness,
    'chromaticAberration': chromaticAberration,
    'lightAngle': lightAngle,
    'lightIntensity': lightIntensity,
    'ambientStrength': ambientStrength,
    'ambientRim': ambientRim,
    'fresnelStrength': fresnelStrength,
    'refractiveIndex': refractiveIndex,
    'saturation': saturation,
    'glowIntensity': glowIntensity,
    'specularSharpness': specularSharpness.name,
    'standardOpacityMultiplier': standardOpacityMultiplier,
    'shadowElevation': shadowElevation,
    'whitenStrength': whitenStrength,
    'whitenGated': whitenGated,
    'edgeAbsorption': edgeAbsorption,
    'backerArgb': backerArgb,
    'bodyMode': bodyMode.name,
    'platformViewMode': platformViewMode.name,
    'platformViewFallbackArgb': platformViewFallbackArgb,
  };

  factory BalanceGlassMaterialConfiguration.fromJson(Map<String, Object?> map) {
    T value<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((item) => item.name == name).firstOrNull ?? fallback;
    double number(String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    final defaults = const BalanceGlassMaterialConfiguration();
    return defaults.copyWith(
      blurX: number('blurX', defaults.blurX),
      blurY: number('blurY', defaults.blurY),
      boundedBlur: map['boundedBlur'] as bool? ?? defaults.boundedBlur,
      backdropGrouping:
          map['backdropGrouping'] as bool? ?? defaults.backdropGrouping,
      tileMode: value(
        BalanceGlassTileMode.values,
        map['tileMode'] as String?,
        defaults.tileMode,
      ),
      blendMode: value(
        BalanceGlassBlendMode.values,
        map['blendMode'] as String?,
        defaults.blendMode,
      ),
      tintArgb: map['tintArgb'] as int? ?? defaults.tintArgb,
      tintOpacity: number('tintOpacity', defaults.tintOpacity),
      gradientStartArgb:
          map['gradientStartArgb'] as int? ?? defaults.gradientStartArgb,
      gradientEndArgb:
          map['gradientEndArgb'] as int? ?? defaults.gradientEndArgb,
      gradientStartOpacity: number(
        'gradientStartOpacity',
        defaults.gradientStartOpacity,
      ),
      gradientEndOpacity: number(
        'gradientEndOpacity',
        defaults.gradientEndOpacity,
      ),
      gradientDirection: value(
        BalanceGlassDirection.values,
        map['gradientDirection'] as String?,
        defaults.gradientDirection,
      ),
      gradientStartStop: number(
        'gradientStartStop',
        defaults.gradientStartStop,
      ),
      gradientEndStop: number('gradientEndStop', defaults.gradientEndStop),
      borderWidth: number('borderWidth', defaults.borderWidth),
      borderArgb: map['borderArgb'] as int? ?? defaults.borderArgb,
      borderOpacity: number('borderOpacity', defaults.borderOpacity),
      borderGradientStartArgb:
          map['borderGradientStartArgb'] as int? ??
          defaults.borderGradientStartArgb,
      borderGradientEndArgb:
          map['borderGradientEndArgb'] as int? ??
          defaults.borderGradientEndArgb,
      borderGradientStartOpacity: number(
        'borderGradientStartOpacity',
        defaults.borderGradientStartOpacity,
      ),
      borderGradientEndOpacity: number(
        'borderGradientEndOpacity',
        defaults.borderGradientEndOpacity,
      ),
      borderGradientDirection: value(
        BalanceGlassDirection.values,
        map['borderGradientDirection'] as String?,
        defaults.borderGradientDirection,
      ),
      borderGradientStartStop: number(
        'borderGradientStartStop',
        defaults.borderGradientStartStop,
      ),
      borderGradientEndStop: number(
        'borderGradientEndStop',
        defaults.borderGradientEndStop,
      ),
      frostedGlass: map['frostedGlass'] as bool? ?? defaults.frostedGlass,
      frostedOpacity: number('frostedOpacity', defaults.frostedOpacity),
      specularOpacity: number('specularOpacity', defaults.specularOpacity),
      shadowEnabled: map['shadowEnabled'] as bool? ?? defaults.shadowEnabled,
      shadowArgb: map['shadowArgb'] as int? ?? defaults.shadowArgb,
      shadowOpacity: number('shadowOpacity', defaults.shadowOpacity),
      shadowBlur: number('shadowBlur', defaults.shadowBlur),
      shadowSpread: number('shadowSpread', defaults.shadowSpread),
      shadowOffsetX: number('shadowOffsetX', defaults.shadowOffsetX),
      shadowOffsetY: number('shadowOffsetY', defaults.shadowOffsetY),
      performanceLow: map['performanceLow'] as bool? ?? defaults.performanceLow,
      thickness: number('thickness', defaults.thickness),
      chromaticAberration: number(
        'chromaticAberration',
        defaults.chromaticAberration,
      ),
      lightAngle: number('lightAngle', defaults.lightAngle),
      lightIntensity: number('lightIntensity', defaults.lightIntensity),
      ambientStrength: number('ambientStrength', defaults.ambientStrength),
      ambientRim: number('ambientRim', defaults.ambientRim),
      fresnelStrength: number('fresnelStrength', defaults.fresnelStrength),
      refractiveIndex: number('refractiveIndex', defaults.refractiveIndex),
      saturation: number('saturation', defaults.saturation),
      glowIntensity: number('glowIntensity', defaults.glowIntensity),
      specularSharpness: value(
        BalanceGlassSpecularSharpness.values,
        map['specularSharpness'] as String?,
        defaults.specularSharpness,
      ),
      standardOpacityMultiplier: number(
        'standardOpacityMultiplier',
        defaults.standardOpacityMultiplier,
      ),
      shadowElevation: number('shadowElevation', defaults.shadowElevation),
      whitenStrength: number('whitenStrength', defaults.whitenStrength),
      whitenGated: map['whitenGated'] as bool? ?? defaults.whitenGated,
      edgeAbsorption: number('edgeAbsorption', defaults.edgeAbsorption),
      backerArgb: map['backerArgb'] as int? ?? defaults.backerArgb,
      bodyMode: value(
        BalanceGlassBodyMode.values,
        map['bodyMode'] as String?,
        defaults.bodyMode,
      ),
      platformViewMode: value(
        BalanceGlassPlatformViewMode.values,
        map['platformViewMode'] as String?,
        defaults.platformViewMode,
      ),
      platformViewFallbackArgb:
          map['platformViewFallbackArgb'] as int? ??
          defaults.platformViewFallbackArgb,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BalanceGlassMaterialConfiguration &&
      mapEquals(other.toJson(), toJson());

  @override
  int get hashCode => Object.hashAll(
    toJson().entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

@immutable
final class BalanceHeaderGlassConfiguration {
  const BalanceHeaderGlassConfiguration({
    this.renderer = BalanceHeaderGlassRenderer.baseline,
    this.verticalPosition = .5,
    this.incomeFillIntensity = .5,
    this.independentIncomeFillSettings = false,
    this.quality = BalanceGlassQuality.standard,
    this.materials =
        const <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
          BalanceHeaderGlassRenderer.baseline:
              BalanceGlassMaterialConfiguration(
                blurX: 0,
                blurY: 0,
                tintOpacity: .28,
                borderOpacity: .2,
              ),
          BalanceHeaderGlassRenderer.flutterNative:
              BalanceGlassMaterialConfiguration(),
          BalanceHeaderGlassRenderer.glassKit:
              BalanceGlassMaterialConfiguration(
                blurX: 14,
                blurY: 14,
                frostedGlass: true,
              ),
          BalanceHeaderGlassRenderer.glassmorphism:
              BalanceGlassMaterialConfiguration(blurX: 14, blurY: 14),
          BalanceHeaderGlassRenderer.flutterGlassUiKit:
              BalanceGlassMaterialConfiguration(blurX: 14, blurY: 14),
          BalanceHeaderGlassRenderer.liquidGlassWidgets:
              BalanceGlassMaterialConfiguration(
                blurX: 5,
                blurY: 5,
                thickness: 24,
              ),
        },
    this.fillMaterials =
        const <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
          BalanceHeaderGlassRenderer.baseline:
              BalanceGlassMaterialConfiguration(
                blurX: 0,
                blurY: 0,
                tintOpacity: .44,
                borderOpacity: .34,
              ),
          BalanceHeaderGlassRenderer.flutterNative:
              BalanceGlassMaterialConfiguration(tintOpacity: .24),
          BalanceHeaderGlassRenderer.glassKit:
              BalanceGlassMaterialConfiguration(
                blurX: 16,
                blurY: 16,
                frostedGlass: true,
                frostedOpacity: .12,
              ),
          BalanceHeaderGlassRenderer.glassmorphism:
              BalanceGlassMaterialConfiguration(
                blurX: 16,
                blurY: 16,
                tintOpacity: .22,
              ),
          BalanceHeaderGlassRenderer.flutterGlassUiKit:
              BalanceGlassMaterialConfiguration(
                blurX: 16,
                blurY: 16,
                tintOpacity: .22,
              ),
          BalanceHeaderGlassRenderer.liquidGlassWidgets:
              BalanceGlassMaterialConfiguration(
                blurX: 6,
                blurY: 6,
                thickness: 28,
              ),
        },
  });

  final BalanceHeaderGlassRenderer renderer;
  final double verticalPosition;
  final double incomeFillIntensity;
  final bool independentIncomeFillSettings;
  final BalanceGlassQuality quality;
  final Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>
  materials;
  final Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>
  fillMaterials;

  BalanceGlassMaterialConfiguration materialFor({required bool incomeFill}) {
    final source = incomeFill && independentIncomeFillSettings
        ? fillMaterials
        : materials;
    final material =
        source[renderer] ?? const BalanceGlassMaterialConfiguration();
    if (!incomeFill || independentIncomeFillSettings) return material;
    // Simple mode has a single material source; density rises only through
    // this common factor and remains renderer-local at paint time.
    return material.copyWith(
      tintOpacity: (material.tintOpacity + incomeFillIntensity * .26)
          .clamp(0, 1)
          .toDouble(),
      frostedOpacity: (material.frostedOpacity + incomeFillIntensity * .12)
          .clamp(0, 1)
          .toDouble(),
      specularOpacity: (material.specularOpacity + incomeFillIntensity * .18)
          .clamp(0, 1)
          .toDouble(),
    );
  }

  BalanceHeaderGlassConfiguration copyWith({
    BalanceHeaderGlassRenderer? renderer,
    double? verticalPosition,
    double? incomeFillIntensity,
    bool? independentIncomeFillSettings,
    BalanceGlassQuality? quality,
    Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>?
    materials,
    Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>?
    fillMaterials,
  }) => BalanceHeaderGlassConfiguration(
    renderer: renderer ?? this.renderer,
    verticalPosition: (verticalPosition ?? this.verticalPosition)
        .clamp(0, 1)
        .toDouble(),
    incomeFillIntensity: (incomeFillIntensity ?? this.incomeFillIntensity)
        .clamp(0, 1)
        .toDouble(),
    independentIncomeFillSettings:
        independentIncomeFillSettings ?? this.independentIncomeFillSettings,
    quality: quality ?? this.quality,
    materials: materials ?? this.materials,
    fillMaterials: fillMaterials ?? this.fillMaterials,
  );

  BalanceHeaderGlassConfiguration updateMaterial({
    required bool incomeFill,
    required BalanceGlassMaterialConfiguration material,
  }) {
    final updated =
        <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
          ...(incomeFill ? fillMaterials : materials),
          renderer: material,
        };
    return incomeFill
        ? copyWith(fillMaterials: updated)
        : copyWith(materials: updated);
  }

  BalanceHeaderGlassConfiguration resetSelectedRenderer() {
    const defaults = BalanceHeaderGlassConfiguration();
    return copyWith(
      materials:
          <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
            ...materials,
            renderer: defaults.materials[renderer]!,
          },
      fillMaterials:
          <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
            ...fillMaterials,
            renderer: defaults.fillMaterials[renderer]!,
          },
    );
  }

  String encode() => jsonEncode(<String, Object>{
    'renderer': renderer.name,
    'verticalPosition': verticalPosition,
    'incomeFillIntensity': incomeFillIntensity,
    'independentIncomeFillSettings': independentIncomeFillSettings,
    'quality': quality.name,
    'materials': materials.map(
      (renderer, material) => MapEntry(renderer.name, material.toJson()),
    ),
    'fillMaterials': fillMaterials.map(
      (renderer, material) => MapEntry(renderer.name, material.toJson()),
    ),
  });

  factory BalanceHeaderGlassConfiguration.decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return const BalanceHeaderGlassConfiguration();
    }
    try {
      final root = jsonDecode(encoded);
      if (root is! Map<Object?, Object?>) {
        return const BalanceHeaderGlassConfiguration();
      }
      final map = root.cast<String, Object?>();
      T enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
          values.where((item) => item.name == name).firstOrNull ?? fallback;
      Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>
      decodeMaterials(
        String key,
        Map<BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>
        fallback,
      ) {
        final raw = map[key];
        if (raw is! Map<Object?, Object?>) return fallback;
        return <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
          for (final renderer in BalanceHeaderGlassRenderer.values)
            renderer: raw[renderer.name] is Map<Object?, Object?>
                ? BalanceGlassMaterialConfiguration.fromJson(
                    (raw[renderer.name] as Map<Object?, Object?>)
                        .cast<String, Object?>(),
                  )
                : fallback[renderer]!,
        };
      }

      const defaults = BalanceHeaderGlassConfiguration();
      return BalanceHeaderGlassConfiguration(
        renderer: enumValue(
          BalanceHeaderGlassRenderer.values,
          map['renderer'] as String?,
          defaults.renderer,
        ),
        verticalPosition:
            ((map['verticalPosition'] as num?)?.toDouble() ??
                    defaults.verticalPosition)
                .clamp(0, 1)
                .toDouble(),
        incomeFillIntensity:
            ((map['incomeFillIntensity'] as num?)?.toDouble() ??
                    defaults.incomeFillIntensity)
                .clamp(0, 1)
                .toDouble(),
        independentIncomeFillSettings:
            map['independentIncomeFillSettings'] as bool? ??
            defaults.independentIncomeFillSettings,
        quality: enumValue(
          BalanceGlassQuality.values,
          map['quality'] as String?,
          defaults.quality,
        ),
        materials: decodeMaterials('materials', defaults.materials),
        fillMaterials: decodeMaterials('fillMaterials', defaults.fillMaterials),
      );
    } catch (_) {
      return const BalanceHeaderGlassConfiguration();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BalanceHeaderGlassConfiguration &&
      other.renderer == renderer &&
      other.verticalPosition == verticalPosition &&
      other.incomeFillIntensity == incomeFillIntensity &&
      other.independentIncomeFillSettings == independentIncomeFillSettings &&
      other.quality == quality &&
      mapEquals(other.materials, materials) &&
      mapEquals(other.fillMaterials, fillMaterials);

  @override
  int get hashCode => Object.hash(
    renderer,
    verticalPosition,
    incomeFillIntensity,
    independentIncomeFillSettings,
    quality,
    Object.hashAll(
      materials.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAll(
      fillMaterials.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
