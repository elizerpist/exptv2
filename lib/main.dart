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
  try {
    initialPreferences =
        await MethodChannelDashboardPresentationPreferencesStore().read();
  } on Object {
    initialPreferences = DashboardPresentationPreferences.defaults;
  }
  runApp(
    FluviApp(
      initialDashboardPresentationPreferences: initialPreferences,
      initialMode: widgetLaunch.mode,
      initialPlane: widgetLaunch.plane,
      initialDirection: widgetLaunch.direction,
    ),
  );
}

final class _FinancialSnapshotWidgetLaunch {
  const _FinancialSnapshotWidgetLaunch({
    required this.mode,
    required this.plane,
    required this.direction,
  });

  final DashboardModeSpec mode;
  final TimePlane plane;
  final LedgerDirection direction;
}

Future<_FinancialSnapshotWidgetLaunch> _readFinancialSnapshotWidgetLaunch() async {
  try {
    final raw = await const MethodChannel(
      'com.fluvi/runtime_monitoring',
    ).invokeMethod<Object?>('getFinancialSnapshotWidgetLaunch');
    if (raw is! Map) {
      return const _FinancialSnapshotWidgetLaunch(
        mode: DashboardModeSpec.balance,
        plane: TimePlane.month,
        direction: LedgerDirection.income,
      );
    }
    final values = Map<Object?, Object?>.from(raw);
    final mode = switch (values['mode'] as String?) {
      'budget' => DashboardModeSpec.budget,
      'mind' => DashboardModeSpec.mind,
      _ => DashboardModeSpec.balance,
    };
    final plane = switch (values['timeAxis'] as String?) {
      'sum' => TimePlane.sum,
      'year' => TimePlane.year,
      _ => TimePlane.month,
    };
    final direction = values['mode'] == 'budget' && values['direction'] == 'expense'
        ? LedgerDirection.expense
        : LedgerDirection.income;
    return _FinancialSnapshotWidgetLaunch(
      mode: mode,
      plane: plane,
      direction: direction,
    );
  } on Object {
    return const _FinancialSnapshotWidgetLaunch(
      mode: DashboardModeSpec.balance,
      plane: TimePlane.month,
      direction: LedgerDirection.income,
    );
  }
}
