import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_key_digest.dart';
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
  // The human-diagnostic profile opts in with the dart define below; debug
  // tests also exercise the bounded evidence path. A normal release carries
  // neither a FrameTiming callback nor diagnostic buffers/timestamps on the
  // Avatar hot path.
  static const _collectFrameTimingDiagnostics =
      bool.fromEnvironment('FLUVI_PHYSICAL_RAIL_DIAGNOSTICS') || kDebugMode;
  static const _targetTimingStampCapacity = 16;

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
  int _budgetProgressPaintedCount = 0;
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
  final CenteredCarouselFrameTimingAccumulator? _frameTimings =
      _collectFrameTimingDiagnostics
      ? CenteredCarouselFrameTimingAccumulator()
      : null;
  final CenteredCarouselLatencyDistributionAccumulator? _rawToSemanticLatency =
      _collectFrameTimingDiagnostics
      ? CenteredCarouselLatencyDistributionAccumulator()
      : null;
  final CenteredCarouselLatencyDistributionAccumulator?
  _semanticToStoreLatency = _collectFrameTimingDiagnostics
      ? CenteredCarouselLatencyDistributionAccumulator()
      : null;
  final CenteredCarouselLatencyDistributionAccumulator? _storeToPaintLatency =
      _collectFrameTimingDiagnostics
      ? CenteredCarouselLatencyDistributionAccumulator()
      : null;
  final CenteredCarouselLatencyDistributionAccumulator?
  _acknowledgedFrameToRasterLatency = _collectFrameTimingDiagnostics
      ? CenteredCarouselLatencyDistributionAccumulator()
      : null;
  final CenteredCarouselLatencyDistributionAccumulator?
  _budgetProgressPaintToRasterLatency = _collectFrameTimingDiagnostics
      ? CenteredCarouselLatencyDistributionAccumulator()
      : null;
  final Map<int, int>? _semanticTargetMicros = _collectFrameTimingDiagnostics
      ? <int, int>{}
      : null;
  final Map<int, int>? _acceptedTargetMicros = _collectFrameTimingDiagnostics
      ? <int, int>{}
      : null;
  TimingsCallback? _frameTimingsCallback;
  int? _lastRawScrollMicros;
  int? _awaitingPaintFrameVsyncMicros;
  _BudgetProgressPaintExpectation? _awaitingBudgetProgressRaster;
  int? _lastBudgetProgressBuildSignature;
  int? _lastBudgetProgressPaintSignature;
  int? _lastBudgetProgressStaleSignature;
  int _motionAvatarRailBuilds = 0;
  _AvatarFirstTargetPipeline? _firstTargetPipeline;

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
    if (_collectFrameTimingDiagnostics) {
      _frameTimingsCallback = _onFrameTimings;
      SchedulerBinding.instance.addTimingsCallback(_frameTimingsCallback!);
    }
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
    final timingsCallback = _frameTimingsCallback;
    if (timingsCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(timingsCallback);
    }
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
    final targetHandle =
        _items[_modulo(logicalIndex, _items.length)].targetHandle;
    _recordFirstAvatarSemanticCrossing(targetHandle);
    if (_activeMotionOrigin != null) {
      if (_collectFrameTimingDiagnostics) {
        final now = developer.Timeline.now;
        final rawScrollMicros = _lastRawScrollMicros;
        if (rawScrollMicros != null) {
          _rawToSemanticLatency!.record(now - rawScrollMicros);
        }
        _recordTargetTimestamp(_semanticTargetMicros!, targetHandle, now);
      }
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
    _previewPublisher.submit(targetHandle);
  }

  /// Records only the first discrete boundary after a physical Avatar pointer.
  /// The generic carousel remains the sole geometry/gesture authority; this
  /// is a bounded diagnostic correlation record for splitting first-feedback
  /// latency from later ballistic crossings.
  void _recordFirstAvatarSemanticCrossing(int targetHandle) {
    if (!_collectFrameTimingDiagnostics) return;
    final pipeline = _firstTargetPipeline;
    if (pipeline == null || pipeline.motionGeneration != _motionGeneration) {
      return;
    }
    final firstTargetHandle = pipeline.targetHandle;
    if (firstTargetHandle != null && firstTargetHandle != targetHandle) {
      _emitFirstTargetPipelineSummary(
        pipeline,
        terminalOutcome: pipeline.exactPhaseAStoreMicros == null
            ? 'coalescedBeforeReadiness'
            : 'coalescedBeforePaint',
      );
      return;
    }
    if (firstTargetHandle != null) return;
    pipeline.targetHandle = targetHandle;
    pipeline.firstSemanticMicros = developer.Timeline.now;
  }

  void _publishPreviewTargetHandle(int targetHandle) {
    if (!mounted) return;
    final phase = _activeMotionPhase;
    final generation = _motionGeneration;
    final firstTargetPipeline = _firstTargetPipeline;
    if (firstTargetPipeline?.motionGeneration == generation &&
        firstTargetPipeline?.targetHandle == targetHandle &&
        firstTargetPipeline?.previewRequestedMicros == null) {
      firstTargetPipeline!.previewRequestedMicros = developer.Timeline.now;
    }
    final semanticCrossedAtMicros = _collectFrameTimingDiagnostics
        ? _semanticTargetMicros![targetHandle]
        : null;
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
        semanticCrossedAtMicros: semanticCrossedAtMicros,
      ),
    );
  }

  Future<void> _recordPreviewAcceptance({
    required Future<bool> acceptance,
    required int targetHandle,
    required int generation,
    required BudgetTargetAvatarMotionPhase? phase,
    required int? semanticCrossedAtMicros,
  }) async {
    var accepted = false;
    Object? error;
    StackTrace? errorStackTrace;
    try {
      accepted = await acceptance;
    } on Object catch (caught, stackTrace) {
      error = caught;
      errorStackTrace = stackTrace;
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
    if (error != null) {
      final selection = widget.presentation.value.liveSelection;
      // The Core logs the full temporal/base identity at its own failure
      // boundary. This presentation seam adds only its local, bounded source
      // evidence; neither raw error text nor a full stack is exported.
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'AVATAR_PHASE_A_ADMISSION_EXCEPTION',
          direction: selection.direction.name,
          coreRevision: selection.coreRevision,
          scope:
              'boundary=onTargetPreviewAccepted '
              'errorType=${error.runtimeType} '
              'errorDigest=${FluviDiagnosticKeyDigest.of(error.toString())} '
              'stackFingerprint=${FluviDiagnosticKeyDigest.of(errorStackTrace.toString())} '
              'targetHandle=$targetHandle '
              'presentationTargetHandle=${selection.target.handle} '
              'presentationEpoch=${widget.presentation.value.visibleModeEpoch} '
              'analysisScopeDigest=${FluviDiagnosticKeyDigest.of(selection.analysisScopeLabel)} '
              'coreRevision=${selection.coreRevision ?? 0} '
              'motionGeneration=$generation '
              'phase=${phase?.name ?? 'idle'}',
        ),
      );
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
            'reason=${error == null ? (accepted ? 'acceptedExact' : 'previewNotPainted') : 'exception'}',
      ),
    );
    final firstTargetPipeline = _firstTargetPipeline;
    if (firstTargetPipeline?.motionGeneration == generation &&
        firstTargetPipeline?.targetHandle == targetHandle) {
      if (accepted && error == null) {
        firstTargetPipeline!.exactPhaseAStoreMicros = developer.Timeline.now;
      } else {
        _emitFirstTargetPipelineSummary(
          firstTargetPipeline!,
          terminalOutcome: error == null
              ? 'staleRejected'
              : 'exactPhaseAAdmissionException',
        );
      }
    }
    if (accepted && error == null) {
      if (_collectFrameTimingDiagnostics) {
        final acceptedAtMicros = developer.Timeline.now;
        if (semanticCrossedAtMicros != null) {
          _semanticToStoreLatency!.record(
            acceptedAtMicros - semanticCrossedAtMicros,
          );
        }
        _recordTargetTimestamp(
          _acceptedTargetMicros!,
          targetHandle,
          acceptedAtMicros,
        );
      }
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
    if (!retainedAtExpectation && _collectFrameTimingDiagnostics) {
      final acceptedAtMicros = _acceptedTargetMicros!.remove(
        painted.targetHandle,
      );
      if (acceptedAtMicros != null) {
        _storeToPaintLatency!.record(developer.Timeline.now - acceptedAtMicros);
      }
      // A frame timing callback supplies the engine's raster-finish timestamp.
      // Keep the raw vsync timestamp rather than a wall clock so the two
      // values share Flutter's engine-time epoch. The result is an upper bound
      // from the acknowledged paint frame to raster completion, not a claim
      // that a semantic crossing itself was rendered in that frame.
      _awaitingPaintFrameVsyncMicros =
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    }
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
    final firstTargetPipeline = _firstTargetPipeline;
    if (!retainedAtExpectation &&
        _collectFrameTimingDiagnostics &&
        firstTargetPipeline?.motionGeneration == expectation.generation &&
        firstTargetPipeline?.targetHandle == painted.targetHandle) {
      firstTargetPipeline!.logBoxPaintMicros = developer.Timeline.now;
      firstTargetPipeline.logBoxPaintVsyncMicros =
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
      _emitFirstTargetPipelineSummary(
        firstTargetPipeline,
        terminalOutcome: painted.exactEmpty
            ? 'exactEmpty'
            : 'exactPhaseAPainted',
      );
    }
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
    final firstTargetPipeline = _firstTargetPipeline;
    if (_collectFrameTimingDiagnostics &&
        origin == CenteredCarouselMotionOrigin.userDrag &&
        firstTargetPipeline != null &&
        firstTargetPipeline.motionGeneration == null) {
      firstTargetPipeline.motionGeneration = _motionGeneration;
      firstTargetPipeline.recognizerOwnedMicros = developer.Timeline.now;
    }
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
    _budgetProgressPaintedCount = 0;
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
    if (_collectFrameTimingDiagnostics) {
      _frameTimings!.reset();
      _rawToSemanticLatency!.reset();
      _semanticToStoreLatency!.reset();
      _storeToPaintLatency!.reset();
      _acknowledgedFrameToRasterLatency!.reset();
      _budgetProgressPaintToRasterLatency!.reset();
      _semanticTargetMicros!.clear();
      _acceptedTargetMicros!.clear();
      _lastRawScrollMicros = null;
      _awaitingPaintFrameVsyncMicros = null;
      _awaitingBudgetProgressRaster = null;
      _lastBudgetProgressBuildSignature = null;
      _lastBudgetProgressPaintSignature = null;
      _lastBudgetProgressStaleSignature = null;
      _motionAvatarRailBuilds = 0;
    }
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
    final timingDiagnostics = _collectFrameTimingDiagnostics;
    final frameTimings = timingDiagnostics ? _frameTimings!.snapshot() : null;
    final rawToSemantic = timingDiagnostics
        ? _rawToSemanticLatency!.snapshot()
        : null;
    final semanticToStore = timingDiagnostics
        ? _semanticToStoreLatency!.snapshot()
        : null;
    final storeToPaint = timingDiagnostics
        ? _storeToPaintLatency!.snapshot()
        : null;
    final acknowledgedFrameToRaster = timingDiagnostics
        ? _acknowledgedFrameToRasterLatency!.snapshot()
        : null;
    final budgetProgressPaintToRaster = timingDiagnostics
        ? _budgetProgressPaintToRasterLatency!.snapshot()
        : null;
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
            'avatarRailBuilds=${timingDiagnostics ? _motionAvatarRailBuilds : -1} '
            'frameTimingSamples=${frameTimings?.retainedFrameCount ?? -1} '
            'frameTimingDroppedSamples=${frameTimings?.droppedFrameCount ?? -1} '
            'frameTimingMissedFrames=${frameTimings?.missedFrameCount ?? -1} '
            'frameTimingBuildP50Micros=${frameTimings?.buildP50Micros ?? -1} '
            'frameTimingBuildP95Micros=${frameTimings?.buildP95Micros ?? -1} '
            'frameTimingBuildMaxMicros=${frameTimings?.buildMaximumMicros ?? -1} '
            'frameTimingRasterP50Micros=${frameTimings?.rasterP50Micros ?? -1} '
            'frameTimingRasterP95Micros=${frameTimings?.rasterP95Micros ?? -1} '
            'frameTimingRasterMaxMicros=${frameTimings?.rasterMaximumMicros ?? -1} '
            'frameTimingTotalSpanP50Micros=${frameTimings?.totalSpanP50Micros ?? -1} '
            'frameTimingTotalSpanP95Micros=${frameTimings?.totalSpanP95Micros ?? -1} '
            'frameTimingTotalSpanMaxMicros=${frameTimings?.totalSpanMaximumMicros ?? -1} '
            'rawToSemanticP95Micros=${rawToSemantic?.p95Micros ?? -1} '
            'semanticToStoreP95Micros=${semanticToStore?.p95Micros ?? -1} '
            'storeToPaintP95Micros=${storeToPaint?.p95Micros ?? -1} '
            'acknowledgedFrameToRasterP95Micros='
            '${acknowledgedFrameToRaster?.p95Micros ?? -1} '
            'budgetProgressPainted=$_budgetProgressPaintedCount '
            'budgetProgressPaintToRasterP95Micros='
            '${budgetProgressPaintToRaster?.p95Micros ?? -1} '
            'frameTimingDiagnostics=$timingDiagnostics '
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
    if (_activeMotionOrigin != null) {
      _motionRawScrollUpdates += 1;
      if (_collectFrameTimingDiagnostics) {
        final now = developer.Timeline.now;
        _lastRawScrollMicros = now;
        final firstTargetPipeline = _firstTargetPipeline;
        if (firstTargetPipeline?.motionGeneration == _motionGeneration &&
            firstTargetPipeline?.firstRawScrollMicros == null) {
          firstTargetPipeline!.firstRawScrollMicros = now;
        }
      }
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_collectFrameTimingDiagnostics) return;
    final motionActive = _activeMotionOrigin != null;
    var awaitingPaintFrameVsyncMicros = _awaitingPaintFrameVsyncMicros;
    var awaitingBudgetProgressRaster = _awaitingBudgetProgressRaster;
    if (!motionActive &&
        awaitingPaintFrameVsyncMicros == null &&
        awaitingBudgetProgressRaster == null) {
      return;
    }
    for (final timing in timings) {
      if (motionActive) _frameTimings!.recordFrameTiming(timing);
      if (awaitingPaintFrameVsyncMicros != null &&
          timing.timestampInMicroseconds(FramePhase.rasterFinish) >=
              awaitingPaintFrameVsyncMicros) {
        final rasterFinishMicros = timing.timestampInMicroseconds(
          FramePhase.rasterFinish,
        );
        _acknowledgedFrameToRasterLatency!.record(
          rasterFinishMicros - awaitingPaintFrameVsyncMicros,
        );
        final firstTargetPipeline = _firstTargetPipeline;
        if (firstTargetPipeline?.logBoxPaintVsyncMicros ==
            awaitingPaintFrameVsyncMicros) {
          firstTargetPipeline!.logBoxRasterFinishMicros = rasterFinishMicros;
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'AVATAR_FIRST_TARGET_RASTER_ACCOUNTED',
              coreRevision: firstTargetPipeline.coreRevision,
              scope:
                  'pointerId=${firstTargetPipeline.pointerId} '
                  'targetHandle=${firstTargetPipeline.targetHandle ?? '-'} '
                  'interactionGeneration='
                  '${firstTargetPipeline.motionGeneration ?? '-'} '
                  'paintVsyncMicros='
                  '${firstTargetPipeline.logBoxPaintVsyncMicros} '
                  'rasterFinishMicros=$rasterFinishMicros '
                  'paintToRasterMicros='
                  '${rasterFinishMicros - awaitingPaintFrameVsyncMicros}',
            ),
          );
        }
        _awaitingPaintFrameVsyncMicros = null;
        awaitingPaintFrameVsyncMicros = null;
      }
      if (awaitingBudgetProgressRaster != null &&
          timing.timestampInMicroseconds(FramePhase.rasterFinish) >=
              awaitingBudgetProgressRaster.paintVsyncMicros) {
        final rasterLatencyMicros =
            timing.timestampInMicroseconds(FramePhase.rasterFinish) -
            awaitingBudgetProgressRaster.paintVsyncMicros;
        _budgetProgressPaintToRasterLatency!.record(rasterLatencyMicros);
        _awaitingBudgetProgressRaster = null;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'BUDGET_PROGRESS_RASTER_ACCOUNTED',
            coreRevision: awaitingBudgetProgressRaster.coreRevision,
            scope:
                'targetHandle=${awaitingBudgetProgressRaster.targetHandle} '
                'interactionGeneration='
                '${awaitingBudgetProgressRaster.interactionGeneration} '
                'visiblePresentationEpoch='
                '${awaitingBudgetProgressRaster.visiblePresentationEpoch ?? '-'} '
                'visibleFrameGeneration='
                '${awaitingBudgetProgressRaster.visibleFrameGeneration ?? '-'} '
                'paintVsyncMicros=${awaitingBudgetProgressRaster.paintVsyncMicros} '
                'rasterFinishMicros='
                '${timing.timestampInMicroseconds(FramePhase.rasterFinish)} '
                'rasterLatencyMicros=$rasterLatencyMicros',
          ),
        );
        awaitingBudgetProgressRaster = null;
      }
      if (_awaitingPaintFrameVsyncMicros == null &&
          _awaitingBudgetProgressRaster == null) {
        break;
      }
    }
  }

  /// Emits one bounded timeline for the first discrete Avatar target reached
  /// after a raw pointer.  It is diagnostic-only: completion neither chooses
  /// a target nor affects Phase-A publication, paint, settle, or physics.
  void _emitFirstTargetPipelineSummary(
    _AvatarFirstTargetPipeline pipeline, {
    required String terminalOutcome,
  }) {
    if (pipeline.summaryEmitted) return;
    pipeline.summaryEmitted = true;

    int elapsedMicros(int? timestampMicros) {
      if (timestampMicros == null) return -1;
      final elapsed = timestampMicros - pipeline.pointerAcceptedMicros;
      return elapsed < 0 ? 0 : elapsed;
    }

    final paintToRasterMicros =
        pipeline.logBoxPaintVsyncMicros == null ||
            pipeline.logBoxRasterFinishMicros == null
        ? -1
        : pipeline.logBoxRasterFinishMicros! - pipeline.logBoxPaintVsyncMicros!;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AVATAR_FIRST_TARGET_PIPELINE_SUMMARY',
        coreRevision: pipeline.coreRevision,
        scope:
            'pointerId=${pipeline.pointerId} '
            'initialSelectedTargetHandle=${pipeline.initialSelectedTargetHandle} '
            'targetHandle=${pipeline.targetHandle ?? '-'} '
            'interactionGeneration=${pipeline.motionGeneration ?? '-'} '
            'startingRawCenteredLogicalIndex='
            '${pipeline.startingRawCenteredLogicalIndex.toStringAsFixed(4)} '
            'distanceToNearestSemanticBoundaryItems='
            '${pipeline.distanceToNearestSemanticBoundaryItems.toStringAsFixed(4)} '
            'distanceToNearestSemanticBoundaryPixels='
            '${(pipeline.distanceToNearestSemanticBoundaryItems * _itemExtent).toStringAsFixed(2)} '
            'touchSlopThresholdPixels=${pipeline.touchSlopThresholdPixels} '
            'pointerToRecognizerMicros='
            '${elapsedMicros(pipeline.recognizerOwnedMicros)} '
            'pointerToFirstRawScrollMicros='
            '${elapsedMicros(pipeline.firstRawScrollMicros)} '
            'pointerToFirstSemanticMicros='
            '${elapsedMicros(pipeline.firstSemanticMicros)} '
            'pointerToPreviewMicros='
            '${elapsedMicros(pipeline.previewRequestedMicros)} '
            'pointerToExactPhaseAStoreMicros='
            '${elapsedMicros(pipeline.exactPhaseAStoreMicros)} '
            'pointerToLogBoxPaintMicros='
            '${elapsedMicros(pipeline.logBoxPaintMicros)} '
            'logBoxPaintToRasterMicros=$paintToRasterMicros '
            'terminalOutcome=$terminalOutcome',
      ),
    );
  }

  void _recordTargetTimestamp(Map<int, int> timestamps, int target, int now) {
    timestamps[target] = now;
    while (timestamps.length > _targetTimingStampCapacity) {
      timestamps.remove(timestamps.keys.first);
    }
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
    if (_collectFrameTimingDiagnostics && _activeMotionOrigin != null) {
      _motionAvatarRailBuilds += 1;
    }
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
                onPointerDownDecision: _recordAvatarPointerDecision,
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
                      onSelectionProgressBuilt:
                          _collectFrameTimingDiagnostics && metrics.isSelected
                          ? _recordBudgetProgressWidgetBuilt
                          : null,
                      onSelectionProgressPainted:
                          _collectFrameTimingDiagnostics && metrics.isSelected
                          ? _recordBudgetProgressPainted
                          : null,
                    ),
                  );
                  final interaction = BudgetTargetAvatarInteraction(
                    onPointerDown: metrics.isSelected && _quickEdit != null
                        ? () => _recordQuickEditPointerDown(item.targetHandle)
                        : null,
                    onLongPressStart: metrics.isSelected && _quickEdit != null
                        ? (details) => _startQuickEditForTarget(
                            targetHandle: item.targetHandle,
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

  void _recordAvatarPointerDecision(
    CenteredCarouselPointerDownDecision decision,
  ) {
    if (!_collectFrameTimingDiagnostics || !decision.accepted) return;
    final previous = _firstTargetPipeline;
    if (previous != null && !previous.summaryEmitted) {
      _emitFirstTargetPipelineSummary(
        previous,
        terminalOutcome: 'cancelledByNewPointer',
      );
    }
    final rawCenteredLogicalIndex = _controller.rawCenteredLogicalIndex;
    final distanceToNearestSemanticBoundaryItems =
        (.5 - (rawCenteredLogicalIndex - rawCenteredLogicalIndex.round()).abs())
            .clamp(0.0, .5)
            .toDouble();
    _firstTargetPipeline = _AvatarFirstTargetPipeline(
      pointerId: decision.pointerId,
      pointerAcceptedMicros: developer.Timeline.now,
      startingRawCenteredLogicalIndex: rawCenteredLogicalIndex,
      distanceToNearestSemanticBoundaryItems:
          distanceToNearestSemanticBoundaryItems,
      touchSlopThresholdPixels: kTouchSlop,
      initialSelectedTargetHandle: widget.presentation.value.selectedHandle,
      coreRevision: widget.presentation.value.liveSelection.coreRevision,
    );
  }

  void _onDirectPointerDown() {
    final firstTargetPipeline = _firstTargetPipeline;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'AV|POINTER_ACCEPTED',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'liveRootReady=${widget.liveTargetReadiness?.value ?? true} '
            'motionActive=${_activeMotionOrigin != null} '
            'pointerId=${firstTargetPipeline?.pointerId ?? '-'} '
            'startingRawCenteredLogicalIndex='
            '${firstTargetPipeline?.startingRawCenteredLogicalIndex ?? '-'} '
            'distanceToNearestSemanticBoundaryPixels='
            '${firstTargetPipeline == null ? '-' : (firstTargetPipeline.distanceToNearestSemanticBoundaryItems * _itemExtent).toStringAsFixed(2)} '
            'touchSlopThresholdPixels='
            '${firstTargetPipeline?.touchSlopThresholdPixels ?? '-'} '
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

  _BudgetProgressPaintExpectation? _currentBudgetProgressPaintExpectation(
    BudgetCategoryAvatarSelectedLimitVisualState visual,
  ) {
    final presentation = widget.presentation.value;
    final currentVisual = presentation.selectedLimitVisual;
    if (presentation.selectedHandle != visual.targetHandle ||
        !currentVisual.sameVisualAs(visual)) {
      if (_collectFrameTimingDiagnostics) {
        final signature = Object.hash(
          presentation.selectedHandle,
          visual.targetHandle,
          visual.limitKey,
          visual.displayNumeratorScaled100,
          visual.displayDenominatorScaled100,
          visual.visualProgress,
        );
        if (_lastBudgetProgressStaleSignature != signature) {
          _lastBudgetProgressStaleSignature = signature;
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'BUDGET_PROGRESS_PAINT_STALE_REJECTED',
              coreRevision: presentation.liveAnalysis.coreRevision,
              scope:
                  'selectedHandle=${presentation.selectedHandle} '
                  'visualTargetHandle=${visual.targetHandle} '
                  'interactionGeneration='
                  '${presentation.liveAnalysis.interactionGeneration}',
            ),
          );
        }
      }
      return null;
    }
    return _BudgetProgressPaintExpectation(
      targetHandle: visual.targetHandle,
      interactionGeneration: presentation.liveAnalysis.interactionGeneration,
      coreRevision: presentation.liveAnalysis.coreRevision,
      visiblePresentationEpoch:
          widget.presentation.visiblePresentationEpochForDiagnostics,
      visibleFrameGeneration:
          widget.presentation.visibleFrameGenerationForDiagnostics,
      visual: visual,
      paintVsyncMicros: 0,
    );
  }

  void _recordBudgetProgressWidgetBuilt(
    BudgetCategoryAvatarSelectedLimitVisualState visual,
  ) {
    if (!_collectFrameTimingDiagnostics || !mounted) return;
    final expectation = _currentBudgetProgressPaintExpectation(visual);
    if (expectation == null) return;
    final signature = expectation.signature;
    if (_lastBudgetProgressBuildSignature == signature) return;
    _lastBudgetProgressBuildSignature = signature;
    final buildVsyncMicros =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_WIDGET_BUILT',
        coreRevision: expectation.coreRevision,
        totalMinor: expectation.visual.displayNumeratorScaled100,
        scope:
            'targetHandle=${expectation.targetHandle} '
            'interactionGeneration=${expectation.interactionGeneration} '
            'visiblePresentationEpoch='
            '${expectation.visiblePresentationEpoch ?? '-'} '
            'visibleFrameGeneration=${expectation.visibleFrameGeneration ?? '-'} '
            'visualProgress=${expectation.visual.visualProgress} '
            'buildVsyncMicros=$buildVsyncMicros',
      ),
    );
  }

  void _recordBudgetProgressPainted(
    BudgetCategoryAvatarSelectedLimitVisualState visual,
    int progressChromePaintMicros,
  ) {
    if (!_collectFrameTimingDiagnostics || !mounted) return;
    final expectation = _currentBudgetProgressPaintExpectation(visual);
    if (expectation == null) return;
    final signature = expectation.signature;
    if (_lastBudgetProgressPaintSignature == signature) return;
    _lastBudgetProgressPaintSignature = signature;
    _budgetProgressPaintedCount += 1;
    final paintVsyncMicros =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    final painted = expectation.withPaintVsyncMicros(paintVsyncMicros);
    _awaitingBudgetProgressRaster = painted;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_PAINTED',
        coreRevision: painted.coreRevision,
        totalMinor: painted.visual.displayNumeratorScaled100,
        scope:
            'targetHandle=${painted.targetHandle} '
            'interactionGeneration=${painted.interactionGeneration} '
            'visiblePresentationEpoch=${painted.visiblePresentationEpoch ?? '-'} '
            'visibleFrameGeneration=${painted.visibleFrameGeneration ?? '-'} '
            'displayNumeratorScaled100='
            '${painted.visual.displayNumeratorScaled100 ?? '-'} '
            'displayDenominatorScaled100='
            '${painted.visual.displayDenominatorScaled100 ?? '-'} '
            'visualProgress=${painted.visual.visualProgress} '
            'paintVsyncMicros=$paintVsyncMicros '
            'progressChromePaintMicros=$progressChromePaintMicros',
      ),
    );
  }

  /// Resolves the editable context only when all of the existing visual and
  /// semantic authorities identify the same Avatar target. The normal
  /// Phase-A transaction makes this true; this fail-closed boundary prevents
  /// a transient split brain from editing a stale category instead.
  DashboardBudgetEditContext? _quickEditContextForTarget(int targetHandle) {
    final presentation = widget.presentation.value;
    final context = widget.presentation.directInputEditContext();
    final contextTargetHandle = switch (context) {
      DashboardBudgetLimitEditContext(:final targetHandle) => targetHandle,
      DashboardBudgetYearLimitEditContext(:final targetHandle) => targetHandle,
      null => null,
    };
    final visualTargetHandle = presentation.selectedLimitVisual.targetHandle;
    final coherent =
        presentation.selectedHandle == targetHandle &&
        visualTargetHandle == targetHandle &&
        contextTargetHandle == targetHandle;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_LIMIT_TARGET_IDENTITY_CHECK',
        direction: presentation.liveSelection.direction.name,
        coreRevision: presentation.liveSelection.coreRevision,
        scope:
            'hitTargetHandle=$targetHandle '
            'selectedHandle=${presentation.selectedHandle} '
            'visualTargetHandle=$visualTargetHandle '
            'editContextTargetHandle=${contextTargetHandle ?? '-'} '
            'coherent=$coherent',
      ),
    );
    return coherent ? context : null;
  }

  void _startQuickEditForTarget({
    required int targetHandle,
    required double globalY,
  }) {
    final context = _quickEditContextForTarget(targetHandle);
    if (context == null) return;
    _quickEdit?.longPressStartedWithContext(context: context, globalY: globalY);
  }

  /// One bounded event proves that the selected Avatar remained the raw
  /// hit-test owner even if a later prepared Header projection is absent. The
  /// actual GestureArena outcome is represented by the following long-press
  /// start/acceptance events in [BudgetLimitQuickEditGestureController].
  void _recordQuickEditPointerDown(int targetHandle) {
    final context = widget.presentation.directInputEditContext();
    final contextTargetHandle = switch (context) {
      DashboardBudgetLimitEditContext(:final targetHandle) => targetHandle,
      DashboardBudgetYearLimitEditContext(:final targetHandle) => targetHandle,
      null => null,
    };
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_LIMIT_EDIT_POINTER_DOWN',
        direction: widget.presentation.value.liveSelection.direction.name,
        coreRevision: widget.presentation.value.liveSelection.coreRevision,
        scope:
            'hitTargetHandle=$targetHandle '
            'selectedHandle=${widget.presentation.value.selectedHandle} '
            'visualTargetHandle=${widget.presentation.value.selectedLimitVisual.targetHandle} '
            'editContextTargetHandle=${contextTargetHandle ?? '-'} '
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

/// Mutable only within one rail State while a diagnostic interaction is
/// active. It contains timestamps and identities, never presentation data or
/// a second scheduling authority.
final class _AvatarFirstTargetPipeline {
  _AvatarFirstTargetPipeline({
    required this.pointerId,
    required this.pointerAcceptedMicros,
    required this.startingRawCenteredLogicalIndex,
    required this.distanceToNearestSemanticBoundaryItems,
    required this.touchSlopThresholdPixels,
    required this.initialSelectedTargetHandle,
    required this.coreRevision,
  });

  final int pointerId;
  final int pointerAcceptedMicros;
  final double startingRawCenteredLogicalIndex;
  final double distanceToNearestSemanticBoundaryItems;
  final double touchSlopThresholdPixels;
  final int initialSelectedTargetHandle;
  final int? coreRevision;
  int? motionGeneration;
  int? recognizerOwnedMicros;
  int? firstRawScrollMicros;
  int? firstSemanticMicros;
  int? previewRequestedMicros;
  int? exactPhaseAStoreMicros;
  int? logBoxPaintMicros;
  int? logBoxPaintVsyncMicros;
  int? logBoxRasterFinishMicros;
  int? targetHandle;
  bool summaryEmitted = false;
}

/// A renderer-owned acknowledgement for the exact immutable progress visual
/// that reached the selected Avatar chrome.  It deliberately carries no
/// mutable presentation authority: the existing presentation controller and
/// visible-frame store remain the source of truth.
final class _BudgetProgressPaintExpectation {
  const _BudgetProgressPaintExpectation({
    required this.targetHandle,
    required this.interactionGeneration,
    required this.coreRevision,
    required this.visiblePresentationEpoch,
    required this.visibleFrameGeneration,
    required this.visual,
    required this.paintVsyncMicros,
  });

  final int targetHandle;
  final int interactionGeneration;
  final int? coreRevision;
  final int? visiblePresentationEpoch;
  final int? visibleFrameGeneration;
  final BudgetCategoryAvatarSelectedLimitVisualState visual;
  final int paintVsyncMicros;

  /// This is bounded debug/profile correlation only, so a value hash keeps
  /// repeated builds and paints from generating unbounded diagnostics.
  int get signature => Object.hashAll(<Object?>[
    targetHandle,
    interactionGeneration,
    coreRevision,
    visiblePresentationEpoch,
    visibleFrameGeneration,
    visual.targetHandle,
    visual.limitKey,
    visual.displayNumeratorScaled100,
    visual.displayDenominatorScaled100,
    visual.rawProgress,
    visual.visualProgress,
    visual.chromeGeometry,
    visual.breakEvenGaugeRatio,
    visual.annualSegments,
    visual.typicalMarkerPosition,
  ]);

  _BudgetProgressPaintExpectation withPaintVsyncMicros(int value) =>
      _BudgetProgressPaintExpectation(
        targetHandle: targetHandle,
        interactionGeneration: interactionGeneration,
        coreRevision: coreRevision,
        visiblePresentationEpoch: visiblePresentationEpoch,
        visibleFrameGeneration: visibleFrameGeneration,
        visual: visual,
        paintVsyncMicros: value,
      );
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

int _modulo(int value, int divisor) => ((value % divisor) + divisor) % divisor;
