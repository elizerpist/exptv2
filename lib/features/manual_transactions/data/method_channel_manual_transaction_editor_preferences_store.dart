import 'package:flutter/services.dart';

import '../application/manual_transaction_editor_preferences.dart';

/// Stores editor-only presentation choices beside the established dashboard
/// local settings. These choices never mutate a transaction draft or ledger.
final class MethodChannelManualTransactionEditorPreferencesStore
    implements ManualTransactionEditorPreferencesStore {
  MethodChannelManualTransactionEditorPreferencesStore({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('fluvi/dashboard_presentation');

  final MethodChannel _channel;

  @override
  Future<ManualTransactionEditorPreferences> read() async {
    try {
      final values = await _channel.invokeMapMethod<String, Object?>(
        'readManualTransactionEditorSettings',
      );
      if (values == null) return ManualTransactionEditorPreferences.defaults;
      return ManualTransactionEditorPreferences(
        // An absent key is deliberately the documented true default. In
        // particular, never reinterpret the old enum integers as this bool.
        showMetadataIconBackgrounds:
            values['showMetadataIconBackgrounds'] as bool? ?? true,
      );
    } on PlatformException {
      return ManualTransactionEditorPreferences.defaults;
    } on MissingPluginException {
      return ManualTransactionEditorPreferences.defaults;
    }
  }

  @override
  Future<void> write(ManualTransactionEditorPreferences preferences) async {
    try {
      await _channel.invokeMethod<void>(
        'writeManualTransactionEditorSettings',
        {
          'showMetadataIconBackgrounds':
              preferences.showMetadataIconBackgrounds,
        },
      );
    } on PlatformException {
      // The editor remains usable in an embedded or unsupported host; the
      // next opening falls back to the documented first-use defaults.
    } on MissingPluginException {
      return;
    }
  }
}
