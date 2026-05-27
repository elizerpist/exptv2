import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

void main() {
  runApp(PushParserApp(store: EventStore(NativeBridge())));
}

class PushParserApp extends StatelessWidget {
  const PushParserApp({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PushParserV2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: MainScreen(store: store),
    );
  }
}
