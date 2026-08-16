import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../application/dashboard_vertical_background_work_snapshot.dart';
import '../../query/application/current_query_controller.dart';
import '../../query/domain/ledger_direction.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/committed_vertical_demand_planner.dart';
import '../../logbox/application/dashboard_logbox_terminal_extent.dart';
import '../../logbox/application/dashboard_logbox_render_domain.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import '../../logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_logbox_presentation_binding.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_header.dart';
import 'dashboard_query_facet_chips.dart';
import 'dashboard_logbox_render_surface.dart';
import 'dashboard_logbox_prepared_scene_cache.dart';
import 'dashboard_logbox_partner_swipe.dart';
import 'dashboard_logbox_text_layout_cache.dart';
import 'dashboard_vertical_scroll_observer.dart';

/// Stable LogBox viewport. Its State, ScrollController, sliver hierarchy and
/// render surface survive every frame; only one immutable bounded payload
/// reference changes.
final class DashboardLogBoxViewport extends StatefulWidget {
  const DashboardLogBoxViewport({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    required this.onLoadNextPage,
    this.onLoadPreviousPage,
    this.onVerticalPointerDown,
    this.onVerticalPointerIntentStarted,
    this.onVerticalPointerIntentEnded,
    this.onVerticalScrollStarted,
    this.onVerticalScrollEnded,
    this.verticalBackgroundWork,
    required this.preparedRasters,
    this.committedViewport,
    this.renderCriticalPayloads,
    this.sceneWindowProvider,
    this.preparedSceneCache,
    this.onEntryTap,
    this.onAvatarTap,
    this.partnerSwipe,
    this.onPartnerFocus,
    this.onWarmupSurfaceAttached,
    this.onWarmupSurfaceLaidOut,
    this.onWarmupTextLayoutsPrepared,
    this.onWarmupError,
    this.onTextLayoutsPrepared,
    this.performanceCounters,
    this.renderDiagnostics,
    this.renderDiagnosticContextProvider,
    this.onExtentPublished,
    this.onCommittedScopeReset,
    this.currentQuery,
    this.onRemoveQueryCategory,
    this.onRemoveQueryPartner,
    this.onClearQuery,
    this.focus,
    this.onClearFocusCategory,
    this.onClearFocusPartner,
    this.onClearFocus,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final ValueChanged<int> onLoadNextPage;
  final ValueChanged<int>? onVerticalPointerIntentStarted;
  final void Function(int pointer, {required bool cancelled})?
  onVerticalPointerIntentEnded;
  final VoidCallback? onLoadPreviousPage;
  final VoidCallback? onVerticalPointerDown;
  final VoidCallback? onVerticalScrollStarted;
  final VoidCallback? onVerticalScrollEnded;
  final DashboardVerticalBackgroundWorkSnapshot Function()?
  verticalBackgroundWork;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
  final ValueChanged<String>? onEntryTap;
  final ValueChanged<DashboardLogRowViewModel>? onAvatarTap;
  final DashboardLogBoxPartnerSwipeController? partnerSwipe;
  final Future<bool> Function(DashboardLogRowViewModel row)? onPartnerFocus;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onWarmupError;
  final DashboardLogBoxTextLayoutPreparedCallback? onTextLayoutsPrepared;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  final DashboardRenderDiagnosticContextProvider?
  renderDiagnosticContextProvider;
  final ValueChanged<DashboardLogBoxRenderExtentSnapshot>? onExtentPublished;
  final VoidCallback? onCommittedScopeReset;
  final CurrentQueryController? currentQuery;
  final ValueChanged<String>? onRemoveQueryCategory;
  final ValueChanged<String>? onRemoveQueryPartner;
  final VoidCallback? onClearQuery;
  final DashboardEphemeralFocusController? focus;
  final VoidCallback? onClearFocusCategory;
  final VoidCallback? onClearFocusPartner;
  final VoidCallback? onClearFocus;

  @override
  State<DashboardLogBoxViewport> createState() =>
      _DashboardLogBoxViewportState();
}

final class _DashboardLogBoxViewportState
    extends State<DashboardLogBoxViewport> {
  late final DashboardVerticalScrollController _scrollController;
  DashboardLogBoxVisibleScopeIdentity? _lastVisibleScope;
  DashboardLogBoxPresentationBinding? _lastVisibleBinding;
  DashboardLogBoxVisibleScopeIdentity? _scopeAwaitingPayloadPaint;
  late final _VerticalInteractionSessionOwner _verticalSession;
  late final DashboardLogBoxSurfaceHitTestController _surfaceHitTest;
  late final _DashboardLogBoxPointerArbitrationOwner _pointerArbitration;

  @override
  void initState() {
    super.initState();
    _verticalSession = _VerticalInteractionSessionOwner();
    _surfaceHitTest = DashboardLogBoxSurfaceHitTestController();
    _pointerArbitration = _DashboardLogBoxPointerArbitrationOwner();
    _scrollController = DashboardVerticalScrollController(
      onBallisticHandoffStarted: _onBallisticHandoffStarted,
      onBallistic: _onBallisticObserved,
      onContentDimensionsChanged: _onContentDimensionsChanged,
    );
    _lastVisibleBinding = widget.visibleFrames.logBoxPresentationLane.value;
    _lastVisibleScope = _visibleScopeFor(_lastVisibleBinding);
    widget.visibleFrames.logBoxPresentationLane.addListener(
      _onPresentationBindingChanged,
    );
    widget.visibleFrames.logBoxLane.addListener(_onLogBoxPayloadChanged);
    widget.currentQuery?.addListener(_onAppliedQueryChanged);
    widget.focus?.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardLogBoxViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuery != widget.currentQuery) {
      oldWidget.currentQuery?.removeListener(_onAppliedQueryChanged);
      widget.currentQuery?.addListener(_onAppliedQueryChanged);
    }
    if (oldWidget.focus != widget.focus) {
      oldWidget.focus?.removeListener(_onFocusChanged);
      widget.focus?.addListener(_onFocusChanged);
    }
    if (identical(oldWidget.visibleFrames, widget.visibleFrames)) return;
    oldWidget.visibleFrames.logBoxPresentationLane.removeListener(
      _onPresentationBindingChanged,
    );
    oldWidget.visibleFrames.logBoxLane.removeListener(_onLogBoxPayloadChanged);
    _lastVisibleBinding = widget.visibleFrames.logBoxPresentationLane.value;
    _lastVisibleScope = _visibleScopeFor(_lastVisibleBinding);
    _scopeAwaitingPayloadPaint = null;
    _verticalSession.invalidate(
      oldBinding: null,
      newBinding: _lastVisibleBinding,
      reason: 'visibleFramesReplaced',
      requiresFreshSession: false,
    );
    widget.visibleFrames.logBoxPresentationLane.addListener(
      _onPresentationBindingChanged,
    );
    widget.visibleFrames.logBoxLane.addListener(_onLogBoxPayloadChanged);
  }

  @override
  void dispose() {
    widget.visibleFrames.logBoxPresentationLane.removeListener(
      _onPresentationBindingChanged,
    );
    widget.visibleFrames.logBoxLane.removeListener(_onLogBoxPayloadChanged);
    widget.currentQuery?.removeListener(_onAppliedQueryChanged);
    widget.focus?.removeListener(_onFocusChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onAppliedQueryChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onBallisticObserved(DashboardVerticalBallisticObservation observation) {
    final binding = widget.visibleFrames.logBoxPresentationLane.value;
    final session = _verticalSession.active;
    if (session == null || !session.matches(binding)) return;
    final transition = _verticalSession.recordBallistic(observation);
    if (transition.release) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_DRAG_RELEASED',
          queryKey: binding?.queryKey.value,
          coreRevision: binding?.coreRevision,
          message:
              'interactionGeneration=${session.generation} '
              'presentationEpoch=${session.presentationEpoch} '
              'pixels=${observation.pixels.round()} '
              'appliedBallisticVelocity=${observation.initialVelocity.round()} '
              'pointerToReleaseMs=${transition.pointerToRelease.inMilliseconds} '
              'highestReady=${widget.committedViewport?.highestReadyPageOrdinal ?? -1} '
              'lastPossible=${_lastPossibleOrdinal(widget.committedViewport)} '
              'hasMorePages=${widget.committedViewport?.hasMorePages ?? false} '
              '${_verticalBackgroundWorkMessage(widget.verticalBackgroundWork?.call())}',
        ),
      );
    }
    if (transition.ballisticStarted) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_BALLISTIC_STARTED',
          queryKey: binding?.queryKey.value,
          coreRevision: binding?.coreRevision,
          message:
              'interactionGeneration=${session.generation} '
              'pixels=${observation.pixels.round()} '
              'appliedBallisticVelocity=${observation.initialVelocity.round()} '
              'maxScrollExtent=${observation.maxScrollExtent.round()} '
              'goBallisticInvocationCountForInteraction=${transition.goBallisticInvocationCount} '
              'contentDimensionChangeCountForInteraction=${transition.contentDimensionChangeCount}',
        ),
      );
    }
    if (transition.terminalScrollEndFinalized) {
      widget.onVerticalScrollEnded?.call();
    }
  }

  /// `ScrollEndNotification` may be dispatched from inside the framework's
  /// `goBallistic` stack. Mark the handoff first so the interaction session
  /// cannot publish a no-ballistic terminal classification before the exact
  /// framework outcome is observed after `super.goBallistic`.
  void _onBallisticHandoffStarted() {
    _verticalSession.recordFrameworkBallisticHandoffStarted();
  }

  void _onContentDimensionsChanged(
    DashboardVerticalContentDimensionObservation observation,
  ) {
    _verticalSession.recordContentDimensionChange(observation);
  }

  int _lastPossibleOrdinal(CommittedLogViewportCache? committed) {
    if (committed == null || committed.totalEntryCount == 0) return 0;
    return (committed.totalEntryCount - 1) ~/ committed.pageSize;
  }

  bool get _hasQueryFacets {
    final query = widget.currentQuery;
    if (query == null) return false;
    final activeDirection =
        widget.visibleFrames.value?.direction ?? LedgerDirection.income;
    final focus = widget.focus?.state;
    if (focus?.anchor.direction == activeDirection && !focus!.isEmpty) {
      return true;
    }
    final facets = query.facetPresentationFor(activeDirection);
    if (facets == null) return false;
    final scope = query.scopeFor(activeDirection);
    return facets.categories.any(
          (item) => scope.categoryIds.contains(item.id),
        ) ||
        facets.partners.any((item) => scope.partnerIds.contains(item.id));
  }

  double get _headerHeight =>
      DashboardLogBoxTokens.summaryHeaderHeight +
      (_hasQueryFacets ? DashboardQueryFacetChips.height : 0);

  double get _facetListGap =>
      _hasQueryFacets ? DashboardLogBoxTokens.facetListGap : 0;

  void _onPresentationBindingChanged() {
    final nextBinding = widget.visibleFrames.logBoxPresentationLane.value;
    final nextScope = _visibleScopeFor(nextBinding);
    final previousBinding = _lastVisibleBinding;
    final previousScope = _lastVisibleScope;
    _lastVisibleBinding = nextBinding;
    _lastVisibleScope = nextScope;
    final scopeChanged = nextScope != previousScope;
    final sessionBindingChanged = _verticalSession.bindingChanged(nextBinding);
    if (scopeChanged || sessionBindingChanged) {
      if (scopeChanged) widget.partnerSwipe?.cancel();
      if (sessionBindingChanged) widget.onVerticalScrollEnded?.call();
      _verticalSession.invalidate(
        oldBinding: previousBinding,
        newBinding: nextBinding,
        reason: scopeChanged
            ? 'siblingScopeChanged'
            : 'presentationEpochChanged',
        requiresFreshSession: scopeChanged,
      );
    }
    if (!scopeChanged || nextScope == null) return;

    // The presentation lane flushes before the payload lane. Reset the stable
    // vertical position here so a newly visible sibling cannot paint once with
    // the previous sibling's deep scroll offset.
    _scopeAwaitingPayloadPaint = nextScope;
    _resetForVisibleScopeChange(
      previousBinding: previousBinding,
      previousScope: previousScope,
      nextBinding: nextBinding!,
      nextScope: nextScope,
    );
  }

  void _resetForVisibleScopeChange({
    required DashboardLogBoxPresentationBinding? previousBinding,
    required DashboardLogBoxVisibleScopeIdentity? previousScope,
    required DashboardLogBoxPresentationBinding nextBinding,
    required DashboardLogBoxVisibleScopeIdentity nextScope,
  }) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final oldPixels = position.pixels;
    final top = position.minScrollExtent;
    if (oldPixels == top) return;

    final verticalActivity = position.isScrollingNotifier.value
        ? 'scrolling'
        : 'idle';
    // jumpTo uses ScrollPosition's native activity reset, which interrupts an
    // in-flight vertical ballistic without replacing the controller/position.
    _scrollController.jumpTo(top);
    widget.onCommittedScopeReset?.call();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_VISIBLE_SCOPE_RESET',
        queryKey: nextScope.queryKey,
        coreRevision: nextScope.coreRevision,
        message:
            'oldQuery=${previousScope?.queryKey ?? 'none'} '
            'newQuery=${nextScope.queryKey} '
            'oldMode=${previousBinding?.mode.name ?? 'none'} '
            'newMode=${nextBinding.mode.name} '
            'oldPixels=${oldPixels.round()} '
            'newPixels=${position.pixels.round()} '
            'trigger=${nextBinding.mode == DashboardVisibleMode.preview ? 'railSiblingPreview' : 'committedStructuralChange'} '
            'verticalActivity=$verticalActivity '
            'presentationEpoch=${nextBinding.presentationEpoch} '
            'viewportId=${nextScope.viewportId}',
      ),
    );
  }

  void _onLogBoxPayloadChanged() {
    final expectedScope = _scopeAwaitingPayloadPaint;
    if (expectedScope == null) return;
    final payload = widget.visibleFrames.logBoxLane.value;
    if (payload == null || payload.queryKey.value != expectedScope.queryKey) {
      return;
    }
    _scopeAwaitingPayloadPaint = null;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels == position.minScrollExtent) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SIBLING_SCROLL_RESET_LATE',
        queryKey: expectedScope.queryKey,
        coreRevision: expectedScope.coreRevision,
        message:
            'pixels=${position.pixels.round()} '
            'minPixels=${position.minScrollExtent.round()} '
            'viewportId=${expectedScope.viewportId}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.logViewportBuild,
    );
    final headerHeight = _headerHeight;
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-lane-repaint-boundary'),
      child: SizedBox(
        width: widget.bounds.width,
        child: Column(
          key: const ValueKey('dashboard-logbox-viewport'),
          children: [
            DashboardLogBoxHeader(
              bounds: DashboardBounds(
                left: 0,
                top: 0,
                width: widget.bounds.width,
                height: headerHeight,
              ),
              visibleFrames: widget.visibleFrames,
              performanceCounters: widget.performanceCounters,
              currentQuery: widget.currentQuery,
              onRemoveCategory: widget.onRemoveQueryCategory,
              onRemovePartner: widget.onRemoveQueryPartner,
              onClear: widget.onClearQuery,
              focus: widget.focus,
              onClearFocusCategory: widget.onClearFocusCategory,
              onClearFocusPartner: widget.onClearFocusPartner,
              onClearFocus: widget.onClearFocus,
            ),
            if (_facetListGap > 0)
              SizedBox(
                key: const ValueKey('dashboard-logbox-facet-list-gap'),
                height: _facetListGap,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final presentationBounds =
                      _DashboardLogBoxHorizontalPresentationBounds.resolve(
                        staticContentWidth: constraints.maxWidth,
                        dashboardGlobalLeft: widget.bounds.left,
                      );
                  return Stack(
                    // This wrapper only exposes the physical left paint space.
                    // Its child RenderViewport remains the sole hard-edge clip.
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        key: const ValueKey(
                          'dashboard-logbox-physical-scroll-host',
                        ),
                        left: presentationBounds.localLeft,
                        top: 0,
                        bottom: 0,
                        width: presentationBounds.physicalHostWidth,
                        child: _DashboardLogScrollArea(
                          staticContentLeftInset:
                              presentationBounds.staticContentLeftInset,
                          visibleFrames: widget.visibleFrames,
                          controller: _scrollController,
                          onVerticalPointerIntentStarted:
                              widget.onVerticalPointerIntentStarted,
                          onVerticalPointerIntentEnded:
                              widget.onVerticalPointerIntentEnded,
                          preparedRasters: widget.preparedRasters,
                          committedViewport: widget.committedViewport,
                          onLoadNextPage: widget.onLoadNextPage,
                          onLoadPreviousPage: widget.onLoadPreviousPage,
                          onVerticalPointerDown: widget.onVerticalPointerDown,
                          onVerticalScrollStarted:
                              widget.onVerticalScrollStarted,
                          onVerticalScrollEnded: widget.onVerticalScrollEnded,
                          verticalBackgroundWork: widget.verticalBackgroundWork,
                          verticalSession: _verticalSession,
                          renderCriticalPayloads: widget.renderCriticalPayloads,
                          sceneWindowProvider: widget.sceneWindowProvider,
                          preparedSceneCache: widget.preparedSceneCache,
                          onEntryTap: widget.onEntryTap,
                          onAvatarTap: widget.onAvatarTap,
                          partnerSwipe: widget.partnerSwipe,
                          onPartnerFocus: widget.onPartnerFocus,
                          hitTestController: _surfaceHitTest,
                          pointerArbitration: _pointerArbitration,
                          onWarmupSurfaceAttached:
                              widget.onWarmupSurfaceAttached,
                          onWarmupSurfaceLaidOut: widget.onWarmupSurfaceLaidOut,
                          onWarmupTextLayoutsPrepared:
                              widget.onWarmupTextLayoutsPrepared,
                          onWarmupError: widget.onWarmupError,
                          onTextLayoutsPrepared: widget.onTextLayoutsPrepared,
                          performanceCounters: widget.performanceCounters,
                          renderDiagnostics: widget.renderDiagnostics,
                          renderDiagnosticContextProvider:
                              widget.renderDiagnosticContextProvider,
                          onExtentPublished: widget.onExtentPublished,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separates the stable card-content inset from the physical clip host.
///
/// The resting LogBox surface is intentionally narrower than the dashboard
/// screen. One active swipe segment may cross that visual gutter, so the hard
/// viewport clip begins at the physical screen edge while the static sliver is
/// padded back to its canonical content origin.
@immutable
final class _DashboardLogBoxHorizontalPresentationBounds {
  const _DashboardLogBoxHorizontalPresentationBounds({
    required this.localLeft,
    required this.physicalHostWidth,
    required this.staticContentLeftInset,
  });

  final double localLeft;
  final double physicalHostWidth;
  final double staticContentLeftInset;

  factory _DashboardLogBoxHorizontalPresentationBounds.resolve({
    required double staticContentWidth,
    required double dashboardGlobalLeft,
  }) {
    final inset = dashboardGlobalLeft.isFinite && dashboardGlobalLeft > 0
        ? dashboardGlobalLeft
        : 0.0;
    return _DashboardLogBoxHorizontalPresentationBounds(
      localLeft: -inset,
      physicalHostWidth: staticContentWidth + inset,
      staticContentLeftInset: inset,
    );
  }
}

@immutable
final class DashboardLogBoxVisibleScopeIdentity {
  const DashboardLogBoxVisibleScopeIdentity({
    required this.queryKey,
    required this.coreRevision,
    required this.viewportId,
  });

  final String queryKey;
  final int coreRevision;
  final int viewportId;

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxVisibleScopeIdentity &&
      queryKey == other.queryKey &&
      coreRevision == other.coreRevision &&
      viewportId == other.viewportId;

  @override
  int get hashCode => Object.hash(queryKey, coreRevision, viewportId);
}

/// A vertical gesture is valid only for the exact visible presentation that
/// created it. The stable viewport owns this lightweight lifetime marker; the
/// rail and the paging controller never own a [ScrollPosition].
final class _VerticalInteractionSession {
  const _VerticalInteractionSession({
    required this.scope,
    required this.presentationEpoch,
    required this.generation,
  });

  final DashboardLogBoxVisibleScopeIdentity scope;
  final int presentationEpoch;
  final int generation;

  bool matches(DashboardLogBoxPresentationBinding? binding) =>
      binding != null &&
      binding.mode == DashboardVisibleMode.committed &&
      scope == _visibleScopeFor(binding) &&
      presentationEpoch == binding.presentationEpoch;
}

@immutable
final class _VerticalBallisticTransition {
  const _VerticalBallisticTransition({
    required this.release,
    required this.ballisticStarted,
    required this.terminalScrollEndFinalized,
    required this.pointerToRelease,
    required this.goBallisticInvocationCount,
    required this.contentDimensionChangeCount,
  });

  final bool release;
  final bool ballisticStarted;
  final bool terminalScrollEndFinalized;
  final Duration pointerToRelease;
  final int goBallisticInvocationCount;
  final int contentDimensionChangeCount;
}

/// Exact ScrollEnd data held only across the synchronous framework
/// `goBallistic` handoff. It is never a second interaction owner: the active
/// session remains authoritative and finalizes this data as soon as the
/// framework reports whether it created a ballistic simulation.
final class _PendingVerticalScrollEnd {
  const _PendingVerticalScrollEnd({
    required this.binding,
    required this.pixels,
    required this.readiness,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.committedViewport,
    required this.backgroundWork,
    required this.performanceCounters,
  });

  final DashboardLogBoxPresentationBinding binding;
  final double pixels;
  final _VerticalReadinessSnapshot readiness;
  final double minScrollExtent;
  final double maxScrollExtent;
  final CommittedLogViewportCache committedViewport;
  final DashboardVerticalBackgroundWorkSnapshot backgroundWork;
  final DashboardPerformanceCounters? performanceCounters;
}

/// The one owner for vertical interaction invalidation and generation.
///
/// A sibling payload can be published while a previous drag still has queued
/// scroll notifications. The notification itself carries no gesture identity,
/// so the only safe boundary is the pre-paint presentation transition: it
/// invalidates the old session before the stable [ScrollPosition] is reset.
final class _VerticalInteractionSessionOwner {
  int _generationCursor = 0;
  _VerticalInteractionSession? _active;
  int? _lastInvalidatedGeneration;
  int? _lastRejectedAgainstGeneration;
  int? _lastPromotionLateGeneration;
  DateTime? _lastPointerDownTimestamp;
  DateTime? _lastPointerUpTimestamp;
  DateTime? _lastPointerEventTimestamp;
  int _pointerMoveEventCount = 0;
  double _pointerCumulativeAbsDy = 0;
  double _pointerNetDy = 0;
  double _pointerMaximumSingleMoveDy = 0;
  int _pointerProcessingWallMicros = 0;
  bool _requiresFreshSession = false;
  DateTime? _sessionStartedAt;
  bool _dragReleased = false;
  bool _ballisticStarted = false;
  bool _ballisticEnded = false;
  bool _frameworkBallisticHandoffPending = false;
  _PendingVerticalScrollEnd? _pendingScrollEnd;
  double _ballisticStartPixels = 0;
  DateTime? _ballisticStartedAt;
  double? _rawReleaseVelocity;
  double? _appliedBallisticVelocity;
  int _sessionGoBallisticInvocationCount = 0;
  int _contentDimensionChangeCount = 0;
  int _readyFrontierOrdinalAtStart = -1;
  double _sessionStartPixels = 0;
  int _repositoryReadsStartedAtStart = 0;
  int _repositoryReadsCompletedAtStart = 0;
  int _pagesCommittedAtStart = 0;
  int _firstVisibleOrdinalAtStart = -1;
  int _lastVisibleOrdinalAtStart = -1;
  int _readyDrawableAheadPagesAtStart = 0;
  int _readyDrawableAheadPagesMinimum = 0;
  double _readyDrawableAheadPixelsAtStart = 0;
  double _readyDrawableAheadPixelsMinimum = 0;
  double _virtualRemainingPixelsAtStart = 0;
  double _virtualRemainingPixelsMinimum = 0;
  int _visibleMissingPageCountAtStart = 0;
  int? _firstVisibleMissingOrdinalAtStart;
  int? _deferredPresentationOrdinalAtStart;
  _VerticalReadinessSnapshot? _readinessAtEnd;
  int? _deferredPresentationOrdinalAtEnd;
  int _textLayoutMissesAtStart = 0;
  int _verticalCacheMissesAtStart = 0;
  int _verticalRootNotDrawableAtStart = 0;
  int _virtualPageMissesAtStart = 0;
  int _virtualGeometryMismatchesAtStart = 0;
  double _virtualExtentAtStart = 0;
  double _maxScrollExtentAtStart = 0;
  int _geometryGenerationAtStart = 0;
  int _resourceGenerationAtStart = 0;
  CommittedPagePreparationInteractionMetrics?
  _pagePreparationInteractionMetrics;

  DashboardVerticalBackgroundWorkSnapshot _backgroundWorkAtPointerDown =
      _emptyVerticalBackgroundWork;
  int _pagePreparationUiMicrosAtPointerDown = 0;
  DashboardVerticalBackgroundWorkSnapshot _backgroundWorkAtPointerUp =
      _emptyVerticalBackgroundWork;
  int _pagePreparationUiMicrosAtPointerUp = 0;
  _VerticalInteractionSession? get active => _active;

  void recordPointerDown(
    DashboardLogBoxPresentationBinding? binding, {
    DashboardVerticalBackgroundWorkSnapshot? backgroundWork,
    CommittedLogViewportCache? committedViewport,
  }) {
    _backgroundWorkAtPointerDown =
        backgroundWork ?? _emptyVerticalBackgroundWork;
    _backgroundWorkAtPointerUp = _emptyVerticalBackgroundWork;
    _pagePreparationUiMicrosAtPointerDown =
        committedViewport?.pagePreparationUiMicros ?? 0;
    _pagePreparationUiMicrosAtPointerUp = _pagePreparationUiMicrosAtPointerDown;
    _lastPointerDownTimestamp = DateTime.now();
    _lastPointerUpTimestamp = null;
    _lastPointerEventTimestamp = _lastPointerDownTimestamp;
    _pointerMoveEventCount = 0;
    _pointerCumulativeAbsDy = 0;
    _pointerNetDy = 0;
    _pointerMaximumSingleMoveDy = 0;
    _pointerProcessingWallMicros = 0;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_POINTER_DOWN',
        queryKey: binding?.queryKey.value,
        coreRevision: binding?.coreRevision,
        message:
            'pointerDownTimestamp=${_lastPointerDownTimestamp!.toIso8601String()} '
            'presentationEpoch=${binding?.presentationEpoch ?? 'none'}',
      ),
    );
  }

  /// Accumulates bounded scalar input evidence only. This listener retains no
  /// pointer samples and deliberately emits nothing from the move hot path.
  void recordPointerMove(PointerMoveEvent event) {
    final started = Stopwatch()..start();
    final dy = event.delta.dy;
    _pointerMoveEventCount += 1;
    _pointerCumulativeAbsDy += dy.abs();
    _pointerNetDy += dy;
    _pointerMaximumSingleMoveDy = _pointerMaximumSingleMoveDy > dy.abs()
        ? _pointerMaximumSingleMoveDy
        : dy.abs();
    _lastPointerEventTimestamp = DateTime.now();
    _pointerProcessingWallMicros += started.elapsedMicroseconds;
  }

  void recordPointerUp({
    DashboardVerticalBackgroundWorkSnapshot? backgroundWork,
    CommittedLogViewportCache? committedViewport,
  }) {
    _backgroundWorkAtPointerUp = backgroundWork ?? _emptyVerticalBackgroundWork;
    _pagePreparationUiMicrosAtPointerUp =
        committedViewport?.pagePreparationUiMicros ??
        _pagePreparationUiMicrosAtPointerDown;
    _lastPointerUpTimestamp = DateTime.now();
  }

  void recordPointerCancelled({
    DashboardVerticalBackgroundWorkSnapshot? backgroundWork,
    CommittedLogViewportCache? committedViewport,
  }) => recordPointerUp(
    backgroundWork: backgroundWork,
    committedViewport: committedViewport,
  );

  /// Emits one bounded summary when the framework does not produce a
  /// [ScrollEndNotification] for a short/tap-like pointer sequence. Real
  /// drag/ballistic sessions still report at ScrollEnd, where framework
  /// goBallistic evidence is available.
  void recordPointerSequenceEndedWithoutScroll() {
    if (_active != null || _lastPointerDownTimestamp == null) return;
    _recordInputSampleSummary();
  }

  bool bindingChanged(DashboardLogBoxPresentationBinding? binding) {
    final active = _active;
    return active != null && !active.matches(binding);
  }

  _VerticalInteractionSession start(
    DashboardLogBoxPresentationBinding binding, {
    required _VerticalReadinessSnapshot readiness,
    required double pixels,
    double maxScrollExtent = 0,
    CommittedLogViewportCache? committedViewport,
    DashboardVerticalBackgroundWorkSnapshot? backgroundWork,
    DashboardPerformanceCounters? performanceCounters,
  }) {
    final session = _VerticalInteractionSession(
      scope: _visibleScopeFor(binding)!,
      presentationEpoch: binding.presentationEpoch,
      generation: ++_generationCursor,
    );
    _active = session;
    _requiresFreshSession = false;
    _lastRejectedAgainstGeneration = null;
    _sessionStartedAt = DateTime.now();
    _dragReleased = false;
    _ballisticStarted = false;
    _ballisticEnded = false;
    _frameworkBallisticHandoffPending = false;
    _pendingScrollEnd = null;
    _ballisticStartPixels = 0;
    _ballisticStartedAt = null;
    _rawReleaseVelocity = null;
    _appliedBallisticVelocity = null;
    _sessionGoBallisticInvocationCount = 0;
    _contentDimensionChangeCount = 0;
    _readyFrontierOrdinalAtStart = readiness.highestReadyOrdinal;
    _sessionStartPixels = pixels;
    final work = backgroundWork ?? _emptyVerticalBackgroundWork;
    _repositoryReadsStartedAtStart = work.committedPageReadsStarted;
    _repositoryReadsCompletedAtStart = work.committedPageReadsCompleted;
    _pagesCommittedAtStart = work.committedPagesCommitted;
    _firstVisibleOrdinalAtStart = readiness.firstVisibleOrdinal;
    _lastVisibleOrdinalAtStart = readiness.lastVisibleOrdinal;
    _readyDrawableAheadPagesAtStart =
        (readiness.highestReadyOrdinal - readiness.lastVisibleOrdinal)
            .clamp(0, double.maxFinite)
            .toInt();
    _readyDrawableAheadPagesMinimum = _readyDrawableAheadPagesAtStart;
    _readyDrawableAheadPixelsAtStart = readiness.readyDrawableAheadPixels;
    _readyDrawableAheadPixelsMinimum = readiness.readyDrawableAheadPixels;
    _virtualRemainingPixelsAtStart = readiness.virtualRemainingPixels;
    _virtualRemainingPixelsMinimum = readiness.virtualRemainingPixels;
    _visibleMissingPageCountAtStart =
        readiness.visibleResourceReadiness.visibleMissingPageCount;
    _firstVisibleMissingOrdinalAtStart =
        readiness.visibleResourceReadiness.firstVisibleMissingOrdinal;
    _deferredPresentationOrdinalAtStart = work.deferredPresentationOrdinal;
    _readinessAtEnd = null;
    _deferredPresentationOrdinalAtEnd = null;
    _textLayoutMissesAtStart = committedViewport?.textLayoutMissCount ?? 0;
    _verticalCacheMissesAtStart =
        performanceCounters?.value(
          DashboardPerformanceMetric.verticalCacheMiss,
        ) ??
        0;
    _verticalRootNotDrawableAtStart =
        committedViewport?.rootNotDrawableCount ?? 0;
    _virtualPageMissesAtStart = committedViewport?.virtualPageMissCount ?? 0;
    _virtualGeometryMismatchesAtStart =
        committedViewport?.virtualGeometryMismatchCount ?? 0;
    _virtualExtentAtStart = committedViewport?.contentHeight ?? 0;
    _maxScrollExtentAtStart = maxScrollExtent;
    _geometryGenerationAtStart = committedViewport?.geometryGeneration ?? 0;
    _resourceGenerationAtStart = committedViewport?.renderGeneration ?? 0;
    _pagePreparationInteractionMetrics = committedViewport
        ?.beginPagePreparationInteractionMetrics();
    return session;
  }

  /// The viewport session is the only owner that distinguishes the drag from
  /// the framework ballistic phase. Cache code stays geometry/resource-only.
  bool get isBallisticActive => _ballisticStarted && !_ballisticEnded;

  void recordReadyAhead({
    required int readyFrontierOrdinal,
    required int lastVisibleOrdinal,
    required double readyDrawableAheadPixels,
    required double virtualRemainingPixels,
  }) {
    final pages = (readyFrontierOrdinal - lastVisibleOrdinal)
        .clamp(0, double.maxFinite)
        .toInt();
    if (pages < _readyDrawableAheadPagesMinimum) {
      _readyDrawableAheadPagesMinimum = pages;
    }
    if (readyDrawableAheadPixels < _readyDrawableAheadPixelsMinimum) {
      _readyDrawableAheadPixelsMinimum = readyDrawableAheadPixels;
    }
    if (virtualRemainingPixels < _virtualRemainingPixelsMinimum) {
      _virtualRemainingPixelsMinimum = virtualRemainingPixels;
    }
  }

  String get lastPointerDownTimestamp =>
      _lastPointerDownTimestamp?.toIso8601String() ?? 'missing';

  String pointerToInteractionWorkMessage({
    required DateTime interactionStartedAt,
    required DashboardVerticalBackgroundWorkSnapshot backgroundWork,
    required CommittedLogViewportCache committedViewport,
  }) {
    final down = _lastPointerDownTimestamp;
    int delta(int current, int baseline) =>
        current >= baseline ? current - baseline : 0;
    final elapsedMicros = down == null
        ? 'unavailable'
        : interactionStartedAt.difference(down).inMicroseconds;
    return 'pointerDownToInteractionStartMicros=$elapsedMicros '
        'repositoryReadsStartedAfterPointerDown=${delta(backgroundWork.committedPageReadsStarted, _backgroundWorkAtPointerDown.committedPageReadsStarted)} '
        'repositoryReadsCompletedAfterPointerDown=${delta(backgroundWork.committedPageReadsCompleted, _backgroundWorkAtPointerDown.committedPageReadsCompleted)} '
        'pagesCommittedAfterPointerDown=${delta(backgroundWork.committedPagesCommitted, _backgroundWorkAtPointerDown.committedPagesCommitted)} '
        'pagePreparationUiMicrosAfterPointerDown=${delta(committedViewport.pagePreparationUiMicros, _pagePreparationUiMicrosAtPointerDown)}';
  }

  _VerticalBallisticTransition recordBallistic(
    DashboardVerticalBallisticObservation observation,
  ) {
    _sessionGoBallisticInvocationCount += 1;
    final ballisticStarted = !_ballisticStarted && observation.ballisticStarted;
    final release =
        !_dragReleased && observation.releaseInvocation && ballisticStarted;
    if (observation.releaseInvocation && !_dragReleased) {
      _dragReleased = true;
      _appliedBallisticVelocity = observation.initialVelocity;
    }
    if (ballisticStarted) {
      _ballisticStarted = true;
      _ballisticStartPixels = observation.pixels;
      _ballisticStartedAt = DateTime.now();
    }
    final pendingScrollEnd = _pendingScrollEnd;
    _pendingScrollEnd = null;
    _frameworkBallisticHandoffPending = false;
    final terminalScrollEndFinalized =
        pendingScrollEnd != null && !observation.ballisticStarted
        ? _finalizePendingScrollEnd(pendingScrollEnd)
        : false;
    return _VerticalBallisticTransition(
      release: release,
      ballisticStarted: ballisticStarted,
      terminalScrollEndFinalized: terminalScrollEndFinalized,
      pointerToRelease: _lastPointerDownTimestamp == null
          ? Duration.zero
          : DateTime.now().difference(_lastPointerDownTimestamp!),
      goBallisticInvocationCount: _sessionGoBallisticInvocationCount,
      contentDimensionChangeCount: _contentDimensionChangeCount,
    );
  }

  /// Raw drag release belongs to Flutter's [ScrollEndNotification], while
  /// [recordBallistic] observes the velocity which physics actually received.
  /// Keeping them separate makes boundary suppression visible without changing
  /// the physics contract.
  void recordRawReleaseVelocity(double? velocity) {
    if (velocity != null) _rawReleaseVelocity = velocity;
  }

  void recordFrameworkBallisticHandoffStarted() {
    if (_active == null || _ballisticEnded) return;
    _frameworkBallisticHandoffPending = true;
  }

  String _velocityMessage(double? velocity) =>
      velocity == null ? 'unavailable' : velocity.round().toString();

  String _ballisticSuppressionReason({
    required double pixels,
    required double minScrollExtent,
    required double maxScrollExtent,
  }) {
    if (_ballisticStarted) return 'none';
    if (maxScrollExtent <= minScrollExtent) return 'noScrollableExtent';
    if (pixels <= minScrollExtent) return 'atMinBoundary';
    if (pixels >= maxScrollExtent) return 'atMaxBoundary';
    return 'frameworkNoSimulation';
  }

  void recordContentDimensionChange(
    DashboardVerticalContentDimensionObservation observation,
  ) {
    if (_active == null || !observation.ballisticActive) return;
    _contentDimensionChangeCount += 1;
  }

  bool recordScrollEnd({
    required DashboardLogBoxPresentationBinding binding,
    required double pixels,
    required _VerticalReadinessSnapshot readiness,
    required double minScrollExtent,
    required double maxScrollExtent,
    required CommittedLogViewportCache committedViewport,
    required DashboardVerticalBackgroundWorkSnapshot backgroundWork,
    DashboardPerformanceCounters? performanceCounters,
  }) {
    final session = _active;
    if (session == null || !session.matches(binding) || _ballisticEnded) {
      return false;
    }
    if (_frameworkBallisticHandoffPending) {
      _pendingScrollEnd = _PendingVerticalScrollEnd(
        binding: binding,
        pixels: pixels,
        readiness: readiness,
        minScrollExtent: minScrollExtent,
        maxScrollExtent: maxScrollExtent,
        committedViewport: committedViewport,
        backgroundWork: backgroundWork,
        performanceCounters: performanceCounters,
      );
      return false;
    }
    return _finalizeScrollEnd(
      binding: binding,
      pixels: pixels,
      readiness: readiness,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      committedViewport: committedViewport,
      backgroundWork: backgroundWork,
      performanceCounters: performanceCounters,
    );
  }

  bool _finalizePendingScrollEnd(_PendingVerticalScrollEnd pending) =>
      _finalizeScrollEnd(
        binding: pending.binding,
        pixels: pending.pixels,
        readiness: pending.readiness,
        minScrollExtent: pending.minScrollExtent,
        maxScrollExtent: pending.maxScrollExtent,
        committedViewport: pending.committedViewport,
        backgroundWork: pending.backgroundWork,
        performanceCounters: pending.performanceCounters,
      );

  bool _finalizeScrollEnd({
    required DashboardLogBoxPresentationBinding binding,
    required double pixels,
    required _VerticalReadinessSnapshot readiness,
    required double minScrollExtent,
    required double maxScrollExtent,
    required CommittedLogViewportCache committedViewport,
    required DashboardVerticalBackgroundWorkSnapshot backgroundWork,
    DashboardPerformanceCounters? performanceCounters,
  }) {
    final session = _active;
    if (session == null || !session.matches(binding) || _ballisticEnded) {
      return false;
    }
    _ballisticEnded = true;
    recordReadyAhead(
      readyFrontierOrdinal: readiness.highestReadyOrdinal,
      lastVisibleOrdinal: readiness.lastVisibleOrdinal,
      readyDrawableAheadPixels: readiness.readyDrawableAheadPixels,
      virtualRemainingPixels: readiness.virtualRemainingPixels,
    );
    _readinessAtEnd = readiness;
    _deferredPresentationOrdinalAtEnd =
        backgroundWork.deferredPresentationOrdinal;
    final duration = _sessionStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_sessionStartedAt!);
    final ballisticSuppressionReason = _ballisticSuppressionReason(
      pixels: pixels,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
    );
    if (_ballisticStarted) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_BALLISTIC_ENDED',
          queryKey: binding.queryKey.value,
          coreRevision: binding.coreRevision,
          message:
              'interactionGeneration=${session.generation} '
              'startPixels=${_ballisticStartPixels.round()} '
              'endPixels=${pixels.round()} '
              'travelledPixels=${(pixels - _ballisticStartPixels).round()} '
              'wallDurationMs=${(_ballisticStartedAt == null ? duration : DateTime.now().difference(_ballisticStartedAt!)).inMilliseconds} '
              'goBallisticInvocationCount=$_sessionGoBallisticInvocationCount '
              'contentDimensionChangeCount=$_contentDimensionChangeCount '
              'readyFrontierAtStart=$_readyFrontierOrdinalAtStart '
              'readyFrontierAtEnd=${readiness.highestReadyOrdinal}',
        ),
      );
      _recordInputSampleSummary(
        binding: binding,
        interactionDuration: duration,
        ballisticSuppressionReason: ballisticSuppressionReason,
      );
      _recordPerformanceSummary(
        session: session,
        binding: binding,
        pixels: pixels,
        duration: duration,
        minScrollExtent: minScrollExtent,
        maxScrollExtent: maxScrollExtent,
        committedViewport: committedViewport,
        backgroundWork: backgroundWork,
        performanceCounters: performanceCounters,
      );
      return true;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_DRAG_ENDED_WITHOUT_BALLISTIC',
        queryKey: binding.queryKey.value,
        coreRevision: binding.coreRevision,
        message:
            'interactionGeneration=${session.generation} pixels=${pixels.round()} '
            'rawReleaseVelocity=${_velocityMessage(_rawReleaseVelocity)} '
            'appliedBallisticVelocity=${_velocityMessage(_appliedBallisticVelocity)} '
            'ballisticSuppressionReason=$ballisticSuppressionReason '
            'sessionDurationMs=${duration.inMilliseconds}',
      ),
    );
    _recordInputSampleSummary(
      binding: binding,
      interactionDuration: duration,
      ballisticSuppressionReason: ballisticSuppressionReason,
    );
    _recordPerformanceSummary(
      session: session,
      binding: binding,
      pixels: pixels,
      duration: duration,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      committedViewport: committedViewport,
      backgroundWork: backgroundWork,
      performanceCounters: performanceCounters,
    );
    return true;
  }

  void _recordPerformanceSummary({
    required _VerticalInteractionSession session,
    required DashboardLogBoxPresentationBinding binding,
    required double pixels,
    required Duration duration,
    required double minScrollExtent,
    required double maxScrollExtent,
    required CommittedLogViewportCache committedViewport,
    required DashboardVerticalBackgroundWorkSnapshot backgroundWork,
    DashboardPerformanceCounters? performanceCounters,
  }) {
    final verticalCacheMisses =
        performanceCounters?.value(
          DashboardPerformanceMetric.verticalCacheMiss,
        ) ??
        0;
    final preparationMetrics = _pagePreparationInteractionMetrics;
    final pagePreparationUiMicros = preparationMetrics?.uiMicros ?? 0;
    final pagePreparationYieldCount = preparationMetrics?.yieldCount ?? 0;
    final largestPagePreparationUiSliceMicrosDuringInteraction =
        preparationMetrics?.largestUiSliceMicros ?? 0;
    final readinessAtEnd =
        _readinessAtEnd ?? _VerticalReadinessSnapshot.unavailable();
    final pointerContactCompleted = _lastPointerUpTimestamp != null;
    int pointerContactDelta(int end, int start) =>
        end >= start ? end - start : 0;
    final pagePreparationUiMicrosDuringPointerContact = pointerContactDelta(
      _pagePreparationUiMicrosAtPointerUp,
      _pagePreparationUiMicrosAtPointerDown,
    );
    final ballisticSuppressionReason = _ballisticSuppressionReason(
      pixels: pixels,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_INTERACTION_PERF_SUMMARY',
        queryKey: binding.queryKey.value,
        coreRevision: binding.coreRevision,
        message:
            'interactionGeneration=${session.generation} '
            'rawReleaseVelocity=${_velocityMessage(_rawReleaseVelocity)} '
            'appliedBallisticVelocity=${_velocityMessage(_appliedBallisticVelocity)} '
            'ballisticSuppressionReason=$ballisticSuppressionReason '
            'travelledPixels=${(pixels - _sessionStartPixels).round()} '
            'wallDurationMs=${duration.inMilliseconds} '
            'goBallisticInvocationCount=$_sessionGoBallisticInvocationCount '
            'contentDimensionChangeCount=$_contentDimensionChangeCount '
            'virtualExtentAtStart=${_virtualExtentAtStart.round()} '
            'virtualExtentAtEnd=${committedViewport.contentHeight.round()} '
            'maxScrollExtentAtStart=${_maxScrollExtentAtStart.round()} '
            'maxScrollExtentAtEnd=${maxScrollExtent.round()} '
            'geometryGenerationAtStart=$_geometryGenerationAtStart '
            'geometryGenerationAtEnd=${committedViewport.geometryGeneration} '
            'resourceGenerationAtStart=$_resourceGenerationAtStart '
            'resourceGenerationAtEnd=${committedViewport.renderGeneration} '
            'pagePreparationUiMicros='
            '$pagePreparationUiMicros '
            'largestPagePreparationUiSliceMicrosDuringInteraction='
            '$largestPagePreparationUiSliceMicrosDuringInteraction '
            'largestPagePreparationUiSliceMicrosForCommittedScope='
            '${committedViewport.largestPagePreparationUiSliceMicros} '
            'pagePreparationYieldCount='
            '$pagePreparationYieldCount '
            'repositoryReadsStartedDuringInteraction='
            '${backgroundWork.committedPageReadsStarted - _repositoryReadsStartedAtStart} '
            'repositoryReadsCompletedDuringInteraction='
            '${backgroundWork.committedPageReadsCompleted - _repositoryReadsCompletedAtStart} '
            'pagesPreparedDuringInteraction='
            '${backgroundWork.committedPagesCommitted - _pagesCommittedAtStart} '
            'pagesPublishedDuringInteraction='
            '${backgroundWork.committedPagesCommitted - _pagesCommittedAtStart} '
            'repositoryReadsStartedDuringPointerContact='
            '${pointerContactCompleted ? pointerContactDelta(_backgroundWorkAtPointerUp.committedPageReadsStarted, _backgroundWorkAtPointerDown.committedPageReadsStarted) : 'unavailable'} '
            'pagesCommittedDuringPointerContact='
            '${pointerContactCompleted ? pointerContactDelta(_backgroundWorkAtPointerUp.committedPagesCommitted, _backgroundWorkAtPointerDown.committedPagesCommitted) : 'unavailable'} '
            'pagePreparationUiMicrosDuringPointerContact='
            '${pointerContactCompleted ? pagePreparationUiMicrosDuringPointerContact : 'unavailable'} '
            // Exact synchronous TextPainter preparation now has its own
            // measured aggregate. It is resource work, but it still consumes
            // UI-isolate time and must not be reported as zero.
            'uiIsolateMicrosDuringInteraction=$pagePreparationUiMicros '
            'schedulerWaitMicrosDuringInteraction=0 '
            'largestSchedulerWaitMicrosDuringInteraction=0 '
            'firstVisibleOrdinalAtStart=$_firstVisibleOrdinalAtStart '
            'lastVisibleOrdinalAtStart=$_lastVisibleOrdinalAtStart '
            'highestReadyOrdinalAtStart=$_readyFrontierOrdinalAtStart '
            'readyDrawableAheadPagesAtStart='
            '$_readyDrawableAheadPagesAtStart '
            'readyDrawableAheadPagesMinimum='
            '$_readyDrawableAheadPagesMinimum '
            'readyDrawableAheadPixelsAtStart='
            '${_readyDrawableAheadPixelsAtStart.round()} '
            'readyDrawableAheadPixelsMinimum='
            '${_readyDrawableAheadPixelsMinimum.round()} '
            'virtualRemainingPixelsAtStart='
            '${_virtualRemainingPixelsAtStart.round()} '
            'virtualRemainingPixelsMinimum='
            '${_virtualRemainingPixelsMinimum.round()} '
            'visibleMissingPageCountAtStart=$_visibleMissingPageCountAtStart '
            'firstVisibleMissingOrdinalAtStart='
            '${_firstVisibleMissingOrdinalAtStart ?? 'none'} '
            'deferredPresentationOrdinalAtStart='
            '${_deferredPresentationOrdinalAtStart ?? 'none'} '
            'firstVisibleOrdinalAtEnd=${readinessAtEnd.firstVisibleOrdinal} '
            'lastVisibleOrdinalAtEnd=${readinessAtEnd.lastVisibleOrdinal} '
            'highestReadyOrdinalAtEnd=${readinessAtEnd.highestReadyOrdinal} '
            'readyDrawableAheadPixelsAtEnd='
            '${readinessAtEnd.readyDrawableAheadPixels.round()} '
            'virtualRemainingPixelsAtEnd='
            '${readinessAtEnd.virtualRemainingPixels.round()} '
            'visibleMissingPageCountAtEnd='
            '${readinessAtEnd.visibleResourceReadiness.visibleMissingPageCount} '
            'firstVisibleMissingOrdinalAtEnd='
            '${readinessAtEnd.visibleResourceReadiness.firstVisibleMissingOrdinal ?? 'none'} '
            'deferredPresentationOrdinalAtEnd='
            '${_deferredPresentationOrdinalAtEnd ?? 'none'} '
            'retainedPages=${committedViewport.retainedPageCount} '
            'cacheBytes=${committedViewport.estimatedBytes} '
            'textLayoutMissCount='
            '${committedViewport.textLayoutMissCount - _textLayoutMissesAtStart} '
            'verticalCacheMissCount='
            '${verticalCacheMisses - _verticalCacheMissesAtStart} '
            'verticalRootNotDrawableCount='
            '${committedViewport.rootNotDrawableCount - _verticalRootNotDrawableAtStart} '
            'virtualPageMissCount='
            '${committedViewport.virtualPageMissCount - _virtualPageMissesAtStart} '
            'virtualGeometryMismatchCount='
            '${committedViewport.virtualGeometryMismatchCount - _virtualGeometryMismatchesAtStart}',
      ),
    );
  }

  void _recordInputSampleSummary({
    DashboardLogBoxPresentationBinding? binding,
    Duration? interactionDuration,
    String? ballisticSuppressionReason,
  }) {
    final down = _lastPointerDownTimestamp;
    final up = _lastPointerUpTimestamp;
    final lastEvent = _lastPointerEventTimestamp;
    final pointerInputDuration = down == null || up == null
        ? null
        : up.difference(down);
    final finalGap = up == null || lastEvent == null
        ? Duration.zero
        : up.difference(lastEvent);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_INPUT_SAMPLE_SUMMARY',
        queryKey: binding?.queryKey.value,
        coreRevision: binding?.coreRevision,
        message:
            'interactionGeneration=${_active?.generation ?? _generationCursor} '
            'moveEventCount=$_pointerMoveEventCount '
            'netDy=${_pointerNetDy.round()} '
            'cumulativeAbsDy=${_pointerCumulativeAbsDy.round()} '
            'maximumSingleMoveDy=${_pointerMaximumSingleMoveDy.round()} '
            'pointerDownTimestamp=${down?.toIso8601String() ?? 'missing'} '
            'pointerUpTimestamp=${up?.toIso8601String() ?? 'missing'} '
            'pointerInputDurationMs='
            '${pointerInputDuration?.inMilliseconds ?? 'unavailable'} '
            'interactionDurationMs='
            '${interactionDuration?.inMilliseconds ?? 'unavailable'} '
            'finalMoveToUpEventGapMs=${finalGap.inMilliseconds} '
            'processingWallDurationMicros=$_pointerProcessingWallMicros '
            'rawReleaseVelocity=${_velocityMessage(_rawReleaseVelocity)} '
            'appliedBallisticVelocity=${_velocityMessage(_appliedBallisticVelocity)} '
            'ballisticSuppressionReason='
            '${ballisticSuppressionReason ?? 'unavailable'}',
      ),
    );
  }

  void invalidate({
    required DashboardLogBoxPresentationBinding? oldBinding,
    required DashboardLogBoxPresentationBinding? newBinding,
    required String reason,
    required bool requiresFreshSession,
  }) {
    final old = _active;
    // A scope boundary is itself a generation boundary even if the old scope
    // never received a genuine vertical drag. That lets a late update be
    // rejected rather than being interpreted as the new scope's first scroll.
    _generationCursor += 1;
    _active = null;
    _frameworkBallisticHandoffPending = false;
    _pendingScrollEnd = null;
    _requiresFreshSession = requiresFreshSession;
    _lastInvalidatedGeneration = old?.generation ?? _generationCursor - 1;
    _lastRejectedAgainstGeneration = null;
    if (old == null) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_INTERACTION_SESSION_INVALIDATED',
        queryKey: newBinding?.queryKey.value,
        coreRevision: newBinding?.coreRevision,
        message:
            'oldQuery=${old.scope.queryKey} '
            'newQuery=${newBinding?.queryKey.value ?? 'none'} '
            'oldInteractionGeneration=${old.generation} reason=$reason',
      ),
    );
  }

  bool matches(DashboardLogBoxPresentationBinding? binding) =>
      _active?.matches(binding) ?? false;

  bool shouldRejectUpdate(DashboardLogBoxPresentationBinding? binding) =>
      _requiresFreshSession && !matches(binding);

  bool markPromotionLate(_VerticalInteractionSession session) {
    if (_lastPromotionLateGeneration == session.generation) return false;
    _lastPromotionLateGeneration = session.generation;
    return true;
  }

  void recordStaleActivityRejected(
    DashboardLogBoxPresentationBinding? binding,
  ) {
    final currentGeneration = _active?.generation ?? _generationCursor;
    if (_lastRejectedAgainstGeneration == currentGeneration) return;
    _lastRejectedAgainstGeneration = currentGeneration;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'STALE_VERTICAL_ACTIVITY_REJECTED',
        queryKey: binding?.queryKey.value,
        coreRevision: binding?.coreRevision,
        message:
            'activityGeneration=${_lastInvalidatedGeneration ?? 'none'} '
            'currentGeneration=$currentGeneration '
            'queryKey=${binding?.queryKey.value ?? 'none'} '
            'rejectedActivitySource=ScrollUpdateNotification',
      ),
    );
  }
}

const _emptyVerticalBackgroundWork = DashboardVerticalBackgroundWorkSnapshot(
  sceneSpeculationActive: false,
  querySpeculationActive: false,
  committedPageRequestInFlight: false,
  committedPageDataPendingPresentation: false,
  committedPagePresentationActive: false,
  committedPageReadsStarted: 0,
  committedPageReadsCompleted: 0,
  committedPagesCommitted: 0,
);

String _verticalBackgroundWorkMessage(
  DashboardVerticalBackgroundWorkSnapshot? work,
) {
  final state = work ?? _emptyVerticalBackgroundWork;
  return 'sceneSpeculationActive=${state.sceneSpeculationActive} '
      'querySpeculationActive=${state.querySpeculationActive} '
      'committedPageRequestInFlight=${state.committedPageRequestInFlight} '
      'committedPageDataPendingPresentation='
      '${state.committedPageDataPendingPresentation} '
      'committedPagePresentationActive='
      '${state.committedPagePresentationActive} '
      'deferredPresentationOrdinal='
      '${state.deferredPresentationOrdinal ?? 'none'}';
}

DashboardLogBoxVisibleScopeIdentity? _visibleScopeFor(
  DashboardLogBoxPresentationBinding? binding,
) {
  if (binding == null) return null;
  return DashboardLogBoxVisibleScopeIdentity(
    queryKey: binding.queryKey.value,
    coreRevision: binding.coreRevision,
    viewportId: binding.viewportId,
  );
}

/// Keeps a row's pointer sequence neutral until its axis is known. This is
/// presentation input state only: it does not own a [ScrollPosition], focus,
/// cache or row resource.
final class _DashboardLogBoxPointerArbitrationOwner {
  int? _deferredPointer;

  bool defer(int pointer) {
    if (_deferredPointer != null) return false;
    _deferredPointer = pointer;
    return true;
  }

  bool consumeDeferred() {
    if (_deferredPointer == null) return false;
    _deferredPointer = null;
    return true;
  }

  void clear(int pointer) {
    if (_deferredPointer == pointer) _deferredPointer = null;
  }
}

final class _DashboardLogScrollArea extends StatelessWidget {
  const _DashboardLogScrollArea({
    required this.staticContentLeftInset,
    required this.visibleFrames,
    required this.controller,
    required this.preparedRasters,
    required this.committedViewport,
    required this.onLoadNextPage,
    required this.onLoadPreviousPage,
    required this.onVerticalPointerDown,
    required this.onVerticalPointerIntentStarted,
    required this.onVerticalPointerIntentEnded,
    required this.onVerticalScrollStarted,
    required this.onVerticalScrollEnded,
    required this.verticalBackgroundWork,
    required this.verticalSession,
    required this.renderCriticalPayloads,
    required this.sceneWindowProvider,
    required this.preparedSceneCache,
    required this.onEntryTap,
    required this.onAvatarTap,
    required this.partnerSwipe,
    required this.onPartnerFocus,
    required this.hitTestController,
    required this.pointerArbitration,
    required this.onWarmupSurfaceAttached,
    required this.onWarmupSurfaceLaidOut,
    required this.onWarmupTextLayoutsPrepared,
    required this.onWarmupError,
    required this.onTextLayoutsPrepared,
    required this.performanceCounters,
    required this.renderDiagnostics,
    required this.renderDiagnosticContextProvider,
    required this.onExtentPublished,
  });

  final double staticContentLeftInset;
  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final ValueChanged<int> onLoadNextPage;
  final VoidCallback? onLoadPreviousPage;
  final VoidCallback? onVerticalPointerDown;
  final ValueChanged<int>? onVerticalPointerIntentStarted;
  final void Function(int pointer, {required bool cancelled})?
  onVerticalPointerIntentEnded;
  final VoidCallback? onVerticalScrollStarted;
  final VoidCallback? onVerticalScrollEnded;
  final DashboardVerticalBackgroundWorkSnapshot Function()?
  verticalBackgroundWork;
  final _VerticalInteractionSessionOwner verticalSession;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
  final ValueChanged<String>? onEntryTap;
  final ValueChanged<DashboardLogRowViewModel>? onAvatarTap;
  final DashboardLogBoxPartnerSwipeController? partnerSwipe;
  final Future<bool> Function(DashboardLogRowViewModel row)? onPartnerFocus;
  final DashboardLogBoxSurfaceHitTestController hitTestController;
  final _DashboardLogBoxPointerArbitrationOwner pointerArbitration;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onWarmupError;
  final DashboardLogBoxTextLayoutPreparedCallback? onTextLayoutsPrepared;
  final DashboardPerformanceCounters? performanceCounters;
  final DashboardRenderReadinessDiagnostics? renderDiagnostics;
  final DashboardRenderDiagnosticContextProvider?
  renderDiagnosticContextProvider;
  final ValueChanged<DashboardLogBoxRenderExtentSnapshot>? onExtentPublished;

  @override
  Widget build(BuildContext context) {
    // These are scope/geometry publication notifications only. Normal page
    // resource commits use `resourceChanges`, so they still repaint without
    // rebuilding the sliver extent during a ballistic interaction.
    final structuralChanges = Listenable.merge(<Listenable>[
      visibleFrames.logBoxLane,
      visibleFrames.logBoxPresentationLane,
      ?committedViewport,
    ]);
    return AnimatedBuilder(
      animation: structuralChanges,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final terminalExtent = DashboardLogBoxTerminalExtent.resolve(
            logBoxContentExtent: _authoritativeLogBoxContentExtent(),
            viewportDimension: constraints.maxHeight,
            terminalBottomInset:
                MediaQuery.paddingOf(context).bottom +
                DashboardLogBoxTokens.terminalBottomBreathingRoom,
          );
          return _buildScrollable(context, terminalExtent: terminalExtent);
        },
      ),
    );
  }

  double _authoritativeLogBoxContentExtent() {
    final frame = visibleFrames.logBoxLane.value;
    final presentation = visibleFrames.logBoxPresentationLane.value;
    final committed = committedViewport;
    if (frame == null ||
        committed == null ||
        !hasExactCommittedLogBoxGeometry(
          payload: frame.logBox,
          presentation: presentation,
          committedViewport: committed,
        )) {
      return 0;
    }
    return committed.contentHeight;
  }

  Widget _buildScrollable(
    BuildContext context, {
    required DashboardLogBoxTerminalExtent terminalExtent,
  }) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: <Type, GestureRecognizerFactory>{
      DashboardLogBoxPartnerSwipeGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<
            DashboardLogBoxPartnerSwipeGestureRecognizer
          >(DashboardLogBoxPartnerSwipeGestureRecognizer.new, (recognizer) {
            recognizer
              ..hitTest = hitTestController.hitAtGlobal
              ..onSwipeTrackingStarted = partnerSwipe?.notePointerDown
              ..onSwipePointerMove = partnerSwipe?.notePointerMove
              ..onSwipeCandidate = _onPartnerSwipeCandidate
              ..onSwipeAcquired = _onPartnerSwipeAcquired
              ..onSwipeUpdate = partnerSwipe?.update
              ..onSwipeEnd = _onPartnerSwipeEnded
              ..onSwipeCancelled = _onPartnerSwipeCancelled
              ..onVerticalIntent = _onPartnerSwipeVerticalIntent;
          }),
    },
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: verticalSession.recordPointerMove,
      onPointerUp: (event) {
        verticalSession.recordPointerUp(
          backgroundWork: verticalBackgroundWork?.call(),
          committedViewport: committedViewport,
        );
        verticalSession.recordPointerSequenceEndedWithoutScroll();
        pointerArbitration.clear(event.pointer);
        onVerticalPointerIntentEnded?.call(event.pointer, cancelled: false);
      },
      onPointerCancel: (event) {
        verticalSession.recordPointerCancelled(
          backgroundWork: verticalBackgroundWork?.call(),
          committedViewport: committedViewport,
        );
        verticalSession.recordPointerSequenceEndedWithoutScroll();
        pointerArbitration.clear(event.pointer);
        onVerticalPointerIntentEnded?.call(event.pointer, cancelled: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            final committed = committedViewport;
            final visible = visibleFrames.value;
            final binding = visibleFrames.logBoxPresentationLane.value;
            final hasCommittedPresentation = _hasCommittedPresentation(
              visible: visible,
              binding: binding,
            );
            final canStart =
                notification.dragDetails != null &&
                _hasExactCommittedPresentation(
                  visible: visible,
                  binding: binding,
                  committed: committed,
                );
            if (canStart) {
              final activeVisible = visible!;
              final activeBinding = binding!;
              final activeCommitted = committed!;
              final railScene = preparedSceneCache?.railCriticalSceneFor(
                activeVisible.logBox,
              );
              if (!activeCommitted.activateVerticalRendering(
                hasExactRailScene: railScene != null,
              )) {
                return false;
              }
              final beforeDomain = _renderDomainName(
                visible: activeVisible,
                binding: activeBinding,
                committed: activeCommitted,
              );
              final contentOffset = notification.metrics.pixels
                  .clamp(0.0, double.infinity)
                  .toDouble();
              final demand = _forwardDemandSnapshot(
                committed: activeCommitted,
                contentOffset: contentOffset,
                viewportDimension: notification.metrics.viewportDimension,
              );
              final backgroundWork =
                  verticalBackgroundWork?.call() ??
                  _emptyVerticalBackgroundWork;
              final readiness = _interactionReadinessSnapshot(
                committed: activeCommitted,
                demand: demand,
              );
              final sessionStartTimestamp = DateTime.now();
              final pointerWorkMessage = verticalSession
                  .pointerToInteractionWorkMessage(
                    interactionStartedAt: sessionStartTimestamp,
                    backgroundWork: backgroundWork,
                    committedViewport: activeCommitted,
                  );
              final session = verticalSession.start(
                activeBinding,
                readiness: readiness,
                pixels: notification.metrics.pixels,
                maxScrollExtent: notification.metrics.maxScrollExtent,
                committedViewport: activeCommitted,
                backgroundWork: backgroundWork,
                performanceCounters: performanceCounters,
              );
              onVerticalScrollStarted?.call();
              final afterDomain = _renderDomainName(
                visible: activeVisible,
                binding: activeBinding,
                committed: activeCommitted,
              );
              FluviDiagnosticLogger.log(
                FluviDiagnosticEvent(
                  stage: 'VERTICAL_INTERACTION_SESSION_STARTED',
                  queryKey: activeBinding.queryKey.value,
                  coreRevision: activeBinding.coreRevision,
                  entryCount: activeCommitted.contiguousReadyRowCount,
                  message:
                      'interactionGeneration=${session.generation} '
                      'presentationEpoch=${activeBinding.presentationEpoch} '
                      'pointerDownTimestamp=${verticalSession.lastPointerDownTimestamp} '
                      'sessionStartTimestamp=${sessionStartTimestamp.toIso8601String()} '
                      'pixels=${notification.metrics.pixels.round()} '
                      'activity=drag renderDomain=$afterDomain '
                      'readyRows=${activeCommitted.contiguousReadyRowCount} '
                      'maxScrollExtent=${notification.metrics.maxScrollExtent.round()} '
                      'firstVisibleOrdinal=${readiness.firstVisibleOrdinal} '
                      'lastVisibleOrdinal=${readiness.lastVisibleOrdinal} '
                      'highestReadyOrdinal=${readiness.highestReadyOrdinal} '
                      'virtualRemainingPixels='
                      '${readiness.virtualRemainingPixels.round()} '
                      'readyDrawableAheadPixels='
                      '${readiness.readyDrawableAheadPixels.round()} '
                      'visibleMissingPageCount='
                      '${readiness.visibleResourceReadiness.visibleMissingPageCount} '
                      'firstVisibleMissingOrdinal='
                      '${readiness.visibleResourceReadiness.firstVisibleMissingOrdinal ?? 'none'} '
                      'deferredPresentationOrdinal='
                      '${backgroundWork.deferredPresentationOrdinal ?? 'none'} '
                      '$pointerWorkMessage',
                ),
              );
              if (beforeDomain != afterDomain) {
                FluviDiagnosticLogger.log(
                  FluviDiagnosticEvent(
                    stage: 'FIRST_VERTICAL_GESTURE_DOMAIN_PROMOTED',
                    queryKey: activeBinding.queryKey.value,
                    coreRevision: activeBinding.coreRevision,
                    entryCount: activeCommitted.contiguousReadyRowCount,
                    message:
                        'fromDomain=$beforeDomain toDomain=$afterDomain '
                        'readyRows=${activeCommitted.contiguousReadyRowCount} '
                        'previewRows=${activeVisible.logBox.previewRowCount} '
                        'drawableExtent=${activeCommitted.drawableExtent.round()} '
                        'pixels=${notification.metrics.pixels.round()}',
                  ),
                );
              }
              _recordLateDomainPromotionIfNeeded(
                session: session,
                visible: activeVisible,
                binding: activeBinding,
                committed: activeCommitted,
              );
              verticalSession.recordReadyAhead(
                readyFrontierOrdinal: activeCommitted.highestReadyPageOrdinal,
                lastVisibleOrdinal: demand.lastVisibleOrdinal,
                readyDrawableAheadPixels: demand.readyDrawableAheadPixels,
                virtualRemainingPixels: demand.distanceToDrawableEnd,
              );
              activeCommitted.recordScrollStarted(scrollOffset: contentOffset);
              // This is the known-good ownership split: the stable viewport
              // observes drawable position and emits one bounded target; the
              // controller remains the only serial cursor/I-O owner. Same-axis
              // drag/ballistic demand is intentionally live, not an idle repair.
              if (activeCommitted.hasMorePages) {
                onLoadNextPage(demand.desiredForwardOrdinal);
              }
            } else if (notification.dragDetails != null &&
                committed == null &&
                hasCommittedPresentation) {
              // This compatibility path is only for the lightweight viewport
              // harness used before the committed cache is attached. It still
              // creates a scope-bound user session, so it cannot turn a queued
              // old-scope update into a new-scope page demand.
              verticalSession.start(
                binding!,
                readiness: _VerticalReadinessSnapshot.unavailable(),
                pixels: notification.metrics.pixels,
              );
              onVerticalScrollStarted?.call();
              onLoadNextPage(1);
            }
            return false;
          }
          if (notification is ScrollEndNotification) {
            final committed = committedViewport;
            final visible = visibleFrames.value;
            final binding = visibleFrames.logBoxPresentationLane.value;
            if (_hasExactCommittedPresentation(
                  visible: visible,
                  binding: binding,
                  committed: committed,
                ) &&
                verticalSession.matches(binding)) {
              final activeCommitted = committed!;
              verticalSession.recordRawReleaseVelocity(
                notification.dragDetails?.velocity.pixelsPerSecond.dy,
              );
              final contentOffset = notification.metrics.pixels
                  .clamp(0.0, double.infinity)
                  .toDouble();
              final demand = _forwardDemandSnapshot(
                committed: activeCommitted,
                contentOffset: contentOffset,
                viewportDimension: notification.metrics.viewportDimension,
              );
              activeCommitted.recordScrollSummary(
                scrollOffset: contentOffset,
                firstVisibleOrdinal: demand.firstVisibleOrdinal,
                lastVisibleOrdinal: demand.lastVisibleOrdinal,
                lastPossibleOrdinal: demand.lastPossibleOrdinal,
                virtualRemainingPixels: demand.distanceToDrawableEnd,
                readyDrawableAheadPixels: demand.readyDrawableAheadPixels,
              );
              final terminalScrollEndFinalized = verticalSession
                  .recordScrollEnd(
                    binding: binding!,
                    pixels: notification.metrics.pixels,
                    readiness: _interactionReadinessSnapshot(
                      committed: activeCommitted,
                      demand: demand,
                    ),
                    minScrollExtent: notification.metrics.minScrollExtent,
                    maxScrollExtent: notification.metrics.maxScrollExtent,
                    committedViewport: activeCommitted,
                    backgroundWork:
                        verticalBackgroundWork?.call() ??
                        _emptyVerticalBackgroundWork,
                    performanceCounters: performanceCounters,
                  );
              if (terminalScrollEndFinalized) onVerticalScrollEnded?.call();
            }
            return false;
          }
          if (notification is! ScrollUpdateNotification) return false;
          final visible = visibleFrames.value;
          final committed = committedViewport;
          final binding = visibleFrames.logBoxPresentationLane.value;
          if (!_hasExactCommittedPresentation(
                visible: visible,
                binding: binding,
                committed: committed,
              ) ||
              !verticalSession.matches(binding) ||
              !(committed?.isVerticalRenderingActive ?? false)) {
            if (!verticalSession.shouldRejectUpdate(binding) ||
                !controller.position.isScrollingNotifier.value) {
              return false;
            }
            _rejectStaleVerticalUpdate(
              controller: controller,
              binding: binding,
              session: verticalSession,
            );
            return false;
          }
          {
            final activeCommitted = committed!;
            _recordLateDomainPromotionIfNeeded(
              session: verticalSession.active!,
              visible: visible!,
              binding: binding!,
              committed: activeCommitted,
            );
            final contentOffset = notification.metrics.pixels.clamp(
              0.0,
              double.infinity,
            );
            final firstPage = activeCommitted.pageOrdinalForOffset(
              contentOffset.toDouble(),
            );
            final lastPage = activeCommitted.pageOrdinalForOffset(
              contentOffset.toDouble() + notification.metrics.viewportDimension,
            );
            // The full immutable manifest, not the materialized resource bank,
            // defines the active scroll world. Retention follows the actual
            // virtual visible pages so page eviction cannot alter geometry.
            final lastVirtualOrdinal = (activeCommitted.totalPageCount - 1)
                .clamp(0, double.maxFinite)
                .toInt();
            final virtualFirstPage = firstPage
                .clamp(0, lastVirtualOrdinal)
                .toInt();
            final virtualLastPage = lastPage
                .clamp(0, lastVirtualOrdinal)
                .toInt();
            activeCommitted.updateVisibleRowWindow(
              start: activeCommitted.geometryManifest!
                  .pageForOrdinal(virtualFirstPage)!
                  .rowStart,
              end:
                  activeCommitted.geometryManifest!
                      .pageForOrdinal(virtualLastPage)!
                      .rowStart +
                  activeCommitted.geometryManifest!
                      .pageForOrdinal(virtualLastPage)!
                      .rowCount,
            );
            // Geometric proximity to the lower retained boundary is not itself
            // reverse-page intent. A previous keyset read is legal only while
            // the actual ScrollPosition moves toward lower offsets. This keeps
            // acquisition direction aligned with the cache's directional
            // retention policy and prevents a forward fling from reloading a
            // prior page that its forward hotset immediately evicts.
            final movingBackward = _isBackwardScrollUpdate(notification);
            if (movingBackward &&
                virtualFirstPage <= activeCommitted.lowestRetainedOrdinal &&
                activeCommitted.lowestRetainedOrdinal > 0) {
              onLoadPreviousPage?.call();
            }
            final demand = _forwardDemandSnapshot(
              committed: activeCommitted,
              contentOffset: contentOffset.toDouble(),
              viewportDimension: notification.metrics.viewportDimension,
              lastVisiblePage: virtualLastPage,
            );
            verticalSession.recordReadyAhead(
              readyFrontierOrdinal: activeCommitted.highestReadyPageOrdinal,
              lastVisibleOrdinal: demand.lastVisibleOrdinal,
              readyDrawableAheadPixels: demand.readyDrawableAheadPixels,
              virtualRemainingPixels: demand.distanceToDrawableEnd,
            );
            if (activeCommitted.hasMorePages) {
              onLoadNextPage(demand.desiredForwardOrdinal);
            }
          }
          return false;
        },
        child: CustomScrollView(
          key: const ValueKey('dashboard-logbox-scroll-view'),
          controller: controller,
          // The RenderViewport owns the one physical two-axis paint boundary.
          // The render surface may overscan for bounded preparation and its
          // local canonical swipe stack may translate one leased segment, but
          // neither may paint above the structural LogBox viewport.
          clipBehavior: Clip.hardEdge,
          cacheExtent: DashboardLogBoxTokens.cacheExtent,
          slivers: [
            SliverPadding(
              key: const ValueKey('dashboard-logbox-static-content-inset'),
              padding: EdgeInsets.only(left: staticContentLeftInset),
              sliver: SliverToBoxAdapter(
                child: DashboardLogBoxRenderSurface(
                  visibleFrames: visibleFrames,
                  scrollController: controller,
                  minimumHeight: terminalExtent.renderSurfaceExtent,
                  terminalBottomInset: terminalExtent.terminalBottomInset,
                  preparedRasters: preparedRasters,
                  committedViewport: committedViewport,
                  renderCriticalPayloads: renderCriticalPayloads,
                  sceneWindowProvider: sceneWindowProvider,
                  preparedSceneCache: preparedSceneCache,
                  onEntryTap: onEntryTap,
                  onAvatarTap: onAvatarTap,
                  hitTestController: hitTestController,
                  partnerSwipe: partnerSwipe,
                  onWarmupSurfaceAttached: onWarmupSurfaceAttached,
                  onWarmupSurfaceLaidOut: onWarmupSurfaceLaidOut,
                  onWarmupTextLayoutsPrepared: onWarmupTextLayoutsPrepared,
                  onWarmupError: onWarmupError,
                  onTextLayoutsPrepared: onTextLayoutsPrepared,
                  performanceCounters: performanceCounters,
                  renderDiagnostics: renderDiagnostics,
                  renderDiagnosticContextProvider:
                      renderDiagnosticContextProvider,
                  onExtentPublished: onExtentPublished,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                key: const ValueKey('dashboard-logbox-terminal-bottom-inset'),
                height: terminalExtent.terminalBottomInset,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _onPointerDown(PointerDownEvent event) {
    final bindingBefore = visibleFrames.logBoxPresentationLane.value;
    onVerticalPointerIntentStarted?.call(event.pointer);
    // Pointer timing belongs to every sequence, including an avatar tap or a
    // partner swipe. Only a confirmed vertical intent may take railPreview
    // over into committed vertical rendering.
    verticalSession.recordPointerDown(
      bindingBefore,
      backgroundWork: verticalBackgroundWork?.call(),
      committedViewport: committedViewport,
    );
    final target = partnerSwipe == null
        ? null
        : hitTestController.hitAtGlobal(event.position);
    if (target != null &&
        target.row.partnerId.isNotEmpty &&
        pointerArbitration.defer(event.pointer)) {
      return;
    }
    _beginVerticalPointerTakeover(bindingBefore);
  }

  /// Previous-page acquisition is a signed viewport-intent decision, never a
  /// side effect of merely touching the lower retention boundary.
  bool _isBackwardScrollUpdate(ScrollUpdateNotification notification) =>
      notification.scrollDelta != null && notification.scrollDelta! < 0;

  void _onPartnerSwipeVerticalIntent() {
    if (!pointerArbitration.consumeDeferred()) return;
    _beginVerticalPointerTakeover(visibleFrames.logBoxPresentationLane.value);
  }

  void _beginVerticalPointerTakeover(
    DashboardLogBoxPresentationBinding? bindingBefore,
  ) {
    // A valid current rail preview becomes committed before this pointer's
    // ScrollStartNotification. A horizontal row swipe never reaches here.
    onVerticalPointerDown?.call();
    final bindingAfter = visibleFrames.logBoxPresentationLane.value;
    if (bindingBefore?.mode == DashboardVisibleMode.preview &&
        bindingAfter?.mode != DashboardVisibleMode.committed) {
      performanceCounters?.increment(
        DashboardPerformanceMetric.freshVerticalGestureRejected,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'FRESH_VERTICAL_GESTURE_REJECTED',
          queryKey: bindingBefore?.queryKey.value,
          coreRevision: bindingBefore?.coreRevision,
          message:
              'reason=currentPreviewWasNotTakenOver '
              'beforeMode=${bindingBefore?.mode.name ?? 'none'} '
              'afterMode=${bindingAfter?.mode.name ?? 'none'} '
              'presentationEpoch=${bindingBefore?.presentationEpoch ?? 'none'}',
        ),
      );
    }
  }

  void _onPartnerSwipeAcquired(DashboardLogBoxRowHitTarget target) {
    pointerArbitration.consumeDeferred();
    final controller = partnerSwipe;
    if (controller == null || !controller.begin(target)) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'PARTNER_SWIPE_CANCELLED',
          queryKey: visibleFrames.logBoxPresentationLane.value?.queryKey.value,
          message:
              'reason=canonicalRowUnavailable entryId=${target.row.entryId}',
        ),
      );
      return;
    }
    controller.noteAcquired();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'PARTNER_SWIPE_ACQUIRED',
        queryKey: visibleFrames.logBoxPresentationLane.value?.queryKey.value,
        message:
            'entryId=${target.row.entryId} partnerId=${target.row.partnerId} '
            'blockRole=${target.blockSegmentRole.name} '
            'screenLeft=${target.globalRowBounds.left.round()} '
            'activationThreshold=${controller.state?.activationThreshold.round() ?? -1}',
      ),
    );
  }

  /// A provisional left/horizontal segment is presentation-only until the
  /// recognizer wins the arena. It gives the physical row continuous finger
  /// tracking without granting it vertical-scroll ownership or starting any
  /// focus/query work.
  void _onPartnerSwipeCandidate(DashboardLogBoxRowHitTarget target) {
    final controller = partnerSwipe;
    if (controller == null || !controller.begin(target)) return;
  }

  void _onPartnerSwipeEnded() {
    final controller = partnerSwipe;
    final row = controller?.finish();
    if (row == null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'PARTNER_SWIPE_CANCELLED',
          queryKey: visibleFrames.logBoxPresentationLane.value?.queryKey.value,
          message: 'reason=belowActivationThreshold',
        ),
      );
      return;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'PARTNER_FOCUS_REQUESTED',
        queryKey: visibleFrames.logBoxPresentationLane.value?.queryKey.value,
        message: 'entryId=${row.entryId} partnerId=${row.partnerId}',
      ),
    );
    final request = onPartnerFocus;
    if (request == null) {
      controller?.rejectFocusPublication();
      return;
    }
    unawaited(_publishPartnerFocus(request, row));
  }

  Future<void> _publishPartnerFocus(
    Future<bool> Function(DashboardLogRowViewModel row) request,
    DashboardLogRowViewModel row,
  ) async {
    final published = await request(row);
    if (published) {
      partnerSwipe?.completeFocusPublication();
    } else {
      partnerSwipe?.rejectFocusPublication();
    }
  }

  void _onPartnerSwipeCancelled() {
    partnerSwipe?.cancel();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'PARTNER_SWIPE_CANCELLED',
        queryKey: visibleFrames.logBoxPresentationLane.value?.queryKey.value,
        message: 'reason=gestureArenaCancelled',
      ),
    );
  }

  bool _hasExactCommittedPresentation({
    required DashboardVisibleFrame? visible,
    required DashboardLogBoxPresentationBinding? binding,
    required CommittedLogViewportCache? committed,
  }) =>
      _hasCommittedPresentation(visible: visible, binding: binding) &&
      committed != null &&
      committed.hasExactCommittedScope &&
      committed.hasVirtualGeometry &&
      committed.queryKey == binding?.queryKey &&
      committed.coreRevision == binding?.coreRevision;

  bool _hasCommittedPresentation({
    required DashboardVisibleFrame? visible,
    required DashboardLogBoxPresentationBinding? binding,
  }) =>
      visible?.mode == DashboardVisibleMode.committed &&
      binding?.mode == DashboardVisibleMode.committed &&
      visible?.queryKey == binding?.queryKey &&
      visible?.coreRevision == binding?.coreRevision &&
      visible?.presentationEpoch == binding?.presentationEpoch;

  String _renderDomainName({
    required DashboardVisibleFrame visible,
    required DashboardLogBoxPresentationBinding binding,
    required CommittedLogViewportCache committed,
  }) => resolveDashboardLogBoxRenderDomain(
    payload: visible.logBox,
    presentation: binding,
    committedViewport: committed,
    hasExactRailScene:
        preparedSceneCache?.railCriticalSceneFor(visible.logBox) != null,
  ).name;

  void _rejectStaleVerticalUpdate({
    required ScrollController controller,
    required DashboardLogBoxPresentationBinding? binding,
    required _VerticalInteractionSessionOwner session,
  }) {
    session.recordStaleActivityRejected(binding);
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels != position.minScrollExtent) {
      // This is synchronous in the notification turn: a residual old-scope
      // update cannot become a paintable new-sibling offset.
      controller.jumpTo(position.minScrollExtent);
    }
  }

  void _recordLateDomainPromotionIfNeeded({
    required _VerticalInteractionSession session,
    required DashboardVisibleFrame visible,
    required DashboardLogBoxPresentationBinding binding,
    required CommittedLogViewportCache committed,
  }) {
    if (committed.contiguousReadyRowCount <= visible.logBox.previewRowCount ||
        _renderDomainName(
              visible: visible,
              binding: binding,
              committed: committed,
            ) ==
            DashboardLogBoxRenderDomain.committedVertical.name ||
        !verticalSession.markPromotionLate(session)) {
      return;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_DOMAIN_PROMOTION_LATE',
        queryKey: binding.queryKey.value,
        coreRevision: binding.coreRevision,
        entryCount: committed.contiguousReadyRowCount,
        error: 'A vertical interaction retained the rail preview domain.',
        message:
            'interactionGeneration=${session.generation} '
            'readyRows=${committed.contiguousReadyRowCount} '
            'previewRows=${visible.logBox.previewRowCount} '
            'drawableExtent=${committed.drawableExtent.round()}',
      ),
    );
  }

  _CommittedVerticalDemandSnapshot _forwardDemandSnapshot({
    required CommittedLogViewportCache committed,
    required double contentOffset,
    required double viewportDimension,
    int? lastVisiblePage,
  }) {
    final lastPossible = committed.totalPageCount == 0
        ? 0
        : committed.totalPageCount - 1;
    final first = committed
        .pageOrdinalForOffset(contentOffset)
        .clamp(0, lastPossible)
        .toInt();
    final last =
        (lastVisiblePage ??
                committed.pageOrdinalForOffset(
                  contentOffset + viewportDimension,
                ))
            .clamp(0, lastPossible)
            .toInt();
    final distance =
        (committed.drawableExtent - (contentOffset + viewportDimension))
            .clamp(0.0, double.infinity)
            .toDouble();
    final readyDrawableAheadPixels =
        (committed.readyDrawableExtent - (contentOffset + viewportDimension))
            .clamp(0.0, double.infinity)
            .toDouble();
    final desired = CommittedVerticalDemandPlanner.plan(
      lastVisibleOrdinal: last,
      highestReadyOrdinal: committed.highestReadyPageOrdinal,
      currentDesiredOrdinal: committed.desiredForwardOrdinal,
      lastPossibleOrdinal: lastPossible,
      hasMorePages: committed.hasMorePages,
      distanceToDrawableEnd: distance,
      viewportDimension: viewportDimension,
    );
    return _CommittedVerticalDemandSnapshot(
      firstVisibleOrdinal: first,
      lastVisibleOrdinal: last,
      lastPossibleOrdinal: lastPossible,
      distanceToDrawableEnd: distance,
      readyDrawableAheadPixels: readyDrawableAheadPixels,
      desiredForwardOrdinal: desired,
    );
  }

  _VerticalReadinessSnapshot _interactionReadinessSnapshot({
    required CommittedLogViewportCache committed,
    required _CommittedVerticalDemandSnapshot demand,
  }) => _VerticalReadinessSnapshot(
    firstVisibleOrdinal: demand.firstVisibleOrdinal,
    lastVisibleOrdinal: demand.lastVisibleOrdinal,
    highestReadyOrdinal: committed.highestReadyPageOrdinal,
    virtualRemainingPixels: demand.distanceToDrawableEnd,
    readyDrawableAheadPixels: demand.readyDrawableAheadPixels,
    visibleResourceReadiness: committed.visibleResourceReadiness(
      firstVisibleOrdinal: demand.firstVisibleOrdinal,
      lastVisibleOrdinal: demand.lastVisibleOrdinal,
    ),
  );
}

final class _CommittedVerticalDemandSnapshot {
  const _CommittedVerticalDemandSnapshot({
    required this.firstVisibleOrdinal,
    required this.lastVisibleOrdinal,
    required this.lastPossibleOrdinal,
    required this.distanceToDrawableEnd,
    required this.readyDrawableAheadPixels,
    required this.desiredForwardOrdinal,
  });

  final int firstVisibleOrdinal;
  final int lastVisibleOrdinal;
  final int lastPossibleOrdinal;
  final double distanceToDrawableEnd;
  final double readyDrawableAheadPixels;
  final int desiredForwardOrdinal;
}

final class _VerticalReadinessSnapshot {
  _VerticalReadinessSnapshot({
    required this.firstVisibleOrdinal,
    required this.lastVisibleOrdinal,
    required this.highestReadyOrdinal,
    required this.virtualRemainingPixels,
    required this.readyDrawableAheadPixels,
    required this.visibleResourceReadiness,
  });

  factory _VerticalReadinessSnapshot.unavailable() =>
      _VerticalReadinessSnapshot(
        firstVisibleOrdinal: -1,
        lastVisibleOrdinal: -1,
        highestReadyOrdinal: -1,
        virtualRemainingPixels: 0,
        readyDrawableAheadPixels: 0,
        visibleResourceReadiness: CommittedVisibleResourceReadiness(
          logicalFirstVisibleOrdinal: -1,
          logicalLastVisibleOrdinal: -1,
          resourceReadyStartOrdinal: null,
          resourceReadyEndOrdinal: null,
          missingVisibleOrdinals: const <int>[],
        ),
      );

  final int firstVisibleOrdinal;
  final int lastVisibleOrdinal;
  final int highestReadyOrdinal;
  final double virtualRemainingPixels;
  final double readyDrawableAheadPixels;
  final CommittedVisibleResourceReadiness visibleResourceReadiness;
}
