import 'package:flutter/material.dart';

enum SpendeeDashboardMode { balance, budgetV2, budget, mind }

const spendeeBalanceFabGradient = LinearGradient(
  begin: Alignment(-0.905579787672639, -1.079227965339569),
  end: Alignment(0.905579787672639, 1.079227965339569),
  colors: <Color>[Color(0xFF6065F5), Color(0xFF8C5CEF), Color(0xFFF25CBF)],
  stops: <double>[0, 0.52, 1],
);

extension SpendeeDashboardModeFab on SpendeeDashboardMode {
  LinearGradient? get fabGradient => switch (this) {
    SpendeeDashboardMode.balance ||
    SpendeeDashboardMode.budgetV2 => spendeeBalanceFabGradient,
    SpendeeDashboardMode.budget || SpendeeDashboardMode.mind => null,
  };

  bool get usesBalanceShell => switch (this) {
    SpendeeDashboardMode.balance || SpendeeDashboardMode.budgetV2 => true,
    SpendeeDashboardMode.budget || SpendeeDashboardMode.mind => false,
  };
}
