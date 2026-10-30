import 'package:flutter/foundation.dart';

enum ManualTransactionEditorLayout { hero, islands }

enum ManualPartnerPickerPresentation { fullScreen, dropdown }

@immutable
final class ManualTransactionEditorPreferences {
  const ManualTransactionEditorPreferences({
    required this.layout,
    required this.partnerPickerPresentation,
  });

  static const defaults = ManualTransactionEditorPreferences(
    layout: ManualTransactionEditorLayout.hero,
    partnerPickerPresentation: ManualPartnerPickerPresentation.fullScreen,
  );

  final ManualTransactionEditorLayout layout;
  final ManualPartnerPickerPresentation partnerPickerPresentation;

  ManualTransactionEditorPreferences copyWith({
    ManualTransactionEditorLayout? layout,
    ManualPartnerPickerPresentation? partnerPickerPresentation,
  }) => ManualTransactionEditorPreferences(
    layout: layout ?? this.layout,
    partnerPickerPresentation:
        partnerPickerPresentation ?? this.partnerPickerPresentation,
  );

  @override
  bool operator ==(Object other) =>
      other is ManualTransactionEditorPreferences &&
      other.layout == layout &&
      other.partnerPickerPresentation == partnerPickerPresentation;

  @override
  int get hashCode => Object.hash(layout, partnerPickerPresentation);
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
