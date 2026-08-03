import 'dart:async';

import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/query/application/dashboard_query_debug.dart';

/// The application bootstrap boundary for seed -> display deck -> live lease.
///
/// UI owns only rendering the returned controller. In particular, it never
/// starts a dashboard query while a debug seed transaction is still running.
class DashboardAppBootstrapCoordinator {
  DashboardAppBootstrapCoordinator({
    required this.createController,
    this.seedDemo,
    DateTime? demoInitialDate,
    this.displayBootstrapTimeout = const Duration(seconds: 5),
  }) : demoInitialDate = demoInitialDate ?? DateTime(2026, 7, 3);

  final DashboardCoreController Function({
    required DateTime? initialDate,
    required bool autoStart,
  })
  createController;
  final Future<void> Function()? seedDemo;
  final DateTime demoInitialDate;
  final Duration displayBootstrapTimeout;

  Timer? _displayBootstrapTimer;
  Completer<void>? _cancellation;
  bool _cancelled = false;

  /// Cancels only this coordinator's bounded bootstrap wait.
  ///
  /// The native operation itself may be non-cancellable, but after the shell
  /// is disposed its result is neither retained nor allowed to create a
  /// fallback controller. Cancelling the owned timer is essential for widget
  /// teardown as well as real navigation away from this shell.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _displayBootstrapTimer?.cancel();
    _displayBootstrapTimer = null;
    _cancellation?.complete();
  }

  Future<DashboardAppBootstrapResult?> bootstrap() async {
    if (_cancelled) return null;
    final shouldSeed = seedDemo != null;
    DashboardQueryDebug.mark(
      'BOOTSTRAP_STARTED',
      detail: 'demoSeed=$shouldSeed',
    );
    if (shouldSeed) {
      await seedDemo!.call();
      if (_cancelled) return null;
      DashboardQueryDebug.mark(
        'BOOTSTRAP_SEED_READY',
        detail:
            'initialScope=month:${demoInitialDate.year.toString().padLeft(4, '0')}-${demoInitialDate.month.toString().padLeft(2, '0')}',
      );
    }

    DashboardCoreController? controller;
    try {
      controller = createController(
        initialDate: shouldSeed ? demoInitialDate : null,
        autoStart: false,
      );
      final cancellation = Completer<void>();
      _cancellation = cancellation;
      final timeout = Completer<void>();
      _displayBootstrapTimer = Timer(displayBootstrapTimeout, () {
        timeout.completeError(
          TimeoutException('Initial dashboard display bootstrap timed out.'),
        );
      });
      try {
        await Future.any<void>([
          controller.bootstrapInitialDisplay(),
          timeout.future,
          cancellation.future,
        ]);
      } finally {
        _displayBootstrapTimer?.cancel();
        _displayBootstrapTimer = null;
        _cancellation = null;
      }
      if (_cancelled) {
        controller.dispose();
        return null;
      }
      return DashboardAppBootstrapResult.ready(controller);
    } on Object catch (error) {
      controller?.dispose();
      if (_cancelled) return null;
      DashboardQueryDebug.mark('BOOTSTRAP_FAILED', detail: 'error=$error');
      // Retain a usable legacy cold path for a native transport failure. This
      // is never entered for the normal seed/bootstrap sequence.
      return DashboardAppBootstrapResult.fallback(
        controller: createController(initialDate: null, autoStart: true),
        bootstrapError: error,
      );
    }
  }
}

class DashboardAppBootstrapResult {
  const DashboardAppBootstrapResult._({
    required this.controller,
    required this.usedFallback,
    this.bootstrapError,
  });

  factory DashboardAppBootstrapResult.ready(
    DashboardCoreController controller,
  ) => DashboardAppBootstrapResult._(
    controller: controller,
    usedFallback: false,
  );

  factory DashboardAppBootstrapResult.fallback({
    required DashboardCoreController controller,
    required Object bootstrapError,
  }) => DashboardAppBootstrapResult._(
    controller: controller,
    usedFallback: true,
    bootstrapError: bootstrapError,
  );

  final DashboardCoreController controller;
  final bool usedFallback;
  final Object? bootstrapError;
}
