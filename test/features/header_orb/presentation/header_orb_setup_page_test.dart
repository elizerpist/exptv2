import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/header_orb/presentation/header_orb_setup_page.dart';

void main() {
  const methods = MethodChannel('fluvi/header_orb_widget');
  const states = MethodChannel('fluvi/header_orb_state');
  const app = MaterialApp(home: HeaderOrbSetupPage());

  testWidgets('permanent ORB uses its own persisted lockscreen setting', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final actions = <MethodCall>[];
    final saved = <String, Object?>{
      'state': 'ready',
      'sizeDp': 112,
      'style56': 'fluviMask',
      'style112': 'orb',
    };
    messenger.setMockMethodCallHandler(states, (_) async => null);
    messenger.setMockMethodCallHandler(methods, (call) async {
      actions.add(call);
      if (call.method == 'setPermanentOrb') {
        saved['permanentOrb'] = call.arguments['enabled'];
      }
      return Map<String, Object?>.of(saved);
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(methods, null);
      messenger.setMockMethodCallHandler(states, null);
    });
    final toggle = find.byKey(const ValueKey('balance-orb-permanent'));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(actions.last.method, 'setPermanentOrb');
    expect(actions.last.arguments, {'enabled': true});
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      find.text('A telefon AOD-támogatása még nincs megállapítva.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(saved['sizeDp'], 112);
    expect(saved['style56'], 'fluviMask');
    expect(saved['style112'], 'orb');
    expect(
      actions.map((call) => call.method),
      everyElement(isIn(['settingsResumed', 'setPermanentOrb'])),
    );
  });

  testWidgets('AOD copy calls its own receipt without starting a capture', (
    tester,
  ) async {
    const capture = MethodChannel('fluvi/wa_lockscreen_capture');
    const report = 'FLUVI_WA_AMBIENT_V1\nphysicalVisibility=UNOBSERVED\n';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final actions = <String>[];
    String? copied;
    messenger.setMockMethodCallHandler(
      methods,
      (_) async => {'state': 'ready', 'sizeDp': 56, 'permanentOrb': true},
    );
    messenger.setMockMethodCallHandler(states, (_) async => null);
    messenger.setMockMethodCallHandler(capture, (call) async {
      actions.add(call.method);
      return {'status': 'READY', 'text': report};
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = call.arguments['text'] as String;
      }
      return null;
    });
    addTearDown(() {
      for (final channel in [
        methods,
        states,
        capture,
        SystemChannels.platform,
      ]) {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    final button = find.text('Legutóbbi AOD-próba másolása');
    await tester.scrollUntilVisible(button, 160);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(actions, ['getLastAmbient']);
    expect(copied, report);
    expect(find.text('Az AOD-napló a vágólapon van.'), findsOneWidget);
  });

  testWidgets(
    'last unlock copy handles waiting, storage and clipboard retries',
    (tester) async {
      const capture = MethodChannel('fluvi/wa_lockscreen_capture');
      const report = 'FLUVI_WA_LAST_UNLOCK_V1\nbodySha256=fixture\n';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var status = 'INACTIVE';
      var value = '';
      var clipboardFails = true;
      final copied = <String>[];
      messenger.setMockMethodCallHandler(
        methods,
        (_) async => {'state': 'ready', 'sizeDp': 112},
      );
      messenger.setMockMethodCallHandler(states, (_) async => null);
      messenger.setMockMethodCallHandler(capture, (call) async {
        expect(call.method, 'getLastUnlock');
        return {'status': status, 'text': value};
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (clipboardFails) throw PlatformException(code: 'clipboard');
          copied.add(call.arguments['text'] as String);
        }
        return null;
      });
      addTearDown(() {
        for (final channel in [
          methods,
          states,
          capture,
          SystemChannels.platform,
        ]) {
          messenger.setMockMethodCallHandler(channel, null);
        }
      });
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      Future<void> press() async {
        final button = find.text('Legutóbbi feloldás másolása');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await press();
      expect(find.text('Az ORB-szolgáltatásra várunk.'), findsOneWidget);
      status = 'EMPTY';
      await press();
      expect(
        find.text('Még nincs napló. Oldd fel a telefont látható ORB mellett.'),
        findsOneWidget,
      );
      status = 'STORAGE_ERROR';
      await press();
      expect(
        find.text('A feloldási napló nem olvasható. Próbáld újra.'),
        findsOneWidget,
      );
      status = 'READY';
      await press();
      expect(copied, isEmpty);
      value = report;
      await press();
      expect(find.text('A másolás sikertelen. Próbáld újra.'), findsOneWidget);
      expect(copied, isEmpty);
      clipboardFails = false;
      await press();
      expect(find.text('A feloldási napló a vágólapon van.'), findsOneWidget);
      expect(copied, [report]);
    },
  );

  testWidgets('styles are independent of active size and restore on reopen', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final saved = <String, Object?>{'state': 'ready', 'sizeDp': 112};
    final actions = <MethodCall>[];
    messenger.setMockMethodCallHandler(states, (_) async => null);
    messenger.setMockMethodCallHandler(methods, (call) async {
      actions.add(call);
      if (call.method == 'selectStyle') {
        final args = call.arguments as Map<Object?, Object?>;
        saved['style${args['dp']}'] = args['style'];
      }
      if (call.method == 'selectSize') {
        saved['sizeDp'] = call.arguments['dp'];
      }
      return Map<String, Object?>.of(saved);
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(methods, null);
      messenger.setMockMethodCallHandler(states, null);
    });

    Finder style(int dp, String value) =>
        find.byKey(ValueKey('balance-orb-style-$dp-$value'));
    bool isSelected(int dp, String value) =>
        tester.widget<ChoiceChip>(style(dp, value)).selected;
    Future<void> choose(Finder item) async {
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(isSelected(56, 'orb'), isTrue);
    expect(isSelected(112, 'orb'), isTrue);

    await choose(style(56, 'fluviMask'));
    expect(saved['sizeDp'], 112);
    expect(actions.last.method, 'selectStyle');
    expect(actions.last.arguments, {'dp': 56, 'style': 'fluviMask'});
    expect(isSelected(56, 'fluviMask'), isTrue);
    expect(isSelected(112, 'orb'), isTrue);

    await choose(find.text('1×1 (56 dp)'));
    expect(saved['sizeDp'], 56);
    expect(isSelected(56, 'fluviMask'), isTrue);
    await choose(style(112, 'fluviMask'));
    expect(saved['sizeDp'], 56);
    await choose(style(56, 'orb'));
    expect(actions.where((call) => call.method == 'selectSize'), hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(isSelected(56, 'orb'), isTrue);
    expect(isSelected(112, 'fluviMask'), isTrue);
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('balance-orb-size-56')))
          .selected,
      isTrue,
    );
  });
}
