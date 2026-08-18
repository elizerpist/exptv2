import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import 'budget_limit_quick_edit_gesture.dart';
import 'budget_target_avatar_interaction.dart';

/// Budget card1's presentation-only five-position target rail. Aggregate and
/// real-category targets share the same prepared motion/render path, while
/// only the headless Budget presentation controller owns semantic selection.
class BudgetTargetAvatarRail extends StatefulWidget {
  const BudgetTargetAvatarRail({
    super.key,
    required this.presentation,
    this.limitEditController,
  });

  final DashboardBudgetPresentationController presentation;
  final DashboardBudgetLimitEditController? limitEditController;

  @override
  State<BudgetTargetAvatarRail> createState() => _BudgetTargetAvatarRailState();
}

class _BudgetTargetAvatarRailState extends State<BudgetTargetAvatarRail> {
  static const _itemExtent = 58.0;

  late final CenteredCarouselController _controller;
  late final CenteredCarouselSpec _spec;
  List<_PreparedBudgetTargetAvatar> _items =
      const <_PreparedBudgetTargetAvatar>[];
  int? _lastProgressIdentityMismatchSignature;
  BudgetLimitQuickEditGestureController? _quickEdit;

  @override
  void initState() {
    super.initState();
    _controller = CenteredCarouselController(initialIndex: 0);
    _spec = CenteredCarouselPresets.budgetCategoryAvatarRail(
      itemExtent: _itemExtent,
    );
    _quickEdit = _createQuickEditController();
    _replaceItems(widget.presentation.value.items, initial: true);
    widget.presentation.addListener(_onPresentationChanged);
  }

  @override
  void didUpdateWidget(covariant BudgetTargetAvatarRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onPresentationChanged);
      widget.presentation.addListener(_onPresentationChanged);
      _onPresentationChanged();
    }
    if (!identical(oldWidget.limitEditController, widget.limitEditController)) {
      _quickEdit?.dispose();
      _quickEdit = _createQuickEditController();
    }
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onPresentationChanged);
    _quickEdit?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPresentationChanged() {
    if (_replaceItems(widget.presentation.value.items) && mounted) {
      setState(() {});
    }
  }

  BudgetLimitQuickEditGestureController? _createQuickEditController() {
    final edits = widget.limitEditController;
    if (edits == null) return null;
    return BudgetLimitQuickEditGestureController(
      edits: edits,
      contextForCurrentSelection: () {
        final context = widget.presentation.value.header.limitEditContext;
        if (context == null) {
          throw StateError('A prepared Budget header is required to edit.');
        }
        return context;
      },
    );
  }

  bool _replaceItems(
    List<DashboardBudgetTargetPresentationItem> next, {
    bool initial = false,
  }) {
    if (_sameItems(_items, next)) return false;
    final previousCenterId = _items.isEmpty
        ? null
        : _items[_modulo(_controller.selectedLogicalIndex, _items.length)]
              .stableId;
    final prepared = _prepareItems(next);
    final nextCenter = previousCenterId == null
        ? widget.presentation.value.selectedHandle
        : prepared.indexWhere((item) => item.stableId == previousCenterId);
    _items = prepared;
    if (!initial && prepared.isNotEmpty) {
      _controller.installSemanticDomain(
        dataMode: CenteredCarouselDataMode.cyclic,
        finiteLength: prepared.length,
        selectedLogicalIndex: nextCenter < 0 ? 0 : nextCenter,
      );
    }
    return true;
  }

  List<_PreparedBudgetTargetAvatar> _prepareItems(
    List<DashboardBudgetTargetPresentationItem> source,
  ) {
    if (source.isEmpty) return const <_PreparedBudgetTargetAvatar>[];
    final atlas = PreparedVectorAssetAtlas.instance;
    if (!atlas.isReady) return const <_PreparedBudgetTargetAvatar>[];
    return List<_PreparedBudgetTargetAvatar>.unmodifiable([
      for (final item in source)
        _PreparedBudgetTargetAvatar.prepare(item, atlas),
    ]);
  }

  bool _sameItems(
    List<_PreparedBudgetTargetAvatar> current,
    List<DashboardBudgetTargetPresentationItem> next,
  ) {
    if (current.length != next.length) return false;
    for (var index = 0; index < current.length; index += 1) {
      final existing = current[index];
      final candidate = next[index];
      if (existing.stableId != candidate.stableId ||
          existing.title != candidate.title ||
          existing.baseColorArgb != candidate.baseColorArgb ||
          existing.iconAssetKey != candidate.iconAssetKey ||
          existing.colorId != candidate.colorId ||
          existing.iconId != candidate.iconId ||
          existing.gradientStartArgb != candidate.gradientStartArgb ||
          existing.gradientEndArgb != candidate.gradientEndArgb) {
        return false;
      }
    }
    return true;
  }

  void _onPreviewChanged(int logicalIndex) {
    if (_items.isEmpty) return;
    widget.presentation.setTargetHandle(
      _items[_modulo(logicalIndex, _items.length)].targetHandle,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: const ValueKey('budget-target-avatar-rail'),
    child: _items.isEmpty
        ? const SizedBox.shrink()
        : RepaintBoundary(
            child: CenteredCarousel<_PreparedBudgetTargetAvatar>(
              key: const ValueKey('budget-target-avatar-carousel'),
              dataSource: CyclicCarouselDataSource<_PreparedBudgetTargetAvatar>(
                _items,
              ),
              controller: _controller,
              spec: _spec,
              height: BudgetCategoryAvatarGeometry.avatarCanvasSize,
              semanticsLabelBuilder: (item) => item.title,
              onPreviewChanged: _onPreviewChanged,
              itemBuilder: (context, item, metrics) => SizedBox.square(
                dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
                child: BudgetTargetAvatarInteraction(
                  onLongPressStart:
                      metrics.isSelected &&
                          _quickEdit != null &&
                          widget.presentation.value.header.limitEditContext !=
                              null
                      ? (details) => _quickEdit?.longPressStarted(
                          globalY: details.globalPosition.dy,
                        )
                      : null,
                  onLongPressMoveUpdate:
                      metrics.isSelected &&
                          _quickEdit != null &&
                          widget.presentation.value.header.limitEditContext !=
                              null
                      ? (details) => _quickEdit?.longPressMoved(
                          globalY: details.globalPosition.dy,
                        )
                      : null,
                  onLongPressEnd:
                      metrics.isSelected &&
                          _quickEdit != null &&
                          widget.presentation.value.header.limitEditContext !=
                              null
                      ? (_) => unawaited(
                          _quickEdit?.longPressEnded() ?? Future<void>.value(),
                        )
                      : null,
                  onLongPressCancel:
                      metrics.isSelected &&
                          _quickEdit != null &&
                          widget.presentation.value.header.limitEditContext !=
                              null
                      ? () => unawaited(
                          _quickEdit?.longPressEnded() ?? Future<void>.value(),
                        )
                      : null,
                  child: item.avatarFor(
                    selected: metrics.isSelected,
                    selectedLiveSelectionListenable: metrics.isSelected
                        ? widget.presentation
                        : null,
                    selectedLimitVisualForLiveSelection: metrics.isSelected
                        ? () => widget.presentation.value.selectedLimitVisual
                        : null,
                    onSelectionVisualIdentityMismatch: () =>
                        _recordProgressIdentityMismatch(item.targetHandle),
                  ),
                ),
              ),
            ),
          ),
  );

  void _recordProgressIdentityMismatch(int avatarTargetHandle) {
    final visual = widget.presentation.value.selectedLimitVisual;
    final signature = Object.hash(
      avatarTargetHandle,
      visual.targetHandle,
      visual.limitKey,
    );
    if (_lastProgressIdentityMismatchSignature == signature) return;
    _lastProgressIdentityMismatchSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_IDENTITY_MISMATCH',
        scope:
            'avatarTargetHandle=$avatarTargetHandle '
            'visualTargetHandle=${visual.targetHandle} '
            'limitKey=${visual.limitKey.runtimeType}',
      ),
    );
  }
}

final class _PreparedBudgetTargetAvatar {
  _PreparedBudgetTargetAvatar._({
    required this.targetHandle,
    required this.stableId,
    required this.title,
    required this.baseColorArgb,
    required this.iconAssetKey,
    required this.colorId,
    required this.iconId,
    required this.gradientStartArgb,
    required this.gradientEndArgb,
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
       );

  factory _PreparedBudgetTargetAvatar.prepare(
    DashboardBudgetTargetPresentationItem item,
    PreparedVectorAssetAtlas atlas,
  ) {
    final categoryColor = item.colorId == null
        ? Color(item.baseColorArgb)
        : CategoryColorCatalog.resolve(item.colorId!).middleColor;
    final icon = switch (item.iconAssetKey) {
      'dollar-sign' => atlas.categoryIcon(
        CategoryIconCatalog.handleOf('icon_17'),
      ),
      'banknote' => atlas.picture(
        PreparedVectorAssetAtlas.budgetIncomeGoalBanknoteHandle,
      ),
      _ => atlas.categoryIcon(CategoryIconCatalog.handleOf(item.iconId!)),
    };
    final start = item.gradientStartArgb;
    final end = item.gradientEndArgb;
    return _PreparedBudgetTargetAvatar._(
      targetHandle: item.target.handle,
      stableId: item.stableId,
      title: item.title,
      baseColorArgb: item.baseColorArgb,
      iconAssetKey: item.iconAssetKey,
      colorId: item.colorId,
      iconId: item.iconId,
      gradientStartArgb: start,
      gradientEndArgb: end,
      color: categoryColor,
      icon: icon,
      artworkIdentity: Object.hash(item.stableId, categoryColor.toARGB32()),
      faceGradient: start == null || end == null
          ? null
          : BudgetCategoryAvatarFaceGradient(
              start: Color(start),
              middle: categoryColor,
              end: Color(end),
            ),
    );
  }

  final int targetHandle;
  final String stableId;
  final String title;
  final int baseColorArgb;
  final String iconAssetKey;
  final String? colorId;
  final String? iconId;
  final int? gradientStartArgb;
  final int? gradientEndArgb;
  final Color color;
  final PreparedVectorPicture icon;
  final int artworkIdentity;
  final BudgetCategoryAvatarFaceGradient? faceGradient;
  final String _normalArtworkSource;
  final String _centeredCoreArtworkSource;

  Widget avatarFor({
    required bool selected,
    ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
    selectedLimitVisualListenable,
    Listenable? selectedLiveSelectionListenable,
    BudgetCategoryAvatarSelectedLimitVisualState Function()?
    selectedLimitVisualForLiveSelection,
    VoidCallback? onSelectionVisualIdentityMismatch,
  }) => BudgetCategoryAvatarArtwork(
    key: selected ? const ValueKey('budget-target-avatar-center') : null,
    color: color,
    icon: icon,
    semanticsLabel: title,
    svgSource: selected ? _centeredCoreArtworkSource : _normalArtworkSource,
    selected: selected,
    selectedTargetHandle: selected ? targetHandle : null,
    selectedLimitVisualListenable: selectedLimitVisualListenable,
    selectedLiveSelectionListenable: selectedLiveSelectionListenable,
    selectedLimitVisualForLiveSelection: selectedLimitVisualForLiveSelection,
    onSelectionVisualIdentityMismatch: onSelectionVisualIdentityMismatch,
  );
}

int _modulo(int value, int divisor) => ((value % divisor) + divisor) % divisor;
