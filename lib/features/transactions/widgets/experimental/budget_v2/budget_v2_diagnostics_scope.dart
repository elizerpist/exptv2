import 'package:flutter/widgets.dart';

/// Presentation policy for legacy visual leaves that still own chart traces.
/// The standalone route disables them without changing legacy contracts.
class BudgetV2DiagnosticsScope extends InheritedWidget {
  const BudgetV2DiagnosticsScope({
    super.key,
    required this.allowLegacyChartDiagnostics,
    required super.child,
  });

  final bool allowLegacyChartDiagnostics;

  static bool allowsLegacyChart(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BudgetV2DiagnosticsScope>()
          ?.allowLegacyChartDiagnostics ??
      true;

  @override
  bool updateShouldNotify(BudgetV2DiagnosticsScope oldWidget) =>
      oldWidget.allowLegacyChartDiagnostics != allowLegacyChartDiagnostics;
}
