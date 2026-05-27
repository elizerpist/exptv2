class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.text,
    required this.bigText,
    required this.subText,
    required this.category,
    required this.notificationKey,
    required this.accessibilityEventType,
    required this.hash,
    required this.isDuplicate,
  });

  final int id;
  final DateTime timestamp;
  final String source;
  final String packageName;
  final String appLabel;
  final String title;
  final String text;
  final String bigText;
  final String subText;
  final String category;
  final String notificationKey;
  final String accessibilityEventType;
  final String hash;
  final bool isDuplicate;

  String get sourceBadge {
    if (source == 'notification_listener') return 'NL';
    if (source == 'accessibility') return 'ACC';
    return source.toUpperCase();
  }

  String get displayApp => appLabel.isNotEmpty ? appLabel : packageName;

  String get bodyText {
    final parts = <String>[
      text,
      bigText,
      subText,
    ].where((value) => value.trim().isNotEmpty).toSet().toList();
    return parts.join('\n');
  }

  bool matchesApp(RegExp regex) {
    return regex.hasMatch(appLabel) || regex.hasMatch(packageName);
  }

  factory NotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    String readString(String key) => (map[key] as String?) ?? '';
    return NotificationEvent(
      id: (map['id'] as num).toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
      source: readString('source'),
      packageName: readString('packageName'),
      appLabel: readString('appLabel'),
      title: readString('title'),
      text: readString('text'),
      bigText: readString('bigText'),
      subText: readString('subText'),
      category: readString('category'),
      notificationKey: readString('notificationKey'),
      accessibilityEventType: readString('accessibilityEventType'),
      hash: readString('hash'),
      isDuplicate: map['isDuplicate'] == true,
    );
  }
}
