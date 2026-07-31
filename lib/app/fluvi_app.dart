import 'package:flutter/material.dart';

import '../core/design/dashboard_mode_palette.dart';
import 'shell/fluvi_app_shell.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: FluviVisualTokens.pageBackground),
      home: const FluviAppShell(),
    );
  }
}
