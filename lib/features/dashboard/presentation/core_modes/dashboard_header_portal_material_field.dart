import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'dashboard_header_visual_control.dart';

/// Machine values from `PortalMessageField.modeOrder` in the audited Color
/// Lab.  The two Portal channels share this field model but not their state.
enum DashboardHeaderPortalMaterialEffectId {
  solidA,
  staticMatter,
  wanderingMist,
  livingArchipelago,
  formingClouds,
}

enum DashboardHeaderPortalChannel { innerMotion, backgroundMorph }

@immutable
final class DashboardHeaderPortalMaterialEffectSpec {
  const DashboardHeaderPortalMaterialEffectSpec({
    required this.id,
    required this.sourceId,
    required this.label,
    required this.isAnimated,
    required this.controls,
  });

  final DashboardHeaderPortalMaterialEffectId id;
  final String sourceId;
  final String label;
  final bool isAnimated;
  final List<DashboardHeaderEffectControl> controls;

  DashboardHeaderEffectControl controlFor(String controlId) =>
      controls.firstWhere(
        (control) => control.id == controlId,
        orElse: () => throw ArgumentError.value(
          controlId,
          'controlId',
          'Unknown control',
        ),
      );

  Map<String, double> get defaultSettings =>
      Map<String, double>.unmodifiable(<String, double>{
        for (final control in controls) control.id: control.defaultValue,
      });
}

@immutable
final class DashboardHeaderPortalMaterialRenderProfile {
  const DashboardHeaderPortalMaterialRenderProfile({
    required this.renderScale,
    required this.frameMs,
  });

  final double renderScale;
  final int frameMs;
}

/// Data-only transcription of `color_lab_portal_message_field.js`.
abstract final class DashboardHeaderPortalMaterialCatalog {
  static const DashboardHeaderPortalMaterialEffectId defaultEffect =
      DashboardHeaderPortalMaterialEffectId.wanderingMist;

  static const List<DashboardHeaderEffectControl> _staticMatterControls =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'coverage',
          label: 'B-fedettség',
          min: 0,
          max: 80,
          step: 1,
          defaultValue: 34,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'B-erősség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 72,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'scale',
          label: 'Anyagskála',
          min: 20,
          max: 180,
          step: 1,
          defaultValue: 100,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Peremlágyság',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 76,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'detail',
          label: 'Részletesség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 28,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'seed',
          label: 'Véletlenmag',
          min: 0,
          max: 9999,
          step: 1,
          defaultValue: 137,
        ),
      ];

  static const List<DashboardHeaderEffectControl> _wanderingMistControls =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'coverage',
          label: 'B-fedettség',
          min: 0,
          max: 80,
          step: 1,
          defaultValue: 36,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'B-erősség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 74,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'scale',
          label: 'Ködskála',
          min: 20,
          max: 200,
          step: 1,
          defaultValue: 118,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Peremlágyság',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 82,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'driftSpeed',
          label: 'Sodródási sebesség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 22,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'curl',
          label: 'Curl erősség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 44,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'morphRate',
          label: 'Alakváltozás',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 28,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'detail',
          label: 'Részletesség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 24,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'seed',
          label: 'Véletlenmag',
          min: 0,
          max: 9999,
          step: 1,
          defaultValue: 311,
        ),
      ];

  static const List<DashboardHeaderEffectControl> _archipelagoControls =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'islandCount',
          label: 'Szigetszám',
          min: 2,
          max: 12,
          step: 1,
          defaultValue: 6,
        ),
        DashboardHeaderEffectControl(
          id: 'size',
          label: 'Átlagos méret',
          min: 8,
          max: 80,
          step: 1,
          defaultValue: 34,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'sizeVariance',
          label: 'Méreteltérés',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 42,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'B-erősség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 78,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Peremlágyság',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 66,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'wanderSpeed',
          label: 'Vándorlási sebesség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 30,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'mergeAttraction',
          label: 'Összeolvadási vonzás',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 55,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'morphRate',
          label: 'Alakváltozás',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 36,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'seed',
          label: 'Véletlenmag',
          min: 0,
          max: 9999,
          step: 1,
          defaultValue: 521,
        ),
      ];

  static const List<DashboardHeaderEffectControl> _formingCloudControls =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'density',
          label: 'Aktív felhősűrűség',
          min: 1,
          max: 10,
          step: 1,
          defaultValue: 4,
        ),
        DashboardHeaderEffectControl(
          id: 'lifetime',
          label: 'Élettartam',
          min: 2,
          max: 30,
          step: 1,
          defaultValue: 14,
          unit: 's',
        ),
        DashboardHeaderEffectControl(
          id: 'birthOverlap',
          label: 'Születési átfedés',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 58,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'growth',
          label: 'Növekedés',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 46,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'B-erősség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 76,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'scale',
          label: 'Felhőskála',
          min: 10,
          max: 120,
          step: 1,
          defaultValue: 46,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Peremlágyság',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 78,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'driftSpeed',
          label: 'Sodródási sebesség',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 24,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'pathIrregularity',
          label: 'Útvonal-szabálytalanság',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 52,
          unit: '%',
        ),
        DashboardHeaderEffectControl(
          id: 'seed',
          label: 'Véletlenmag',
          min: 0,
          max: 9999,
          step: 1,
          defaultValue: 887,
        ),
      ];

  static final List<DashboardHeaderPortalMaterialEffectSpec> effects =
      List<DashboardHeaderPortalMaterialEffectSpec>.unmodifiable(
        const <DashboardHeaderPortalMaterialEffectSpec>[
          DashboardHeaderPortalMaterialEffectSpec(
            id: DashboardHeaderPortalMaterialEffectId.solidA,
            sourceId: 'solid-a',
            label: 'Nincs dinamikus effekt',
            isAnimated: false,
            controls: <DashboardHeaderEffectControl>[],
          ),
          DashboardHeaderPortalMaterialEffectSpec(
            id: DashboardHeaderPortalMaterialEffectId.staticMatter,
            sourceId: 'static-matter',
            label: 'Statikus köd/szigetek',
            isAnimated: false,
            controls: _staticMatterControls,
          ),
          DashboardHeaderPortalMaterialEffectSpec(
            id: DashboardHeaderPortalMaterialEffectId.wanderingMist,
            sourceId: 'wandering-mist',
            label: 'Vándorló köd',
            isAnimated: true,
            controls: _wanderingMistControls,
          ),
          DashboardHeaderPortalMaterialEffectSpec(
            id: DashboardHeaderPortalMaterialEffectId.livingArchipelago,
            sourceId: 'living-archipelago',
            label: 'Élő szigetvilág',
            isAnimated: true,
            controls: _archipelagoControls,
          ),
          DashboardHeaderPortalMaterialEffectSpec(
            id: DashboardHeaderPortalMaterialEffectId.formingClouds,
            sourceId: 'forming-clouds',
            label: 'Keletkező energiafelhők',
            isAnimated: true,
            controls: _formingCloudControls,
          ),
        ],
      );

  static DashboardHeaderPortalMaterialEffectSpec effectFor(
    DashboardHeaderPortalMaterialEffectId effect,
  ) => effects.firstWhere((spec) => spec.id == effect);

  static Map<String, double> defaultSettings(
    DashboardHeaderPortalMaterialEffectId effect,
  ) => effectFor(effect).defaultSettings;

  static Map<String, double> normalizeSettings(
    DashboardHeaderPortalMaterialEffectId effect,
    Map<String, double>? input,
  ) => Map<String, double>.unmodifiable(<String, double>{
    for (final control in effectFor(effect).controls)
      control.id: control.normalize(input?[control.id] ?? control.defaultValue),
  });

  static DashboardHeaderPortalMaterialRenderProfile renderProfile(
    DashboardHeaderPortalMaterialEffectId effect,
  ) => effect == DashboardHeaderPortalMaterialEffectId.formingClouds
      ? const DashboardHeaderPortalMaterialRenderProfile(
          renderScale: .48,
          frameMs: 52,
        )
      : const DashboardHeaderPortalMaterialRenderProfile(
          renderScale: .55,
          frameMs: 48,
        );
}

/// Independent state for one source selector. The mutable phase bank remains
/// private to the Header controller through this object, which avoids a map
/// allocation for every animation frame while keeping tuner writes immutable.
final class DashboardHeaderPortalChannelState {
  DashboardHeaderPortalChannelState._({
    required this.enabled,
    required this.effect,
    required Map<DashboardHeaderPortalMaterialEffectId, Map<String, double>>
    settingsByEffect,
    required Map<DashboardHeaderPortalMaterialEffectId, double> phaseByEffect,
    required this.rotationEnabled,
    required this.rotationSpeed,
    required this.paletteCenterPercent,
    required this.paletteWindowPercent,
  }) : _settingsByEffect =
           Map<
             DashboardHeaderPortalMaterialEffectId,
             Map<String, double>
           >.unmodifiable(
             <DashboardHeaderPortalMaterialEffectId, Map<String, double>>{
               for (final entry in settingsByEffect.entries)
                 entry.key: Map<String, double>.unmodifiable(entry.value),
             },
           ),
       _phaseByEffect = phaseByEffect;

  factory DashboardHeaderPortalChannelState.innerMotionDefaults() =>
      DashboardHeaderPortalChannelState._(
        enabled: true,
        effect: DashboardHeaderPortalMaterialCatalog.defaultEffect,
        settingsByEffect: _defaultSettingsByEffect(),
        phaseByEffect: _defaultPhaseByEffect(),
        rotationEnabled: false,
        rotationSpeed: 28,
        paletteCenterPercent: 50,
        paletteWindowPercent: 68,
      );

  factory DashboardHeaderPortalChannelState.backgroundMorphDefaults() =>
      DashboardHeaderPortalChannelState._(
        enabled: true,
        effect: DashboardHeaderPortalMaterialCatalog.defaultEffect,
        settingsByEffect: _defaultSettingsByEffect(),
        phaseByEffect: _defaultPhaseByEffect(),
        rotationEnabled: false,
        rotationSpeed: 28,
        paletteCenterPercent: 50,
        paletteWindowPercent: 68,
      );

  final bool enabled;
  final DashboardHeaderPortalMaterialEffectId effect;
  final Map<DashboardHeaderPortalMaterialEffectId, Map<String, double>>
  _settingsByEffect;
  final Map<DashboardHeaderPortalMaterialEffectId, double> _phaseByEffect;
  final bool rotationEnabled;
  final double rotationSpeed;
  final double paletteCenterPercent;
  final double paletteWindowPercent;

  Map<String, double> settingsFor(
    DashboardHeaderPortalMaterialEffectId value,
  ) => _settingsByEffect[value] ?? const <String, double>{};

  double phaseFor(DashboardHeaderPortalMaterialEffectId value) =>
      _phaseByEffect[value] ?? 0;

  bool get requiresFrames =>
      enabled &&
      DashboardHeaderPortalMaterialCatalog.effectFor(effect).isAnimated;

  DashboardHeaderPortalChannelState copyWith({
    bool? enabled,
    DashboardHeaderPortalMaterialEffectId? effect,
    Map<DashboardHeaderPortalMaterialEffectId, Map<String, double>>?
    settingsByEffect,
    bool? rotationEnabled,
    double? rotationSpeed,
    double? paletteCenterPercent,
    double? paletteWindowPercent,
  }) => DashboardHeaderPortalChannelState._(
    enabled: enabled ?? this.enabled,
    effect: effect ?? this.effect,
    settingsByEffect: settingsByEffect ?? _settingsByEffect,
    phaseByEffect: _phaseByEffect,
    rotationEnabled: rotationEnabled ?? this.rotationEnabled,
    rotationSpeed: (rotationSpeed ?? this.rotationSpeed).clamp(0.0, 100.0),
    paletteCenterPercent: (paletteCenterPercent ?? this.paletteCenterPercent)
        .clamp(0.0, 100.0),
    paletteWindowPercent: (paletteWindowPercent ?? this.paletteWindowPercent)
        .clamp(10.0, 100.0),
  );

  void advance(Duration delta) {
    if (!requiresFrames) return;
    final settings = settingsFor(effect);
    _phaseByEffect[effect] = DashboardHeaderPortalMaterialField.advancePhase(
      effect: effect,
      phase: phaseFor(effect),
      elapsedSeconds: delta.inMicroseconds / Duration.microsecondsPerSecond,
      settings: settings,
    );
  }

  static Map<DashboardHeaderPortalMaterialEffectId, Map<String, double>>
  _defaultSettingsByEffect() =>
      <DashboardHeaderPortalMaterialEffectId, Map<String, double>>{
        for (final spec in DashboardHeaderPortalMaterialCatalog.effects)
          spec.id: spec.defaultSettings,
      };

  static Map<DashboardHeaderPortalMaterialEffectId, double>
  _defaultPhaseByEffect() => <DashboardHeaderPortalMaterialEffectId, double>{
    for (final spec in DashboardHeaderPortalMaterialCatalog.effects)
      if (spec.isAnimated) spec.id: 0,
  };
}

/// Exact scalar source math from `PortalMessageField`. The painter samples it
/// at a reduced grid resolution and never calls persistence or palette owners.
abstract final class DashboardHeaderPortalMaterialField {
  static double sample({
    required DashboardHeaderPortalMaterialEffectId effect,
    required double x,
    required double y,
    required double phase,
    required Map<String, double> settings,
  }) {
    final nx = _clamp01(x);
    final ny = _clamp01(y);
    if (effect == DashboardHeaderPortalMaterialEffectId.solidA) return 0;
    return switch (effect) {
      DashboardHeaderPortalMaterialEffectId.staticMatter => _sampleStaticMatter(
        nx,
        ny,
        settings,
      ),
      DashboardHeaderPortalMaterialEffectId.wanderingMist =>
        _sampleWanderingMist(nx, ny, phase, settings),
      DashboardHeaderPortalMaterialEffectId.livingArchipelago =>
        _sampleArchipelago(nx, ny, phase, settings),
      DashboardHeaderPortalMaterialEffectId.formingClouds =>
        _sampleFormingClouds(nx, ny, phase, settings),
      DashboardHeaderPortalMaterialEffectId.solidA => 0,
    };
  }

  static double advancePhase({
    required DashboardHeaderPortalMaterialEffectId effect,
    required double phase,
    required double elapsedSeconds,
    required Map<String, double> settings,
  }) {
    final spec = DashboardHeaderPortalMaterialCatalog.effectFor(effect);
    if (!spec.isAnimated) return phase;
    final speed =
        effect == DashboardHeaderPortalMaterialEffectId.livingArchipelago
        ? _setting(settings, 'wanderSpeed')
        : _setting(settings, 'driftSpeed');
    return phase + math.max(0, elapsedSeconds) * speed / 24;
  }

  static double _sampleStaticMatter(
    double x,
    double y,
    Map<String, double> settings,
  ) {
    final frequency = 3.8 - ((_setting(settings, 'scale') / 180) * 2.9);
    final coarse = _fbm(
      x * frequency,
      y * frequency,
      _setting(settings, 'seed'),
      3,
    );
    final fine = _fbm(
      x * frequency * 2.7,
      y * frequency * 2.7,
      _setting(settings, 'seed') + 41,
      2,
    );
    final value = _lerp(coarse, fine, _setting(settings, 'detail') / 180);
    return _clamp01(
      _materialThreshold(
            value,
            _setting(settings, 'coverage'),
            _setting(settings, 'softness'),
          ) *
          _setting(settings, 'strength') /
          100,
    );
  }

  static double _sampleWanderingMist(
    double x,
    double y,
    double phase,
    Map<String, double> settings,
  ) {
    final frequency = 4.2 - ((_setting(settings, 'scale') / 200) * 3.35);
    final drift = phase * (.035 + (_setting(settings, 'driftSpeed') / 420));
    final morph = phase * (.025 + (_setting(settings, 'morphRate') / 520));
    final curl = (_setting(settings, 'curl') / 100) * .48;
    final warpX =
        _fbm(
          x * 1.7 + math.cos(drift),
          y * 1.7 + math.sin(morph),
          _setting(settings, 'seed') + 17,
          3,
        ) -
        .5;
    final warpY =
        _fbm(
          x * 1.7 - math.sin(morph),
          y * 1.7 + math.cos(drift),
          _setting(settings, 'seed') + 73,
          3,
        ) -
        .5;
    final px = (x + warpX * curl) * frequency + math.cos(drift * .73);
    final py = (y + warpY * curl) * frequency + math.sin(drift * .61);
    final broad = _fbm(px, py, _setting(settings, 'seed'), 3);
    final fine = _fbm(
      px * 2.6 - morph,
      py * 2.6 + morph,
      _setting(settings, 'seed') + 191,
      2,
    );
    final value = _lerp(broad, fine, _setting(settings, 'detail') / 150);
    return _clamp01(
      _materialThreshold(
            value,
            _setting(settings, 'coverage'),
            _setting(settings, 'softness'),
          ) *
          _setting(settings, 'strength') /
          100,
    );
  }

  static double _sampleArchipelago(
    double x,
    double y,
    double phase,
    Map<String, double> settings,
  ) {
    var sum = 0.0;
    final count = _setting(settings, 'islandCount').round();
    for (var index = 0; index < count; index += 1) {
      final angle = _hash2(index, 1, _setting(settings, 'seed')) * math.pi * 2;
      final rate =
          .08 +
          _setting(settings, 'wanderSpeed') / 560 +
          _hash2(index, 2, _setting(settings, 'seed')) * .09;
      final orbit = .1 + _hash2(index, 3, _setting(settings, 'seed')) * .34;
      final cx = .5 + math.cos(angle + phase * rate) * orbit;
      final cy = .5 + math.sin(angle * 1.31 - phase * rate * .83) * orbit * .72;
      final variance =
          1 +
          (_hash2(index, 4, _setting(settings, 'seed')) - .5) *
              _setting(settings, 'sizeVariance') /
              100;
      final morph =
          1 +
          math.sin(
                phase * (.08 + _setting(settings, 'morphRate') / 600) + angle,
              ) *
              _setting(settings, 'morphRate') /
              310;
      final radius = math.max(
        .025,
        _setting(settings, 'size') / 220 * variance * morph,
      );
      sum += _gaussian(
        x - cx,
        y - cy,
        radius,
        radius * (.72 + _hash2(index, 5, _setting(settings, 'seed')) * .42),
      );
    }
    final merged =
        1 - math.exp(-sum * (.7 + _setting(settings, 'mergeAttraction') / 42));
    final width = .03 + _setting(settings, 'softness') / 260;
    return _clamp01(
      _smoothstep(.2 - width, .2 + width, merged) *
          _setting(settings, 'strength') /
          100,
    );
  }

  static double _sampleFormingClouds(
    double x,
    double y,
    double phase,
    Map<String, double> settings,
  ) {
    var fieldValue = 0.0;
    final count = math.max(2, _setting(settings, 'density').round() * 2);
    for (var index = 0; index < count; index += 1) {
      final offset = _hash2(index, 11, _setting(settings, 'seed'));
      final age = _fract(
        phase / math.max(2, _setting(settings, 'lifetime')) + offset,
      );
      final overlap = .35 + _setting(settings, 'birthOverlap') / 125;
      final life = math
          .pow(
            math.max(0, math.sin(math.pi * age)),
            .65 + (100 - _setting(settings, 'growth')) / 95,
          )
          .toDouble();
      final irregularity = _setting(settings, 'pathIrregularity') / 100;
      final drift = age * (.05 + _setting(settings, 'driftSpeed') / 170);
      final cx = _fract(
        _hash2(index, 12, _setting(settings, 'seed')) +
            drift +
            math.sin((age + offset) * math.pi * 2) * .08 * irregularity,
      );
      final cy = _clamp01(
        _hash2(index, 13, _setting(settings, 'seed')) +
            math.sin(age * 4.7 + offset * 8) * .2 * irregularity,
      );
      final radius = math.max(
        .02,
        _setting(settings, 'scale') / 210 * (.35 + life * overlap),
      );
      fieldValue = math.max(
        fieldValue,
        _gaussian(x - cx, y - cy, radius, radius * .76) * life,
      );
    }
    final width = .02 + _setting(settings, 'softness') / 240;
    return _clamp01(
      _smoothstep(.18 - width, .18 + width, fieldValue) *
          _setting(settings, 'strength') /
          100,
    );
  }

  static double _setting(Map<String, double> settings, String key) =>
      settings[key] ?? 0;

  static double _materialThreshold(
    double value,
    double coverage,
    double softness,
  ) {
    final center = 1 - coverage / 100;
    final width = .015 + softness / 100 * .24;
    return _smoothstep(center - width, center + width, value);
  }

  static double _clamp01(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0;

  static double _lerp(double left, double right, double amount) =>
      left + (right - left) * amount;

  static double _fract(double value) => value - value.floorToDouble();

  static double _smoothstep(double edge0, double edge1, double value) {
    if (edge0 == edge1) return value < edge0 ? 0 : 1;
    final amount = _clamp01((value - edge0) / (edge1 - edge0));
    return amount * amount * (3 - 2 * amount);
  }

  static double _hash2(num x, num y, double seed) =>
      _fract(math.sin(x * 127.1 + y * 311.7 + seed * .0173) * 43758.5453123);

  static double _valueNoise(double x, double y, double seed) {
    final ix = x.floorToDouble();
    final iy = y.floorToDouble();
    final fx = x - ix;
    final fy = y - iy;
    final sx = fx * fx * (3 - 2 * fx);
    final sy = fy * fy * (3 - 2 * fy);
    final top = _lerp(_hash2(ix, iy, seed), _hash2(ix + 1, iy, seed), sx);
    final bottom = _lerp(
      _hash2(ix, iy + 1, seed),
      _hash2(ix + 1, iy + 1, seed),
      sx,
    );
    return _lerp(top, bottom, sy);
  }

  static double _fbm(double x, double y, double seed, int octaves) {
    var frequency = 1.0;
    var amplitude = .5;
    var total = 0.0;
    var weight = 0.0;
    for (var octave = 0; octave < octaves; octave += 1) {
      total +=
          _valueNoise(x * frequency, y * frequency, seed + octave * 97) *
          amplitude;
      weight += amplitude;
      frequency *= 2.03;
      amplitude *= .5;
    }
    return weight == 0 ? 0 : total / weight;
  }

  static double _gaussian(
    double dx,
    double dy,
    double radiusX,
    double radiusY,
  ) {
    final safeX = math.max(.0001, radiusX);
    final safeY = math.max(.0001, radiusY);
    return math.exp(
      -.5 * ((dx / safeX) * (dx / safeX) + (dy / safeY) * (dy / safeY)),
    );
  }
}
