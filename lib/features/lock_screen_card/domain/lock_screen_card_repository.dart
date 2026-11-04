abstract interface class LockScreenCardRepository {
  Future<LockScreenCardStatus> load();
  Future<LockScreenCardStatus> save(LockScreenCardConfiguration configuration);

  /// Opens exactly the channel that owns the Fluvi card. This is deliberately
  /// separate from generic app notification settings because lock-screen
  /// visibility and silent-channel policy belong to Android/the launcher.
  Future<void> openRuntimeNotificationChannelSettings();
}

enum LockScreenCardMode { mind, balance, budget }

enum LockScreenCardTimeAxis { sum, year, month, day }

enum LockScreenCardDirection { income, expense }

enum LockScreenCardEventLine { related, processed, hidden }

enum LockScreenCardPrivacy { discreet, full }

final class LockScreenCardConfiguration {
  const LockScreenCardConfiguration({
    required this.enabled,
    required this.mode,
    required this.timeAxis,
    required this.direction,
    this.categoryId,
    required this.eventLine,
    required this.privacy,
    required this.valid,
  });

  factory LockScreenCardConfiguration.fromMap(Map<Object?, Object?> map) =>
      LockScreenCardConfiguration(
        enabled: map['enabled'] as bool? ?? false,
        mode: _enumByName(LockScreenCardMode.values, map['mode'] as String?),
        timeAxis: _enumByName(
          LockScreenCardTimeAxis.values,
          map['timeAxis'] as String?,
        ),
        direction: _enumByName(
          LockScreenCardDirection.values,
          map['direction'] as String?,
        ),
        categoryId: map['categoryId'] as String?,
        eventLine: _enumByName(
          LockScreenCardEventLine.values,
          map['eventLine'] as String?,
        ),
        privacy: _enumByName(
          LockScreenCardPrivacy.values,
          map['privacy'] as String?,
        ),
        valid: map['valid'] as bool? ?? false,
      );

  final bool enabled;
  final LockScreenCardMode mode;
  final LockScreenCardTimeAxis timeAxis;
  final LockScreenCardDirection direction;
  final String? categoryId;
  final LockScreenCardEventLine eventLine;
  final LockScreenCardPrivacy privacy;
  final bool valid;

  LockScreenCardConfiguration copyWith({
    bool? enabled,
    LockScreenCardMode? mode,
    LockScreenCardTimeAxis? timeAxis,
    LockScreenCardDirection? direction,
    String? categoryId,
    bool clearCategory = false,
    LockScreenCardEventLine? eventLine,
    LockScreenCardPrivacy? privacy,
    bool? valid,
  }) => LockScreenCardConfiguration(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    timeAxis: timeAxis ?? this.timeAxis,
    direction: direction ?? this.direction,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    eventLine: eventLine ?? this.eventLine,
    privacy: privacy ?? this.privacy,
    valid: valid ?? this.valid,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'enabled': enabled,
    'mode': mode.name,
    'timeAxis': timeAxis.name,
    'direction': direction.name,
    'categoryId': categoryId,
    'eventLine': eventLine.name,
    'privacy': privacy.name,
  };
}

final class LockScreenCardStatus {
  const LockScreenCardStatus({
    required this.configuration,
    required this.content,
    required this.categories,
    required this.postNotificationsGranted,
    required this.statusChannelEnabled,
    required this.statusChannelImportance,
  });

  factory LockScreenCardStatus.fromMap(Map<Object?, Object?> map) {
    final rawConfiguration =
        map['configuration'] as Map<Object?, Object?>? ??
        const <Object?, Object?>{};
    final rawContent =
        map['content'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    return LockScreenCardStatus(
      configuration: LockScreenCardConfiguration.fromMap(rawConfiguration),
      content: LockScreenCardContent.fromMap(rawContent),
      categories: ((map['categories'] as List<Object?>?) ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(LockScreenCardCategory.fromMap)
          .toList(growable: false),
      postNotificationsGranted:
          map['postNotificationsGranted'] as bool? ?? false,
      statusChannelEnabled: map['statusChannelEnabled'] as bool? ?? true,
      statusChannelImportance:
          map['statusChannelImportance'] as String? ?? 'Ismeretlen',
    );
  }

  final LockScreenCardConfiguration configuration;
  final LockScreenCardContent content;
  final List<LockScreenCardCategory> categories;
  final bool postNotificationsGranted;
  final bool statusChannelEnabled;
  final String statusChannelImportance;
}

final class LockScreenCardContent {
  const LockScreenCardContent({
    required this.focus,
    required this.primary,
    required this.secondary,
    this.event,
    this.eventLabel,
    required this.available,
  });

  factory LockScreenCardContent.fromMap(Map<Object?, Object?> map) =>
      LockScreenCardContent(
        focus: map['focus'] as String? ?? 'Fluvi',
        primary: map['primary'] as String? ?? 'Mintaadat',
        secondary: map['secondary'] as String? ?? '',
        event: map['event'] as String?,
        eventLabel: map['eventLabel'] as String?,
        available: map['available'] as bool? ?? false,
      );

  final String focus;
  final String primary;
  final String secondary;
  final String? event;
  final String? eventLabel;
  final bool available;
}

final class LockScreenCardCategory {
  const LockScreenCardCategory({required this.id, required this.name});
  factory LockScreenCardCategory.fromMap(Map<Object?, Object?> map) =>
      LockScreenCardCategory(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
      );
  final String id;
  final String name;
}

T _enumByName<T extends Enum>(List<T> values, String? value) =>
    values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => values.first,
    );
