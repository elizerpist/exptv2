import '../theme/expense_surface.dart';

export '../theme/expense_surface.dart';

enum MagnetType {
  fade('fade'),
  nofade('nofade'),
  budget('budget'),
  magnetcard('magnetcard'),
  adaptive('adaptive');

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
  orbitBudget('orbitBudget');

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
  };

  String get description => switch (this) {
    BackheaderStyle.classic => 'A mostani kategória/overview bar rendszer',
    BackheaderStyle.heroToken => 'Nagy aktív kategória token mini partitionnel',
    BackheaderStyle.orbitBudget => 'Kategóriaszínű orbit/ring budget nézet',
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
  turquoise('Türkiz'),
  dark('Sötét');

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

class AppThemeSettings {
  const AppThemeSettings({
    required this.magnetType,
    required this.cardColor,
    required this.theme,
    required this.backgroundColor,
    required this.boxColor,
    required this.buttonSurfaceStyle,
    required this.contentSurfaceStyle,
    required this.backheaderStyle,
  });

  factory AppThemeSettings.defaults() {
    return const AppThemeSettings(
      magnetType: MagnetType.fade,
      cardColor: AppCardColor.lightgray,
      theme: AppTheme.turquoise,
      backgroundColor: AppBackgroundColor.gray,
      boxColor: AppBoxColor.gray,
      buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      contentSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
      backheaderStyle: BackheaderStyle.classic,
    );
  }

  factory AppThemeSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppThemeSettings(
      magnetType: MagnetType.fromAny(map['magnetType']),
      cardColor: AppCardColor.fromAny(map['cardColor']),
      theme: AppTheme.fromAny(map['theme']),
      backgroundColor: AppBackgroundColor.fromAny(map['backgroundColor']),
      boxColor: AppBoxColor.fromAny(map['boxColor']),
      buttonSurfaceStyle: ExpenseSurfaceInteraction.fromAny(
        map['buttonSurfaceStyle'],
      ),
      contentSurfaceStyle: ExpenseSurfaceInteraction.fromAny(
        map['contentSurfaceStyle'],
      ),
      backheaderStyle: BackheaderStyle.fromAny(map['backheaderStyle']),
    );
  }

  final MagnetType magnetType;
  final AppCardColor cardColor;
  final AppTheme theme;
  final AppBackgroundColor backgroundColor;
  final AppBoxColor boxColor;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction contentSurfaceStyle;
  final BackheaderStyle backheaderStyle;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'magnetType': magnetType.nativeValue,
      'cardColor': cardColor.nativeValue,
      'theme': theme.nativeValue,
      'backgroundColor': backgroundColor.nativeValue,
      'boxColor': boxColor.nativeValue,
      'buttonSurfaceStyle': buttonSurfaceStyle.nativeValue,
      'contentSurfaceStyle': contentSurfaceStyle.nativeValue,
      'backheaderStyle': backheaderStyle.nativeValue,
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
    BackheaderStyle? backheaderStyle,
  }) {
    return AppThemeSettings(
      magnetType: magnetType ?? this.magnetType,
      cardColor: cardColor ?? this.cardColor,
      theme: theme ?? this.theme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      boxColor: boxColor ?? this.boxColor,
      buttonSurfaceStyle: buttonSurfaceStyle ?? this.buttonSurfaceStyle,
      contentSurfaceStyle: contentSurfaceStyle ?? this.contentSurfaceStyle,
      backheaderStyle: backheaderStyle ?? this.backheaderStyle,
    );
  }
}
