import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import 'fluvi_bottom_navigation.dart';

/// Root owner for the one dashboard controller lifecycle in this UI slice.
class FluviAppShell extends StatefulWidget {
  const FluviAppShell({super.key, this.mode = DashboardModeSpec.balance});

  final DashboardModeSpec mode;

  @override
  State<FluviAppShell> createState() => _FluviAppShellState();
}

class _FluviAppShellState extends State<FluviAppShell> {
  late final DashboardCoreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardCoreController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('fluvi-app-shell'),
      color: FluviVisualTokens.pageBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CoreDashboard(mode: widget.mode, controller: _controller),
          Align(
            alignment: Alignment.bottomCenter,
            child: FluviBottomNavigation(onDashboardTap: _dashboardTap),
          ),
        ],
      ),
    );
  }

  static void _dashboardTap() {}
}
