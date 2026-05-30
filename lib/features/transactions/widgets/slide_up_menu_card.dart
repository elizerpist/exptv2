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
  });

  final Key cardKey;
  final Widget child;
  final VoidCallback? onDismissed;
  final bool zIndexShadow;
  final String? debugLabel;
  final double? panelHeight;
  final double dragHandleExtent;

  @override
  State<SlideUpMenuCard> createState() => _SlideUpMenuCardState();
}

class _SlideUpMenuCardState extends State<SlideUpMenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final ValueNotifier<double> _dragDy;
  bool _closing = false;
  bool _dragActive = false;
  double? _lastLoggedAvailableHeight;
  double? _lastLoggedPanelHeight;

  String get _debugLabel => widget.debugLabel ?? widget.cardKey.toString();

  @override
  void initState() {
    super.initState();
    _dragDy = ValueNotifier<double>(0);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 192),
      reverseDuration: const Duration(milliseconds: 160),
    )..addStatusListener(_logStatus);
    DebugConsole.log('[SlideUpMenu] $_debugLabel open start');
    _entry.forward();
  }

  @override
  void dispose() {
    _entry
      ..removeStatusListener(_logStatus)
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
        return Align(
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
                  key: widget.cardKey,
                  offset: Offset(0, entryOffset + _dragDy.value),
                  child: child,
                );
              },
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: (_) => _snapBack(),
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
        );
      },
    );
  }

  void _logStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      DebugConsole.log('[SlideUpMenu] $_debugLabel open complete');
      return;
    }
    if (status == AnimationStatus.dismissed && _closing) {
      DebugConsole.log('[SlideUpMenu] $_debugLabel dismiss complete');
    }
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
        '[SlideUpMenu] $_debugLabel layout available=${availableHeight.toStringAsFixed(1)} panel=${panelHeight.toStringAsFixed(1)}',
      );
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_closing) return;
    _dragActive = event.localPosition.dy <= widget.dragHandleExtent;
    if (!_dragActive) return;
    _dragDy.value = 0;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag start y=${event.localPosition.dy.toStringAsFixed(1)}',
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_closing || !_dragActive) return;
    final next = (_dragDy.value + event.delta.dy)
        .clamp(-42.0, 220.0)
        .toDouble();
    if ((next - _dragDy.value).abs() < 0.01) return;
    _dragDy.value = next;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_closing || !_dragActive) return;
    final dragOffset = _dragDy.value;
    _dragActive = false;
    DebugConsole.log(
      '[SlideUpMenu] $_debugLabel drag end offset=${dragOffset.toStringAsFixed(1)}',
    );
    if (dragOffset > 90) {
      _dismiss();
      return;
    }
    _snapBack();
  }

  void _snapBack() {
    if (!mounted || _closing) return;
    if (_dragDy.value.abs() >= 0.01) {
      DebugConsole.log(
        '[SlideUpMenu] $_debugLabel snap back offset=${_dragDy.value.toStringAsFixed(1)}',
      );
    }
    _dragActive = false;
    _dragDy.value = 0;
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    DebugConsole.log('[SlideUpMenu] $_debugLabel dismiss start');
    _dragDy.value = 0;
    await _entry.reverse();
    if (mounted) widget.onDismissed?.call();
  }
}
