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
  static const Duration _trailLifetime = Duration(milliseconds: 800);
  static const Duration _rippleFadeDuration = Duration(milliseconds: 1560);
  static const Duration _releaseCleanup = Duration(milliseconds: 1740);
  static const Duration _tapToDragTransition = Duration(milliseconds: 80);
  static const double _dragThresholdLogicalPixels = 5;
  static const double _sampleSpacingLogicalPixels = 6;
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
  Offset _origin = const Offset(.5, .5);
  bool _pointerActive = false;
  bool _dragging = false;
  bool _pathBreakPending = false;
  Duration? _releaseStartedAt;
  Duration? _dragStartedAt;
  Duration? _lastPointerTimestamp;
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
      _releaseStartedAt != null || _ripples.isNotEmpty || _trails.isNotEmpty;

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
    _releaseStartedAt = null;
    _dragStartedAt = null;
    _lastPointerTimestamp = timestamp;
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
    _spawnRipple(_origin, timestamp);
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

    if (!_dragging) {
      _pendingMovement += logicalDelta;
      if (_pendingMovement.distance < _dragThresholdLogicalPixels) return;
      _dragging = true;
      _dragStartedAt = timestamp;
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

  void pointerUp({required Duration timestamp}) {
    if (!_pointerActive) return;
    _pointerActive = false;
    _releaseStartedAt = timestamp;
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
      (ripple) => timestamp - ripple.startedAt >= _rippleLifetime,
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
        timestamp - releaseStartedAt >= _releaseCleanup) {
      _releaseStartedAt = null;
    }
  }

  DashboardHeaderTapWaveOverlay? overlayAt(Duration timestamp) {
    if (_pointerActive) {
      final dragFade = _dragOverlayFactor(timestamp);
      if (dragFade <= .0001) return null;
      return _overlay(
        opacity: .96 * dragFade,
        scale: _lerp(.8, 1, 1 - dragFade),
        blur: _lerp(7, 10, 1 - dragFade),
      );
    }
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt == null) return null;
    final age = timestamp - releaseStartedAt;
    if (age >= _releaseCleanup) return null;
    // A real drag has already retracted the large tap overlay. It must not
    // reappear as a second circle when the pointer is released.
    if (_dragging) return null;
    const initialOpacity = .96;
    const initialScale = .8;
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
      opacity: initialOpacity * (1 - fade),
      scale: _lerp(initialScale, 1.42, transform),
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
      ..x = _origin.dx
      ..y = _origin.dy;
    if (_pointerActive) {
      final dragFade = _dragOverlayFactor(timestamp);
      if (dragFade <= .0001) {
        into.clear();
        return;
      }
      into
        ..opacity = .96 * dragFade
        ..scale = _lerp(.8, 1, 1 - dragFade)
        ..blur = _lerp(7, 10, 1 - dragFade)
        ..active = 1;
      return;
    }
    final releaseStartedAt = _releaseStartedAt;
    if (releaseStartedAt == null) {
      into.clear();
      return;
    }
    final age = timestamp - releaseStartedAt;
    if (age >= _releaseCleanup) {
      into.clear();
      return;
    }
    if (_dragging) {
      into.clear();
      return;
    }
    const initialOpacity = .96;
    const initialScale = .8;
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
      ..opacity = initialOpacity * (1 - fade)
      ..scale = _lerp(initialScale, 1.42, transform)
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
    return DashboardHeaderTapWaveTrailSample(
      age: math.max(0, age.inMicroseconds) / Duration.microsecondsPerSecond,
      velocity: trail.velocity,
      connectsToPrevious: trail.connectsToPrevious,
    );
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
    final pieces = math.max(1, (distance / _sampleSpacingLogicalPixels).ceil());
    for (var index = 1; index <= pieces; index += 1) {
      final progress = index / pieces;
      _appendTrail(
        origin: Offset.lerp(from.origin, to, progress)!,
        timestamp: _lerpDuration(from.startedAt, timestamp, progress),
        velocity: velocity,
        connectsToPrevious: true,
      );
    }
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

  double _dragOverlayFactor(Duration timestamp) {
    final startedAt = _dragStartedAt;
    if (startedAt == null) return 1;
    final age = timestamp - startedAt;
    final progress =
        age.inMicroseconds / math.max(1, _tapToDragTransition.inMicroseconds);
    final smooth = progress.clamp(0.0, 1.0).toDouble();
    return 1 - smooth * smooth * (3 - 2 * smooth);
  }

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

  static Duration get _rippleLifetime => Duration(
    microseconds: (_rippleFadeDuration.inMicroseconds * 1.08).round(),
  );
}
