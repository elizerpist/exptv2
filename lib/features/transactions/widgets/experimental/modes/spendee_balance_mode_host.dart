part of '../spendee_test_dashboard.dart';

class SpendeeBalanceModeHost extends StatelessWidget {
  const SpendeeBalanceModeHost._({super.key, required dashboard})
    : _dashboard = dashboard;

  final _SpendeeTestDashboardState _dashboard;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-balance'),
      child: switch (_dashboard._dashboardMode) {
        SpendeeDashboardMode.balance => _dashboard._balanceDashboard(
          refresh: true,
        ),
        SpendeeDashboardMode.balanceV2 => _dashboard._balanceV2Dashboard(
          refresh: true,
        ),
        _ => throw StateError('Balance host received a non-Balance variant.'),
      },
    );
  }
}
