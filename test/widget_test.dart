import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/platform/browser_fullscreen_controller.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/main.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/features/shell/widgets/expt_fab.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/add_transaction_sheet.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_menu_card.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_panel_metrics.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/stats_test_frame_worker.dart';
import 'helpers/channel_tolerance_golden_comparator.dart';

final savedTransactions = <Map<dynamic, dynamic>>[];
final updatedTransactions = <Map<dynamic, dynamic>>[];
final updatedThemeSettings = <Map<dynamic, dynamic>>[];
final recurringRulesPayload = <Map<String, Object?>>[];
final deletedTransactionIds = <int>[];
Map<String, Object?>? themeSettingsOverride;
Map<String, Object?>? expenseBootstrapOverride;
var firstLaunchNotificationPromptEnabled = false;
var firstLaunchNotificationPromptCalls = 0;

Future<void> _dragSpendeeHeaderByExactDelta(
  WidgetTester tester,
  double delta,
) async {
  final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(const Offset(0, kTouchSlop + 1));
  await tester.pump();
  await gesture.moveBy(Offset(0, delta));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StatsPage.debugRenderFrameWorkerOverride =
        const TestImmediateStatsFrameWorker();
    DebugConsole.clear();
    savedTransactions.clear();
    updatedTransactions.clear();
    updatedThemeSettings.clear();
    recurringRulesPayload.clear();
    deletedTransactionIds.clear();
    themeSettingsOverride = null;
    expenseBootstrapOverride = null;
    firstLaunchNotificationPromptEnabled = false;
    firstLaunchNotificationPromptCalls = 0;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('exptv2/native_ime_sheet'),
          (call) async => false,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_keyboard_controller/keyboard_events'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('exptv2/keyboard_insets'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pushparser/methods'), (
          call,
        ) async {
          if (call.method == 'loadEvents') return <Map<String, Object?>>[];
          if (call.method == 'expenseLoadBootstrap') {
            return expenseBootstrapOverride ?? expenseBootstrapPayload();
          }
          if (call.method == 'expenseLoadSettings') {
            return <String, Object?>{
              'themeSettings':
                  themeSettingsOverride ??
                  <String, Object?>{
                    'magnetType': 'fade',
                    'cardColor': 'lightgray',
                    'theme': 'Türkiz',
                    'backgroundColor': 'gray',
                    'boxColor': 'gray',
                    'backheaderStyle': 'classic',
                  },
              'fastInfoConfig': <String, Object?>{
                'pills': <Object?>[null, null, null],
                'boxes': <Object?>[null, null, null],
              },
              'securitySettings': <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': false,
                'biometricLabel': 'Nem elerheto',
              },
            };
          }
          if (call.method == 'expenseUpdateThemeSettings') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            updatedThemeSettings.add(payload);
            return payload;
          }
          if (call.method == 'expenseListRecurringTransactions') {
            return <Map<String, Object?>>[];
          }
          if (call.method == 'expenseListRecurringRules') {
            return recurringRulesPayload;
          }
          if (call.method == 'expenseListCategories') {
            return ((expenseBootstrapOverride ??
                    expenseBootstrapPayload())['categories']
                as List<Map<String, Object?>>);
          }
          if (call.method == 'expenseAddTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            savedTransactions.add(payload);
            final amount = payload['amount'] as num;
            final type = payload['type']?.toString();
            return <String, Object?>{
              'id': 250914,
              'date': payload['date'],
              'time': payload['time'],
              'merchant': payload['merchant'],
              'amount': type == 'income' ? amount : -amount.abs(),
              'userAssignedName': null,
              'transactionCategoryID': payload['transactionCategoryID'],
            };
          }
          if (call.method == 'expenseUpdateTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            updatedTransactions.add(payload);
            final amount = payload['amount'] as num;
            final type = payload['type']?.toString();
            return <String, Object?>{
              'id': payload['id'],
              'date': payload['date'],
              'time': payload['time'],
              'merchant': payload['merchant'],
              'amount': type == 'income' ? amount : -amount.abs(),
              'userAssignedName': null,
              'transactionCategoryID': payload['transactionCategoryID'],
            };
          }
          if (call.method == 'expenseDeleteTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            deletedTransactionIds.add(payload['id'] as int);
            return true;
          }
          if (call.method == 'listInstalledApps') {
            return <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'com.mand.notitest',
                'label': 'Notification Test',
                'iconBase64':
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
              },
            ];
          }
          if (call.method == 'loadNotificationParserProfiles') {
            return <String, Object?>{
              'profiles': <Object?>[notificationParserProfilePayload()],
            };
          }
          if (call.method == 'saveNotificationParserProfiles') {
            return Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
          }
          if (call.method == 'loadNotificationParserRule') {
            return notificationParserProfilePayload();
          }
          if (call.method == 'saveNotificationParserRule') {
            return Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
          }
          if (call.method == 'getStatus') {
            return <String, Object?>{
              'captureMode': 'both',
              'notificationListenerEnabled': false,
              'accessibilityEnabled': false,
              'notificationListenerActive': false,
              'accessibilityActive': false,
              'lastNotificationListenerEvent': 0,
              'lastAccessibilityEvent': 0,
              'totalEvents': 0,
            };
          }
          if (call.method == 'requestPostNotificationsOnFirstLaunch') {
            firstLaunchNotificationPromptCalls += 1;
            return firstLaunchNotificationPromptEnabled;
          }
          return null;
        });
  });

  tearDown(() {
    StatsPage.debugRenderFrameWorkerOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('pushparser/methods'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('exptv2/native_ime_sheet'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_keyboard_controller/keyboard_events'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('exptv2/keyboard_insets'),
          null,
        );
  });

  Widget buildApp({
    NativeBridge? nativeBridge,
    EventStore? store,
    BrowserFullscreenController? browserFullscreenController,
  }) {
    final bridge = nativeBridge ?? NativeBridge();
    return Exptv2App(
      store: store ?? EventStore(bridge, realtimeEnabled: false),
      nativeBridge: bridge,
      statsRenderFrameWorker: const TestImmediateStatsFrameWorker(),
      browserFullscreenController: browserFullscreenController,
    );
  }

  testWidgets('renders transaction home with bottom nav and FAB', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Kiadás'), findsOneWidget);
    expect(find.text('Bevétel'), findsOneWidget);
    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Főoldal'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Értesítések'), findsNothing);
    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
  });

  testWidgets('shell layout keeps notifications in header and FAB right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'fabSize': 80,
    };

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Főoldal'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.text('Értesítések'), findsNothing);
    expect(
      find.byKey(const ValueKey('header-notification-button')),
      findsOneWidget,
    );

    final fabRect = tester.getRect(find.byKey(const ValueKey('expt-fab')));
    expect(fabRect.left, greaterThan(280));
    expect(fabRect.width, 80);
    expect(fabRect.height, 80);

    final debugRect = tester.getRect(
      find.byKey(const ValueKey('debug-floating-button')),
    );
    expect(debugRect.bottom, lessThan(fabRect.top));

    final fabSurface = tester.widget<Container>(
      find.byKey(const ValueKey('expt-fab')),
    );
    final decoration = fabSurface.decoration as BoxDecoration;
    final borderRadius = decoration.borderRadius! as BorderRadius;
    expect(borderRadius.topLeft.x, 18);
  });

  testWidgets(
    'header settings button opens settings overlay without shell nav',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('header-settings-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
      expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('header-settings-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-root-back')), findsOneWidget);
      expect(find.byKey(const ValueKey('expt-bottom-nav')), findsNothing);
      expect(find.byKey(const ValueKey('expt-fab')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('settings-root-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings-page')), findsNothing);
      expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
      expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
    },
  );

  testWidgets('spendee test dashboard uses specialized shell navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'dashboardDesignMode': 'spendeeTest',
    };

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Stats'), findsNothing);
    expect(
      find.byKey(const ValueKey('spendee-test-app-settings-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-app-fullscreen-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-settings-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-outer-glow')),
      findsNothing,
    );
    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Q'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );
    expect(find.text('Stats'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsNothing);
    expect(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      findsOneWidget,
    );

    await _dragSpendeeHeaderByExactDelta(tester, 134);

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-category-avatar-6-selected')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-context-carousel')),
      findsOneWidget,
    );

    await _dragSpendeeHeaderByExactDelta(tester, 272);

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-focus')),
      findsOneWidget,
    );
  });

  testWidgets(
    'dashboard design switch replaces navigation while Settings is active',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('settings-dashboard-design-spendee-test')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('spendee-test-bottom-nav')),
        findsOneWidget,
      );
      expect(find.text('Stats'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('settings-dashboard-design-current')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-bottom-nav')),
        findsNothing,
      );
      expect(find.text('Stats'), findsOneWidget);
    },
  );

  testWidgets('spendee test normalizes persisted hidden tabs to Dashboard', (
    tester,
  ) async {
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'dashboardDesignMode': 'spendeeTest',
    };
    for (final hiddenTab in <String>['stats', 'notifications']) {
      final bridge = NativeBridge();
      final store = EventStore(bridge, realtimeEnabled: false)
        ..shellActiveTabKey = hiddenTab;

      await tester.pumpWidget(buildApp(nativeBridge: bridge, store: store));
      await tester.pumpAndSettle();

      expect(store.shellActiveTabKey, 'home');
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-bottom-nav')),
        findsOneWidget,
      );
      expect(find.text('Stats'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('spendee test exposes reactive browser fullscreen control', (
    tester,
  ) async {
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'dashboardDesignMode': 'spendeeTest',
    };
    final driver = _WidgetTestBrowserFullscreenDriver();
    final controller = BrowserFullscreenController(driver);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildApp(browserFullscreenController: controller));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-app-settings-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-app-fullscreen-button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-app-fullscreen-button')),
    );
    await tester.pumpAndSettle();

    expect(driver.enterCalls, 1);
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

    driver.setFullscreenExternally(false);
    await tester.pump();

    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
  });

  testWidgets('spendee test accepts a replacement fullscreen controller', (
    tester,
  ) async {
    themeSettingsOverride = _spendeeThemeSettings();
    final bridge = NativeBridge();
    final store = EventStore(bridge, realtimeEnabled: false);
    final firstDriver = _WidgetTestBrowserFullscreenDriver();
    final firstController = BrowserFullscreenController(firstDriver);
    final secondDriver = _WidgetTestBrowserFullscreenDriver();
    final secondController = BrowserFullscreenController(secondDriver);
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);

    await tester.pumpWidget(
      buildApp(
        nativeBridge: bridge,
        store: store,
        browserFullscreenController: firstController,
      ),
    );
    await tester.pumpAndSettle();

    firstDriver.setFullscreenExternally(true);
    await tester.pump();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

    await tester.pumpWidget(
      buildApp(
        nativeBridge: bridge,
        store: store,
        browserFullscreenController: secondController,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    secondDriver.setFullscreenExternally(true);
    await tester.pump();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
  });

  testWidgets('spendee test center FAB opens the transaction editor', (
    tester,
  ) async {
    themeSettingsOverride = _spendeeThemeSettings();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final settingsTarget = tester.getCenter(
      find.byKey(const ValueKey('bottom-nav-settings')),
    );
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );

    await tester.tapAt(settingsTarget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsNothing);
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
  });

  testWidgets('spendee test center FAB works from Settings', (tester) async {
    themeSettingsOverride = _spendeeThemeSettings();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );
    final dashboardTarget = tester.getCenter(
      find.byKey(const ValueKey('bottom-nav-home')),
    );

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );

    await tester.tapAt(dashboardTarget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
  });

  testWidgets(
    'spendee header keeps its snapped stage when viewport geometry changes',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      themeSettingsOverride = <String, Object?>{
        'magnetType': 'fade',
        'cardColor': 'lightgray',
        'theme': 'Türkiz',
        'backgroundColor': 'gray',
        'boxColor': 'gray',
        'backheaderStyle': 'classic',
        'dashboardDesignMode': 'spendeeTest',
      };

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _dragSpendeeHeaderByExactDelta(tester, 134);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(412, 893);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
        reason: 'A MediaQuery geometry update must not reset Stage 1.',
      );

      await _dragSpendeeHeaderByExactDelta(tester, 272);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(412, 891);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
        findsOneWidget,
        reason: 'A MediaQuery geometry update must not reset Stage 2.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'spendee header keeps armed snaps across physical drag frames without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      themeSettingsOverride = <String, Object?>{
        'magnetType': 'fade',
        'cardColor': 'lightgray',
        'theme': 'Türkiz',
        'backgroundColor': 'gray',
        'boxColor': 'gray',
        'backheaderStyle': 'classic',
        'dashboardDesignMode': 'spendeeTest',
      };

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final headerCard = find.byKey(const ValueKey('spendee-test-header-card'));
      final homeContent = find.byKey(
        const ValueKey('spendee-test-home-content'),
      );
      expect(headerCard, findsOneWidget);
      expect(homeContent, findsOneWidget);
      final initialHeaderHeight = tester.getSize(headerCard).height;
      final initialContentTop = tester.getTopLeft(homeContent).dy;

      var handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      var gesture = await tester.startGesture(tester.getCenter(handle));
      for (final delta in const [100.0, 34.0, 4.0]) {
        await gesture.moveBy(Offset(0, delta));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getTopLeft(homeContent).dy - initialContentTop,
          closeTo(tester.getSize(headerCard).height - initialHeaderHeight, .01),
          reason: 'Home content must follow the live header delta exactly.',
        );
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
        reason: 'A later pointer frame must not disarm the Stage 1 tick.',
      );

      handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      gesture = await tester.startGesture(tester.getCenter(handle));
      for (final delta in const [100.0, 172.0, 80.0]) {
        await gesture.moveBy(Offset(0, delta));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'The live Stage 2 pull must not overflow before release.',
        );
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
        findsOneWidget,
        reason: 'A later pointer frame must not disarm the Stage 2 tick.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('spendee Stage 0 matches the computed Color Lab C1 geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'dashboardDesignMode': 'spendeeTest',
    };

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('spendee-test-header-card'));
    final brand = find.byKey(const ValueKey('spendee-test-brand-lockup'));
    final logo = find.byKey(const ValueKey('spendee-test-brand-logo'));
    final homeContent = find.byKey(const ValueKey('spendee-test-home-content'));
    final typeRow = find.byKey(const ValueKey('spendee-test-type-row'));
    final incomePill = find.byKey(
      const ValueKey('spendee-test-income-type-pill'),
    );
    final expensePill = find.byKey(
      const ValueKey('spendee-test-expense-type-pill'),
    );
    final summary = find.byKey(const ValueKey('spendee-test-summary-pill'));
    final search = find.byKey(const ValueKey('spendee-test-search-pill'));

    expect(header, findsOneWidget);
    expect(brand, findsOneWidget);
    expect(logo, findsOneWidget);
    expect(homeContent, findsOneWidget);
    expect(typeRow, findsOneWidget);
    expect(incomePill, findsOneWidget);
    expect(expensePill, findsOneWidget);
    expect(search, findsOneWidget);
    expect(find.text('BUDGET'), findsOneWidget);
    expect(find.textContaining('Elköltve'), findsNothing);

    expect(tester.getRect(header), const Rect.fromLTWH(20, 104, 372, 104));
    expect(tester.getRect(brand), const Rect.fromLTWH(0, 33.3, 412, 118));
    expect(tester.getRect(logo), const Rect.fromLTWH(30, 39.3, 47.88, 47.88));
    expect(tester.getTopLeft(homeContent), const Offset(0, 212));
    expect(tester.getRect(typeRow), const Rect.fromLTWH(0, 212, 412, 66));
    expect(tester.getRect(incomePill), const Rect.fromLTWH(28, 224, 173, 42));
    expect(tester.getRect(expensePill), const Rect.fromLTWH(211, 224, 173, 42));
    final incomeDecoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: incomePill,
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    final expenseDecoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: expensePill,
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(incomeDecoration.boxShadow, const <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, .08),
        offset: Offset(0, 10),
        blurRadius: 23,
      ),
    ]);
    expect(expenseDecoration.boxShadow, const <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, .08),
        offset: Offset(0, 12),
        blurRadius: 24,
      ),
    ]);
    expect(tester.getRect(summary), const Rect.fromLTWH(28, 278, 356, 59));
    expect(tester.getRect(search), const Rect.fromLTWH(28, 349, 356, 45));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'spendee physical popout return cycle and carousel stay exception free',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      themeSettingsOverride = _spendeeThemeSettings();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      Future<void> dragHandle(List<double> deltas) async {
        final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
        final gesture = await tester.startGesture(tester.getCenter(handle));
        for (final delta in deltas) {
          await gesture.moveBy(Offset(0, delta));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await dragHandle(const [100, 34, 4]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
      );

      final carousel = find.byKey(
        const ValueKey('spendee-test-context-carousel'),
      );
      final horizontal = await tester.startGesture(tester.getCenter(carousel));
      await horizontal.moveBy(const Offset(-72, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await horizontal.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
      );

      await dragHandle(const [8]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage0')),
        findsOneWidget,
      );

      await dragHandle(const [134]);
      await dragHandle(const [12, -12]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
      );

      await dragHandle(const [100, 172, 4]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
        findsOneWidget,
      );

      await dragHandle(const [8]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
        findsOneWidget,
      );

      await dragHandle(const [272]);
      await dragHandle(const [8, -8]);
      expect(
        find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'spendee Stage 1 and 2 support zero one and many real-shaped categories',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      themeSettingsOverride = _spendeeThemeSettings();

      for (final scenario in const <(int, int)>[(0, 0), (1, 1), (7, 400)]) {
        final (categoryCount, transactionCount) = scenario;
        expenseBootstrapOverride = _spendeeBootstrapPayload(
          expenseCategoryCount: categoryCount,
          transactionCount: transactionCount,
        );
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _dragSpendeeHeaderByExactDelta(tester, 134);
        expect(
          find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final avatars = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'spendee-test-category-avatar-',
              ),
        );
        final expectedCategoryAvatars = categoryCount <= 1
            ? categoryCount
            : categoryCount.clamp(0, 4);
        expect(avatars, findsNWidgets(expectedCategoryAvatars));

        await _dragSpendeeHeaderByExactDelta(tester, 272);
        expect(
          find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
          findsOneWidget,
        );
        if (categoryCount == 0 || transactionCount == 0) {
          expect(
            find.byKey(const ValueKey('spendee-test-budget-pie-empty-hidden')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('spendee-test-budget-pie-panel')),
            findsNothing,
          );
        } else {
          expect(
            find.byKey(const ValueKey('spendee-test-budget-pie-panel')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);

        await _dragSpendeeHeaderByExactDelta(tester, 8);
        expect(
          find.byKey(const ValueKey('spendee-test-dashboard-stage-stage1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await _dragSpendeeHeaderByExactDelta(tester, 8);
        expect(
          find.byKey(const ValueKey('spendee-test-dashboard-stage-stage0')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('spendee C1 C2 C3 and menu match reviewed golden renders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    themeSettingsOverride = _spendeeThemeSettings();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final previousGoldenComparator = goldenFileComparator;
    goldenFileComparator = ChannelToleranceGoldenComparator(
      Uri.parse('test/widget_test.dart'),
      maxChannelDelta: 2,
    );
    addTearDown(() => goldenFileComparator = previousGoldenComparator);

    await expectLater(
      find.byKey(const ValueKey('spendee-test-header-golden-boundary')),
      matchesGoldenFile('goldens/spendeetest/c1_header.png'),
    );
    await expectLater(
      find.byKey(const ValueKey('spendee-test-header-menu-golden-boundary')),
      matchesGoldenFile('goldens/spendeetest/menu_button.png'),
    );
    await expectLater(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      matchesGoldenFile('goldens/spendeetest/c1_dashboard.png'),
    );

    await _dragSpendeeHeaderByExactDelta(tester, 134);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      matchesGoldenFile('goldens/spendeetest/c2_dashboard.png'),
    );

    await _dragSpendeeHeaderByExactDelta(tester, 272);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      matchesGoldenFile('goldens/spendeetest/c3_dashboard.png'),
    );
  });

  testWidgets('shell keeps the body stable while the keyboard opens', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
  });

  testWidgets('backheader live tuner covers bottom nav from shell overlay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'centerBadgeBudget',
    };
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));
    await tester.pumpAndSettle();

    final surfaceTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('backheader-experimental-surface')),
    );
    await tester.tapAt(surfaceTopLeft + const Offset(24, 96));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('backheader-live-tuner-slide-card')),
      findsOneWidget,
    );
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('backheader-live-tuner-slide-card')),
    );
    final summaryRect = tester.getRect(
      find.byKey(const ValueKey('summary-pill')),
    );
    final navRect = tester.getRect(
      find.byKey(const ValueKey('expt-bottom-nav')),
    );
    expect(sheetRect.top, lessThan(navRect.top));
    expect(sheetRect.bottom, greaterThanOrEqualTo(navRect.bottom));
    expect(sheetRect.top, greaterThanOrEqualTo(summaryRect.top - 1));
    expect(sheetRect.top, lessThanOrEqualTo(summaryRect.top + 4));

    final scrollRect = tester.getRect(
      find.byKey(const ValueKey('settings-backheader-style-scroll')),
    );
    expect(scrollRect.top, greaterThanOrEqualTo(sheetRect.top));
    expect(scrollRect.bottom, lessThanOrEqualTo(sheetRect.bottom));

    await tester.tap(find.text('Beállítások'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsNothing);
  });

  testWidgets('vendor sheet covers bottom nav and FAB without hiding them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('vendor-filter-slide-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('vendor-filter-slide-card')),
    );
    final navRect = tester.getRect(
      find.byKey(const ValueKey('expt-bottom-nav')),
    );
    final fabRect = tester.getRect(find.byKey(const ValueKey('expt-fab')));
    expect(sheetRect.top, lessThan(navRect.top));
    expect(sheetRect.bottom, greaterThanOrEqualTo(navRect.bottom));
    expect(sheetRect.top, lessThan(fabRect.bottom));
    expect(sheetRect.bottom, greaterThanOrEqualTo(fabRect.bottom));

    await tester.tapAt(fabRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('vendor-filter-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('add-transaction-sheet-card')),
      findsNothing,
    );
  });

  testWidgets('bottom nav taps switch secondary pages', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-sum-year-cards')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsNothing);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
    var fab = tester.widget<ExptFab>(find.byType(ExptFab));
    expect(fab.onHorizontalDragStep, isNotNull);
    expect(fab.onVerticalDragStep, isNotNull);

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();
    expect(find.text('Kiadás'), findsOneWidget);
    fab = tester.widget<ExptFab>(find.byType(ExptFab));
    expect(fab.onHorizontalDragStep, isNull);
    expect(fab.onVerticalDragStep, isNull);

    await tester.tap(find.byKey(const ValueKey('header-notification-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-month-header')),
      findsOneWidget,
    );
    expect(find.text('Nincsenek értesítések'), findsOneWidget);

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();
    expect(find.text('Kiadás'), findsOneWidget);
  });

  testWidgets('shell tab host avoids IndexedStack inactive page layout', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(IndexedStack), findsNothing);
  });

  testWidgets('bottom nav tab switch does not rebuild transaction home', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav tap from=home to=settings'));
    expect(logs, contains('[Perf] BottomNav frame from=home to=settings'));
    expect(logs, isNot(contains('[Perf] HomeBuild frame')));
  });

  testWidgets('bottom nav return to home reuses the existing home page', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav tap from=settings to=home'));
    expect(logs, contains('[Perf] BottomNav frame from=settings to=home'));
    expect(
      logs,
      isNot(contains('[Perf] Store start skipped reason=completed')),
    );
    expect(logs, isNot(contains('[Perf] FastInfo metrics build')));
  });

  testWidgets('stats tab switch defers heavy page jump and reuses cache', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    var logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav pointer dispatch tab=stats'));
    expect(logs, contains('[Perf] BottomNav page jump deferred tab=stats'));
    expect(logs, isNot(contains('[Perf] CalendarRender build source=overlay')));
    expect(find.byKey(const ValueKey('stats-sum-year-cards')), findsOneWidget);

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav pointer dispatch tab=stats'));
    expect(logs, contains('[Perf] BottomNav page jump deferred tab=stats'));
    expect(logs, isNot(contains('[Perf] CalendarRender build source=overlay')));
  });

  testWidgets('first launch requests Android notification permission once', (
    tester,
  ) async {
    firstLaunchNotificationPromptEnabled = true;

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(firstLaunchNotificationPromptCalls, 1);
  });

  testWidgets('FAB opens stats threshold sheet on the stats tab', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    await _tapFab(tester);

    expect(find.byKey(const ValueKey('stats-threshold-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-snapshot-row')), findsOneWidget);
    expect(find.text('Új kiadási tranzakció'), findsNothing);
    expect(find.text('Tranzakció neve'), findsNothing);
  });

  testWidgets('FAB opens Flutter add transaction sheet directly', (
    tester,
  ) async {
    const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async {
          calls.add(call);
          if (call.method == 'openAddTransaction') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, null),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      calls.map((call) => call.method),
      isNot(contains('openAddTransaction')),
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(
      DebugConsole.entries.any(
        (entry) => entry.contains(
          '[SlideUpMenu] AddTransaction shell open requested source=fab',
        ),
      ),
      isTrue,
    );
  });

  testWidgets('native hosted add transaction content omits SlideUpMenuCard', (
    tester,
  ) async {
    final bridge = NativeBridge();
    final store = TransactionStore(TransactionRepository(bridge));
    var savedCallbacks = 0;
    addTearDown(store.dispose);
    await store.start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTransactionSheet(
            store: store,
            nativeHostMode: true,
            onSaved: () => savedCallbacks += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(find.text('Tranzakció neve'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-editor-card')), findsNothing);
    expect(find.byType(SlideUpMenuCard), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'Native Host Store',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '1234');
    await tester.tap(find.byKey(const ValueKey('transaction-save-button')));
    await tester.pumpAndSettle();

    expect(savedCallbacks, 1);
    expect(savedTransactions.last['merchant'], 'Native Host Store');
    expect(savedTransactions.last['type'], 'expense');
  });

  testWidgets(
    'Flutter add transaction sheet uses scroll body and fixed footer',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _tapFab(tester);
      await tester.pumpAndSettle();

      final scrollBody = find.byKey(
        const ValueKey('transaction-editor-scroll-body'),
      );
      final saveFooter = find.byKey(const ValueKey('transaction-save-footer'));

      expect(scrollBody, findsOneWidget);
      expect(
        find.descendant(
          of: scrollBody,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(saveFooter, findsOneWidget);
      expect(
        find.descendant(of: scrollBody, matching: saveFooter),
        findsNothing,
      );
    },
  );

  testWidgets('FAB long press opens the recurring manager', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Ismétlődő kiadás'), findsOneWidget);
    expect(find.text('Kiadás a fő pill alapján'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recurring-trigger-date')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recurring-trigger-push')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recurring-rule-day')), findsOneWidget);
    expect(find.byKey(const ValueKey('recurring-rule-date')), findsNothing);
    expect(
      find.byKey(const ValueKey('recurring-rule-date-picker-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('recurring-rule-time')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('transaction-editor-card')), findsNothing);
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
  });

  testWidgets('recurring push training taps stay inside the manager', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recurring-push-day')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recurring-push-date-picker-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('recurring-push-app-pill')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recurring-rule-time')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recurring-push-app-pill')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notification Test'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('recurring-rule-sample')),
      'Kartyas vasarlas: Tesco - 12 345 Ft',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-training-merchant')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-training-merchant')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-training-token-Tesco')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recurring-training-token-Tesco')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
    expect(find.text('Tesco'), findsWidgets);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsNothing);
  });

  testWidgets('recurring trigger pills use transaction type pill styling', (
    tester,
  ) async {
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
      'buttonSurfaceStyle': 'neutralInset',
    };
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    BoxDecoration surfaceDecoration(String key) {
      final container = tester.widget<Container>(find.byKey(ValueKey(key)));
      return container.decoration! as BoxDecoration;
    }

    Text labelText(String key, String label) {
      return tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.text(label),
        ),
      );
    }

    final dateSurface = surfaceDecoration('recurring-trigger-date-surface');
    final pushSurface = surfaceDecoration('recurring-trigger-push-surface');
    final expenseSurface = surfaceDecoration(
      'transaction-type-pill-expense-surface',
    );
    expect(dateSurface, expenseSurface);
    expect((pushSurface.border! as Border).top.color, AppColors.gray200);
    expect(
      labelText('recurring-trigger-date', 'Idő').style?.color,
      AppColors.white,
    );
    expect(
      labelText('recurring-trigger-push', 'Push').style?.color,
      AppColors.gray500,
    );

    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();

    final selectedPushSurface = surfaceDecoration(
      'recurring-trigger-push-surface',
    );
    expect(selectedPushSurface, expenseSurface);
    expect(
      labelText('recurring-trigger-push', 'Push').style?.color,
      AppColors.white,
    );
    expect(find.byKey(const ValueKey('recurring-push-day')), findsOneWidget);
  });

  testWidgets('recurring manager body scroll never becomes sheet drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-push-advanced')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-push-advanced')));
    await tester.pumpAndSettle();

    final scrollFinder = find.byKey(const ValueKey('recurring-manager-scroll'));
    await tester.drag(scrollFinder, const Offset(0, -520));
    await tester.pumpAndSettle();

    final beforeDrag = _slideCardTranslationY(tester);
    final gesture = await tester.startGesture(tester.getCenter(scrollFinder));
    await gesture.moveBy(const Offset(0, 760));
    await tester.pump();

    expect(
      _slideCardTranslationY(tester),
      moreOrLessEquals(beforeDrag, epsilon: 0.1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('recurring-manager-drag-handle')),
      const Offset(0, 220),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsNothing);
  });

  testWidgets('recurring rule cards use main logbox corner radius', (
    tester,
  ) async {
    recurringRulesPayload.add(<String, Object?>{
      'id': 7,
      'triggerType': 'date',
      'transactionType': 'expense',
      'name': 'Hitel',
      'estimatedAmount': 123456,
      'expectedDayOfMonth': 5,
      'expectedTime': '20:15',
      'categoryId': 1,
      'isActive': true,
      'appFilterText': '',
      'packageName': '',
      'appLabel': '',
      'sampleText': '',
      'includeKeyword': '',
      'amountPattern': '',
      'amountSelection': '',
      'merchantPattern': '',
      'merchantSelection': '',
      'dateToleranceDays': 5,
      'amountTolerancePercent': 20,
      'amountToleranceMin': 5000,
      'createdAt': '2026-06-01T10:00:00.000',
      'updatedAt': '2026-06-01T10:00:00.000',
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('recurring-rule-card-7')),
    );
    final decoration = card.decoration! as BoxDecoration;
    final radius = decoration.borderRadius! as BorderRadius;

    expect(radius.topLeft.x, 25);
    expect(radius.topRight.x, 25);
    expect(radius.bottomLeft.x, 25);
    expect(radius.bottomRight.x, 25);
  });

  testWidgets('FAB repeated taps keep opening the transaction sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
      reason: DebugConsole.allText,
    );
    expect(
      find.byKey(const ValueKey('budget-target-editor-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
  });

  testWidgets('FAB single tap dispatches immediately', (tester) async {
    var singleTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(onPressed: () => singleTaps += 1)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 1));

    expect(singleTaps, 1);
  });

  testWidgets('FAB renders as rounded square by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(onPressed: () {})),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('expt-fab')),
    );
    final decoration = surface.decoration as BoxDecoration;
    final borderRadius = decoration.borderRadius! as BorderRadius;

    expect(borderRadius.topLeft.x, 18);
    expect(borderRadius.topRight.x, 18);
    expect(borderRadius.bottomLeft.x, 18);
    expect(borderRadius.bottomRight.x, 18);
  });

  testWidgets('FAB size controls surface and icon dimensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(size: 80, onPressed: () {})),
        ),
      ),
    );

    final fabRect = tester.getRect(find.byKey(const ValueKey('expt-fab')));
    expect(fabRect.width, 80);
    expect(fabRect.height, 80);
    expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 32);
  });

  testWidgets('FAB quick second tap dispatches another single tap', (
    tester,
  ) async {
    var singleTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(onPressed: () => singleTaps += 1)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 1));

    expect(singleTaps, 2);
  });

  testWidgets('transaction editor closed height fits primary controls', (
    tester,
  ) async {
    var mobileClosedHeight = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              mobileClosedHeight = SlideUpPanelMetrics.transactionHeight(
                context,
                pickerOpen: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(mobileClosedHeight, lessThanOrEqualTo(404));
    expect(mobileClosedHeight, greaterThanOrEqualTo(390));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    expect(cardRect.height, lessThanOrEqualTo(456));

    for (final key in const [
      ValueKey('transaction-category-selector'),
      ValueKey('transaction-date-picker-button'),
      ValueKey('transaction-time-picker-button'),
      ValueKey('transaction-save-button'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.top, greaterThanOrEqualTo(cardRect.top));
      expect(rect.bottom, lessThanOrEqualTo(cardRect.bottom));
    }
  });

  testWidgets(
    'transaction editor closed layout uses scroll body and fixed footer',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _tapFab(tester);

      final nameField = find.widgetWithText(TextField, 'Tranzakció neve');
      expect(nameField, findsOneWidget);
      expect(
        find.ancestor(
          of: nameField,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('transaction-editor-scroll-body')),
          matching: find.byKey(const ValueKey('transaction-save-footer')),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('transaction-category-selector')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('transaction-category-scroll-list')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('transaction-category-scroll-list')),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('transaction editor keeps one field gap between every control', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    _expectTransactionEditorGapsMatchFieldGap(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-logbox-250909')),
        matching: find.text('-505 Ft'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Kiadási tranzakció módosítása'), findsOneWidget);
    _expectTransactionEditorGapsMatchFieldGap(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bevétel'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await _tapFab(tester);

    expect(find.text('Új bevételi tranzakció'), findsOneWidget);
    _expectTransactionEditorGapsMatchFieldGap(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    await tester.pump();

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    _expectTransactionEditorGapsMatchFieldGap(tester);
  });

  testWidgets(
    'transaction editor keeps date-time and save gap stable while keyboard appears',
    (tester) async {
      tester.view.physicalSize = const Size(390, 919);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 0.8;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
        tester.view.resetViewInsets();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _tapFab(tester);

      final panelHeightBefore = tester
          .getRect(find.byKey(const ValueKey('transaction-editor-card')))
          .height;
      final gapBefore = _transactionEditorDateTimeSaveGap(tester);

      final keyboard = KeyboardControllerScope.of(
        tester.element(find.byKey(const ValueKey('transaction-editor-card'))),
      );
      keyboard.handleEvent(
        const KeyboardEventData(
          height: 180,
          progress: 0.5,
          duration: 285,
          timestamp: 1,
          isVisible: true,
          type: KeyboardEventType.move,
        ),
      );
      await tester.pump();

      final panelHeightAfter = tester
          .getRect(find.byKey(const ValueKey('transaction-editor-card')))
          .height;
      final transformAfter = tester.widget<Transform>(
        find.byKey(const ValueKey('slide-up-menu-transform')),
      );
      final cardRectAfter = tester.getRect(
        find.byKey(const ValueKey('transaction-editor-card')),
      );
      final footerRectAfter = tester.getRect(
        find.byKey(const ValueKey('transaction-save-footer')),
      );

      expect(panelHeightAfter, moreOrLessEquals(panelHeightBefore, epsilon: 1));
      expect(
        cardRectAfter.bottom - footerRectAfter.bottom,
        moreOrLessEquals(32, epsilon: 1),
      );
      expect(
        _transactionEditorDateTimeSaveGap(tester),
        moreOrLessEquals(gapBefore, epsilon: 1),
      );
      expect(
        transformAfter.transform.getTranslation().y,
        moreOrLessEquals(-180, epsilon: 0.1),
      );
      expect(DebugConsole.allText, contains('source=keyboard-controller'));
      expect(DebugConsole.allText, contains('lag=0.0'));
    },
  );

  testWidgets(
    'transaction editor save button aligns with category filter action',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _tapFab(tester);
      final transactionSaveBottom = tester
          .getRect(find.byKey(const ValueKey('transaction-save-button')))
          .bottom;

      final transactionCardTopLeft = tester.getTopLeft(
        find.byKey(const ValueKey('transaction-editor-card')),
      );
      final closeGesture = await tester.startGesture(
        transactionCardTopLeft + const Offset(200, 24),
      );
      await closeGesture.moveBy(const Offset(0, 140));
      await closeGesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await tester.pumpAndSettle();

      final categoryActionBottom = tester
          .getRect(find.byKey(const ValueKey('category-menu-apply-button')))
          .bottom;

      expect(
        transactionSaveBottom,
        moreOrLessEquals(categoryActionBottom, epsilon: 4),
      );
    },
  );

  testWidgets('transaction editor logs text focus performance', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await _tapFab(tester);
    await tester.tap(find.widgetWithText(TextField, 'Tranzakció neve'));
    await tester.pump();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] AddTransaction focus field=name'));
    expect(logs, contains('[Perf] AddTransaction focus frame field=name'));
    expect(logs, contains('[Perf] TextInput focus label=AddTransaction.name'));
    expect(logs, contains('keyboard='));
  });

  testWidgets('transaction category field opens inline scroll picker', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final slideCard = tester.widget<SlideUpMenuCard>(
      find.ancestor(
        of: find.byKey(const ValueKey('transaction-editor-card')),
        matching: find.byType(SlideUpMenuCard),
      ),
    );
    expect(slideCard.entryDuration, const Duration(milliseconds: 192));
    expect(slideCard.deferEntryAnimation, isTrue);
    expect(
      slideCard.keyboardMotionSource,
      SlideUpKeyboardMotionSource.controller,
    );
    final cardBefore = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final saveBefore = tester.getRect(
      find.byKey(const ValueKey('transaction-save-button')),
    );

    await tester.tap(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-category-popup')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );

    final editorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final saveAfter = tester.getRect(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
    );
    final selectorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(editorRect.top, lessThan(cardBefore.top));
    expect(
      editorRect.height,
      moreOrLessEquals(
        SlideUpPanelMetrics.transactionHeight(
          tester.element(find.byKey(const ValueKey('transaction-editor-card'))),
          pickerOpen: true,
        ),
        epsilon: 0.1,
      ),
    );
    expect(saveAfter.bottom, moreOrLessEquals(saveBefore.bottom, epsilon: 1));
    expect(saveAfter.bottom, lessThanOrEqualTo(screenHeight));
    expect(
      pickerRect.top,
      moreOrLessEquals(selectorRect.bottom + 8, epsilon: 1),
    );
    expect(pickerRect.height, moreOrLessEquals(211, epsilon: 0.1));
    expect(pickerRect.bottom, lessThanOrEqualTo(saveAfter.top - 12));

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
    );
    await tester.pumpAndSettle();

    final beforeDrag = _slideCardTranslationY(tester);
    await tester.drag(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      const Offset(0, 120),
    );
    await tester.pump();
    expect(
      _slideCardTranslationY(tester),
      moreOrLessEquals(beforeDrag, epsilon: 0.1),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-category-option-6')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-category-option-6')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    expect(find.text('Q'), findsWidgets);
  });

  testWidgets('transaction editor keeps save button above the safe zone', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final saveRect = tester.getRect(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    final footerRect = tester.getRect(
      find.byKey(const ValueKey('transaction-save-footer')),
    );
    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-scroll-body')),
    );
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(saveRect.bottom, moreOrLessEquals(screenHeight - 8, epsilon: 1));
    expect(footerRect.bottom, moreOrLessEquals(screenHeight - 8, epsilon: 1));
    expect(bodyRect.bottom, lessThanOrEqualTo(footerRect.top));
  });

  testWidgets('recurring manager keeps add rule button fixed above safe zone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    final saveRect = tester.getRect(
      find.byKey(const ValueKey('recurring-manager-save')),
    );
    final footerRect = tester.getRect(
      find.byKey(const ValueKey('recurring-manager-footer')),
    );
    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('recurring-manager-scroll-body')),
    );

    expect(saveRect.bottom, moreOrLessEquals(919 - 8, epsilon: 1));
    expect(footerRect.bottom, moreOrLessEquals(919 - 8, epsilon: 1));
    expect(bodyRect.bottom, lessThanOrEqualTo(footerRect.top));
  });

  testWidgets(
    'recurring manager keeps sheet fixed and lifts only footer for keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 919);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey('expt-fab')));
      await tester.pumpAndSettle();

      final transformBefore = _slideCardTranslationY(tester);
      final footerBefore = tester.getRect(
        find.byKey(const ValueKey('recurring-manager-footer')),
      );

      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final footerAfter = tester.getRect(
        find.byKey(const ValueKey('recurring-manager-footer')),
      );

      expect(
        _slideCardTranslationY(tester),
        moreOrLessEquals(transformBefore, epsilon: 0.1),
      );
      expect(footerAfter.top, lessThan(footerBefore.top));
      expect(
        DebugConsole.allText,
        contains('[KeyboardFlow] RecurringManager footer keyboard frame'),
      );
    },
  );

  testWidgets('category sheet keeps shell navigation controls visible', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-calendar-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

    expect(
      find.byKey(const ValueKey('category-menu-back-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-menu-add-card')),
      findsOneWidget,
    );
  });

  testWidgets('slide-up category sheet covers shell navigation hit area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    themeSettingsOverride = <String, Object?>{
      'magnetType': 'fade',
      'cardColor': 'lightgray',
      'theme': 'Türkiz',
      'backgroundColor': 'gray',
      'boxColor': 'gray',
      'backheaderStyle': 'classic',
    };

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-menu-add-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final navRect = tester.getRect(
      find.byKey(const ValueKey('expt-bottom-nav')),
    );
    expect(sheetRect.bottom, moreOrLessEquals(919, epsilon: 1));
    expect(sheetRect.bottom, greaterThanOrEqualTo(navRect.bottom));

    await tester.tap(find.text('Stats'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-page')), findsNothing);
  });

  testWidgets('stats category sheet uses real screen bottom above shell nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('stats-scope-slide-card')),
    );
    final navRect = tester.getRect(
      find.byKey(const ValueKey('expt-bottom-nav')),
    );
    expect(sheetRect.bottom, moreOrLessEquals(919, epsilon: 1));
    expect(sheetRect.bottom, greaterThanOrEqualTo(navRect.bottom));

    await tester.tap(find.text('Főoldal'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
  });

  testWidgets('add category sheet keeps the picker behind and covers nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final allCardRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-all-card')),
    );
    final addCardRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-add-card')),
    );
    expect(sheetRect.top, lessThan(allCardRect.top));
    expect(addCardRect.top, moreOrLessEquals(allCardRect.top, epsilon: 1));
    expect(addCardRect.left, greaterThan(allCardRect.left));

    await tester.tap(find.byKey(const ValueKey('category-menu-add-card')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );

    await tester.tap(find.text('Stats'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-page')), findsNothing);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
  });

  testWidgets('transaction editor is focused and aligned to summary pill', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;
    final editorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final editorTop = editorRect.top;

    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(editorTop, greaterThan(summaryTop + 20));
    expect(
      editorRect.bottom,
      moreOrLessEquals(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
    );
    expect(editorRect.height, lessThan(600));
  });

  testWidgets('transaction editor drags down to close', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );

    final cardTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final gesture = await tester.startGesture(
      cardTopLeft + const Offset(200, 24),
    );
    await gesture.moveBy(const Offset(0, 140));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-editor-card')), findsNothing);
  });

  testWidgets(
    'outside tap on type pills dismisses the focused transaction editor',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _tapFab(tester);
      expect(find.text('Új kiadási tranzakció'), findsOneWidget);

      await tester.tap(find.text('Bevétel'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('transaction-editor-card')),
        findsNothing,
      );
      await _tapFab(tester);
      expect(find.text('Új bevételi tranzakció'), findsOneWidget);
      expect(find.text('Új kiadási tranzakció'), findsNothing);
    },
  );

  testWidgets('logbox tap opens transaction editor in edit mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-logbox-250909')),
        matching: find.text('-505 Ft'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Kiadási tranzakció módosítása'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
  });

  testWidgets('right swipe asks before deleting a transaction', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-250909')),
      const Offset(160, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tranzakció törlése'), findsOneWidget);
    expect(find.text('Törlés'), findsOneWidget);

    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();

    expect(deletedTransactionIds, [250909]);
  });

  testWidgets('add transaction sheet opens date and time pickers', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-time-picker-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-time-picker-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('add transaction sheet saves through native bridge', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'New Shop',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '42');
    await tester.ensureVisible(find.text('Mentés'));
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    expect(savedTransactions, hasLength(1));
    expect(savedTransactions.single['merchant'], 'New Shop');
    expect(savedTransactions.single['amount'], 42.0);
    expect(savedTransactions.single['type'], 'expense');
    expect(savedTransactions.single['transactionCategoryID'], 6);
  });

  testWidgets('settings contains Backheader style selector', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    final backheaderOption = find.ancestor(
      of: find.text('Backheader'),
      matching: find.byType(InkWell),
    );
    expect(backheaderOption, findsOneWidget);
    await tester.ensureVisible(backheaderOption);
    await tester.pumpAndSettle();
    await tester.tap(backheaderOption);
    await tester.pumpAndSettle();

    expect(find.text('Jelenlegi bar rendszer (jelenlegi)'), findsOneWidget);
    expect(find.text('C - Hero Token'), findsNothing);
    expect(find.text('D - Orbit Budget'), findsNothing);
    expect(find.text('E - Center Badge Budget'), findsOneWidget);
    expect(find.text('A - Color Field Partition'), findsNothing);
    expect(find.text('B - Partition Dashboard'), findsNothing);
    expect(find.text('E - Mosaic Budget'), findsNothing);
    expect(find.text('F - Ledger Strip'), findsNothing);

    await tester.ensureVisible(find.text('E - Center Badge Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E - Center Badge Budget'));
    await tester.pumpAndSettle();

    expect(updatedThemeSettings.single['backheaderStyle'], 'centerBadgeBudget');
  });

  testWidgets('settings contains push parser profiles and app picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();

    expect(find.text('Profilok'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-parser-profile-profile-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-parser-sample')),
      findsOneWidget,
    );
    expect(find.text('App regex'), findsNothing);
    final appPicker = find.byKey(
      const ValueKey('notification-parser-app-picker'),
    );
    expect(appPicker, findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('settings-parsed-app-scroll')),
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();

    await tester.tap(appPicker);
    await tester.pumpAndSettle();
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('installed-app-picker-sheet')),
    );
    expect(
      pickerRect.height,
      moreOrLessEquals(
        SlideUpPanelMetrics.fullHeightForScreen(919),
        epsilon: 1,
      ),
    );
    expect(
      pickerRect.top,
      moreOrLessEquals(
        919 - SlideUpPanelMetrics.fullHeightForScreen(919),
        epsilon: 1,
      ),
    );
    expect(
      find.byKey(const ValueKey('installed-app-picker-search')),
      findsOneWidget,
    );
    final picker = find.byKey(const ValueKey('installed-app-picker-sheet'));
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: picker, matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('installed-app-picker-search')),
      'missing',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('installed-app-picker-search')),
      'notification',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: picker, matching: find.text('Notification Test')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsWidgets);
  });

  testWidgets('settings resets submenu after active bottom nav switch', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elkapott push üzenetek'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    expect(find.text('Alkalmazás beállítások'), findsOneWidget);
    expect(find.text('Push import'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsNothing,
    );
  });

  testWidgets('settings submenu survives shell recreation with same store', (
    tester,
  ) async {
    final bridge = NativeBridge();
    final store = EventStore(bridge, realtimeEnabled: false);

    await tester.pumpWidget(buildApp(nativeBridge: bridge, store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elkapott push üzenetek'));
    await tester.pumpAndSettle();

    expect(store.shellActiveTabKey, 'settings');
    expect(store.settingsActiveMenuKey, 'pushLog');
    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildApp(nativeBridge: bridge, store: store));
    await tester.pumpAndSettle();

    expect(find.text('Beállítások'), findsWidgets);
    expect(find.text('Elkapott push üzenetek'), findsWidgets);
    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );
  });
}

Map<String, Object?> notificationParserProfilePayload() {
  return <String, Object?>{
    'id': 'profile-1',
    'name': 'Profil',
    'enabled': true,
    'appFilterText': '',
    'packageName': 'com.mand.notitest',
    'appLabel': 'Notification Test',
    'sampleText': 'Paid 999 Ft at Corner Shop',
    'includeKeyword': '',
    'amountPattern': r'(?<amount>\d+)\s*Ft',
    'merchantPattern': r'at\s+(?<merchant>.+)',
    'transactionType': 'expense',
  };
}

Map<String, Object?> expenseBootstrapPayload() {
  final transactions = <Map<String, Object?>>[
    if (!deletedTransactionIds.contains(250909))
      <String, Object?>{
        'id': 250909,
        'date': '2025.09.25',
        'time': '20:30:00',
        'merchant': 'Test Store',
        'amount': -505,
        'userAssignedName': null,
        'transactionCategoryID': 6,
      },
  ];
  if (savedTransactions.isNotEmpty) {
    final payload = savedTransactions.last;
    final amount = payload['amount'] as num;
    transactions.insert(0, <String, Object?>{
      'id': 250914,
      'date': payload['date'],
      'time': payload['time'],
      'merchant': payload['merchant'],
      'amount': -amount.abs(),
      'userAssignedName': null,
      'transactionCategoryID': payload['transactionCategoryID'],
    });
  }

  return <String, Object?>{
    'categories': <Map<String, Object?>>[
      <String, Object?>{
        'transactionCategoryID': 5,
        'name': 'Rr',
        'type': 'bevétel',
        'colorSlot': 2,
        'iconSlot': 0,
        'backgroundColor': '#3b82f6',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 6,
        'name': 'Q',
        'type': 'kiadás',
        'colorSlot': 7,
        'iconSlot': 2,
        'backgroundColor': '#dc2626',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 7,
        'name': 'Food',
        'type': 'kiadás',
        'colorSlot': 1,
        'iconSlot': 3,
        'backgroundColor': '#10b981',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 8,
        'name': 'Travel',
        'type': 'kiadás',
        'colorSlot': 4,
        'iconSlot': 4,
        'backgroundColor': '#f59e0b',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 9,
        'name': 'Bills',
        'type': 'kiadás',
        'colorSlot': 5,
        'iconSlot': 5,
        'backgroundColor': '#8b5cf6',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
    ],
    'transactions': transactions,
  };
}

Map<String, Object?> _spendeeThemeSettings() {
  return <String, Object?>{
    'magnetType': 'fade',
    'cardColor': 'lightgray',
    'theme': 'Türkiz',
    'backgroundColor': 'gray',
    'boxColor': 'gray',
    'backheaderStyle': 'classic',
    'dashboardDesignMode': 'spendeeTest',
  };
}

Map<String, Object?> _spendeeBootstrapPayload({
  required int expenseCategoryCount,
  required int transactionCount,
}) {
  final categories = List<Map<String, Object?>>.generate(
    expenseCategoryCount,
    (index) => <String, Object?>{
      'transactionCategoryID': 100 + index,
      'name': 'Kategória ${index + 1}',
      'type': 'kiadás',
      'colorSlot': index % 21,
      'iconSlot': index % 8,
      'backgroundColor': '#06b6d4',
      'hasLimit': index.isEven,
      'limitAmount': index.isEven ? 100000 + index * 10000 : 0,
      'alertActive': false,
      'isCustomIcon': true,
    },
  );
  final transactions = expenseCategoryCount == 0
      ? <Map<String, Object?>>[]
      : List<Map<String, Object?>>.generate(
          transactionCount,
          (index) => <String, Object?>{
            'id': 900000 + index,
            'date': '2026.07.${(index % 28 + 1).toString().padLeft(2, '0')}',
            'time': '${(index % 24).toString().padLeft(2, '0')}:30:00',
            'merchant': 'Teszt kereskedő $index',
            'amount': -(100 + index),
            'userAssignedName': null,
            'transactionCategoryID':
                categories[index %
                    expenseCategoryCount]['transactionCategoryID'],
          },
        );
  return <String, Object?>{
    'categories': categories,
    'transactions': transactions,
  };
}

Future<void> _tapFab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 919);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('expt-fab')));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

double _slideCardTranslationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('slide-up-menu-transform')),
  );
  return transform.transform.getTranslation().y;
}

void _expectTransactionEditorGapsMatchFieldGap(WidgetTester tester) {
  final titleBottom = tester
      .getRect(
        find.descendant(
          of: find.byKey(const ValueKey('transaction-editor-card')),
          matching: find.textContaining('tranzakció'),
        ),
      )
      .bottom;
  final nameRect = tester.getRect(
    find.widgetWithText(TextField, 'Tranzakció neve'),
  );
  final amountRect = tester.getRect(find.widgetWithText(TextField, 'Összeg'));
  final categoryRect = tester.getRect(
    find.byKey(const ValueKey('transaction-category-selector')),
  );
  final dateRect = tester.getRect(find.widgetWithText(TextField, 'Dátum'));
  final timeRect = tester.getRect(find.widgetWithText(TextField, 'Idő'));
  final fieldGap = amountRect.top - nameRect.bottom;
  final dateTimeTop = [
    dateRect.top,
    timeRect.top,
  ].reduce((value, element) => value < element ? value : element);
  final dateTimeBottom = [
    dateRect.bottom,
    timeRect.bottom,
  ].reduce((value, element) => value > element ? value : element);
  final saveTop = tester
      .getRect(find.byKey(const ValueKey('transaction-save-button')))
      .top;

  expect(nameRect.top - titleBottom, moreOrLessEquals(14, epsilon: 1));
  expect(
    categoryRect.top - amountRect.bottom,
    moreOrLessEquals(fieldGap, epsilon: 1),
  );
  expect(
    dateTimeTop - categoryRect.bottom,
    moreOrLessEquals(fieldGap, epsilon: 1),
  );
  expect(saveTop - dateTimeBottom, moreOrLessEquals(fieldGap, epsilon: 1));
}

double _transactionEditorDateTimeSaveGap(WidgetTester tester) {
  final dateRect = tester.getRect(find.widgetWithText(TextField, 'Dátum'));
  final timeRect = tester.getRect(find.widgetWithText(TextField, 'Idő'));
  final dateTimeBottom = [
    dateRect.bottom,
    timeRect.bottom,
  ].reduce((value, element) => value > element ? value : element);
  final saveTop = tester
      .getRect(find.byKey(const ValueKey('transaction-save-button')))
      .top;
  return saveTop - dateTimeBottom;
}

class _WidgetTestBrowserFullscreenDriver implements BrowserFullscreenDriver {
  var _isFullscreen = false;
  var enterCalls = 0;
  var exitCalls = 0;
  final List<VoidCallback> _listeners = <VoidCallback>[];

  @override
  bool get isAvailable => true;

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  void addStateListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeStateListener(VoidCallback listener) =>
      _listeners.remove(listener);

  @override
  Future<void> enter() async {
    enterCalls += 1;
    setFullscreenExternally(true);
  }

  @override
  Future<void> exit() async {
    exitCalls += 1;
    setFullscreenExternally(false);
  }

  void setFullscreenExternally(bool value) {
    _isFullscreen = value;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void dispose() => _listeners.clear();
}
