import 'package:flutter/foundation.dart';

import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import 'dashboard_motion_state.dart';
import 'dashboard_semantic_catalog.dart';

typedef DashboardSemanticCrossing =
    void Function(DashboardSemanticEntry entry, DashboardMotionContext context);
typedef DashboardMotionSettle =
    void Function(DashboardSemanticEntry entry, DashboardMotionContext context);

/// The dashboard rail's sole physical-motion owner.
///
/// Its crossing path performs one catalog lookup and invokes a synchronous
/// semantic callback. It has no knowledge of visible values, loading state or
/// transaction rows.
final class DashboardMotionKernel extends ChangeNotifier {
  DashboardMotionKernel({
    required DashboardSemanticCatalog catalog,
    int initialLogicalIndex = 0,
    DashboardSemanticCrossing? onSemanticCrossed,
    DashboardMotionSettle? onSettled,
  }) : _catalog = catalog,
       _onSemanticCrossed = onSemanticCrossed,
       _onSettled = onSettled,
       carouselController = CenteredCarouselController(
         initialIndex: initialLogicalIndex,
       ),
       _state = DashboardMotionState.initial(
         semanticIndex: catalog
             .entryAtLogicalIndex(initialLogicalIndex)
             .logicalIndex,
       ) {
    final initialSpec = CenteredCarouselPresets.timeRail(itemExtent: 1);
    carouselController.updateConfiguration(
      itemCount: catalog.length,
      itemExtent: initialSpec.itemExtent,
      dataMode: catalog.mode,
      finiteLength: catalog.finiteLength,
      enableHaptics: initialSpec.enableHaptics,
      hapticThrottle: initialSpec.hapticThrottle,
      programmaticScrollDuration: initialSpec.programmaticScrollDuration,
      programmaticScrollCurve: initialSpec.programmaticScrollCurve,
    );
    dashboardPhysics = carouselController.physicsFor(initialSpec);
  }

  final CenteredCarouselController carouselController;
  late final CenterSnapScrollPhysics dashboardPhysics;
  DashboardSemanticCatalog _catalog;
  DashboardMotionState _state;
  DashboardSemanticCrossing? _onSemanticCrossed;
  DashboardMotionSettle? _onSettled;
  int? _lastSettledMotionEpoch;
  int? _lastSettledSemanticIndex;

  DashboardSemanticCatalog get catalog => _catalog;
  DashboardMotionState get state => _state;

  void setCallbacks({
    DashboardSemanticCrossing? onSemanticCrossed,
    DashboardMotionSettle? onSettled,
  }) {
    _onSemanticCrossed = onSemanticCrossed;
    _onSettled = onSettled;
  }

  void beginGesture() {
    _publish(
      _state.copyWith(
        activity: DashboardMotionActivity.drag,
        velocity: 0,
        gestureId: _state.gestureId + 1,
        motionEpoch: _state.motionEpoch + 1,
      ),
    );
  }

  void beginBallistic(double velocity) {
    _publish(
      _state.copyWith(
        activity: DashboardMotionActivity.ballistic,
        velocity: velocity,
      ),
    );
  }

  void updateOffset(double offset, {required double velocity}) {
    _publish(_state.copyWith(offset: offset, velocity: velocity));
  }

  void semanticCrossed(int logicalIndex) {
    final entry = _catalog.entryAtLogicalIndex(logicalIndex);
    final next = _state.copyWith(semanticIndex: entry.logicalIndex);
    _publish(next);
    _onSemanticCrossed?.call(entry, _contextFor(entry));
  }

  void settled(int logicalIndex) {
    final entry = _catalog.entryAtLogicalIndex(logicalIndex);
    if (_lastSettledMotionEpoch == _state.motionEpoch &&
        _lastSettledSemanticIndex == entry.logicalIndex) {
      return;
    }
    _lastSettledMotionEpoch = _state.motionEpoch;
    _lastSettledSemanticIndex = entry.logicalIndex;
    _publish(
      _state.copyWith(
        activity: DashboardMotionActivity.idle,
        velocity: 0,
        semanticIndex: entry.logicalIndex,
      ),
    );
    _onSettled?.call(entry, _contextFor(entry));
  }

  void installCatalog(
    DashboardSemanticCatalog catalog, {
    required int selectedLogicalIndex,
  }) {
    final selectedEntry = catalog.entryAtLogicalIndex(selectedLogicalIndex);
    _catalog = catalog;
    carouselController.updateDataConfiguration(
      dataMode: catalog.mode,
      finiteLength: catalog.finiteLength,
    );
    carouselController.jumpToIndexSilently(selectedLogicalIndex);
    _lastSettledMotionEpoch = null;
    _lastSettledSemanticIndex = null;
    _publish(
      _state.copyWith(
        activity: DashboardMotionActivity.idle,
        velocity: 0,
        semanticIndex: selectedEntry.logicalIndex,
        motionEpoch: _state.motionEpoch + 1,
      ),
    );
  }

  DashboardMotionContext _contextFor(DashboardSemanticEntry entry) =>
      DashboardMotionContext(
        gestureId: _state.gestureId,
        motionEpoch: _state.motionEpoch,
        semanticIndex: entry.logicalIndex,
      );

  void _publish(DashboardMotionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    carouselController.dispose();
    super.dispose();
  }
}
