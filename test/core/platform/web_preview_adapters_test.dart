import 'package:exptv2/core/keyboard/app_keyboard_provider_web.dart';
import 'package:exptv2/core/keyboard/app_keyboard_height_web.dart';
import 'package:exptv2/core/platform/network_failure_web.dart';
import 'package:exptv2/features/stats/data/stats_render_frame_worker_web.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/services/native_ime_sheet_bridge.dart';
import 'package:exptv2/services/recurring_alarm_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web keyboard provider builds its child unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AppKeyboardProvider(
        child: MaterialApp(home: Text('preview-child')),
      ),
    );

    expect(find.text('preview-child'), findsOneWidget);
  });

  testWidgets('web keyboard height adapter has no native notifier', (
    tester,
  ) async {
    ValueListenable<double>? notifier;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            notifier = appKeyboardHeightNotifierOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(notifier, isNull);
  });

  test('web stats worker returns the canonical frame asynchronously', () async {
    final request = StatsRenderFrameRequest(
      year: 2026,
      month: 7,
      activeType: TransactionType.expense,
      thresholdValue: 5000,
      transactions: const [],
      categories: const [],
      selectedCategoryIds: const {},
      vendorFilters: const {},
      summaryScope: StatsSummaryScope.yearly,
      query: '',
      today: DateTime(2026, 7, 18),
    );
    var completed = false;

    final pending = const IsolateStatsRenderFrameWorker().build(request).then((
      frame,
    ) {
      completed = true;
      return frame;
    });

    expect(completed, isFalse);
    final frame = await pending;
    expect(frame.yearData.year, 2026);
  });

  test('web network classifier has no IO-specific failures', () {
    expect(isNetworkFailure(Exception('offline')), isFalse);
  });

  test('disabled recurring alarm returns stable empty results', () async {
    final service = RecurringAlarmService.disabled();

    expect(await service.syncRecurringAlarms(), isFalse);
    final processed = await service.processRecurringNow();
    expect(processed.processedCount, 0);
    expect(processed.processed, isEmpty);
    final state = await service.loadDebugState();
    expect(state.usingOverride, isFalse);
    expect(state.logs, isEmpty);
    expect(await service.clearDebugLog(), isFalse);
  });

  test('disabled native IME bridge never invokes a platform channel', () async {
    final bridge = NativeImeSheetBridge.disabled();

    await bridge.openProbe();
    await bridge.closeProbe();
    expect(
      await bridge.openAddTransaction(type: TransactionType.expense),
      isFalse,
    );
    expect(await bridge.getInitialState(), isEmpty);
    await bridge.closeSheet();
    await bridge.notifyTransactionCommitted();
    await bridge.notifyContentReady();
    bridge.dispose();
  });
}
