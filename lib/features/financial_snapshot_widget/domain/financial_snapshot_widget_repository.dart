abstract interface class FinancialSnapshotWidgetRepository {
  Future<FinancialSnapshotWidgetStatus> load();
  Future<FinancialSnapshotWidgetStatus> saveWidget(
    FinancialSnapshotWidgetConfiguration configuration,
  );
}

enum FinancialSnapshotMode { mind, balance, budget }

enum FinancialSnapshotTimeAxis { sum, year, month, day }

enum FinancialSnapshotDirection { income, expense }

enum FinancialSnapshotEventLine { related, processed, hidden }

enum FinancialSnapshotPrivacy { discreet, full }

final class FinancialSnapshotWidgetConfiguration {
  const FinancialSnapshotWidgetConfiguration({
    required this.mode,
    required this.timeAxis,
    required this.direction,
    this.categoryId,
    required this.eventLine,
    required this.privacy,
    required this.valid,
  });

  factory FinancialSnapshotWidgetConfiguration.fromMap(
    Map<Object?, Object?> map,
  ) => FinancialSnapshotWidgetConfiguration(
    mode: _enumByName(FinancialSnapshotMode.values, map['mode'] as String?),
    timeAxis: _enumByName(
      FinancialSnapshotTimeAxis.values,
      map['timeAxis'] as String?,
    ),
    direction: _enumByName(
      FinancialSnapshotDirection.values,
      map['direction'] as String?,
    ),
    categoryId: map['categoryId'] as String?,
    eventLine: _enumByName(
      FinancialSnapshotEventLine.values,
      map['eventLine'] as String?,
    ),
    privacy: _enumByName(
      FinancialSnapshotPrivacy.values,
      map['privacy'] as String?,
    ),
    valid: map['valid'] as bool? ?? false,
  );

  final FinancialSnapshotMode mode;
  final FinancialSnapshotTimeAxis timeAxis;
  final FinancialSnapshotDirection direction;
  final String? categoryId;
  final FinancialSnapshotEventLine eventLine;
  final FinancialSnapshotPrivacy privacy;
  final bool valid;

  FinancialSnapshotWidgetConfiguration copyWith({
    FinancialSnapshotMode? mode,
    FinancialSnapshotTimeAxis? timeAxis,
    FinancialSnapshotDirection? direction,
    String? categoryId,
    bool clearCategory = false,
    FinancialSnapshotEventLine? eventLine,
    FinancialSnapshotPrivacy? privacy,
    bool? valid,
  }) => FinancialSnapshotWidgetConfiguration(
    mode: mode ?? this.mode,
    timeAxis: timeAxis ?? this.timeAxis,
    direction: direction ?? this.direction,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    eventLine: eventLine ?? this.eventLine,
    privacy: privacy ?? this.privacy,
    valid: valid ?? this.valid,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'mode': mode.name,
    'timeAxis': timeAxis.name,
    'direction': direction.name,
    'categoryId': categoryId,
    'eventLine': eventLine.name,
    'privacy': privacy.name,
  };
}

final class FinancialSnapshotWidgetStatus {
  const FinancialSnapshotWidgetStatus({
    required this.configuration,
    required this.content,
    required this.categories,
    required this.hostWidgetCount,
    required this.lockscreenPlacementVerified,
  });

  factory FinancialSnapshotWidgetStatus.fromMap(Map<Object?, Object?> map) {
    final rawConfiguration =
        map['configuration'] as Map<Object?, Object?>? ??
        const <Object?, Object?>{};
    final rawContent =
        map['content'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    return FinancialSnapshotWidgetStatus(
      configuration: FinancialSnapshotWidgetConfiguration.fromMap(
        rawConfiguration,
      ),
      content: FinancialSnapshotContent.fromMap(rawContent),
      categories: ((map['categories'] as List<Object?>?) ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(FinancialSnapshotCategory.fromMap)
          .toList(growable: false),
      hostWidgetCount: map['hostWidgetCount'] as int? ?? 0,
      lockscreenPlacementVerified:
          map['lockscreenPlacementVerified'] as bool? ?? false,
    );
  }

  final FinancialSnapshotWidgetConfiguration configuration;
  final FinancialSnapshotContent content;
  final List<FinancialSnapshotCategory> categories;
  final int hostWidgetCount;
  final bool lockscreenPlacementVerified;
}

final class FinancialSnapshotContent {
  const FinancialSnapshotContent({
    required this.focus,
    required this.primary,
    required this.secondary,
    this.event,
    this.eventLabel,
    required this.available,
  });

  factory FinancialSnapshotContent.fromMap(Map<Object?, Object?> map) =>
      FinancialSnapshotContent(
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

final class FinancialSnapshotCategory {
  const FinancialSnapshotCategory({required this.id, required this.name});
  factory FinancialSnapshotCategory.fromMap(Map<Object?, Object?> map) =>
      FinancialSnapshotCategory(
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
