import 'package:flutter/material.dart';

import '../core/design/dashboard_mode_palette.dart';
import '../features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'shell/fluvi_app_shell.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({super.key, this.dashboardRepository, this.initialDate});

  final DashboardPreparedDeckRepository? dashboardRepository;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: FluviVisualTokens.pageBackground),
      home: FluviAppShell(
        dashboardRepository: dashboardRepository,
        initialDate: initialDate,
      ),
    );
  }
}
