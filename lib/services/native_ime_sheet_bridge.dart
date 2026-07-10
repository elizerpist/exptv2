import 'package:flutter/services.dart';

import '../features/transactions/models/transaction_category.dart';

class NativeImeSheetBridge {
  NativeImeSheetBridge({
    MethodChannel? methodChannel,
    Future<void> Function()? onTransactionCommitted,
    Future<void> Function()? onSheetClosed,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('exptv2/native_ime_sheet'),
       _onTransactionCommitted = onTransactionCommitted,
       _onSheetClosed = onSheetClosed {
    if (_onTransactionCommitted != null || _onSheetClosed != null) {
      _methodChannel.setMethodCallHandler(_handleNativeCall);
    }
  }

  final MethodChannel _methodChannel;
  final Future<void> Function()? _onTransactionCommitted;
  final Future<void> Function()? _onSheetClosed;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'transactionCommitted':
        await _onTransactionCommitted?.call();
        return null;
      case 'sheetClosed':
        await _onSheetClosed?.call();
        return null;
      default:
        throw MissingPluginException(
          'No native IME sheet handler for ${call.method}',
        );
    }
  }

  Future<void> openProbe() async {
    await _methodChannel.invokeMethod<void>('openProbe');
  }

  Future<void> closeProbe() async {
    await _methodChannel.invokeMethod<void>('closeProbe');
  }

  Future<bool> openAddTransaction({required TransactionType type}) async {
    try {
      final opened = await _methodChannel.invokeMethod<bool>(
        'openAddTransaction',
        {'type': type.nativeValue},
      );
      return opened == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<Map<dynamic, dynamic>> getInitialState() async {
    final state = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'getInitialState',
    );
    return state ?? <dynamic, dynamic>{};
  }

  Future<void> closeSheet() async {
    await _methodChannel.invokeMethod<void>('closeSheet');
  }

  Future<void> notifyTransactionCommitted() async {
    await _methodChannel.invokeMethod<void>('transactionCommitted');
  }

  void dispose() {
    if (_onTransactionCommitted != null || _onSheetClosed != null) {
      _methodChannel.setMethodCallHandler(null);
    }
  }
}
