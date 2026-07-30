part of '../spendee_test_dashboard.dart';

class SpendeeBudgetModeHost extends StatelessWidget {
  const SpendeeBudgetModeHost._({super.key, required dashboard})
    : _dashboard = dashboard;

  final _SpendeeTestDashboardState _dashboard;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-budget'),
      child: _dashboard._dashboardMode == SpendeeDashboardMode.budgetV2
          ? _dashboard._budgetV2Dashboard(refresh: true)
          : _dashboard._buildLegacyModeContent(context),
    );
  }
}
