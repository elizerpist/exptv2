import 'package:flutter/material.dart';

enum SpendeeDashboardMode { balance, balanceV2, budgetV2, budget, mind }

enum SpendeeDashboardModeFamily { balance, budget, mind }

extension SpendeeDashboardModeFamilyX on SpendeeDashboardMode {
  SpendeeDashboardModeFamily get family => switch (this) {
    SpendeeDashboardMode.balance ||
    SpendeeDashboardMode.balanceV2 => SpendeeDashboardModeFamily.balance,
    SpendeeDashboardMode.budget ||
    SpendeeDashboardMode.budgetV2 => SpendeeDashboardModeFamily.budget,
    SpendeeDashboardMode.mind => SpendeeDashboardModeFamily.mind,
  };
}

const spendeeBalanceFabGradient = LinearGradient(
  begin: Alignment(-0.905579787672639, -1.079227965339569),
  end: Alignment(0.905579787672639, 1.079227965339569),
  colors: <Color>[Color(0xFF6065F5), Color(0xFF8C5CEF), Color(0xFFF25CBF)],
  stops: <double>[0, 0.52, 1],
);

extension SpendeeDashboardModeFab on SpendeeDashboardMode {
  LinearGradient? get fabGradient => switch (this) {
    SpendeeDashboardMode.balance ||
    SpendeeDashboardMode.balanceV2 ||
    SpendeeDashboardMode.budgetV2 => spendeeBalanceFabGradient,
    SpendeeDashboardMode.budget || SpendeeDashboardMode.mind => null,
  };

  bool get usesBalanceShell => switch (this) {
    SpendeeDashboardMode.balance ||
    SpendeeDashboardMode.balanceV2 ||
    SpendeeDashboardMode.budgetV2 => true,
    SpendeeDashboardMode.budget || SpendeeDashboardMode.mind => false,
  };
}
