part of '../spendee_test_dashboard.dart';

class SpendeeBalanceModeHost extends StatefulWidget {
  const SpendeeBalanceModeHost._({
    super.key,
    required _SpendeeTestDashboardState dashboard,
    required SpendeeDashboardMode variant,
    required Object cacheRevision,
  }) : _dashboard = dashboard,
       _variant = variant,
       _cacheRevision = cacheRevision;

  final _SpendeeTestDashboardState _dashboard;
  final SpendeeDashboardMode _variant;
  final Object _cacheRevision;

  @override
  State<SpendeeBalanceModeHost> createState() => _SpendeeBalanceModeHostState();
}

class _SpendeeBalanceModeHostState extends State<SpendeeBalanceModeHost> {
  Widget? _balanceDashboardCache;
  Widget? _balanceV2DashboardCache;

  @override
  void didUpdateWidget(covariant SpendeeBalanceModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._variant != widget._variant ||
        oldWidget._dashboard != widget._dashboard ||
        oldWidget._cacheRevision != widget._cacheRevision) {
      _clearDashboardCaches();
    }
  }

  @override
  void dispose() {
    _clearDashboardCaches();
    super.dispose();
  }

  void _clearDashboardCaches() {
    _balanceDashboardCache = null;
    _balanceV2DashboardCache = null;
  }

  Widget _balanceDashboard({required bool refresh}) {
    final cached = _balanceDashboardCache;
    if (!refresh && cached != null) return cached;
    final input = BalanceFrameInput.fromStore(widget._dashboard.widget.store);
    final dashboard = widget._dashboard._buildBalanceDashboard(input: input);
    _balanceDashboardCache = dashboard;
    return dashboard;
  }

  Widget _balanceV2Dashboard({required bool refresh}) {
    final cached = _balanceV2DashboardCache;
    if (!refresh && cached != null) return cached;
    final input = BalanceFrameInput.fromStore(widget._dashboard.widget.store);
    final dashboard = widget._dashboard._buildBalanceDashboard(
      input: input,
      presentation: SpendeeBalancePresentation.balanceV2,
    );
    _balanceV2DashboardCache = dashboard;
    return dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-balance'),
      child: switch (widget._variant) {
        SpendeeDashboardMode.balance => _balanceDashboard(refresh: true),
        SpendeeDashboardMode.balanceV2 => _balanceV2Dashboard(refresh: true),
        _ => throw StateError('Balance host received a non-Balance variant.'),
      },
    );
  }
}
