import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel('com.fluvi/diagnostics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockStreamHandler(channel, null);
  });

  test(
    'decodes native diagnostic events without owning business state',
    () async {
      final event = <String, Object?>{
        'stage': 'D5',
        'message': 'READ_SERVICE_RESULT',
        'flowId': 'Q-expense|month:2026-07',
        'queryKey': 'expense|month:2026-07',
        'totalMinor': 68900000,
        'entryCount': 94,
        'coreRevision': 12,
      };
      messenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (arguments, events) => events.success(event),
        ),
      );

      final received = await FluviDiagnosticBridge().watch().first;

      expect(received.stage, 'D5');
      expect(received.flowId, 'Q-expense|month:2026-07');
      expect(received.totalMinor, 68900000);
      expect(received.entryCount, 94);
    },
  );
}
