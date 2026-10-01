import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fluvi/dashboard_presentation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads every persisted dashboard-only display preference', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'readDashboardPresentationSettings');
      return <String, Object?>{
        'sumVisualStyle': MindSumVisualStyle.sumB.index,
        'showSumLayoutChooser': false,
        'showYearMotherCardActions': false,
        'balanceUsesChildCards': false,
      };
    });

    final preferences =
        await MethodChannelDashboardPresentationPreferencesStore().read();

    expect(preferences.sumVisualStyle, MindSumVisualStyle.sumB);
    expect(preferences.showSumLayoutChooser, isFalse);
    expect(preferences.showYearMotherCardActions, isFalse);
    expect(preferences.balanceUsesChildCards, isFalse);
  });

  test(
    'writes only dashboard display preferences through the native boundary',
    () async {
      MethodCall? request;
      messenger.setMockMethodCallHandler(channel, (call) async {
        request = call;
        return null;
      });

      await MethodChannelDashboardPresentationPreferencesStore().write(
        const DashboardPresentationPreferences(
          sumVisualStyle: MindSumVisualStyle.sumA,
          showSumLayoutChooser: false,
          showYearMotherCardActions: true,
          balanceUsesChildCards: false,
        ),
      );

      expect(request?.method, 'writeDashboardPresentationSettings');
      expect(request?.arguments, <String, Object>{
        'sumVisualStyle': MindSumVisualStyle.sumA.index,
        'showSumLayoutChooser': false,
        'showYearMotherCardActions': true,
        'balanceUsesChildCards': false,
      });
    },
  );

  test('falls back to safe visual defaults without a native plugin', () async {
    final preferences =
        await MethodChannelDashboardPresentationPreferencesStore().read();

    expect(preferences.sumVisualStyle, MindSumVisualStyle.current);
    expect(preferences.showSumLayoutChooser, isTrue);
    expect(preferences.showYearMotherCardActions, isTrue);
    expect(preferences.balanceUsesChildCards, isTrue);
  });
}
