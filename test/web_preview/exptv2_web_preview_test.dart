import 'package:exptv2/exptv2_app.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/services/preview/preview_native_bridge_transport.dart';
import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stats_test_frame_worker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StatsPage.debugRenderFrameWorkerOverride =
        const TestImmediateStatsFrameWorker();
    _setPlatformChannelStubs();
  });

  tearDown(() {
    StatsPage.debugRenderFrameWorkerOverride = null;
    _clearPlatformChannelStubs();
  });

  testWidgets('production tree starts and navigates every primary surface', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);

    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-stats')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-notification-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-month-header')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('notification-logbox-1')), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    _expectNoException(tester);

    await tester.drag(
      find.byKey(const ValueKey('transaction-editor-card')),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('desktop web frame keeps primary navigation and fallback sheet', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(
      tester,
      size: const Size(1280, 900),
      webPreviewFrameEnabled: true,
    );
    addTearDown(harness.dispose);

    expect(
      tester.getSize(find.byKey(const ValueKey('web-preview-frame'))),
      const Size(480, 900),
    );
    await tester.tap(find.byKey(const ValueKey('bottom-nav-stats')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-notification-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-month-header')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    _expectNoException(tester);
  });

  testWidgets('transaction CRUD mutates shared preview state through the UI', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);
    final originalCount = harness.state.transactions.length;

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'Browser Design Shop',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '4200');
    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('transaction-save-button')));
    await tester.pumpAndSettle();

    expect(harness.state.transactions, hasLength(originalCount + 1));
    final added = harness.state.transactions.singleWhere(
      (row) => row['merchant'] == 'Browser Design Shop',
    );
    final id = added['id']! as int;
    expect(added['amount'], -4200.0);
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('transaction-logbox-$id')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(ValueKey('transaction-logbox-$id')), findsOneWidget);
    _expectNoException(tester);

    await tester.tap(find.byKey(ValueKey('transaction-logbox-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'Browser Design Cafe',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '5100');
    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('transaction-save-button')));
    await tester.pumpAndSettle();

    final updated = harness.state.transactions.singleWhere(
      (row) => row['id'] == id,
    );
    expect(updated['merchant'], 'Browser Design Shop');
    expect(updated['userAssignedName'], 'Browser Design Cafe');
    expect(updated['amount'], -5100.0);
    expect(find.text('Browser Design Cafe'), findsOneWidget);

    await tester.drag(
      find.byKey(ValueKey('transaction-logbox-$id')),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();

    expect(harness.state.transactions.where((row) => row['id'] == id), isEmpty);
    expect(find.byKey(ValueKey('transaction-logbox-$id')), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('category CRUD mutates shared preview state through the UI', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);
    final originalCount = harness.state.categories.length;

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-menu-add-card')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-input')),
      'Browser Design',
    );
    await tester.tap(find.byKey(const ValueKey('category-save-button')));
    await tester.pumpAndSettle();

    expect(harness.state.categories, hasLength(originalCount + 1));
    final added = harness.state.categories.singleWhere(
      (row) => row['name'] == 'Browser Design',
    );
    final id = added['transactionCategoryID']! as int;
    final card = find.byKey(ValueKey('category-card-$id'));
    await tester.scrollUntilVisible(
      card,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(card, findsOneWidget);

    await tester.longPress(card);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-input')),
      'Browser Design Updated',
    );
    await tester.tap(find.byKey(const ValueKey('category-save-button')));
    await tester.pumpAndSettle();

    expect(
      harness.state.categories.singleWhere(
        (row) => row['transactionCategoryID'] == id,
      )['name'],
      'Browser Design Updated',
    );
    expect(find.text('Browser Design Updated'), findsOneWidget);

    await tester.longPress(card);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('category-editor-delete-button')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.state.categories.where(
        (row) => row['transactionCategoryID'] == id,
      ),
      isEmpty,
    );
    expect(card, findsNothing);
    _expectNoException(tester);
  });

  testWidgets('budget editor saves a monthly preview limit through the UI', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    _expectNoException(tester);
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pumpAndSettle();
    _expectNoException(tester);
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    _expectNoException(tester);
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '777777',
    );
    await tester.pump();
    _expectNoException(tester);
    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    final saved = harness.state.limits.singleWhere(
      (row) =>
          row['targetType'] == 'overview' &&
          row['transactionType'] == 'expense' &&
          row['window'] == 'monthly' &&
          row['periodKey'] == '2026-07',
    );
    expect(saved['targetId'], 0);
    expect(saved['limitAmount'], 777777.0);
    expect(saved['hasLimit'], isTrue);
    _expectNoException(tester);
  });

  testWidgets('recurring rule toggle and delete mutate preview state', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);
    final rule = harness.state.recurringRules.first;
    final id = rule['id']! as int;
    expect(rule['isActive'], isTrue);

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(ValueKey('recurring-rule-toggle-$id'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      harness.state.recurringRules.singleWhere(
        (row) => row['id'] == id,
      )['isActive'],
      isFalse,
    );

    final delete = find.byKey(ValueKey('recurring-rule-delete-$id'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();

    expect(
      harness.state.recurringRules.where((row) => row['id'] == id),
      isEmpty,
    );
    expect(find.byKey(ValueKey('recurring-rule-card-$id')), findsNothing);
    _expectNoException(tester);
  });

  testWidgets('notification inbox marks read and swipe deletes preview cards', (
    tester,
  ) async {
    final harness = await _pumpPreviewApp(tester);
    addTearDown(harness.dispose);
    expect(
      harness.state.notificationCards.singleWhere(
        (row) => row['id'] == 1,
      )['isRead'],
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('header-notification-button')));
    await tester.pumpAndSettle();

    expect(
      harness.state.notificationCards.singleWhere(
        (row) => row['id'] == 1,
      )['isRead'],
      isTrue,
    );
    final card = find.byKey(const ValueKey('notification-logbox-1'));
    expect(card, findsOneWidget);

    await tester.drag(card, const Offset(-160, 0));
    await tester.pumpAndSettle();

    expect(
      harness.state.notificationCards.where((row) => row['id'] == 1),
      isEmpty,
    );
    expect(card, findsNothing);
    _expectNoException(tester);
  });

  testWidgets(
    'theme notification and parser settings persist in preview state',
    (tester) async {
      final harness = await _pumpPreviewApp(tester);
      addTearDown(harness.dispose);

      await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Téma'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Téma'));
      await tester.pumpAndSettle();
      final neumorph = find.byKey(
        const ValueKey('theme-button-surface-neumorph'),
      );
      await tester.scrollUntilVisible(
        neumorph,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(neumorph);
      await tester.pumpAndSettle();

      expect(harness.state.themeSettings['buttonSurfaceStyle'], 'neutralInset');

      await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
      await tester.pumpAndSettle();
      final notificationSettings = find.text(
        'Részletes értesítési beállítások',
      );
      await tester.scrollUntilVisible(
        notificationSettings,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(notificationSettings);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(harness.state.notificationSettings['androidPushEnabled'], isFalse);

      await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Push import'),
        -180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Push import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(harness.state.automaticPushParserEnabled, isFalse);
      _expectNoException(tester);
    },
  );
}

class _PreviewHarness {
  const _PreviewHarness({required this.state, required this.store});

  final PreviewNativeState state;
  final EventStore store;

  Future<void> dispose() async {
    store.dispose();
    await state.dispose();
  }
}

Future<_PreviewHarness> _pumpPreviewApp(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  bool webPreviewFrameEnabled = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
  final transport = PreviewNativeBridgeTransport(state: state);
  final bridge = NativeBridge(transport: transport);
  final store = EventStore(bridge, realtimeEnabled: false);
  await tester.pumpWidget(
    Exptv2App(
      store: store,
      nativeBridge: bridge,
      statsRenderFrameWorker: const TestImmediateStatsFrameWorker(),
      webPreviewFrameEnabled: webPreviewFrameEnabled,
    ),
  );
  await tester.pumpAndSettle();
  return _PreviewHarness(state: state, store: store);
}

void _expectNoException(WidgetTester tester) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: exception is FlutterError
        ? exception.toStringDeep()
        : exception?.toString(),
  );
}

void _setPlatformChannelStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('exptv2/native_ime_sheet'),
    (call) async => false,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter_keyboard_controller/keyboard_events'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('exptv2/recurring_alarm'),
    (call) async => call.method == 'syncRecurringAlarms' ? false : null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('exptv2/keyboard_insets'),
    (call) async => null,
  );
}

void _clearPlatformChannelStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in <MethodChannel>[
    const MethodChannel('exptv2/native_ime_sheet'),
    const MethodChannel('flutter_keyboard_controller/keyboard_events'),
    const MethodChannel('exptv2/recurring_alarm'),
    const MethodChannel('exptv2/keyboard_insets'),
  ]) {
    messenger.setMockMethodCallHandler(channel, null);
  }
}
