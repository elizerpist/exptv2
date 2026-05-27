import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/expt_shell.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

class Exptv2App extends StatelessWidget {
  const Exptv2App({super.key, required this.store, required this.nativeBridge});

  final EventStore store;
  final NativeBridge nativeBridge;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exptv2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ExptShell(store: store, nativeBridge: nativeBridge),
    );
  }
}
