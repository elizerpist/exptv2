import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

ValueListenable<double>? appKeyboardHeightNotifierOf(BuildContext context) =>
    context.keyboardOrNull?.heightNotifier;
