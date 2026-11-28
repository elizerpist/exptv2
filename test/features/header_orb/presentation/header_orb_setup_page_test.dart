import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/header_orb/presentation/header_orb_setup_page.dart';

void main() {
  const methods = MethodChannel('fluvi/header_orb_widget');
  const states = MethodChannel('fluvi/header_orb_state');
  const app = MaterialApp(home: HeaderOrbSetupPage());

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
