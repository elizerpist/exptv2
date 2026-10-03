import 'package:fluvi/core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fluvi/dashboard_presentation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'PRESENTATION-PREFERENCES-02 reads every persisted display choice',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'readDashboardPresentationSettings');
        return <String, Object?>{
          'sumVisualStyle': MindSumVisualStyle.sumB.index,
          'showSumLayoutChooser': false,
          'yearGridLayout': MindYearHeatmapGridLayout.twoBySix.index,
          'yearMonthlyAmountPresentation':
              MindYearMonthlyAmountPresentation.veil.index,
          'showDayContentViewChooser': true,
          'balanceUsesChildCards': false,
        };
      });

      final preferences =
          await MethodChannelDashboardPresentationPreferencesStore().read();

      expect(preferences.sumVisualStyle, MindSumVisualStyle.sumB);
      expect(preferences.showSumLayoutChooser, isFalse);
      expect(preferences.yearGridLayout, MindYearHeatmapGridLayout.twoBySix);
      expect(
        preferences.yearMonthlyAmountPresentation,
        MindYearMonthlyAmountPresentation.veil,
      );
      expect(preferences.showDayContentViewChooser, isTrue);
      expect(preferences.balanceUsesChildCards, isFalse);
    },
  );

  test('PRESENTATION-PREFERENCES-03 writes only display choices', () async {
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return null;
    });

    await MethodChannelDashboardPresentationPreferencesStore().write(
      const DashboardPresentationPreferences(
        sumVisualStyle: MindSumVisualStyle.sumA,
        showSumLayoutChooser: false,
        yearGridLayout: MindYearHeatmapGridLayout.threeByFour,
        yearMonthlyAmountPresentation: MindYearMonthlyAmountPresentation.inline,
        showDayContentViewChooser: false,
        balanceUsesChildCards: false,
      ),
    );

    expect(request?.method, 'writeDashboardPresentationSettings');
    expect(request?.arguments, <String, Object>{
      'sumVisualStyle': MindSumVisualStyle.sumA.index,
      'showSumLayoutChooser': false,
      'yearGridLayout': MindYearHeatmapGridLayout.threeByFour.index,
      'yearMonthlyAmountPresentation':
          MindYearMonthlyAmountPresentation.inline.index,
      'showDayContentViewChooser': false,
      'balanceUsesChildCards': false,
    });
  });

  test(
    'PRESENTATION-PREFERENCES-04 safely defaults without native plugin',
    () async {
      final preferences =
          await MethodChannelDashboardPresentationPreferencesStore().read();

      expect(preferences, DashboardPresentationPreferences.defaults);
    },
  );
}
