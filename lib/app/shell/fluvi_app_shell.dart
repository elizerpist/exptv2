import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../debug/demo_seed_coordinator.dart';
import '../../core/assets/prepared_vector_asset_atlas.dart';
import '../../core/design/dashboard_mode_palette.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/diagnostics/fluvi_diagnostic_bridge.dart';
import '../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../core/demo_data/demo_data_bridge.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_bootstrap_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import '../../features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import '../../features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import '../../features/dashboard/runtime/data/method_channel_dashboard_data_runtime_repository.dart';
import 'bnb03_bottom_navigation.dart';
import 'fluvi_fullscreen_button.dart';

class _BottomNavigationSafeArea extends StatelessWidget {
  const _BottomNavigationSafeArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomInset,
          child: const ColoredBox(
            key: ValueKey('fluvi-bottom-safe-area-background'),
            color: Colors.white,
          ),
        ),
        SafeArea(top: false, child: child),
      ],
    );
  }
}

/// Root owner for the one dashboard controller lifecycle in this UI slice.
class FluviAppShell extends StatefulWidget {
  const FluviAppShell({
    super.key,
    this.mode = DashboardModeSpec.balance,
    this.dashboardRepository,
    this.initialDate,
  });

  final DashboardModeSpec mode;
  final DashboardDataRuntimeRepository? dashboardRepository;
  final DateTime? initialDate;

  @override
  State<FluviAppShell> createState() => _FluviAppShellState();
}

class _DashboardBootstrapSurface extends StatelessWidget {
  const _DashboardBootstrapSurface();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey('dashboard-bootstrap-surface'),
      color: FluviVisualTokens.pageBackground,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DashboardBootstrapFailureSurface extends StatelessWidget {
  const _DashboardBootstrapFailureSurface({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('dashboard-bootstrap-failure-surface'),
    color: FluviVisualTokens.pageBackground,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A dashboard adatai nem tölthetők be.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('dashboard-bootstrap-retry'),
              onPressed: onRetry,
              child: const Text('Újrapróbálás'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FluviAppShellState extends State<FluviAppShell> {
  late final DashboardCoreController _controller;
  late final DashboardBootstrapController _bootstrap;
  late final bool _seedDemo;
  Future<void>? _startupFlow;
  StreamSubscription? _diagnosticSubscription;
  Bnb03Item _selectedNavigationItem = Bnb03Item.home;

  @override
  void initState() {
    super.initState();
    _seedDemo =
        !kIsWeb && kDebugMode && const bool.fromEnvironment('FLUVI_SEED_DEMO');
    final repository = kIsWeb
        ? const EmptyDashboardDataRuntimeRepository()
        : widget.dashboardRepository ??
              MethodChannelDashboardDataRuntimeRepository();
    _controller = DashboardCoreController(
      dataRepository: repository,
      initialDate: widget.initialDate,
      seedReady: !_seedDemo,
    );
    _bootstrap = DashboardBootstrapController(
      preparePresentationAssets: PreparedVectorAssetAtlas.instance.prepare,
      bootstrap: _controller.bootstrap,
    );
    if (kDebugMode && !kIsWeb) {
      _diagnosticSubscription = FluviDiagnosticBridge().watch().listen(
        FluviDiagnosticLogger.log,
      );
    }
    unawaited(_startDashboard());
  }

  Future<void> _startDashboard() {
    final existing = _startupFlow;
    if (existing != null) return existing;
    late final Future<void> operation;
    operation = _runDashboardStartup().whenComplete(() {
      if (identical(_startupFlow, operation)) _startupFlow = null;
    });
    _startupFlow = operation;
    return operation;
  }

  Future<void> _runDashboardStartup() async {
    if (_seedDemo) {
      try {
        await DemoSeedCoordinator(
          bridge: const MethodChannelDemoDataBridge(),
          timeNavigation: _controller.navigation,
        ).seedAndNavigate();
        _controller.markSeedCommitted();
      } on Object catch (error) {
        debugPrint('[FluviDemoSeed] failed: $error');
        _bootstrap.fail(error);
        return;
      }
    }
    await _bootstrap.start();
  }

  @override
  void dispose() {
    _diagnosticSubscription?.cancel();
    _diagnosticSubscription = null;
    _bootstrap.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('fluvi-app-shell'),
      extendBody: true,
      backgroundColor: FluviVisualTokens.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bootstrap,
            builder: (context, _) => switch (_bootstrap.phase) {
              DashboardBootstrapPhase.ready => CoreDashboard(
                mode: widget.mode,
                controller: _controller,
              ),
              DashboardBootstrapPhase.failed =>
                _DashboardBootstrapFailureSurface(
                  onRetry: () => unawaited(_startDashboard()),
                ),
              _ => const _DashboardBootstrapSurface(),
            },
          ),
          const Positioned(
            top: 12,
            right: 12,
            child: SafeArea(bottom: false, child: FluviFullscreenButton()),
          ),
          if (kDebugMode) const DebugFloatingButton(),
        ],
      ),
      bottomNavigationBar: _BottomNavigationSafeArea(
        child: Bnb03BottomNavigation(
          selected: _selectedNavigationItem,
          onChanged: (item) {
            setState(() => _selectedNavigationItem = item);
          },
        ),
      ),
    );
  }
}
