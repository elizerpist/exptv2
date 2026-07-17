import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class AppKeyboardProvider extends StatelessWidget {
  const AppKeyboardProvider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => KeyboardProvider(child: child);
}
