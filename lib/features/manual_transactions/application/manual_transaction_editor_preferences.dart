import 'package:flutter/foundation.dart';

@immutable
final class ManualTransactionEditorPreferences {
  const ManualTransactionEditorPreferences({
    this.showMetadataIconBackgrounds = true,
  });

  static const defaults = ManualTransactionEditorPreferences(
    showMetadataIconBackgrounds: true,
  );

  /// The only editor presentation preference. Legacy layout and picker-mode
  /// values are intentionally neither decoded nor allowed to affect the UI.
  final bool showMetadataIconBackgrounds;

  ManualTransactionEditorPreferences copyWith({
    bool? showMetadataIconBackgrounds,
  }) => ManualTransactionEditorPreferences(
    showMetadataIconBackgrounds:
        showMetadataIconBackgrounds ?? this.showMetadataIconBackgrounds,
  );

  @override
  bool operator ==(Object other) =>
      other is ManualTransactionEditorPreferences &&
      other.showMetadataIconBackgrounds == showMetadataIconBackgrounds;

  @override
  int get hashCode => showMetadataIconBackgrounds.hashCode;
}

abstract interface class ManualTransactionEditorPreferencesStore {
  Future<ManualTransactionEditorPreferences> read();
  Future<void> write(ManualTransactionEditorPreferences preferences);
}

/// Safe test/web fallback. Native hosts replace this with the existing local
/// dashboard-presentation preference channel.
final class DefaultManualTransactionEditorPreferencesStore
    implements ManualTransactionEditorPreferencesStore {
  const DefaultManualTransactionEditorPreferencesStore();

  @override
  Future<ManualTransactionEditorPreferences> read() async =>
      ManualTransactionEditorPreferences.defaults;

  @override
  Future<void> write(ManualTransactionEditorPreferences preferences) async {}
}
