abstract interface class LockScreenCardRepository {
  Future<LockScreenCardStatus> load();
  Future<LockScreenCardStatus> save(LockScreenCardConfiguration configuration);
  Future<LockScreenCardStatus> saveWidget(
    FinancialSnapshotWidgetConfiguration configuration,
  );
  Future<LockScreenCardStatus> saveNativeKeyguardCard(
    NativeKeyguardCardConfiguration configuration,
  );
  Future<LockScreenCardStatus> patchNativeKeyguardCardLayout(
    NativeKeyguardCardLayoutPatch patch,
  );
  Future<void> openNativeKeyguardSettings();

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

enum NativeKeyguardCardAnimationMode { off, orbOnly, orbAndBackground }

enum NativeKeyguardCardPresentationMode { card, orb }

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
    required this.statusChannelLockscreenVisibility,
    required this.widget,
    required this.nativeCard,
    required this.keyguardCategories,
    this.keyguardContent,
  });

  factory LockScreenCardStatus.fromMap(Map<Object?, Object?> map) {
    final rawConfiguration =
        map['configuration'] as Map<Object?, Object?>? ??
        const <Object?, Object?>{};
    final rawContent =
        map['content'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    final rawWidget =
        map['widget'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
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
      statusChannelLockscreenVisibility:
          map['statusChannelLockscreenVisibility'] as String? ??
          'Rendszer szerinti',
      widget: FinancialSnapshotWidgetStatus.fromMap(rawWidget),
      nativeCard: NativeKeyguardCardStatus.fromMap(
        map['nativeCard'] as Map<Object?, Object?>? ??
            const <Object?, Object?>{},
      ),
      keyguardCategories:
          ((map['keyguardCategories'] as List<Object?>?) ?? const <Object?>[])
              .whereType<Map<Object?, Object?>>()
              .map(LockScreenCardCategory.fromMap)
              .toList(growable: false),
      keyguardContent: map['keyguardContent'] is Map<Object?, Object?>
          ? LockScreenCardContent.fromMap(
              map['keyguardContent'] as Map<Object?, Object?>,
            )
          : null,
    );
  }

  final LockScreenCardConfiguration configuration;
  final LockScreenCardContent content;
  final List<LockScreenCardCategory> categories;
  final bool postNotificationsGranted;
  final bool statusChannelEnabled;
  final String statusChannelImportance;
  final String statusChannelLockscreenVisibility;
  final FinancialSnapshotWidgetStatus widget;
  final NativeKeyguardCardStatus nativeCard;
  final List<LockScreenCardCategory> keyguardCategories;
  final LockScreenCardContent? keyguardContent;
}

/// Separate consent for the accessibility overlay. It deliberately does not
/// inherit either the optional notification's Full setting or the widget
/// host's Full setting.
final class NativeKeyguardCardConfiguration {
  const NativeKeyguardCardConfiguration({
    required this.requested,
    required this.showFinancialDetails,
    required this.verticalOffsetDp,
    required this.animationMode,
    this.presentationMode = NativeKeyguardCardPresentationMode.card,
    this.cardPosition,
    this.orbPosition,
    this.layoutRevision = 0,
    this.focus = const NativeKeyguardCardFocus(),
  });

  final bool requested;
  final bool showFinancialDetails;
  final int verticalOffsetDp;
  final NativeKeyguardCardAnimationMode animationMode;
  final NativeKeyguardCardPresentationMode presentationMode;
  final NativeKeyguardCardCardPosition? cardPosition;
  final NativeKeyguardCardOrbPosition? orbPosition;
  final int layoutRevision;
  final NativeKeyguardCardFocus focus;

  NativeKeyguardCardConfiguration copyWith({
    bool? requested,
    bool? showFinancialDetails,
    int? verticalOffsetDp,
    NativeKeyguardCardAnimationMode? animationMode,
    NativeKeyguardCardPresentationMode? presentationMode,
    NativeKeyguardCardFocus? focus,
  }) => NativeKeyguardCardConfiguration(
    requested: requested ?? this.requested,
    showFinancialDetails: showFinancialDetails ?? this.showFinancialDetails,
    verticalOffsetDp: verticalOffsetDp ?? this.verticalOffsetDp,
    animationMode: animationMode ?? this.animationMode,
    presentationMode: presentationMode ?? this.presentationMode,
    cardPosition: cardPosition,
    orbPosition: orbPosition,
    layoutRevision: layoutRevision,
    focus: focus ?? this.focus,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'requested': requested,
    'showFinancialDetails': showFinancialDetails,
    'verticalOffsetDp': verticalOffsetDp,
    'animationMode': animationMode.name,
    'presentationMode': presentationMode.name,
    'focus': focus.toMap(),
  };
}

final class NativeKeyguardCardCardPosition {
  const NativeKeyguardCardCardPosition(this.yFraction);

  factory NativeKeyguardCardCardPosition.fromMap(Map<Object?, Object?> map) =>
      NativeKeyguardCardCardPosition(
        ((map['yFraction'] as num?)?.toDouble() ?? .5).clamp(0, 1).toDouble(),
      );

  final double yFraction;

  Map<String, Object?> toMap() => <String, Object?>{'yFraction': yFraction};
}

final class NativeKeyguardCardOrbPosition {
  const NativeKeyguardCardOrbPosition(this.xFraction, this.yFraction);

  factory NativeKeyguardCardOrbPosition.fromMap(Map<Object?, Object?> map) =>
      NativeKeyguardCardOrbPosition(
        ((map['xFraction'] as num?)?.toDouble() ?? .5).clamp(0, 1).toDouble(),
        ((map['yFraction'] as num?)?.toDouble() ?? .5).clamp(0, 1).toDouble(),
      );

  final double xFraction;
  final double yFraction;

  Map<String, Object?> toMap() => <String, Object?>{
    'xFraction': xFraction,
    'yFraction': yFraction,
  };
}

/// Sent independently of the full card configuration so a stale page snapshot
/// cannot overwrite a location committed by a lock-screen drag.
final class NativeKeyguardCardLayoutPatch {
  const NativeKeyguardCardLayoutPatch({
    this.presentationMode,
    this.cardPosition,
    this.orbPosition,
    this.resetPosition = false,
  });

  final NativeKeyguardCardPresentationMode? presentationMode;
  final NativeKeyguardCardCardPosition? cardPosition;
  final NativeKeyguardCardOrbPosition? orbPosition;
  final bool resetPosition;

  Map<String, Object?> toMap() => <String, Object?>{
    if (presentationMode != null) 'presentationMode': presentationMode!.name,
    if (cardPosition != null) 'cardPosition': cardPosition!.toMap(),
    if (orbPosition != null) 'orbPosition': orbPosition!.toMap(),
    if (resetPosition) 'resetPosition': true,
  };
}

/// Persistent focus owned by the native keyguard card only.  It shares enum
/// vocabulary with the other surfaces but deliberately has separate storage
/// and generation on Android.
final class NativeKeyguardCardFocus {
  const NativeKeyguardCardFocus({
    this.mode = LockScreenCardMode.balance,
    this.timeAxis = LockScreenCardTimeAxis.month,
    this.direction = LockScreenCardDirection.expense,
    this.categoryId,
    this.eventLine = LockScreenCardEventLine.related,
    this.generation = 0,
    this.valid = true,
  });

  factory NativeKeyguardCardFocus.fromMap(Map<Object?, Object?> map) {
    final mode = _enumByName(LockScreenCardMode.values, map['mode'] as String?);
    final categoryId = map['categoryId'] as String?;
    return NativeKeyguardCardFocus(
      mode: mode,
      timeAxis: _enumByName(
        LockScreenCardTimeAxis.values,
        map['timeAxis'] as String?,
      ),
      direction: _enumByName(
        LockScreenCardDirection.values,
        map['direction'] as String?,
      ),
      categoryId: categoryId,
      eventLine: _enumByName(
        LockScreenCardEventLine.values,
        map['eventLine'] as String?,
      ),
      generation: map['generation'] as int? ?? 0,
      valid:
          map['valid'] as bool? ??
          (mode != LockScreenCardMode.budget ||
              (categoryId?.isNotEmpty ?? false)),
    );
  }

  final LockScreenCardMode mode;
  final LockScreenCardTimeAxis timeAxis;
  final LockScreenCardDirection direction;
  final String? categoryId;
  final LockScreenCardEventLine eventLine;
  final int generation;
  final bool valid;

  NativeKeyguardCardFocus copyWith({
    LockScreenCardMode? mode,
    LockScreenCardTimeAxis? timeAxis,
    LockScreenCardDirection? direction,
    String? categoryId,
    bool clearCategory = false,
    LockScreenCardEventLine? eventLine,
  }) {
    final nextMode = mode ?? this.mode;
    final nextCategory = clearCategory ? null : categoryId ?? this.categoryId;
    return NativeKeyguardCardFocus(
      mode: nextMode,
      timeAxis: timeAxis ?? this.timeAxis,
      direction: direction ?? this.direction,
      categoryId: nextCategory,
      eventLine: eventLine ?? this.eventLine,
      generation: generation,
      valid:
          nextMode != LockScreenCardMode.budget ||
          (nextCategory?.isNotEmpty ?? false),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'mode': mode.name,
    'timeAxis': timeAxis.name,
    'direction': direction.name,
    'categoryId': categoryId,
    'eventLine': eventLine.name,
  };
}

final class NativeKeyguardCardStatus {
  const NativeKeyguardCardStatus({
    required this.configuration,
    required this.systemServiceEnabled,
    required this.serviceConnected,
    required this.lastDecisionReason,
    required this.lastAttachResult,
    required this.diagnosticSummary,
    required this.materialDiagnostics,
  });

  factory NativeKeyguardCardStatus.fromMap(
    Map<Object?, Object?> map,
  ) => NativeKeyguardCardStatus(
    configuration: NativeKeyguardCardConfiguration(
      requested: map['requested'] as bool? ?? false,
      showFinancialDetails: map['showFinancialDetails'] as bool? ?? false,
      verticalOffsetDp: map['verticalOffsetDp'] as int? ?? 0,
      animationMode: NativeKeyguardCardAnimationMode.values.firstWhere(
        (value) => value.name == (map['animationMode'] as String?),
        orElse: () => NativeKeyguardCardAnimationMode.orbOnly,
      ),
      presentationMode: NativeKeyguardCardPresentationMode.values.firstWhere(
        (value) => value.name == (map['presentationMode'] as String?),
        orElse: () => NativeKeyguardCardPresentationMode.card,
      ),
      cardPosition: map['cardPosition'] is Map<Object?, Object?>
          ? NativeKeyguardCardCardPosition.fromMap(
              map['cardPosition'] as Map<Object?, Object?>,
            )
          : null,
      orbPosition: map['orbPosition'] is Map<Object?, Object?>
          ? NativeKeyguardCardOrbPosition.fromMap(
              map['orbPosition'] as Map<Object?, Object?>,
            )
          : null,
      layoutRevision: map['layoutRevision'] as int? ?? 0,
      focus: NativeKeyguardCardFocus.fromMap(
        map['focus'] as Map<Object?, Object?>? ?? const <Object?, Object?>{},
      ),
    ),
    systemServiceEnabled: map['systemServiceEnabled'] as bool? ?? false,
    serviceConnected: map['serviceConnected'] as bool? ?? false,
    lastDecisionReason:
        map['lastDecisionReason'] as String? ?? 'Nincs zárképernyő-próba',
    lastAttachResult:
        map['lastAttachResult'] as String? ?? 'Nincs csatolási kísérlet',
    diagnosticSummary: map['diagnosticSummary'] as String? ?? '',
    materialDiagnostics: NativeKeyguardCardMaterialDiagnostics.fromMap(
      map['materialDiagnostics'] as Map<Object?, Object?>? ??
          const <Object?, Object?>{},
    ),
  );

  final NativeKeyguardCardConfiguration configuration;
  final bool systemServiceEnabled;
  final bool serviceConnected;
  final String lastDecisionReason;
  final String lastAttachResult;
  final String diagnosticSummary;
  final NativeKeyguardCardMaterialDiagnostics materialDiagnostics;
}

final class NativeKeyguardCardMaterialDiagnostics {
  const NativeKeyguardCardMaterialDiagnostics({
    required this.rendererBackend,
    required this.requestedRenderer,
    required this.activeRenderer,
    required this.hardwareAccelerated,
    required this.shaderCreationCount,
    required this.animationStartCount,
    required this.animationStopCount,
    required this.drawCount,
    required this.frameCallbackCount,
    required this.onDrawCount,
    required this.shaderDrawCount,
    required this.fallbackDrawCount,
    required this.phaseAdvanceCount,
    required this.shaderCompileAttempts,
    required this.shaderCompileSuccesses,
    required this.shaderCompileFailures,
    required this.frameIntervalP50,
    required this.frameIntervalP95,
    required this.largeFrameGapCount,
    this.lastRendererFailure,
    this.lastFailureStage,
    this.lastFailureClass,
    this.lastFailureMessage,
    this.shaderSourceHash,
    this.generatedAgslHash,
    this.adapterVersion,
    this.effectId,
  });

  factory NativeKeyguardCardMaterialDiagnostics.fromMap(
    Map<Object?, Object?> map,
  ) => NativeKeyguardCardMaterialDiagnostics(
    rendererBackend: map['rendererBackend'] as String? ?? 'not-connected',
    requestedRenderer: map['requestedRenderer'] as String? ?? 'not-connected',
    activeRenderer: map['activeRenderer'] as String? ?? 'not-connected',
    hardwareAccelerated: map['hardwareAccelerated'] as bool? ?? false,
    shaderCreationCount: map['shaderCreationCount'] as int? ?? 0,
    animationStartCount: map['animationStartCount'] as int? ?? 0,
    animationStopCount: map['animationStopCount'] as int? ?? 0,
    drawCount: map['drawCount'] as int? ?? 0,
    frameCallbackCount: map['frameCallbackCount'] as int? ?? 0,
    onDrawCount: map['onDrawCount'] as int? ?? 0,
    shaderDrawCount: map['shaderDrawCount'] as int? ?? 0,
    fallbackDrawCount: map['fallbackDrawCount'] as int? ?? 0,
    phaseAdvanceCount: map['phaseAdvanceCount'] as int? ?? 0,
    shaderCompileAttempts: map['shaderCompileAttempts'] as int? ?? 0,
    shaderCompileSuccesses: map['shaderCompileSuccesses'] as int? ?? 0,
    shaderCompileFailures: map['shaderCompileFailures'] as int? ?? 0,
    frameIntervalP50: map['frameIntervalP50'] as int? ?? 0,
    frameIntervalP95: map['frameIntervalP95'] as int? ?? 0,
    largeFrameGapCount: map['largeFrameGapCount'] as int? ?? 0,
    lastRendererFailure: map['lastRendererFailure'] as String?,
    lastFailureStage: map['lastFailureStage'] as String?,
    lastFailureClass: map['lastFailureClass'] as String?,
    lastFailureMessage: map['lastFailureMessage'] as String?,
    shaderSourceHash: map['shaderSourceHash'] as String?,
    generatedAgslHash: map['generatedAgslHash'] as String?,
    adapterVersion: map['adapterVersion'] as String?,
    effectId: map['effectId'] as String?,
  );

  final String rendererBackend;
  final String requestedRenderer;
  final String activeRenderer;
  final bool hardwareAccelerated;
  final int shaderCreationCount;
  final int animationStartCount;
  final int animationStopCount;
  final int drawCount;
  final int frameCallbackCount;
  final int onDrawCount;
  final int shaderDrawCount;
  final int fallbackDrawCount;
  final int phaseAdvanceCount;
  final int shaderCompileAttempts;
  final int shaderCompileSuccesses;
  final int shaderCompileFailures;
  final int frameIntervalP50;
  final int frameIntervalP95;
  final int largeFrameGapCount;
  final String? lastRendererFailure;
  final String? lastFailureStage;
  final String? lastFailureClass;
  final String? lastFailureMessage;
  final String? shaderSourceHash;
  final String? generatedAgslHash;
  final String? adapterVersion;
  final String? effectId;
}

/// Independent from the optional notification configuration.  A RemoteViews
/// host sees the exact fields Fluvi writes, therefore a new widget always
/// starts in discreet mode even if an older notification used Full mode.
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

  final LockScreenCardMode mode;
  final LockScreenCardTimeAxis timeAxis;
  final LockScreenCardDirection direction;
  final String? categoryId;
  final LockScreenCardEventLine eventLine;
  final LockScreenCardPrivacy privacy;
  final bool valid;

  FinancialSnapshotWidgetConfiguration copyWith({
    LockScreenCardMode? mode,
    LockScreenCardTimeAxis? timeAxis,
    LockScreenCardDirection? direction,
    String? categoryId,
    bool clearCategory = false,
    LockScreenCardEventLine? eventLine,
    LockScreenCardPrivacy? privacy,
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
      content: LockScreenCardContent.fromMap(rawContent),
      categories: ((map['categories'] as List<Object?>?) ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(LockScreenCardCategory.fromMap)
          .toList(growable: false),
      hostWidgetCount: map['hostWidgetCount'] as int? ?? 0,
      lockscreenPlacementVerified:
          map['lockscreenPlacementVerified'] as bool? ?? false,
    );
  }

  final FinancialSnapshotWidgetConfiguration configuration;
  final LockScreenCardContent content;
  final List<LockScreenCardCategory> categories;
  final int hostWidgetCount;
  final bool lockscreenPlacementVerified;
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
