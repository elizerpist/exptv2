import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/application/dashboard_core_mode_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'dashboard_active_header_frame_preparer.dart';

/// Converts the committed foreground header to one complete AppWidget package.
final class DashboardHeaderWidgetPublisher {
  DashboardHeaderWidgetPublisher({
    required this.controller,
    required this.activeMode,
    required this.balanceFrame,
    required this.budgetFrame,
    required this.mindFrame,
    required this.isVisible,
    MethodChannel channel = const MethodChannel('fluvi/header_orb_widget'),
    ActiveHeaderFramesRenderer render = renderActiveHeaderFrames,
  }) : _channel = channel,
       _render = render,
       _motionEnabled = controller.motionEnabled {
    controller.tuning.addListener(schedule);
    controller.portalSettingsGeneration.addListener(schedule);
    controller.orbExportCommitGeneration.addListener(schedule);
    controller.addListener(_updateMotion);
    balanceFrame.addListener(schedule);
    budgetFrame.addListener(schedule);
    mindFrame.addListener(schedule);
    activeMode.addListener(schedule);
  }

  final DashboardHeaderVisualController controller;
  final DashboardCoreModeController activeMode;
  final ValueListenable<DashboardHeaderVisualFrame> balanceFrame;
  final ValueListenable<DashboardHeaderVisualFrame> budgetFrame;
  final ValueListenable<DashboardHeaderVisualFrame> mindFrame;
  final bool Function() isVisible;
  final MethodChannel _channel;
  final ActiveHeaderFramesRenderer _render;
  Size? _geometry;
  double _pixelRatio = 1;
  bool _motionEnabled;
  bool _disposed = false;
  bool _scheduled = false;
  bool _working = false;
  String? _requestedVisual;
  int _generation = 0;
  _HeaderRequest? _pending;

  void _updateMotion() {
    if (_motionEnabled == controller.motionEnabled) return;
    _motionEnabled = controller.motionEnabled;
    schedule();
  }

  void updateHeaderGeometry(Size geometry, {required double devicePixelRatio}) {
    if (geometry.isEmpty || !geometry.isFinite) return;
    // Only a real change in the displayed physical size invalidates the source.
    final physicalSize = Size(
      (geometry.width * devicePixelRatio).roundToDouble(),
      (geometry.height * devicePixelRatio).roundToDouble(),
    );
    if (_geometry == physicalSize) return;
    _geometry = physicalSize;
    _pixelRatio = devicePixelRatio;
    schedule();
  }

  void schedule() {
    if (_disposed ||
        _scheduled ||
        _geometry == null ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed || !isVisible()) return;
      final mode = activeMode.committedMode.mode;
      final frame = switch (mode) {
        DashboardMode.mind => mindFrame.value,
        DashboardMode.balance => balanceFrame.value,
        DashboardMode.budget => budgetFrame.value,
      };
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: frame,
      );
      final geometry = _geometry!;
      final signature =
          '${mode.name}|${activeMode.committedModeEpoch}|$geometry|'
          '$_motionEnabled|${snapshot.orbVisualCacheKey}';
      if (signature == _requestedVisual) return;
      _requestedVisual = signature;
      unawaited(
        _claim(
          _HeaderRequest(
            generation: ++_generation,
            mode: mode.name,
            signature: signature,
            snapshot: snapshot,
            geometry: geometry / _pixelRatio,
            pixelRatio: _pixelRatio,
            motionEnabled: _motionEnabled,
            phaseOriginUtcMs: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// A visit after toggling consent may have the same visual signature.
  void refresh() {
    _requestedVisual = null;
    schedule();
  }

  Future<void> _claim(_HeaderRequest request) async {
    try {
      final receipt = await _channel.invokeMapMethod<String, Object?>(
        'prepare',
        {'mode': request.mode, 'signature': request.signature},
      );
      if (!_current(request)) return;
      final token = receipt?['token'];
      if (token is String) {
        _pending = request.withToken(token);
        if (!_working) unawaited(_drain());
      } else if (receipt?['cached'] != true) {
        _requestedVisual = null;
      }
    } on MissingPluginException {
      // Dashboard-only hosts have no Android widget provider.
    } on PlatformException {
      if (_current(request)) _requestedVisual = null;
    }
  }

  bool _current(_HeaderRequest request) =>
      !_disposed && request.generation == _generation;

  Future<void> _drain() async {
    _working = true;
    try {
      while (!_disposed && _pending != null) {
        final request = _pending!;
        _pending = null;
        if (!_current(request)) continue;
        try {
          final prepared = await _render(
            snapshot: request.snapshot,
            headerSize: request.geometry,
            devicePixelRatio: request.pixelRatio,
            motionEnabled: request.motionEnabled,
            isCurrent: () => _current(request),
          );
          if (!_current(request)) continue;
          final playback = prepared.playback;
          final frames = prepared.frames;
          if (!prepared.ready || playback == null || frames == null) {
            _requestedVisual = null;
            await _channel.invokeMethod<void>('unavailable', {
              'token': request.token,
              'reason': prepared.status.name,
            });
            continue;
          }
          final accepted = await _channel.invokeMethod<bool>('publish', {
            'token': request.token,
            'motion': request.motionEnabled && request.snapshot.isAnimated,
            'phaseOriginUtcMs': request.phaseOriginUtcMs,
            'size': playback.frameSizePx,
            'intervalMs': playback.intervalMs,
            'frames': frames,
          });
          if (_current(request) && accepted != true) _requestedVisual = null;
        } on MissingPluginException {
          if (_current(request)) _requestedVisual = null;
        } on PlatformException {
          if (_current(request)) _requestedVisual = null;
        }
      }
    } finally {
      _working = false;
    }
  }

  void dispose() {
    _disposed = true;
    _pending = null;
    controller.tuning.removeListener(schedule);
    controller.portalSettingsGeneration.removeListener(schedule);
    controller.orbExportCommitGeneration.removeListener(schedule);
    controller.removeListener(_updateMotion);
    balanceFrame.removeListener(schedule);
    budgetFrame.removeListener(schedule);
    mindFrame.removeListener(schedule);
    activeMode.removeListener(schedule);
  }
}

final class _HeaderRequest {
  const _HeaderRequest({
    required this.generation,
    required this.mode,
    required this.signature,
    required this.snapshot,
    required this.geometry,
    required this.pixelRatio,
    required this.motionEnabled,
    required this.phaseOriginUtcMs,
    this.token,
  });

  final int generation;
  final String mode;
  final String signature;
  final DashboardHeaderMaterialSnapshot snapshot;
  final Size geometry;
  final double pixelRatio;
  final bool motionEnabled;
  final int phaseOriginUtcMs;
  final String? token;

  _HeaderRequest withToken(String token) => _HeaderRequest(
    generation: generation,
    mode: mode,
    signature: signature,
    snapshot: snapshot,
    geometry: geometry,
    pixelRatio: pixelRatio,
    motionEnabled: motionEnabled,
    phaseOriginUtcMs: phaseOriginUtcMs,
    token: token,
  );
}
