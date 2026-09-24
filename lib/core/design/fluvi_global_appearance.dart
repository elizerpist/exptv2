import 'package:flutter/material.dart';

/// One session-lifetime user choice for the active income/expense treatment.
enum FluviDirectionColorProfile { original, pastel, saturated, vivid }

extension FluviDirectionColorProfilePresentation on FluviDirectionColorProfile {
  String get label => switch (this) {
    FluviDirectionColorProfile.original => 'Eredeti',
    FluviDirectionColorProfile.pastel => 'Pastel',
    FluviDirectionColorProfile.saturated => 'Telítettebb',
    FluviDirectionColorProfile.vivid => 'Élénk',
  };
}

/// The only user-selectable application typeface choice.
enum FluviTypographyProfile { app, colorLab }

extension FluviTypographyProfilePresentation on FluviTypographyProfile {
  String get label => switch (this) {
    FluviTypographyProfile.app => 'App',
    FluviTypographyProfile.colorLab => 'Color Lab',
  };

  String? get fontFamily => switch (this) {
    FluviTypographyProfile.app => null,
    FluviTypographyProfile.colorLab => 'FluviColorLabInter',
  };

  TextStyle applyTo(TextStyle style) =>
      fontFamily == null ? style : style.copyWith(fontFamily: fontFamily);

  ThemeData applyToTheme(ThemeData theme) => fontFamily == null
      ? theme
      : theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: theme.primaryTextTheme.apply(
            fontFamily: fontFamily,
          ),
        );
}

/// Immutable presentation-only user choices shared by the dashboard shell.
@immutable
final class FluviGlobalAppearance {
  const FluviGlobalAppearance({
    required this.directionColorProfile,
    required this.avatarColorProfile,
    required this.showsDirectionArtwork,
    required this.typography,
  });

  const FluviGlobalAppearance.defaults()
    : directionColorProfile = FluviDirectionColorProfile.original,
      avatarColorProfile = CategoryAvatarColorProfile.original,
      showsDirectionArtwork = true,
      typography = FluviTypographyProfile.app;

  final FluviDirectionColorProfile directionColorProfile;
  final CategoryAvatarColorProfile avatarColorProfile;
  final bool showsDirectionArtwork;
  final FluviTypographyProfile typography;

  FluviGlobalAppearance copyWith({
    FluviDirectionColorProfile? directionColorProfile,
    CategoryAvatarColorProfile? avatarColorProfile,
    bool? showsDirectionArtwork,
    FluviTypographyProfile? typography,
  }) => FluviGlobalAppearance(
    directionColorProfile: directionColorProfile ?? this.directionColorProfile,
    avatarColorProfile: avatarColorProfile ?? this.avatarColorProfile,
    showsDirectionArtwork: showsDirectionArtwork ?? this.showsDirectionArtwork,
    typography: typography ?? this.typography,
  );

  @override
  bool operator ==(Object other) =>
      other is FluviGlobalAppearance &&
      directionColorProfile == other.directionColorProfile &&
      avatarColorProfile == other.avatarColorProfile &&
      showsDirectionArtwork == other.showsDirectionArtwork &&
      typography == other.typography;

  @override
  int get hashCode => Object.hash(
    directionColorProfile,
    avatarColorProfile,
    showsDirectionArtwork,
    typography,
  );
}

/// The semantic profile for an existing category colour handle.
enum CategoryAvatarColorProfile { original, pastel, saturated, vivid }

extension CategoryAvatarColorProfilePresentation on CategoryAvatarColorProfile {
  String get label => switch (this) {
    CategoryAvatarColorProfile.original => 'Eredeti',
    CategoryAvatarColorProfile.pastel => 'Pastel',
    CategoryAvatarColorProfile.saturated => 'Telítettebb',
    CategoryAvatarColorProfile.vivid => 'Élénk',
  };
}

/// Exact authored active treatments for the shared direction control.
abstract final class FluviDirectionColorPaletteCatalog {
  static const LinearGradient _originalIncome = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF715EFB), Color(0xFFB484F3), Color(0xFFE478C3)],
    stops: <double>[0, .5, 1],
  );
  // Preserve the current two-stop expense gradient geometry and implicit
  // stops exactly; alternatives are the supplied three-stop authored data.
  static const LinearGradient _originalExpense = LinearGradient(
    colors: <Color>[Color(0xFFFF8A3D), Color(0xFFF542A7)],
  );
  static const LinearGradient _pastelIncome = LinearGradient(
    colors: <Color>[Color(0xFFAF99FF), Color(0xFFCAADFF), Color(0xFFFFC2E2)],
    stops: <double>[0, .5, 1],
  );
  static const LinearGradient _pastelExpense = LinearGradient(
    colors: <Color>[Color(0xFFFFC2E2), Color(0xFFFFADC7), Color(0xFFFF99B6)],
    stops: <double>[0, .5, 1],
  );
  static const LinearGradient _saturatedIncome = LinearGradient(
    colors: <Color>[Color(0xFF9678FF), Color(0xFFB388FF), Color(0xFFFF9ED6)],
    stops: <double>[0, .5, 1],
  );
  static const LinearGradient _saturatedExpense = LinearGradient(
    colors: <Color>[Color(0xFFFF9ED6), Color(0xFFFF7FAE), Color(0xFFFF6A95)],
    stops: <double>[0, .5, 1],
  );
  static const LinearGradient _vividIncome = LinearGradient(
    colors: <Color>[Color(0xFF7A52FF), Color(0xFF9F66FF), Color(0xFFFF78CB)],
    stops: <double>[0, .5, 1],
  );
  static const LinearGradient _vividExpense = LinearGradient(
    colors: <Color>[Color(0xFFFF78CB), Color(0xFFFF4F96), Color(0xFFFF3380)],
    stops: <double>[0, .5, 1],
  );

  static LinearGradient income(FluviDirectionColorProfile profile) =>
      switch (profile) {
        FluviDirectionColorProfile.original => _originalIncome,
        FluviDirectionColorProfile.pastel => _pastelIncome,
        FluviDirectionColorProfile.saturated => _saturatedIncome,
        FluviDirectionColorProfile.vivid => _vividIncome,
      };

  static LinearGradient expense(FluviDirectionColorProfile profile) =>
      switch (profile) {
        FluviDirectionColorProfile.original => _originalExpense,
        FluviDirectionColorProfile.pastel => _pastelExpense,
        FluviDirectionColorProfile.saturated => _saturatedExpense,
        FluviDirectionColorProfile.vivid => _vividExpense,
      };
}
