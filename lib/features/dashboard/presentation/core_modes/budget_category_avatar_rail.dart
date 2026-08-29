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
import 'budget_target_avatar_preview_coalescer.dart';
import 'budget_target_avatar_rail_controller.dart';

/// Budget card1's presentation-only five-position target rail. Aggregate and
/// real-category targets share the same prepared motion/render path; the
/// parent semantic-commit coordinator owns their visible selection.
class BudgetTargetAvatarRail extends StatefulWidget {
  const BudgetTargetAvatarRail({
    super.key,
    required this.presentation,
    this.limitEditController,
    this.navigationController,
    this.onTargetPreview,
    this.onTargetSettled,
    this.onPreparedTargetHotsetRequested,
    this.onDirectInputStarted,
    this.onMotionActiveChanged,
  });

  final DashboardBudgetPresentationController presentation;
  final DashboardBudgetLimitEditController? limitEditController;
  final BudgetTargetAvatarRailController? navigationController;

  /// One semantic carousel crossing on its direct prepared preview lane.
  /// Consumers may publish the corresponding prepared visible frame, but must
  /// use their existing stale generation gate rather than perform pixel-rate
  /// data work here.
  final ValueChanged<int>? onTargetPreview;

  /// A committed consumer, such as the LogBox focus/query bridge. This is
  /// intentionally separate from [onTargetPreview]: settlement promotes the
  /// last accepted prepared target and must not manufacture a second query.
  final ValueChanged<int>? onTargetSettled;

  /// Asks the coordinator to prepare a small stable semantic neighbourhood
  /// while the carousel is idle. This never changes the selected target.
  final ValueChanged<List<int>>? onPreparedTargetHotsetRequested;

  /// Raw Avatar contact gets the same input-priority boundary as the visual
  /// rail, but does not itself claim a motion lane. A tap/cancel must not
  /// become a global motion lock before the carousel recognizer starts.
  final VoidCallback? onDirectInputStarted;

  /// The one Core-owned foreground work gate for physical avatar motion.
  /// The rail remains the only gesture/carousel owner.
  final ValueChanged<bool>? onMotionActiveChanged;

  /// The selected shell is larger than the static avatar canvas. This is the
  /// rail's vertical input/layout surface; horizontal slots remain [_itemExtent].
  static const selectedInputSurfaceHeight =
      BudgetCategoryAvatarGeometry.selectionShellVisualDiameter;
  static const selectedInputVerticalOverflow =
      (selectedInputSurfaceHeight -
          BudgetCategoryAvatarGeometry.avatarCanvasSize) /
      2;

  @override
  State<BudgetTargetAvatarRail> createState() => _BudgetTargetAvatarRailState();
}

class _BudgetTargetAvatarRailState extends State<BudgetTargetAvatarRail>
    implements BudgetTargetAvatarRailCommandDelegate {
  static const _itemExtent = 58.0;

  late final CenteredCarouselController _controller;
  late final CenteredCarouselSpec _spec;
  List<_PreparedBudgetTargetAvatar> _items =
      const <_PreparedBudgetTargetAvatar>[];
  int? _lastProgressIdentityMismatchSignature;
  BudgetLimitQuickEditGestureController? _quickEdit;
  late final BudgetTargetAvatarPreviewPublisher _previewPublisher;
  CenteredCarouselMotionOrigin? _activeMotionOrigin;
  int _motionSemanticCrossings = 0;
  int _motionPreviewPublications = 0;

  @override
  void initState() {
    super.initState();
    _controller = CenteredCarouselController(initialIndex: 0);
    _spec = CenteredCarouselPresets.budgetCategoryAvatarRail(
      itemExtent: _itemExtent,
    );
    _previewPublisher = BudgetTargetAvatarPreviewPublisher(
      onPublish: _publishPreviewTargetHandle,
    );
    _quickEdit = _createQuickEditController();
    _replaceItems(widget.presentation.value.items, initial: true);
    _requestPreparedTargetHotset();
    widget.presentation.addListener(_onPresentationChanged);
    widget.navigationController?.attach(this);
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
    if (!identical(
      oldWidget.navigationController,
      widget.navigationController,
    )) {
      oldWidget.navigationController?.detach(this);
      widget.navigationController?.attach(this);
    }
  }

  @override
  void dispose() {
    if (_activeMotionOrigin != null) widget.onMotionActiveChanged?.call(false);
    widget.presentation.removeListener(_onPresentationChanged);
    widget.navigationController?.detach(this);
    _quickEdit?.dispose();
    _previewPublisher.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPresentationChanged() {
    if (_replaceItems(widget.presentation.value.items) && mounted) {
      _requestPreparedTargetHotset();
      setState(() {});
    }
  }

  BudgetLimitQuickEditGestureController? _createQuickEditController() {
    final edits = widget.limitEditController;
    if (edits == null) return null;
    return BudgetLimitQuickEditGestureController(
      edits: edits,
      contextForCurrentSelection: () {
        final context = widget.presentation.directInputEditContext();
        if (context == null) {
          throw StateError(
            'A canonical selected Budget target and scope are required to edit.',
          );
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
    if (_activeMotionOrigin != null) _motionSemanticCrossings += 1;
    _previewPublisher.submit(
      _items[_modulo(logicalIndex, _items.length)].targetHandle,
    );
  }

  void _publishPreviewTargetHandle(int targetHandle) {
    if (!mounted) return;
    if (_activeMotionOrigin != null) _motionPreviewPublications += 1;
    widget.onTargetPreview?.call(targetHandle);
  }

  void _onMotionStarted(CenteredCarouselMotionOrigin origin) {
    _activeMotionOrigin = origin;
    _motionSemanticCrossings = 0;
    _motionPreviewPublications = 0;
    widget.onMotionActiveChanged?.call(true);
  }

  // The final visual target is flushed at settlement. Only a user-owned
  // settled motion may enter a committed data bridge; programmatic target
  // intents retain their existing explicit command seam.
  void _onSelectionSettled(int logicalIndex) {
    final origin = _activeMotionOrigin;
    _activeMotionOrigin = null;
    if (origin != null) widget.onMotionActiveChanged?.call(false);
    if (origin != null) _recordMotionSummary(origin);
    _requestPreparedTargetHotset(centerLogicalIndex: logicalIndex);
    // A direct avatar tap is programmatic physical motion but still a user
    // semantic intent, so it commits after settle. Pie/list commands are
    // already committed by [BudgetTargetAvatarRailController] after its
    // awaited explicit command completes; do not duplicate that focus/query.
    if (origin != null &&
        !(widget.navigationController?.isExplicitTargetIntentInFlight ??
            false)) {
      widget.onTargetSettled?.call(
        _items[_modulo(logicalIndex, _items.length)].targetHandle,
      );
    }
  }

  void _recordMotionSummary(CenteredCarouselMotionOrigin origin) {
    final positionIdentity = _controller.scrollController.hasClients
        ? identityHashCode(_controller.scrollController.position)
        : 0;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_AVATAR_MOTION_SUMMARY',
        scope:
            'origin=${origin.name} '
            'avatarSemanticCrossings=$_motionSemanticCrossings '
            'avatarPreviewPublishes=$_motionPreviewPublications '
            'preparedFocusRequestsAtTicks=$_motionPreviewPublications '
            'controllerIdentity=${identityHashCode(_controller)} '
            'scrollPositionIdentity=$positionIdentity '
            'physicsCreationCount=${_controller.physicsCreationCount} '
            'headerPalettePath=discretePreparedPreview '
            'source=preparedCatalog',
      ),
    );
  }

  void _requestPreparedTargetHotset({int? centerLogicalIndex}) {
    if (_items.isEmpty) return;
    final callback = widget.onPreparedTargetHotsetRequested;
    if (callback == null) return;
    final center = centerLogicalIndex ?? _controller.selectedLogicalIndex;
    final handles = <int>[];
    final seen = <int>{};
    // 0, -1, +1, -2, +2 ... keeps physical neighbours first while covering
    // the largest supported eight-crossing fling in either direction.
    for (
      var distance = 0;
      distance <= 8 && handles.length < _items.length;
      distance += 1
    ) {
      for (final offset
          in distance == 0 ? const <int>[0] : <int>[-distance, distance]) {
        final handle =
            _items[_modulo(center + offset, _items.length)].targetHandle;
        if (seen.add(handle)) handles.add(handle);
      }
    }
    callback(List<int>.unmodifiable(handles));
  }

  @override
  int get logicalIndex => _controller.selectedLogicalIndex;

  @override
  int get targetCount => _items.length;

  @override
  Future<void> animateToLogicalIndex(int logicalIndex) =>
      _controller.animateToIndex(logicalIndex);

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
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              semanticsLabelBuilder: (item) => item.title,
              onPreviewChanged: _onPreviewChanged,
              onDirectPointerDown: widget.onDirectInputStarted,
              onSelectionSettled: _onSelectionSettled,
              onMotionStarted: _onMotionStarted,
              itemBuilder: (context, item, metrics) {
                final avatar = SizedBox.square(
                  dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
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
                );
                final interaction = BudgetTargetAvatarInteraction(
                  onPointerDown: metrics.isSelected && _quickEdit != null
                      ? () => _recordQuickEditPointerDown(item.targetHandle)
                      : null,
                  onLongPressStart: metrics.isSelected && _quickEdit != null
                      ? (details) => _quickEdit?.longPressStarted(
                          globalY: details.globalPosition.dy,
                        )
                      : null,
                  onLongPressMoveUpdate:
                      metrics.isSelected && _quickEdit != null
                      ? (details) => _quickEdit?.longPressMoved(
                          globalY: details.globalPosition.dy,
                        )
                      : null,
                  onLongPressEnd: metrics.isSelected && _quickEdit != null
                      ? (_) => unawaited(
                          _quickEdit?.longPressEnded() ?? Future<void>.value(),
                        )
                      : null,
                  onLongPressCancel: metrics.isSelected && _quickEdit != null
                      ? () => unawaited(
                          _quickEdit?.longPressEnded() ?? Future<void>.value(),
                        )
                      : null,
                  child: metrics.isSelected ? Center(child: avatar) : avatar,
                );
                return metrics.isSelected
                    ? SizedBox(
                        height:
                            BudgetTargetAvatarRail.selectedInputSurfaceHeight,
                        child: interaction,
                      )
                    : interaction;
              },
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

  /// One bounded event proves that the selected Avatar remained the raw
  /// hit-test owner even if a later prepared Header projection is absent. The
  /// actual GestureArena outcome is represented by the following long-press
  /// start/acceptance events in [BudgetLimitQuickEditGestureController].
  void _recordQuickEditPointerDown(int targetHandle) {
    final context = widget.presentation.directInputEditContext();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_LIMIT_EDIT_POINTER_DOWN',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'hitTargetHandle=$targetHandle '
            'selectedHandle=${widget.presentation.value.selectedHandle} '
            'editContextResolved=${context != null} '
            'headerAvailable=${widget.presentation.value.header.editContext != null}',
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
  final String _centeredShadowedArtworkSource;

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
    svgSource: _normalArtworkSource,
    centeredCoreSvgSource: _centeredCoreArtworkSource,
    centeredShadowedSvgSource: _centeredShadowedArtworkSource,
    selected: selected,
    selectedTargetHandle: selected ? targetHandle : null,
    selectedLimitVisualListenable: selectedLimitVisualListenable,
    selectedLiveSelectionListenable: selectedLiveSelectionListenable,
    selectedLimitVisualForLiveSelection: selectedLimitVisualForLiveSelection,
    onSelectionVisualIdentityMismatch: onSelectionVisualIdentityMismatch,
  );
}

int _modulo(int value, int divisor) => ((value % divisor) + divisor) % divisor;
