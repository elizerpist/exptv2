import 'package:flutter/material.dart';

import 'dashboard_mode_palette.dart';

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

/// The presentation of the one existing semantic income/expense selector.
enum FluviDirectionControlStyle { splitButtons, slidingRail }

extension FluviDirectionControlStylePresentation on FluviDirectionControlStyle {
  String get label => switch (this) {
    FluviDirectionControlStyle.splitButtons => 'Külön gombok',
    FluviDirectionControlStyle.slidingRail => 'Csúszó rail',
  };
}

/// Presentation-only visual treatment of the one central transaction FAB.
/// It is deliberately independent from [showsDirectionArtwork], which owns
/// the semantic income/expense control rather than the FAB artwork itself.
enum FluviFabIconPresentation {
  legacyWhiteStore,
  directionArtwork,
  compactEditableVector,
  fullBabyBlueVector,
}

/// Fixed vector material sampled from the approved baby-blue FAB reference.
///
/// This is intentionally independent of the active income/expense palette:
/// the full-vector presentation is a supplied artwork treatment, while the
/// direction palette remains the authority for direction controls and the
/// normal FAB variants. Keeping the two values here gives every renderer one
/// semantic source without inventing a second direction colour profile.
abstract final class FluviFabReferenceMaterial {
  static const Color fullBabyBluePrimary = Color(0xFF06B6D4);
  static const Color fullBabyBlueHighlight = Color(0xFFDDF9FC);
}

extension FluviFabIconPresentationPresentation on FluviFabIconPresentation {
  String get label => switch (this) {
    FluviFabIconPresentation.legacyWhiteStore => 'Fehér bolt ikon',
    FluviFabIconPresentation.directionArtwork => 'Artwork',
    FluviFabIconPresentation.compactEditableVector => 'Színezhető vektor',
    FluviFabIconPresentation.fullBabyBlueVector => 'Babakék vektor',
  };
}

/// The visual location of the one existing expansion tap/drag affordance.
enum FluviCollapseHandleStyle { standalone, headerNotch, headerTranslucentPill }

extension FluviCollapseHandleStylePresentation on FluviCollapseHandleStyle {
  String get label => switch (this) {
    FluviCollapseHandleStyle.standalone => 'Különálló',
    FluviCollapseHandleStyle.headerNotch => 'Header bevágás',
    FluviCollapseHandleStyle.headerTranslucentPill => 'Áttetsző pill',
  };
}

/// Mind-only physical relationship between its reactive Header and analytics
/// surface. This has no score, heatmap, range or navigation semantics.
enum MindExpandedSurfaceStyle { separateCards, seamlessCard }

extension MindExpandedSurfaceStylePresentation on MindExpandedSurfaceStyle {
  String get label => switch (this) {
    MindExpandedSurfaceStyle.separateCards => 'Jelenlegi — külön kártyák',
    MindExpandedSurfaceStyle.seamlessCard => 'Egybefüggő kártya',
  };
}

/// Budget-only physical relationship between the existing avatar selector and
/// its detail card. It cannot change target/page selection or Budget data.
enum BudgetAvatarContentStyle { separate, overlappingGlow, avatarRail }

extension BudgetAvatarContentStylePresentation on BudgetAvatarContentStyle {
  String get label => switch (this) {
    BudgetAvatarContentStyle.separate => 'Jelenlegi',
    BudgetAvatarContentStyle.overlappingGlow => 'Rálógó + glow',
    BudgetAvatarContentStyle.avatarRail => 'Avatar rail',
  };
}

enum FluviActiveDirectionLabelTone { softenedWhite, black }

extension FluviActiveDirectionLabelTonePresentation
    on FluviActiveDirectionLabelTone {
  String get label => switch (this) {
    FluviActiveDirectionLabelTone.softenedWhite => 'Lágyított fehér',
    FluviActiveDirectionLabelTone.black => 'Fekete',
  };

  Color get color => switch (this) {
    FluviActiveDirectionLabelTone.softenedWhite => const Color(0xE6FFFFFF),
    FluviActiveDirectionLabelTone.black => Colors.black,
  };
}

/// Deliberately excludes white: an inactive rail label may be softened grey
/// or black only.
enum FluviInactiveDirectionLabelTone { softenedGray, black }

extension FluviInactiveDirectionLabelTonePresentation
    on FluviInactiveDirectionLabelTone {
  String get label => switch (this) {
    FluviInactiveDirectionLabelTone.softenedGray => 'Lágyított szürke',
    FluviInactiveDirectionLabelTone.black => 'Fekete',
  };

  Color get color => switch (this) {
    FluviInactiveDirectionLabelTone.softenedGray =>
      FluviVisualTokens.textSecondary,
    FluviInactiveDirectionLabelTone.black => Colors.black,
  };
}

/// Immutable presentation-only user choices shared by the dashboard shell.
@immutable
final class FluviGlobalAppearance {
  const FluviGlobalAppearance({
    required this.directionColorProfile,
    required this.avatarColorProfile,
    required this.showsDirectionArtwork,
    required this.typography,
    this.directionControlStyle = FluviDirectionControlStyle.splitButtons,
    this.fabIconPresentation = FluviFabIconPresentation.directionArtwork,
    this.fabVectorPrimaryArgb = 0xFF715EFB,
    this.fabVectorHighlightArgb = 0xFFE2D7FF,
    this.collapseHandleStyle = FluviCollapseHandleStyle.standalone,
    this.activeDirectionLabelTone = FluviActiveDirectionLabelTone.softenedWhite,
    this.inactiveDirectionLabelTone =
        FluviInactiveDirectionLabelTone.softenedGray,
    this.showsHeaderModeLabelAboveValue = false,
    this.mindExpandedSurfaceStyle = MindExpandedSurfaceStyle.seamlessCard,
    this.budgetAvatarContentStyle = BudgetAvatarContentStyle.separate,
  });

  const FluviGlobalAppearance.defaults()
    : directionColorProfile = FluviDirectionColorProfile.original,
      avatarColorProfile = CategoryAvatarColorProfile.original,
      showsDirectionArtwork = true,
      typography = FluviTypographyProfile.app,
      directionControlStyle = FluviDirectionControlStyle.splitButtons,
      fabIconPresentation = FluviFabIconPresentation.directionArtwork,
      fabVectorPrimaryArgb = 0xFF715EFB,
      fabVectorHighlightArgb = 0xFFE2D7FF,
      collapseHandleStyle = FluviCollapseHandleStyle.standalone,
      activeDirectionLabelTone = FluviActiveDirectionLabelTone.softenedWhite,
      inactiveDirectionLabelTone = FluviInactiveDirectionLabelTone.softenedGray,
      showsHeaderModeLabelAboveValue = false,
      mindExpandedSurfaceStyle = MindExpandedSurfaceStyle.seamlessCard,
      budgetAvatarContentStyle = BudgetAvatarContentStyle.separate;

  final FluviDirectionColorProfile directionColorProfile;
  final CategoryAvatarColorProfile avatarColorProfile;
  final bool showsDirectionArtwork;
  final FluviTypographyProfile typography;
  final FluviDirectionControlStyle directionControlStyle;
  final FluviFabIconPresentation fabIconPresentation;

  /// The editable compact-vector material palette. It has no bearing on the
  /// active income/expense semantic direction or its source palette.
  final int fabVectorPrimaryArgb;
  final int fabVectorHighlightArgb;
  final FluviCollapseHandleStyle collapseHandleStyle;
  final FluviActiveDirectionLabelTone activeDirectionLabelTone;
  final FluviInactiveDirectionLabelTone inactiveDirectionLabelTone;
  final bool showsHeaderModeLabelAboveValue;
  final MindExpandedSurfaceStyle mindExpandedSurfaceStyle;
  final BudgetAvatarContentStyle budgetAvatarContentStyle;

  FluviGlobalAppearance copyWith({
    FluviDirectionColorProfile? directionColorProfile,
    CategoryAvatarColorProfile? avatarColorProfile,
    bool? showsDirectionArtwork,
    FluviTypographyProfile? typography,
    FluviDirectionControlStyle? directionControlStyle,
    FluviFabIconPresentation? fabIconPresentation,
    int? fabVectorPrimaryArgb,
    int? fabVectorHighlightArgb,
    FluviCollapseHandleStyle? collapseHandleStyle,
    FluviActiveDirectionLabelTone? activeDirectionLabelTone,
    FluviInactiveDirectionLabelTone? inactiveDirectionLabelTone,
    bool? showsHeaderModeLabelAboveValue,
    MindExpandedSurfaceStyle? mindExpandedSurfaceStyle,
    BudgetAvatarContentStyle? budgetAvatarContentStyle,
  }) => FluviGlobalAppearance(
    directionColorProfile: directionColorProfile ?? this.directionColorProfile,
    avatarColorProfile: avatarColorProfile ?? this.avatarColorProfile,
    showsDirectionArtwork: showsDirectionArtwork ?? this.showsDirectionArtwork,
    typography: typography ?? this.typography,
    directionControlStyle: directionControlStyle ?? this.directionControlStyle,
    fabIconPresentation: fabIconPresentation ?? this.fabIconPresentation,
    fabVectorPrimaryArgb: fabVectorPrimaryArgb ?? this.fabVectorPrimaryArgb,
    fabVectorHighlightArgb:
        fabVectorHighlightArgb ?? this.fabVectorHighlightArgb,
    collapseHandleStyle: collapseHandleStyle ?? this.collapseHandleStyle,
    activeDirectionLabelTone:
        activeDirectionLabelTone ?? this.activeDirectionLabelTone,
    inactiveDirectionLabelTone:
        inactiveDirectionLabelTone ?? this.inactiveDirectionLabelTone,
    showsHeaderModeLabelAboveValue:
        showsHeaderModeLabelAboveValue ?? this.showsHeaderModeLabelAboveValue,
    mindExpandedSurfaceStyle:
        mindExpandedSurfaceStyle ?? this.mindExpandedSurfaceStyle,
    budgetAvatarContentStyle:
        budgetAvatarContentStyle ?? this.budgetAvatarContentStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is FluviGlobalAppearance &&
      directionColorProfile == other.directionColorProfile &&
      avatarColorProfile == other.avatarColorProfile &&
      showsDirectionArtwork == other.showsDirectionArtwork &&
      typography == other.typography &&
      directionControlStyle == other.directionControlStyle &&
      fabIconPresentation == other.fabIconPresentation &&
      fabVectorPrimaryArgb == other.fabVectorPrimaryArgb &&
      fabVectorHighlightArgb == other.fabVectorHighlightArgb &&
      collapseHandleStyle == other.collapseHandleStyle &&
      activeDirectionLabelTone == other.activeDirectionLabelTone &&
      inactiveDirectionLabelTone == other.inactiveDirectionLabelTone &&
      showsHeaderModeLabelAboveValue == other.showsHeaderModeLabelAboveValue &&
      mindExpandedSurfaceStyle == other.mindExpandedSurfaceStyle &&
      budgetAvatarContentStyle == other.budgetAvatarContentStyle;

  @override
  int get hashCode => Object.hash(
    directionColorProfile,
    avatarColorProfile,
    showsDirectionArtwork,
    typography,
    directionControlStyle,
    fabIconPresentation,
    fabVectorPrimaryArgb,
    fabVectorHighlightArgb,
    collapseHandleStyle,
    activeDirectionLabelTone,
    inactiveDirectionLabelTone,
    showsHeaderModeLabelAboveValue,
    mindExpandedSurfaceStyle,
    budgetAvatarContentStyle,
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

  /// Samples an authored direction gradient at its exact centre stop. The
  /// active direction pill and the BNB FAB therefore share a source palette:
  /// a future user-selected profile change automatically keeps their middle
  /// color in sync without a second FAB palette.
  static Color midpoint(LinearGradient gradient) {
    final stops =
        gradient.stops ??
        List<double>.generate(
          gradient.colors.length,
          (index) => gradient.colors.length == 1
              ? 0
              : index / (gradient.colors.length - 1),
        );
    for (var index = 1; index < stops.length; index += 1) {
      if (stops[index] < .5) continue;
      final lowerStop = stops[index - 1];
      final upperStop = stops[index];
      final fraction = upperStop == lowerStop
          ? 0.0
          : (.5 - lowerStop) / (upperStop - lowerStop);
      return Color.lerp(
        gradient.colors[index - 1],
        gradient.colors[index],
        fraction.clamp(0.0, 1.0),
      )!;
    }
    return gradient.colors.last;
  }

  /// The rail paints one immutable purple-to-pink field in rail coordinates.
  /// The moving active pill is only a rounded window into this full-width
  /// shader; it must never carry a pill-local gradient with it.
  static LinearGradient rail(FluviDirectionColorProfile profile) {
    final source = income(profile);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: source.colors,
      stops: source.stops,
    );
  }
}
