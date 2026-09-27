import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import 'balance_carousel_wave_motion.dart';

/// Latest bounded facts about the one Balance-carousel decorative-wave clock.
/// It deliberately stores observations, not a second clock or notifier: the
/// existing carousel State remains the only animation owner.
@immutable
final class BalanceCarouselWaveDiagnosticSnapshot {
  const BalanceCarouselWaveDiagnosticSnapshot({
    required this.animationEnabled,
    required this.reducedMotion,
    required this.clockRunning,
    required this.visibleWaveCount,
    required this.selectedCardId,
    required this.profileId,
    required this.phase,
    required this.direction,
    required this.loopMode,
    required this.waveOpacity,
    required this.backgroundOpacity,
    required this.lastGeometryHash,
    required this.lastFrameSummary,
  });

  final bool animationEnabled;
  final bool reducedMotion;
  final bool clockRunning;
  final int visibleWaveCount;
  final String? selectedCardId;
  final String? profileId;
  final double phase;
  final String direction;
  final String loopMode;
  final double waveOpacity;
  final double backgroundOpacity;
  final String? lastGeometryHash;
  final String? lastFrameSummary;

  Map<String, Object?> toMarkerContext() => <String, Object?>{
    'animationEnabled': animationEnabled,
    'reducedMotion': reducedMotion,
    'clockRunning': clockRunning,
    'visibleWaveCount': visibleWaveCount,
    'selectedCard': selectedCardId,
    'profile': profileId,
    'phase': phase.toStringAsFixed(4),
    'direction': direction,
    'loopMode': loopMode,
    'waveOpacity': waveOpacity.toStringAsFixed(3),
    'backgroundOpacity': backgroundOpacity.toStringAsFixed(3),
    'lastGeometryHash': lastGeometryHash,
    'lastFrameSummary': lastFrameSummary,
  };
}

/// Bounded telemetry for the shared wave clock.  The State calls [onTick] on
/// controller ticks and painters call [onPaint]; neither method writes one log
/// record per frame.  This remains intentionally testable without a widget
/// tree or an `AnimationController` dependency.
final class BalanceCarouselWaveRuntimeDiagnostics {
  BalanceCarouselWaveRuntimeDiagnostics({
    required this.clockOwner,
    required this.configuredDuration,
    this.visibleWaveCount = 3,
  });

  static const _maximumClockSamples = 15;
  static const _maximumGeometrySamples = 24;
  static const _maximumLoopBoundaries = 4;
  // A diagnostics session may last far longer than the bounded observation
  // window. Keep representative frame and settings facts without allowing
  // this decorative subsystem to evict unrelated retained evidence.
  static const _maximumFrameSummaries = 4;
  static const _maximumSettingsSamples = 16;
  static const _summaryInterval = Duration(seconds: 3);
  static const _longTickIntervalMicros = 33334;

  final String clockOwner;
  final Duration configuredDuration;
  final int visibleWaveCount;
  final Set<String> _boundProfiles = <String>{};
  final Set<String> _milestones = <String>{};

  bool _bound = false;
  bool _animationEnabled = false;
  bool _reducedMotion = false;
  bool _clockRunning = false;
  double _waveOpacity = 1;
  double _backgroundOpacity = 1;
  double _borderOpacity = 1;
  String? _selectedCardId;
  BalanceCarouselWaveProfile? _selectedProfile;
  double _phase = 0;
  double? _previousPhase;
  int _cycle = 0;
  int _clockSamples = 0;
  int _geometrySamples = 0;
  int _loopBoundaries = 0;
  int _frameSummaries = 0;
  int _settingsSamples = 0;
  int _intervalTicks = 0;
  int _intervalPaints = 0;
  int _intervalLongTicks = 0;
  int _intervalTickMicros = 0;
  int? _lastTickElapsedMicros;
  int? _summaryStartedMicros;
  int _summaryBuildRevision = 0;
  String? _lastGeometryHash;
  String? _lastFrameSummary;

  bool get isBound => _bound;

  BalanceCarouselWaveDiagnosticSnapshot get snapshot =>
      BalanceCarouselWaveDiagnosticSnapshot(
        animationEnabled: _animationEnabled,
        reducedMotion: _reducedMotion,
        clockRunning: _clockRunning,
        visibleWaveCount: visibleWaveCount,
        selectedCardId: _selectedCardId,
        profileId: _selectedProfile?.family.name,
        phase: _phase,
        direction: 'forward-periodic',
        loopMode: 'periodic',
        waveOpacity: _waveOpacity,
        backgroundOpacity: _backgroundOpacity,
        lastGeometryHash: _lastGeometryHash,
        lastFrameSummary: _lastFrameSummary,
      );

  void bind({
    required bool animationEnabled,
    required bool reducedMotion,
    required bool clockRunning,
    required double waveOpacity,
    required double backgroundOpacity,
  }) {
    _setConfiguration(
      animationEnabled: animationEnabled,
      reducedMotion: reducedMotion,
      clockRunning: clockRunning,
      waveOpacity: waveOpacity,
      backgroundOpacity: backgroundOpacity,
    );
    if (_bound) return;
    _bound = true;
    _emit(
      'BOUND',
      'animationEnabled=$_animationEnabled reducedMotion=$_reducedMotion '
          'clockOwner=$clockOwner tickerCount=1 controllerCount=1 '
          'visibleWaveCount=$visibleWaveCount '
          'configuredDurationMs=${configuredDuration.inMilliseconds} '
          'loopMode=periodic backgroundOpacity=${_backgroundOpacity.toStringAsFixed(3)} '
          'waveOpacity=${_waveOpacity.toStringAsFixed(3)}',
    );
  }

  void settingsChanged({
    required bool animationEnabled,
    required bool reducedMotion,
    required bool clockRunning,
    required double waveOpacity,
    required double backgroundOpacity,
    required double borderOpacity,
  }) {
    final changed =
        _animationEnabled != animationEnabled ||
        _reducedMotion != reducedMotion ||
        _waveOpacity != waveOpacity ||
        _backgroundOpacity != backgroundOpacity ||
        _borderOpacity != borderOpacity;
    _setConfiguration(
      animationEnabled: animationEnabled,
      reducedMotion: reducedMotion,
      clockRunning: clockRunning,
      waveOpacity: waveOpacity,
      backgroundOpacity: backgroundOpacity,
    );
    _borderOpacity = borderOpacity;
    if (!changed) return;
    if (_settingsSamples < _maximumSettingsSamples) {
      _settingsSamples += 1;
      _emit(
        'SETTINGS_CHANGED',
        'animationEnabled=$_animationEnabled reducedMotion=$_reducedMotion '
            'clockRunning=$_clockRunning waveOpacity=${_waveOpacity.toStringAsFixed(3)} '
            'backgroundOpacity=${_backgroundOpacity.toStringAsFixed(3)} '
            'borderOpacity=${borderOpacity.toStringAsFixed(3)}',
      );
    }
  }

  void bindProfile(
    BalanceCarouselWaveProfile profile, {
    required bool selected,
  }) {
    if (selected) {
      _selectedCardId = profile.cardId;
      _selectedProfile = profile;
    }
    if (!_boundProfiles.add(profile.cardId)) return;
    final signature = BalanceCarouselWaveMotion.geometryDigest(
      BalanceCarouselWaveMotion.geometryFor(profile: profile, clockPhase: 0),
    );
    _emit(
      'CARD_PROFILE',
      'cardId=${profile.cardId} profileId=${profile.family.name} '
          'phaseOffset=${profile.phaseOffset.toStringAsFixed(4)} '
          'speedMultiplier=1.000 morphVariant=${profile.family.name} '
          'selected=$selected pathControlSignature=$signature',
    );
  }

  void onTick({
    required Duration elapsed,
    required double phase,
    required int buildRevision,
  }) {
    final elapsedMicros = elapsed.inMicroseconds;
    _clockRunning = _animationEnabled && !_reducedMotion;
    _phase = phase;
    _intervalTicks += 1;
    final previousElapsed = _lastTickElapsedMicros;
    if (previousElapsed != null) {
      final interval = elapsedMicros - previousElapsed;
      if (interval > 0) {
        _intervalTickMicros += interval;
        if (interval > _longTickIntervalMicros) _intervalLongTicks += 1;
      }
    }
    _lastTickElapsedMicros = elapsedMicros;
    _summaryStartedMicros ??= elapsedMicros;

    final previousPhase = _previousPhase;
    if (previousPhase != null && phase < previousPhase - .5) {
      _cycle += 1;
      _emitLoopBoundary(previousPhase: previousPhase, nextPhase: phase);
    }
    _previousPhase = phase;
    final bucket = _phaseBucket(phase);
    final milestone = '$_cycle:$bucket';
    if (_clockSamples < _maximumClockSamples && _milestones.add(milestone)) {
      _clockSamples += 1;
      _emit(
        'CLOCK_SAMPLE',
        'elapsedMicros=$elapsedMicros normalizedPhase=${phase.toStringAsFixed(4)} '
            'direction=forward-periodic clockValue=${phase.toStringAsFixed(4)} '
            'paintRevision=$_intervalPaints',
      );
    }
    final summaryStarted = _summaryStartedMicros!;
    if (elapsedMicros - summaryStarted >= _summaryInterval.inMicroseconds) {
      final average = _intervalTicks < 2
          ? null
          : (_intervalTickMicros / (_intervalTicks - 1)).round();
      _lastFrameSummary =
          'tickCount=$_intervalTicks paintCount=$_intervalPaints '
          'rebuildCount=${buildRevision - _summaryBuildRevision} '
          'averageTickIntervalMicros=${average ?? '-'} '
          'longIntervalCount=$_intervalLongTicks activeVisibleCards=$visibleWaveCount';
      if (_frameSummaries < _maximumFrameSummaries) {
        _frameSummaries += 1;
        _emit('FRAME_SUMMARY', _lastFrameSummary!);
      }
      _summaryStartedMicros = elapsedMicros;
      _summaryBuildRevision = buildRevision;
      _intervalTicks = 0;
      _intervalPaints = 0;
      _intervalLongTicks = 0;
      _intervalTickMicros = 0;
    }
  }

  void onPaint({
    required BalanceCarouselWaveProfile profile,
    required double phase,
    required Size paintBounds,
    required BalanceCarouselWaveGeometry geometry,
  }) {
    _intervalPaints += 1;
    final sampleKey = '${profile.cardId}:$_cycle:${_phaseBucket(phase)}';
    if (_geometrySamples >= _maximumGeometrySamples ||
        !_milestones.add('geometry:$sampleKey')) {
      return;
    }
    _geometrySamples += 1;
    final digest = BalanceCarouselWaveMotion.geometryDigest(geometry);
    _lastGeometryHash = digest;
    final points = geometry.normalizedControlPoints;
    _emit(
      'GEOMETRY_SAMPLE',
      'cardId=${profile.cardId} profileId=${profile.family.name} '
          'phase=${phase.toStringAsFixed(4)} geometryDigest=$digest '
          'controlPoints=${points[1].toStringAsFixed(4)},${points[3].toStringAsFixed(4)},${points[7].toStringAsFixed(4)},${points[13].toStringAsFixed(4)} '
          'paintBounds=0,0,${paintBounds.width.toStringAsFixed(1)}x${paintBounds.height.toStringAsFixed(1)} '
          'clipBounds=0,0,${paintBounds.width.toStringAsFixed(1)}x${paintBounds.height.toStringAsFixed(1)}',
    );
  }

  void _emitLoopBoundary({
    required double previousPhase,
    required double nextPhase,
  }) {
    if (_loopBoundaries >= _maximumLoopBoundaries) return;
    _loopBoundaries += 1;
    final profile = _selectedProfile;
    final before = profile == null
        ? '-'
        : BalanceCarouselWaveMotion.geometryDigest(
            BalanceCarouselWaveMotion.geometryFor(
              profile: profile,
              clockPhase: 1,
            ),
          );
    final after = profile == null
        ? '-'
        : BalanceCarouselWaveMotion.geometryDigest(
            BalanceCarouselWaveMotion.geometryFor(
              profile: profile,
              clockPhase: 0,
            ),
          );
    _emit(
      'LOOP_BOUNDARY',
      'previousPhase=${previousPhase.toStringAsFixed(4)} '
          'nextPhase=${nextPhase.toStringAsFixed(4)} '
          'previousDirection=forward nextDirection=forward '
          'geometryBeforeHash=$before geometryAfterHash=$after '
          'discontinuityDetected=${before != after}',
    );
  }

  void _setConfiguration({
    required bool animationEnabled,
    required bool reducedMotion,
    required bool clockRunning,
    required double waveOpacity,
    required double backgroundOpacity,
  }) {
    _animationEnabled = animationEnabled;
    _reducedMotion = reducedMotion;
    _clockRunning = clockRunning;
    _waveOpacity = waveOpacity;
    _backgroundOpacity = backgroundOpacity;
  }

  static int _phaseBucket(double phase) =>
      (phase.clamp(0.0, .999999) * 4).floor();

  static void _emit(String suffix, String scope) => FluviDiagnosticLogger.log(
    FluviDiagnosticEvent(stage: 'BALANCE_WAVE|$suffix', scope: scope),
  );
}
