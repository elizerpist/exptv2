import 'package:flutter/material.dart';

import '../core/design/dashboard_mode_palette.dart';
import '../features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'shell/fluvi_app_shell.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({super.key, this.dashboardRepository});

  final DashboardLedgerRepository? dashboardRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: FluviVisualTokens.pageBackground),
      home: FluviAppShell(dashboardRepository: dashboardRepository),
    );
  }
}
