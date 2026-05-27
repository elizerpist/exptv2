class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
  });

  final String packageName;
  final String label;

  String get displayName => label.isNotEmpty ? label : packageName;

  factory InstalledApp.fromMap(Map<dynamic, dynamic> map) {
    return InstalledApp(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
    );
  }
}
