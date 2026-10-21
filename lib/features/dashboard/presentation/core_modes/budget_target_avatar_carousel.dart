import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_budget_presentation_controller.dart';

/// One geometry authority for the Budget target rail wherever it is mounted.
/// The dashboard and the fullscreen manager deliberately create separate
/// [CenteredCarouselController] instances, while using this same geometry and
/// motion preset.
abstract final class BudgetTargetAvatarCarouselGeometry {
  static const double itemExtent = 58;
  static const double selectedInputSurfaceHeight =
      BudgetCategoryAvatarGeometry.selectionShellVisualDiameter;
  static const double selectedInputVerticalOverflow =
      (selectedInputSurfaceHeight -
          BudgetCategoryAvatarGeometry.avatarCanvasSize) /
      2;

  /// The fullscreen manager preserves its former single-avatar allocation;
  /// the shared rail paints its selected shell with Clip.none above it rather
  /// than pushing the editor content down.
  static const double managerViewportHeight = 72;
}

/// Shared prepared visual target. Preparation is bounded to the catalog and
/// uses the already-ready vector atlas; carousel crossings never parse SVG.
@immutable
final class BudgetTargetAvatarCarouselItem {
  BudgetTargetAvatarCarouselItem._({
    required this.targetHandle,
    required this.stableId,
    required this.title,
    required this.baseColorArgb,
    required this.iconAssetKey,
    required this.colorId,
    required this.iconId,
    required this.gradientStartArgb,
    required this.gradientEndArgb,
    required this.avatarColorProfile,
    required this.color,
    required this.icon,
    required this.artworkIdentity,
    required this.faceGradient,
  }) : _normalArtworkSource = BudgetCategoryAvatarSvg.flutterRenderable(
         BudgetCategoryAvatarSvg.avatarDisc(
           color,
           artworkIdentity,
           variant: BudgetCategoryAvatarVariant.normalRail,
           faceGradient: faceGradient,
         ),
       ),
       _centeredCoreArtworkSource = BudgetCategoryAvatarSvg.flutterRenderable(
         BudgetCategoryAvatarSvg.avatarDisc(
           color,
           artworkIdentity,
           variant: BudgetCategoryAvatarVariant.centeredCore,
           faceGradient: faceGradient,
         ),
       ),
       _centeredShadowedArtworkSource =
           BudgetCategoryAvatarSvg.flutterRenderable(
             BudgetCategoryAvatarSvg.avatarDisc(
               color,
               artworkIdentity,
               variant: BudgetCategoryAvatarVariant.centeredShadowed,
               faceGradient: faceGradient,
             ),
           );

  factory BudgetTargetAvatarCarouselItem.prepare(
    DashboardBudgetTargetPresentationItem item,
    PreparedVectorAssetAtlas atlas, {
    required CategoryAvatarColorProfile avatarColorProfile,
  }) {
    final categoryPalette =
        item.colorId == null ||
            avatarColorProfile == CategoryAvatarColorProfile.original
        ? null
        : CategoryAvatarPaletteCatalog.tokenFor(
            avatarColorProfile,
            CategoryColorCatalog.handleOf(item.colorId!),
          );
    final categoryColor =
        categoryPalette?.middleColor ??
        (item.colorId == null
            ? Color(item.baseColorArgb)
            : CategoryColorCatalog.resolve(item.colorId!).middleColor);
    final icon = switch (item.iconAssetKey) {
      'dollar-sign' => atlas.categoryIcon(
        CategoryIconCatalog.handleOf('icon_17'),
      ),
      'banknote' => atlas.picture(
        PreparedVectorAssetAtlas.budgetIncomeGoalBanknoteHandle,
      ),
      _ => atlas.categoryIcon(CategoryIconCatalog.handleOf(item.iconId!)),
    };
    final start = categoryPalette?.colorA.toARGB32() ?? item.gradientStartArgb;
    final end = categoryPalette?.colorB.toARGB32() ?? item.gradientEndArgb;
    return BudgetTargetAvatarCarouselItem._(
      targetHandle: item.target.handle,
      stableId: item.stableId,
      title: item.title,
      baseColorArgb: item.baseColorArgb,
      iconAssetKey: item.iconAssetKey,
      colorId: item.colorId,
      iconId: item.iconId,
      gradientStartArgb: start,
      gradientEndArgb: end,
      avatarColorProfile: avatarColorProfile,
      color: categoryColor,
      icon: icon,
      artworkIdentity: Object.hash(
        item.stableId,
        avatarColorProfile,
        categoryColor.toARGB32(),
        start,
        end,
      ),
      faceGradient: start == null || end == null
          ? null
          : BudgetCategoryAvatarFaceGradient(
              start: Color(start),
              middle: categoryColor,
              end: Color(end),
            ),
    );
  }

  /// Builds the one reusable prepared-artwork catalog for a Budget rail.
  /// Both the dashboard and the fullscreen manager use this exact path;
  /// no caller parses or maps avatar artwork during a carousel crossing.
  static List<BudgetTargetAvatarCarouselItem> prepareAll(
    Iterable<DashboardBudgetTargetPresentationItem> items,
    PreparedVectorAssetAtlas atlas, {
    required CategoryAvatarColorProfile avatarColorProfile,
  }) => List<BudgetTargetAvatarCarouselItem>.unmodifiable([
    for (final item in items)
      BudgetTargetAvatarCarouselItem.prepare(
        item,
        atlas,
        avatarColorProfile: avatarColorProfile,
      ),
  ]);

  final int targetHandle;
  final String stableId;
  final String title;
  final int baseColorArgb;
  final String iconAssetKey;
  final String? colorId;
  final String? iconId;
  final int? gradientStartArgb;
  final int? gradientEndArgb;
  final CategoryAvatarColorProfile avatarColorProfile;
  final Color color;
  final PreparedVectorPicture icon;
  final int artworkIdentity;
  final BudgetCategoryAvatarFaceGradient? faceGradient;
  final String _normalArtworkSource;
  final String _centeredCoreArtworkSource;
  final String _centeredShadowedArtworkSource;

  bool matches(DashboardBudgetTargetPresentationItem candidate) =>
      stableId == candidate.stableId &&
      title == candidate.title &&
      baseColorArgb == candidate.baseColorArgb &&
      iconAssetKey == candidate.iconAssetKey &&
      colorId == candidate.colorId &&
      iconId == candidate.iconId &&
      gradientStartArgb == candidate.gradientStartArgb &&
      gradientEndArgb == candidate.gradientEndArgb;

  Widget avatarFor({
    required bool selected,
    ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
    selectedLimitVisualListenable,
    Listenable? selectedLiveSelectionListenable,
    BudgetCategoryAvatarSelectedLimitVisualState Function()?
    selectedLimitVisualForLiveSelection,
    VoidCallback? onSelectionVisualIdentityMismatch,
    ValueChanged<BudgetCategoryAvatarSelectedLimitVisualState>?
    onSelectionProgressBuilt,
    BudgetCategoryAvatarProgressPainted? onSelectionProgressPainted,
  }) => BudgetCategoryAvatarArtwork(
    key: selected ? const ValueKey('budget-target-avatar-center') : null,
    color: color,
    icon: icon,
    semanticsLabel: title,
    svgSource: _normalArtworkSource,
    centeredCoreSvgSource: _centeredCoreArtworkSource,
    centeredShadowedSvgSource: _centeredShadowedArtworkSource,
    selected: selected,
    selectedTargetHandle: selected ? targetHandle : null,
    selectedLimitVisualListenable: selectedLimitVisualListenable,
    selectedLiveSelectionListenable: selectedLiveSelectionListenable,
    selectedLimitVisualForLiveSelection: selectedLimitVisualForLiveSelection,
    onSelectionVisualIdentityMismatch: onSelectionVisualIdentityMismatch,
    onSelectionProgressBuilt: onSelectionProgressBuilt,
    onSelectionProgressPainted: onSelectionProgressPainted,
  );
}

/// Physical/visual Budget target rail primitive.  Callers provide only their
/// target catalog, their own controller instance and feature-specific
/// callbacks; motion, cyclic indexing, haptic crossings and SVG preparation
/// are implemented exactly once here.
final class BudgetTargetAvatarCarousel extends StatefulWidget {
  const BudgetTargetAvatarCarousel({
    super.key,
    required this.items,
    required this.controller,
    required this.itemBuilder,
    this.onPreviewChanged,
    this.onSelectionSettled,
    this.onMotionStarted,
    this.onBallisticStarted,
    this.onMotionInterrupted,
    this.onDirectPointerDown,
    this.onPointerDownDecision,
    this.semanticsLabelBuilder,
    this.height = BudgetTargetAvatarCarouselGeometry.selectedInputSurfaceHeight,
  });

  final List<BudgetTargetAvatarCarouselItem> items;
  final CenteredCarouselController controller;
  final Widget Function(
    BuildContext context,
    BudgetTargetAvatarCarouselItem item,
    CenteredCarouselItemMetrics metrics,
  )
  itemBuilder;
  final ValueChanged<int>? onPreviewChanged;
  final ValueChanged<int>? onSelectionSettled;
  final ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted;
  final ValueChanged<double>? onBallisticStarted;
  final VoidCallback? onMotionInterrupted;
  final VoidCallback? onDirectPointerDown;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onPointerDownDecision;
  final String Function(BudgetTargetAvatarCarouselItem item)?
  semanticsLabelBuilder;
  final double height;

  /// Exposed for structural tests and to make the single physics authority
  /// explicit at both call sites.
  static CenteredCarouselSpec budgetPreset() =>
      CenteredCarouselPresets.budgetCategoryAvatarRail(
        itemExtent: BudgetTargetAvatarCarouselGeometry.itemExtent,
      );

  @override
  State<BudgetTargetAvatarCarousel> createState() =>
      _BudgetTargetAvatarCarouselState();
}

final class _BudgetTargetAvatarCarouselState
    extends State<BudgetTargetAvatarCarousel> {
  late final CenteredCarouselSpec _spec;

  @override
  void initState() {
    super.initState();
    _spec = BudgetTargetAvatarCarousel.budgetPreset();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CenteredCarousel<BudgetTargetAvatarCarouselItem>(
      key: const ValueKey('budget-target-avatar-carousel'),
      dataSource: CyclicCarouselDataSource<BudgetTargetAvatarCarouselItem>(
        widget.items,
      ),
      controller: widget.controller,
      spec: _spec,
      height: widget.height,
      semanticsLabelBuilder:
          widget.semanticsLabelBuilder ?? (item) => item.title,
      onPreviewChanged: widget.onPreviewChanged,
      onDirectPointerDown: widget.onDirectPointerDown,
      onPointerDownDecision: widget.onPointerDownDecision,
      onSelectionSettled: widget.onSelectionSettled,
      onMotionStarted: widget.onMotionStarted,
      onBallisticStarted: widget.onBallisticStarted,
      onMotionInterrupted: widget.onMotionInterrupted,
      itemBuilder: widget.itemBuilder,
    ),
  );
}

int budgetTargetAvatarCarouselModulo(int value, int divisor) =>
    ((value % divisor) + divisor) % divisor;
