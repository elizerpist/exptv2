import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Source/app-added tuning metadata for the shared Header touch wave.
///
/// `interactionOpacity` is the single real Color Lab control. The remaining
/// controls intentionally expose visually important source constants without
/// changing their audited defaults.
@immutable
final class DashboardHeaderTapWaveControl {
  const DashboardHeaderTapWaveControl({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
    required this.unit,
    required this.isSourceControl,
  });

  final String id;
  final String label;
  final double min;
  final double max;
  final double step;
  final double defaultValue;
  final String unit;
  final bool isSourceControl;

  double normalize(double candidate) {
    final bounded = candidate.isFinite
        ? candidate.clamp(min, max).toDouble()
        : defaultValue;
    final snapped = min + ((bounded - min) / step).round() * step;
    final decimal = _decimalPlaces(step);
    return decimal == 0
        ? snapped.roundToDouble()
        : double.parse(snapped.toStringAsFixed(decimal));
  }

  static int _decimalPlaces(double value) {
    final text = value.toString();
    final dot = text.indexOf('.');
    return dot == -1 ? 0 : text.length - dot - 1;
  }
}

abstract final class DashboardHeaderTapWaveCatalog {
  static const List<DashboardHeaderTapWaveControl> controls =
      <DashboardHeaderTapWaveControl>[
        DashboardHeaderTapWaveControl(
          id: 'interactionOpacity',
          label: 'Interakció opacity',
          min: 0,
          max: 100,
          step: 1,
          defaultValue: 100,
          unit: '%',
          isSourceControl: true,
        ),
        DashboardHeaderTapWaveControl(
          id: 'releaseDurationMs',
          label: 'Elengedési idő',
          min: 400,
          max: 3000,
          step: 20,
          defaultValue: 1640,
          unit: 'ms',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: 'rippleRadiusTravel',
          label: 'Hullámsugár',
          min: .12,
          max: .80,
          step: .01,
          defaultValue: .42,
          unit: '',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: 'rippleIntensity',
          label: 'Hullámerő',
          min: .25,
          max: 2,
          step: .01,
          defaultValue: 1,
          unit: '×',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: 'trailSize',
          label: 'Nyom mérete',
          min: 24,
          max: 160,
          step: 1,
          defaultValue: 82,
          unit: 'px',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: 'pulseLight',
          label: 'Mezőfény',
          min: 0,
          max: .08,
          step: .001,
          defaultValue: .025,
          unit: '',
          isSourceControl: false,
        ),
      ];

  static DashboardHeaderTapWaveControl controlFor(String id) =>
      controls.firstWhere(
        (control) => control.id == id,
        orElse: () =>
            throw ArgumentError.value(id, 'id', 'Unknown tap wave control'),
      );

  static Map<String, double> get defaultSettings =>
      Map<String, double>.unmodifiable(<String, double>{
        for (final control in controls) control.id: control.defaultValue,
      });
}

@immutable
final class DashboardHeaderTapWaveTuning {
  DashboardHeaderTapWaveTuning({
    required Map<String, double> settings,
    required this.generation,
  }) : settings = Map<String, double>.unmodifiable(settings);

  factory DashboardHeaderTapWaveTuning.defaults() =>
      DashboardHeaderTapWaveTuning(
        settings: DashboardHeaderTapWaveCatalog.defaultSettings,
        generation: 0,
      );

  final Map<String, double> settings;
  final int generation;

  double valueFor(String controlId) =>
      settings[controlId] ??
      DashboardHeaderTapWaveCatalog.controlFor(controlId).defaultValue;

  DashboardHeaderTapWaveTuning copyWithValue(String controlId, double value) {
    final control = DashboardHeaderTapWaveCatalog.controlFor(controlId);
    final normalized = control.normalize(value);
    return DashboardHeaderTapWaveTuning(
      settings: <String, double>{...settings, controlId: normalized},
      generation: generation + 1,
    );
  }
}

@immutable
final class DashboardHeaderTapWaveOverlay {
  const DashboardHeaderTapWaveOverlay({
    required this.origin,
    required this.opacity,
    required this.scale,
    required this.blur,
    required this.colors,
    required this.stops,
  });

  final Offset origin;
  final double opacity;
  final double scale;
  final double blur;
  final List<Color> colors;
  final List<double> stops;

  static const List<Color> sourceColors = <Color>[
    Color(0xfaffa7e2),
    Color(0xdbff8bda),
    Color(0xc28b3eff),
    Color(0x75ffffff),
    Color(0x00ffffff),
  ];
  static const List<double> sourceStops = <double>[0, .05, .11, .19, .25];
}

@immutable
final class DashboardHeaderTapWaveFieldSample {
  const DashboardHeaderTapWaveFieldSample({
    required this.coordinate,
    required this.pulseLight,
  });

  final Offset coordinate;
  final double pulseLight;
}

/// Reused by the dense Header field loop while a touch ripple is active.
/// Keeping this mutable scratch separate from the immutable public projection
/// avoids two short-lived objects for every mesh sample on the UI isolate.
final class DashboardHeaderTapWaveFieldScratch {
  double x = 0;
  double y = 0;
  double pulseLight = 0;
}

@immutable
final class DashboardHeaderTapWaveRipple {
  const DashboardHeaderTapWaveRipple({
    required this.origin,
    required this.startedAt,
  });

  final Offset origin;
  final Duration startedAt;
}

@immutable
final class DashboardHeaderTapWaveTrail {
  const DashboardHeaderTapWaveTrail({
    required this.origin,
    required this.startedAt,
  });

  final Offset origin;
  final Duration startedAt;
}

/// Source CSS keyframe projection for one pointer-trail particle.  It lives
/// with the state rather than the painter so deterministic contract tests and
/// rendering share precisely the same 0% → 58% → 100% curve.
@immutable
final class DashboardHeaderTapWaveTrailSample {
  const DashboardHeaderTapWaveTrailSample({
    required this.opacity,
    required this.scale,
    required this.blur,
    required this.saturation,
  });

  final double opacity;
  final double scale;
  final double blur;
  final double saturation;
}

/// Bounded one-shot source state advanced by the existing shared Header clock.
/// It intentionally owns neither a [Ticker] nor any Dashboard semantic state.
final class DashboardHeaderTapWaveState {
  static const Duration _trailLifetime = Duration(milliseconds: 1350);
  static const Duration _rippleFadeDuration = Duration(milliseconds: 1560);
  static const Duration _releaseCleanup = Duration(milliseconds: 1740);
  static const Duration _rippleMinimumGap = Duration(milliseconds: 58);
  static const Duration _trailMinimumGap = Duration(milliseconds: 24);
  static const double _trailMinimumDistance = .055;
  static const int _maxRipples = 10;
  static const int _maxTrails = 26;

  final List<DashboardHeaderTapWaveRipple> _ripples =
      <DashboardHeaderTapWaveRipple>[];
  final List<DashboardHeaderTapWaveTrail> _trails =
      <DashboardHeaderTapWaveTrail>[];
  DashboardHeaderTapWaveTuning _tuning =
      DashboardHeaderTapWaveTuning.defaults();
  Offset _origin = const Offset(.5, .5);
  bool _pointerActive = false;
  bool _moved = false;
  Duration? _releaseStartedAt;
  Duration? _lastTrailAt;
  Offset? _lastTrailOrigin;
  int _waveGeneration = 0;

  DashboardHeaderTapWaveTuning get tuning => _tuning;
  Iterable<DashboardHeaderTapWaveRipple> get ripples => _ripples;
  Iterable<DashboardHeaderTapWaveTrail> get trails => _trails;
  int get rippleCount => _ripples.length;
  int get trailCount => _trails.length;
  int get waveGeneration => _waveGeneration;
  bool get hasActiveFieldRipples => _ripples.isNotEmpty;

  bool get requiresFrames =>
      _pointerActive ||
      _releaseStartedAt != null ||
      _ripples.isNotEmpty ||
      _trails.isNotEmpty;

  void configure(DashboardHeaderTapWaveTuning value) => _tuning = value;

  void pointerDown({required Offset origin, required Duration timestamp}) {
    _origin = _clampPoint(origin);
    _pointerActive = true;
    _moved = false;
    _releaseStartedAt = null;
    _spawnTrail(_origin, timestamp, force: true);
    _spawnRipple(_origin, timestamp);
  }

  void pointerMove({required Offset origin, required Duration timestamp}) {
    if (!_pointerActive) return;
    _origin = _clampPoint(origin);
    _moved = true;
    _spawnTrail(_origin, timestamp);
    _spawnRipple(_origin, timestamp);
  }

  void pointerUp({required Duration timestamp}) {
    if (!_pointerActive) return;
    _pointerActive = false;
    _releaseStartedAt = timestamp;
  }

  void advance(Duration timestamp) {
    _ripples.removeWhere(
      (ripple) => timestamp - ripple.startedAt >= _rippleLifetime,
    );
    _trails.removeWhere(
      (trail) => timestamp - trail.startedAt >= _trailLifetime,
    );
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt != null &&
        timestamp - releaseStartedAt >= _releaseCleanup) {
      _releaseStartedAt = null;
    }
  }

  DashboardHeaderTapWaveOverlay? overlayAt(Duration timestamp) {
    if (_pointerActive) {
      return _overlay(
        opacity: _moved ? .9 : .96,
        scale: _moved ? 1 : .8,
        blur: _moved ? 10 : 7,
      );
    }
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt == null) return null;
    final age = timestamp - releaseStartedAt;
    if (age >= _releaseCleanup) return null;
    final initialOpacity = _moved ? .9 : .96;
    final initialScale = _moved ? 1.0 : .8;
    final initialBlur = _moved ? 10.0 : 7.0;
    final fade = _curveFraction(
      age,
      const Duration(milliseconds: 1560),
      Curves.ease,
    );
    final transform = _curveFraction(
      age,
      Duration(milliseconds: _tuning.valueFor('releaseDurationMs').round()),
      const Cubic(.19, 1, .22, 1),
    );
    return _overlay(
      opacity: initialOpacity * (1 - fade),
      scale: _lerp(initialScale, 1.42, transform),
      blur: _lerp(initialBlur, 20, fade),
    );
  }

  DashboardHeaderTapWaveFieldSample fieldSampleAt({
    required Offset point,
    required Duration timestamp,
  }) {
    final scratch = DashboardHeaderTapWaveFieldScratch();
    writeFieldSample(
      x: point.dx,
      y: point.dy,
      timestamp: timestamp,
      into: scratch,
    );
    return DashboardHeaderTapWaveFieldSample(
      coordinate: Offset(scratch.x, scratch.y),
      pulseLight: scratch.pulseLight,
    );
  }

  DashboardHeaderTapWaveTrailSample? trailSampleAt({
    required DashboardHeaderTapWaveTrail trail,
    required Duration timestamp,
  }) {
    final age = timestamp - trail.startedAt;
    if (age < Duration.zero || age >= _trailLifetime) return null;
    final fraction = age.inMicroseconds / _trailLifetime.inMicroseconds;
    const curve = Cubic(.16, 1, .3, 1);
    if (fraction <= .58) {
      final amount = curve.transform(fraction / .58);
      return DashboardHeaderTapWaveTrailSample(
        opacity: _lerp(.96, .48, amount),
        scale: _lerp(1, .58, amount),
        blur: _lerp(8, 14, amount),
        saturation: _lerp(2, 1.65, amount),
      );
    }
    final amount = curve.transform((fraction - .58) / .42);
    return DashboardHeaderTapWaveTrailSample(
      opacity: _lerp(.48, 0, amount),
      scale: _lerp(.58, .18, amount),
      blur: _lerp(14, 21, amount),
      saturation: _lerp(1.65, 1.2, amount),
    );
  }

  void writeFieldSample({
    required double x,
    required double y,
    required Duration timestamp,
    required DashboardHeaderTapWaveFieldScratch into,
  }) {
    var resolvedX = x.clamp(0.0, 1.0).toDouble();
    var resolvedY = y.clamp(0.0, 1.0).toDouble();
    final lifetimeMicros = _rippleLifetime.inMicroseconds;
    final fadeMicros = _rippleFadeDuration.inMicroseconds;
    final radiusTravel = _tuning.valueFor('rippleRadiusTravel');
    final intensity = _tuning.valueFor('rippleIntensity');
    for (final ripple in _ripples) {
      final elapsedMicros = (timestamp - ripple.startedAt).inMicroseconds;
      if (elapsedMicros < 0 || elapsedMicros >= lifetimeMicros) continue;
      final age = elapsedMicros / lifetimeMicros;
      final dx = resolvedX - ripple.origin.dx;
      final dy = resolvedY - ripple.origin.dy;
      final distance = math.max(.001, math.sqrt(dx * dx + dy * dy));
      final ring =
          math.sin(distance * 10.5 - age * math.pi * 2.2) *
          math.exp(-(distance - age * radiusTravel).abs() * 7.2) *
          (1 - age) *
          .32 *
          intensity;
      resolvedX += dx / distance * ring * .018;
      resolvedY += dy / distance * ring * .014;
    }
    final newest = _ripples.isEmpty ? null : _ripples.last;
    final pulse = newest == null
        ? 0.0
        : math
              .max(
                0,
                1 - (timestamp - newest.startedAt).inMicroseconds / fadeMicros,
              )
              .toDouble();
    into
      ..x = resolvedX.clamp(0.0, 1.0).toDouble()
      ..y = resolvedY.clamp(0.0, 1.0).toDouble()
      ..pulseLight = pulse;
  }

  DashboardHeaderTapWaveOverlay _overlay({
    required double opacity,
    required double scale,
    required double blur,
  }) => DashboardHeaderTapWaveOverlay(
    origin: _origin,
    opacity: opacity,
    scale: scale,
    blur: blur,
    colors: DashboardHeaderTapWaveOverlay.sourceColors,
    stops: DashboardHeaderTapWaveOverlay.sourceStops,
  );

  void _spawnRipple(Offset origin, Duration timestamp) {
    final last = _ripples.isEmpty ? null : _ripples.last;
    if (last != null && timestamp - last.startedAt < _rippleMinimumGap) return;
    _ripples.add(
      DashboardHeaderTapWaveRipple(origin: origin, startedAt: timestamp),
    );
    _waveGeneration += 1;
    if (_ripples.length > _maxRipples) _ripples.removeAt(0);
  }

  void _spawnTrail(Offset origin, Duration timestamp, {bool force = false}) {
    final lastAt = _lastTrailAt;
    final lastOrigin = _lastTrailOrigin;
    if (!force && lastAt != null && lastOrigin != null) {
      final dx = origin.dx - lastOrigin.dx;
      final dy = origin.dy - lastOrigin.dy;
      if (timestamp - lastAt < _trailMinimumGap &&
          math.sqrt(dx * dx + dy * dy) < _trailMinimumDistance) {
        return;
      }
    }
    _lastTrailAt = timestamp;
    _lastTrailOrigin = origin;
    _trails.add(
      DashboardHeaderTapWaveTrail(origin: origin, startedAt: timestamp),
    );
    if (_trails.length > _maxTrails) _trails.removeAt(0);
  }

  static Offset _clampPoint(Offset value) => Offset(
    value.dx.clamp(0.0, 1.0).toDouble(),
    value.dy.clamp(0.0, 1.0).toDouble(),
  );

  static double _curveFraction(
    Duration elapsed,
    Duration duration,
    Curve curve,
  ) => curve.transform(
    (elapsed.inMicroseconds / math.max(1, duration.inMicroseconds))
        .clamp(0.0, 1.0)
        .toDouble(),
  );

  static double _lerp(double from, double to, double amount) =>
      from + (to - from) * amount;

  static Duration get _rippleLifetime => Duration(
    microseconds: (_rippleFadeDuration.inMicroseconds * 1.08).round(),
  );
}
