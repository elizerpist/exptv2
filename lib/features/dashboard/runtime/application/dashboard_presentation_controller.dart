import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import '../../motion/dashboard_display_frame_coalescer.dart';
import '../../motion/dashboard_motion_kernel.dart';
import '../../motion/dashboard_motion_state.dart';
import '../../motion/dashboard_semantic_catalog.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../domain/prepared_dashboard_index.dart';

typedef DashboardPreparedFrameSelected =
    void Function(DashboardVisibleFrame frame, int selectorMicros);
typedef DashboardPresentationApplyStarted =
    void Function(DashboardVisibleFrame frame);
typedef DashboardPresentationApplyCompleted =
    void Function(
      DashboardVisibleFrame frame,
      int applyMicros,
      DashboardVisibleFramePublishMetrics publishMetrics,
    );

@immutable
final class DashboardCommittedState {
  const DashboardCommittedState({
    required this.committedScope,
    required this.committedQueryKey,
    required this.committedRevision,
    required this.committedEpoch,
    required this.commitGeneration,
  });

  const DashboardCommittedState.empty()
    : committedScope = null,
      committedQueryKey = null,
      committedRevision = null,
      committedEpoch = 0,
      commitGeneration = 0;

  final CurrentLedgerQueryScope? committedScope;
  final LedgerQueryKey? committedQueryKey;
  final int? committedRevision;
  final int committedEpoch;
  final int commitGeneration;
}

/// Synchronous RAM-only owner of dashboard navigation and visible selection.
///
/// This module deliberately has no repository, channel, SQL, stream or index
/// builder dependency. Its only data capability is an already complete
/// [PreparedDashboardIndex].
final class DashboardPresentationController {
  DashboardPresentationController({
    DateTime? initialDate,
    TimePlane initialPlane = TimePlane.month,
    bool initialRailOpen = false,
    LedgerDirection initialDirection = LedgerDirection.income,
    int initialCoreRevision = 0,
    DashboardDisplayFrameScheduler? displayFrameScheduler,
    this.onMotionActiveChanged,
    this.onCommittedFrame,
    this.onSemanticCrossed,
    this.onSettled,
    this.onBallisticStarted,
    this.onPreparedFrameSelected,
    this.onPresentationApplyStarted,
    this.onPresentationApplyCompleted,
    this.onRailCanonicalCenterMismatch,
    DashboardTemporalAnchorChanged? onTemporalAnchorChanged,
    DashboardPlaneTargetDerived? onPlaneTargetDerived,
  }) : navigation = DashboardNavigationController(
         initialDate: initialDate,
         initialPlane: initialPlane,
         initialRailOpen: initialRailOpen,
         initialDirection: initialDirection,
         initialCoreRevision: initialCoreRevision,
         onTemporalAnchorChanged: onTemporalAnchorChanged,
         onPlaneTargetDerived: onPlaneTargetDerived,
       ),
       visibleFrames = DashboardVisibleFrameStore() {
    final initialCatalog = _catalogForUnprepared(navigation.state);
    motion = DashboardMotionKernel(
      catalog: initialCatalog,
      initialLogicalIndex: navigation.selectedChildLogicalIndex,
    );
    frameCoalescer = DashboardDisplayFrameCoalescer(
      scheduler:
          displayFrameScheduler ?? FlutterDashboardDisplayFrameScheduler(),
      publish: _publishCoalescedFrame,
    );
    motion.setCallbacks(
      onSemanticCrossed: _onSemanticCrossed,
      onSettled: _onSettled,
      onBallisticStarted: onBallisticStarted,
    );
  }

  final DashboardNavigationController navigation;
  late final DashboardMotionKernel motion;
  final DashboardVisibleFrameStore visibleFrames;
  late final DashboardDisplayFrameCoalescer frameCoalescer;
  final ValueChanged<bool>? onMotionActiveChanged;
  final ValueChanged<DashboardVisibleFrame>? onCommittedFrame;
  final DashboardSemanticCrossing? onSemanticCrossed;
  final DashboardMotionSettle? onSettled;
  final DashboardBallisticStart? onBallisticStarted;
  final DashboardPreparedFrameSelected? onPreparedFrameSelected;
  final DashboardPresentationApplyStarted? onPresentationApplyStarted;
  final DashboardPresentationApplyCompleted? onPresentationApplyCompleted;
  final VoidCallback? onRailCanonicalCenterMismatch;

  PreparedDashboardIndex? _index;
  DashboardCommittedState _committedState =
      const DashboardCommittedState.empty();
  _PendingMetadataCommit? _pendingCommit;
  int _presentationEpoch = 0;
  bool _motionActive = false;
  bool _disposed = false;
  int railCanonicalCenterMismatchCount = 0;

  PreparedDashboardIndex? get index => _index;
  DashboardCommittedState get committedState => _committedState;
  LedgerQueryKey? get expectedVisibleQueryKey {
    final installed = _index;
    if (installed == null) return null;
    final state = navigation.state;
    if (!state.isRailOpen) return state.parentQueryKey;
    final catalog = installed.catalogForKey(state.parentQueryKey);
    return catalog.entryAtLogicalIndex(_selectedIndex(state, catalog)).queryKey;
  }

  DashboardVisibleFrame installIndex(
    PreparedDashboardIndex index, {
    bool publishImmediately = false,
  }) {
    if (_disposed) throw StateError('Dashboard presentation is disposed.');
    final current = _index;
    if (current != null && index.coreRevision < current.coreRevision) {
      throw StateError('A stale prepared index cannot be installed.');
    }
    _index = index;
    _presentationEpoch += 1;
    _pendingCommit = null;
    final state = navigation.state;
    final catalog = index.catalogForKey(state.parentQueryKey);
    _installCatalog(
      catalog,
      selectedLogicalIndex: _selectedIndex(state, catalog),
      policy: DashboardSemanticInstallPolicy.reconcileCanonicalSelection,
      reason: 'revisionActivation',
    );
    final frame = _visibleFor(state, mode: DashboardVisibleMode.committed);
    if (publishImmediately) {
      _publishCoalescedFrame(frame);
    } else {
      frameCoalescer.request(frame);
    }
    return frame;
  }

  void setRailOpen(bool open) {
    if (open == navigation.state.isRailOpen) return;
    navigation.setRailOpen(open, coreRevision: _index?.coreRevision);
    _selectStructuralTarget();
  }

  void navigateParent(DashboardTimeNavigationChangeDirection direction) {
    final target = parentCandidate(direction);
    if (target == null) return;
    navigation.commitParentCandidate(target, direction);
    _selectStructuralTarget();
  }

  DashboardNavigationState? parentCandidate(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final candidate = navigation.parentCursorCandidate(
      direction,
      coreRevision: _index?.coreRevision,
    );
    if (candidate == null) return null;
    return _canonicalCandidate(candidate);
  }

  void navigatePlane({required bool finer}) {
    final candidate = navigation.planeCursorCandidate(
      finer: finer,
      coreRevision: _index?.coreRevision,
    );
    navigation.commitPlaneCandidate(
      _requireCanonicalCandidate(candidate),
      finer: finer,
    );
    _selectStructuralTarget();
  }

  void selectDirection(LedgerDirection direction) {
    if (direction == navigation.state.parentQueryScope.direction) return;
    navigation.commitDirectionCandidate(
      _requireCanonicalCandidate(
        navigation.directionCandidate(
          direction,
          coreRevision: _index?.coreRevision,
        ),
        direction: direction,
      ),
    );
    _selectStructuralTarget();
  }

  DashboardNavigationState? _canonicalCandidate(
    DashboardNavigationState candidate, {
    LedgerDirection? direction,
  }) {
    final installed = _index;
    if (installed == null) return null;
    final timeScope = switch (candidate.plane) {
      TimePlane.sum => const AllTimeScope(),
      TimePlane.year => YearScope(candidate.yearCursor),
      TimePlane.month => MonthScope(candidate.monthCursor),
    };
    final catalog = installed.catalogForIdentity(
      direction: direction ?? candidate.parentQueryScope.direction,
      timeScope: timeScope,
    );
    if (catalog == null) return null;
    return candidate.copyWith(parentQueryScope: catalog.parentScope);
  }

  DashboardNavigationState _requireCanonicalCandidate(
    DashboardNavigationState candidate, {
    LedgerDirection? direction,
  }) =>
      _canonicalCandidate(candidate, direction: direction) ??
      (throw StateError('Prepared index has no structural target catalog.'));

  void _selectStructuralTarget() {
    final installed = _requireIndex();
    _presentationEpoch += 1;
    _pendingCommit = null;
    final state = navigation.state;
    final catalog = installed.catalogForKey(state.parentQueryKey);
    final policy = _semanticInstallPolicyFor(state);
    _installCatalog(
      catalog,
      selectedLogicalIndex: _selectedIndex(state, catalog),
      policy: policy,
      reason: state.lastChange.kind.name,
    );
    frameCoalescer.request(
      _visibleFor(state, mode: DashboardVisibleMode.committed),
    );
  }

  void beginRailMotion(CenteredCarouselMotionOrigin origin) {
    _pendingCommit = null;
    _setMotionActive(true);
    if (origin == CenteredCarouselMotionOrigin.userDrag) {
      motion.beginGesture();
    } else {
      motion.beginProgrammaticMotion();
    }
  }

  void semanticCrossed(int logicalIndex) =>
      motion.semanticCrossed(logicalIndex);

  void settleRail(int logicalIndex) => motion.settled(logicalIndex);

  void _onSemanticCrossed(
    DashboardSemanticEntry entry,
    DashboardMotionContext context,
  ) {
    onSemanticCrossed?.call(entry, context);
    final selectionObserver = onPreparedFrameSelected;
    final selectionStart = selectionObserver == null
        ? 0
        : developer.Timeline.now;
    final installed = _requireIndex();
    final state = navigation.state;
    if (!state.isRailOpen ||
        motion.catalog.parentScope.key != state.parentQueryKey ||
        motion.catalog.entryAtLogicalIndex(entry.logicalIndex).queryKey !=
            entry.queryKey) {
      return;
    }
    final prepared = installed.frameForKey(entry.queryKey);
    final frame = DashboardVisibleFrame.fromPrepared(
      prepared,
      parentQueryKey: state.parentQueryKey,
      plane: state.plane,
      railOpen: true,
      semanticIndex: entry.logicalIndex,
      childLabel: entry.label,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
      frameGeneration: visibleFrames.nextFrameGeneration(),
      mode: DashboardVisibleMode.preview,
    );
    frameCoalescer.request(frame);
    if (selectionObserver != null) {
      selectionObserver(frame, developer.Timeline.now - selectionStart);
    }
  }

  void _onSettled(
    DashboardSemanticEntry entry,
    DashboardMotionContext context,
  ) {
    _setMotionActive(false);
    final state = navigation.state;
    if (!state.isRailOpen ||
        motion.catalog.entryForQueryKey(entry.queryKey) == null) {
      return;
    }
    if (!navigation.retainSettledChild(
      value: entry.value,
      expectedNavigationEpoch: state.navigationEpoch,
      childQueryKey: entry.queryKey,
      coreRevision: _index?.coreRevision,
    )) {
      return;
    }
    _pendingCommit = _PendingMetadataCommit(
      queryKey: entry.queryKey,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
    );
    _promotePendingCommit();
    onSettled?.call(entry, context);
  }

  /// Synchronously transfers a valid rail preview to vertical ownership.
  ///
  /// This transaction intentionally changes only canonical metadata and the
  /// visible frame's render-domain flag. Its immutable LogBox payload is
  /// neither queried nor rebound, so the pointer-down path contains no I/O,
  /// text layout, scene preparation, wait, or synthetic rail settle.
  bool takeOverVisibleRailPreviewForVerticalInput() {
    final installed = _index;
    final visible = visibleFrames.value;
    final state = navigation.state;
    if (installed == null ||
        visible == null ||
        !state.isRailOpen ||
        visible.mode != DashboardVisibleMode.preview ||
        visible.coreRevision != installed.coreRevision ||
        visible.parentQueryKey != state.parentQueryKey ||
        visible.navigationEpoch != state.navigationEpoch ||
        visible.presentationEpoch != _presentationEpoch ||
        motion.catalog.parentScope.key != state.parentQueryKey ||
        motion.state.semanticIndex != visible.semanticChildIndex) {
      return false;
    }
    final entry = motion.catalog.entryAtLogicalIndex(
      visible.semanticChildIndex,
    );
    if (entry.queryKey != visible.queryKey ||
        entry.logicalIndex != visible.semanticChildIndex) {
      return false;
    }

    // Order is deliberate: the vertical paging gate observes rail inactivity
    // before it receives committed page-zero metadata for this exact child.
    motion.reconcileCanonicalSelection(entry.logicalIndex);
    _setMotionActive(false);
    if (!navigation.retainChild(
      value: entry.value,
      expectedNavigationEpoch: state.navigationEpoch,
      childQueryKey: entry.queryKey,
      coreRevision: installed.coreRevision,
      reason: DashboardRetainedChildReason.verticalInputTakeover,
    )) {
      return false;
    }
    if (!visibleFrames.promoteCommitted(
      expectedKey: entry.queryKey,
      epoch: visible.presentationEpoch,
    )) {
      return false;
    }
    final committed = visibleFrames.value;
    if (committed == null ||
        committed.mode != DashboardVisibleMode.committed ||
        committed.queryKey != entry.queryKey ||
        committed.presentationEpoch != visible.presentationEpoch) {
      return false;
    }
    _commitMetadata(committed);
    return true;
  }

  void _publishCoalescedFrame(DashboardVisibleFrame frame) {
    final applyObserver = onPresentationApplyCompleted;
    onPresentationApplyStarted?.call(frame);
    final applyStart = applyObserver == null ? 0 : developer.Timeline.now;
    DashboardVisibleFramePublishMetrics? publishMetrics;
    final published = visibleFrames.publish(
      frame,
      onMeasured: applyObserver == null
          ? null
          : (metrics) => publishMetrics = metrics,
    );
    if (applyObserver != null) {
      applyObserver(
        frame,
        developer.Timeline.now - applyStart,
        publishMetrics ??
            DashboardVisibleFramePublishMetrics(
              published: published,
              equalityMicros: 0,
              notifierMicros: 0,
            ),
      );
    }
    _promotePendingCommit();
    final current = visibleFrames.value;
    if (frame.mode == DashboardVisibleMode.committed &&
        identical(current, frame)) {
      _commitMetadata(frame);
    } else if (!published && current?.mode == DashboardVisibleMode.committed) {
      _commitMetadata(current!);
    }
  }

  void _promotePendingCommit() {
    final pending = _pendingCommit;
    final visible = visibleFrames.value;
    if (pending == null ||
        visible == null ||
        visible.queryKey != pending.queryKey ||
        visible.navigationEpoch != pending.navigationEpoch ||
        visible.presentationEpoch != pending.presentationEpoch) {
      return;
    }
    _pendingCommit = null;
    visibleFrames.promoteCommitted(
      expectedKey: pending.queryKey,
      epoch: pending.presentationEpoch,
    );
    final committed = visibleFrames.value;
    if (committed?.mode == DashboardVisibleMode.committed) {
      _commitMetadata(committed!);
    }
  }

  void _commitMetadata(DashboardVisibleFrame frame) {
    final current = _committedState;
    if (current.committedQueryKey == frame.queryKey &&
        current.committedRevision == frame.coreRevision &&
        current.committedEpoch == frame.presentationEpoch) {
      return;
    }
    _committedState = DashboardCommittedState(
      committedScope: frame.scope,
      committedQueryKey: frame.queryKey,
      committedRevision: frame.coreRevision,
      committedEpoch: frame.presentationEpoch,
      commitGeneration: current.commitGeneration + 1,
    );
    onCommittedFrame?.call(frame);
  }

  DashboardSemanticInstallPolicy _semanticInstallPolicyFor(
    DashboardNavigationState state,
  ) {
    final kind = state.lastChange.kind;
    if (!state.isRailOpen ||
        kind == DashboardTimeNavigationChangeKind.rail ||
        kind == DashboardTimeNavigationChangeKind.plane) {
      return DashboardSemanticInstallPolicy.reconcileCanonicalSelection;
    }
    return switch (kind) {
      DashboardTimeNavigationChangeKind.parentWhileRailOpen ||
      DashboardTimeNavigationChangeKind.direction =>
        DashboardSemanticInstallPolicy.preservePhysicalContinuity,
      _ => DashboardSemanticInstallPolicy.reconcileCanonicalSelection,
    };
  }

  void _installCatalog(
    DashboardSemanticCatalog catalog, {
    required int selectedLogicalIndex,
    required DashboardSemanticInstallPolicy policy,
    required String reason,
  }) {
    final carousel = motion.carouselController;
    final oldSelectedLogicalIndex = carousel.selectedLogicalIndex;
    final oldCenteredLogicalIndex = carousel.logicalIndexForPhysical(
      carousel.rawCenteredIndex.round(),
    );
    final oldPixels = carousel.scrollController.hasClients
        ? carousel.scrollController.position.pixels
        : 0.0;
    final oldActivity = motion.state.activity.name;
    final controllerIdentity = identityHashCode(carousel);
    final positionIdentity = carousel.scrollController.hasClients
        ? identityHashCode(carousel.scrollController.position)
        : 0;
    final physicsIdentity = identityHashCode(motion.dashboardPhysics);

    motion.installCatalog(
      catalog,
      selectedLogicalIndex: selectedLogicalIndex,
      policy: policy,
    );
    if (policy != DashboardSemanticInstallPolicy.reconcileCanonicalSelection) {
      return;
    }

    _setMotionActive(false);
    final newCenteredLogicalIndex = carousel.logicalIndexForPhysical(
      carousel.rawCenteredIndex.round(),
    );
    final newPixels = carousel.scrollController.hasClients
        ? carousel.scrollController.position.pixels
        : 0.0;
    final expectedLogicalIndex = catalog
        .entryAtLogicalIndex(selectedLogicalIndex)
        .logicalIndex;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'RAIL_CANONICAL_SELECTION_RECONCILED',
        queryKey: catalog
            .entryAtLogicalIndex(expectedLogicalIndex)
            .queryKey
            .value,
        coreRevision: _index?.coreRevision,
        message:
            'reason=$reason navEpoch=${navigation.state.navigationEpoch} '
            'presentationEpoch=$_presentationEpoch '
            'canonicalSemanticIndex=$expectedLogicalIndex '
            'oldSelectedLogicalIndex=$oldSelectedLogicalIndex '
            'oldCenteredLogicalIndex=$oldCenteredLogicalIndex '
            'newSelectedLogicalIndex=${carousel.selectedLogicalIndex} '
            'newCenteredLogicalIndex=$newCenteredLogicalIndex '
            'oldPixels=${oldPixels.round()} newPixels=${newPixels.round()} '
            'oldActivity=$oldActivity newActivity=${motion.state.activity.name} '
            'controllerIdentity=$controllerIdentity '
            'positionIdentity=$positionIdentity '
            'physicsIdentity=$physicsIdentity',
      ),
    );
    if (newCenteredLogicalIndex != expectedLogicalIndex ||
        motion.state.semanticIndex != expectedLogicalIndex ||
        carousel.selectedLogicalIndex != expectedLogicalIndex) {
      railCanonicalCenterMismatchCount += 1;
      onRailCanonicalCenterMismatch?.call();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'RAIL_CANONICAL_CENTER_MISMATCH',
          queryKey: catalog
              .entryAtLogicalIndex(expectedLogicalIndex)
              .queryKey
              .value,
          coreRevision: _index?.coreRevision,
          message:
              'expected=$expectedLogicalIndex centered=$newCenteredLogicalIndex '
              'semantic=${motion.state.semanticIndex} '
              'selected=${carousel.selectedLogicalIndex}',
        ),
      );
    }
  }

  DashboardVisibleFrame _visibleFor(
    DashboardNavigationState state, {
    required DashboardVisibleMode mode,
  }) {
    final installed = _requireIndex();
    final catalog = installed.catalogForKey(state.parentQueryKey);
    final selectedIndex = _selectedIndex(state, catalog);
    final selectedEntry = catalog.entryAtLogicalIndex(selectedIndex);
    final queryKey = state.isRailOpen
        ? selectedEntry.queryKey
        : state.parentQueryKey;
    return DashboardVisibleFrame.fromPrepared(
      installed.frameForKey(queryKey),
      parentQueryKey: state.parentQueryKey,
      plane: state.plane,
      railOpen: state.isRailOpen,
      semanticIndex: selectedIndex,
      childLabel: selectedEntry.label,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
      frameGeneration: visibleFrames.nextFrameGeneration(),
      mode: mode,
    );
  }

  PreparedDashboardIndex _requireIndex() =>
      _index ?? (throw StateError('No prepared dashboard index is installed.'));

  static int _selectedIndex(
    DashboardNavigationState state,
    DashboardSemanticCatalog catalog,
  ) => catalog.logicalIndexForValue(state.retainedSemanticChild);

  static DashboardSemanticCatalog _catalogForUnprepared(
    DashboardNavigationState state,
  ) => DashboardSemanticCatalog.forParent(
    parentScope: state.parentQueryScope,
    childKind: switch (state.plane) {
      TimePlane.sum => DashboardChildKind.year,
      TimePlane.year => DashboardChildKind.month,
      TimePlane.month => DashboardChildKind.day,
    },
    retainedYear: state.retainedChildYear,
  );

  void _setMotionActive(bool active) {
    if (_motionActive == active) return;
    _motionActive = active;
    onMotionActiveChanged?.call(active);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    motion.dispose();
    visibleFrames.dispose();
    navigation.dispose();
  }
}

final class _PendingMetadataCommit {
  const _PendingMetadataCommit({
    required this.queryKey,
    required this.navigationEpoch,
    required this.presentationEpoch,
  });

  final LedgerQueryKey queryKey;
  final int navigationEpoch;
  final int presentationEpoch;
}
