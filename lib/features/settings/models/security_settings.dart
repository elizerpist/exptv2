class SecuritySettings {
  const SecuritySettings({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.biometricAvailable,
    required this.biometricLabel,
  });

  factory SecuritySettings.defaults() {
    return const SecuritySettings(
      pinEnabled: false,
      biometricEnabled: false,
      biometricAvailable: false,
      biometricLabel: 'Nem elerheto',
    );
  }

  factory SecuritySettings.fromMap(Map<dynamic, dynamic> map) {
    final pinEnabled = map['pinEnabled'] == true;
    final biometricAvailable = map['biometricAvailable'] == true;
    final biometricEnabled = pinEnabled && map['biometricEnabled'] == true;
    final label = map['biometricLabel']?.toString().trim();
    return SecuritySettings(
      pinEnabled: pinEnabled,
      biometricEnabled: biometricEnabled,
      biometricAvailable: biometricAvailable,
      biometricLabel: label == null || label.isEmpty ? 'Nem elerheto' : label,
    );
  }

  final bool pinEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final String biometricLabel;

  bool get authEnabled => pinEnabled || biometricEnabled;
  bool get biometricReady =>
      pinEnabled && biometricEnabled && biometricAvailable;

  SecuritySettings copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
    String? biometricLabel,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricLabel: biometricLabel ?? this.biometricLabel,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'pinEnabled': pinEnabled,
      'biometricEnabled': biometricEnabled,
      'biometricAvailable': biometricAvailable,
      'biometricLabel': biometricLabel,
    };
  }
}
