import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/services/preview/preview_method_handler.dart';
import 'package:exptv2/services/preview/preview_native_bridge_transport.dart';
import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes real NativeBridge decoders through preview payloads', () async {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    addTearDown(state.dispose);
    final transport = PreviewNativeBridgeTransport(state: state);
    final bridge = NativeBridge(transport: transport);

    final bootstrap = await bridge.expenseLoadBootstrap();
    final settings = await bridge.expenseLoadSettings();
    final cards = await bridge.expenseListNotificationCards();
    final recurring = await bridge.expenseListRecurringRules();
    final events = await bridge.loadEvents();

    expect(bootstrap.categories, hasLength(8));
    expect(bootstrap.transactions, hasLength(20));
    expect(settings.securitySettings.authEnabled, isFalse);
    expect(cards, isNotEmpty);
    expect(recurring, isNotEmpty);
    expect(events, isNotEmpty);
  });

  test('bridge mutations share the transport session state', () async {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    addTearDown(state.dispose);
    final bridge = NativeBridge(
      transport: PreviewNativeBridgeTransport(state: state),
    );

    final added = await bridge.expenseAddTransaction(<String, Object?>{
      'date': '2026.07.18',
      'time': '12:30',
      'merchant': 'Browser Cafe',
      'amount': 2100,
      'type': 'expense',
      'transactionCategoryID': 1,
    });

    expect(added.amount, -2100);
    expect(
      state.transactions.singleWhere(
        (row) => row['id'] == added.id,
      )['merchant'],
      'Browser Cafe',
    );
  });

  test('unknown methods fail with the missing method name', () async {
    final transport = PreviewNativeBridgeTransport();
    addTearDown(transport.state.dispose);

    await expectLater(
      transport.invokeMethod<Object?>('unmappedMethod'),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('unmappedMethod'),
        ),
      ),
    );
  });

  test('duplicate handler routes are rejected at construction', () {
    final state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    addTearDown(state.dispose);
    final handlers = <PreviewMethodHandler>[
      _StubHandler('sameMethod'),
      _StubHandler('sameMethod'),
    ];

    expect(
      () => PreviewNativeBridgeTransport(state: state, handlers: handlers),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('sameMethod'),
        ),
      ),
    );
  });
}

class _StubHandler implements PreviewMethodHandler {
  _StubHandler(this.method);

  final String method;

  @override
  Set<String> get supportedMethods => <String>{method};

  @override
  Future<Object?> invoke(String method, Object? arguments) async => null;
}
