import 'package:flutter/foundation.dart';

enum DashboardMode { balance, budget, mind }

enum DashboardSubheaderComposition { split, unified }

/// Immutable variation points for the common dashboard layout and behavior.
@immutable
class DashboardModeSpec {
  const DashboardModeSpec({
    required this.mode,
    required this.subheaderComposition,
  });

  static const balance = DashboardModeSpec(
    mode: DashboardMode.balance,
    subheaderComposition: DashboardSubheaderComposition.split,
  );
  static const budget = DashboardModeSpec(
    mode: DashboardMode.budget,
    subheaderComposition: DashboardSubheaderComposition.split,
  );
  static const mind = DashboardModeSpec(
    mode: DashboardMode.mind,
    subheaderComposition: DashboardSubheaderComposition.unified,
  );

  static const values = <DashboardModeSpec>[balance, budget, mind];

  final DashboardMode mode;
  final DashboardSubheaderComposition subheaderComposition;
}
