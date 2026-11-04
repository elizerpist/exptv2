import 'package:flutter/material.dart';

import '../core/categories/domain/category_repository.dart';
import '../core/financial_limits/domain/financial_limit_repository.dart';
import '../core/design/dashboard_mode_palette.dart';
import '../features/dashboard/query/domain/ledger_direction.dart';
import '../features/dashboard/application/dashboard_presentation_preferences.dart';
import '../features/dashboard/application/dashboard_mode_spec.dart';
import '../features/dashboard/presentation/dashboard_shell_presentation.dart';
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
    this.initialMode = DashboardModeSpec.balance,
    this.initialPlane = TimePlane.month,
    this.initialRailOpen = false,
    this.initialDirection = LedgerDirection.income,
    this.shellPresentation,
    this.initialDashboardPresentationPreferences,
  });

  final DashboardDataRuntimeRepository? dashboardRepository;
  final CategoryRepository? categoryRepository;
  final FinancialLimitRepository? financialLimitRepository;
  final QueryMenuRepository? queryRepository;
  final DateTime? initialDate;
  final DashboardModeSpec initialMode;
  final TimePlane initialPlane;
  final bool initialRailOpen;
  final LedgerDirection initialDirection;

  /// Optional explicit shell presentation owner for an embedding host. The
  /// normal application shell retains its session-local owner when omitted.
  final DashboardShellPresentationController? shellPresentation;
  final DashboardPresentationPreferences?
  initialDashboardPresentationPreferences;

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
        mode: initialMode,
        initialPlane: initialPlane,
        initialRailOpen: initialRailOpen,
        initialDirection: initialDirection,
        shellPresentation: shellPresentation,
        initialDashboardPresentationPreferences:
            initialDashboardPresentationPreferences,
      ),
    );
  }
}
