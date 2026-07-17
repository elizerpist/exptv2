import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/services/native_bridge_transport.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingTransport implements NativeBridgeTransport {
  final calls = <String>[];

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(method);
    if (method == 'getStatus') {
      return <String, Object?>{
            'captureMode': 'both',
            'notificationListenerEnabled': false,
            'accessibilityEnabled': false,
            'notificationListenerActive': false,
            'accessibilityActive': false,
            'totalEvents': 0,
          }
          as T;
    }
    return null;
  }

  @override
  Future<List<T>?> invokeListMethod<T>(
    String method, [
    Object? arguments,
  ]) async {
    calls.add(method);
    return <T>[];
  }

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    Object? arguments,
  ]) async {
    final value = await invokeMethod<Object?>(method, arguments);
    return (value as Map?)?.cast<K, V>();
  }

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) =>
      const Stream<Object?>.empty();
}

void main() {
  test('NativeBridge delegates method, list, map, and event work', () async {
    final transport = RecordingTransport();
    final bridge = NativeBridge(transport: transport);

    await bridge.loadEvents();
    await bridge.getStatus();
    await bridge.watchEvents().drain<void>();

    expect(transport.calls, containsAll(<String>['loadEvents', 'getStatus']));
  });
}
