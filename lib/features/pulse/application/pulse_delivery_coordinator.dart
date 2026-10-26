import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

/// Shell-owned delivery state. The header is a rendering surface only; this
/// class owns reservation, lifecycle cancellation and qualified exposure.
/// It deliberately has no polling carousel: a changed surface, resume or
/// explicit user action is what causes another evaluation.
final class PulseDeliveryCoordinator extends ChangeNotifier {
  PulseDeliveryCoordinator({required PulseRepository repository})
    : _repository = repository,
      _hostSessionId = 'header-${DateTime.now().microsecondsSinceEpoch}';

  final PulseRepository _repository;
  final String _hostSessionId;
  PulseHeaderPresentationReservation? _presentation;
  PulseDeliverySurfaceContext? _surface;
  Timer? _exposureTimer;
  Timer? _finishTimer;
  bool _evaluating = false;
  bool _presented = false;
  int _generation = 0;

  PulseHeaderPresentationReservation? get presentation => _presentation;
  String get hostSessionId => _hostSessionId;

  /// Called by the shell/host whenever lifecycle, navigation, obstruction,
  /// geometry or active gesture changes. A false surface stops exposure.
  void updateSurface({
    required bool appActive,
    required bool ledgerVisible,
    required bool headerVisible,
    required bool unobstructed,
    required bool interactionIdle,
    required bool headerLayoutSupported,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final previous = _surface;
    _surface = PulseDeliverySurfaceContext(
      appActive: appActive,
      ledgerVisible: ledgerVisible,
      headerVisible: headerVisible,
      unobstructed: unobstructed,
      interactionIdle: interactionIdle,
      headerLayoutSupported: headerLayoutSupported,
      hostSessionId: _hostSessionId,
      interactionIdleSinceUtcMs: interactionIdle
          ? (previous?.interactionIdle == true
                ? previous!.interactionIdleSinceUtcMs
                : now)
          : null,
    );
    if (!_isQualifiedSurface) {
      _cancelExposureTimer();
      _finishTimer?.cancel();
      _finishTimer = null;
    } else if (!_wasQualified(previous) &&
        _presentation != null &&
        _presented) {
      // A sheet or a gesture breaks continuous exposure. When the header is
      // usable again, begin a new qualified interval instead of carrying over
      // milliseconds that elapsed while the copy was obscured.
      _armExposure(_presentation!);
      _armFinish(_presentation!);
    }
    if (_presentation == null) unawaited(reconcile());
  }

  void appLifecycleChanged(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    final surface = _surface;
    if (surface == null) return;
    updateSurface(
      appActive: active,
      ledgerVisible: surface.ledgerVisible,
      headerVisible: surface.headerVisible,
      unobstructed: surface.unobstructed,
      interactionIdle: surface.interactionIdle,
      headerLayoutSupported: surface.headerLayoutSupported,
    );
    if (!active && _presentation != null) {
      unawaited(_cancelActive('app-not-active'));
    }
  }

  void reportHeaderLayout(bool supported) {
    final current = _surface;
    if (current == null || current.headerLayoutSupported == supported) return;
    updateSurface(
      appActive: current.appActive,
      ledgerVisible: current.ledgerVisible,
      headerVisible: current.headerVisible,
      unobstructed: current.unobstructed,
      interactionIdle: current.interactionIdle,
      headerLayoutSupported: supported,
    );
  }

  Future<void> reconcile() async {
    final surface = _surface;
    if (surface == null || _evaluating || _presentation != null) return;
    _evaluating = true;
    final generation = ++_generation;
    final scope = DateTime.now();
    try {
      // The native decision remains useful to the Delivery Inspector even
      // while surface gates are closed. Reservation is only attempted here.
      final decision = await _repository.deliveryDecision(
        year: scope.year,
        month: scope.month,
        surface: surface,
      );
      if (generation != _generation || _presentation != null) return;
      if (decision.selected == null) return;
      final reservation = await _repository.reserveHeaderPresentation(
        year: scope.year,
        month: scope.month,
        surface: surface,
        commandKey:
            'automatic:$generation:${DateTime.now().microsecondsSinceEpoch}',
      );
      if (generation != _generation || reservation == null) return;
      _presentation = reservation;
      notifyListeners();
    } catch (_) {
      // Delivery is optional presentation. A bridge failure must not disturb
      // the dashboard or manufacture an in-memory shown state.
    } finally {
      _evaluating = false;
    }
  }

  Future<bool> presentationStarted(
    PulseHeaderPresentationReservation value,
  ) async {
    if (!identical(value, _presentation) &&
        value.attemptId != _presentation?.attemptId) {
      return false;
    }
    final accepted = await _repository.reportPresentationStarted(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
    );
    if (!accepted && value.attemptId == _presentation?.attemptId) {
      _clearPresentation();
    }
    return accepted;
  }

  Future<void> presented(PulseHeaderPresentationReservation value) async {
    if (value.attemptId != _presentation?.attemptId) return;
    final accepted = await _repository.reportPresented(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
    );
    if (!accepted || value.attemptId != _presentation?.attemptId) return;
    _presented = true;
    _armExposure(value);
    _armFinish(value);
  }

  /// A direct user tap while the Story is actually visible is a qualified
  /// interaction. It still verifies the native attempt token first.
  Future<void> confirmVisibleTap() async {
    final value = _presentation;
    if (value == null || !_isQualifiedSurface) return;
    await _repository.confirmQualifiedExposure(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
    );
  }

  Future<void> dismiss() async {
    final value = _presentation;
    if (value == null) return;
    await _repository.dismissStory(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
      commandKey: 'dismiss:${value.attemptId}',
    );
    _clearPresentation();
  }

  Future<void> cancelPresentation(
    PulseHeaderPresentationReservation value, {
    required String reason,
  }) async {
    if (value.attemptId != _presentation?.attemptId) return;
    await _repository.cancelPresentation(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
      reason: reason,
    );
    _clearPresentation();
  }

  Future<void> snooze(Duration duration) async {
    final value = _presentation;
    if (value == null) return;
    final until = DateTime.now().toUtc().add(duration).millisecondsSinceEpoch;
    await _repository.snoozeSituation(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
      untilUtcMs: until,
      commandKey: 'snooze:${value.attemptId}:$until',
    );
    _clearPresentation();
  }

  Future<void> muteCurrentTarget(String targetScope) async {
    await _repository.muteDeliveryTarget(
      targetScope: targetScope,
      commandKey: 'mute:$targetScope:${DateTime.now().microsecondsSinceEpoch}',
    );
    _clearPresentation();
  }

  Future<void> _cancelActive(String reason) async {
    final value = _presentation;
    if (value == null) return;
    await _repository.cancelPresentation(
      attemptId: value.attemptId,
      leaseToken: value.leaseToken,
      hostSessionId: _hostSessionId,
      contentFingerprint: value.story.contentFingerprint,
      reason: reason,
    );
    _clearPresentation();
  }

  void _armExposure(PulseHeaderPresentationReservation value) {
    _cancelExposureTimer();
    _exposureTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (value.attemptId != _presentation?.attemptId || !_isQualifiedSurface) {
        return;
      }
      await _repository.confirmQualifiedExposure(
        attemptId: value.attemptId,
        leaseToken: value.leaseToken,
        hostSessionId: _hostSessionId,
        contentFingerprint: value.story.contentFingerprint,
      );
    });
  }

  void _armFinish(PulseHeaderPresentationReservation value) {
    _finishTimer?.cancel();
    final duration = Duration(milliseconds: value.readableDurationMillis);
    _finishTimer = Timer(duration, () async {
      if (value.attemptId != _presentation?.attemptId) return;
      await _repository.finishPresentation(
        attemptId: value.attemptId,
        leaseToken: value.leaseToken,
        hostSessionId: _hostSessionId,
        contentFingerprint: value.story.contentFingerprint,
      );
      _clearPresentation();
    });
  }

  bool get _isQualifiedSurface {
    final value = _surface;
    return value != null &&
        value.appActive &&
        value.ledgerVisible &&
        value.headerVisible &&
        value.unobstructed &&
        value.interactionIdle &&
        value.headerLayoutSupported;
  }

  bool _wasQualified(PulseDeliverySurfaceContext? value) =>
      value != null &&
      value.appActive &&
      value.ledgerVisible &&
      value.headerVisible &&
      value.unobstructed &&
      value.interactionIdle &&
      value.headerLayoutSupported;

  void _cancelExposureTimer() {
    _exposureTimer?.cancel();
    _exposureTimer = null;
  }

  void _clearPresentation() {
    _cancelExposureTimer();
    _finishTimer?.cancel();
    _finishTimer = null;
    _presented = false;
    if (_presentation == null) return;
    _presentation = null;
    _generation++;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelExposureTimer();
    _finishTimer?.cancel();
    super.dispose();
  }
}
