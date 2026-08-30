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
import '../../time_navigation/domain/dashboard_temporal_availability.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../domain/prepared_dashboard_index.dart';
import '../domain/prepared_presentation_frame.dart';

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
    // Index installation occurs only after the controller has built the exact
    // structural/interaction scene requirement.  Make its compact zero frame
    // concrete here before presentation selects it; subsequent rail
    // crossings use [frameForKey] and cannot allocate a viewport.
    final catalogForPreparation = index.catalogForKey(state.parentQueryKey);
    index.materializeFrameForPreparation(state.parentQueryKey);
    if (state.isRailOpen) {
      index.materializeFrameForPreparation(
        catalogForPreparation
            .entryAtLogicalIndex(_selectedIndex(state, catalogForPreparation))
            .queryKey,
      );
    }
    final catalog = catalogForPreparation;
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
    if (!open) retainVisibleRailChildForStructuralExit();
    commitRailVisibilityCandidate(railVisibilityCandidate(open));
  }

  DashboardNavigationState railVisibilityCandidate(bool open) =>
      _requireCanonicalCandidate(
        navigation.railVisibilityCandidate(
          open,
          coreRevision: _index?.coreRevision,
        ),
      );

  void commitRailVisibilityCandidate(DashboardNavigationState candidate) {
    navigation.commitRailVisibilityCandidate(candidate);
    _selectStructuralTarget();
  }

  void navigateParent(DashboardTimeNavigationChangeDirection direction) {
    final target = parentCandidate(direction);
    if (target == null) return;
    commitParentCandidate(target, direction);
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

  /// Canonical read-only target for the primary mother's settled offset.
  DashboardNavigationState? parentOffsetCandidate(int offset) {
    final candidate = navigation.parentOffsetCandidate(
      offset,
      coreRevision: _index?.coreRevision,
    );
    if (candidate == null) return null;
    return _canonicalCandidate(candidate);
  }

  void commitParentCandidate(
    DashboardNavigationState candidate,
    DashboardTimeNavigationChangeDirection direction,
  ) {
    navigation.commitParentCandidate(candidate, direction);
    _selectStructuralTarget();
  }

  void navigatePlane({required bool finer}) {
    commitPlaneCandidate(planeCandidate(finer: finer), finer: finer);
  }

  DashboardNavigationState planeCandidate({required bool finer}) {
    retainVisibleRailChildForStructuralExit();
    return _requireCanonicalCandidate(
      navigation.planeCursorCandidate(
        finer: finer,
        coreRevision: _index?.coreRevision,
      ),
    );
  }

  /// Canonical read-only target for the settled primary-axis item.
  DashboardNavigationState planeTargetCandidate(TimePlane target) {
    retainVisibleRailChildForStructuralExit();
    return _requireCanonicalCandidate(
      navigation.planeTargetCandidate(
        target,
        coreRevision: _index?.coreRevision,
      ),
    );
  }

  /// Canonical candidate for a fixed experimental SummaryPill hierarchy.
  /// This stays inside the same prepared-index/catalog boundary as legacy
  /// plane and rail navigation.
  DashboardNavigationState temporalCandidate({
    required TimePlane plane,
    required bool isRailOpen,
  }) {
    retainVisibleRailChildForStructuralExit();
    return _requireCanonicalCandidate(
      navigation.temporalCandidate(
        plane: plane,
        isRailOpen: isRailOpen,
        coreRevision: _index?.coreRevision,
      ),
    );
  }

  /// Reads one availability-aware existing Y-M-D coordinate target without
  /// publishing it. The presentation widget uses this only at a discrete
  /// carousel crossing, never for per-pixel animation work.
  DashboardNavigationState? temporalComponentOffsetCandidate({
    required TimePlane plane,
    required bool isRailOpen,
    required DashboardTemporalAnchorComponent component,
    required int offset,
    DashboardNavigationState? base,
  }) {
    final candidate = navigation.temporalComponentOffsetCandidate(
      plane: plane,
      isRailOpen: isRailOpen,
      component: component,
      offset: offset,
      base: base,
      coreRevision: _index?.coreRevision,
    );
    return candidate == null ? null : _canonicalCandidate(candidate);
  }

  void commitPlaneCandidate(
    DashboardNavigationState candidate, {
    required bool finer,
  }) {
    navigation.commitPlaneCandidate(candidate, finer: finer);
    _selectStructuralTarget();
  }

  void commitPlaneTargetCandidate(
    DashboardNavigationState candidate, {
    required bool finer,
  }) {
    navigation.commitPlaneTargetCandidate(candidate, finer: finer);
    _selectStructuralTarget();
  }

  void commitTemporalCandidate(DashboardNavigationState candidate) {
    navigation.commitTemporalCandidate(candidate);
    _selectStructuralTarget();
  }

  /// General prepared-frame publication for a Segmented Summary component
  /// crossing. YEAR/MONTH/DAY share this exact foreground contract whenever
  /// the candidate's frame is already materialized. It deliberately performs
  /// no compact-frame materialization, scene-window preparation, query, text
  /// work or settle wait; a strict miss returns false for the existing
  /// fail-closed structural path.
  bool publishPreparedExperimentalTemporalCandidate(
    DashboardNavigationState candidate,
  ) {
    final installed = _index;
    if (installed == null) return false;
    final candidateQueryKey = candidate.isRailOpen
        ? candidate.temporalAnchor.sourceChildQueryKey
        : candidate.parentQueryKey;
    final catalog = installed.catalogForKey(candidate.parentQueryKey);
    final candidateSemanticIndex = _selectedIndex(candidate, catalog);
    final candidateEntry = catalog.entryAtLogicalIndex(candidateSemanticIndex);
    final resolvedCandidateQueryKey = candidate.isRailOpen
        ? candidateEntry.queryKey
        : candidate.parentQueryKey;
    // Validate all canonical target relations before mutating navigation. A
    // failed strict lookup must remain a genuinely fail-closed structural
    // fallback, never a half-committed candidate.
    if (resolvedCandidateQueryKey != candidateQueryKey) return false;
    late final DashboardPreparedFrame prepared;
    try {
      prepared = installed.frameForKey(candidateQueryKey);
    } on StateError {
      return false;
    }
    navigation.commitTemporalCandidate(candidate);
    final state = navigation.state;
    final semanticIndex = _selectedIndex(state, catalog);
    final selectedEntry = catalog.entryAtLogicalIndex(semanticIndex);
    final queryKey = state.isRailOpen
        ? selectedEntry.queryKey
        : state.parentQueryKey;
    // The pre-commit validation and canonical commit must refer to one target.
    // This is defensive only: a mismatch would be an internal invariant
    // violation, not a reason to route a partially committed state through
    // structural navigation.
    assert(queryKey == candidateQueryKey && prepared.queryKey == queryKey);
    _presentationEpoch += 1;
    _pendingCommit = null;
    // Day's old direct path intentionally left the existing child carousel
    // intact. Parent candidates need only a catalog reconciliation; this is
    // synchronous metadata and cannot materialize a scene.
    if (!state.isRailOpen) {
      _installCatalog(
        catalog,
        selectedLogicalIndex: semanticIndex,
        policy: _semanticInstallPolicyFor(state),
        reason: 'experimentalPreparedTemporal',
      );
    }
    frameCoalescer.request(
      DashboardVisibleFrame.fromPrepared(
        prepared,
        parentQueryKey: state.parentQueryKey,
        plane: state.plane,
        railOpen: state.isRailOpen,
        semanticIndex: semanticIndex,
        childLabel: selectedEntry.label,
        navigationEpoch: state.navigationEpoch,
        presentationEpoch: _presentationEpoch,
        frameGeneration: visibleFrames.nextFrameGeneration(),
        mode: DashboardVisibleMode.committed,
      ),
    );
    return true;
  }

  /// Compatibility entrypoint for the original DAY-only fast path. Keeping
  /// it as a delegate prevents two independent prepared-publication lanes.
  bool publishPreparedExperimentalChild(DashboardNavigationState candidate) {
    final state = navigation.state;
    return state.isRailOpen &&
        candidate.isRailOpen &&
        state.plane == TimePlane.month &&
        candidate.plane == TimePlane.month &&
        state.parentQueryKey == candidate.parentQueryKey &&
        publishPreparedExperimentalTemporalCandidate(candidate);
  }

  /// Sends the already-derived scalar amount for an ephemeral focus target to
  /// the SummaryPill without waiting for the target LogBox scene window. The
  /// complete visible frame remains scene-atomic; this is deliberately only
  /// the prepared amount leaf used by the Budget avatar preview path.
  bool publishPreparedFocusAmountPreview({
    required PreparedDashboardIndex index,
    required DashboardNavigationState state,
    required int previewGeneration,
  }) {
    final catalog = index.catalogForKey(state.parentQueryKey);
    final selectedIndex = _selectedIndex(state, catalog);
    final selectedEntry = catalog.entryAtLogicalIndex(selectedIndex);
    final queryKey = state.isRailOpen
        ? selectedEntry.queryKey
        : state.parentQueryKey;
    final frame = DashboardVisibleFrame.fromPrepared(
      // This is the compact prepared presentation frame assembled during the
      // focus derivation. It does not prepare a scene or perform text layout.
      index.materializeFrameForPreparation(queryKey),
      parentQueryKey: state.parentQueryKey,
      plane: state.plane,
      railOpen: state.isRailOpen,
      semanticIndex: selectedIndex,
      childLabel: selectedEntry.label,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
      frameGeneration: visibleFrames.nextFrameGeneration(),
      mode: DashboardVisibleMode.preview,
    );
    return visibleFrames.publishPreparedAmountPreview(
      frame,
      previewGeneration: previewGeneration,
    );
  }

  /// Stages an exact prepared filter preview into amount/count/LogBox lanes
  /// without replacing the installed index, navigation, or committed frame.
  bool publishPreparedInteractionPreview({
    required PreparedDashboardIndex index,
    required DashboardNavigationState state,
    required int previewGeneration,
  }) {
    final catalog = index.catalogForKey(state.parentQueryKey);
    final selectedIndex = _selectedIndex(state, catalog);
    final selectedEntry = catalog.entryAtLogicalIndex(selectedIndex);
    final queryKey = state.isRailOpen
        ? selectedEntry.queryKey
        : state.parentQueryKey;
    final frame = DashboardVisibleFrame.fromPrepared(
      index.materializeFrameForPreparation(queryKey),
      parentQueryKey: state.parentQueryKey,
      plane: state.plane,
      railOpen: state.isRailOpen,
      semanticIndex: selectedIndex,
      childLabel: selectedEntry.label,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
      frameGeneration: visibleFrames.nextFrameGeneration(),
      mode: DashboardVisibleMode.preview,
    );
    return visibleFrames.publishPreparedInteractionPreview(
      frame,
      previewGeneration: previewGeneration,
    );
  }

  void selectDirection(LedgerDirection direction) {
    if (direction == navigation.state.parentQueryScope.direction) return;
    commitDirectionCandidate(directionCandidate(direction));
  }

  DashboardNavigationState directionCandidate(
    LedgerDirection direction, {
    CurrentLedgerQueryScope? template,
    DashboardTemporalAvailability? availability,
  }) => _requireCanonicalCandidate(
    navigation.directionCandidate(
      direction,
      template: template,
      availability: availability,
      coreRevision: _index?.coreRevision,
    ),
    direction: direction,
  );

  void commitDirectionCandidate(
    DashboardNavigationState candidate, {
    DashboardTemporalAvailability? availability,
  }) {
    navigation.commitDirectionCandidate(candidate, availability: availability);
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
    // This method is a committed structural publication boundary, not a rail
    // crossing or painter lookup. Compact deterministic zero scopes therefore
    // become concrete here before the selected frame is requested. The exact
    // matching scene is still prepared/required by the outer coordinator
    // before a user-visible state can be committed.
    installed.materializeFrameForPreparation(state.parentQueryKey);
    if (state.isRailOpen) {
      installed.materializeFrameForPreparation(
        catalog.entryAtLogicalIndex(_selectedIndex(state, catalog)).queryKey,
      );
    }
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

  /// Captures only the exact currently published rail preview before a
  /// structural action leaves its scope. Crossings remain presentation-only;
  /// this explicit boundary is the sole non-settle path that updates the
  /// global temporal anchor.
  bool retainVisibleRailChildForStructuralExit() {
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
    final oldAnchor = state.temporalAnchor;
    if (!navigation.retainChild(
      value: entry.value,
      expectedNavigationEpoch: state.navigationEpoch,
      childQueryKey: entry.queryKey,
      coreRevision: installed.coreRevision,
      reason: DashboardRetainedChildReason.structuralRailExit,
    )) {
      return false;
    }
    final nextAnchor = navigation.temporalAnchor;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'RAIL_VISIBLE_CHILD_RETAINED_FOR_STRUCTURAL_EXIT',
        queryKey: entry.queryKey.value,
        coreRevision: installed.coreRevision,
        message:
            'reason=structuralRailExit plane=${state.plane.name} '
            'parentQueryKey=${state.parentQueryKey.value} '
            'semanticIndex=${entry.logicalIndex} semanticValue=${entry.value} '
            'oldVisibleYear=${oldAnchor.visibleYear} '
            'oldVisibleMonth=${oldAnchor.visibleMonth} '
            'oldVisibleDay=${oldAnchor.visibleDay} '
            'newVisibleYear=${nextAnchor.visibleYear} '
            'newVisibleMonth=${nextAnchor.visibleMonth} '
            'newVisibleDay=${nextAnchor.visibleDay} '
            'navigationEpoch=${state.navigationEpoch} '
            'presentationEpoch=$_presentationEpoch '
            'railActivityBefore=${motion.state.activity.name}',
      ),
    );
    return true;
  }

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
