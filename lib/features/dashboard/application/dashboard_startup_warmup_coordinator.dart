import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dashboard_parent_display_bundle.dart';

enum DashboardStartupWarmupPhase {
  idle,
  interactiveShell,
  currentBundleReady,
  categoryAssets,
  adjacentBundles,
  complete,
}

/// Sequences non-critical dashboard startup work without putting it in widgets.
///
/// Phase 0 is published as soon as the shell can render. The current finite
/// bundle remains the only blocking data phase; SVG and adjacent-parent work
/// wait for rail/header motion to be idle and never mutate displayed state.
class DashboardStartupWarmupCoordinator extends ChangeNotifier {
  DashboardStartupWarmupCoordinator({
    required Future<DashboardParentDisplayBundle> Function()
    ensureCurrentBundle,
    required Future<void> Function(DashboardParentDisplayBundle bundle)
    warmCurrentAndAdjacentCategoryAssets,
    required Future<void> Function(DashboardParentDisplayBundle bundle)
    prewarmAdjacentBundles,
    required bool Function() isCriticalMotionActive,
    required Listenable motionListenable,
  }) : _ensureCurrentBundle = ensureCurrentBundle,
       _warmCurrentAndAdjacentCategoryAssets =
           warmCurrentAndAdjacentCategoryAssets,
       _prewarmAdjacentBundles = prewarmAdjacentBundles,
       _isCriticalMotionActive = isCriticalMotionActive,
       _motionListenable = motionListenable;

  final Future<DashboardParentDisplayBundle> Function() _ensureCurrentBundle;
  final Future<void> Function(DashboardParentDisplayBundle bundle)
  _warmCurrentAndAdjacentCategoryAssets;
  final Future<void> Function(DashboardParentDisplayBundle bundle)
  _prewarmAdjacentBundles;
  final bool Function() _isCriticalMotionActive;
  final Listenable _motionListenable;

  DashboardStartupWarmupPhase _phase = DashboardStartupWarmupPhase.idle;
  Future<void>? _running;
  Completer<void>? _idleWaiter;
  bool _disposed = false;

  DashboardStartupWarmupPhase get phase => _phase;

  Future<void> start() => _running ??= _run();

  Future<void> _run() async {
    _setPhase(DashboardStartupWarmupPhase.interactiveShell);
    final current = await _ensureCurrentBundle();
    if (_disposed) return;
    _setPhase(DashboardStartupWarmupPhase.currentBundleReady);

    await _waitForIdle();
    if (_disposed) return;
    _setPhase(DashboardStartupWarmupPhase.categoryAssets);
    await _warmCurrentAndAdjacentCategoryAssets(current);
    if (_disposed) return;

    await _waitForIdle();
    if (_disposed) return;
    _setPhase(DashboardStartupWarmupPhase.adjacentBundles);
    await _prewarmAdjacentBundles(current);
    if (_disposed) return;
    _setPhase(DashboardStartupWarmupPhase.complete);
  }

  Future<void> _waitForIdle() {
    if (!_isCriticalMotionActive()) return Future<void>.value();
    final waiter = Completer<void>();
    _idleWaiter = waiter;
    void listener() {
      if (_isCriticalMotionActive() || waiter.isCompleted) return;
      _motionListenable.removeListener(listener);
      if (identical(_idleWaiter, waiter)) _idleWaiter = null;
      waiter.complete();
    }

    _motionListenable.addListener(listener);
    listener();
    return waiter.future;
  }

  void _setPhase(DashboardStartupWarmupPhase value) {
    if (_phase == value) return;
    _phase = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _idleWaiter?.complete();
    _idleWaiter = null;
    super.dispose();
  }
}
