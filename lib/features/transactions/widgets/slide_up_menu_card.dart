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
    this.showFocusVeil = true,
    this.focusVeilOpacity = 0.28,
  });

  final Key cardKey;
  final Widget child;
  final VoidCallback? onDismissed;
  final bool zIndexShadow;
  final String? debugLabel;
  final double? panelHeight;
  final double dragHandleExtent;
  final bool showFocusVeil;
  final double focusVeilOpacity;

  @override
  State<SlideUpMenuCard> createState() => _SlideUpMenuCardState();
}

class _SlideUpMenuCardState extends State<SlideUpMenuCard>
    with TickerProviderStateMixin {
  static const _dismissThreshold = 90.0;
  static const _minDragOffset = -42.0;
  static const _maxDragOffset = 220.0;
  static const _snapBackDuration = Duration(milliseconds: 170);

  late final AnimationController _entry;
  late final AnimationController _snapBackController;
  late final ValueNotifier<double> _dragDy;
  bool _closing = false;
  bool _dragActive = false;
  double _snapStartDy = 0;
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
      duration: const Duration(milliseconds: 192),
      reverseDuration: const Duration(milliseconds: 160),
    )..addStatusListener(_logEntryStatus);
    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    )
      ..addListener(_syncSnapBackOffset)
      ..addStatusListener(_logSnapBackStatus);
    _openStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel open start duration=${_entry.duration!.inMilliseconds}ms',
    );
    _entry.forward();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final panelHeight = (widget.panelHeight ?? availableHeight)
            .clamp(0.0, availableHeight)
            .toDouble();
        _logLayout(availableHeight, panelHeight);
        return Stack(
          children: [
            if (widget.showFocusVeil)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: ColoredBox(
                    key: const ValueKey('slide-up-menu-veil'),
                    color: Colors.black.withValues(
                      alpha: widget.focusVeilOpacity,
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
                  child: Listener(
                    key: widget.cardKey,
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: (_) => _snapBack(reason: 'cancel'),
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
                                  color: Colors.black.withValues(alpha: 0.14),
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
          ],
        );
      },
    );
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
    _dragDy.value = 0;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel snap complete elapsed=${_elapsedMs(_snapStartedAt)}ms',
    );
    _snapStartedAt = null;
    _snapStartDy = 0;
  }

  void _syncSnapBackOffset() {
    if (_snapStartDy.abs() < 0.01) return;
    final progress = Curves.easeOutCubic.transform(_snapBackController.value);
    _dragDy.value = _snapStartDy * (1 - progress);
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
    _dragActive = event.localPosition.dy <= widget.dragHandleExtent;
    if (!_dragActive) return;
    _snapBackController.stop();
    _dragStartedAt = DateTime.now();
    _lastLoggedDragOffset = _dragDy.value;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag start y=${event.localPosition.dy.toStringAsFixed(1)} offset=${_dragDy.value.toStringAsFixed(1)} handle=${widget.dragHandleExtent.toStringAsFixed(1)}',
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_closing || !_dragActive) return;
    final next = (_dragDy.value + event.delta.dy)
        .clamp(_minDragOffset, _maxDragOffset)
        .toDouble();
    if ((next - _dragDy.value).abs() < 0.01) return;
    _dragDy.value = next;
    _logDragMove(next, event.delta.dy);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_closing || !_dragActive) return;
    final dragOffset = _dragDy.value;
    _dragActive = false;
    final decision = dragOffset > _dismissThreshold ? 'dismiss' : 'snap';
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag end offset=${dragOffset.toStringAsFixed(1)} threshold=${_dismissThreshold.toStringAsFixed(1)} elapsed=${_elapsedMs(_dragStartedAt)}ms decision=$decision',
    );
    _dragStartedAt = null;
    _lastLoggedDragOffset = null;
    if (dragOffset > _dismissThreshold) {
      _dismiss();
      return;
    }
    _snapBack(reason: 'release');
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
      '[SlideUpMenu] $_debugLabel drag move offset=${offset.toStringAsFixed(1)} delta=${delta.toStringAsFixed(1)}',
    );
  }

  void _snapBack({required String reason}) {
    if (!mounted || _closing) return;
    _dragActive = false;
    final offset = _dragDy.value;
    if (offset.abs() < 0.01) return;
    _snapBackController.stop();
    _snapStartDy = offset;
    _snapStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel snap start reason=$reason from=${offset.toStringAsFixed(1)} to=0.0 duration=${_snapBackDuration.inMilliseconds}ms',
    );
    _snapBackController.forward(from: 0);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _snapBackController.stop();
    _dismissStartedAt = DateTime.now();
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel dismiss start dragOffset=${_dragDy.value.toStringAsFixed(1)}',
    );
    _dragDy.value = 0;
    await _entry.reverse();
    if (mounted) widget.onDismissed?.call();
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
