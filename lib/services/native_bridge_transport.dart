import 'package:flutter/services.dart';

abstract interface class NativeBridgeTransport {
  Future<T?> invokeMethod<T>(String method, [Object? arguments]);

  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]);

  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [Object? arguments]);

  Stream<Object?> receiveBroadcastStream([Object? arguments]);
}

class MethodChannelNativeBridgeTransport implements NativeBridgeTransport {
  MethodChannelNativeBridgeTransport({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('pushparser/methods'),
       _eventChannel = eventChannel ?? const EventChannel('pushparser/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) =>
      _methodChannel.invokeMethod<T>(method, arguments);

  @override
  Future<List<T>?> invokeListMethod<T>(String method, [Object? arguments]) =>
      _methodChannel.invokeListMethod<T>(method, arguments);

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    Object? arguments,
  ]) => _methodChannel.invokeMapMethod<K, V>(method, arguments);

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) =>
      _eventChannel.receiveBroadcastStream(arguments);
}
