import 'app/fluvi_app.dart';
import 'core/diagnostics/fluvi_build_identity.dart';
import 'core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'features/dashboard/application/dashboard_mode_spec.dart';
import 'features/dashboard/application/dashboard_presentation_preferences.dart';
import 'features/dashboard/query/domain/ledger_direction.dart';
import 'features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  verifyFluviHumanBuildIntegrity();
  DashboardPresentationPreferences initialPreferences;
  final widgetLaunch = await _readFinancialSnapshotWidgetLaunch();
  final launch = ValueNotifier<_FinancialSnapshotWidgetLaunch>(widgetLaunch);
  _financialSnapshotChannel.setMethodCallHandler((call) async {
    if (call.method == 'financialSnapshotWidgetOpen' && call.arguments is Map) {
      launch.value = _FinancialSnapshotWidgetLaunch.fromMap(
        Map<Object?, Object?>.from(call.arguments as Map),
        serial: launch.value.serial + 1,
      );
    }
  });
  try {
    initialPreferences =
        await MethodChannelDashboardPresentationPreferencesStore().read();
  } on Object {
    initialPreferences = DashboardPresentationPreferences.defaults;
  }
  runApp(
    _FinancialSnapshotLaunchHost(
      launch: launch,
      initialDashboardPresentationPreferences: initialPreferences,
    ),
  );
}

const _financialSnapshotChannel = MethodChannel('com.fluvi/runtime_monitoring');

class _FinancialSnapshotLaunchHost extends StatelessWidget {
  const _FinancialSnapshotLaunchHost({
    required this.launch,
    required this.initialDashboardPresentationPreferences,
  });

  final ValueNotifier<_FinancialSnapshotWidgetLaunch> launch;
  final DashboardPresentationPreferences
  initialDashboardPresentationPreferences;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<_FinancialSnapshotWidgetLaunch>(
        valueListenable: launch,
        builder: (context, value, _) => FluviApp(
          key: ValueKey('financial-focus-${value.serial}'),
          initialDashboardPresentationPreferences:
              initialDashboardPresentationPreferences,
          initialMode: value.mode,
          initialPlane: value.plane,
          initialRailOpen: value.initialRailOpen,
          initialDirection: value.direction,
          initialCategoryIds:
              value.mode != DashboardModeSpec.budget || value.categoryId == null
              ? const <String>{}
              : <String>{value.categoryId!},
        ),
      );
}

final class _FinancialSnapshotWidgetLaunch {
  const _FinancialSnapshotWidgetLaunch({
    required this.mode,
    required this.plane,
    required this.direction,
    this.categoryId,
    this.initialRailOpen = false,
    this.serial = 0,
  });

  factory _FinancialSnapshotWidgetLaunch.fromMap(
    Map<Object?, Object?> values, {
    int serial = 0,
  }) {
    final mode = switch (values['mode'] as String?) {
      'budget' => DashboardModeSpec.budget,
      'mind' => DashboardModeSpec.mind,
      _ => DashboardModeSpec.balance,
    };
    final axis = values['timeAxis'] as String?;
    final plane = switch (axis) {
      'sum' => TimePlane.sum,
      'year' => TimePlane.year,
      _ => TimePlane.month,
    };
    final direction =
        values['mode'] == 'budget' && values['direction'] == 'expense'
        ? LedgerDirection.expense
        : LedgerDirection.income;
    return _FinancialSnapshotWidgetLaunch(
      mode: mode,
      plane: plane,
      direction: direction,
      categoryId: values['categoryId'] as String?,
      initialRailOpen: axis == 'day',
      serial: serial,
    );
  }

  final DashboardModeSpec mode;
  final TimePlane plane;
  final LedgerDirection direction;
  final String? categoryId;
  final bool initialRailOpen;
  final int serial;
}

Future<_FinancialSnapshotWidgetLaunch>
_readFinancialSnapshotWidgetLaunch() async {
  try {
    final raw = await _financialSnapshotChannel.invokeMethod<Object?>(
      'getFinancialSnapshotWidgetLaunch',
    );
    if (raw is! Map) {
      return const _FinancialSnapshotWidgetLaunch(
        mode: DashboardModeSpec.balance,
        plane: TimePlane.month,
        direction: LedgerDirection.income,
      );
    }
    return _FinancialSnapshotWidgetLaunch.fromMap(
      Map<Object?, Object?>.from(raw),
    );
  } on Object {
    return const _FinancialSnapshotWidgetLaunch(
      mode: DashboardModeSpec.balance,
      plane: TimePlane.month,
      direction: LedgerDirection.income,
    );
  }
}
