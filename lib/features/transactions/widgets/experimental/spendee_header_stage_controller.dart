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
    required SpendeeHeaderStageGeometry geometry,
    this.stage1TriggerDistance = 72,
    this.stage2TriggerDistance = 220,
    this.popoutOvershoot = 18,
  }) : _geometry = geometry,
       _settledHeight = geometry.stage0Height,
       _height = geometry.stage0Height;

  final double stage1TriggerDistance;
  final double stage2TriggerDistance;
  final double popoutOvershoot;

  SpendeeHeaderStageGeometry _geometry;
  SpendeeHeaderStage _settledStage = SpendeeHeaderStage.stage0;
  SpendeeHeaderStage _armedTarget = SpendeeHeaderStage.stage0;
  double _settledHeight;
  double _height;
  double _dragOffset = 0;
  bool _popoutTicked = false;
  bool _stage1Ticked = false;
  bool _stage2Ticked = false;

  SpendeeHeaderStageGeometry get geometry => _geometry;
  SpendeeHeaderStage get stage => _settledStage;
  double get currentHeight => _height;

  void replaceGeometry(SpendeeHeaderStageGeometry geometry) {
    _geometry = geometry;
    _settledHeight = geometry.heightFor(_settledStage);
    _height = _heightForDragOffset();
  }

  void beginDrag() {
    _dragOffset = 0;
    _armedTarget = _settledStage;
    _popoutTicked = false;
    _stage1Ticked = false;
    _stage2Ticked = false;
    _settledHeight = geometry.heightFor(_settledStage);
    _height = _settledHeight;
  }

  SpendeeHeaderDragUpdate dragBy(double dy) {
    _dragOffset += dy;
    _height = _heightForDragOffset();
    var tick = false;

    if (_settledStage == SpendeeHeaderStage.stage0) {
      _armedTarget = _dragOffset >= stage1TriggerDistance
          ? SpendeeHeaderStage.stage1
          : SpendeeHeaderStage.stage0;
      if (!_stage1Ticked && _dragOffset >= stage1TriggerDistance) {
        _stage1Ticked = true;
        tick = true;
      }
    } else if (_settledStage == SpendeeHeaderStage.stage1) {
      if (_dragOffset <= 0) {
        _armedTarget = SpendeeHeaderStage.stage1;
      } else if (_dragOffset >= stage2TriggerDistance) {
        _armedTarget = SpendeeHeaderStage.stage2;
      } else {
        _armedTarget = SpendeeHeaderStage.stage0;
      }
      if (!_popoutTicked && _dragOffset > 0) {
        _popoutTicked = true;
        tick = true;
      }
      if (!_stage2Ticked && _dragOffset >= stage2TriggerDistance) {
        _stage2Ticked = true;
        tick = true;
      }
    } else {
      _armedTarget = _dragOffset > 0
          ? SpendeeHeaderStage.stage1
          : SpendeeHeaderStage.stage2;
      if (!_popoutTicked && _dragOffset > 0) {
        _popoutTicked = true;
        tick = true;
      }
    }

    return SpendeeHeaderDragUpdate(height: _height, tick: tick);
  }

  SpendeeHeaderRelease release() {
    final target = _armedTarget;
    final springBack = target == _settledStage;
    _settledStage = target;
    _settledHeight = geometry.heightFor(target);
    _height = _settledHeight;
    _dragOffset = 0;
    _armedTarget = target;
    return SpendeeHeaderRelease(
      targetStage: target,
      targetHeight: _height,
      springBack: springBack,
    );
  }

  double _heightForDragOffset() {
    final dragCeiling = _settledStage == SpendeeHeaderStage.stage2
        ? _settledHeight + popoutOvershoot
        : geometry.stage2Height;
    final maxHeight = dragCeiling < _settledHeight
        ? _settledHeight
        : dragCeiling;
    return (_settledHeight + _dragOffset)
        .clamp(_settledHeight, maxHeight)
        .toDouble();
  }
}
