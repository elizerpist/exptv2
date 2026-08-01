import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/presentation/core_dashboard.dart';
import 'bnb03_bottom_navigation.dart';
import 'fluvi_fullscreen_button.dart';

/// Root owner for the one dashboard controller lifecycle in this UI slice.
class FluviAppShell extends StatefulWidget {
  const FluviAppShell({super.key, this.mode = DashboardModeSpec.balance});

  final DashboardModeSpec mode;

  @override
  State<FluviAppShell> createState() => _FluviAppShellState();
}

class _FluviAppShellState extends State<FluviAppShell> {
  late final DashboardCoreController _controller;
  Bnb03Item _selectedNavigationItem = Bnb03Item.home;

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
    return Scaffold(
      key: const ValueKey('fluvi-app-shell'),
      extendBody: true,
      backgroundColor: FluviVisualTokens.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CoreDashboard(mode: widget.mode, controller: _controller),
          const Positioned(
            top: 12,
            right: 12,
            child: SafeArea(bottom: false, child: FluviFullscreenButton()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
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
