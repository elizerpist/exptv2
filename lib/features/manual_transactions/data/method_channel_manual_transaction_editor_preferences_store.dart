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
        layout: _enumValue(
          ManualTransactionEditorLayout.values,
          values['layout'] as int?,
          ManualTransactionEditorLayout.hero,
        ),
        partnerPickerPresentation: _enumValue(
          ManualPartnerPickerPresentation.values,
          values['partnerPickerPresentation'] as int?,
          ManualPartnerPickerPresentation.fullScreen,
        ),
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
      await _channel
          .invokeMethod<void>('writeManualTransactionEditorSettings', {
            'layout': preferences.layout.index,
            'partnerPickerPresentation':
                preferences.partnerPickerPresentation.index,
          });
    } on PlatformException {
      // The editor remains usable in an embedded or unsupported host; the
      // next opening falls back to the documented first-use defaults.
    } on MissingPluginException {
      return;
    }
  }
}

T _enumValue<T extends Enum>(List<T> values, int? index, T fallback) =>
    index != null && index >= 0 && index < values.length
    ? values[index]
    : fallback;
