import 'preview_method_handler.dart';
import 'preview_native_state.dart';

class PreviewSettingsHandler implements PreviewMethodHandler {
  PreviewSettingsHandler(this.state);

  final PreviewNativeState state;

  static const _methods = <String>{
    'listInstalledApps',
    'expenseLoadSettings',
    'expenseUpdateThemeSettings',
    'expenseUpdateFastInfoConfig',
    'expenseSaveTextFile',
    'expenseShareTextFile',
    'expenseUpdatePushRecurringSettings',
    'expenseUpdateNotificationSettings',
    'expenseSetSecurityPin',
    'expenseChangeSecurityPin',
    'expenseClearSecurityPin',
    'expenseVerifySecurityPin',
    'expenseSetBiometricEnabled',
    'expenseGetBiometricAvailability',
    'expenseAuthenticateBiometric',
    'loadNotificationParserProfiles',
    'saveNotificationParserProfiles',
    'loadNotificationParserRule',
    'saveNotificationParserRule',
    'loadAutomaticPushParserEnabled',
    'saveAutomaticPushParserEnabled',
  };

  static const _disabledSecurity = <String, Object?>{
    'pinEnabled': false,
    'biometricEnabled': false,
    'biometricAvailable': false,
    'biometricLabel': 'Nem elerheto',
  };

  @override
  Set<String> get supportedMethods => _methods;

  @override
  Future<Object?> invoke(String method, Object? arguments) async {
    if (method == 'saveAutomaticPushParserEnabled') {
      final enabled = _bool(arguments);
      state.automaticPushParserEnabled = enabled;
      return enabled;
    }

    final payload = _arguments(arguments);
    return switch (method) {
      'listInstalledApps' => <Map<String, Object?>>[],
      'expenseLoadSettings' => _loadSettings(),
      'expenseUpdateThemeSettings' => _updateMap(state.themeSettings, payload),
      'expenseUpdateFastInfoConfig' => _updateMap(
        state.fastInfoConfig,
        payload,
      ),
      'expenseSaveTextFile' => _saveTextFile(payload),
      'expenseShareTextFile' => _shareTextFile(payload),
      'expenseUpdatePushRecurringSettings' => _updateMap(
        state.pushRecurringSettings,
        payload,
      ),
      'expenseUpdateNotificationSettings' => _updateMap(
        state.notificationSettings,
        payload,
      ),
      'expenseSetSecurityPin' ||
      'expenseChangeSecurityPin' ||
      'expenseClearSecurityPin' ||
      'expenseSetBiometricEnabled' ||
      'expenseGetBiometricAvailability' => _securityDisabled(),
      'expenseVerifySecurityPin' || 'expenseAuthenticateBiometric' => false,
      'loadNotificationParserProfiles' => previewDeepCopyMap(
        state.notificationParserConfig,
      ),
      'saveNotificationParserProfiles' => _saveParserProfiles(payload),
      'loadNotificationParserRule' => _loadParserRule(),
      'saveNotificationParserRule' => _saveParserRule(payload),
      'loadAutomaticPushParserEnabled' => state.automaticPushParserEnabled,
      _ => throw UnsupportedError(
        'Unsupported preview settings method: $method',
      ),
    };
  }

  Map<String, Object?> _loadSettings() => <String, Object?>{
    'themeSettings': previewDeepCopyMap(state.themeSettings),
    'fastInfoConfig': previewDeepCopyMap(state.fastInfoConfig),
    'pushRecurringSettings': previewDeepCopyMap(state.pushRecurringSettings),
    'notificationSettings': previewDeepCopyMap(state.notificationSettings),
    'securitySettings': _securityDisabled(),
  };

  Map<String, Object?> _updateMap(
    Map<String, Object?> target,
    Map<String, Object?> payload,
  ) {
    target.addAll(previewDeepCopyMap(payload));
    return previewDeepCopyMap(target);
  }

  String _saveTextFile(Map<String, Object?> payload) {
    _recordExport(payload);
    return 'memory://${Uri.encodeComponent(state.lastExportFileName ?? '')}';
  }

  Object? _shareTextFile(Map<String, Object?> payload) {
    _recordExport(payload);
    return null;
  }

  void _recordExport(Map<String, Object?> payload) {
    state.lastExportFileName = payload['fileName']?.toString() ?? '';
    state.lastExportMimeType = payload['mimeType']?.toString() ?? '';
    state.lastExportContent = payload['content']?.toString() ?? '';
  }

  Map<String, Object?> _securityDisabled() {
    state.securitySettings
      ..clear()
      ..addAll(_disabledSecurity);
    return Map<String, Object?>.from(_disabledSecurity);
  }

  Map<String, Object?> _saveParserProfiles(Map<String, Object?> payload) {
    state.notificationParserConfig = previewDeepCopyMap(payload);
    return previewDeepCopyMap(state.notificationParserConfig);
  }

  Map<String, Object?> _loadParserRule() {
    final profiles = state.notificationParserConfig['profiles'];
    if (profiles is List && profiles.isNotEmpty && profiles.first is Map) {
      return previewDeepCopyMap(profiles.first as Map);
    }
    return <String, Object?>{};
  }

  Map<String, Object?> _saveParserRule(Map<String, Object?> payload) {
    final profiles = state.notificationParserConfig['profiles'];
    if (profiles is List && profiles.isNotEmpty && profiles.first is Map) {
      final updated = <String, Object?>{
        ...previewDeepCopyMap(profiles.first as Map),
        ...previewDeepCopyMap(payload),
      };
      profiles[0] = updated;
    } else {
      state.notificationParserConfig = <String, Object?>{
        'profiles': <Map<String, Object?>>[previewDeepCopyMap(payload)],
      };
    }
    return previewDeepCopyMap(payload);
  }
}

Map<String, Object?> _arguments(Object? arguments) {
  if (arguments == null) return <String, Object?>{};
  if (arguments is! Map) {
    throw ArgumentError.value(arguments, 'arguments', 'Expected a map');
  }
  return arguments.map(
    (key, value) => MapEntry(key.toString(), value as Object?),
  );
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}
