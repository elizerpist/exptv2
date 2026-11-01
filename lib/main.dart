import 'app/fluvi_app.dart';
import 'core/diagnostics/fluvi_build_identity.dart';
import 'core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  verifyFluviHumanBuildIntegrity();
  DashboardPresentationPreferences initialPreferences;
  try {
    initialPreferences =
        await MethodChannelDashboardPresentationPreferencesStore().read();
  } on Object {
    initialPreferences = DashboardPresentationPreferences.defaults;
  }
  runApp(FluviApp(initialDashboardPresentationPreferences: initialPreferences));
}
