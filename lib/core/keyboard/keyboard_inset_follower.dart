import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../debug/debug_console.dart';
import 'native_keyboard_insets.dart';

class KeyboardInsetMetrics {
  const KeyboardInsetMetrics({
    required this.rawInset,
    required this.animatedInset,
    required this.safeBottom,
    required this.enabled,
    required this.source,
    required this.fallbackInset,
    this.phase,
    this.sequence,
    this.ageMs,
    this.nativeSource,
  });

  final double rawInset;
  final double animatedInset;
  final double safeBottom;
  final bool enabled;
  final String source;
  final double fallbackInset;
  final String? phase;
  final int? sequence;
  final int? ageMs;
  final String? nativeSource;

  double get effectiveInset => enabled ? animatedInset : 0;

  double get lag => enabled ? (rawInset - animatedInset).abs() : 0;
}

typedef KeyboardInsetTransitionBuilder =
    Widget Function(
      BuildContext context,
      KeyboardInsetMetrics metrics,
      Widget? child,
    );

class KeyboardInsetFollower extends StatefulWidget {
  const KeyboardInsetFollower({
    super.key,
    required this.builder,
    this.child,
    this.debugLabel,
    this.enabled = true,
  });

  final KeyboardInsetTransitionBuilder builder;
  final Widget? child;
  final String? debugLabel;
  final bool enabled;

  @override
  State<KeyboardInsetFollower> createState() => _KeyboardInsetFollowerState();
}

class _KeyboardInsetFollowerState extends State<KeyboardInsetFollower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _keyboardSessionController;
  double? _lastLoggedRawInset;
  double? _lastLoggedAnimatedInset;
  String? _lastLoggedSource;
  String? _lastLoggedPhase;
  int? _lastLoggedSequence;
  var _sessionActive = false;
  var _sessionStartInset = 0.0;
  var _sessionEndInset = 0.0;
  var _sessionDuration = Duration.zero;
  DateTime? _sessionStartedAt;
  int? _sessionSequence;
  String? _sessionNativeSource;

  @override
  void initState() {
    super.initState();
    _keyboardSessionController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1),
          )
          ..addListener(_handleSessionTick)
          ..addStatusListener(_handleSessionStatus);
    NativeKeyboardInsets.instance
      ..ensureStarted()
      ..addListener(_handleNativeKeyboardFrame);
  }

  @override
  void dispose() {
    NativeKeyboardInsets.instance.removeListener(_handleNativeKeyboardFrame);
    _keyboardSessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshotOf(context);
    final rawInset = snapshot.inset;
    final targetInset = widget.enabled ? rawInset : 0.0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final metrics = KeyboardInsetMetrics(
      rawInset: rawInset,
      animatedInset: targetInset,
      safeBottom: safeBottom,
      enabled: widget.enabled,
      source: snapshot.source,
      fallbackInset: snapshot.fallbackInset,
      phase: snapshot.phase,
      sequence: snapshot.sequence,
      ageMs: snapshot.ageMs,
      nativeSource: snapshot.nativeSource,
    );
    _logFrame(metrics);
    return widget.builder(context, metrics, widget.child);
  }

  void _handleNativeKeyboardFrame() {
    if (!mounted) return;
    _syncNativeSession();
    setState(() {});
  }

  void _handleSessionTick() {
    if (!mounted || !_sessionActive) return;
    setState(() {});
  }

  void _handleSessionStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    if (!_sessionActive) return;
    setState(() {
      _sessionActive = false;
    });
  }

  void _syncNativeSession() {
    final session = NativeKeyboardInsets.instance.latestSession;
    if (session == null || session.sequence == _sessionSequence) return;
    _sessionSequence = session.sequence;

    if (session.phase == KeyboardAnimationPhase.end) {
      _keyboardSessionController.stop();
      _sessionActive = false;
      _sessionStartedAt = null;
      return;
    }

    if (!session.isActive) return;
    _sessionActive = true;
    _sessionStartInset = session.startInset;
    _sessionEndInset = session.endInset;
    _sessionDuration = session.duration.inMilliseconds <= 0
        ? const Duration(milliseconds: 180)
        : session.duration;
    _sessionStartedAt = session.startedAt;
    _sessionNativeSource = session.nativeSource;

    final duration = _sessionDuration;
    final startProgress = session.progressAt(DateTime.now());
    final remainingMs = (duration.inMilliseconds * (1 - startProgress))
        .round()
        .clamp(1, duration.inMilliseconds);
    _keyboardSessionController
      ..stop()
      ..value = startProgress;
    _keyboardSessionController.animateTo(
      1,
      duration: Duration(milliseconds: remainingMs),
      curve: Curves.linear,
    );
  }

  ResolvedKeyboardInset _snapshotOf(BuildContext context) {
    final fallback = KeyboardInsetReader.idleSnapshotOf(context);
    if (!_sessionActive) return fallback;
    final progress = math
        .max(
          _keyboardSessionController.value,
          _sessionProgressAt(DateTime.now()),
        )
        .clamp(0.0, 1.0)
        .toDouble();
    final inset =
        _sessionStartInset + (_sessionEndInset - _sessionStartInset) * progress;
    return ResolvedKeyboardInset(
      inset: inset,
      source: 'local-ime-session',
      fallbackInset: fallback.fallbackInset,
      phase: 'session-active',
      sequence: _sessionSequence,
      nativeSource: _sessionNativeSource,
    );
  }

  double _sessionProgressAt(DateTime now) {
    final durationMs = _sessionDuration.inMilliseconds;
    final startedAt = _sessionStartedAt;
    if (durationMs <= 0 || startedAt == null) {
      return _keyboardSessionController.value;
    }
    return now.difference(startedAt).inMilliseconds / durationMs;
  }

  void _logFrame(KeyboardInsetMetrics metrics) {
    final label = widget.debugLabel;
    if (label == null) return;
    final previousRaw = _lastLoggedRawInset;
    final previousAnimated = _lastLoggedAnimatedInset;
    final sameIdentity =
        _lastLoggedSource == metrics.source &&
        _lastLoggedPhase == metrics.phase &&
        _lastLoggedSequence == metrics.sequence;
    if (sameIdentity &&
        metrics.source == 'local-ime-session' &&
        metrics.phase == 'session-active') {
      return;
    }
    if (previousRaw != null &&
        previousAnimated != null &&
        sameIdentity &&
        (previousRaw - metrics.rawInset).abs() < 0.5 &&
        (previousAnimated - metrics.animatedInset).abs() < 0.5) {
      return;
    }
    _lastLoggedRawInset = metrics.rawInset;
    _lastLoggedAnimatedInset = metrics.animatedInset;
    _lastLoggedSource = metrics.source;
    _lastLoggedPhase = metrics.phase;
    _lastLoggedSequence = metrics.sequence;
    DebugConsole.log(
      '[KeyboardFlow] $label keyboard frame '
      'raw=${metrics.rawInset.toStringAsFixed(1)} '
      'animated=${metrics.animatedInset.toStringAsFixed(1)} '
      'effective=${metrics.effectiveInset.toStringAsFixed(1)} '
      'lag=${metrics.lag.toStringAsFixed(1)} '
      'safe=${metrics.safeBottom.toStringAsFixed(1)} '
      'enabled=${metrics.enabled} source=${metrics.source} '
      'phase=${metrics.phase ?? 'none'} '
      'seq=${metrics.sequence?.toString() ?? 'n/a'} '
      'ageMs=${metrics.ageMs?.toString() ?? 'n/a'} '
      'fallback=${metrics.fallbackInset.toStringAsFixed(1)} '
      'nativeSource=${metrics.nativeSource ?? 'n/a'} '
      'mode=native-first',
    );
  }
}

class KeyboardInsetReader {
  const KeyboardInsetReader._();

  static double rawOf(BuildContext context) {
    return snapshotOf(context).inset;
  }

  static ResolvedKeyboardInset snapshotOf(BuildContext context) {
    return idleSnapshotOf(context);
  }

  static ResolvedKeyboardInset idleSnapshotOf(BuildContext context) {
    NativeKeyboardInsets.instance.ensureStarted();
    final fallbackInset =
        MediaQuery.maybeOf(context)?.viewInsets.bottom ?? platformRawInset();
    return KeyboardInsetMotionCoordinator.resolveIdle(
      nativeSample: NativeKeyboardInsets.instance.latest,
      fallbackInset: fallbackInset,
      now: DateTime.now(),
    );
  }

  static double platformRawInset() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 0;
    final view = views.first;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }
}
