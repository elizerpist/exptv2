part of '../spendee_test_dashboard.dart';

class SpendeeMindModeHost extends StatefulWidget {
  const SpendeeMindModeHost._({super.key, required dashboard})
    : _dashboard = dashboard;

  final _SpendeeTestDashboardState _dashboard;

  @override
  State<SpendeeMindModeHost> createState() => _SpendeeMindModeHostState();
}

class _SpendeeMindModeHostState extends State<SpendeeMindModeHost>
    with TickerProviderStateMixin {
  late final _SpendeeLegacyInteractionCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = _SpendeeLegacyInteractionCoordinator(
      vsync: this,
      bridge: _legacyInteractionBridgeFor(context, widget._dashboard),
      rebuildHost: _rebuild,
    );
  }

  @override
  void didUpdateWidget(covariant SpendeeMindModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _coordinator.replaceBridge(
      _legacyInteractionBridgeFor(context, widget._dashboard),
    );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-mind'),
      child: _buildSpendeeLegacyModeContent(
        context,
        widget._dashboard,
        _coordinator,
      ),
    );
  }
}
