import 'package:fluvi/features/dashboard/application/balance_daily_calculation_mode.dart';
import 'package:fluvi/core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fluvi/dashboard_presentation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'fourth day perspective persists at index3 without changing earlier choices',
    () async {
      Map<String, Object?> stored = {};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      final defaults = DashboardPresentationPreferences.defaults;
      final choice = DashboardPresentationPreferences(
        sumVisualStyle: defaults.sumVisualStyle,
        showSumLayoutChooser: defaults.showSumLayoutChooser,
        yearGridLayout: defaults.yearGridLayout,
        yearMonthlyAmountPresentation: defaults.yearMonthlyAmountPresentation,
        showDayContentViewChooser: defaults.showDayContentViewChooser,
        balanceUsesChildCards: defaults.balanceUsesChildCards,
        balanceHeaderGraphPresentation: defaults.balanceHeaderGraphPresentation,
        balanceHeaderPartitionHeightPercent:
            defaults.balanceHeaderPartitionHeightPercent,
        balanceMonthCombinedCardPresentation:
            defaults.balanceMonthCombinedCardPresentation,
        balanceDayLayoutPresentation: BalanceDayLayoutPresentation.focused,
        balanceDayFocusedPresentation:
            BalanceDayFocusedPresentation.monthlyNetMarginImpact,
        balanceDayRatioPresentation: BalanceDayRatioPresentation.netMargin,
        balanceDayRatioViewPresentation:
            BalanceDayRatioViewPresentation.performanceIndex,
        balanceDayPerformanceVisualPresentation:
            BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      expect(BalanceDayFocusedPresentation.financialCompass.index, 0);
      expect(BalanceDayFocusedPresentation.financialComparison.index, 1);
      expect(BalanceDayFocusedPresentation.dailyImpactFocus.index, 2);
      expect(BalanceDayFocusedPresentation.monthlyNetMarginImpact.index, 3);
      await store.write(choice);
      expect(stored['balanceDayFocusedPresentation'], 3);
      expect(
        await MethodChannelDashboardPresentationPreferencesStore().read(),
        choice,
      );
      for (final index in [0, 1, 2, 3, -1, 4, 999]) {
        stored['balanceDayFocusedPresentation'] = index;
        final restored = await store.read();
        expect(
          restored.balanceDayFocusedPresentation,
          BalanceDayFocusedPresentation.values[index >= 0 && index <= 3
              ? index
              : 0],
        );
        expect(
          restored.balanceDayRatioPresentation,
          BalanceDayRatioPresentation.netMargin,
        );
        expect(
          restored.balanceDayRatioViewPresentation,
          BalanceDayRatioViewPresentation.performanceIndex,
        );
        expect(
          restored.balanceDayPerformanceVisualPresentation,
          BalanceDayPerformanceVisualPresentation.horizontalMeter,
        );
      }
    },
  );

  test(
    'day ratio persists independently and unknown legacy values use coverage',
    () async {
      Map<String, Object?> stored = {};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      expect(
        (await store.read()).balanceDayRatioPresentation,
        BalanceDayRatioPresentation.coverage,
      );
      expect(
        (await store.read()).balanceDayPerformanceVisualPresentation,
        BalanceDayPerformanceVisualPresentation.semicircle,
      );
      final defaults = DashboardPresentationPreferences.defaults;
      final choice = DashboardPresentationPreferences(
        sumVisualStyle: defaults.sumVisualStyle,
        showSumLayoutChooser: defaults.showSumLayoutChooser,
        yearGridLayout: defaults.yearGridLayout,
        yearMonthlyAmountPresentation: defaults.yearMonthlyAmountPresentation,
        showDayContentViewChooser: defaults.showDayContentViewChooser,
        balanceUsesChildCards: defaults.balanceUsesChildCards,
        balanceHeaderGraphPresentation: defaults.balanceHeaderGraphPresentation,
        balanceHeaderPartitionHeightPercent:
            defaults.balanceHeaderPartitionHeightPercent,
        balanceMonthCombinedCardPresentation:
            defaults.balanceMonthCombinedCardPresentation,
        balanceDayLayoutPresentation: BalanceDayLayoutPresentation.focused,
        balanceDayFocusedPresentation:
            BalanceDayFocusedPresentation.dailyImpactFocus,
        balanceShowFocusedDayImpact: false,
        balanceDayPerformanceVisualPresentation:
            BalanceDayPerformanceVisualPresentation.horizontalMeter,
        balanceDayRatioViewPresentation:
            BalanceDayRatioViewPresentation.performanceIndex,
        balanceDayRatioPresentation: BalanceDayRatioPresentation.netMargin,
      );
      await store.write(choice);
      expect(stored['balanceDayPerformanceVisualPresentation'], 1);
      expect(stored['balanceDayRatioViewPresentation'], 1);
      expect(stored['balanceDayRatioPresentation'], 1);
      final restored =
          await MethodChannelDashboardPresentationPreferencesStore().read();
      expect(restored, choice);
      expect(restored.hashCode, choice.hashCode);
      for (final invalid in <Object?>[null, -1, 2, 999, 'unknown']) {
        stored['balanceDayPerformanceVisualPresentation'] = invalid;
        stored['balanceDayRatioPresentation'] = invalid;
        stored['balanceDayRatioViewPresentation'] = invalid;
        final legacy = await store.read();
        expect(
          legacy.balanceDayRatioPresentation,
          BalanceDayRatioPresentation.coverage,
        );
        expect(
          legacy.balanceDayFocusedPresentation,
          BalanceDayFocusedPresentation.dailyImpactFocus,
        );
        expect(
          legacy.balanceDayRatioViewPresentation,
          BalanceDayRatioViewPresentation.dualGauge,
        );
        expect(
          legacy.balanceDayPerformanceVisualPresentation,
          BalanceDayPerformanceVisualPresentation.semicircle,
        );
        expect(legacy.balanceShowFocusedDayImpact, isFalse);
      }
    },
  );

  test(
    'daily calculation survives a native adapter write/read and invalid legacy values default safely',
    () async {
      Map<String, Object?> stored = <String, Object?>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      final original = await store.read();
      expect(
        original.balanceDailyCalculationMode,
        BalanceDailyCalculationMode.monthToDate,
      );
      final choice = DashboardPresentationPreferences(
        sumVisualStyle: original.sumVisualStyle,
        showSumLayoutChooser: original.showSumLayoutChooser,
        yearGridLayout: original.yearGridLayout,
        yearMonthlyAmountPresentation: original.yearMonthlyAmountPresentation,
        showDayContentViewChooser: original.showDayContentViewChooser,
        balanceUsesChildCards: original.balanceUsesChildCards,
        balanceHeaderGraphPresentation: original.balanceHeaderGraphPresentation,
        balanceSumLayoutPresentation: BalanceSumLayoutPresentation.focused,
        balanceSumFocusedPresentation: BalanceSumFocusedPresentation.stability,
        balanceShowSumFocusedSupplementaryStats: false,
        balanceDayLayoutPresentation: BalanceDayLayoutPresentation.focused,
        balanceDayFocusedPresentation:
            BalanceDayFocusedPresentation.dailyImpactFocus,
        balanceShowFocusedDayImpact: false,
        balanceMonthLayoutPresentation: BalanceMonthLayoutPresentation.focused,
        balanceYearLayoutPresentation: BalanceYearLayoutPresentation.focused,
        balanceDailyCalculationMode: BalanceDailyCalculationMode.allTimeToDate,
        balanceHeaderPartitionHeightPercent:
            original.balanceHeaderPartitionHeightPercent,
        balanceMonthCombinedCardPresentation:
            original.balanceMonthCombinedCardPresentation,
      );
      await store.write(choice);
      expect(
        await MethodChannelDashboardPresentationPreferencesStore().read(),
        choice,
      );
      stored['balanceSumLayoutPresentation'] = 99;
      stored['balanceSumFocusedPresentation'] = 99;
      stored.remove('balanceShowSumFocusedSupplementaryStats');
      final restoredSum = await store.read();
      expect(
        restoredSum.balanceSumLayoutPresentation,
        BalanceSumLayoutPresentation.current,
      );
      expect(
        restoredSum.balanceSumFocusedPresentation,
        BalanceSumFocusedPresentation.distribution,
      );
      expect(restoredSum.balanceShowSumFocusedSupplementaryStats, isTrue);
      stored['balanceDayLayoutPresentation'] = 99;
      stored['balanceDayFocusedPresentation'] = 99;
      stored.remove('balanceShowFocusedDayImpact');
      final restoredDay = await store.read();
      expect(
        restoredDay.balanceDayLayoutPresentation,
        BalanceDayLayoutPresentation.current,
      );
      expect(
        restoredDay.balanceDayFocusedPresentation,
        BalanceDayFocusedPresentation.financialCompass,
      );
      expect(restoredDay.balanceShowFocusedDayImpact, isTrue);
      stored['balanceMonthLayoutPresentation'] = 99;
      expect(
        (await store.read()).balanceMonthLayoutPresentation,
        BalanceMonthLayoutPresentation.current,
      );
      stored['balanceYearLayoutPresentation'] = 99;
      expect(
        (await store.read()).balanceYearLayoutPresentation,
        BalanceYearLayoutPresentation.current,
      );
      stored['balanceDailyCalculationMode'] = 99;
      expect(
        (await store.read()).balanceDailyCalculationMode,
        BalanceDailyCalculationMode.monthToDate,
      );
    },
  );

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
          'balanceDailyCalculationMode':
              BalanceDailyCalculationMode.allTimeToDate.index,
          'balanceUsesChildCards': false,
          'balanceHeaderGraphPresentation':
              BalanceHeaderGraphPresentation.simpleIncomeExpensePartition.index,
          'balanceMonthlySpendingChartPresentation':
              BalanceMonthlySpendingChartPresentation.reactiveSvg.index,
          'balanceHeaderPartitionHeightPercent': 80,
          'balanceMonthCombinedCardPresentation':
              BalanceMonthCombinedCardPresentation.spendingRhythm.index,
          'balanceHeaderGlassConfigurationJson': '{"renderer":"glassKit"}',
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
      expect(
        preferences.balanceDailyCalculationMode,
        BalanceDailyCalculationMode.allTimeToDate,
      );
      expect(preferences.balanceUsesChildCards, isFalse);
      expect(
        preferences.balanceHeaderGraphPresentation,
        BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
      );
      expect(
        preferences.balanceMonthlySpendingChartPresentation,
        BalanceMonthlySpendingChartPresentation.reactiveSvg,
      );
      expect(preferences.balanceHeaderPartitionHeightPercent, 80);
      expect(
        preferences.balanceMonthCombinedCardPresentation,
        BalanceMonthCombinedCardPresentation.spendingRhythm,
      );
      expect(
        preferences.balanceHeaderGlassConfigurationJson,
        '{"renderer":"glassKit"}',
      );
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
        balanceHeaderGraphPresentation:
            BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
        balanceMonthlySpendingChartPresentation:
            BalanceMonthlySpendingChartPresentation.reactiveSvg,
        balanceHeaderPartitionHeightPercent: 80,
        balanceMonthCombinedCardPresentation:
            BalanceMonthCombinedCardPresentation.spendingRhythm,
        balanceHeaderGlassConfigurationJson: '{"renderer":"glassKit"}',
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
      'balanceSumLayoutPresentation':
          BalanceSumLayoutPresentation.current.index,
      'balanceSumFocusedPresentation':
          BalanceSumFocusedPresentation.distribution.index,
      'balanceShowSumFocusedSupplementaryStats': true,
      'balanceDayLayoutPresentation':
          BalanceDayLayoutPresentation.current.index,
      'balanceDayFocusedPresentation':
          BalanceDayFocusedPresentation.financialCompass.index,
      'balanceShowFocusedDayImpact': true,
      'balanceDayPerformanceVisualPresentation':
          BalanceDayPerformanceVisualPresentation.semicircle.index,
      'balanceDayRatioViewPresentation':
          BalanceDayRatioViewPresentation.dualGauge.index,
      'balanceDayRatioPresentation': BalanceDayRatioPresentation.coverage.index,
      'balanceMonthLayoutPresentation':
          BalanceMonthLayoutPresentation.current.index,
      'balanceYearLayoutPresentation':
          BalanceYearLayoutPresentation.current.index,
      'balanceDailyCalculationMode':
          BalanceDailyCalculationMode.monthToDate.index,
      'balanceUsesChildCards': false,
      'balanceHeaderGraphPresentation':
          BalanceHeaderGraphPresentation.simpleIncomeExpensePartition.index,
      'balanceMonthlySpendingChartPresentation':
          BalanceMonthlySpendingChartPresentation.reactiveSvg.index,
      'balanceHeaderPartitionHeightPercent': 80,
      'balanceMonthCombinedCardPresentation':
          BalanceMonthCombinedCardPresentation.spendingRhythm.index,
      'balanceHeaderGlassConfigurationJson': '{"renderer":"glassKit"}',
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

  test(
    'PRESENTATION-PREFERENCES-05 missing SUM style starts from SUM-A without rewriting valid stored choices',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'readDashboardPresentationSettings');
        return <String, Object?>{};
      });

      final preferences =
          await MethodChannelDashboardPresentationPreferencesStore().read();

      expect(preferences.sumVisualStyle, MindSumVisualStyle.sumA);
    },
  );
}
