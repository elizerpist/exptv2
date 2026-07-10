import 'package:flutter/services.dart';

class NativeImeSheetBridge {
  NativeImeSheetBridge({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('exptv2/native_ime_sheet');

  final MethodChannel _methodChannel;

  Future<void> openProbe() async {
    await _methodChannel.invokeMethod<void>('openProbe');
  }

  Future<void> closeProbe() async {
    await _methodChannel.invokeMethod<void>('closeProbe');
  }
}
