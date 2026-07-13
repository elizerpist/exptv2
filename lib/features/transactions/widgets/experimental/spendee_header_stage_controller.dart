enum SpendeeHeaderStage { stage0, stage1, stage2 }

class SpendeeHeaderStageGeometry {
  const SpendeeHeaderStageGeometry({
    required this.headerTop,
    required this.stage0Height,
    required this.stage1Height,
    required this.stage2Height,
    required this.contentGap,
  });

  factory SpendeeHeaderStageGeometry.html({required double screenHeight}) {
    const headerTop = 104.0;
    const stage0Height = 104.0;
    const stage1Height = 284.0;
    const contentGap = 4.0;
    const typeRowHeight = 66.0;
    const summaryVisibleHeight = 59.0;
    const searchTopGap = 12.0;
    const searchVisibleHeight = 45.0;
    final safetyTop = screenHeight - 18.0;
    final stage2VisibleStackHeight =
        typeRowHeight +
        summaryVisibleHeight +
        searchTopGap +
        searchVisibleHeight;
    final stage2Height =
        safetyTop - headerTop - contentGap - stage2VisibleStackHeight;
    return SpendeeHeaderStageGeometry(
      headerTop: headerTop,
      stage0Height: stage0Height,
      stage1Height: stage1Height,
      stage2Height: stage2Height,
      contentGap: contentGap,
    );
  }

  final double headerTop;
  final double stage0Height;
  final double stage1Height;
  final double stage2Height;
  final double contentGap;

  double heightFor(SpendeeHeaderStage stage) {
    return switch (stage) {
      SpendeeHeaderStage.stage0 => stage0Height,
      SpendeeHeaderStage.stage1 => stage1Height,
      SpendeeHeaderStage.stage2 => stage2Height,
    };
  }

  double contentTopFor(SpendeeHeaderStage stage) {
    return headerTop + heightFor(stage) + contentGap;
  }
}

class SpendeeHeaderDragUpdate {
  const SpendeeHeaderDragUpdate({required this.height, required this.tick});

  final double height;
  final bool tick;
}

class SpendeeHeaderRelease {
  const SpendeeHeaderRelease({
    required this.targetStage,
    required this.targetHeight,
    required this.springBack,
  });

  final SpendeeHeaderStage targetStage;
  final double targetHeight;
  final bool springBack;
}

class SpendeeHeaderStageController {
  SpendeeHeaderStageController({
    required this.geometry,
    this.stage1TriggerDistance = 72,
    this.stage2TriggerDistance = 220,
    this.popoutOvershoot = 18,
  }) : _height = geometry.stage0Height;

  final SpendeeHeaderStageGeometry geometry;
  final double stage1TriggerDistance;
  final double stage2TriggerDistance;
  final double popoutOvershoot;

  SpendeeHeaderStage _stage = SpendeeHeaderStage.stage0;
  SpendeeHeaderStage? _releaseTarget;
  late double _height;
  double _dragDistance = 0;
  bool _popoutTicked = false;
  bool _stage1Ticked = false;
  bool _stage2Ticked = false;

  SpendeeHeaderStage get stage => _stage;
  double get currentHeight => _height;

  void beginDrag() {
    _dragDistance = 0;
    _releaseTarget = _stage;
    _popoutTicked = false;
    _stage1Ticked = false;
    _stage2Ticked = false;
    _height = geometry.heightFor(_stage);
  }

  SpendeeHeaderDragUpdate dragBy(double dy) {
    _dragDistance = (_dragDistance + dy)
        .clamp(
          0.0,
          geometry.stage2Height - geometry.stage0Height + popoutOvershoot,
        )
        .toDouble();
    var tick = false;
    final baseHeight = geometry.heightFor(_stage);
    final maxHeight = _stage == SpendeeHeaderStage.stage2
        ? geometry.stage2Height + popoutOvershoot
        : geometry.stage2Height;
    _height = (baseHeight + _dragDistance)
        .clamp(baseHeight, maxHeight)
        .toDouble();

    if (_stage == SpendeeHeaderStage.stage0) {
      _releaseTarget = SpendeeHeaderStage.stage0;
      if (!_stage1Ticked && _dragDistance >= stage1TriggerDistance) {
        _stage1Ticked = true;
        _releaseTarget = SpendeeHeaderStage.stage1;
        tick = true;
      }
    } else if (_stage == SpendeeHeaderStage.stage1) {
      _releaseTarget = _dragDistance > 0
          ? SpendeeHeaderStage.stage0
          : SpendeeHeaderStage.stage1;
      if (!_popoutTicked && _dragDistance > 0) {
        _popoutTicked = true;
        tick = true;
      }
      if (!_stage2Ticked && _dragDistance >= stage2TriggerDistance) {
        _stage2Ticked = true;
        _releaseTarget = SpendeeHeaderStage.stage2;
        tick = true;
      } else if (_stage2Ticked && _dragDistance < stage2TriggerDistance) {
        _releaseTarget = _dragDistance > 0
            ? SpendeeHeaderStage.stage0
            : SpendeeHeaderStage.stage1;
      }
    } else {
      _releaseTarget = _dragDistance > 0
          ? SpendeeHeaderStage.stage1
          : SpendeeHeaderStage.stage2;
      if (!_popoutTicked && _dragDistance > 0) {
        _popoutTicked = true;
        tick = true;
      }
    }

    return SpendeeHeaderDragUpdate(height: _height, tick: tick);
  }

  SpendeeHeaderRelease release() {
    final target = _releaseTarget ?? _stage;
    final springBack = target == _stage;
    _stage = target;
    _height = geometry.heightFor(target);
    _dragDistance = 0;
    _releaseTarget = target;
    return SpendeeHeaderRelease(
      targetStage: target,
      targetHeight: _height,
      springBack: springBack,
    );
  }
}
