import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/keyguard_timing_capture_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluvi/runtime_monitoring');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('starts native capture with immutable build identity', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return <String, Object?>{
            'available': true,
            'captureState': 'REC',
            'captureId': 'capture-1',
            'attemptCount': 0,
            'eventsRecorded': 1,
            'eventsRetained': 1,
            'eventsEvicted': 0,
            'eventsCoalesced': 0,
            'report': 'FLUVI_KEYGUARD_TIMING_CAPTURE_V1',
          };
        });

    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => true,
    );
    final snapshot = await bridge.start();

    expect(received?.method, 'startKeyguardDiagnosticCapture');
    expect((received?.arguments as Map)['build'], isNotEmpty);
    expect((received?.arguments as Map)['captureMode'], 'LIGHT');
    expect((received?.arguments as Map)['r43Evidence'], isFalse);
    expect(snapshot.recording, isTrue);
    expect(snapshot.captureId, 'capture-1');
  });

  test('R43 evidence must be explicitly requested', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return <String, Object?>{'available': true, 'captureState': 'REC'};
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => true,
    );
    await bridge.start(r43Evidence: true);
    expect(received?.method, 'startKeyguardDiagnosticCapture');
    expect((received?.arguments as Map)['r43Evidence'], isTrue);
  });

  test('can explicitly request the full native causal capture', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return <String, Object?>{
            'available': true,
            'captureState': 'REC',
            'captureId': 'capture-full',
            'attemptCount': 0,
            'eventsRecorded': 1,
            'eventsRetained': 1,
            'eventsEvicted': 0,
            'eventsCoalesced': 0,
            'captureMode': 'FULL',
            'report': '',
          };
        });

    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => true,
    );
    await bridge.start(mode: KeyguardTimingCaptureMode.full);

    expect((received?.arguments as Map)['captureMode'], 'FULL');
  });

  test('does not invoke a platform channel outside Android', () async {
    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => false,
    );

    final snapshot = await bridge.get();

    expect(snapshot.available, isFalse);
    expect(snapshot.message, contains('Androidon'));
  });

  test('route selection reports the pending hidden boundary', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, Object?>{
            'available': true,
            'configured': 'SURFACE_STATIC',
            'effective': 'SURFACE_LIVE',
            'pendingBoundary': true,
          };
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => true,
    );

    final status = await bridge.setRenderMode(
      KeyguardOrbRenderMode.surfaceStatic,
    );
    expect(calls.single.method, 'setKeyguardOrbRenderMode');
    expect((calls.single.arguments as Map)['mode'], 'SURFACE_STATIC');
    expect(status.configured, KeyguardOrbRenderMode.surfaceStatic);
    expect(status.effective, KeyguardOrbRenderMode.surfaceLive);
    expect(status.pendingBoundary, isTrue);
  });

  test('route controls remain unavailable off Android', () async {
    final bridge = KeyguardTimingCaptureBridge(
      channel: channel,
      isAndroid: () => false,
    );
    expect((await bridge.getRenderMode()).available, isFalse);
  });
}
