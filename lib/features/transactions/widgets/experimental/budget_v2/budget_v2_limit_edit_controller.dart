import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

typedef BudgetV2LimitPersistCallback =
    void Function(String avatarKey, double amount, int operationId);
typedef BudgetV2LimitOperationIdAllocator = int Function();

class BudgetV2LimitEditController extends ChangeNotifier {
  BudgetV2LimitEditController({
    required BudgetV2LimitOperationIdAllocator allocateOperationId,
    required BudgetV2LimitPersistCallback onPersist,
  }) : _allocateOperationId = allocateOperationId,
       _onPersist = onPersist;

  static const veryLongPressDelay = Duration(milliseconds: 720);

  final BudgetV2LimitOperationIdAllocator _allocateOperationId;
  final BudgetV2LimitPersistCallback _onPersist;
  final Map<String, double> _pendingPreviewAmounts = <String, double>{};
  final Map<String, int> _pendingPreviewOperationIds = <String, int>{};
  final Map<String, int> _latestOperationIds = <String, int>{};
  final Set<int> _successfulOperationIds = <int>{};

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
      persist(avatarKey, previewAmount(avatarKey, fallback: 0));
    }
    final pendingOperationId = _pendingPreviewOperationIds[avatarKey];
    _clearSession();
    if (pendingOperationId != null) {
      _releaseSuccessfulPreview(avatarKey, pendingOperationId);
    }
    notifyListeners();
  }

  void cancel() {
    final avatarKey = _activeAvatarKey;
    final baseline = _sessionBaselineAmount;
    final pendingOperationId = avatarKey == null
        ? null
        : _pendingPreviewOperationIds[avatarKey];
    if (!_clearedByVeryLongPress && avatarKey != null && baseline != null) {
      _pendingPreviewAmounts[avatarKey] = baseline;
    }
    finish(persistFinal: false);
    if (avatarKey != null &&
        pendingOperationId == null &&
        !_pendingPreviewOperationIds.containsKey(avatarKey) &&
        _pendingPreviewAmounts.remove(avatarKey) != null) {
      notifyListeners();
    }
  }

  /// Starts one monotonic write and binds an existing preview to its exact ID.
  ///
  /// Inline edits also enter through this method. They receive an operation ID
  /// without creating a second preview owner.
  void persist(String avatarKey, double amount) {
    if (_disposed) return;
    final operationId = _allocateOperationId();
    final normalized = _normalizeAmount(amount);
    final previousOperationId = _pendingPreviewOperationIds[avatarKey];
    if (previousOperationId != null) {
      _successfulOperationIds.remove(previousOperationId);
    }
    _latestOperationIds[avatarKey] = operationId;
    if (_pendingPreviewAmounts.containsKey(avatarKey)) {
      _pendingPreviewAmounts[avatarKey] = normalized;
      _pendingPreviewOperationIds[avatarKey] = operationId;
    }
    _onPersist(avatarKey, normalized, operationId);
  }

  void acknowledgePersisted(String avatarKey, {required int operationId}) {
    if (_disposed || _latestOperationIds[avatarKey] != operationId) return;
    if (_pendingPreviewOperationIds[avatarKey] != operationId) {
      _latestOperationIds.remove(avatarKey);
      return;
    }
    if (_activeAvatarKey == avatarKey) {
      _successfulOperationIds.add(operationId);
      return;
    }
    if (!_releasePreview(avatarKey, operationId)) return;
    notifyListeners();
  }

  bool _releaseSuccessfulPreview(String avatarKey, int operationId) {
    if (!_successfulOperationIds.remove(operationId)) return false;
    return _releasePreview(avatarKey, operationId);
  }

  bool _releasePreview(String avatarKey, int operationId) {
    if (_pendingPreviewOperationIds[avatarKey] != operationId) return false;
    _pendingPreviewAmounts.remove(avatarKey);
    _pendingPreviewOperationIds.remove(avatarKey);
    if (_latestOperationIds[avatarKey] == operationId) {
      _latestOperationIds.remove(avatarKey);
    }
    return true;
  }

  void reset() {
    if (_disposed) return;
    final hadState = isEditing || _pendingPreviewAmounts.isNotEmpty;
    _cancelTimers();
    _clearSession();
    _pendingPreviewAmounts.clear();
    _pendingPreviewOperationIds.clear();
    _latestOperationIds.clear();
    _successfulOperationIds.clear();
    if (hadState) notifyListeners();
  }

  void _clearActiveLimit() {
    if (_disposed) return;
    final avatarKey = _activeAvatarKey;
    if (avatarKey == null || _lastDy.abs() > 5) return;
    _clearedByVeryLongPress = true;
    _autoTickTimer?.cancel();
    _autoTickTimer = null;
    _setPreview(avatarKey, 0);
    persist(avatarKey, 0);
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
    final normalized = _normalizeAmount(amount);
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

  static double _normalizeAmount(double amount) =>
      amount <= 0 ? 0.0 : (amount / 1000).round() * 1000.0;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimers();
    _clearSession();
    _pendingPreviewAmounts.clear();
    _pendingPreviewOperationIds.clear();
    _latestOperationIds.clear();
    _successfulOperationIds.clear();
    super.dispose();
  }
}
