import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_render_readiness_diagnostics.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/committed_vertical_demand_planner.dart';
import '../../logbox/application/dashboard_logbox_render_domain.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import '../../logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_logbox_presentation_binding.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_header.dart';
import 'dashboard_logbox_render_surface.dart';
import 'dashboard_logbox_prepared_scene_cache.dart';
import 'dashboard_logbox_text_layout_cache.dart';

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
    this.onVerticalScrollStarted,
    required this.preparedRasters,
    this.committedViewport,
    this.renderCriticalPayloads,
    this.sceneWindowProvider,
    this.preparedSceneCache,
    this.onEntryTap,
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
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final ValueChanged<int> onLoadNextPage;
  final VoidCallback? onLoadPreviousPage;
  final VoidCallback? onVerticalScrollStarted;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
  final ValueChanged<String>? onEntryTap;
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

  @override
  State<DashboardLogBoxViewport> createState() =>
      _DashboardLogBoxViewportState();
}

final class _DashboardLogBoxViewportState
    extends State<DashboardLogBoxViewport> {
  late final ScrollController _scrollController;
  DashboardLogBoxVisibleScopeIdentity? _lastVisibleScope;
  DashboardLogBoxPresentationBinding? _lastVisibleBinding;
  DashboardLogBoxVisibleScopeIdentity? _scopeAwaitingPayloadPaint;
  late final _VerticalInteractionSessionOwner _verticalSession;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _verticalSession = _VerticalInteractionSessionOwner();
    _lastVisibleBinding = widget.visibleFrames.logBoxPresentationLane.value;
    _lastVisibleScope = _visibleScopeFor(_lastVisibleBinding);
    widget.visibleFrames.logBoxPresentationLane.addListener(
      _onPresentationBindingChanged,
    );
    widget.visibleFrames.logBoxLane.addListener(_onLogBoxPayloadChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardLogBoxViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _scrollController.dispose();
    super.dispose();
  }

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
    final height = (MediaQuery.sizeOf(context).height - widget.bounds.top)
        .clamp(DashboardLogBoxTokens.summaryHeaderHeight, double.infinity);
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-lane-repaint-boundary'),
      child: SizedBox(
        width: widget.bounds.width,
        height: height,
        child: Stack(
          key: const ValueKey('dashboard-logbox-viewport'),
          clipBehavior: Clip.hardEdge,
          children: [
            _DashboardLogScrollArea(
              visibleFrames: widget.visibleFrames,
              controller: _scrollController,
              viewportHeight: height,
              preparedRasters: widget.preparedRasters,
              committedViewport: widget.committedViewport,
              onLoadNextPage: widget.onLoadNextPage,
              onLoadPreviousPage: widget.onLoadPreviousPage,
              onVerticalScrollStarted: widget.onVerticalScrollStarted,
              verticalSession: _verticalSession,
              renderCriticalPayloads: widget.renderCriticalPayloads,
              sceneWindowProvider: widget.sceneWindowProvider,
              preparedSceneCache: widget.preparedSceneCache,
              onEntryTap: widget.onEntryTap,
              onWarmupSurfaceAttached: widget.onWarmupSurfaceAttached,
              onWarmupSurfaceLaidOut: widget.onWarmupSurfaceLaidOut,
              onWarmupTextLayoutsPrepared: widget.onWarmupTextLayoutsPrepared,
              onWarmupError: widget.onWarmupError,
              onTextLayoutsPrepared: widget.onTextLayoutsPrepared,
              performanceCounters: widget.performanceCounters,
              renderDiagnostics: widget.renderDiagnostics,
              renderDiagnosticContextProvider:
                  widget.renderDiagnosticContextProvider,
              onExtentPublished: widget.onExtentPublished,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: DashboardLogBoxTokens.summaryHeaderHeight,
              child: DashboardLogBoxHeader(
                bounds: DashboardBounds(
                  left: 0,
                  top: 0,
                  width: widget.bounds.width,
                  height: DashboardLogBoxTokens.summaryHeaderHeight,
                ),
                visibleFrames: widget.visibleFrames,
                performanceCounters: widget.performanceCounters,
              ),
            ),
          ],
        ),
      ),
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
  bool _requiresFreshSession = false;

  _VerticalInteractionSession? get active => _active;

  bool bindingChanged(DashboardLogBoxPresentationBinding? binding) {
    final active = _active;
    return active != null && !active.matches(binding);
  }

  _VerticalInteractionSession start(
    DashboardLogBoxPresentationBinding binding,
  ) {
    final session = _VerticalInteractionSession(
      scope: _visibleScopeFor(binding)!,
      presentationEpoch: binding.presentationEpoch,
      generation: ++_generationCursor,
    );
    _active = session;
    _requiresFreshSession = false;
    _lastRejectedAgainstGeneration = null;
    return session;
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
            'queryKey=${binding?.queryKey.value ?? 'none'}',
      ),
    );
  }
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

final class _DashboardLogScrollArea extends StatelessWidget {
  const _DashboardLogScrollArea({
    required this.visibleFrames,
    required this.controller,
    required this.viewportHeight,
    required this.preparedRasters,
    required this.committedViewport,
    required this.onLoadNextPage,
    required this.onLoadPreviousPage,
    required this.onVerticalScrollStarted,
    required this.verticalSession,
    required this.renderCriticalPayloads,
    required this.sceneWindowProvider,
    required this.preparedSceneCache,
    required this.onEntryTap,
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

  final DashboardVisibleFrameStore visibleFrames;
  final ScrollController controller;
  final double viewportHeight;
  final PreparedLogBoxRasterSet preparedRasters;
  final CommittedLogViewportCache? committedViewport;
  final ValueChanged<int> onLoadNextPage;
  final VoidCallback? onLoadPreviousPage;
  final VoidCallback? onVerticalScrollStarted;
  final _VerticalInteractionSessionOwner verticalSession;
  final DashboardLogBoxCriticalPayloadProvider? renderCriticalPayloads;
  final DashboardLogBoxSceneWindow Function()? sceneWindowProvider;
  final DashboardLogBoxPreparedSceneCache? preparedSceneCache;
  final ValueChanged<String>? onEntryTap;
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
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
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
          final beforeDomain = _renderDomainName(
            visible: visible!,
            binding: binding!,
            committed: committed!,
          );
          final session = verticalSession.start(binding);
          onVerticalScrollStarted?.call();
          if (!committed.activateVerticalRendering()) return false;
          final afterDomain = _renderDomainName(
            visible: visible,
            binding: binding,
            committed: committed,
          );
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'VERTICAL_INTERACTION_SESSION_STARTED',
              queryKey: binding.queryKey.value,
              coreRevision: binding.coreRevision,
              entryCount: committed.contiguousReadyRowCount,
              message:
                  'interactionGeneration=${session.generation} '
                  'presentationEpoch=${binding.presentationEpoch} '
                  'pixels=${notification.metrics.pixels.round()} '
                  'activity=drag renderDomain=$afterDomain '
                  'readyRows=${committed.contiguousReadyRowCount} '
                  'maxScrollExtent=${notification.metrics.maxScrollExtent.round()}',
            ),
          );
          if (beforeDomain != afterDomain) {
            FluviDiagnosticLogger.log(
              FluviDiagnosticEvent(
                stage: 'FIRST_VERTICAL_GESTURE_DOMAIN_PROMOTED',
                queryKey: binding.queryKey.value,
                coreRevision: binding.coreRevision,
                entryCount: committed.contiguousReadyRowCount,
                message:
                    'fromDomain=$beforeDomain toDomain=$afterDomain '
                    'readyRows=${committed.contiguousReadyRowCount} '
                    'previewRows=${visible.logBox.flatItems.length} '
                    'drawableExtent=${committed.drawableExtent.round()} '
                    'pixels=${notification.metrics.pixels.round()}',
              ),
            );
          }
          _recordLateDomainPromotionIfNeeded(
            session: session,
            visible: visible,
            binding: binding,
            committed: committed,
          );
          final contentOffset =
              (notification.metrics.pixels -
                      DashboardLogBoxTokens.summaryHeaderHeight)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final demand = _forwardDemandSnapshot(
            committed: committed,
            contentOffset: contentOffset,
            viewportDimension: notification.metrics.viewportDimension,
          );
          committed.recordScrollStarted(scrollOffset: contentOffset);
          committed.updateForwardDemand(
            demand.desiredForwardOrdinal,
            trigger: 'scrollStart',
            firstVisibleOrdinal: demand.firstVisibleOrdinal,
            lastVisibleOrdinal: demand.lastVisibleOrdinal,
            distanceToDrawableEnd: demand.distanceToDrawableEnd,
          );
          _recordFrontierStallIfNeeded(committed, demand);
          // A scroll start is an explicit demand epoch. It is the only path
          // allowed to retry a previously failed cursor identity; ordinary
          // ScrollUpdate notifications still only advance a new target.
          if (committed.hasMorePages) {
            onLoadNextPage(committed.desiredForwardOrdinal);
          }
        } else if (notification.dragDetails != null &&
            committed == null &&
            hasCommittedPresentation) {
          // This compatibility path is only for the lightweight viewport
          // harness used before the committed cache is attached. It still
          // creates a scope-bound user session, so it cannot turn a queued
          // old-scope update into a new-scope page demand.
          verticalSession.start(binding!);
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
          final contentOffset =
              (notification.metrics.pixels -
                      DashboardLogBoxTokens.summaryHeaderHeight)
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
            distanceToDrawableEnd: demand.distanceToDrawableEnd,
          );
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
        final contentOffset =
            (notification.metrics.pixels -
                    DashboardLogBoxTokens.summaryHeaderHeight)
                .clamp(0.0, double.infinity);
        final firstPage = activeCommitted.pageOrdinalForOffset(
          contentOffset.toDouble(),
        );
        final lastPage = activeCommitted.pageOrdinalForOffset(
          contentOffset.toDouble() + notification.metrics.viewportDimension,
        );
        // Scroll metrics can temporarily project past the contiguous ready
        // geometry. Retention may only follow drawable pages; otherwise it
        // can evict the current page before the planned frontier arrives.
        final drawableFirstPage = firstPage
            .clamp(0, activeCommitted.highestReadyPageOrdinal)
            .toInt();
        final drawableLastPage = lastPage
            .clamp(0, activeCommitted.highestReadyPageOrdinal)
            .toInt();
        activeCommitted.updateVisibleRowWindow(
          start: drawableFirstPage * activeCommitted.pageSize,
          end: (drawableLastPage + 1) * activeCommitted.pageSize,
        );
        if (drawableFirstPage <= activeCommitted.lowestRetainedOrdinal &&
            activeCommitted.lowestRetainedOrdinal > 0) {
          onLoadPreviousPage?.call();
        }
        if (activeCommitted.hasMorePages) {
          // Keep the forward demand bounded relative to the actual drawable
          // viewport, rather than to an extent that may have just grown. This
          // preserves a two-page ready lookahead without allowing a fast
          // stream of ScrollUpdates to prepare and evict pages ahead of the
          // user before they can be painted.
          final demand = _forwardDemandSnapshot(
            committed: activeCommitted,
            contentOffset: contentOffset.toDouble(),
            viewportDimension: notification.metrics.viewportDimension,
            lastVisiblePage: drawableLastPage,
          );
          if (activeCommitted.updateForwardDemand(
            demand.desiredForwardOrdinal,
            trigger: 'scrollUpdate',
            firstVisibleOrdinal: demand.firstVisibleOrdinal,
            lastVisibleOrdinal: demand.lastVisibleOrdinal,
            distanceToDrawableEnd: demand.distanceToDrawableEnd,
          )) {
            onLoadNextPage(activeCommitted.desiredForwardOrdinal);
          }
          _recordFrontierStallIfNeeded(activeCommitted, demand);
        }
      }
      return false;
    },
    child: CustomScrollView(
      key: const ValueKey('dashboard-logbox-scroll-view'),
      controller: controller,
      cacheExtent: DashboardLogBoxTokens.cacheExtent,
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: DashboardLogBoxTokens.summaryHeaderHeight),
        ),
        SliverToBoxAdapter(
          child: DashboardLogBoxRenderSurface(
            visibleFrames: visibleFrames,
            scrollController: controller,
            minimumHeight:
                (viewportHeight - DashboardLogBoxTokens.summaryHeaderHeight)
                    .clamp(0, double.infinity),
            preparedRasters: preparedRasters,
            committedViewport: committedViewport,
            renderCriticalPayloads: renderCriticalPayloads,
            sceneWindowProvider: sceneWindowProvider,
            preparedSceneCache: preparedSceneCache,
            onEntryTap: onEntryTap,
            onWarmupSurfaceAttached: onWarmupSurfaceAttached,
            onWarmupSurfaceLaidOut: onWarmupSurfaceLaidOut,
            onWarmupTextLayoutsPrepared: onWarmupTextLayoutsPrepared,
            onWarmupError: onWarmupError,
            onTextLayoutsPrepared: onTextLayoutsPrepared,
            performanceCounters: performanceCounters,
            renderDiagnostics: renderDiagnostics,
            renderDiagnosticContextProvider: renderDiagnosticContextProvider,
            onExtentPublished: onExtentPublished,
          ),
        ),
      ],
    ),
  );

  bool _hasExactCommittedPresentation({
    required DashboardVisibleFrame? visible,
    required DashboardLogBoxPresentationBinding? binding,
    required CommittedLogViewportCache? committed,
  }) =>
      _hasCommittedPresentation(visible: visible, binding: binding) &&
      committed != null &&
      committed.hasExactCommittedScope &&
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
    if (committed.contiguousReadyRowCount <= visible.logBox.flatItems.length ||
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
            'previewRows=${visible.logBox.flatItems.length} '
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
    final highestReady = committed.highestReadyPageOrdinal < 0
        ? 0
        : committed.highestReadyPageOrdinal;
    final first = committed
        .pageOrdinalForOffset(contentOffset)
        .clamp(0, highestReady)
        .toInt();
    final last =
        (lastVisiblePage ??
                committed.pageOrdinalForOffset(
                  contentOffset + viewportDimension,
                ))
            .clamp(0, highestReady)
            .toInt();
    final distance =
        (committed.drawableExtent - (contentOffset + viewportDimension))
            .clamp(0.0, double.infinity)
            .toDouble();
    final lastPossible = committed.totalEntryCount == 0
        ? 0
        : (committed.totalEntryCount - 1) ~/ committed.pageSize;
    return _CommittedVerticalDemandSnapshot(
      firstVisibleOrdinal: first,
      lastVisibleOrdinal: last,
      lastPossibleOrdinal: lastPossible,
      distanceToDrawableEnd: distance,
      desiredForwardOrdinal: CommittedVerticalDemandPlanner.plan(
        lastVisibleOrdinal: last,
        highestReadyOrdinal: committed.highestReadyPageOrdinal,
        currentDesiredOrdinal: committed.desiredForwardOrdinal,
        lastPossibleOrdinal: lastPossible,
        hasMorePages: committed.hasMorePages,
        distanceToDrawableEnd: distance,
        viewportDimension: viewportDimension,
      ),
    );
  }

  void _recordFrontierStallIfNeeded(
    CommittedLogViewportCache committed,
    _CommittedVerticalDemandSnapshot demand,
  ) {
    if (committed.hasMorePages &&
        demand.distanceToDrawableEnd <= 1 &&
        demand.desiredForwardOrdinal <= committed.highestReadyPageOrdinal) {
      committed.recordFrontierStall(
        firstVisibleOrdinal: demand.firstVisibleOrdinal,
        lastVisibleOrdinal: demand.lastVisibleOrdinal,
        distanceToDrawableEnd: demand.distanceToDrawableEnd,
      );
    }
  }
}

final class _CommittedVerticalDemandSnapshot {
  const _CommittedVerticalDemandSnapshot({
    required this.firstVisibleOrdinal,
    required this.lastVisibleOrdinal,
    required this.lastPossibleOrdinal,
    required this.distanceToDrawableEnd,
    required this.desiredForwardOrdinal,
  });

  final int firstVisibleOrdinal;
  final int lastVisibleOrdinal;
  final int lastPossibleOrdinal;
  final double distanceToDrawableEnd;
  final int desiredForwardOrdinal;
}
