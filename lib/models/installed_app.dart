class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.iconBase64,
  });

  final String packageName;
  final String label;
  final String iconBase64;

  String get displayName => label.isNotEmpty ? label : packageName;

  bool get hasIcon => iconBase64.isNotEmpty;

  factory InstalledApp.fromMap(Map<dynamic, dynamic> map) {
    return InstalledApp(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      iconBase64: (map['iconBase64'] as String?) ?? '',
    );
  }
}
