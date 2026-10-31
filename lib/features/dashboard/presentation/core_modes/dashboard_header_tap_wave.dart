import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Source/app-added tuning metadata for the shared Header touch wave.
///
/// The first three controls are the stable user-facing visual profile. The
/// retained source controls below them preserve the older effect-model
/// contracts without appearing in the dashboard tuner.
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
  static const dynamicTrailStrengthId = 'dynamicTrailStrengthPercent';
  static const tapStartSizeId = 'tapStartSizePercent';
  static const tapStrengthId = 'tapStrengthPercent';
  static const tapSpeedId = 'tapSpeedPercent';
  static const dragRippleLifetimeId = 'dragRippleLifetimeSeconds';

  static const List<DashboardHeaderTapWaveControl> controls =
      <DashboardHeaderTapWaveControl>[
        DashboardHeaderTapWaveControl(
          id: dynamicTrailStrengthId,
          label: 'Dinamikus nyomvonal erőssége',
          min: 0,
          max: 300,
          step: 5,
          defaultValue: 225,
          unit: '%',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: tapStartSizeId,
          label: 'Tap-hullám indulómérete',
          min: 25,
          max: 100,
          step: 5,
          defaultValue: 55,
          unit: '%',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: tapStrengthId,
          label: 'Tap-hullám erőssége',
          min: 0,
          max: 100,
          step: 5,
          defaultValue: 75,
          unit: '%',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: tapSpeedId,
          label: 'Tap-hullám sebessége',
          min: 50,
          max: 200,
          step: 5,
          defaultValue: 100,
          unit: '%',
          isSourceControl: false,
        ),
        DashboardHeaderTapWaveControl(
          id: dragRippleLifetimeId,
          label: 'Húzási hullámok életideje',
          min: .40,
          max: 2,
          step: .05,
          defaultValue: 1.20,
          unit: ' s',
          isSourceControl: false,
        ),
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

  static List<DashboardHeaderTapWaveControl> get visualControls => controls
      .where(
        (control) =>
            control.id == dynamicTrailStrengthId ||
            control.id == tapStartSizeId ||
            control.id == tapStrengthId ||
            control.id == tapSpeedId ||
            control.id == dragRippleLifetimeId,
      )
      .toList(growable: false);

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

  /// Keeps the source/audited 100% reference available without overwriting
  /// the persisted personal profile.
  DashboardHeaderTapWaveTuning asCurrentReference() =>
      copyWithValue(DashboardHeaderTapWaveCatalog.dynamicTrailStrengthId, 100)
          .copyWithValue(DashboardHeaderTapWaveCatalog.tapStartSizeId, 100)
          .copyWithValue(DashboardHeaderTapWaveCatalog.tapStrengthId, 100)
          .copyWithValue(DashboardHeaderTapWaveCatalog.tapSpeedId, 100)
          .copyWithValue(
            DashboardHeaderTapWaveCatalog.dragRippleLifetimeId,
            .80,
          );
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
    required this.velocity,
    required this.connectsToPrevious,
  });

  final Offset origin;
  final Duration startedAt;

  /// Smoothed logical-pixel velocity, normalized to the shader's bounded
  /// 0..1 domain. A negative value is reserved by the retained frame for a
  /// deliberate path break; this source value always remains non-negative.
  final double velocity;

  /// A fresh pointer contact, a re-entry after leaving the Header, or a
  /// capacity-trimmed tail must never draw a line to its predecessor.
  final bool connectsToPrevious;

  DashboardHeaderTapWaveTrail withoutPreviousConnection() =>
      DashboardHeaderTapWaveTrail(
        origin: origin,
        startedAt: startedAt,
        velocity: velocity,
        connectsToPrevious: false,
      );
}

/// Immutable diagnostic projection for one water-path sample. The shader
/// joins consecutive samples; it never renders this as a standalone dot.
@immutable
final class DashboardHeaderTapWaveTrailSample {
  const DashboardHeaderTapWaveTrailSample({
    required this.age,
    required this.velocity,
    required this.connectsToPrevious,
  });

  final double age;
  final double velocity;
  final bool connectsToPrevious;
}

/// Mutable bridge from the source-state curves to the retained fragment
/// shader uniform bank. It is deliberately not a public visual state: one
/// instance is reused by the Header paint lane and avoids allocating an
/// overlay/trail projection for every animation frame.
final class DashboardHeaderTapWaveOverlayFrame {
  double x = .5;
  double y = .5;
  double opacity = 0;
  double scale = 1;
  double blur = 0;
  double active = 0;

  void clear() {
    opacity = 0;
    scale = 1;
    blur = 0;
    active = 0;
  }
}

/// Retained live-finger marker. It is intentionally distinct from the
/// release overlay: holding a finger must not create the large pink field.
final class DashboardHeaderTapWaveLivePointFrame {
  double x = .5;
  double y = .5;
  double radius = 7;
  double opacity = 0;
  double active = 0;

  void clear() {
    opacity = 0;
    active = 0;
  }
}

/// Mutable projection for one retained water-path vertex.
///
/// The fragment ABI intentionally keeps the historic vec4 capacity, but its
/// components now are `(x, y, ageSeconds, signedVelocity)`. A negative
/// velocity is a path-break sentinel, which prevents separate contacts or an
/// outside detour from being joined by the shader.
final class DashboardHeaderTapWaveTrailFrame {
  double x = 0;
  double y = 0;
  double age = 1;
  double signedVelocity = -1;

  void clear() {
    x = 0;
    y = 0;
    age = 1;
    signedVelocity = -1;
  }
}

/// Bounded one-shot source state advanced by the existing shared Header clock.
/// It intentionally owns neither a [Ticker] nor any Dashboard semantic state.
final class DashboardHeaderTapWaveState {
  static const Duration _referenceTrailLifetime = Duration(milliseconds: 800);
  static const Duration _rippleFadeDuration = Duration(milliseconds: 1560);
  static const Duration _releaseCleanup = Duration(milliseconds: 1740);
  static const double _dragThresholdLogicalPixels = 5;
  static const double _sampleSpacingLogicalPixels = 12;
  static const Duration _slowDragEmissionInterval = Duration(milliseconds: 210);
  static const double _maximumVelocityLogicalPixelsPerSecond = 1200;
  static const int _maxRipples = 10;
  static const int _maxTrailSegments = 24;
  static const int _maxTrails = _maxTrailSegments + 1;

  final List<DashboardHeaderTapWaveRipple> _ripples =
      <DashboardHeaderTapWaveRipple>[];
  final List<DashboardHeaderTapWaveTrail> _trails =
      <DashboardHeaderTapWaveTrail>[];
  DashboardHeaderTapWaveTuning _tuning =
      DashboardHeaderTapWaveTuning.defaults();
  // `_origin` belongs to the live pointer.  A release wave deliberately owns
  // a second origin: a following touch must not drag an already released
  // large field to the new finger position.
  Offset _origin = const Offset(.5, .5);
  Offset _releaseOrigin = const Offset(.5, .5);
  bool _pointerActive = false;
  bool _dragging = false;
  bool _pathBreakPending = false;
  Duration? _releaseStartedAt;
  Duration? _lastPointerTimestamp;
  Duration? _lastTrailEmissionAt;
  Size _pathLogicalSize = Size.zero;
  Offset _pendingMovement = Offset.zero;
  double _smoothedVelocity = 0;
  int _waveGeneration = 0;

  DashboardHeaderTapWaveTuning get tuning => _tuning;
  Iterable<DashboardHeaderTapWaveRipple> get ripples => _ripples;
  Iterable<DashboardHeaderTapWaveTrail> get trails => _trails;
  int get rippleCount => _ripples.length;
  int get trailCount => _trails.length;
  int get waveGeneration => _waveGeneration;
  bool get hasActiveFieldRipples => _ripples.isNotEmpty;
  bool get isDragging => _dragging;
  static int get maxTrailSegments => _maxTrailSegments;
  static int get maxTrailSamples => _maxTrails;

  bool get requiresFrames =>
      _pointerActive ||
      _releaseStartedAt != null ||
      _ripples.isNotEmpty ||
      _trails.isNotEmpty;

  void configure(DashboardHeaderTapWaveTuning value) => _tuning = value;

  void pointerDown({
    required Offset origin,
    required Duration timestamp,
    required Size logicalSize,
  }) {
    _origin = _clampPoint(origin);
    _pointerActive = true;
    _dragging = false;
    _pathBreakPending = false;
    _lastPointerTimestamp = timestamp;
    _lastTrailEmissionAt = timestamp;
    _pathLogicalSize = _safeLogicalSize(logicalSize);
    _pendingMovement = Offset.zero;
    _smoothedVelocity = 0;
    _appendTrail(
      origin: _origin,
      timestamp: timestamp,
      velocity: 0,
      connectsToPrevious: false,
      force: true,
    );
  }

  void pointerMove({
    required Offset origin,
    required Offset logicalDelta,
    required Size logicalSize,
    required Duration timestamp,
  }) {
    if (!_pointerActive) return;
    final nextOrigin = _clampPoint(origin);
    final nextSize = _safeLogicalSize(logicalSize);
    final previousTimestamp = _lastPointerTimestamp ?? timestamp;
    final elapsedMicros = (timestamp - previousTimestamp).inMicroseconds;
    // Pointer event timestamps, not the render clock, own velocity. Multiple
    // moves can legitimately land in one animation frame, so an equal event
    // timestamp falls back to a small, stable sampling interval rather than
    // producing an infinite speed spike.
    final safeElapsedMicros = elapsedMicros > 0
        ? elapsedMicros
        : const Duration(milliseconds: 8).inMicroseconds;
    final deltaDistance = logicalDelta.distance;
    final rawVelocity =
        (deltaDistance * Duration.microsecondsPerSecond / safeElapsedMicros)
            .clamp(0.0, _maximumVelocityLogicalPixelsPerSecond)
            .toDouble();
    _smoothedVelocity = _smoothedVelocity == 0
        ? rawVelocity
        : _lerp(_smoothedVelocity, rawVelocity, .36);
    _lastPointerTimestamp = timestamp;

    final sizeChanged = _pathLogicalSize != nextSize;
    if (sizeChanged) {
      // A collapsing/expanding Header changes normalized coordinates without
      // the user moving. Keep old vertices surface-relative, and require a
      // fresh in-bounds vertex before a resized path can continue.
      _pathLogicalSize = nextSize;
      if (deltaDistance <= .001) {
        _pathBreakPending = true;
        return;
      }
      _pathBreakPending = true;
    }

    // The live point is not a trail sample.  It follows even a sub-threshold
    // or stationary drag, so a deliberately slow finger never loses the
    // immediate under-finger acknowledgement while historical rings fade.
    _origin = nextOrigin;

    if (!_dragging) {
      _pendingMovement += logicalDelta;
      if (_pendingMovement.distance < _dragThresholdLogicalPixels) return;
      _dragging = true;
    }

    if (_pathBreakPending) {
      _origin = nextOrigin;
      _appendTrail(
        origin: nextOrigin,
        timestamp: timestamp,
        velocity: _normalizedVelocity,
        connectsToPrevious: false,
        force: true,
      );
      _pathBreakPending = false;
      return;
    }

    _appendResampledPath(
      to: nextOrigin,
      timestamp: timestamp,
      velocity: _normalizedVelocity,
    );
    _origin = nextOrigin;
  }

  void pointerUp({
    required Duration timestamp,
    Offset? releaseOrigin,
    bool emitReleaseRipple = true,
  }) {
    if (!_pointerActive) return;
    if (releaseOrigin != null) _origin = _clampPoint(releaseOrigin);
    _pointerActive = false;
    // Only an actual in-surface PointerUp creates the large release ring.
    // Cancels, disposal and off-surface endings merely close the live touch.
    if (emitReleaseRipple) {
      _releaseOrigin = _origin;
      _releaseStartedAt = timestamp;
      _spawnRipple(_origin, timestamp);
    }
    _lastPointerTimestamp = null;
  }

  /// Called by the passive listener when a primary pointer leaves the visual
  /// Header bounds. It intentionally does not clamp a stream of off-surface
  /// events to one edge pixel; a later re-entry begins a separate segment.
  void breakPath() {
    if (!_pointerActive) return;
    _pathBreakPending = true;
    _pendingMovement = Offset.zero;
  }

  void advance(Duration timestamp) {
    _ripples.removeWhere(
      (ripple) => _tapAge(timestamp - ripple.startedAt) >= _rippleLifetime,
    );
    var trimmedTrailHead = false;
    while (_trails.isNotEmpty &&
        timestamp - _trails.first.startedAt >= _trailLifetime) {
      _trails.removeAt(0);
      trimmedTrailHead = true;
    }
    if (trimmedTrailHead && _trails.isNotEmpty) {
      _trails[0] = _trails.first.withoutPreviousConnection();
    }
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt != null &&
        _tapAge(timestamp - releaseStartedAt) >= _releaseCleanup) {
      _releaseStartedAt = null;
    }
  }

  DashboardHeaderTapWaveOverlay? overlayAt(Duration timestamp) {
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt == null) return null;
    final age = _tapAge(timestamp - releaseStartedAt);
    if (age >= _releaseCleanup) return null;
    const initialOpacity = .96;
    const initialBlur = 7.0;
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
      origin: _releaseOrigin,
      opacity: initialOpacity * (1 - fade) * _tapStrengthFactor,
      scale: _releasedTapScale(age, transform),
      blur: _lerp(initialBlur, 20, fade),
    );
  }

  /// Writes the CSS-source overlay curve into retained numeric storage for
  /// the full-surface fragment path. The former Canvas/saveLayer adapter
  /// called [overlayAt]; normal production rendering must not allocate that
  /// immutable wrapper or a low-resolution blur layer per phase tick.
  void writeOverlayFrame({
    required Duration timestamp,
    required DashboardHeaderTapWaveOverlayFrame into,
  }) {
    into
      ..x = _releaseOrigin.dx
      ..y = _releaseOrigin.dy;
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt == null) {
      into.clear();
      return;
    }
    final age = _tapAge(timestamp - releaseStartedAt);
    if (age >= _releaseCleanup) {
      into.clear();
      return;
    }
    const initialOpacity = .96;
    const initialBlur = 7.0;
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
    into
      ..opacity = initialOpacity * (1 - fade) * _tapStrengthFactor
      ..scale = _releasedTapScale(age, transform)
      ..blur = _lerp(initialBlur, 20, fade)
      ..active = 1;
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
    if (age >= _trailLifetime) return null;
    // The fragment ABI's retained trail phase is intentionally normalized to
    // its historical 0…0.8 interval.  The persisted lifetime only changes
    // how quickly real time travels through that phase; CPU expiry and shader
    // visibility therefore agree at both slider limits.
    return DashboardHeaderTapWaveTrailSample(
      age:
          (math.max(0, age.inMicroseconds) /
                  math.max(1, _trailLifetime.inMicroseconds) *
                  _referenceTrailLifetime.inMicroseconds /
                  Duration.microsecondsPerSecond)
              .clamp(0.0, .8)
              .toDouble(),
      velocity: trail.velocity,
      connectsToPrevious: trail.connectsToPrevious,
    );
  }

  /// The fragment ripple bank must follow the exact same local tap clock as
  /// the overlay, otherwise a 50%/200% setting would split one release into
  /// two visibly different animations.
  double? ripplePhaseAt({
    required DashboardHeaderTapWaveRipple ripple,
    required Duration timestamp,
  }) {
    final age = _tapAge(timestamp - ripple.startedAt);
    if (age.isNegative || age >= _rippleLifetime) return null;
    return (age.inMicroseconds / _rippleLifetime.inMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Writes a vertex of the time-decaying, connected water path into retained
  /// storage without allocating a frame object per paint.
  void writeTrailFrame({
    required DashboardHeaderTapWaveTrail trail,
    required Duration timestamp,
    required DashboardHeaderTapWaveTrailFrame into,
  }) {
    final sample = trailSampleAt(trail: trail, timestamp: timestamp);
    if (sample == null) {
      into.clear();
      return;
    }
    into
      ..x = trail.origin.dx
      ..y = trail.origin.dy
      ..age = sample.age
      ..signedVelocity = sample.connectsToPrevious
          ? math.max(.0001, sample.velocity)
          : -math.max(.0001, sample.velocity);
  }

  void writeLivePointFrame({
    required DashboardHeaderTapWaveLivePointFrame into,
  }) {
    into
      ..x = _origin.dx
      ..y = _origin.dy
      ..radius = 7;
    if (!_pointerActive || _dynamicTrailStrengthFactor <= .0001) {
      into.clear();
      return;
    }
    into
      ..opacity = (.28 + .24 * _dynamicTrailStrengthFactor).clamp(0.0, .8)
      ..active = 1;
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
    final intensity = _tuning.valueFor('rippleIntensity') * _tapStrengthFactor;
    for (final ripple in _ripples) {
      final elapsedMicros = _tapAge(
        timestamp - ripple.startedAt,
      ).inMicroseconds;
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
                1 -
                    _tapAge(timestamp - newest.startedAt).inMicroseconds /
                        fadeMicros,
              )
              .toDouble();
    into
      ..x = resolvedX.clamp(0.0, 1.0).toDouble()
      ..y = resolvedY.clamp(0.0, 1.0).toDouble()
      ..pulseLight = pulse * _tapStrengthFactor;
  }

  DashboardHeaderTapWaveOverlay _overlay({
    required Offset origin,
    required double opacity,
    required double scale,
    required double blur,
  }) => DashboardHeaderTapWaveOverlay(
    origin: origin,
    opacity: opacity,
    scale: scale,
    blur: blur,
    colors: DashboardHeaderTapWaveOverlay.sourceColors,
    stops: DashboardHeaderTapWaveOverlay.sourceStops,
  );

  double get _tapStrengthFactor =>
      (_tuning.valueFor(DashboardHeaderTapWaveCatalog.tapStrengthId) / 100)
          .clamp(0.0, 1.0)
          .toDouble();

  double get _tapStartFactor =>
      (_tuning.valueFor(DashboardHeaderTapWaveCatalog.tapStartSizeId) / 100)
          .clamp(.25, 1.0)
          .toDouble();

  double get _dynamicTrailStrengthFactor =>
      (_tuning.valueFor(DashboardHeaderTapWaveCatalog.dynamicTrailStrengthId) /
              100)
          .clamp(0.0, 3.0)
          .toDouble();

  Duration get _trailLifetime => Duration(
    microseconds:
        (_tuning.valueFor(DashboardHeaderTapWaveCatalog.dragRippleLifetimeId) *
                Duration.microsecondsPerSecond)
            .round(),
  );

  Duration _tapAge(Duration actualAge) => Duration(
    microseconds:
        (actualAge.inMicroseconds *
                (_tuning.valueFor(DashboardHeaderTapWaveCatalog.tapSpeedId) /
                    100))
            .round(),
  );

  double _releasedTapScale(Duration age, double transform) {
    final original = _lerp(.8, 1.42, transform);
    final recovery = _smoothstep(age.inMilliseconds / 180);
    return original - .8 * (1 - _tapStartFactor) * (1 - recovery);
  }

  void _spawnRipple(Offset origin, Duration timestamp) {
    _ripples.add(
      DashboardHeaderTapWaveRipple(origin: origin, startedAt: timestamp),
    );
    _waveGeneration += 1;
    if (_ripples.length > _maxRipples) _ripples.removeAt(0);
  }

  void _appendResampledPath({
    required Offset to,
    required Duration timestamp,
    required double velocity,
  }) {
    if (_trails.isEmpty) {
      _appendTrail(
        origin: to,
        timestamp: timestamp,
        velocity: velocity,
        connectsToPrevious: false,
        force: true,
      );
      return;
    }
    final from = _trails.last;
    final distance = _logicalDistance(from.origin, to, _pathLogicalSize);
    if (distance <= .001) return;
    final elapsed = timestamp - (_lastTrailEmissionAt ?? timestamp);
    final requiresSlowEmission =
        elapsed >= _slowDragEmissionInterval && distance >= 1;
    final pieces = math.max(
      1,
      requiresSlowEmission
          ? 1
          : (distance / _sampleSpacingLogicalPixels).ceil(),
    );
    for (var index = 1; index <= pieces; index += 1) {
      final progress = index / pieces;
      _appendTrail(
        origin: Offset.lerp(from.origin, to, progress)!,
        timestamp: _lerpDuration(from.startedAt, timestamp, progress),
        velocity: velocity,
        connectsToPrevious: true,
      );
    }
    _lastTrailEmissionAt = timestamp;
  }

  void _appendTrail({
    required Offset origin,
    required Duration timestamp,
    required double velocity,
    required bool connectsToPrevious,
    bool force = false,
  }) {
    final last = _trails.isEmpty ? null : _trails.last;
    if (!force &&
        last != null &&
        _logicalDistance(last.origin, origin, _pathLogicalSize) <= .001) {
      return;
    }
    _trails.add(
      DashboardHeaderTapWaveTrail(
        origin: origin,
        startedAt: timestamp,
        velocity: velocity,
        connectsToPrevious: connectsToPrevious && last != null,
      ),
    );
    if (_trails.length > _maxTrails) {
      _trails.removeAt(0);
      if (_trails.isNotEmpty) {
        _trails[0] = _trails.first.withoutPreviousConnection();
      }
    }
  }

  double get _normalizedVelocity =>
      (_smoothedVelocity / _maximumVelocityLogicalPixelsPerSecond)
          .clamp(0.0, 1.0)
          .toDouble();

  static Size _safeLogicalSize(Size value) => Size(
    value.width.isFinite && value.width > 0 ? value.width : 1,
    value.height.isFinite && value.height > 0 ? value.height : 1,
  );

  static double _logicalDistance(Offset from, Offset to, Size size) {
    final dx = (to.dx - from.dx) * size.width;
    final dy = (to.dy - from.dy) * size.height;
    return math.sqrt(dx * dx + dy * dy);
  }

  static Duration _lerpDuration(Duration from, Duration to, double amount) =>
      Duration(
        microseconds: _lerp(
          from.inMicroseconds.toDouble(),
          to.inMicroseconds.toDouble(),
          amount,
        ).round(),
      );

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

  static double _smoothstep(double amount) {
    final bounded = amount.clamp(0.0, 1.0).toDouble();
    return bounded * bounded * (3 - 2 * bounded);
  }

  static Duration get _rippleLifetime => Duration(
    microseconds: (_rippleFadeDuration.inMicroseconds * 1.08).round(),
  );
}
