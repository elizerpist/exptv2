import 'spendee_header_visual_spec.dart';

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
    final source = SpendeeHeaderVisualSpec.budgetDefault().geometry;
    return SpendeeHeaderStageGeometry(
      headerTop: source.headerTop,
      stage0Height: source.stage0Height,
      stage1Height: source.stage1Height,
      stage2Height: source.stage2HeightFor(screenHeight),
      contentGap: source.contentGap,
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
  const SpendeeHeaderDragUpdate({
    required this.height,
    required this.tickCount,
  });

  final double height;
  final int tickCount;

  bool get tick => tickCount > 0;
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
    double? stage1TriggerDistance,
    double? stage2TriggerDistance,
    this.popoutOvershoot = 18,
  }) : _stage1TriggerDistance = stage1TriggerDistance,
       _stage2TriggerDistance = stage2TriggerDistance,
       _geometry = geometry,
       _settledHeight = geometry.stage0Height,
       _height = geometry.stage0Height;

  final double? _stage1TriggerDistance;
  final double? _stage2TriggerDistance;
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
  double get stage1TriggerDistance =>
      _stage1TriggerDistance ??
      (geometry.stage1Height - geometry.stage0Height)
          .clamp(0.0, double.infinity)
          .toDouble();
  double get stage2TriggerDistance =>
      _stage2TriggerDistance ??
      (geometry.stage2Height - geometry.stage1Height)
          .clamp(0.0, double.infinity)
          .toDouble();

  void replaceGeometry(SpendeeHeaderStageGeometry geometry) {
    _geometry = geometry;
    _settledHeight = geometry.heightFor(_settledStage);
    _height = _heightForDragOffset();
    _armedTarget = _targetForDragOffset();
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
    var tickCount = 0;

    if (_settledStage == SpendeeHeaderStage.stage0) {
      if (!_stage1Ticked && _dragOffset >= stage1TriggerDistance) {
        _stage1Ticked = true;
        tickCount += 1;
      }
    } else if (_settledStage == SpendeeHeaderStage.stage1) {
      if (!_popoutTicked && _dragOffset > 0) {
        _popoutTicked = true;
        tickCount += 1;
      }
      if (!_stage2Ticked && _dragOffset >= stage2TriggerDistance) {
        _stage2Ticked = true;
        tickCount += 1;
      }
    } else {
      if (!_popoutTicked && _dragOffset > 0) {
        _popoutTicked = true;
        tickCount += 1;
      }
    }
    _armedTarget = _targetForDragOffset();

    return SpendeeHeaderDragUpdate(height: _height, tickCount: tickCount);
  }

  SpendeeHeaderRelease release() {
    final target = _armedTarget;
    final targetHeight = geometry.heightFor(target);
    final springBack = (_height - targetHeight).abs() > 0.5;
    _settledStage = target;
    _settledHeight = targetHeight;
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
    final dragCeiling = switch (_settledStage) {
      SpendeeHeaderStage.stage0 => geometry.stage2Height,
      SpendeeHeaderStage.stage1 => geometry.stage2Height + popoutOvershoot,
      SpendeeHeaderStage.stage2 => _settledHeight + popoutOvershoot,
    };
    final maxHeight = dragCeiling < _settledHeight
        ? _settledHeight
        : dragCeiling;
    return (_settledHeight + _dragOffset)
        .clamp(_settledHeight, maxHeight)
        .toDouble();
  }

  SpendeeHeaderStage _targetForDragOffset() {
    return switch (_settledStage) {
      SpendeeHeaderStage.stage0 =>
        _dragOffset >= stage1TriggerDistance
            ? SpendeeHeaderStage.stage1
            : SpendeeHeaderStage.stage0,
      SpendeeHeaderStage.stage1 =>
        _dragOffset <= 0
            ? SpendeeHeaderStage.stage1
            : _dragOffset >= stage2TriggerDistance
            ? SpendeeHeaderStage.stage2
            : SpendeeHeaderStage.stage0,
      SpendeeHeaderStage.stage2 =>
        _dragOffset > 0
            ? SpendeeHeaderStage.stage1
            : SpendeeHeaderStage.stage2,
    };
  }
}
