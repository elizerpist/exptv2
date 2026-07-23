import '../native_bridge_transport.dart';
import 'preview_activity_handler.dart';
import 'preview_method_handler.dart';
import 'preview_native_state.dart';
import 'preview_settings_handler.dart';
import 'preview_transaction_handler.dart';

class PreviewNativeBridgeTransport implements NativeBridgeTransport {
  PreviewNativeBridgeTransport({
    PreviewNativeState? state,
    List<PreviewMethodHandler>? handlers,
  }) : state = state ?? PreviewNativeState.seeded() {
    final sources =
        handlers ??
        <PreviewMethodHandler>[
          PreviewTransactionHandler(this.state),
          PreviewSettingsHandler(this.state),
          PreviewActivityHandler(this.state),
        ];
    for (final handler in sources) {
      for (final method in handler.supportedMethods) {
        if (_routes.containsKey(method)) {
          throw StateError('Duplicate preview method route: $method');
        }
        _routes[method] = handler;
      }
    }
  }

  final PreviewNativeState state;
  final Map<String, PreviewMethodHandler> _routes =
      <String, PreviewMethodHandler>{};

  Future<Object?> _dispatch(String method, Object? arguments) {
    final handler = _routes[method];
    if (handler == null) {
      throw UnsupportedError('Unsupported preview bridge method: $method');
    }
    return handler.invoke(method, arguments);
  }

  @override
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) async =>
      await _dispatch(method, arguments) as T?;

  @override
  Future<List<T>?> invokeListMethod<T>(
    String method, [
    Object? arguments,
  ]) async => (await _dispatch(method, arguments) as List?)?.cast<T>();

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    Object? arguments,
  ]) async => (await _dispatch(method, arguments) as Map?)?.cast<K, V>();

  @override
  Stream<Object?> receiveBroadcastStream([Object? arguments]) =>
      state.eventController.stream;
}
