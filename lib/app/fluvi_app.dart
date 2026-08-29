import 'package:flutter/material.dart';

import '../core/categories/domain/category_repository.dart';
import '../core/financial_limits/domain/financial_limit_repository.dart';
import '../core/design/dashboard_mode_palette.dart';
import '../features/dashboard/query/domain/ledger_direction.dart';
import '../features/dashboard/query/data/query_menu_repository.dart';
import '../features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import '../features/dashboard/time_navigation/domain/time_plane.dart';
import 'shell/fluvi_app_shell.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({
    super.key,
    this.dashboardRepository,
    this.categoryRepository,
    this.financialLimitRepository,
    this.queryRepository,
    this.initialDate,
    this.initialPlane = TimePlane.month,
    this.initialRailOpen = false,
    this.initialDirection = LedgerDirection.income,
  });

  final DashboardDataRuntimeRepository? dashboardRepository;
  final CategoryRepository? categoryRepository;
  final FinancialLimitRepository? financialLimitRepository;
  final QueryMenuRepository? queryRepository;
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
        categoryRepository: categoryRepository,
        financialLimitRepository: financialLimitRepository,
        queryRepository: queryRepository,
        initialDate: initialDate,
        initialPlane: initialPlane,
        initialRailOpen: initialRailOpen,
        initialDirection: initialDirection,
      ),
    );
  }
}
