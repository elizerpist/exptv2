import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/core/theme/app_dimensions.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/settings_page.dart';
import 'package:exptv2/features/settings/widgets/options/theme_options_panel.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/settings_page_methods');
  final savedParserRules = <Map<dynamic, dynamic>>[];
  final calls = <String>[];

  setUp(() {
    savedParserRules.clear();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{
                  'magnetType': 'fade',
                  'cardColor': 'lightgray',
                  'theme': 'Türkiz',
                  'backgroundColor': 'gray',
                  'boxColor': 'gray',
                },
                'fastInfoConfig': <String, Object?>{
                  'pills': <Object?>[
                    <String, Object?>{
                      'id': 'megtakaritas',
                      'label': 'Megtakarítás',
                      'value': '156,780 Ft',
                      'type': 'pill',
                    },
                    null,
                    null,
                  ],
                  'boxes': <Object?>[
                    <String, Object?>{
                      'id': 'mai_nap',
                      'label': 'Mai nap',
                      'value': '2 db',
                      'extra': '-4,500 Ft',
                      'type': 'box',
                    },
                    null,
                    null,
                  ],
                },
                'securitySettings': <String, Object?>{
                  'pinEnabled': false,
                  'biometricEnabled': false,
                  'biometricAvailable': true,
                  'biometricLabel': 'Ujjlenyomat elerheto',
                },
              };
            case 'expenseSetSecurityPin':
              return <String, Object?>{
                'pinEnabled': true,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseVerifySecurityPin':
              return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
            case 'expenseClearSecurityPin':
              return <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseSetBiometricEnabled':
              return <String, Object?>{
                'pinEnabled': true,
                'biometricEnabled':
                    (call.arguments as Map<dynamic, dynamic>)['enabled'] ==
                    true,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseAuthenticateBiometric':
              return true;
            case 'expenseGetBiometricAvailability':
              return <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'loadNotificationParserProfiles':
              return <String, Object?>{
                'profiles': <Object?>[
                  <String, Object?>{
                    'id': 'bank-a',
                    'name': 'Bank A profil',
                    'enabled': true,
                    'appFilterText': r'^Bank A$',
                    'packageName': 'hu.bank.a',
                    'appLabel': 'Bank A',
                    'sampleText': 'Paid 999 Ft at Corner Shop',
                    'includeKeyword': 'Paid',
                    'amountPattern': r'(?<amount>\d+)\s*Ft',
                    'merchantPattern': r'at\s+(?<merchant>.+)',
                    'transactionType': 'expense',
                  },
                  <String, Object?>{
                    'id': 'bank-b',
                    'name': 'Bank B profil',
                    'enabled': true,
                    'appFilterText': r'^Bank B$',
                    'packageName': 'hu.bank.b',
                    'appLabel': 'Bank B',
                    'sampleText': 'Paid 1000 Ft at Backup Shop',
                    'includeKeyword': 'Paid',
                    'amountPattern': r'(?<amount>\d+)\s*Ft',
                    'merchantPattern': r'at\s+(?<merchant>.+)',
                    'transactionType': 'expense',
                  },
                ],
              };
            case 'saveNotificationParserProfiles':
              savedParserRules.add(
                Map<dynamic, dynamic>.from(
                  call.arguments as Map<dynamic, dynamic>,
                ),
              );
              return call.arguments;
            case 'loadNotificationParserRule':
              return <String, Object?>{
                'enabled': true,
                'sampleText': 'Paid 999 Ft at Corner Shop',
                'includeKeyword': 'Paid',
                'amountPattern': r'(?<amount>\d+)\s*Ft',
                'merchantPattern': r'at\s+(?<merchant>.+)',
              };
            case 'saveNotificationParserRule':
              savedParserRules.add(
                Map<dynamic, dynamic>.from(
                  call.arguments as Map<dynamic, dynamic>,
                ),
              );
              return call.arguments;
            case 'expenseListCategories':
              return <Map<String, Object?>>[
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
              ];
            case 'listInstalledApps':
              return <Map<String, Object?>>[
                <String, Object?>{
                  'packageName': 'hu.bank.a',
                  'label': 'Bank A',
                  'iconBase64':
                      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
                },
                <String, Object?>{
                  'packageName': 'hu.bank.b',
                  'label': 'Bank B',
                  'iconBase64':
                      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
                },
              ];
            case 'getStatus':
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
            case 'loadNotificationEventPage':
              return <String, Object?>{
                'events': <Object?>[
                  pushLogEventRow(
                    id: 77,
                    status: 'missing',
                    statusText: 'Nincs hozzárendelt log',
                  ),
                ],
                'totalCount': 1,
                'limit': 60,
                'offset': 0,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildSubject() {
    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_page_events'),
    );
    return MaterialApp(
      home: SettingsPage(
        store: EventStore(bridge, realtimeEnabled: false),
        nativeBridge: bridge,
      ),
    );
  }

  Widget buildSubjectWith({
    required NativeBridge bridge,
    required EventStore store,
    Key? key,
  }) {
    return MaterialApp(
      home: SettingsPage(key: key, store: store, nativeBridge: bridge),
    );
  }

  testWidgets('renders original settings sections', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.text('Alkalmazás beállítások'), findsOneWidget);
    expect(find.text('Megjelenítési beállítások'), findsOneWidget);
    expect(find.text('Adatkezelés'), findsOneWidget);
    expect(find.text('Értesítési beállítások'), findsOneWidget);
    expect(find.text('Adatvédelem és biztonság'), findsOneWidget);
    expect(find.text('Visszajelzések'), findsOneWidget);
    expect(find.text('Információ és támogatás'), findsOneWidget);
    expect(find.text('Ghost logbox'), findsNothing);
    expect(find.text('Ismétlődő tranzakciók'), findsNothing);
    expect(find.text('Statisztikák'), findsNothing);
  });

  testWidgets('opens theme and FastInfo submenus', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Téma'));
    await tester.pumpAndSettle();
    expect(find.text('Téma Beállítások'), findsOneWidget);
    expect(find.text('Mágneskártya'), findsOneWidget);
    expect(find.text('Gombok felülete'), findsOneWidget);
    expect(find.text('Logboxok felülete'), findsOneWidget);
    expect(find.text('Design profil'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('theme-category-menu-color-darkgray')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sötétebb szürke'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Sötétebb szürke box'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Neumorph'), findsWidgets);
    expect(find.text('Pink'), findsWidgets);
    expect(find.text('Éjszakai mód'), findsNothing);
    expect(find.text('Éjszaka Amber'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('FastInfo'));
    await tester.pumpAndSettle();
    expect(find.text('FastInfo'), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-box-slot-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fastinfo-upper-row-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-lower-row-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-upper-row-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-lower-row-box')),
      findsOneWidget,
    );
    final fastInfoFrameBottom = tester
        .getBottomLeft(
          find.byKey(const ValueKey('settings-submenu-content-frame')),
        )
        .dy;
    expect(fastInfoFrameBottom, 1200 - AppDimensions.bottomNavHeight);
    await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
    await tester.pumpAndSettle();
  });

  testWidgets('root settings does not expose detailed Ghost logbox submenu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Ghost logbox'), findsNothing);
    expect(find.text('Várható felirat'), findsNothing);
  });

  testWidgets('theme menu exposes component surface and app color choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final updated = <AppThemeSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: updated.add,
        ),
      ),
    );

    expect(find.text('Design profil'), findsNothing);
    expect(find.text('Gombok felülete'), findsOneWidget);
    expect(find.text('Logboxok felülete'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('theme-button-surface-normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-button-surface-neutral-inset')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-button-surface-neumorph')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-logbox-surface-normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-logbox-surface-neumorph')),
      findsOneWidget,
    );
    expect(find.text('App színe'), findsOneWidget);
    expect(find.text('Kategória menü mód'), findsOneWidget);
    expect(find.text('Kategória menü felülete'), findsOneWidget);
    expect(find.text('Kategória kártyák felülete'), findsOneWidget);
    expect(find.text('Árnyékok'), findsOneWidget);
    expect(find.text('Türkiz (jelenlegi)'), findsOneWidget);
    expect(find.text('Pink'), findsOneWidget);
    expect(find.text('Éjszakai mód'), findsNothing);
    expect(find.text('Kikapcsolva (jelenlegi)'), findsNothing);
    expect(find.text('Éjszaka Cyan'), findsNothing);
    expect(find.text('Éjszaka Amber'), findsNothing);
    expect(find.text('Neumorphism'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('theme-button-surface-neutral-inset')),
    );
    expect(
      updated.last.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.neutralInset,
    );

    await tester.tap(
      find.byKey(const ValueKey('theme-button-surface-neumorph')),
    );
    expect(
      updated.last.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.raisedInset,
    );
    expect(
      updated.last.contentSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      updated.last.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );

    await tester.tap(
      find.byKey(const ValueKey('theme-logbox-surface-neumorph')),
    );
    expect(
      updated.last.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      updated.last.contentSurfaceStyle,
      ExpenseSurfaceInteraction.insetInset,
    );
    expect(
      updated.last.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    await tester.tap(
      find.byKey(const ValueKey('theme-category-menu-surface-neumorph')),
    );
    expect(
      updated.last.categoryMenuSurfaceStyle,
      ExpenseSurfaceInteraction.insetInset,
    );

    await tester.tap(
      find.byKey(const ValueKey('theme-category-menu-presentation-slide')),
    );
    expect(
      updated.last.categoryMenuPresentation,
      CategoryMenuPresentation.slideUpSheet,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('theme-category-card-shadow-off')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('theme-category-card-shadow-off')),
    );
    expect(updated.last.categoryCardShadowEnabled, isFalse);

    await tester.ensureVisible(
      find.byKey(const ValueKey('theme-logbox-shadow-off')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-logbox-shadow-off')));
    expect(updated.last.logboxShadowEnabled, isFalse);

    await tester.ensureVisible(
      find.byKey(const ValueKey('theme-header-pill-shadow-off')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('theme-header-pill-shadow-off')),
    );
    expect(updated.last.headerPillShadowEnabled, isFalse);

    await tester.ensureVisible(
      find.byKey(const ValueKey('theme-summary-pill-shadow-off')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('theme-summary-pill-shadow-off')),
    );
    expect(updated.last.summaryPillShadowEnabled, isFalse);

    await tester.ensureVisible(
      find.byKey(const ValueKey('theme-search-pill-shadow-off')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('theme-search-pill-shadow-off')),
    );
    expect(updated.last.searchPillShadowEnabled, isFalse);

    await tester.tap(
      find.byKey(const ValueKey('theme-category-card-surface-neumorph')),
    );
    expect(
      updated.last.categoryCardSurfaceStyle,
      ExpenseSurfaceInteraction.raisedInset,
    );

    await tester.tap(
      find.byKey(const ValueKey('theme-category-menu-color-darkgray')),
    );
    expect(updated.last.categoryMenuColor, AppBoxColor.darkgray);

    await tester.tap(
      find.byKey(const ValueKey('theme-category-card-color-white')),
    );
    expect(updated.last.categoryCardColor, AppBoxColor.white);

    await tester.tap(find.text('Pink'));
    expect(updated.last.appColor, AppColorMode.pink);
  });

  testWidgets('theme menu exposes partitioned magnet as separate option', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final updated = <AppThemeSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: updated.add,
        ),
      ),
    );

    expect(find.text('Budget vizualizáció'), findsOneWidget);
    expect(find.text('Partitioned budget mágnescsík'), findsOneWidget);

    await tester.tap(find.text('Partitioned budget mágnescsík'));
    await tester.pump();

    expect(updated.single.magnetType, MagnetType.partitionedBudget);
  });

  testWidgets('permissions menu opens Android permission actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Engedélyek'));
    await tester.pumpAndSettle();

    expect(find.text('Engedélyek'), findsOneWidget);
    expect(find.text('Használati útmutató'), findsOneWidget);
    expect(find.text('Android push értesítések'), findsOneWidget);

    final permissionCallsStart = calls.length;
    await tester.tap(find.byKey(const ValueKey('permissions-request-post')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('permissions-app-notifications')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('permissions-app-info')));
    await tester.pumpAndSettle();

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('permissions-options-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('permissions-notification-listener')),
      120,
      scrollable: scrollable,
    );
    await tester.tap(
      find.byKey(const ValueKey('permissions-notification-listener')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('permissions-accessibility')),
      120,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const ValueKey('permissions-accessibility')));
    await tester.pumpAndSettle();

    expect(
      calls.sublist(permissionCallsStart),
      containsAllInOrder([
        'requestPostNotifications',
        'sendTestNotification',
        'openAppNotificationSettings',
        'openAppInfoSettings',
        'openNotificationAccessSettings',
        'openAccessibilitySettings',
      ]),
    );
  });

  testWidgets('sets security pin from settings', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('PIN kód beállítása'), 160);
    await tester.tap(find.text('PIN kód beállítása'));
    await tester.pumpAndSettle();

    expect(find.text('PIN beállítása'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('pin-new-input')), '1234');
    await tester.enterText(
      find.byKey(const ValueKey('pin-confirm-input')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('pin-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('PIN aktív'), findsOneWidget);
    expect(calls, contains('expenseSetSecurityPin'));
  });

  testWidgets('biometric setting requires pin first', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Biometrikus azonosítás'), 160);
    await tester.tap(find.text('Biometrikus azonosítás'));
    await tester.pumpAndSettle();

    expect(find.text('PIN szükséges'), findsOneWidget);
    expect(find.byKey(const ValueKey('biometric-enable-switch')), findsNothing);
  });

  testWidgets(
    'observed app settings manages parser profiles in teaching mode',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Push import'));
      await tester.pumpAndSettle();

      expect(find.text('Profilok'), findsOneWidget);
      expect(find.text('Bank A profil'), findsWidgets);
      expect(
        find.byKey(const ValueKey('notification-parser-add-profile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-parser-profile-icon-bank-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-parser-delete-profile-bank-b')),
        findsOneWidget,
      );
      expect(find.text('App regex'), findsNothing);
      expect(find.text('Tanító mód'), findsOneWidget);
      expect(find.text('Haladó beállítások'), findsOneWidget);
      expect(find.text('Összeg regex'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notification-parser-type-income')).first,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(
        find.byKey(const ValueKey('notification-parser-type-income')).first,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('notification-parser-sample')),
        'Kártyás vásárlás: Tesco - 12 345 HUF',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find
            .byKey(const ValueKey('notification-parser-token-12 345 HUF'))
            .first,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(
        find
            .byKey(const ValueKey('notification-parser-token-12 345 HUF'))
            .first,
      );
      await tester.pumpAndSettle();

      final amountFrame = tester.widget<Container>(
        find
            .byKey(const ValueKey('notification-parser-token-frame-12 345 HUF'))
            .first,
      );
      final amountDecoration = amountFrame.decoration! as BoxDecoration;
      expect((amountDecoration.border! as Border).top.color, AppColors.income);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notification-parser-mode-merchant')).first,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(
        find.byKey(const ValueKey('notification-parser-mode-merchant')).first,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notification-parser-token-Tesco')).first,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(
        find.byKey(const ValueKey('notification-parser-token-Tesco')).first,
      );
      await tester.pumpAndSettle();

      final merchantFrame = tester.widget<Container>(
        find
            .byKey(const ValueKey('notification-parser-token-frame-Tesco'))
            .first,
      );
      final merchantDecoration = merchantFrame.decoration! as BoxDecoration;
      expect(
        (merchantDecoration.border! as Border).top.color,
        const Color(0xFFF97316),
      );

      expect(find.text('12 345 HUF').hitTestable(), findsWidgets);
      expect(find.text('Tesco').hitTestable(), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Haladó beállítások'),
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Haladó beállítások'));
      await tester.pumpAndSettle();
      expect(find.text('Összeg regex'), findsOneWidget);
      expect(find.text('Bolt regex'), findsOneWidget);

      final parsedAppScrollable = find
          .descendant(
            of: find.byKey(const ValueKey('settings-parsed-app-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      final saveButton = find.byKey(
        const ValueKey('notification-parser-save-profile'),
      );
      for (var attempt = 0; attempt < 6; attempt += 1) {
        if (saveButton.hitTestable().evaluate().isNotEmpty) break;
        await tester.drag(parsedAppScrollable, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      expect(saveButton.hitTestable(), findsOneWidget);
      await tester.tap(saveButton.hitTestable().first);
      await tester.pumpAndSettle();

      expect(savedParserRules, isNotEmpty);
      final profiles = savedParserRules.last['profiles'] as List<dynamic>;
      final first = profiles.first as Map<dynamic, dynamic>;
      expect(first['amountSelection'], '12 345 HUF');
      expect(first['merchantSelection'], 'Tesco');
      expect(first['transactionType'], 'income');
    },
  );

  testWidgets('observed app settings can delete parser profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('notification-parser-delete-profile-bank-b')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil törlése'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-delete-profile')));
    await tester.pumpAndSettle();

    expect(savedParserRules, isNotEmpty);
    final profiles = savedParserRules.last['profiles'] as List<dynamic>;
    expect(
      profiles.map((row) => (row as Map<dynamic, dynamic>)['id']),
      isNot(contains('bank-b')),
    );
  });

  testWidgets('settings submenu survives page recreation with same store', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_page_events'),
    );
    final store = EventStore(bridge, realtimeEnabled: false);

    await tester.pumpWidget(buildSubjectWith(bridge: bridge, store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elkapott push üzenetek'));
    await tester.pumpAndSettle();

    expect(find.text('Elkapott push üzenetek'), findsWidgets);

    await tester.pumpWidget(
      buildSubjectWith(key: UniqueKey(), bridge: bridge, store: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elkapott push üzenetek'), findsWidgets);
    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );
  });

  testWidgets('parsed app submenu opens captured push messages log', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Push import'));
    await tester.pumpAndSettle();

    expect(find.text('PushParser napló'), findsOneWidget);
    expect(find.text('Elkapott push üzenetek'), findsOneWidget);

    await tester.tap(find.text('Elkapott push üzenetek'));
    await tester.pumpAndSettle();

    expect(find.text('Elkapott push üzenetek'), findsWidgets);
    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );
    final pushLogBox = find.byKey(const ValueKey('push-logbox-77'));
    expect(pushLogBox, findsOneWidget);
    expect(
      find.descendant(
        of: pushLogBox,
        matching: find.text('Nincs hozzárendelt log'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
    await tester.pumpAndSettle();

    expect(find.text('PushParser napló'), findsOneWidget);
    expect(find.text('Profilok'), findsOneWidget);
  });

  testWidgets('settings submenus stop above the bottom navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('FastInfo'));
    await tester.pumpAndSettle();

    final frame = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('settings-submenu-content-frame')),
    );
    final bottom = frame.localToGlobal(Offset.zero).dy + frame.size.height;

    expect(bottom, 1200 - AppDimensions.bottomNavHeight);
  });
}

Map<String, Object?> pushLogEventRow({
  required int id,
  required String status,
  required String statusText,
  int? linkedTransactionId,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': DateTime(2026, 6, 7, 21, 10).millisecondsSinceEpoch,
    'source': 'notification_listener',
    'packageName': 'hu.bank.app',
    'appLabel': 'Bank',
    'title': 'Vásárlás',
    'text': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': 'n-$id',
    'accessibilityEventType': '',
    'hash': 'h-$id',
    'isDuplicate': false,
    'manualStatus': '',
    'displayText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'status': status,
    'statusText': statusText,
    'linkedTransactionId': linkedTransactionId,
  };
}
