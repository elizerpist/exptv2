import 'package:flutter/material.dart';

class FluviApp extends StatelessWidget {
  const FluviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: Colors.grey.shade100),
      home: const Scaffold(
        key: ValueKey('fluvi-app-shell'),
        body: Center(child: Text('Dashboard')),
      ),
    );
  }
}
