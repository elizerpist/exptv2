import 'package:flutter/services.dart';

import '../../../features/dashboard/application/dashboard_presentation_preferences.dart';
import '../../../features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';

/// Native SharedPreferences adapter for presentation-only dashboard choices.
final class MethodChannelDashboardPresentationPreferencesStore
    implements DashboardPresentationPreferencesStore {
  MethodChannelDashboardPresentationPreferencesStore({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'fluvi/dashboard_presentation';

  final MethodChannel _channel;

  @override
  Future<DashboardPresentationPreferences> read() async {
    try {
      final values = await _channel.invokeMapMethod<String, Object?>(
        'readDashboardPresentationSettings',
      );
      if (values == null) return DashboardPresentationPreferences.defaults;
      final styleIndex = values['sumVisualStyle'] as int? ?? 0;
      return DashboardPresentationPreferences(
        sumVisualStyle:
            styleIndex >= 0 && styleIndex < MindSumVisualStyle.values.length
            ? MindSumVisualStyle.values[styleIndex]
            : MindSumVisualStyle.current,
        showSumLayoutChooser: values['showSumLayoutChooser'] as bool? ?? true,
        showYearMotherCardActions:
            values['showYearMotherCardActions'] as bool? ?? true,
        balanceUsesChildCards: values['balanceUsesChildCards'] as bool? ?? true,
      );
    } on PlatformException {
      return DashboardPresentationPreferences.defaults;
    } on MissingPluginException {
      return DashboardPresentationPreferences.defaults;
    }
  }

  @override
  Future<void> write(DashboardPresentationPreferences preferences) =>
      _channel.invokeMethod<void>(
        'writeDashboardPresentationSettings',
        <String, Object>{
          'sumVisualStyle': preferences.sumVisualStyle.index,
          'showSumLayoutChooser': preferences.showSumLayoutChooser,
          'showYearMotherCardActions': preferences.showYearMotherCardActions,
          'balanceUsesChildCards': preferences.balanceUsesChildCards,
        },
      );
}
