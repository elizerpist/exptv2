import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../debug/demo_seed_coordinator.dart';
import '../../core/design/dashboard_mode_palette.dart';
import '../../core/debug/debug_floating_button.dart';
import '../../core/diagnostics/fluvi_diagnostic_bridge.dart';
import '../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../core/demo_data/demo_data_bridge.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_bootstrap_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import '../../features/dashboard/query/data/dashboard_ledger_repository.dart';
import '../../features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart';
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
  });

  final DashboardModeSpec mode;
  final DashboardLedgerRepository? dashboardRepository;

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

class _FluviAppShellState extends State<FluviAppShell> {
  late final DashboardCoreController _controller;
  late final DashboardBootstrapController _bootstrap;
  StreamSubscription? _diagnosticSubscription;
  Bnb03Item _selectedNavigationItem = Bnb03Item.home;

  @override
  void initState() {
    super.initState();
    final seedDemo =
        !kIsWeb && kDebugMode && const bool.fromEnvironment('FLUVI_SEED_DEMO');
    _controller = DashboardCoreController(
      queryRepository: kIsWeb
          ? const EmptyDashboardLedgerRepository()
          : widget.dashboardRepository ??
                MethodChannelDashboardLedgerRepository(),
      liveQueryLeaseQuiescence: const Duration(milliseconds: 120),
      autoStartQuery: false,
    );
    _bootstrap = DashboardBootstrapController(
      store: _controller.presentationStore,
      readInitialBundle: _controller.readParentDisplayBundleForBootstrap,
    );
    if (kDebugMode && !kIsWeb) {
      _diagnosticSubscription = FluviDiagnosticBridge().watch().listen(
        FluviDiagnosticLogger.log,
      );
    }
    if (seedDemo) {
      unawaited(
        DemoSeedCoordinator(
          bridge: const MethodChannelDemoDataBridge(),
          timeNavigation: _controller.rail,
        ).seedAndNavigate().then<void>(
          (_) {
            _controller.startQuery(reason: 'postSeed');
            return _bootstrap.start();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('[FluviDemoSeed] failed: $error');
          },
        ),
      );
    } else {
      unawaited(_bootstrap.start());
    }
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
            builder: (context, _) => _bootstrap.isReady
                ? CoreDashboard(mode: widget.mode, controller: _controller)
                : const _DashboardBootstrapSurface(),
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
