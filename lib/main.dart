import 'package:flutter/material.dart';

import 'exptv2_app.dart';
import 'features/transactions/native/native_ime_sheet_app.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

export 'exptv2_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapCategoryIconsForStartup();
  final bridge = NativeBridge();
  runApp(Exptv2App(store: EventStore(bridge), nativeBridge: bridge));
}

@pragma('vm:entry-point')
Future<void> nativeImeSheetMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NativeImeSheetApp());
}
