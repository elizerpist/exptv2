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
import '../../application/dashboard_avatar_target_painted.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import 'budget_limit_quick_edit_gesture.dart';
import 'budget_target_avatar_interaction.dart';
import 'budget_target_avatar_preview_coalescer.dart';
import 'budget_target_avatar_rail_controller.dart';

/// Reports whether the production focus/visible-frame coordinator accepted
/// one exact Phase-A semantic/list frame for a discrete Avatar target. Rich
/// LogBox paint is deliberately not an admission condition for settlement.
typedef BudgetTargetAvatarPreviewAcceptance =
    Future<bool> Function(int targetHandle);

enum BudgetTargetAvatarMotionPhase {
  directDrag,
  ballistic,
  settling,
  interrupted,
}

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
    this.onTargetPreviewAccepted,
    this.onTargetSettled,
    this.onPreparedTargetHotsetRequested,
    this.liveTargetReadiness,
    this.liveTargetPainted,
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

  /// Production counterpart of [onTargetPreview]. It returns the Core's
  /// exact Phase-A publication decision so phase-specific diagnostics never
  /// mistake an emitted carousel callback for accepted visible data.
  final BudgetTargetAvatarPreviewAcceptance? onTargetPreviewAccepted;

  /// Settlement promotes the last already-visible prepared target. It must
  /// not manufacture a second query or the first matching LogBox frame.
  final ValueChanged<int>? onTargetSettled;

  /// Asks the coordinator to prepare a small stable semantic neighbourhood
  /// while the carousel is idle. This never changes the selected target.
  final ValueChanged<List<int>>? onPreparedTargetHotsetRequested;

  /// Rich resources are a bounded Phase-B enhancement. They are observed for
  /// diagnostics but never gate the rail's Phase-A semantic crossing.
  final ValueListenable<bool>? liveTargetReadiness;

  /// One Core-confirmed, identity-valid post-paint event. The rail observes
  /// this only to account for actual Phase-A/Phase-B paint in a flight report;
  /// it never uses it to choose, settle, or replace a target.
  final ValueListenable<DashboardAvatarTargetPainted?>? liveTargetPainted;

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
  BudgetTargetAvatarMotionPhase? _activeMotionPhase;
  int _motionGeneration = 0;
  int _motionSemanticCrossings = 0;
  int _motionPreviewPublications = 0;
  int _motionRawScrollUpdates = 0;
  int _directSemanticCrossings = 0;
  int _ballisticSemanticCrossings = 0;
  int _directPreviewRequests = 0;
  int _ballisticPreviewRequests = 0;
  int _directPreviewAccepted = 0;
  int _ballisticPreviewAccepted = 0;
  int _directPreviewRejected = 0;
  int _ballisticPreviewRejected = 0;
  int _directMatchingLogBoxPaints = 0;
  int _ballisticMatchingLogBoxPaints = 0;
  int _retainedExactPaints = 0;
  int _matchingRichPhaseBPaints = 0;
  int? _latestPaintedTargetHandle;
  int? _latestRichPaintedTargetHandle;
  _AvatarPreviewPaintExpectation? _pendingPaintExpectation;
  _AvatarTerminalPaintSummary? _pendingTerminalPaintSummary;
  int _stalePreviewCompletions = 0;
  int _untrackedPreviewCompletions = 0;
  int _settleVisualDeltaCount = 0;
  int? _latestSemanticTargetHandle;
  int? _pendingSettleTargetHandle;
  bool _terminalSettleAwaitingSemanticFrame = false;
  bool _settledTargetCommitted = false;
  final CenteredCarouselSemanticCadenceAccumulator _semanticCadence =
      CenteredCarouselSemanticCadenceAccumulator();

  @override
  void initState() {
    super.initState();
    _controller = CenteredCarouselController(initialIndex: 0);
    _controller.scrollController.addListener(_onRawScrollUpdate);
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
    widget.liveTargetPainted?.addListener(_onLiveTargetPainted);
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
    if (!identical(oldWidget.liveTargetPainted, widget.liveTargetPainted)) {
      oldWidget.liveTargetPainted?.removeListener(_onLiveTargetPainted);
      widget.liveTargetPainted?.addListener(_onLiveTargetPainted);
    }
  }

  @override
  void dispose() {
    if (_activeMotionOrigin != null) widget.onMotionActiveChanged?.call(false);
    widget.presentation.removeListener(_onPresentationChanged);
    widget.liveTargetPainted?.removeListener(_onLiveTargetPainted);
    widget.navigationController?.detach(this);
    _quickEdit?.dispose();
    _previewPublisher.dispose();
    _controller.scrollController.removeListener(_onRawScrollUpdate);
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
    if (_activeMotionOrigin != null) {
      _motionSemanticCrossings += 1;
      switch (_activeMotionPhase) {
        case BudgetTargetAvatarMotionPhase.directDrag:
          _directSemanticCrossings += 1;
        case BudgetTargetAvatarMotionPhase.ballistic:
          _ballisticSemanticCrossings += 1;
        case BudgetTargetAvatarMotionPhase.settling:
        case BudgetTargetAvatarMotionPhase.interrupted:
        case null:
          break;
      }
      _semanticCadence.recordTick(logicalIndex);
    }
    _previewPublisher.submit(
      _items[_modulo(logicalIndex, _items.length)].targetHandle,
    );
  }

  void _publishPreviewTargetHandle(int targetHandle) {
    if (!mounted) return;
    final phase = _activeMotionPhase;
    final generation = _motionGeneration;
    if (_activeMotionOrigin != null) {
      _motionPreviewPublications += 1;
      switch (phase) {
        case BudgetTargetAvatarMotionPhase.directDrag:
          _directPreviewRequests += 1;
        case BudgetTargetAvatarMotionPhase.ballistic:
          _ballisticPreviewRequests += 1;
        case BudgetTargetAvatarMotionPhase.settling:
        case BudgetTargetAvatarMotionPhase.interrupted:
        case null:
          break;
      }
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|PREVIEW_REQUESTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$generation phase=${phase?.name ?? 'idle'} '
            'targetHandle=$targetHandle',
      ),
    );
    widget.onTargetPreview?.call(targetHandle);
    final accepted = widget.onTargetPreviewAccepted;
    if (accepted == null) {
      _untrackedPreviewCompletions += 1;
      // Standalone/presentation-only users retain the historical synchronous
      // handoff. The production Dashboard supplies the typed callback below,
      // whose true result means an exact Phase-A frame was accepted.
      _markSemanticTargetAccepted(
        targetHandle: targetHandle,
        generation: generation,
      );
      return;
    }
    unawaited(
      _recordPreviewAcceptance(
        acceptance: accepted(targetHandle),
        targetHandle: targetHandle,
        generation: generation,
        phase: phase,
      ),
    );
  }

  Future<void> _recordPreviewAcceptance({
    required Future<bool> acceptance,
    required int targetHandle,
    required int generation,
    required BudgetTargetAvatarMotionPhase? phase,
  }) async {
    var accepted = false;
    Object? error;
    try {
      accepted = await acceptance;
    } on Object catch (caught) {
      error = caught;
    }
    if (!mounted || generation != _motionGeneration) {
      _stalePreviewCompletions += 1;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'AV|PREVIEW_COMPLETION_STALE',
          scope:
              'generation=$generation activeGeneration=$_motionGeneration '
              'phase=${phase?.name ?? 'idle'} targetHandle=$targetHandle',
        ),
      );
      return;
    }
    switch (phase) {
      case BudgetTargetAvatarMotionPhase.directDrag:
        if (accepted && error == null) {
          _directPreviewAccepted += 1;
        } else {
          _directPreviewRejected += 1;
        }
      case BudgetTargetAvatarMotionPhase.ballistic:
        if (accepted && error == null) {
          _ballisticPreviewAccepted += 1;
        } else {
          _ballisticPreviewRejected += 1;
        }
      case BudgetTargetAvatarMotionPhase.settling:
      case BudgetTargetAvatarMotionPhase.interrupted:
      case null:
        break;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: accepted && error == null
            ? 'AV|PREVIEW_ACCEPTED'
            : 'AV|PREVIEW_REJECTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$generation phase=${phase?.name ?? 'idle'} '
            'targetHandle=$targetHandle '
            'reason=${error == null ? (accepted ? 'acceptedExact' : 'coordinatorRejected') : 'exception'}',
      ),
    );
    if (accepted && error == null) {
      _pendingPaintExpectation = _AvatarPreviewPaintExpectation(
        targetHandle: targetHandle,
        generation: generation,
        phase: phase,
      );
      // Same-target raw re-entry may retain an exact Core-confirmed paint
      // while no new ValueNotifier change is necessary. Consume that bounded
      // metadata after the local expectation is armed; it remains accounting
      // only and cannot select or settle a target.
      _onLiveTargetPainted(retainedAtExpectation: true);
      _markSemanticTargetAccepted(
        targetHandle: targetHandle,
        generation: generation,
      );
    }
  }

  void _onLiveTargetPainted({bool retainedAtExpectation = false}) {
    final painted = widget.liveTargetPainted?.value;
    final expectation = _pendingPaintExpectation;
    if (painted == null ||
        expectation == null ||
        expectation.generation != _motionGeneration ||
        expectation.targetHandle != painted.targetHandle) {
      return;
    }
    // Core validates query/revision/presentation/frame identity before it
    // writes this metadata. Its newer-target path cancels the former waiter;
    // an immediate read is limited to a retained exact same-target paint.
    // Target plus the local flight generation remains the rail's bounded
    // correlation key.
    switch (expectation.phase) {
      case BudgetTargetAvatarMotionPhase.directDrag:
        if (retainedAtExpectation) {
          _retainedExactPaints += 1;
        } else {
          _directMatchingLogBoxPaints += 1;
        }
      case BudgetTargetAvatarMotionPhase.ballistic:
        if (retainedAtExpectation) {
          _retainedExactPaints += 1;
        } else {
          _ballisticMatchingLogBoxPaints += 1;
        }
      case BudgetTargetAvatarMotionPhase.settling:
      case BudgetTargetAvatarMotionPhase.interrupted:
      case null:
        return;
    }
    final terminalSummary = _pendingTerminalPaintSummary;
    _pendingPaintExpectation = null;
    _pendingTerminalPaintSummary = null;
    _latestPaintedTargetHandle = painted.targetHandle;
    if (painted.hasRichPhaseBPaint) {
      if (!retainedAtExpectation) _matchingRichPhaseBPaints += 1;
      _latestRichPaintedTargetHandle = painted.targetHandle;
    }
    final paintSource = retainedAtExpectation
        ? 'retainedExactPaint'
        : painted.hasRichPhaseBPaint
        ? 'richPhaseB'
        : 'preparedReadablePhaseA';
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|LOGBOX_TARGET_PAINT_ACCOUNTED',
        queryKey: painted.queryKey,
        coreRevision: painted.coreRevision,
        scope:
            'generation=${expectation.generation} '
            'phase=${expectation.phase!.name} '
            'targetHandle=${painted.targetHandle} '
            'focusGeneration=${painted.focusGeneration} '
            'presentationEpoch=${painted.presentationEpoch} '
            'frameGeneration=${painted.frameGeneration} '
            'readablePhaseARowsPainted=${painted.readablePhaseARowsPainted} '
            'richPhaseBRowsPainted=${painted.richPhaseBRowsPainted} '
            'source=$paintSource '
            'paintOccurrence=${retainedAtExpectation ? 'alreadyVisibleBeforeExpectation' : 'actualExtentAfterExpectation'}',
      ),
    );
    if (terminalSummary == null ||
        terminalSummary.generation != expectation.generation) {
      return;
    }
    _pendingTerminalPaintSummary = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_AVATAR_MOTION_PAINT_RECONCILED',
        queryKey: painted.queryKey,
        coreRevision: painted.coreRevision,
        scope:
            'generation=${terminalSummary.generation} '
            'origin=${terminalSummary.origin.name} '
            'terminalReason=${terminalSummary.terminalReason} '
            'phase=${expectation.phase!.name} '
            'targetHandle=${painted.targetHandle} '
            'matchingLogBoxPaints='
            '${_directMatchingLogBoxPaints + _ballisticMatchingLogBoxPaints} '
            'directMatchingLogBoxPaints=$_directMatchingLogBoxPaints '
            'ballisticMatchingLogBoxPaints=$_ballisticMatchingLogBoxPaints '
            'retainedExactPaints=$_retainedExactPaints '
            'richScenePainted=$_matchingRichPhaseBPaints '
            'source=$paintSource',
      ),
    );
  }

  void _markSemanticTargetAccepted({
    required int targetHandle,
    required int generation,
  }) {
    if (!mounted || generation != _motionGeneration) return;
    if (_activeMotionOrigin == null && !_terminalSettleAwaitingSemanticFrame) {
      return;
    }
    _latestSemanticTargetHandle = targetHandle;
    _tryCommitSettledExactTarget();
  }

  void _onMotionStarted(CenteredCarouselMotionOrigin origin) {
    _activeMotionOrigin = origin;
    _activeMotionPhase = BudgetTargetAvatarMotionPhase.directDrag;
    _motionGeneration += 1;
    _motionSemanticCrossings = 0;
    _motionPreviewPublications = 0;
    _motionRawScrollUpdates = 0;
    _directSemanticCrossings = 0;
    _ballisticSemanticCrossings = 0;
    _directPreviewRequests = 0;
    _ballisticPreviewRequests = 0;
    _directPreviewAccepted = 0;
    _ballisticPreviewAccepted = 0;
    _directPreviewRejected = 0;
    _ballisticPreviewRejected = 0;
    _directMatchingLogBoxPaints = 0;
    _ballisticMatchingLogBoxPaints = 0;
    _retainedExactPaints = 0;
    _matchingRichPhaseBPaints = 0;
    _latestPaintedTargetHandle = null;
    _latestRichPaintedTargetHandle = null;
    _pendingPaintExpectation = null;
    _pendingTerminalPaintSummary = null;
    _stalePreviewCompletions = 0;
    _untrackedPreviewCompletions = 0;
    _settleVisualDeltaCount = 0;
    _latestSemanticTargetHandle = null;
    _pendingSettleTargetHandle = null;
    _terminalSettleAwaitingSemanticFrame = false;
    _settledTargetCommitted = false;
    _semanticCadence.reset();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|FLING_STARTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$_motionGeneration phase=${_activeMotionPhase!.name} '
            'origin=${origin.name} selectedHandle=${widget.presentation.value.selectedHandle} '
            'controllerIdentity=${identityHashCode(_controller)} '
            'physicsCreationCount=${_controller.physicsCreationCount}',
      ),
    );
    widget.onMotionActiveChanged?.call(true);
  }

  void _onBallisticStarted(double velocity) {
    if (_activeMotionOrigin == null) return;
    _activeMotionPhase = BudgetTargetAvatarMotionPhase.ballistic;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|BALLISTIC_STARTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$_motionGeneration velocity=${velocity.round()} '
            'selectedHandle=${widget.presentation.value.selectedHandle} '
            'controllerIdentity=${identityHashCode(_controller)}',
      ),
    );
  }

  void _onMotionInterrupted() {
    final origin = _activeMotionOrigin;
    if (origin == null) return;
    _activeMotionPhase = BudgetTargetAvatarMotionPhase.interrupted;
    _terminalSettleAwaitingSemanticFrame = false;
    _pendingSettleTargetHandle = null;
    _latestSemanticTargetHandle = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|MOTION_INTERRUPTED_BY_NEW_POINTER',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$_motionGeneration origin=${origin.name} '
            'controllerIdentity=${identityHashCode(_controller)}',
      ),
    );
    _activeMotionOrigin = null;
    widget.onMotionActiveChanged?.call(false);
    _recordMotionSummary(origin, terminalReason: 'interruptedByNewPointer');
  }

  // Settlement promotes the final target only after its exact Phase-A
  // semantic/list frame was accepted. Rich paint may finish later and never
  // decides which Avatar wins pointer-up.
  void _onSelectionSettled(int logicalIndex) {
    final origin = _activeMotionOrigin;
    _activeMotionPhase = BudgetTargetAvatarMotionPhase.settling;
    _activeMotionOrigin = null;
    if (origin != null) widget.onMotionActiveChanged?.call(false);
    final settledTargetHandle = _items.isEmpty
        ? null
        : _items[_modulo(logicalIndex, _items.length)].targetHandle;
    final explicitTargetIntent =
        widget.navigationController?.isExplicitTargetIntentInFlight ?? false;
    _pendingSettleTargetHandle = origin == null || explicitTargetIntent
        ? null
        : settledTargetHandle;
    _terminalSettleAwaitingSemanticFrame = _pendingSettleTargetHandle != null;
    if (widget.onTargetPreviewAccepted == null &&
        _pendingSettleTargetHandle != null) {
      // Presentation-only consumers have no Core acknowledgement seam. Keep
      // their existing immediate settled handoff without weakening the real
      // Dashboard path, which always supplies [onTargetPreviewAccepted].
      _latestSemanticTargetHandle = _pendingSettleTargetHandle;
    }
    if (origin != null) {
      _recordMotionSummary(origin, terminalReason: 'settled');
    }
    if (origin != null && _items.isNotEmpty) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'AV|FLING_SETTLED',
          direction: widget.presentation.value.liveSelection.direction.name,
          coreRevision: widget.presentation.value.liveSelection.coreRevision,
          scope:
              'origin=${origin.name} settledLogicalIndex=$logicalIndex '
              'generation=$_motionGeneration phase=${_activeMotionPhase!.name} '
              'settledTargetHandle=${_items[_modulo(logicalIndex, _items.length)].targetHandle} '
              'crossingCount=$_motionSemanticCrossings '
              'previewCount=$_motionPreviewPublications',
        ),
      );
    }
    _requestPreparedTargetHotset(centerLogicalIndex: logicalIndex);
    _tryCommitSettledExactTarget();
  }

  void _tryCommitSettledExactTarget() {
    final settledTargetHandle = _pendingSettleTargetHandle;
    if (settledTargetHandle == null || _settledTargetCommitted) return;
    if (_latestSemanticTargetHandle != settledTargetHandle) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'AV|FLING_SETTLE_AWAITING_SEMANTIC_FRAME',
          direction: widget.presentation.value.liveSelection.direction.name,
          coreRevision: widget.presentation.value.liveSelection.coreRevision,
          scope:
              'generation=$_motionGeneration settledTargetHandle='
              '$settledTargetHandle latestSemanticTargetHandle='
              '${_latestSemanticTargetHandle ?? '-'}',
        ),
      );
      return;
    }
    _settledTargetCommitted = true;
    _terminalSettleAwaitingSemanticFrame = false;
    widget.onTargetSettled?.call(settledTargetHandle);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|FLING_SETTLED_AFTER_SEMANTIC_FRAME',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'generation=$_motionGeneration settledTargetHandle='
            '$settledTargetHandle settleVisualDeltaCount='
            '$_settleVisualDeltaCount',
      ),
    );
  }

  void _recordMotionSummary(
    CenteredCarouselMotionOrigin origin, {
    required String terminalReason,
  }) {
    final positionIdentity = _controller.scrollController.hasClients
        ? identityHashCode(_controller.scrollController.position)
        : 0;
    final cadence = _semanticCadence.snapshot();
    final pendingPaint = _pendingPaintExpectation;
    final awaitingExactPaint =
        pendingPaint?.generation == _motionGeneration &&
        pendingPaint?.phase != null;
    _pendingTerminalPaintSummary = awaitingExactPaint
        ? _AvatarTerminalPaintSummary(
            generation: _motionGeneration,
            origin: origin,
            terminalReason: terminalReason,
          )
        : null;
    final paintAccountingState = awaitingExactPaint
        ? 'awaitingExactPaint'
        : (_directMatchingLogBoxPaints + _ballisticMatchingLogBoxPaints > 0
              ? 'accounted'
              : _retainedExactPaints > 0
              ? 'retainedExactPaintAlreadyVisible'
              : 'noAcceptedPaintExpected');
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_AVATAR_MOTION_SUMMARY',
        scope:
            'generation=$_motionGeneration origin=${origin.name} '
            'terminalReason=$terminalReason '
            'avatarSemanticCrossings=$_motionSemanticCrossings '
            'avatarPreviewPublishes=$_motionPreviewPublications '
            'directSemanticCrossings=$_directSemanticCrossings '
            'ballisticSemanticCrossings=$_ballisticSemanticCrossings '
            'directPreviewRequests=$_directPreviewRequests '
            'ballisticPreviewRequests=$_ballisticPreviewRequests '
            'directPreviewAccepted=$_directPreviewAccepted '
            'ballisticPreviewAccepted=$_ballisticPreviewAccepted '
            'directPreviewRejected=$_directPreviewRejected '
            'ballisticPreviewRejected=$_ballisticPreviewRejected '
            'directMatchingLogBoxPaints=$_directMatchingLogBoxPaints '
            'ballisticMatchingLogBoxPaints=$_ballisticMatchingLogBoxPaints '
            'retainedExactPaints=$_retainedExactPaints '
            'visibleExactPaints=${_directMatchingLogBoxPaints + _ballisticMatchingLogBoxPaints + _retainedExactPaints} '
            'paintAccountingState=$paintAccountingState '
            'pendingPaintTargetHandle='
            '${awaitingExactPaint ? pendingPaint!.targetHandle : '-'} '
            'pendingPaintPhase='
            '${awaitingExactPaint ? pendingPaint!.phase!.name : '-'} '
            'stalePreviewCompletions=$_stalePreviewCompletions '
            'untrackedPreviewCompletions=$_untrackedPreviewCompletions '
            'latestSemanticTargetHandle='
            '${_latestSemanticTargetHandle ?? '-'} '
            'latestPaintedTargetHandle=${_latestPaintedTargetHandle ?? '-'} '
            'latestRichPaintedTargetHandle='
            '${_latestRichPaintedTargetHandle ?? '-'} '
            'settleTargetHandle=${_pendingSettleTargetHandle ?? '-'} '
            'rawScrollUpdates=$_motionRawScrollUpdates '
            'firstTickMicros=${cadence.firstTickLatencyMicros} '
            'interTickMinMicros=${cadence.interTickMinimumMicros} '
            'interTickMedianMicros=${cadence.interTickMedianMicros} '
            'interTickP95Micros=${cadence.interTickP95Micros} '
            'interTickMaxMicros=${cadence.interTickMaximumMicros} '
            'longGapCount=${cadence.longGapCount} '
            'duplicateTickCount=${cadence.duplicateTickCount} '
            'skippedSemanticIndexCount=${cadence.skippedSemanticIndexCount} '
            'acceptedLiveSnapshots=${_directPreviewAccepted + _ballisticPreviewAccepted} '
            'semanticFrameAccepted=${_directPreviewAccepted + _ballisticPreviewAccepted} '
            'richScenePainted=$_matchingRichPhaseBPaints '
            'completeLivePublications=${_directPreviewAccepted + _ballisticPreviewAccepted} '
            'sameVsyncCoalescedTickCount=${_motionSemanticCrossings - _motionPreviewPublications} '
            'repositoryRequestsAtTicks=0 indexBuildsAtTicks=0 '
            'scenePreparesAtTicks=0 canonicalPersistenceCommitsAtTicks=0 '
            'canonicalFocusCommitsAtSettle=0 '
            'settleVisualDeltaCount=$_settleVisualDeltaCount '
            'partitionRetainedFromPreviousTarget=false '
            'controllerIdentity=${identityHashCode(_controller)} '
            'scrollPositionIdentity=$positionIdentity '
            'physicsCreationCount=${_controller.physicsCreationCount} '
            'headerPalettePath=discretePreparedPreview '
            'source=preparedCatalog',
      ),
    );
  }

  void _onRawScrollUpdate() {
    if (_activeMotionOrigin != null) _motionRawScrollUpdates += 1;
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
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: const ValueKey('budget-target-avatar-rail'),
      child: _items.isEmpty
          ? const SizedBox.shrink()
          : RepaintBoundary(
              child: CenteredCarousel<_PreparedBudgetTargetAvatar>(
                key: const ValueKey('budget-target-avatar-carousel'),
                dataSource:
                    CyclicCarouselDataSource<_PreparedBudgetTargetAvatar>(
                      _items,
                    ),
                controller: _controller,
                spec: _spec,
                height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
                semanticsLabelBuilder: (item) => item.title,
                onPreviewChanged: _onPreviewChanged,
                onDirectPointerDown: _onDirectPointerDown,
                onSelectionSettled: _onSelectionSettled,
                onMotionStarted: _onMotionStarted,
                onBallisticStarted: _onBallisticStarted,
                onMotionInterrupted: _onMotionInterrupted,
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
                            _quickEdit?.longPressEnded() ??
                                Future<void>.value(),
                          )
                        : null,
                    onLongPressCancel: metrics.isSelected && _quickEdit != null
                        ? () => unawaited(
                            _quickEdit?.longPressEnded() ??
                                Future<void>.value(),
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
  }

  void _onDirectPointerDown() {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|POINTER_ACCEPTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'liveRootReady=${widget.liveTargetReadiness?.value ?? true} '
            'motionActive=${_activeMotionOrigin != null} '
            'controllerIdentity=${identityHashCode(_controller)} '
            'physicsCreationCount=${_controller.physicsCreationCount}',
      ),
    );
    widget.onDirectInputStarted?.call();
  }

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

final class _AvatarPreviewPaintExpectation {
  const _AvatarPreviewPaintExpectation({
    required this.targetHandle,
    required this.generation,
    required this.phase,
  });

  final int targetHandle;
  final int generation;
  final BudgetTargetAvatarMotionPhase? phase;
}

final class _AvatarTerminalPaintSummary {
  const _AvatarTerminalPaintSummary({
    required this.generation,
    required this.origin,
    required this.terminalReason,
  });

  final int generation;
  final CenteredCarouselMotionOrigin origin;
  final String terminalReason;
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
