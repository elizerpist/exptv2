import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';

class SlideUpMenuCard extends StatefulWidget {
  const SlideUpMenuCard({
    super.key,
    required this.cardKey,
    required this.child,
    this.onDismissed,
    this.zIndexShadow = true,
    this.debugLabel,
    this.panelHeight,
    this.dragHandleExtent = 56,
    this.entryDuration = const Duration(milliseconds: 192),
    this.visible = true,
    this.showFocusVeil = true,
    this.focusVeilOpacity = 0.28,
    this.dragExclusionKeys = const <GlobalKey>[],
    this.openRequestedAt,
  });

  final Key cardKey;
  final Widget child;
  final VoidCallback? onDismissed;
  final bool zIndexShadow;
  final String? debugLabel;
  final double? panelHeight;
  final double dragHandleExtent;
  final Duration entryDuration;
  final bool visible;
  final bool showFocusVeil;
  final double focusVeilOpacity;
  final List<GlobalKey> dragExclusionKeys;
  final DateTime? openRequestedAt;

  @override
  State<SlideUpMenuCard> createState() => _SlideUpMenuCardState();
}

class _SlideUpMenuCardState extends State<SlideUpMenuCard>
    with TickerProviderStateMixin {
  static const _dismissThreshold = 90.0;
  static const _minDragOffset = 0.0;
  static const _axisLockSlop = 8.0;
  static const _horizontalAxisBias = 1.2;
  static const _snapBackDuration = Duration(milliseconds: 170);
  static const _dismissDuration = Duration(milliseconds: 180);

  late final AnimationController _entry;
  late final AnimationController _snapBackController;
  late final ValueNotifier<double> _dragDy;
  bool _closing = false;
  bool _dragActive = false;
  bool _dragMoved = false;
  bool _dragLoggedStart = false;
  bool _verticalDragAccepted = false;
  bool _dismissAnimatingFromDrag = false;
  double _snapStartDy = 0;
  double _snapEndDy = 0;
  double _panelHeight = 0;
  double _dragStartY = 0;
  double _gestureDx = 0;
  double _gestureDy = 0;
  double? _lastLoggedAvailableHeight;
  double? _lastLoggedPanelHeight;
  double? _lastLoggedDragOffset;
  DateTime? _openStartedAt;
  DateTime? _dragStartedAt;
  DateTime? _snapStartedAt;
  DateTime? _dismissStartedAt;

  String get _debugLabel => widget.debugLabel ?? widget.cardKey.toString();

  @override
  void initState() {
    super.initState();
    _dragDy = ValueNotifier<double>(0);
    _entry = AnimationController(
      vsync: this,
      duration: widget.entryDuration,
      reverseDuration: const Duration(milliseconds: 160),
    )..addStatusListener(_logEntryStatus);
    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    )
      ..addListener(_syncSnapBackOffset)
      ..addStatusListener(_logSnapBackStatus);
    if (widget.visible) {
      _startOpenAnimation(fromInitialMount: true);
    }
  }


  @override
  void didUpdateWidget(covariant SlideUpMenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryDuration != widget.entryDuration) {
      _entry.duration = widget.entryDuration;
    }
    if (!oldWidget.visible && widget.visible) {
      _startOpenAnimation();
    } else if (oldWidget.visible && !widget.visible) {
      _resetHiddenState();
    }
  }

  @override
  void dispose() {
    _entry
      ..removeStatusListener(_logEntryStatus)
      ..dispose();
    _snapBackController
      ..removeListener(_syncSnapBackOffset)
      ..removeStatusListener(_logSnapBackStatus)
      ..dispose();
    _dragDy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participates = widget.visible ||
        _entry.isAnimating ||
        _snapBackController.isAnimating ||
        _dragDy.value > 0.01;
    return TickerMode(
      enabled: participates,
      child: Visibility(
        visible: participates,
        maintainState: true,
        maintainAnimation: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final panelHeight = (widget.panelHeight ?? availableHeight)
            .clamp(0.0, availableHeight)
            .toDouble();
        _panelHeight = panelHeight;
        _logLayout(availableHeight, panelHeight);
        return Stack(
          children: [
            if (widget.showFocusVeil)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_closing) return;
                    DebugConsole.log(
                      '[SlideUpMenu] $_debugLabel veil tap dismiss',
                    );
                    _dismiss();
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_entry, _dragDy]),
                    builder: (context, child) {
                      final dragFade = (1 - (_dragDy.value / _dragMaxOffset))
                          .clamp(0.0, 1.0)
                          .toDouble();
                      return Opacity(
                        key: const ValueKey('slide-up-menu-veil-opacity'),
                        opacity: (_entry.value * dragFade)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        child: child,
                      );
                    },
                    child: ColoredBox(
                      key: const ValueKey('slide-up-menu-veil'),
                      color: Colors.black.withValues(
                        alpha: widget.focusVeilOpacity,
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: panelHeight,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_entry, _dragDy]),
                  builder: (context, child) {
                    final entryOffset =
                        (1 - Curves.easeOutCubic.transform(_entry.value)) *
                        panelHeight;
                    return Transform.translate(
                      key: const ValueKey('slide-up-menu-transform'),
                      offset: Offset(0, entryOffset + _dragDy.value),
                      child: child,
                    );
                  },
                  child: RepaintBoundary(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerUp,
                      onPointerCancel: _handlePointerCancel,
                      child: KeyedSubtree(
                        key: widget.cardKey,
                        child: SizedBox.expand(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              border: Border.all(color: AppColors.gray200),
                              boxShadow: widget.zIndexShadow
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.14,
                                        ),
                                        offset: const Offset(0, -2),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
          },
        ),
      ),
    );
  }


  void _startOpenAnimation({bool fromInitialMount = false}) {
    _closing = false;
    _dismissAnimatingFromDrag = false;
    _snapBackController.stop();
    _dragDy.value = 0;
    _entry.stop();
    _entry.value = 0;
    _openStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel open start '
      'duration=${_entry.duration!.inMilliseconds}ms '
      'requestElapsed=${_elapsedMs(widget.openRequestedAt)}ms '
      'source=${fromInitialMount ? 'mount' : 'visible'}',
    );
    _entry.forward(from: 0);
  }

  void _resetHiddenState() {
    _entry.stop();
    _snapBackController.stop();
    _entry.value = 0;
    _dragDy.value = 0;
    _closing = false;
    _dragActive = false;
    _dismissAnimatingFromDrag = false;
    _snapStartDy = 0;
    _snapEndDy = 0;
    _openStartedAt = null;
    _dragStartedAt = null;
    _snapStartedAt = null;
    _dismissStartedAt = null;
  }

  void _logEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      DebugConsole.log('[SlideUpMenu] $_debugLabel open animating');
      return;
    }
    if (status == AnimationStatus.completed) {
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel open complete elapsed=${_elapsedMs(_openStartedAt)}ms',
      );
      _openStartedAt = null;
      return;
    }
    if (status == AnimationStatus.reverse) {
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel dismiss animating duration=${_entry.reverseDuration!.inMilliseconds}ms',
      );
      return;
    }
    if (status == AnimationStatus.dismissed && _closing) {
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel dismiss complete elapsed=${_elapsedMs(_dismissStartedAt)}ms',
      );
      _dismissStartedAt = null;
    }
  }

  void _logSnapBackStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_dismissAnimatingFromDrag) {
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel dismiss complete elapsed=${_elapsedMs(_dismissStartedAt)}ms',
      );
      _dismissStartedAt = null;
      _dismissAnimatingFromDrag = false;
      return;
    }
    _dragDy.value = 0;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel snap complete elapsed=${_elapsedMs(_snapStartedAt)}ms',
    );
    _snapStartedAt = null;
    _snapStartDy = 0;
    _snapEndDy = 0;
  }

  void _syncSnapBackOffset() {
    if ((_snapStartDy - _snapEndDy).abs() < 0.01) return;
    final progress = Curves.easeOutCubic.transform(_snapBackController.value);
    _dragDy.value = lerpDouble(_snapStartDy, _snapEndDy, progress) ?? 0;
  }

  void _logLayout(double availableHeight, double panelHeight) {
    if (_lastLoggedAvailableHeight == availableHeight &&
        _lastLoggedPanelHeight == panelHeight) {
      return;
    }
    _lastLoggedAvailableHeight = availableHeight;
    _lastLoggedPanelHeight = panelHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel layout available=${availableHeight.toStringAsFixed(1)} panel=${panelHeight.toStringAsFixed(1)} veil=${widget.showFocusVeil}',
      );
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_closing) return;
    _resetPointerGestureState();
    if (_isDragExcluded(event.position)) {
      _dragActive = false;
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel drag ignored by exclusion y=${event.localPosition.dy.toStringAsFixed(1)}',
      );
      return;
    }
    _dragActive = true;
    _dragStartY = event.localPosition.dy;
    _snapBackController.stop();
    _dragStartedAt = DateTime.now();
    _lastLoggedDragOffset = _dragDy.value;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_closing || !_dragActive) return;
    _gestureDx += event.delta.dx;
    _gestureDy += event.delta.dy;

    if (!_verticalDragAccepted) {
      final absDx = _gestureDx.abs();
      final absDy = _gestureDy.abs();
      if (absDx > _axisLockSlop && absDx > absDy * _horizontalAxisBias) {
        _dragActive = false;
        DebugConsole.log(
          '[SlideUpMenu] $_debugLabel drag horizontal lock dx=${_gestureDx.toStringAsFixed(1)} dy=${_gestureDy.toStringAsFixed(1)}',
        );
        return;
      }
      if (absDy <= _axisLockSlop || absDy < absDx) return;
      _verticalDragAccepted = true;
    }

    final maxDrag = _dragMaxOffset;
    final next = (_dragDy.value + event.delta.dy)
        .clamp(_minDragOffset, maxDrag)
        .toDouble();
    if ((next - _dragDy.value).abs() < 0.01) return;
    if (!_dragLoggedStart) {
      _dragLoggedStart = true;
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel drag start y=${_dragStartY.toStringAsFixed(1)} offset=${_dragDy.value.toStringAsFixed(1)} max=${maxDrag.toStringAsFixed(1)} handle=${widget.dragHandleExtent.toStringAsFixed(1)}',
      );
    }
    _dragMoved = true;
    _dragDy.value = next;
    _logDragMove(next, event.delta.dy);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_closing) return;
    if (!_dragActive) {
      _resetPointerGestureState();
      return;
    }
    final dragOffset = _dragDy.value;
    _dragActive = false;
    if (!_dragMoved) {
      _dragStartedAt = null;
      _lastLoggedDragOffset = null;
      _resetPointerGestureState();
      return;
    }
    final decision = dragOffset > _dismissThreshold ? 'dismiss' : 'snap';
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag end offset=${dragOffset.toStringAsFixed(1)} threshold=${_dismissThreshold.toStringAsFixed(1)} max=${_dragMaxOffset.toStringAsFixed(1)} elapsed=${_elapsedMs(_dragStartedAt)}ms decision=$decision',
    );
    _dragStartedAt = null;
    _lastLoggedDragOffset = null;
    _resetPointerGestureState();
    if (dragOffset > _dismissThreshold) {
      _dismiss();
      return;
    }
    _snapBack(reason: 'release');
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_closing) return;
    if (!_dragActive) {
      _resetPointerGestureState();
      return;
    }
    _resetPointerGestureState();
    _snapBack(reason: 'cancel');
  }

  void _resetPointerGestureState() {
    _dragActive = false;
    _dragMoved = false;
    _dragLoggedStart = false;
    _verticalDragAccepted = false;
    _gestureDx = 0;
    _gestureDy = 0;
  }

  void _logDragMove(double offset, double delta) {
    final last = _lastLoggedDragOffset;
    final crossedThreshold = last != null &&
        last <= _dismissThreshold &&
        offset > _dismissThreshold;
    if (last != null &&
        (offset - last).abs() < 28 &&
        !crossedThreshold) {
      return;
    }
    _lastLoggedDragOffset = offset;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag move offset=${offset.toStringAsFixed(1)} delta=${delta.toStringAsFixed(1)} max=${_dragMaxOffset.toStringAsFixed(1)}',
    );
  }

  void _snapBack({required String reason}) {
    if (!mounted || _closing) return;
    _dragActive = false;
    final offset = _dragDy.value;
    if (offset.abs() < 0.01) return;
    _snapBackController.stop();
    _dismissAnimatingFromDrag = false;
    _snapStartDy = offset;
    _snapEndDy = 0;
    _snapBackController.duration = _snapBackDuration;
    _snapStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel snap start reason=$reason from=${offset.toStringAsFixed(1)} to=0.0 duration=${_snapBackDuration.inMilliseconds}ms',
    );
    _snapBackController.forward(from: 0);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _dragActive = false;
    _snapBackController.stop();
    final from = _dragDy.value;
    final to = math.max(_dragMaxOffset, from);
    _snapStartDy = from;
    _snapEndDy = to;
    _dismissAnimatingFromDrag = true;
    _snapBackController.duration = _dismissDuration;
    _dismissStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel dismiss start from=${from.toStringAsFixed(1)} to=${to.toStringAsFixed(1)} duration=${_dismissDuration.inMilliseconds}ms',
    );
    await _snapBackController.forward(from: 0);
    if (!mounted) return;
    _entry.value = 0;
    _dragDy.value = 0;
    _closing = false;
    widget.onDismissed?.call();
  }

  double get _dragMaxOffset => math.max(_panelHeight, 1);

  bool _isDragExcluded(Offset globalPosition) {
    for (final key in widget.dragExclusionKeys) {
      final keyContext = key.currentContext;
      final renderObject = keyContext?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        continue;
      }
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      if (rect.contains(globalPosition)) return true;
    }
    return false;
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
