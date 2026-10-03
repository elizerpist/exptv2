import 'package:flutter/services.dart';

import '../../../features/dashboard/application/dashboard_presentation_preferences.dart';
import '../../../features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';

/// Native SharedPreferences adapter for presentation-only dashboard choices.
///
/// This boundary intentionally transfers no financial, query, navigation or
/// prepared-data state. A missing plugin is safe for tests and embedded hosts.
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
      final yearGridLayoutIndex =
          values['yearGridLayout'] as int? ??
          MindYearHeatmapGridLayout.fourByThree.index;
      final amountPresentationIndex =
          values['yearMonthlyAmountPresentation'] as int?;
      final legacyScopeAmounts =
          values['showYearFourByThreeScopeAmounts'] as bool? ?? true;
      return DashboardPresentationPreferences(
        sumVisualStyle:
            styleIndex >= 0 && styleIndex < MindSumVisualStyle.values.length
            ? MindSumVisualStyle.values[styleIndex]
            : MindSumVisualStyle.current,
        showSumLayoutChooser: values['showSumLayoutChooser'] as bool? ?? true,
        yearGridLayout:
            yearGridLayoutIndex >= 0 &&
                yearGridLayoutIndex < MindYearHeatmapGridLayout.values.length
            ? MindYearHeatmapGridLayout.values[yearGridLayoutIndex]
            : MindYearHeatmapGridLayout.fourByThree,
        yearMonthlyAmountPresentation:
            amountPresentationIndex != null &&
                amountPresentationIndex >= 0 &&
                amountPresentationIndex <
                    MindYearMonthlyAmountPresentation.values.length
            ? MindYearMonthlyAmountPresentation.values[amountPresentationIndex]
            : legacyScopeAmounts
            ? MindYearMonthlyAmountPresentation.inline
            : MindYearMonthlyAmountPresentation.hidden,
        showDayContentViewChooser:
            values['showDayContentViewChooser'] as bool? ?? false,
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
          'yearGridLayout': preferences.yearGridLayout.index,
          'yearMonthlyAmountPresentation':
              preferences.yearMonthlyAmountPresentation.index,
          'showDayContentViewChooser': preferences.showDayContentViewChooser,
          'balanceUsesChildCards': preferences.balanceUsesChildCards,
        },
      );
}
