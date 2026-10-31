import 'package:fluvi/features/dashboard/application/balance_daily_calculation_mode.dart';
import 'package:fluvi/core/preferences/data/method_channel_dashboard_presentation_preferences_store.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fluvi/dashboard_presentation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'missing or invalid scope layouts fall back to the focused presentation while saved current choices remain intact',
    () async {
      final stored = <String, Object?>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored
            ..clear()
            ..addAll(Map<String, Object?>.from(call.arguments as Map));
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();

      Future<void> expectFocused() async {
        final restored = await store.read();
        expect(
          restored.balanceDayLayoutPresentation,
          BalanceDayLayoutPresentation.focused,
        );
        expect(
          restored.balanceMonthLayoutPresentation,
          BalanceMonthLayoutPresentation.focused,
        );
        expect(
          restored.balanceYearLayoutPresentation,
          BalanceYearLayoutPresentation.focused,
        );
        expect(
          restored.balanceSumLayoutPresentation,
          BalanceSumLayoutPresentation.focused,
        );
      }

      await expectFocused();
      stored.addAll(<String, Object?>{
        'balanceDayLayoutPresentation': 99,
        'balanceMonthLayoutPresentation': -1,
        'balanceYearLayoutPresentation': 'bad',
        'balanceSumLayoutPresentation': 2,
      });
      await expectFocused();

      stored.addAll(<String, Object?>{
        'balanceDayLayoutPresentation':
            BalanceDayLayoutPresentation.current.index,
        'balanceMonthLayoutPresentation':
            BalanceMonthLayoutPresentation.current.index,
        'balanceYearLayoutPresentation':
            BalanceYearLayoutPresentation.current.index,
        'balanceSumLayoutPresentation':
            BalanceSumLayoutPresentation.current.index,
      });
      final savedCurrent = await store.read();
      expect(
        savedCurrent.balanceDayLayoutPresentation,
        BalanceDayLayoutPresentation.current,
      );
      expect(
        savedCurrent.balanceMonthLayoutPresentation,
        BalanceMonthLayoutPresentation.current,
      );
      expect(
        savedCurrent.balanceYearLayoutPresentation,
        BalanceYearLayoutPresentation.current,
      );
      expect(
        savedCurrent.balanceSumLayoutPresentation,
        BalanceSumLayoutPresentation.current,
      );
    },
  );

  test(
    'Balance header palettes round-trip through the native preference map and stale unsupported variants normalize to original',
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
        balanceHeaderPalette: DashboardBalanceHeaderPalette.dynamicRedB3mBridge,
        balanceHeaderPaletteVariant:
            DashboardBalanceHeaderPaletteVariant.original,
        balanceHeaderPalettePositionPercent: 0,
        balanceHeaderPaletteWindowWidthPercent: 100,
      );

      await store.write(choice);
      expect(
        stored['balanceHeaderPalette'],
        DashboardBalanceHeaderPalette.dynamicRedB3mBridge.index,
      );
      expect(
        stored['balanceHeaderPaletteVariant'],
        DashboardBalanceHeaderPaletteVariant.original.index,
      );
      expect(stored['balanceHeaderPalettePositionPercent'], 0);
      expect(stored['balanceHeaderPaletteWindowWidthPercent'], 100);
      expect(await store.read(), choice);

      stored.addAll(<String, Object?>{
        'balanceHeaderPalette': DashboardBalanceHeaderPalette.b3mMy3.index,
        'balanceHeaderPaletteVariant':
            DashboardBalanceHeaderPaletteVariant.vivid.index,
        'balanceHeaderPalettePositionPercent': 'invalid',
        'balanceHeaderPaletteWindowWidthPercent': 999,
      });
      final repaired = await store.read();
      expect(
        repaired.balanceHeaderPalette,
        DashboardBalanceHeaderPalette.b3mMy3,
      );
      expect(
        repaired.balanceHeaderPaletteVariant,
        DashboardBalanceHeaderPaletteVariant.original,
      );
      expect(repaired.balanceHeaderPalettePositionPercent, 50);
      expect(repaired.balanceHeaderPaletteWindowWidthPercent, 100);
    },
  );

  test(
    'obsolete Balance keys cannot reactivate legacy layouts or erase scope choices',
    () async {
      final legacy = <String, Object?>{
        'balanceContentSurfaceStyle': 0,
        'contentSurfaceStyle': 0,
        'balanceUnifiedBodyLayout': 0,
        'unifiedBodyLayout': 0,
        'alternativeMotherCardVisible': false,
        'balanceCarouselWaveAnimationEnabled': true,
        'hiddenBalanceCarouselCardKinds': <int>[0, 1, 2],
        'balanceHeaderChartTimeLabels': 1,
        'balanceLatestTransactionCardPresentation': 1,
        'balanceSumLayoutPresentation': 1,
        'balanceYearLayoutPresentation': 1,
        'balanceMonthLayoutPresentation': 1,
        'balanceDayLayoutPresentation': 1,
        'balanceDayFocusedPresentation': 3,
        'balanceDayRatioPresentation': 1,
        'balanceDayRatioViewPresentation': 1,
        'balanceDayPerformanceVisualPresentation': 1,
        'balanceUsesChildCards': false,
        'sumVisualStyle': 0,
      };
      Map<String, Object?>? written;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          written = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return legacy;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      final restored = await store.read();
      expect(
        restored.balanceSumLayoutPresentation,
        BalanceSumLayoutPresentation.focused,
      );
      expect(
        restored.balanceYearLayoutPresentation,
        BalanceYearLayoutPresentation.focused,
      );
      expect(
        restored.balanceMonthLayoutPresentation,
        BalanceMonthLayoutPresentation.focused,
      );
      expect(
        restored.balanceDayLayoutPresentation,
        BalanceDayLayoutPresentation.focused,
      );
      expect(
        restored.balanceDayFocusedPresentation,
        BalanceDayFocusedPresentation.monthlyNetMarginImpact,
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
      expect(restored.balanceUsesChildCards, isFalse);
      await store.write(restored);
      for (final key in <String>[
        'balanceContentSurfaceStyle',
        'contentSurfaceStyle',
        'balanceUnifiedBodyLayout',
        'unifiedBodyLayout',
        'alternativeMotherCardVisible',
        'balanceCarouselWaveAnimationEnabled',
        'hiddenBalanceCarouselCardKinds',
        'balanceHeaderChartTimeLabels',
        'balanceLatestTransactionCardPresentation',
      ]) {
        expect(written, isNot(contains(key)));
      }
      expect(written!['balanceDayFocusedPresentation'], 3);
      expect(written!['balanceDayRatioPresentation'], 1);
      expect(written!['balanceDayPerformanceVisualPresentation'], 1);
    },
  );

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
        BalanceSumLayoutPresentation.focused,
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
        BalanceDayLayoutPresentation.focused,
      );
      expect(
        restoredDay.balanceDayFocusedPresentation,
        BalanceDayFocusedPresentation.financialCompass,
      );
      expect(restoredDay.balanceShowFocusedDayImpact, isTrue);
      stored['balanceMonthLayoutPresentation'] = 99;
      expect(
        (await store.read()).balanceMonthLayoutPresentation,
        BalanceMonthLayoutPresentation.focused,
      );
      stored['balanceYearLayoutPresentation'] = 99;
      expect(
        (await store.read()).balanceYearLayoutPresentation,
        BalanceYearLayoutPresentation.focused,
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
          BalanceSumLayoutPresentation.focused.index,
      'balanceSumFocusedPresentation':
          BalanceSumFocusedPresentation.distribution.index,
      'balanceShowSumFocusedSupplementaryStats': true,
      'balanceDayLayoutPresentation':
          BalanceDayLayoutPresentation.focused.index,
      'balanceDayFocusedPresentation':
          BalanceDayFocusedPresentation.financialCompass.index,
      'balanceShowFocusedDayImpact': true,
      'balanceDayPerformanceVisualPresentation':
          BalanceDayPerformanceVisualPresentation.semicircle.index,
      'balanceDayRatioViewPresentation':
          BalanceDayRatioViewPresentation.dualGauge.index,
      'balanceDayRatioPresentation': BalanceDayRatioPresentation.coverage.index,
      'balanceMonthLayoutPresentation':
          BalanceMonthLayoutPresentation.focused.index,
      'balanceYearLayoutPresentation':
          BalanceYearLayoutPresentation.focused.index,
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
      'balanceHeaderPalette': DashboardBalanceHeaderPalette.softRainbow.index,
      'balanceHeaderPaletteVariant':
          DashboardBalanceHeaderPaletteVariant.saturated.index,
      'balanceHeaderPalettePositionPercent': 50,
      'balanceHeaderPaletteWindowWidthPercent': 15,
      'ghostQuickFilterIconPack':
          DashboardGhostQuickFilterIconPack.current.index,
      'ghostQuickFilterPresentation':
          DashboardGhostQuickFilterPresentation.searchPillFling.index,
      'recurringUiDesign': 'unified',
      'pushProfileUiDesign': 'unified',
      'automationHomeUiDesign': 'unified',
      'headerTapWaveTrailStrengthPercent': 225,
      'headerTapWaveTapStartSizePercent': 55,
      'headerTapWaveTapStrengthPercent': 75,
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

  test(
    'recurring UI defaults to unified and ignores historical numeric values',
    () async {
      Map<String, Object?> stored = <String, Object?>{'recurringUiDesign': 0};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      expect((await store.read()).recurringUiDesign, RecurringUiDesign.unified);

      stored['recurringUiDesign'] = 'legacy';
      expect((await store.read()).recurringUiDesign, RecurringUiDesign.legacy);
      await store.write(
        (await store.read()).withGhostQuickFilterIconPack(
          DashboardGhostQuickFilterIconPack.receiptGhost,
        ),
      );
      expect(stored['recurringUiDesign'], 'legacy');
    },
  );

  test(
    'push profile UI defaults to unified and uses only named values',
    () async {
      Map<String, Object?> stored = <String, Object?>{'pushProfileUiDesign': 0};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      expect(
        (await store.read()).pushProfileUiDesign,
        PushProfileUiDesign.unified,
      );
      stored['pushProfileUiDesign'] = 'legacy';
      expect(
        (await store.read()).pushProfileUiDesign,
        PushProfileUiDesign.legacy,
      );
      await store.write(
        (await store.read()).withRecurringUiDesign(RecurringUiDesign.legacy),
      );
      expect(stored['pushProfileUiDesign'], 'legacy');
    },
  );

  test(
    'Automation home UI defaults to unified and uses only named values',
    () async {
      Map<String, Object?> stored = <String, Object?>{
        'automationHomeUiDesign': 0,
      };
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      expect(
        (await store.read()).automationHomeUiDesign,
        AutomationHomeUiDesign.unified,
      );
      stored['automationHomeUiDesign'] = 'legacy';
      expect(
        (await store.read()).automationHomeUiDesign,
        AutomationHomeUiDesign.legacy,
      );
      await store.write(
        (await store.read()).withPushProfileUiDesign(
          PushProfileUiDesign.legacy,
        ),
      );
      expect(stored['automationHomeUiDesign'], 'legacy');
    },
  );

  test(
    'ghost quick-filter presentation choices persist independently and unknown values use Searchpill',
    () async {
      Map<String, Object?> stored = <String, Object?>{
        'ghostQuickFilterIconPack': 99,
        'ghostQuickFilterPresentation': 99,
      };
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeDashboardPresentationSettings') {
          stored = Map<String, Object?>.from(call.arguments as Map);
          return null;
        }
        return stored;
      });
      final store = MethodChannelDashboardPresentationPreferencesStore();
      expect(
        (await store.read()).ghostQuickFilterIconPack,
        DashboardGhostQuickFilterIconPack.current,
      );
      expect(
        (await store.read()).ghostQuickFilterPresentation,
        DashboardGhostQuickFilterPresentation.searchPillFling,
      );
      stored['ghostQuickFilterPresentation'] = 'invalid';
      expect(
        (await store.read()).ghostQuickFilterPresentation,
        DashboardGhostQuickFilterPresentation.searchPillFling,
      );
      stored.remove('ghostQuickFilterPresentation');
      expect(
        (await store.read()).ghostQuickFilterPresentation,
        DashboardGhostQuickFilterPresentation.searchPillFling,
      );
      for (final legacyChoice in <(int, DashboardGhostQuickFilterPresentation)>[
        (0, DashboardGhostQuickFilterPresentation.current),
        (1, DashboardGhostQuickFilterPresentation.dropdown),
        (2, DashboardGhostQuickFilterPresentation.rail),
      ]) {
        stored['ghostQuickFilterPresentation'] = legacyChoice.$1;
        expect(
          (await store.read()).ghostQuickFilterPresentation,
          legacyChoice.$2,
          reason:
              'The appended Searchpill option must not renumber existing '
              'persisted presentation choices.',
        );
      }
      final receipt = DashboardPresentationPreferences.defaults
          .withGhostQuickFilterIconPack(
            DashboardGhostQuickFilterIconPack.receiptGhost,
          )
          .withGhostQuickFilterPresentation(
            DashboardGhostQuickFilterPresentation.searchPillFling,
          );
      await store.write(receipt);
      expect(stored['ghostQuickFilterIconPack'], 1);
      expect(stored['ghostQuickFilterPresentation'], 3);
      expect(
        (await store.read()).ghostQuickFilterIconPack,
        DashboardGhostQuickFilterIconPack.receiptGhost,
      );
      expect(
        (await store.read()).ghostQuickFilterPresentation,
        DashboardGhostQuickFilterPresentation.searchPillFling,
      );
    },
  );

  test(
    'Header wave controls use stepped defaults and persist independently',
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
      final defaults = await store.read();
      expect(defaults.headerTapWaveTrailStrengthPercent, 225);
      expect(defaults.headerTapWaveTapStartSizePercent, 55);
      expect(defaults.headerTapWaveTapStrengthPercent, 75);

      await store.write(
        defaults.withHeaderTapWaveControls(
          trailStrengthPercent: 300,
          tapStartSizePercent: 25,
          tapStrengthPercent: 0,
        ),
      );
      expect(stored['headerTapWaveTrailStrengthPercent'], 300);
      expect(stored['headerTapWaveTapStartSizePercent'], 25);
      expect(stored['headerTapWaveTapStrengthPercent'], 0);
      expect((await store.read()).headerTapWaveTrailStrengthPercent, 300);
    },
  );
}
