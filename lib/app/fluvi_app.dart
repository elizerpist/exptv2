import 'package:flutter/material.dart';

import '../core/design/dashboard_mode_palette.dart';
import '../features/dashboard/query/domain/ledger_direction.dart';
import '../features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import '../features/dashboard/time_navigation/domain/time_plane.dart';
import 'shell/fluvi_app_shell.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({
    super.key,
    this.dashboardRepository,
    this.initialDate,
    this.initialPlane = TimePlane.month,
    this.initialRailOpen = false,
    this.initialDirection = LedgerDirection.income,
  });

  final DashboardDataRuntimeRepository? dashboardRepository;
  final DateTime? initialDate;
  final TimePlane initialPlane;
  final bool initialRailOpen;
  final LedgerDirection initialDirection;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: FluviVisualTokens.pageBackground),
      home: FluviAppShell(
        dashboardRepository: dashboardRepository,
        initialDate: initialDate,
        initialPlane: initialPlane,
        initialRailOpen: initialRailOpen,
        initialDirection: initialDirection,
      ),
    );
  }
}
