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
  centerBadgeBudget('centerBadgeBudget');

  const BackheaderStyle(this.nativeValue);
  final String nativeValue;

  static BackheaderStyle fromAny(Object? value) {
    final raw = value?.toString();
    return BackheaderStyle.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => BackheaderStyle.classic,
    );
  }

  String get displayTitle => switch (this) {
    BackheaderStyle.classic => 'Jelenlegi bar rendszer',
    BackheaderStyle.heroToken => 'C - Hero Token',
    BackheaderStyle.orbitBudget => 'D - Orbit Budget',
    BackheaderStyle.centerBadgeBudget => 'E - Center Badge Budget',
  };

  String get description => switch (this) {
    BackheaderStyle.classic => 'A mostani kategória/overview bar rendszer',
    BackheaderStyle.heroToken => 'Nagy aktív kategória token mini partitionnel',
    BackheaderStyle.orbitBudget => 'Kategóriaszínű orbit/ring budget nézet',
    BackheaderStyle.centerBadgeBudget =>
      'Középső limit/budget badge élő progress ringgel',
  };
}

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

enum CategoryMenuPresentation {
  inline('inline'),
  slideUpSheet('slideUpSheet');

  const CategoryMenuPresentation(this.nativeValue);
  final String nativeValue;

  static CategoryMenuPresentation fromAny(Object? value) {
    final raw = value?.toString();
    return CategoryMenuPresentation.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => CategoryMenuPresentation.inline,
    );
  }
}

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
    required this.categoryMenuSurfaceStyle,
    required this.categoryCardColor,
    required this.categoryCardSurfaceStyle,
    required this.backheaderStyle,
    required this.appColor,
    this.categoryMenuPresentation = CategoryMenuPresentation.inline,
    this.categoryCardShadowEnabled = true,
    this.logboxShadowEnabled = false,
    this.headerPillShadowEnabled = true,
    this.summaryPillShadowEnabled = true,
    this.searchPillShadowEnabled = true,
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
      categoryMenuSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      categoryCardColor: AppBoxColor.gray,
      categoryCardSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      backheaderStyle: BackheaderStyle.classic,
      appColor: AppColorMode.turquoise,
      categoryMenuPresentation: CategoryMenuPresentation.inline,
      categoryCardShadowEnabled: true,
      logboxShadowEnabled: false,
      headerPillShadowEnabled: true,
      summaryPillShadowEnabled: true,
      searchPillShadowEnabled: true,
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
      categoryMenuColor: AppBoxColor.fromAny(map['categoryMenuColor']),
      categoryMenuSurfaceStyle: _surfaceFromMap(
        map,
        'categoryMenuSurfaceStyle',
        ExpenseSurfaceInteraction.neutralNeutral,
      ),
      categoryCardColor: AppBoxColor.fromAny(map['categoryCardColor']),
      categoryCardSurfaceStyle: _surfaceFromMap(
        map,
        'categoryCardSurfaceStyle',
        ExpenseSurfaceInteraction.neutralNeutral,
      ),
      backheaderStyle: BackheaderStyle.fromAny(map['backheaderStyle']),
      appColor: _appColorFromMap(map),
      categoryMenuPresentation: CategoryMenuPresentation.fromAny(
        map['categoryMenuPresentation'],
      ),
      categoryCardShadowEnabled: _bool(map['categoryCardShadowEnabled'], true),
      logboxShadowEnabled: _bool(map['logboxShadowEnabled'], false),
      headerPillShadowEnabled: _bool(map['headerPillShadowEnabled'], true),
      summaryPillShadowEnabled: _bool(map['summaryPillShadowEnabled'], true),
      searchPillShadowEnabled: _bool(map['searchPillShadowEnabled'], true),
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
  final ExpenseSurfaceInteraction categoryMenuSurfaceStyle;
  final AppBoxColor categoryCardColor;
  final ExpenseSurfaceInteraction categoryCardSurfaceStyle;
  final BackheaderStyle backheaderStyle;
  final AppColorMode appColor;
  final CategoryMenuPresentation categoryMenuPresentation;
  final bool categoryCardShadowEnabled;
  final bool logboxShadowEnabled;
  final bool headerPillShadowEnabled;
  final bool summaryPillShadowEnabled;
  final bool searchPillShadowEnabled;

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
      'categoryMenuSurfaceStyle': categoryMenuSurfaceStyle.nativeValue,
      'categoryCardColor': categoryCardColor.nativeValue,
      'categoryCardSurfaceStyle': categoryCardSurfaceStyle.nativeValue,
      'backheaderStyle': backheaderStyle.nativeValue,
      'appColor': appColor.nativeValue,
      'categoryMenuPresentation': categoryMenuPresentation.nativeValue,
      'categoryCardShadowEnabled': categoryCardShadowEnabled,
      'logboxShadowEnabled': logboxShadowEnabled,
      'headerPillShadowEnabled': headerPillShadowEnabled,
      'summaryPillShadowEnabled': summaryPillShadowEnabled,
      'searchPillShadowEnabled': searchPillShadowEnabled,
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
    ExpenseSurfaceInteraction? categoryMenuSurfaceStyle,
    AppBoxColor? categoryCardColor,
    ExpenseSurfaceInteraction? categoryCardSurfaceStyle,
    BackheaderStyle? backheaderStyle,
    AppColorMode? appColor,
    CategoryMenuPresentation? categoryMenuPresentation,
    bool? categoryCardShadowEnabled,
    bool? logboxShadowEnabled,
    bool? headerPillShadowEnabled,
    bool? summaryPillShadowEnabled,
    bool? searchPillShadowEnabled,
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
      categoryMenuColor: categoryMenuColor ?? this.categoryMenuColor,
      categoryMenuSurfaceStyle:
          categoryMenuSurfaceStyle ?? this.categoryMenuSurfaceStyle,
      categoryCardColor: categoryCardColor ?? this.categoryCardColor,
      categoryCardSurfaceStyle:
          categoryCardSurfaceStyle ?? this.categoryCardSurfaceStyle,
      backheaderStyle: backheaderStyle ?? this.backheaderStyle,
      appColor: appColor ?? this.appColor,
      categoryMenuPresentation:
          categoryMenuPresentation ?? this.categoryMenuPresentation,
      categoryCardShadowEnabled:
          categoryCardShadowEnabled ?? this.categoryCardShadowEnabled,
      logboxShadowEnabled: logboxShadowEnabled ?? this.logboxShadowEnabled,
      headerPillShadowEnabled:
          headerPillShadowEnabled ?? this.headerPillShadowEnabled,
      summaryPillShadowEnabled:
          summaryPillShadowEnabled ?? this.summaryPillShadowEnabled,
      searchPillShadowEnabled:
          searchPillShadowEnabled ?? this.searchPillShadowEnabled,
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
}
