import 'native_bridge.dart';
import 'preview/preview_native_bridge_transport.dart';

NativeBridge createNativeBridge() =>
    NativeBridge(transport: PreviewNativeBridgeTransport());
