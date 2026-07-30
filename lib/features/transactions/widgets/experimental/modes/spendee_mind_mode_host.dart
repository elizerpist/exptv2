part of '../spendee_test_dashboard.dart';

class SpendeeMindModeHost extends StatelessWidget {
  const SpendeeMindModeHost._({super.key, required dashboard})
    : _dashboard = dashboard;

  final _SpendeeTestDashboardState _dashboard;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-mind'),
      child: _dashboard._buildLegacyModeContent(context),
    );
  }
}
