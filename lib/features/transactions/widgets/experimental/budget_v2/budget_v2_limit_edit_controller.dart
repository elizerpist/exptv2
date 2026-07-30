import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

typedef BudgetV2LimitPersistCallback =
    void Function(String avatarKey, double amount);

class BudgetV2LimitEditController extends ChangeNotifier {
  BudgetV2LimitEditController({required BudgetV2LimitPersistCallback onPersist})
    : _onPersist = onPersist;

  static const veryLongPressDelay = Duration(milliseconds: 720);

  final BudgetV2LimitPersistCallback _onPersist;
  final Map<String, double> _pendingPreviewAmounts = <String, double>{};

  Timer? _clearTimer;
  Timer? _autoTickTimer;
  String? _activeAvatarKey;
  double? _activationGlobalY;
  var _lastDy = 0.0;
  var _dragAccumulator = 0.0;
  double? _sessionBaselineAmount;
  var _clearedByVeryLongPress = false;
  var _disposed = false;

  bool get isEditing => _activeAvatarKey != null;
  String? get activeAvatarKey => _activeAvatarKey;
  Map<String, double> get pendingPreviewAmounts =>
      Map<String, double>.unmodifiable(_pendingPreviewAmounts);

  double previewAmount(String avatarKey, {required double fallback}) =>
      _pendingPreviewAmounts[avatarKey] ?? fallback;

  void begin({
    required String avatarKey,
    required double initialAmount,
    required double globalY,
  }) {
    if (_disposed) return;
    _cancelTimers();
    _activeAvatarKey = avatarKey;
    _activationGlobalY = globalY;
    _lastDy = 0;
    _dragAccumulator = 0;
    _clearedByVeryLongPress = false;
    _sessionBaselineAmount = math.max(0, initialAmount).toDouble();
    _pendingPreviewAmounts[avatarKey] = _sessionBaselineAmount!;
    _clearTimer = Timer(veryLongPressDelay, _clearActiveLimit);
    notifyListeners();
  }

  void update({required double globalY}) {
    if (_disposed || _clearedByVeryLongPress) return;
    final avatarKey = _activeAvatarKey;
    final activationGlobalY = _activationGlobalY;
    if (avatarKey == null || activationGlobalY == null) return;
    final dy = globalY - activationGlobalY;
    final delta = dy - _lastDy;
    _lastDy = dy;
    if (dy.abs() > 5) {
      _clearTimer?.cancel();
      _clearTimer = null;
    }
    _dragAccumulator += -delta;
    _drainDragTicks(avatarKey, distance: dy.abs());
    _scheduleAutoTick(avatarKey);
  }

  void finish({bool persistFinal = true}) {
    if (_disposed) return;
    _clearTimer?.cancel();
    _clearTimer = null;
    _autoTickTimer?.cancel();
    _autoTickTimer = null;
    final avatarKey = _activeAvatarKey;
    if (avatarKey == null) return;
    if (persistFinal && !_clearedByVeryLongPress) {
      _onPersist(avatarKey, previewAmount(avatarKey, fallback: 0));
    }
    _clearSession();
    notifyListeners();
  }

  void cancel() {
    final avatarKey = _activeAvatarKey;
    final baseline = _sessionBaselineAmount;
    if (avatarKey != null && baseline != null) {
      _pendingPreviewAmounts[avatarKey] = baseline;
    }
    finish(persistFinal: false);
  }

  void _clearActiveLimit() {
    if (_disposed) return;
    final avatarKey = _activeAvatarKey;
    if (avatarKey == null || _lastDy.abs() > 5) return;
    _clearedByVeryLongPress = true;
    _autoTickTimer?.cancel();
    _autoTickTimer = null;
    _setPreview(avatarKey, 0);
    _onPersist(avatarKey, 0);
  }

  void _drainDragTicks(String avatarKey, {required double distance}) {
    final largeStep = distance >= 50;
    final tickDistance = largeStep ? 18.0 : 12.0;
    final amountStep = largeStep ? 10000.0 : 1000.0;
    final direction = _dragAccumulator > 0 ? 1 : -1;
    final tickCount = (_dragAccumulator.abs() / tickDistance).floor();
    if (tickCount < 1) return;
    _dragAccumulator -= direction * tickDistance * tickCount;
    _applyTick(
      avatarKey,
      direction: direction,
      amountStep: amountStep,
      tickCount: tickCount,
    );
  }

  void _scheduleAutoTick(String avatarKey) {
    _autoTickTimer?.cancel();
    _autoTickTimer = null;
    if (_activeAvatarKey != avatarKey) return;
    final distance = _lastDy.abs();
    if (distance < 14) return;
    final intervalMs = (440 - distance * 5.2).clamp(80.0, 440.0).round();
    _autoTickTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (_disposed || _activeAvatarKey != avatarKey) return;
      _applyTick(
        avatarKey,
        direction: _lastDy < 0 ? 1 : -1,
        amountStep: _lastDy.abs() >= 50 ? 10000 : 1000,
        tickCount: 1,
      );
      _scheduleAutoTick(avatarKey);
    });
  }

  void _applyTick(
    String avatarKey, {
    required int direction,
    required double amountStep,
    required int tickCount,
  }) {
    final current = previewAmount(avatarKey, fallback: 0);
    final next = math
        .max(0, current + direction * amountStep * tickCount)
        .toDouble();
    _setPreview(avatarKey, next);
  }

  void _setPreview(String avatarKey, double amount) {
    final normalized = amount <= 0 ? 0.0 : (amount / 1000).round() * 1000.0;
    if (_pendingPreviewAmounts[avatarKey] == normalized) return;
    _pendingPreviewAmounts[avatarKey] = normalized;
    notifyListeners();
  }

  void _cancelTimers() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _autoTickTimer?.cancel();
    _autoTickTimer = null;
  }

  void _clearSession() {
    _activeAvatarKey = null;
    _activationGlobalY = null;
    _lastDy = 0;
    _dragAccumulator = 0;
    _sessionBaselineAmount = null;
    _clearedByVeryLongPress = false;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimers();
    _clearSession();
    super.dispose();
  }
}
