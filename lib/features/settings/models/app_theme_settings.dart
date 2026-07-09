import '../theme/expense_surface.dart';

export '../theme/expense_surface.dart';

enum MagnetType {
  fade('fade'),
  nofade('nofade'),
  budget('budget'),
  magnetcard('magnetcard'),
  adaptive('adaptive'),
  partitionedBudget('partitionedBudget');

  const MagnetType(this.nativeValue);
  final String nativeValue;

  static MagnetType fromAny(Object? value) {
    final raw = value?.toString();
    return MagnetType.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => MagnetType.fade,
    );
  }
}

enum BackheaderStyle {
  classic('classic'),
  heroToken('heroToken'),
  orbitBudget('orbitBudget'),
  centerBadgeBudget('centerBadgeBudget'),
  ambulanceSkin('ambulanceSkin');

  const BackheaderStyle(this.nativeValue);
  final String nativeValue;

  static const selectableValues = <BackheaderStyle>[
    BackheaderStyle.classic,
    BackheaderStyle.centerBadgeBudget,
    BackheaderStyle.ambulanceSkin,
  ];

  static BackheaderStyle fromAny(Object? value) {
    final raw = value?.toString();
    return selectableValues.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => BackheaderStyle.classic,
    );
  }

  String get displayTitle => switch (this) {
    BackheaderStyle.classic => 'Jelenlegi bar rendszer',
    BackheaderStyle.heroToken => 'C - Hero Token',
    BackheaderStyle.orbitBudget => 'D - Orbit Budget',
    BackheaderStyle.centerBadgeBudget => 'E - Center Badge Budget',
    BackheaderStyle.ambulanceSkin => 'Mentők skin',
  };

  String get description => switch (this) {
    BackheaderStyle.classic => 'A mostani kategória/overview bar rendszer',
    BackheaderStyle.heroToken => 'Nagy aktív kategória token mini partitionnel',
    BackheaderStyle.orbitBudget => 'Kategóriaszínű orbit/ring budget nézet',
    BackheaderStyle.centerBadgeBudget =>
      'Középső limit/budget badge élő progress ringgel',
    BackheaderStyle.ambulanceSkin =>
      'Mentőautó ihletésű sárga header narancs mágnescsíkkal',
  };
}

enum BackheaderCenterDesign {
  neutral('neutral'),
  colored('colored');

  const BackheaderCenterDesign(this.nativeValue);
  final String nativeValue;

  static BackheaderCenterDesign fromAny(Object? value) {
    final raw = value?.toString();
    return BackheaderCenterDesign.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => BackheaderCenterDesign.neutral,
    );
  }

  String get displayTitle => switch (this) {
    BackheaderCenterDesign.neutral => 'Jelenlegi háttér',
    BackheaderCenterDesign.colored => 'Színes háttér',
  };

  String get description => switch (this) {
    BackheaderCenterDesign.neutral =>
      'A Center Badge Budget az app jelenlegi háttérszínét használja.',
    BackheaderCenterDesign.colored =>
      'Kategóriaszínű, orbit jellegű háttér fehér badge veil elemekkel.',
  };
}

enum CenterBadgeBorderMode {
  limitOnly('limitOnly'),
  always('always');

  const CenterBadgeBorderMode(this.nativeValue);
  final String nativeValue;

  static CenterBadgeBorderMode fromAny(Object? value) {
    final raw = value?.toString();
    return CenterBadgeBorderMode.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => CenterBadgeBorderMode.limitOnly,
    );
  }
}

const kCenterBadgeWhiteDiscOpacityDefaults = <int>[18, 13, 10, 9, 8];
const kCenterBadgeWhiteIconOpacityDefaults = <int>[100, 72, 58, 48, 42];
const kCenterBadgeWhiteProgressOpacityDefaults = <int>[100, 72, 58, 48, 42];
const kCenterBadgeColoredFillOpacityDefaults = <int>[100, 72, 58, 48, 42];
const kCenterBadgeColoredIconOpacityDefaults = <int>[100, 72, 58, 48, 42];
const kCenterBadgeColoredProgressOpacityDefaults = <int>[100, 72, 58, 48, 42];
const kCenterBadgeColoredBackgroundOpacityDefault = 72;
const kCenterBadgeSlotSizePercentDefaults = <int>[
  100,
  100,
  100,
  100,
  100,
  100,
  100,
  100,
  100,
];
const kCenterBadgeSlotXOffsetDefaults = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0];
const kCenterBadgeSlotSizePercentMin = 50;
const kCenterBadgeSlotSizePercentMax = 180;
const kCenterBadgeSlotXOffsetMin = -64;
const kCenterBadgeSlotXOffsetMax = 64;

enum AppCardColor {
  white('white'),
  lightgray('lightgray'),
  darkgray('darkgray');

  const AppCardColor(this.nativeValue);
  final String nativeValue;

  static AppCardColor fromAny(Object? value) {
    final raw = value?.toString();
    return AppCardColor.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppCardColor.lightgray,
    );
  }
}

enum AppTheme {
  pink('Pink'),
  turquoise('Türkiz');

  const AppTheme(this.nativeValue);
  final String nativeValue;

  static AppTheme fromAny(Object? value) {
    final raw = value?.toString();
    return AppTheme.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppTheme.turquoise,
    );
  }
}

enum AppDesignProfile {
  normal('normal'),
  neumorphism('neumorphism');

  const AppDesignProfile(this.nativeValue);
  final String nativeValue;

  static AppDesignProfile fromAny(Object? value) {
    final raw = value?.toString();
    return AppDesignProfile.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppDesignProfile.normal,
    );
  }
}

enum AppColorMode {
  turquoise('turquoise'),
  pink('pink');

  const AppColorMode(this.nativeValue);
  final String nativeValue;

  static AppColorMode fromAny(Object? value) {
    final raw = value?.toString().trim();
    if (raw == AppTheme.pink.nativeValue ||
        raw == AppColorMode.pink.nativeValue) {
      return AppColorMode.pink;
    }
    return AppColorMode.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppColorMode.turquoise,
    );
  }
}

enum AppBackgroundColor {
  white('white'),
  gray('gray'),
  darkgray('darkgray');

  const AppBackgroundColor(this.nativeValue);
  final String nativeValue;

  static AppBackgroundColor fromAny(Object? value) {
    final raw = value?.toString();
    return AppBackgroundColor.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppBackgroundColor.gray,
    );
  }
}

enum AppBoxColor {
  white('white'),
  gray('gray'),
  darkgray('darkgray');

  const AppBoxColor(this.nativeValue);
  final String nativeValue;

  static AppBoxColor fromAny(Object? value) {
    final raw = value?.toString();
    return AppBoxColor.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppBoxColor.gray,
    );
  }
}

const kFabSizeDefault = 66;
const kFabSizeMin = 52;
const kFabSizeMax = 88;

enum GhostLogboxBorderStyle {
  normal('normal'),
  dashed('dashed');

  const GhostLogboxBorderStyle(this.nativeValue);
  final String nativeValue;

  static GhostLogboxBorderStyle fromAny(Object? value) {
    final raw = value?.toString();
    return GhostLogboxBorderStyle.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => GhostLogboxBorderStyle.dashed,
    );
  }
}

enum GhostLogboxTextTone {
  normal('normal'),
  gray('gray');

  const GhostLogboxTextTone(this.nativeValue);
  final String nativeValue;

  static GhostLogboxTextTone fromAny(Object? value) {
    final raw = value?.toString();
    return GhostLogboxTextTone.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => GhostLogboxTextTone.normal,
    );
  }
}

class GhostLogboxSettings {
  const GhostLogboxSettings({
    required this.borderStyle,
    required this.backgroundOpacityEnabled,
    required this.avatarOpacityEnabled,
    required this.textOpacityEnabled,
    required this.avatarBadgeEnabled,
    required this.textTone,
    required this.expectedLabelEnabled,
  });

  factory GhostLogboxSettings.defaults() {
    return const GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.dashed,
      backgroundOpacityEnabled: true,
      avatarOpacityEnabled: false,
      textOpacityEnabled: false,
      avatarBadgeEnabled: true,
      textTone: GhostLogboxTextTone.normal,
      expectedLabelEnabled: true,
    );
  }

  factory GhostLogboxSettings.fromMap(Map<dynamic, dynamic>? map) {
    final payload = map ?? const <dynamic, dynamic>{};
    final defaults = GhostLogboxSettings.defaults();
    return GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.fromAny(payload['borderStyle']),
      backgroundOpacityEnabled: _bool(
        payload['backgroundOpacityEnabled'],
        defaults.backgroundOpacityEnabled,
      ),
      avatarOpacityEnabled: _bool(
        payload['avatarOpacityEnabled'],
        defaults.avatarOpacityEnabled,
      ),
      textOpacityEnabled: _bool(
        payload['textOpacityEnabled'],
        defaults.textOpacityEnabled,
      ),
      avatarBadgeEnabled: _bool(
        payload['avatarBadgeEnabled'],
        defaults.avatarBadgeEnabled,
      ),
      textTone: GhostLogboxTextTone.fromAny(payload['textTone']),
      expectedLabelEnabled: _bool(
        payload['expectedLabelEnabled'],
        defaults.expectedLabelEnabled,
      ),
    );
  }

  final GhostLogboxBorderStyle borderStyle;
  final bool backgroundOpacityEnabled;
  final bool avatarOpacityEnabled;
  final bool textOpacityEnabled;
  final bool avatarBadgeEnabled;
  final GhostLogboxTextTone textTone;
  final bool expectedLabelEnabled;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'borderStyle': borderStyle.nativeValue,
      'backgroundOpacityEnabled': backgroundOpacityEnabled,
      'avatarOpacityEnabled': avatarOpacityEnabled,
      'textOpacityEnabled': textOpacityEnabled,
      'avatarBadgeEnabled': avatarBadgeEnabled,
      'textTone': textTone.nativeValue,
      'expectedLabelEnabled': expectedLabelEnabled,
    };
  }

  GhostLogboxSettings copyWith({
    GhostLogboxBorderStyle? borderStyle,
    bool? backgroundOpacityEnabled,
    bool? avatarOpacityEnabled,
    bool? textOpacityEnabled,
    bool? avatarBadgeEnabled,
    GhostLogboxTextTone? textTone,
    bool? expectedLabelEnabled,
  }) {
    return GhostLogboxSettings(
      borderStyle: borderStyle ?? this.borderStyle,
      backgroundOpacityEnabled:
          backgroundOpacityEnabled ?? this.backgroundOpacityEnabled,
      avatarOpacityEnabled: avatarOpacityEnabled ?? this.avatarOpacityEnabled,
      textOpacityEnabled: textOpacityEnabled ?? this.textOpacityEnabled,
      avatarBadgeEnabled: avatarBadgeEnabled ?? this.avatarBadgeEnabled,
      textTone: textTone ?? this.textTone,
      expectedLabelEnabled: expectedLabelEnabled ?? this.expectedLabelEnabled,
    );
  }

  static bool _bool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return fallback;
  }
}

class AppThemeSettings {
  const AppThemeSettings({
    required this.magnetType,
    required this.cardColor,
    required this.theme,
    required this.backgroundColor,
    required this.boxColor,
    required this.buttonSurfaceStyle,
    required this.contentSurfaceStyle,
    required this.ghostLogboxSurfaceStyle,
    required this.ghostLogboxSettings,
    required this.categoryMenuColor,
    required this.categoryCardColor,
    required this.categoryCardSurfaceStyle,
    required this.backheaderStyle,
    required this.appColor,
    this.statsMonthCardColor = AppBoxColor.white,
    this.centerBackheaderDesign = BackheaderCenterDesign.neutral,
    this.centerPartitionRingEnabled = false,
    this.centerBadgeDiscEnabled = true,
    this.centerBadgeBorderMode = CenterBadgeBorderMode.limitOnly,
    this.centerBadgeOverlapMaskEnabled = false,
    this.centerBadgeWhiteDiscOpacities = kCenterBadgeWhiteDiscOpacityDefaults,
    this.centerBadgeWhiteIconOpacities = kCenterBadgeWhiteIconOpacityDefaults,
    this.centerBadgeWhiteProgressOpacities =
        kCenterBadgeWhiteProgressOpacityDefaults,
    this.centerBadgeColoredFillOpacities =
        kCenterBadgeColoredFillOpacityDefaults,
    this.centerBadgeColoredIconOpacities =
        kCenterBadgeColoredIconOpacityDefaults,
    this.centerBadgeColoredProgressOpacities =
        kCenterBadgeColoredProgressOpacityDefaults,
    this.centerBadgeSlotSizePercents = kCenterBadgeSlotSizePercentDefaults,
    this.centerBadgeSlotXOffsets = kCenterBadgeSlotXOffsetDefaults,
    this.centerBadgeColoredBackgroundOpacity =
        kCenterBadgeColoredBackgroundOpacityDefault,
    this.fabSize = kFabSizeDefault,
  });

  factory AppThemeSettings.defaults() {
    return AppThemeSettings(
      magnetType: MagnetType.fade,
      cardColor: AppCardColor.lightgray,
      theme: AppTheme.turquoise,
      backgroundColor: AppBackgroundColor.gray,
      boxColor: AppBoxColor.gray,
      buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      contentSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      ghostLogboxSettings: GhostLogboxSettings.defaults(),
      categoryMenuColor: AppBoxColor.gray,
      categoryCardColor: AppBoxColor.gray,
      categoryCardSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      backheaderStyle: BackheaderStyle.classic,
      statsMonthCardColor: AppBoxColor.white,
      centerBackheaderDesign: BackheaderCenterDesign.neutral,
      centerPartitionRingEnabled: false,
      centerBadgeDiscEnabled: true,
      centerBadgeBorderMode: CenterBadgeBorderMode.limitOnly,
      centerBadgeOverlapMaskEnabled: false,
      centerBadgeWhiteDiscOpacities: kCenterBadgeWhiteDiscOpacityDefaults,
      centerBadgeWhiteIconOpacities: kCenterBadgeWhiteIconOpacityDefaults,
      centerBadgeWhiteProgressOpacities:
          kCenterBadgeWhiteProgressOpacityDefaults,
      centerBadgeColoredFillOpacities: kCenterBadgeColoredFillOpacityDefaults,
      centerBadgeColoredIconOpacities: kCenterBadgeColoredIconOpacityDefaults,
      centerBadgeColoredProgressOpacities:
          kCenterBadgeColoredProgressOpacityDefaults,
      centerBadgeSlotSizePercents: kCenterBadgeSlotSizePercentDefaults,
      centerBadgeSlotXOffsets: kCenterBadgeSlotXOffsetDefaults,
      centerBadgeColoredBackgroundOpacity:
          kCenterBadgeColoredBackgroundOpacityDefault,
      appColor: AppColorMode.turquoise,
      fabSize: kFabSizeDefault,
    );
  }

  factory AppThemeSettings.fromMap(Map<dynamic, dynamic> map) {
    final legacyProfile = AppDesignProfile.fromAny(map['designProfile']);
    return AppThemeSettings(
      magnetType: MagnetType.fromAny(map['magnetType']),
      cardColor: AppCardColor.fromAny(map['cardColor']),
      theme: AppTheme.fromAny(map['theme']),
      backgroundColor: AppBackgroundColor.fromAny(map['backgroundColor']),
      boxColor: AppBoxColor.fromAny(map['boxColor']),
      buttonSurfaceStyle: _surfaceFromMap(
        map,
        'buttonSurfaceStyle',
        legacyProfile == AppDesignProfile.neumorphism
            ? ExpenseSurfaceInteraction.raisedInset
            : ExpenseSurfaceInteraction.neutralNeutral,
      ),
      contentSurfaceStyle: _surfaceFromMap(
        map,
        'contentSurfaceStyle',
        legacyProfile == AppDesignProfile.neumorphism
            ? ExpenseSurfaceInteraction.insetInset
            : ExpenseSurfaceInteraction.neutralNeutral,
      ),
      ghostLogboxSurfaceStyle: _surfaceFromMap(
        map,
        'ghostLogboxSurfaceStyle',
        legacyProfile == AppDesignProfile.neumorphism
            ? ExpenseSurfaceInteraction.insetInset
            : ExpenseSurfaceInteraction.neutralNeutral,
      ),
      ghostLogboxSettings: GhostLogboxSettings.fromMap(
        map['ghostLogboxSettings'] is Map
            ? Map<dynamic, dynamic>.from(map['ghostLogboxSettings'] as Map)
            : null,
      ),
      categoryMenuColor: _categoryBoxColorFromAny(map['categoryMenuColor']),
      categoryCardColor: _categoryBoxColorFromAny(map['categoryCardColor']),
      categoryCardSurfaceStyle: _surfaceFromMap(
        map,
        'categoryCardSurfaceStyle',
        ExpenseSurfaceInteraction.neutralNeutral,
      ),
      backheaderStyle: BackheaderStyle.fromAny(map['backheaderStyle']),
      statsMonthCardColor: _hasValue(map['statsMonthCardColor'])
          ? AppBoxColor.fromAny(map['statsMonthCardColor'])
          : AppBoxColor.white,
      centerBackheaderDesign: BackheaderCenterDesign.fromAny(
        map['centerBackheaderDesign'],
      ),
      centerPartitionRingEnabled: _bool(
        map['centerPartitionRingEnabled'],
        false,
      ),
      centerBadgeDiscEnabled: _bool(map['centerBadgeDiscEnabled'], true),
      centerBadgeBorderMode: CenterBadgeBorderMode.fromAny(
        map['centerBadgeBorderMode'],
      ),
      centerBadgeOverlapMaskEnabled: _bool(
        map['centerBadgeOverlapMaskEnabled'],
        false,
      ),
      centerBadgeWhiteDiscOpacities: _opacityList(
        map['centerBadgeWhiteDiscOpacities'],
        kCenterBadgeWhiteDiscOpacityDefaults,
      ),
      centerBadgeWhiteIconOpacities: _opacityList(
        map['centerBadgeWhiteIconOpacities'],
        kCenterBadgeWhiteIconOpacityDefaults,
      ),
      centerBadgeWhiteProgressOpacities: _opacityList(
        map['centerBadgeWhiteProgressOpacities'],
        kCenterBadgeWhiteProgressOpacityDefaults,
      ),
      centerBadgeColoredFillOpacities: _opacityList(
        map['centerBadgeColoredFillOpacities'],
        kCenterBadgeColoredFillOpacityDefaults,
      ),
      centerBadgeColoredIconOpacities: _opacityList(
        map['centerBadgeColoredIconOpacities'],
        kCenterBadgeColoredIconOpacityDefaults,
      ),
      centerBadgeColoredProgressOpacities: _opacityList(
        map['centerBadgeColoredProgressOpacities'],
        kCenterBadgeColoredProgressOpacityDefaults,
      ),
      centerBadgeSlotSizePercents: _intList(
        map['centerBadgeSlotSizePercents'],
        kCenterBadgeSlotSizePercentDefaults,
        min: kCenterBadgeSlotSizePercentMin,
        max: kCenterBadgeSlotSizePercentMax,
      ),
      centerBadgeSlotXOffsets: _intList(
        map['centerBadgeSlotXOffsets'],
        kCenterBadgeSlotXOffsetDefaults,
        min: kCenterBadgeSlotXOffsetMin,
        max: kCenterBadgeSlotXOffsetMax,
      ),
      centerBadgeColoredBackgroundOpacity: _opacityPercent(
        map['centerBadgeColoredBackgroundOpacity'],
        kCenterBadgeColoredBackgroundOpacityDefault,
      ),
      appColor: _appColorFromMap(map),
      fabSize: _boundedInt(
        map['fabSize'],
        kFabSizeDefault,
        min: kFabSizeMin,
        max: kFabSizeMax,
      ),
    );
  }

  final MagnetType magnetType;
  final AppCardColor cardColor;
  final AppTheme theme;
  final AppBackgroundColor backgroundColor;
  final AppBoxColor boxColor;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction contentSurfaceStyle;
  final ExpenseSurfaceInteraction ghostLogboxSurfaceStyle;
  final GhostLogboxSettings ghostLogboxSettings;
  final AppBoxColor categoryMenuColor;
  final AppBoxColor categoryCardColor;
  final ExpenseSurfaceInteraction categoryCardSurfaceStyle;
  final BackheaderStyle backheaderStyle;
  final AppBoxColor statsMonthCardColor;
  final BackheaderCenterDesign centerBackheaderDesign;
  final bool centerPartitionRingEnabled;
  final bool centerBadgeDiscEnabled;
  final CenterBadgeBorderMode centerBadgeBorderMode;
  final bool centerBadgeOverlapMaskEnabled;
  final List<int> centerBadgeWhiteDiscOpacities;
  final List<int> centerBadgeWhiteIconOpacities;
  final List<int> centerBadgeWhiteProgressOpacities;
  final List<int> centerBadgeColoredFillOpacities;
  final List<int> centerBadgeColoredIconOpacities;
  final List<int> centerBadgeColoredProgressOpacities;
  final List<int> centerBadgeSlotSizePercents;
  final List<int> centerBadgeSlotXOffsets;
  final int centerBadgeColoredBackgroundOpacity;
  final AppColorMode appColor;
  final int fabSize;

  AppDesignProfile get designProfile {
    final looksNeumorphic =
        buttonSurfaceStyle == ExpenseSurfaceInteraction.raisedInset &&
        contentSurfaceStyle == ExpenseSurfaceInteraction.insetInset &&
        ghostLogboxSurfaceStyle == ExpenseSurfaceInteraction.insetInset;
    return looksNeumorphic
        ? AppDesignProfile.neumorphism
        : AppDesignProfile.normal;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'magnetType': magnetType.nativeValue,
      'cardColor': cardColor.nativeValue,
      'theme': theme.nativeValue,
      'backgroundColor': backgroundColor.nativeValue,
      'boxColor': boxColor.nativeValue,
      'buttonSurfaceStyle': buttonSurfaceStyle.nativeValue,
      'contentSurfaceStyle': contentSurfaceStyle.nativeValue,
      'ghostLogboxSurfaceStyle': ghostLogboxSurfaceStyle.nativeValue,
      'ghostLogboxSettings': ghostLogboxSettings.toMap(),
      'categoryMenuColor': categoryMenuColor.nativeValue,
      'categoryCardColor': categoryCardColor.nativeValue,
      'categoryCardSurfaceStyle': categoryCardSurfaceStyle.nativeValue,
      'backheaderStyle': backheaderStyle.nativeValue,
      'statsMonthCardColor': statsMonthCardColor.nativeValue,
      'centerBackheaderDesign': centerBackheaderDesign.nativeValue,
      'centerPartitionRingEnabled': centerPartitionRingEnabled,
      'centerBadgeDiscEnabled': centerBadgeDiscEnabled,
      'centerBadgeBorderMode': centerBadgeBorderMode.nativeValue,
      'centerBadgeOverlapMaskEnabled': centerBadgeOverlapMaskEnabled,
      'centerBadgeWhiteDiscOpacities': centerBadgeWhiteDiscOpacities,
      'centerBadgeWhiteIconOpacities': centerBadgeWhiteIconOpacities,
      'centerBadgeWhiteProgressOpacities': centerBadgeWhiteProgressOpacities,
      'centerBadgeColoredFillOpacities': centerBadgeColoredFillOpacities,
      'centerBadgeColoredIconOpacities': centerBadgeColoredIconOpacities,
      'centerBadgeColoredProgressOpacities':
          centerBadgeColoredProgressOpacities,
      'centerBadgeSlotSizePercents': centerBadgeSlotSizePercents,
      'centerBadgeSlotXOffsets': centerBadgeSlotXOffsets,
      'centerBadgeColoredBackgroundOpacity':
          centerBadgeColoredBackgroundOpacity,
      'appColor': appColor.nativeValue,
      'fabSize': fabSize,
    };
  }

  AppThemeSettings copyWith({
    MagnetType? magnetType,
    AppCardColor? cardColor,
    AppTheme? theme,
    AppBackgroundColor? backgroundColor,
    AppBoxColor? boxColor,
    ExpenseSurfaceInteraction? buttonSurfaceStyle,
    ExpenseSurfaceInteraction? contentSurfaceStyle,
    ExpenseSurfaceInteraction? ghostLogboxSurfaceStyle,
    GhostLogboxSettings? ghostLogboxSettings,
    AppBoxColor? categoryMenuColor,
    AppBoxColor? categoryCardColor,
    ExpenseSurfaceInteraction? categoryCardSurfaceStyle,
    BackheaderStyle? backheaderStyle,
    AppBoxColor? statsMonthCardColor,
    BackheaderCenterDesign? centerBackheaderDesign,
    bool? centerPartitionRingEnabled,
    bool? centerBadgeDiscEnabled,
    CenterBadgeBorderMode? centerBadgeBorderMode,
    bool? centerBadgeOverlapMaskEnabled,
    List<int>? centerBadgeWhiteDiscOpacities,
    List<int>? centerBadgeWhiteIconOpacities,
    List<int>? centerBadgeWhiteProgressOpacities,
    List<int>? centerBadgeColoredFillOpacities,
    List<int>? centerBadgeColoredIconOpacities,
    List<int>? centerBadgeColoredProgressOpacities,
    List<int>? centerBadgeSlotSizePercents,
    List<int>? centerBadgeSlotXOffsets,
    int? centerBadgeColoredBackgroundOpacity,
    AppColorMode? appColor,
    int? fabSize,
  }) {
    return AppThemeSettings(
      magnetType: magnetType ?? this.magnetType,
      cardColor: cardColor ?? this.cardColor,
      theme: theme ?? this.theme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      boxColor: boxColor ?? this.boxColor,
      buttonSurfaceStyle: buttonSurfaceStyle ?? this.buttonSurfaceStyle,
      contentSurfaceStyle: contentSurfaceStyle ?? this.contentSurfaceStyle,
      ghostLogboxSurfaceStyle:
          ghostLogboxSurfaceStyle ?? this.ghostLogboxSurfaceStyle,
      ghostLogboxSettings: ghostLogboxSettings ?? this.ghostLogboxSettings,
      categoryMenuColor: categoryMenuColor == null
          ? this.categoryMenuColor
          : _categoryBoxColorFromAny(categoryMenuColor.nativeValue),
      categoryCardColor: categoryCardColor == null
          ? this.categoryCardColor
          : _categoryBoxColorFromAny(categoryCardColor.nativeValue),
      categoryCardSurfaceStyle:
          categoryCardSurfaceStyle ?? this.categoryCardSurfaceStyle,
      backheaderStyle: backheaderStyle ?? this.backheaderStyle,
      statsMonthCardColor: statsMonthCardColor ?? this.statsMonthCardColor,
      centerBackheaderDesign:
          centerBackheaderDesign ?? this.centerBackheaderDesign,
      centerPartitionRingEnabled:
          centerPartitionRingEnabled ?? this.centerPartitionRingEnabled,
      centerBadgeDiscEnabled:
          centerBadgeDiscEnabled ?? this.centerBadgeDiscEnabled,
      centerBadgeBorderMode:
          centerBadgeBorderMode ?? this.centerBadgeBorderMode,
      centerBadgeOverlapMaskEnabled:
          centerBadgeOverlapMaskEnabled ?? this.centerBadgeOverlapMaskEnabled,
      centerBadgeWhiteDiscOpacities:
          centerBadgeWhiteDiscOpacities ?? this.centerBadgeWhiteDiscOpacities,
      centerBadgeWhiteIconOpacities:
          centerBadgeWhiteIconOpacities ?? this.centerBadgeWhiteIconOpacities,
      centerBadgeWhiteProgressOpacities:
          centerBadgeWhiteProgressOpacities ??
          this.centerBadgeWhiteProgressOpacities,
      centerBadgeColoredFillOpacities:
          centerBadgeColoredFillOpacities ??
          this.centerBadgeColoredFillOpacities,
      centerBadgeColoredIconOpacities:
          centerBadgeColoredIconOpacities ??
          this.centerBadgeColoredIconOpacities,
      centerBadgeColoredProgressOpacities:
          centerBadgeColoredProgressOpacities ??
          this.centerBadgeColoredProgressOpacities,
      centerBadgeSlotSizePercents:
          centerBadgeSlotSizePercents ?? this.centerBadgeSlotSizePercents,
      centerBadgeSlotXOffsets:
          centerBadgeSlotXOffsets ?? this.centerBadgeSlotXOffsets,
      centerBadgeColoredBackgroundOpacity:
          centerBadgeColoredBackgroundOpacity ??
          this.centerBadgeColoredBackgroundOpacity,
      appColor: appColor ?? this.appColor,
      fabSize: fabSize == null
          ? this.fabSize
          : fabSize.clamp(kFabSizeMin, kFabSizeMax).toInt(),
    );
  }

  static ExpenseSurfaceInteraction _surfaceFromMap(
    Map<dynamic, dynamic> map,
    String key,
    ExpenseSurfaceInteraction fallback,
  ) {
    if (!_hasValue(map[key])) return fallback;
    return ExpenseSurfaceInteraction.fromAny(map[key]);
  }

  static AppColorMode _appColorFromMap(Map<dynamic, dynamic> map) {
    if (_hasValue(map['appColor'])) {
      return AppColorMode.fromAny(map['appColor']);
    }
    return AppColorMode.fromAny(map['theme']);
  }

  static AppBoxColor _categoryBoxColorFromAny(Object? value) {
    return AppBoxColor.fromAny(value) == AppBoxColor.white
        ? AppBoxColor.white
        : AppBoxColor.gray;
  }

  static bool _hasValue(Object? value) {
    final raw = value?.toString().trim();
    return raw != null && raw.isNotEmpty;
  }

  static bool _bool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == '1' || normalized == 'true';
    }
    return fallback;
  }

  static List<int> _opacityList(Object? value, List<int> fallback) {
    return _intList(value, fallback, min: 0, max: 100);
  }

  static List<int> _intList(
    Object? value,
    List<int> fallback, {
    required int min,
    required int max,
  }) {
    final source = value is Iterable ? value.toList(growable: false) : null;
    return List<int>.generate(fallback.length, (index) {
      if (source == null || index >= source.length) return fallback[index];
      return _boundedInt(source[index], fallback[index], min: min, max: max);
    }, growable: false);
  }

  static int _opacityPercent(Object? value, int fallback) {
    return _boundedInt(value, fallback, min: 0, max: 100);
  }

  static int _boundedInt(
    Object? value,
    int fallback, {
    required int min,
    required int max,
  }) {
    num? parsed;
    if (value is num) {
      parsed = value;
    } else if (value is String) {
      parsed = num.tryParse(value.trim());
    }
    if (parsed == null) return fallback;
    return parsed.round().clamp(min, max).toInt();
  }
}
